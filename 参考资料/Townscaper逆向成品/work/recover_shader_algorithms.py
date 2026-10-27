"""Translate every business DXBC instruction to register-explicit HLSL and recover Unity bindings."""
from pathlib import Path
import json,re,struct,sys,collections,hashlib
BASE=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(BASE/'work/asset_pydeps'))
from UnityPy.streams import EndianBinaryReader
from UnityPy.export.ShaderConverter import ShaderSubProgram
ROOT=BASE/'outputs/townscaper_shader_programs';OUT=BASE/'outputs/townscaper_shader_algorithms';OUT.mkdir(exist_ok=True)
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'))
business=[s for s in manifest if s.get('name','').startswith(('Placemaker/','PlacemakerUi/','Hidden/Ao','Hidden/ShadowBaker','Hidden/MarchingSquares'))]
def dxbc_execution_literals(path):
    data=path.read_bytes();chunks=struct.unpack_from('<I',data,28)[0]
    for off in struct.unpack_from('<'+'I'*chunks,data,32):
        if data[off:off+4]in(b'SHDR',b'SHEX'):
            size=struct.unpack_from('<I',data,off+4)[0];tokens=struct.unpack_from('<'+'I'*(size//4),data,off+8);break
    def operand(words,i,literals):
        token=words[i];i+=1;ext=token
        while ext&0x80000000:ext=words[i];i+=1
        typ=(token>>12)&255;dim=(token>>20)&3
        if typ==4:
            count={1:1,2:4}[token&3];literals.append(list(words[i:i+count]));return i+count
        if typ==5:raise ValueError('unexpected immediate64')
        for j in range(dim):
            mode=(token>>(22+3*j))&7
            if mode==0:i+=1
            elif mode==1:i+=2
            elif mode==2:i=operand(words,i,literals)
            elif mode==3:i+=1;i=operand(words,i,literals)
            elif mode==4:i+=2;i=operand(words,i,literals)
            else:raise ValueError('index mode '+str(mode))
        return i
    result=[];i=2
    while i<len(tokens):
        token=tokens[i];n=(token>>24)&127;opcode=token&2047;assert n>0
        words=tokens[i:i+n];i+=n
        if 88<=opcode<=106:continue # all SM4 declarations used by this target
        literals=[];j=1;ext=token
        while ext&0x80000000:ext=words[j];j+=1
        while j<len(words):j=operand(words,j,literals)
        assert j==len(words)
        result.append({'opcode':opcode,'literals':literals})
    return result
CURRENT_LITERALS=[]
def split(s):
    parts=[];depth=0;start=0
    for i,c in enumerate(s):
        if c in '([':depth+=1
        elif c in ')]':depth-=1
        elif c==',' and depth==0:parts.append(s[start:i].strip());start=i+1
    parts.append(s[start:].strip());return parts
def bindings(s,p):
    name=Path(s['parsed_form']).name.removesuffix('.parsed.json')
    blob=(ROOT/(name+'__p'+str(p['platform'])+'.decompressed.bin')).read_bytes()
    off,length,seg=struct.unpack_from('<III',blob,4+12*p['index'])
    reader=EndianBinaryReader(blob,endian='<');reader.Position=off;ShaderSubProgram(reader)
    start=reader.Position;tail=blob[start:off+length];strings=[]
    for i in range(0,len(tail)-8,4):
        n=struct.unpack_from('<I',tail,i)[0]
        if not 1<=n<=120 or i+4+n>len(tail):continue
        b=tail[i+4:i+4+n]
        if not re.fullmatch(rb'[A-Za-z_$][A-Za-z0-9_$]*',b):continue
        end=(i+4+n+3)//4*4
        post=list(struct.unpack_from('<'+'I'*min(6,(len(tail)-end)//4),tail,end))
        strings.append({'name':b.decode(),'tail_offset':i,'blob_offset':start+i,'post':post})
    slots={};blocks={};owner=None;fields=[];textures=[]
    for t in strings:
        a=t['post'];n=t['name']
        if len(a)>=3 and a[0]==1 and a[2]==0 and a[1]<16 and (n.startswith('Unity') or n=='$Globals'):slots[n]=a[1]
        if len(a)>=2 and a[0]>=16 and a[0]%16==0 and a[1]<100 and (n.startswith('Unity') or n=='$Globals'):
            owner=n;blocks[n]={'name':n,'bytes':a[0],'declared_fields':a[1]}
        elif len(a)==6 and a[0]==0 and a[1]in(1,2,3,4) and 1<=a[2]<=4 and a[3]in(0,1) and a[4]==0 and a[5]%4==0:
            fields.append({'name':n,'buffer':owner,'type_raw':a[0],'rows':a[1],'columns':a[2],'matrix':bool(a[3]),'array_raw':a[4],'offset':a[5],'blob_offset':t['blob_offset']})
        elif len(a)>=4 and a[0]==0 and a[1]<16 and a[2]<16 and a[3]==4:
            textures.append({'name':n,'texture':a[1],'sampler':a[2],'raw_flags':a[0],'dimension_raw':a[3],'blob_offset':t['blob_offset']})
    for f in fields:f['slot']=slots.get(f['buffer']);f['register']=f['offset']//16;f['component']='xyzw'[(f['offset']%16)//4]
    return {'program_blob_offset':off,'program_blob_length':length,'tail_offset':start,'buffers':[dict(b,slot=slots.get(n))for n,b in blocks.items()],'fields':fields,'textures':textures,'raw_strings':strings}
def source(s,integer=False):
    s=s.strip();neg=s.startswith('-')
    if neg:s=s[1:]
    absolute=s.startswith('|') and s.endswith('|')
    if absolute:s=s[1:-1]
    if s.startswith('l('):
        vals=split(s[2:-1]);bits=CURRENT_LITERALS.pop(0);assert len(bits)==len(vals),(s,bits)
        vs=[hex(v)+'u'for v in bits]
        if len(vs)==1:vs*=4
        assert len(vs)==4,(s,vs)
        out='uint4('+', '.join(vs)+')'
    else:
        m=re.fullmatch(r'(cb\d+\[\d+\]|[rvo]\d+)(?:\.([xyzw]+))?',s);assert m,s
        reg,sw=m.groups();sw=sw or 'xyzw';sw=(sw+sw[-1]*4)[:4]
        if reg.startswith('o'):reg='out_'+reg
        out=reg+'.'+sw
    if absolute:out='asuint(abs(asfloat('+out+')))'
    if neg:out='asuint(-'+('asint'if integer else'asfloat')+'('+out+'))'
    return out
def signatures(code,which):
    area=code.split('// '+which+' signature:',1)[1]
    if which=='Input':area=area.split('// Output signature:',1)[0]
    else:area=area.split('\n'+re.search(r'[pv]s_4_0',code).group(0),1)[0]
    ans={}
    for l in area.splitlines():
        m=re.match(r'//\s+(\w+)\s+(\d+)\s+([xyzw]+)\s+(\d+)\s+(\w+)\s+(float|uint|sint)',l)
        if m:
            name,index,mask,reg,sysvalue,typ=m.groups();ans.setdefault(int(reg),[]).append({'semantic':name+(index if not name.startswith('SV_') else ''),'mask':mask,'type':typ})
    return ans
OPCOUNTS=collections.Counter();records=[]
for s in business:
 for p in s['programs']:
    code=(BASE/p['assembly']).read_text(encoding='utf8');lines=code.splitlines();stage=re.search(r'([pv]s_4_0)',code).group(1)
    bind=bindings(s,p);inputs=signatures(code,'Input');outputs=signatures(code,'Output');decl=[];body=[];indent=1;instruction_count=0;temps=0;raw_instructions=dxbc_execution_literals((BASE/p['assembly']).with_suffix('.dxbc'))
    def emit(t):body.append('    '*indent+t)
    def assignment(dst,expr,line,n):
        if dst=='null':return
        m=re.fullmatch(r'([ro]\d+)(?:\.([xyzw]+))?',dst);assert m,dst
        reg,mask=m.groups();mask=mask or 'xyzw';reg='out_'+reg if reg.startswith('o')else reg
        # Separate RHS temporary preserves simultaneous lane reads before masked writes.
        emit('uint4 value_'+str(n)+' = '+expr+'; // '+line)
        emit(reg+'.'+mask+' = value_'+str(n)+'.'+mask+';')
    for line in lines:
        line=line.strip()
        if not line or line.startswith('//')or line==stage:continue
        op,*rest=line.split(' ',1);args=split(rest[0])if rest else[]
        if op.startswith('dcl_'):
            if op=='dcl_constantbuffer':
                slot,num=re.search(r'CB(\d+)\[(\d+)\]',line).groups();decl.append(f'cbuffer Buffer{slot}:register(b{slot}) {{ uint4 cb{slot}[{num}]; }};')
            elif op=='dcl_resource_texture2d':
                n=re.search(r't(\d+)$',line).group(1);decl.append(f'Texture2D<float4> t{n}:register(t{n});')
            elif op=='dcl_sampler':
                n=re.search(r's(\d+)',line).group(1);decl.append(f'SamplerState s{n}:register(s{n});')
            elif op=='dcl_temps':decl.append('// temporary registers: '+args[0]);temps=int(args[0])
            continue
        instruction_count+=1;OPCOUNTS[op]+=1;n=instruction_count
        assert not CURRENT_LITERALS
        CURRENT_LITERALS=[list(v)for v in raw_instructions[n-1]['literals']]
        if op=='loop':emit('while (true) {');indent+=1;continue
        if op=='endloop':indent-=1;emit('}');continue
        if op=='if_nz':emit('if ('+source(args[0])+'.x != 0u) {');indent+=1;continue
        if op=='else':indent-=1;emit('} else {');indent+=1;continue
        if op=='endif':indent-=1;emit('}');continue
        if op in ('breakc_nz','discard_nz'):
            emit('if ('+source(args[0])+'.x != 0u) '+('break;'if op.startswith('break')else'discard;')+' // '+line);continue
        if op=='ret':emit('// ret: return all declared output registers below.');continue
        sat=op.endswith('_sat');opbase=op.removesuffix('_sat')
        dst=args[0];vals=[source(a,integer=opbase in ('iadd','imad','ishr','ilt'))for a in args[1:]]if opbase not in ('sample','sample_l','sample_b','sincos','udiv')else[]
        F=lambda i:'asfloat('+vals[i]+')';I=lambda i:'asint('+vals[i]+')';U=lambda i:vals[i]
        if opbase=='mov':expr=U(0)
        elif opbase in ('add','mul','div'):expr='asuint('+F(0)+{'add':' + ','mul':' * ','div':' / '}[opbase]+F(1)+')'
        elif opbase=='mad':expr='asuint(mad('+F(0)+', '+F(1)+', '+F(2)+'))'
        elif opbase in ('min','max'):expr='asuint('+opbase+'('+F(0)+', '+F(1)+'))'
        elif opbase.startswith('dp'):expr='asuint(dot('+F(0)+'.'+'xyzw'[:int(opbase[2])]+', '+F(1)+'.'+'xyzw'[:int(opbase[2])]+')).xxxx'
        elif opbase in ('frc','sqrt','rsq','round_ni','round_z','round_ne','deriv_rtx','deriv_rty'):
            fun={'frc':'frac','sqrt':'sqrt','rsq':'rsqrt','round_ni':'floor','round_z':'trunc','round_ne':'round','deriv_rtx':'ddx','deriv_rty':'ddy'}[opbase];expr='asuint('+fun+'('+F(0)+'))'
        elif opbase in ('ge','lt','eq','ilt'):
            cmp={'ge':'>=','lt':'<','eq':'==','ilt':'<'}[opbase];lhs,rhs=(I(0),I(1))if opbase=='ilt'else(F(0),F(1));expr='(('+lhs+' '+cmp+' '+rhs+') ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u))'
        elif opbase=='movc':expr='(('+U(0)+' != 0u) ? '+U(1)+' : '+U(2)+')'
        elif opbase=='and':expr='('+U(0)+' & '+U(1)+')'
        elif opbase=='ishr':expr='asuint('+I(0)+' >> ('+U(1)+' & 31u))'
        elif opbase=='iadd':expr='('+U(0)+' + '+U(1)+')'
        elif opbase=='imad':expr='('+U(0)+' * '+U(1)+' + '+U(2)+')'
        elif opbase=='itof':expr='asuint(float4('+I(0)+'))'
        elif opbase=='utof':expr='asuint(float4('+U(0)+'))'
        elif opbase=='ftoi':expr='asuint(int4('+F(0)+'))'
        elif opbase=='ftou':expr='uint4('+F(0)+')'
        elif opbase in ('sample','sample_l','sample_b'):
            coord=source(args[1]);tex,tsw=args[2].split('.');sam=args[3];fun={'sample':'Sample','sample_l':'SampleLevel','sample_b':'SampleBias'}[opbase]
            params=f'{sam}, asfloat({coord}).xy'+(', asfloat('+source(args[4])+').x'if len(args)>4 else'')
            expr=f'asuint({tex}.{fun}({params})).{tsw}'
        elif opbase=='sincos':
            src=source(args[2]);assignment(args[0],'asuint(sin(asfloat('+src+')))',line,str(n)+'s');assignment(args[1],'asuint(cos(asfloat('+src+')))',line,str(n)+'c');continue
        elif opbase=='udiv':
            a,b=source(args[2]),source(args[3]);assignment(args[0],'('+a+' / '+b+')',line,str(n)+'q');assignment(args[1],'('+a+' % '+b+')',line,str(n)+'r');continue
        else:raise ValueError((p['assembly'],line))
        if sat:expr='asuint(saturate(asfloat('+expr+')))'
        assignment(dst,expr,line,n)
    assert indent==1 and not CURRENT_LITERALS and instruction_count==len(raw_instructions)
    headers=['// Register-explicit recovered HLSL. Not original source.','// '+s['name']+' '+stage+' variant '+str(p['keywords']), '// Source SHA256 '+p['sha256']]
    for b in bind['buffers']:headers.append('// b'+str(b['slot'])+': '+b['name']+' '+str(b['bytes'])+' bytes')
    for f in bind['fields']:headers.append('// cb'+str(f['slot'])+'['+str(f['register'])+'].'+f['component']+' = '+f['name']+' rows='+str(f['rows'])+' cols='+str(f['columns'])+' byte_offset='+str(f['offset']))
    for t in bind['textures']:headers.append('// t'+str(t['texture'])+' / s'+str(t['sampler'])+' = '+t['name'])
    # I/O are bit-preserved in uint4; native semantics remain on floating point struct fields.
    istr=['struct Input {']+[f"    float{len(v['mask'])if len(v['mask'])>1 else ''} v{k}_{j}: {v['semantic']};"for k,vs in inputs.items()for j,v in enumerate(vs)]+['};']
    ostr=['struct Output {']+[f"    float{len(v['mask'])if len(v['mask'])>1 else ''} o{k}_{j}: {v['semantic']};"for k,vs in outputs.items()for j,v in enumerate(vs)]+['};']
    bodytext='\n'.join(body)
    init=[f'    uint4 r{k};'for k in range(temps)]+[f'    uint4 out_o{k};'for k in outputs]+[f'    uint4 v{k};'for k in inputs]+[f"    v{k}.{v['mask']} = asuint(input.v{k}_{j});"for k,vs in inputs.items()for j,v in enumerate(vs)]
    end=['    Output result;']+[f"    result.o{k}_{j} = asfloat(out_o{k}.{v['mask']});"for k,vs in outputs.items()for j,v in enumerate(vs)]+['    return result;','}']
    path=OUT/(Path(p['assembly']).stem+'.hlsl');path.write_text('\n'.join(headers+decl+istr+ostr+['Output main(Input input) {']+init+[bodytext]+end)+'\n',encoding='utf8')
    records.append({'shader':s['name'],'source_file':s['source'],'path_id':s['path_id'],'program':p['index'],'stage':stage,'keywords':p['keywords'],'local_keywords':p['local_keywords'],'dxbc_sha256':p['sha256'],'instruction_count':instruction_count,'input':inputs,'output':outputs,'bindings':bind,'raw_instruction_literals':raw_instructions,'hlsl':str(path.relative_to(BASE)),'assembly':p['assembly']})
(OUT/'manifest.json').write_text(json.dumps({'source':'Shipped DXBC assembly + exact token immediate bits + independently parsed Unity program parameter descriptors','programs':records,'opcode_counts':dict(OPCOUNTS),'limitations':['Recompiled instruction ordering/rounding and sampler/image output still require GPU comparison.']},ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({'programs':len(records),'instructions':sum(p['instruction_count']for p in records),'opcodes':len(OPCOUNTS),'binding_fields':sum(len(p['bindings']['fields'])for p in records)}))
