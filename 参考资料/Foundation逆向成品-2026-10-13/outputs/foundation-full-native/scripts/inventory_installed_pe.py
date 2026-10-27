from pathlib import Path
import struct,json,hashlib,re
root=Path.cwd();out=root/'outputs/foundation-full-native';install=Path(r'D:\steamtest\steamapps\common\Foundation');results=[]
for p in sorted(install.rglob('*')):
 if not p.is_file() or p.suffix.lower() not in ['.exe','.dll']:continue
 b=p.read_bytes();u16=lambda o:struct.unpack_from('<H',b,o)[0];u32=lambda o:struct.unpack_from('<I',b,o)[0];u64=lambda o:struct.unpack_from('<Q',b,o)[0];pe=u32(0x3c);assert b[pe:pe+4]==b'PE\0\0';op=pe+24;magic=u16(op);x64=magic==0x20b;base=u64(op+24) if x64 else u32(op+28);ds=op+(112 if x64 else 96);ss=op+u16(pe+20);secs=[]
 for i in range(u16(pe+6)):
  s=ss+40*i;secs.append({'name':b[s:s+8].split(b'\0')[0].decode(),'rva':u32(s+12),'virtual_size':u32(s+8),'file_offset':u32(s+20),'file_bytes':u32(s+16),'characteristics':hex(u32(s+36))})
 def off(rva):
  if rva<u32(op+60):return rva
  for s in secs:
   if s['rva']<=rva<s['rva']+s['file_bytes']:return s['file_offset']+rva-s['rva']
  raise ValueError(hex(rva))
 def z(o):return b[o:b.index(0,o)].decode('ascii','replace')
 dirs=[{'rva':u32(ds+i*8),'size':u32(ds+i*8+4)} for i in range(min(u32(op+(108 if x64 else 92)),16))]
 imports=[]
 if dirs[1]['rva']:
  at=off(dirs[1]['rva'])
  while any(b[at:at+20]):
   orig,ts,fwd,name,first=struct.unpack_from('<IIIII',b,at);th=off(orig or first);syms=[];i=0
   while val:=(u64(th+i*8) if x64 else u32(th+i*4)):
    s={'iat_va':hex(base+first+i*(8 if x64 else 4))}
    if val&(1<<(63 if x64 else 31)):s['ordinal']=val&65535
    else:s['name']=z(off(val)+2);s['hint']=u16(off(val))
    syms.append(s);i+=1
   imports.append({'dll':z(off(name)),'symbols':syms});at+=20
 exports=[]
 if dirs[0]['rva']:
  at=off(dirs[0]['rva']);ec,ts,maj,minv,en,ordinalbase,nfun,nname,af,an,ao=struct.unpack_from('<IIHHIIIIIII',b,at);names={}
  for i in range(nname):names.setdefault(u16(off(ao)+2*i),[]).append(z(off(u32(off(an)+4*i))))
  for i in range(nfun):
   rva=u32(off(af)+4*i)
   if not rva:continue
   r={'ordinal':ordinalbase+i,'rva':hex(rva),'va':hex(base+rva),'names':names.get(i,[])}
   if dirs[0]['rva']<=rva<dirs[0]['rva']+dirs[0]['size']:r['forwarder']=z(off(rva))
   exports.append(r)
 debug=[]
 if len(dirs)>6 and dirs[6]['rva']:
  at=off(dirs[6]['rva'])
  for i in range(dirs[6]['size']//28):
   dc,ts,ma,mi,typ,size,addr,ptr=struct.unpack_from('<IIHHIIII',b,at+i*28);d={'type':typ,'bytes':size,'file_offset':ptr,'sha256':hashlib.sha256(b[ptr:ptr+size]).hexdigest()}
   if typ==2 and b[ptr:ptr+4]==b'RSDS':d.update(codeview_signature='RSDS',guid_bytes=b[ptr+4:ptr+20].hex(),age=u32(ptr+20),pdb_path=z(ptr+24))
   debug.append(d)
 cert=[]
 if len(dirs)>4 and dirs[4]['rva']:
  at=dirs[4]['rva'];end=at+dirs[4]['size']
  while at+8<=end:
   length,rev,typ=struct.unpack_from('<IHH',b,at)
   if length<8:break
   cert.append({'file_offset':at,'bytes':length,'revision':hex(rev),'certificate_type':typ,'sha256':hashlib.sha256(b[at:at+length]).hexdigest(),'verification':'Certificate blob inventoried; Authenticode trust/signature validity not evaluated.'});at+=(length+7)&~7
 strings=[]
 for m in re.finditer(rb'[\x20-\x7e]{5,300}',b):
  s=m.group().decode()
  if re.search('LuaSocket|Lua 5|FFmpeg|Copyright|CrashRpt|pthread|zlib|Valve|Steamworks',s,re.I):strings.append({'file_offset':m.start(),'value':s})
 record={'relative_path':p.relative_to(install).as_posix(),'artifact':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b),'machine':hex(u16(pe+4)),'format':'PE32+' if x64 else 'PE32','role':'dll' if u16(pe+22)&0x2000 else 'exe','image_base':hex(base),'entry_va':hex(base+u32(op+16)),'timestamp':u32(pe+8),'sections':secs,'data_directories':dirs,'managed_cli_present':len(dirs)>14 and dirs[14]['rva']!=0,'imports':imports,'exports':exports,'debug_records':debug,'certificate_records':cert,'static_identity_strings':strings,'scope':'Execution-free PE header/regular imports/export/debug/security-directory parse; regular import list excludes delay imports. No claim of signature trust or runtime DLL loading.'}
 results.append(record)
 (out/('component-'+p.name+'.json')).write_text(json.dumps(record,indent=2),encoding='utf-8')
summary={'root':str(install),'pe_count':len(results),'exe_count':sum(r['role']=='exe' for r in results),'dll_count':sum(r['role']=='dll' for r in results),'components':[{'path':r['relative_path'],'sha256':r['sha256'],'bytes':r['bytes'],'machine':r['machine'],'image_base':r['image_base'],'exports':len(r['exports']),'imports':sum(len(d['symbols']) for d in r['imports']),'managed':r['managed_cli_present'],'debug_records':len(r['debug_records']),'certificates':len(r['certificate_records'])} for r in results]}
(out/'installed-pe-components.json').write_text(json.dumps(summary,indent=2),encoding='utf-8');print(json.dumps(summary,indent=2))
