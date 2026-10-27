from pathlib import Path
import struct,json,re,hashlib,bisect,csv,gzip
root=Path.cwd();out=root/'outputs/foundation-full-native';out.mkdir(parents=True,exist_ok=True);work=root/'work/full-native';work.mkdir(exist_ok=True)
path=Path(r'D:\steamtest\steamapps\common\Foundation\foundation.exe');b=path.read_bytes();sha=hashlib.sha256(b).hexdigest()
layout=json.loads((root/'outputs/foundation-package-evidence/foundation-exe-pe-layout.json').read_text());base=int(layout['image_base'],16);sections=layout['sections']
def offva(off):
 for s in sections:
  if s['raw_offset']<=off<s['raw_offset']+s['raw_size']:return base+s['rva']+off-s['raw_offset']
def vaoff(va):
 for s in sections:
  if base+s['rva']<=va<base+s['rva']+s['raw_size']:return s['raw_offset']+va-base-s['rva']
def u32(off):return struct.unpack_from('<I',b,off)[0]
pd=next(s for s in sections if s['name']=='.pdata');functions=[]
for off in range(pd['raw_offset'],pd['raw_offset']+pd['virtual_size']-11,12):
 a,e,u=struct.unpack_from('<III',b,off)
 if not a or e<=a:continue
 rec={'entry':hex(base+a),'end_exclusive':hex(base+e),'unwind':hex(base+u),'pdata_file_offset':off,'bytes':e-a}
 try:
  uw=vaoff(base+u);vflags,prolog,count,frame=struct.unpack_from('<BBBB',b,uw);flags=vflags>>3
  rec.update(unwind_version=vflags&7,unwind_flags=flags,prolog_bytes=prolog,unwind_code_slots=count)
  pos=uw+4+((count+1)&~1)*2
  if flags&4:
   ca,ce,cu=struct.unpack_from('<III',b,pos);rec['classification']='chained_unwind_fragment';rec['chain_parent_entry']=hex(base+ca);rec['chain_parent_end']=hex(base+ce)
  elif flags&3:rec['classification']='exception_handler_range';rec['handler_entry']=hex(base+u32(pos))
  else:rec['classification']='runtime_function_range'
 except Exception as exc:rec['classification']='unwind_unresolved';rec['error']=str(exc)
 functions.append(rec)
functions.sort(key=lambda r:int(r['entry'],16));starts=[int(r['entry'],16) for r in functions]
def owner(a):
 i=bisect.bisect_right(starts,a)-1
 return functions[i]['entry'] if i>=0 and a<int(functions[i]['end_exclusive'],16) else None
with gzip.open(out/'all-pdata-ranges.jsonl.gz','wt',encoding='utf-8') as f:
 for r in functions:f.write(json.dumps(r)+'\n')
(work/'all-ranges.tsv').write_text(''.join(r['entry']+'\t'+r['end_exclusive']+'\t'+r['classification']+'\n' for r in functions),encoding='utf-8')
# MSVC x64 complete-object locators contain image-relative type descriptors.
td={};rd=next(s for s in sections if s['name']=='.rdata');low=rd['raw_offset'];high=low+rd['raw_size']
for m in re.finditer(rb'\.\?A[VU][^\x00]{2,500}\x00',b):
 off=m.start();mapped=offva(off)
 if mapped:a=mapped-16;td[a]={'type_descriptor':hex(a),'mangled_type':m.group()[:-1].decode('ascii','replace')}
cols={};types=[]
for off in range(low,high-24,4):
 if u32(off)!=1:continue
 sig,offset,cd,typ,ch,selfr=struct.unpack_from('<IIIIII',b,off);a=offva(off)
 if base+selfr!=a or base+typ not in td:continue
 row={'complete_object_locator':hex(a),'object_offset':offset,'constructor_displacement':cd,**td[base+typ],'class_hierarchy':hex(base+ch)}
 try:
  cho=vaoff(base+ch);hs,hattr,hcount,harr=struct.unpack_from('<IIII',b,cho);row['hierarchy_attributes']=hattr;row['base_class_count']=hcount;bases=[]
  if hcount<1000:
   ao=vaoff(base+harr)
   for j in range(hcount):
    bd=base+u32(ao+j*4);bo=vaoff(bd);bt,num,mdisp,pdisp,vdisp,attr=struct.unpack_from('<IIiiiI',b,bo)
    bases.append({'descriptor':hex(bd),'type_descriptor':hex(base+bt),'mangled_type':td.get(base+bt,{}).get('mangled_type'),'contained_bases':num,'member_displacement':mdisp,'vbtable_displacement':pdisp,'vbase_displacement':vdisp,'attributes':attr})
  row['bases']=bases
 except Exception as exc:row['hierarchy_error']=str(exc)
 cols[a]=row
for off in range(low,high-16,8):
 col=struct.unpack_from('<Q',b,off)[0]
 if col not in cols:continue
 slots=[]
 for j in range(1,501):
  p=off+j*8
  if p+8>high:break
  dest=struct.unpack_from('<Q',b,p)[0]
  text=sections[0]
  if not base+text['rva']<=dest<base+text['rva']+text['virtual_size']:break
  slots.append({'slot':j-1,'pointer_va':hex(offva(p)),'target':hex(dest),'pdata_owner':owner(dest)})
 if slots:types.append({**cols[col],'vtable':hex(offva(off+8)),'slots':slots,'slot_boundary':'Contiguous text pointers until first non-text pointer; may include adjacent tables; max 500.'})
with gzip.open(out/'rtti-vtables.jsonl.gz','wt',encoding='utf-8') as f:
 for row in types:f.write(json.dumps(row)+'\n')
leaf_targets={s['target'] for row in types for s in row['slots'] if not s['pdata_owner']}
(work/'vtable-leaf-targets.tsv').write_text(''.join(a+'\n' for a in sorted(leaf_targets)),encoding='utf-8')
strs=[]
for m in re.finditer(rb'[\x20-\x7e]{5,}',b):
 if len(m.group())<=2000:
  va=offva(m.start())
  if va:strs.append({'va':hex(va),'file_offset':m.start(),'value':m.group().decode()})
with gzip.open(out/'all-ascii-strings.jsonl.gz','wt',encoding='utf-8') as f:
 for row in strs:f.write(json.dumps(row)+'\n')
counts={x:sum(r['classification']==x for r in functions) for x in sorted({r['classification'] for r in functions})}
meta={'artifact':str(path),'sha256':sha,'image_base':hex(base),'pdata_records':len(functions),'classification_counts':counts,'pdata_code_bytes_sum':sum(r['bytes'] for r in functions),'text_virtual_bytes':sections[0]['virtual_size'],'rtti_type_descriptors':len(td),'verified_complete_object_locators':len(cols),'vtable_candidates':len(types),'ascii_strings':len(strs),'limits':['MSVC RTTI parsing is static and uses exact self-image-relative COL checks.','Contiguous pointer vtable boundary is a candidate, not recovered original class definition.','Runtime function and chained EH ranges are not guaranteed one original C++ function each.']}
(out/'inventory.json').write_text(json.dumps(meta,indent=2),encoding='utf-8');print(json.dumps(meta,indent=2))
