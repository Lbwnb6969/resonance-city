from pathlib import Path
import csv, gzip, hashlib, json, re, sys

workspace=Path(__file__).resolve().parent.parent
out=workspace/'outputs'
target=Path(r'D:\SteamLibrary\steamapps\common\Nova Roma')
checks=[]
def check(name,passed,details):
    checks.append({'name':name,'pass':bool(passed),'details':details})

with (out/'file-inventory.csv').open(encoding='utf-8-sig',newline='') as f:
    entries=list(csv.DictReader(f))
changed=[]
for entry in entries:
    p=target/entry['path']
    if not p.is_file(): changed.append({'path':entry['path'],'reason':'missing'}); continue
    h=hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda:f.read(8*1024*1024),b''):h.update(chunk)
    if p.stat().st_size!=int(entry['size']) or h.hexdigest()!=entry['sha256']:
        changed.append({'path':entry['path'],'reason':'content mismatch'})
current={str(p.relative_to(target)) for p in target.rglob('*') if p.is_file()}
initial={entry['path'] for entry in entries}
check('original_game_files_unchanged',not changed and current==initial,{'hashed_files':len(entries),'changed':changed,'added':sorted(current-initial),'missing':sorted(initial-current)})
invalid=[]
for p in sorted(out.glob('*.json')):
    try:json.loads(p.read_text(encoding='utf-8-sig'))
    except Exception as exc:invalid.append({'file':p.name,'error':str(exc)})
check('json_deliverables_parse',not invalid,{'count':len(list(out.glob('*.json'))),'invalid':invalid})
catalog=json.loads(gzip.decompress((out/'unity-object-catalog.json.gz').read_bytes()))
check('compressed_asset_catalog_parse',isinstance(catalog,list),{'records':len(catalog)})
cases=json.loads((out/'solver-cases.json').read_text(encoding='utf-8-sig'))['cases']
check('shipped_solver_controlled_replay',len(cases)==4 and all(c['pass'] for c in cases),{'cases':len(cases),'passed':sum(c['pass'] for c in cases),'boundary':'Pure Roma.Aqueduct DLL under .NET 10; no Unity game execution'})
index=json.loads((out/'code-index.json').read_text(encoding='utf-8'))
bad=[]
for item in index['files']:
    p=workspace/item['path']
    if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest()!=item['sha256']:bad.append(item['path'])
check('decompiled_source_index_matches',not bad,{'files':len(index['files']),'mismatches':bad})
missing_links=[]
for p in out.glob('*.md'):
    for link in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
        if '://' in link or link.startswith('#'):continue
        link=link.split('#')[0].strip('<>')
        if not (p.parent/link).exists():missing_links.append({'document':p.name,'link':link})
check('markdown_file_links_exist',not missing_links,{'missing':missing_links})
bundle=json.loads((out/'rea-evidence.json').read_text(encoding='utf-8'))
check('rea_evidence_bundle_retained',len(bundle['records'])==5,{'records':len(bundle['records']),'note':'Includes main-member resource-limit failure; unknowns array is not a completeness claim'})
result={'scope':'Analysis deliverables and original-file integrity','checks':checks,'all_pass':all(c['pass'] for c in checks)}
(out/'validation-results.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
sys.exit(0 if result['all_pass'] else 1)
