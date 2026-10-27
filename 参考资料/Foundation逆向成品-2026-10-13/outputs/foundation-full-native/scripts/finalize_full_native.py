from pathlib import Path
import json,gzip,csv,collections,hashlib,shutil
root=Path.cwd();out=root/'outputs/foundation-full-native';work=root/'work/full-native'
def records(name):
 with gzip.open(out/name,'rt',encoding='utf-8') as f:
  for line in f:yield json.loads(line)
initial=json.loads((out/'decompile-coverage.json').read_text());stats=collections.Counter(initial['status_counts']);failures={r['entry']:r for r in json.loads((out/'decompile-failures.json').read_text())};retry=[]
if (out/'pseudocode-retry.jsonl.gz').exists():
 for r in records('pseudocode-retry.jsonl.gz'):
  retry.append({'entry':r['entry'],'status':r['status'],'error':r.get('error',''),'timeout_seconds':r['timeout_seconds']})
  if r['status']=='complete':original=failures.pop(r['entry'],None);stats['complete']+=1;stats[original['status'] if original else 'failed']-=1
inventory=json.loads((out/'inventory.json').read_text());decode=json.loads((out/'decode-coverage.json').read_text());expected='2c0a048bc1fa2791f58ea432b85cbd9b816af0efec6d6d1c0be6c12195da31af';actual=hashlib.sha256(Path(inventory['artifact']).read_bytes()).hexdigest();assert actual==expected==inventory['sha256']
assert initial['unique_decompilation_records']==decode['recovered_function_entries']
assert decode['byte_partition_closed']
assert len(list(records('all-pdata-ranges.jsonl.gz')))==160598
index=[]
for name in ['pseudocode-address-index.csv','pseudocode-resume-index.csv']:
 if (out/name).exists():
  with (out/name).open(newline='',encoding='utf-8') as f:index.extend(csv.DictReader(f))
assert len(index)==len({r['entry'] for r in index})==initial['unique_decompilation_records']
with (out/'pseudocode-complete-address-index.csv').open('w',newline='',encoding='utf-8') as f:
 w=csv.DictWriter(f,fieldnames=['entry','shard','line','status','body_bytes']);w.writeheader();w.writerows(sorted(index,key=lambda r:int(r['entry'],16)))
final={'artifact':inventory['artifact'],'sha256':actual,'text_byte_partition_closed':True,'function_records':initial['unique_decompilation_records'],'final_status_counts':dict(stats),'retry_records':retry,'remaining_decompile_failures':list(failures.values()),'code_coverage':decode,'rtti':{k:inventory[k] for k in ['rtti_type_descriptors','verified_complete_object_locators','vtable_candidates']},'runtime_target_execution':False,'limitations':['C output is Ghidra pseudo-source, not original/recompilable source.','31,060 chained unwind ranges remain fragments rather than merged original functions.','Unassigned .text bytes retained verbatim; meaningful code/data classification not established for all remaining bytes.','All call instructions are exported but indirect call target resolution is incomplete.','Recovered vtable boundaries and original types/variable names remain partially unknown.']}
final['analysis_profile']={'ghidra_version':'12.1.4 PUBLIC','jdk_version':'21.0.12.1+1','headless_heap':'8G','default_autoanalysis':False,'bounded_workers':8,'first_pass_function_timeout_seconds':8,'retry_function_timeout_seconds':45,'source_mapping':'preferred PE ImageBase 0x140000000; exact .pdata RUNTIME_FUNCTION ranges plus disassembly-bounded leaf candidates','evidence_origin':'Local execution-free Ghidra supplement following REA skill; not new retained REA Evidence IDs.','global_tool_settings_modified':False}
(out/'final-coverage.json').write_text(json.dumps(final,indent=2),encoding='utf-8')
scripts=out/'scripts';scripts.mkdir(exist_ok=True)
for name in ['prepare_full_native.py','FullNativeRecover.java','run_full_native.ps1','reproduce_full_native.ps1','summarize_full_native.py','finalize_full_native.py','verify_text_bytes.py','inventory_installed_pe.py','RecoverSocket.java']:
 shutil.copy2(work/name,scripts/name)
for name in ['decode-console.log','supplement-console.log','decompile-console.log','retry-console.log','socket-console.log']:
 if (work/name).exists():shutil.copy2(work/name,scripts/name)
manifest=[]
for p in sorted(out.rglob('*')):
 if p.is_file() and p.name!='native-output-sha256.json':manifest.append({'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(out/'native-output-sha256.json').write_text(json.dumps({'input_sha256':actual,'files':manifest,'scope':'Files present at full native investigation completion; later database archives should preserve separate hashes.'},indent=2),encoding='utf-8')
print(json.dumps({'functions':final['function_records'],'final_status_counts':dict(stats),'remaining_failures':len(failures),'files':len(manifest),'output_bytes':sum(p['bytes'] for p in manifest),'input_sha256_unchanged':actual==expected},indent=2))
