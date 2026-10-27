"""Minimal independent source/frontier and original-render hash checks."""
from pathlib import Path
import hashlib,json,re
BASE=Path(__file__).resolve().parent.parent;OUT=BASE/'outputs'
g=json.loads((OUT/'townscaper_native_graph.json').read_text(encoding='utf8'))
nodes={int(n['rva'],16):n for n in g['nodes']};refs=set()
for n in nodes.values():
    p=BASE/n['source'];data=p.read_bytes();assert hashlib.sha256(data).hexdigest()==n['source_sha256']
    for s in re.findall(r'\bFUN_([0-9A-Fa-f]{8})\b',data.decode('utf8')):
        va=int(s,16)
        if 0x10000000<=va<0x11500000:refs.add(va-0x10000000)
assert refs-set(nodes)==set(map(lambda s:int(s,16),g['remaining_anonymous_function_frontier']))==set()
assert len(refs)==g['counts']['anonymous_referenced_unique_rvas']
assert 0x417f85 in nodes and (BASE/nodes[0x417f85]['source']).is_file()
v=json.loads((OUT/'townscaper_runtime_render_verification.json').read_text(encoding='utf8'))
assert v['graphics_backend']=='Direct3D 11' and all(v['checks'].values())
for f in v['frames']:
    assert hashlib.sha256((OUT/f['file']).read_bytes()).hexdigest()==f['sha256']
    assert f['size']==[2560,1440] and f['distinct_rgb_colors']>1
links=0
for name in ['townscaper_shaders.md','townscaper_shader_algorithms.md']:
    doc=OUT/name
    for link in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf8')):
        if link.startswith(('https://','http://')):continue
        assert (doc.parent/link).exists(),link;links+=1
result={'native_unique_sources_hashed':len(nodes),'anonymous_targets_with_body':len(refs),'input_mode_tail_source':nodes[0x417f85]['source'],'original_d3d11_frames_hashed':len(v['frames']),'shader_report_local_links':links,'limits':'Named external runtime dependencies and indirect calls are outside anonymous closure. Original D3D11 frames are not recompiled HLSL pixel-equivalence tests.'}
(OUT/'townscaper_frontier_render_verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8');print(json.dumps(result))
