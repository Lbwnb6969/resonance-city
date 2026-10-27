"""Validate retained shader bytes and local evidence links; archive first-pass artifacts."""
from pathlib import Path
import re,json,hashlib,struct,shutil
BASE=Path(__file__).resolve().parent.parent
ROOT=BASE/'outputs/townscaper_shader_programs'
stale=[p for p in ROOT.iterdir() if re.search(r'__\d+__\.parsed\.json$',p.name) or re.match(r'^(resources|sharedassets\d+|unity_builtin_extra|unity default resources)\.(dxbc|asm|program\.bin)$',p.name)]
dest=BASE/'discarded/shader-first-export-incorrect-prefix'
dest.mkdir(parents=True,exist_ok=True)
for p in stale:
    target=dest/p.name
    assert not target.exists(),target
    shutil.move(str(p),str(target))
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'))
programs=[p for s in manifest for p in s['programs']]
assert len(programs)==525 and all(p['disassembled'] for p in programs)
for p in programs:
    asm=BASE/p['assembly'];dxbc=asm.with_suffix('.dxbc').read_bytes()
    assert len(dxbc)==p['dxbc_bytes']==struct.unpack_from('<I',dxbc,24)[0]
    assert hashlib.sha256(dxbc).hexdigest()==p['sha256']
    assert re.search(r'^(?:vs|ps|gs|hs|ds|cs)_\d_\d$',asm.read_text(encoding='utf8'),re.M),asm
links=0
for name in ['townscaper_generation.md','townscaper_shaders.md','townscaper_prop_configurations.md']:
    doc=BASE/'outputs'/name
    for ref in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf8')):
        path=Path(ref.rsplit(':',1)[0]) if re.search(r':\d+$',ref) else Path(ref)
        if not path.is_absolute():path=doc.parent/path
        assert path.exists(),(doc,ref)
        links+=1
props=json.loads((BASE/'outputs/townscaper_prop_configurations.json').read_text(encoding='utf8'))
assert len(props['components'])==427
assert props['counts']['PropCollider']==154 and props['counts']['PropNode']==159
print(json.dumps({'dxbc_sha256_and_length_verified':len(programs),'report_links_verified':links,'props_verified':427,'stale_archived':len(stale)}))
