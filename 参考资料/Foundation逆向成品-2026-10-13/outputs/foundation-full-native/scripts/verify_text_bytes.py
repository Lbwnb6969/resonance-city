from pathlib import Path
import json,gzip,hashlib,time
root=Path.cwd();out=root/'outputs/foundation-full-native';inventory=json.loads((out/'inventory.json').read_text());raw=Path(inventory['artifact']).read_bytes();assert hashlib.sha256(raw).hexdigest()==inventory['sha256']
textva=0x140001000;fileoff=1024;textsize=46543712
count=0;insbytes=0;gapbytes=0;seen=bytearray(textsize);start=time.time()
for name,kind in [('all-text-instructions.jsonl.gz','instruction'),('unassigned-text-byte-ranges.jsonl.gz','unassigned')]:
 with gzip.open(out/name,'rt',encoding='utf-8') as f:
  for l in f:
   r=json.loads(l);a=int(r['va'] if kind=='instruction' else r['start'],16);data=bytes.fromhex(r['bytes']);p=a-textva
   assert 0<=p<p+len(data)<=textsize
   assert raw[fileoff+p:fileoff+p+len(data)]==data,(hex(a),'input bytes differ')
   assert not any(seen[p:p+len(data)]),(hex(a),'overlap')
   seen[p:p+len(data)]=b'\1'*len(data)
   if kind=='instruction':count+=1;insbytes+=len(data)
   else:gapbytes+=len(data)
assert all(seen),'uncovered .text bytes'
record={'input_sha256':inventory['sha256'],'text_file_offset':fileoff,'text_va':hex(textva),'text_bytes':textsize,'instruction_records_verified':count,'instruction_bytes_verified':insbytes,'unassigned_bytes_verified':gapbytes,'all_exported_bytes_match_original':True,'no_overlaps':True,'complete_text_byte_coverage':True,'elapsed_seconds':round(time.time()-start,3),'scope':'All exported text instruction and gap bytes were independently compared to the original PE file. This verifies lossless byte capture, not decompiler semantic correctness.'}
(out/'text-bytes-verification.json').write_text(json.dumps(record,indent=2),encoding='utf-8');print(json.dumps(record,indent=2))
