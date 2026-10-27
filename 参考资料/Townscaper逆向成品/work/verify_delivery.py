"""Check the new central deliverable, source links and observed invariants."""
import json
import hashlib
import re
from pathlib import Path

root=Path(__file__).resolve().parents[1]
out=root/'outputs'
names=['townscaper_complete_index.md','townscaper_wire_ground_workflows.md','townscaper_ui_material_workflows.md','townscaper_remaining_audit.md','townscaper_platform.md','townscaper_sandbank_smoothing.md','townscaper_sandbank_slopes.md','townscaper_shore_local_math.md','townscaper_sandbank_water_math.md']
count=0
errors=[]
for name in names:
    file=out/name
    for target in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)',file.read_text(encoding='utf-8')):
        if target.startswith(('http:','https:','#')):continue
        target=target.strip('<>')
        match=re.match(r'^(.*?):(\d+)$',target)
        line=int(match.group(2)) if match else None
        target=match.group(1) if match else target
        path=Path(target) if re.match(r'^[A-Za-z]:[/\\]',target) else file.parent/target
        if not path.exists():errors.append([name,target,'missing'])
        elif line and len(path.read_text(encoding='utf-8').splitlines())<line:errors.append([name,target,'invalid line'])
        count+=1
assert not errors,errors
parsed=[]
for name in ('townscaper_native_graph.json','townscaper_shader_algorithms/verification.json','townscaper_runtime_render_verification.json','townscaper_integrity_verification.json','townscaper_runtime_grid_verification.json','townscaper_runtime_boundaries.json','townscaper_graph_load_fixtures.json','townscaper_runtime_graphics.json'):
    parsed.append(json.loads((out/name).read_text(encoding='utf-8')))
graph,shader,render,integrity,grid,bounds,fixtures,graphics=parsed
assert graph['counts']['business_platform_rvas']==graph['counts']['exported_selected_rvas']==2087
assert graph['counts']['anonymous_references_without_body']==0
assert shader['programs']==84 and shader['matching_original_recompiled_interfaces']==168
assert all(render['checks'].values())
assert integrity['existing_user_files_unchanged'] and integrity['registry_unchanged'] and all(x['unchanged'] for x in integrity['game_binaries'])
assert graphics['scenario']['checks']['undo_restores'] and graphics['scenario']['generation_checks']['undo_restores_modules']
asset_manifest=json.loads((out/'townscaper_extracted_assets/index.json').read_text(encoding='utf-8'))
asset_outputs=0
for record in asset_manifest['records']:
    for item in record.get('outputs',[]):
        data=(out/'townscaper_extracted_assets'/item['file']).read_bytes()
        assert len(data)==item['bytes'] and hashlib.sha256(data).hexdigest()==item['sha256'],item['file']
        asset_outputs+=1
result={'documents':names,'local_links_checked':count,'missing_or_invalid_links':errors,'native_business_coverage':2087,'native_unique_functions':graph['counts']['all_exported_unique_rvas'],'shader_programs_compiled':84,'shader_io_interfaces_matching':168,'original_render_frames':len(render['frames']),'extracted_asset_files_hash_verified':asset_outputs,'original_files_and_registry_unchanged':True,'scope':'Artifact link/invariant validation, reuses preserved original runtime and compiler evidence; no new game execution and no claim of all inputs/pixel equivalence.'}
(out/'townscaper_delivery_verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({k:v for k,v in result.items() if k not in ('documents','scope')}))
