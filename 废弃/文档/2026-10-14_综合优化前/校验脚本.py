from pathlib import Path
import hashlib
import importlib.util
import json
import shutil

archive = Path(__file__).resolve().parent
root = archive.parents[2]
backup = root / '备份/文档综合优化前_20261014_101721'
report = {'archive': str(archive), 'backup': str(backup)}
hashof = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
comparisons = []
for path in sorted((backup / '文档').rglob('*')):
    if path.is_file():
        rel = path.relative_to(backup)
        target = archive / rel
        comparisons.append({'path': rel.as_posix(), 'equal': path.read_bytes() == target.read_bytes(), 'sha256': hashof(path)})
assert all(x['equal'] for x in comparisons)
assert (backup / 'PROJECT.md').read_bytes() == (archive / 'PROJECT.md').read_bytes()
report['original_files'] = comparisons
report['original_project_equal'] = True

module_spec = importlib.util.spec_from_file_location('spec_builder', root / 'tools/build_spec_data.py')
builder = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(builder)
world = root / '数据/world_v2.json'
legacy = root / '数据/spec_values.json'
baseline = archive / 'world_v2_修改前.json'
before = json.loads((baseline if baseline.exists() else world).read_text(encoding='utf-8'))
expected_text = builder.generate()
after = json.loads(expected_text)
prior_sources = before.pop('sources')
new_sources = after.pop('sources')
assert before == after, 'Runtime configuration changed beyond source hashes'
report['runtime_parameters_equal'] = True
report['legacy_sha256'] = hashof(legacy)
report['sources_changed'] = [k for k in new_sources if new_sources[k] != prior_sources[k]]
if not (archive / 'world_v2_修改前.json').exists():
    shutil.copyfile(world, archive / 'world_v2_修改前.json')
world.write_text(expected_text, encoding='utf-8', newline='\n')
assert hashof(legacy) == report['legacy_sha256']
report['legacy_bytes_unchanged'] = True
report['active_original_paths'] = len([p for p in (archive / '文档').rglob('*.md')])
report['active_new_paths'] = len([p for p in (root / '文档').rglob('*.md')])
report['checks'] = {}
(archive / '验证结果.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: v for k,v in report.items() if k != 'original_files'}, ensure_ascii=False, indent=2))
