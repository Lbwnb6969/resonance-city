"""Read one recovered address or search retained strings/RTTI without loading all code.
Usage: python read_native.py function 0x140128170
       python read_native.py strings GamCLuaManager
       python read_native.py types GamCAssetManager
"""
from pathlib import Path
import sys,gzip,json,csv
root=Path(__file__).resolve().parent
def records(name):
 with gzip.open(root/name,'rt',encoding='utf-8') as f:
  for line in f:yield json.loads(line)
def function(address):
 address=hex(int(address,16))
 indexes=['pseudocode-retry-address-index.csv','pseudocode-complete-address-index.csv','pseudocode-address-index.csv','pseudocode-resume-index.csv']
 for name in indexes:
  path=root/name
  if not path.exists():continue
  with path.open(newline='',encoding='utf-8') as f:
   for row in csv.DictReader(f):
    if row['entry']==address:
     for i,record in enumerate(records(row['shard'])):
      if i==int(row['line']):
       print(json.dumps({k:v for k,v in record.items() if k!='pseudocode'},indent=2,ensure_ascii=False));print(record.get('pseudocode',''));return
 print('Address not present in retained decompiler index. Try the containing range from all-pdata-ranges.jsonl.gz.')
def search(kind,value):
 name='all-ascii-strings.jsonl.gz' if kind=='strings' else 'rtti-vtables.jsonl.gz'
 count=0
 for record in records(name):
  if value.lower() in str(record.get('value',record.get('mangled_type',''))).lower():print(json.dumps(record,ensure_ascii=False));count+=1
 print('matches:',count)
if __name__=='__main__':
 if len(sys.argv)!=3 or sys.argv[1] not in ['function','strings','types']:raise SystemExit(__doc__)
 if sys.argv[1]=='function':function(sys.argv[2])
 else:search(sys.argv[1],sys.argv[2])
