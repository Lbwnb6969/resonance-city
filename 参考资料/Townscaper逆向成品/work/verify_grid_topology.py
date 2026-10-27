"""Validate report references and original-byte bindings; this is not a runtime test."""
from pathlib import Path
import hashlib, json, re, struct, sys

root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root/'work/pydeps'))
import pefile

report_path = root/'outputs/townscaper_grid_topology.md'
links = re.findall(r'\]\((C:/[^)]+)\)', report_path.read_text(encoding='utf8'))
for link in links:
    match = re.match(r'^(.*):(\d+)$', link)
    path = Path(match[1] if match else link)
    assert path.is_file(), link
    if match:
        assert 1 <= int(match[2]) <= len(path.read_text(encoding='utf8').splitlines()), link

math = json.loads((root/'outputs/townscaper_grid_math.json').read_text(encoding='utf8'))
target = Path(math['target'])
assert hashlib.sha256(target.read_bytes()).hexdigest() == math['target_sha256']
pe = pefile.PE(str(target))
assert len(math['ranges']) == 12
for record in math['ranges']:
    data = pe.get_data(int(record['rva'],16),record['size'])
    assert data.hex() == record['bytes'], record['name']
    assert hashlib.sha256(data).hexdigest() == record['sha256'], record['name']

library = json.loads((root/'outputs/townscaper_grid_library.json').read_text(encoding='utf8'))
assert library['validation']['patches_validated'] == 40
assert library['validation']['disk_euler_all_1']
assert library['validation']['no_nonmanifold_edges']
assert library['validation']['all_selectors_in_range_or_255']
result = {'report':str(report_path),'file_links_validated':len(links),
          'raw_ranges_verified':len(math['ranges']),'original_pe_sha256_matched':True,
          'topology_validation':library['validation'],
          'collider_y_constants':{'0xbf333333':struct.unpack('<f',bytes.fromhex('333333bf'))[0],
                                  '0x3e99999a':struct.unpack('<f',bytes.fromhex('9a99993e'))[0]},
          'limitations':'Static link/topology/PE evidence verification only; no runtime behavior test'}
(root/'outputs/townscaper_grid_verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(result,ensure_ascii=False))
