from pathlib import Path
import json,gzip,csv,hashlib,collections,re
root=Path.cwd();out=root/'outputs/foundation-full-native';work=root/'work/full-native'
def rows(path):
 with gzip.open(path,'rt',encoding='utf-8') as f:
  for l in f:yield json.loads(l)
seen=set();stats=collections.Counter();errors=[];warnings=collections.Counter();shards=[]
for p in sorted(out.glob('pseudocode-[0-9]*.jsonl.gz')):
 count=0;ok=0;codes=0
 for r in rows(p):
  assert r['entry'] not in seen,r['entry'];seen.add(r['entry']);count+=1;stats[r['status']]+=1
  if r['status']=='complete':ok+=1
  else:errors.append({'entry':r['entry'],'status':r['status'],'shard':p.name,'line':count-1,'error':r.get('error',''),'body_bytes':r['body_bytes']})
  text=r.get('pseudocode','');codes+=len(text.encode());
  for warning in re.findall(r'/\* WARNING:(.*?)\*/',text,re.S):warnings[warning.strip()]+=1
 shards.append({'file':p.name,'records':count,'completed':ok,'uncompressed_c_bytes':codes,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
summary={'unique_decompilation_records':len(seen),'status_counts':dict(stats),'failed_records':len(errors),'warning_counts':dict(warnings),'shards':shards,'limits':'complete means Ghidra emitted C pseudocode, not semantic correctness or recovery of original source/types; unwind fragment pseudo-functions remain classified.'}
(out/'decompile-coverage.json').write_text(json.dumps(summary,indent=2),encoding='utf-8');(out/'decompile-failures.json').write_text(json.dumps(errors,indent=2),encoding='utf-8');(work/'retry-addresses.tsv').write_text(''.join(r['entry']+'\n' for r in errors),encoding='utf-8');print(json.dumps({'count':len(seen),'stats':dict(stats),'failures':len(errors),'top_errors':collections.Counter(r['error'] for r in errors).most_common(10)},indent=2))
