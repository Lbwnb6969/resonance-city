"""Index recovered native bodies and preserve ambiguous IL2CPP address aliases."""
import csv
import hashlib
import json
import re
from pathlib import Path

root=Path(__file__).resolve().parents[1]
inventory=json.loads((root/'outputs/townscaper_method_inventory.json').read_text(encoding='utf-8'))
methods=json.loads((root/'work/reverse/il2cpp/script.json').read_text(encoding='utf-8'))['ScriptMethod']
aliases={}
for method in methods:aliases.setdefault(method['Address'],[]).append(method['Name'])
nodes={}
edges=[]
anonymous_references={}
export_files=0
for path in sorted((root/'outputs').glob('native_*/*.c')):
    export_files+=1
    rva=int(path.stem,16)
    if rva in nodes:continue
    source=path.read_text(encoding='utf-8')
    assert int(re.search(r'^// RVA (0x[0-9a-fA-F]+)',source).group(1),16)==rva,path
    node={'rva':hex(rva),'va':hex(rva+0x10000000),'aliases':aliases.get(rva,[]),'source':str(path.relative_to(root)).replace('\\','/'),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'pdb_name':source.splitlines()[1].removeprefix('// PDB: '),'lines':len(source.splitlines())}
    nodes[rva]=node
    header=source.split('\n\n',1)[0]
    for address,name in re.findall(r'^// ([0-9a-fA-F]{8}) (.+)$',header,re.M):
        target=int(address,16)-0x10000000
        edges.append({'from':hex(rva),'to':hex(target),'pdb_name':name,'relation':'ghidra_direct_callee','resolution_limit':'Static provider direct references; shared aliases are not uniquely selected and execution is not observed.'})
    for address in re.findall(r'\bFUN_([0-9a-fA-F]{8})\b',source):
        target=int(address,16)-0x10000000
        if 0<=target<0x1500000:
            anonymous_references.setdefault(target,set()).add(rva)
for edge in edges:
    target=int(edge['to'],16)
    edge['body_exported']=target in nodes
    edge['aliases']=aliases.get(target,[])
selected={int(row['rva'],16) for name in ['townscaper_application_methods.tsv','townscaper_platform_methods.tsv'] for row in csv.DictReader((root/'outputs'/name).open(encoding='utf-8'),delimiter='\t')}
missing=sorted(selected-set(nodes))
anonymous_frontier=sorted(set(anonymous_references)-set(nodes))
result={'provenance':'Saved Ghidra/PDB exports plus IL2CPP address aliases; not new REA Evidence','counts':{'business_platform_rvas':len(selected),'exported_selected_rvas':len(selected-set(missing)),'all_exported_unique_rvas':len(nodes),'static_direct_edges':len(edges),'outside_export_edge_count':sum(not e['body_exported'] for e in edges)},'missing_selected':list(map(hex,missing)),'remaining_anonymous_function_frontier':list(map(hex,anonymous_frontier)),'nodes':list(nodes.values()),'edges':edges,'limits':['Dependencies not exported include Unity/.NET/native runtime helpers. This index does not establish vtable/interface/generic call targets or runtime reachability.','Generated C is pseudocode, not compilable original source. PDB/IL2CPP names sharing one address remain aliases.']}
result['counts'].update({'export_files':export_files,'anonymous_referenced_unique_rvas':len(anonymous_references),'anonymous_references_without_body':len(anonymous_frontier)})
result['anonymous_reference_audit']=[{'rva':hex(target),'body_exported':target in nodes,'referrer_rvas':list(map(hex,sorted(referrers)))} for target,referrers in sorted(anonymous_references.items())]
result['closure_scope']={'selected_methods_complete':not missing,'referenced_anonymous_functions_complete':not anonymous_frontier,'all_direct_dependencies_complete':all(e['body_exported'] for e in edges),'definition':'Anonymous closure means every FUN_XXXXXXXX token referenced by the retained pseudocode/header within VA 0x10000000..0x11500000 has an exact RVA export across ALL outputs/native_* directories. It does not mean that named Unity/.NET/native dependencies, indirect calls or all executable code have been recovered.','input_mode_manager_tail':{'rva':'0x417f85','source':nodes.get(0x417f85,{}).get('source'),'body_exported':0x417f85 in nodes}}
(root/'outputs/townscaper_native_graph.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'counts':result['counts'],'missing_selected':result['missing_selected'],'anonymous_frontier':result['remaining_anonymous_function_frontier']}))
