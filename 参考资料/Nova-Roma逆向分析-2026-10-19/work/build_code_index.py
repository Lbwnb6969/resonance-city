"""Inventory derived C# text; counts are reconstruction counts, not original LOC."""
from pathlib import Path
import json, hashlib, re
root=Path(__file__).resolve().parent.parent
items=[]
for group in ('main','firstpass','aqueduct'):
    for p in sorted((root/'work/decompiled'/group).rglob('*.cs')):
        data=p.read_bytes(); s=data.decode('utf-8-sig')
        ns=re.search(r'^namespace ([\w.]+)',s,re.M)
        items.append(dict(assembly_group=group,path=p.relative_to(root).as_posix(),bytes=len(data),lines=len(s.splitlines()),sha256=hashlib.sha256(data).hexdigest(),namespace=ns.group(1) if ns else '<global>',declared_types=len(re.findall(r'^\s*(?:(?:public|private|internal|protected|static|abstract|sealed|readonly|partial|unsafe)\s+)*(?:class|struct|interface|enum)\s+',s,re.M))))
out={'kind':'derived-ilspy-source-inventory','decompiler':'ILSpyCmd 11.1.0.9782','limitations':['File and line counts describe reconstructed C#, not original project files or original lines. Nested/generated types are not equivalent to source files. No original Unity project or compilation validation.'],'assemblies':{},'files':items}
for g in ('main','firstpass','aqueduct'):
    xs=[x for x in items if x['assembly_group']==g]
    out['assemblies'][g]={'files':len(xs),'derived_lines':sum(x['lines'] for x in xs),'derived_bytes':sum(x['bytes'] for x in xs),'largest':sorted(xs,key=lambda x:x['lines'],reverse=True)[:15]}
(root/'outputs/code-index.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:{a:b for a,b in v.items() if a!='largest'} for k,v in out['assemblies'].items()},indent=2))
