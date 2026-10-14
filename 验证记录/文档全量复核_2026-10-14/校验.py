from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
AUDIT = Path(__file__).resolve().parent
baseline = json.loads((AUDIT/'基线.json').read_text(encoding='utf-8'))
inventory = json.loads((AUDIT/'来源清单.json').read_text(encoding='utf-8'))
checks = {}
parser = argparse.ArgumentParser()
parser.add_argument('--git-index', action='store_true', help='Verify staged Git backup bytes before committing')
args = parser.parse_args()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

original = ROOT/'备份/文档_原始_20261013_213114/文档'
archive = ROOT/baseline['archive']
backup = ROOT/baseline['backup']
assert len(inventory) == 31
assert {p.relative_to(original).as_posix() for p in original.rglob('*.md')} == {i['source'] for i in inventory}
for item in inventory:
    assert sha(original/item['source']) == item['sha256']
    assert sha(ROOT/item['archive']) == item['sha256']
    assert (ROOT/'文档'/item['current_target']).is_file()
checks['original_integrity'] = {'files':31, 'headings':baseline['original_headings'], 'result':'PASS'}
for name, digest in baseline['backup_files'].items():
    assert sha(backup/name) == digest, name
    if name.startswith('文档/'):
        assert sha(archive/'复核前文档'/name[len('文档/'):]) == digest, name
    elif name == 'PROJECT.md':
        assert sha(archive/'PROJECT_复核前.md') == digest
checks['pre_edit_backup'] = {'files':len(baseline['backup_files']), 'result':'PASS'}
specs = list((ROOT/'文档/01_执行规格').glob('spec.*.md'))
assert len(specs) == 10
assert all('## 表 H1' not in p.read_text(encoding='utf-8') and '## 现有实现兼容参数' not in p.read_text(encoding='utf-8') for p in specs)
assert len(list((ROOT/'数据/兼容规格').glob('spec.*.md'))) == 5
checks['active_specs_and_legacy_isolation'] = {'active':10, 'legacy_inputs':5, 'result':'PASS'}
old_config = json.loads((AUDIT/'world_v2_修改前.json').read_text(encoding='utf-8'))
config = json.loads((ROOT/'数据/world_v2.json').read_text(encoding='utf-8'))
assert {k:v for k,v in old_config.items() if k != 'sources'} == {k:v for k,v in config.items() if k != 'sources'}
assert sha(ROOT/'数据/spec_values.json') == baseline['spec_values_sha256']
checks['runtime_data_unchanged'] = {'world_v2_except_sources':'PASS', 'spec_values_sha256':baseline['spec_values_sha256']}

city = (ROOT/'文档/15_时代与地标.md').read_text(encoding='utf-8')
catalog = city.split('## 完整 27 座地标内容池')[1].split('## 渐进换代')[0]
landmarks = [line.split('|')[2].strip() for line in catalog.splitlines() if line.startswith(('| 古典 |','| 中世纪 |','| 文艺复兴 |','| 工业 |','| 现代 |'))]
assert len(landmarks) == len(set(landmarks)) == 27
original_city = (original/'01_执行规格/spec.city.md').read_text(encoding='utf-8-sig')
assert all(name in original_city for name in landmarks), 'Landmark name lost or invented'
scale = (ROOT/'文档/18_城市规模.md').read_text(encoding='utf-8')
district_section = scale.split('## 保留完整功能区词汇')[1]
districts = ['居住','商业','工坊','圣所','港口','梯田','园林','市集','学园','工业带','滨水带','山城','遗迹','枢纽']
assert all(f'| {name} |' in district_section for name in districts)
growth = (ROOT/'文档/14_城市生长.md').read_text(encoding='utf-8')
forms = ['环形合唱城','双子港','梯田赋格镇','深流','织机','回声街','独奏岛']
assert all(name in growth for name in forms)
assert '120 FPS' in scale and '3,000–5,000' in scale
assert '约 80 秒' in city and '期间允许继续建设' in city
coverage = (ROOT/'文档/需求与旧稿覆盖.md').read_text(encoding='utf-8')
assert all(f"| {item['source']} |" in coverage for item in inventory)
checks['recovered_content'] = {'landmarks':27, 'districts':14, 'forms':7, 'source_rows':31, 'era_and_performance_targets':'PASS'}

if args.git_index:
    archived_files = [(ROOT/item['archive'],item['sha256']) for item in inventory]
    for name,digest in baseline['backup_files'].items():
        if name.startswith('文档/'):
            archived_files.append((archive/'复核前文档'/name[len('文档/'):],digest))
        elif name == 'PROJECT.md':
            archived_files.append((archive/'PROJECT_复核前.md',digest))
    for path,digest in archived_files:
        blob = subprocess.run(['git','show',':'+path.relative_to(ROOT).as_posix()],cwd=ROOT,capture_output=True,check=True).stdout
        assert hashlib.sha256(blob).hexdigest() == digest, path
    staged = subprocess.run(['git','diff','--cached','--name-only','-z'],cwd=ROOT,capture_output=True,check=True).stdout.decode('utf-8').split('\0')
    prefixes = ('文档/','数据/兼容规格/','废弃/文档/2026-10-14_全量复核/','验证记录/文档全量复核_2026-10-14/')
    files = {'PROJECT.md','tools/build_spec_data.py','tools/merge_docs_compact.py','数据/world_v2.json'}
    assert all(not name or name in files or name.startswith(prefixes) for name in staged), 'Unrelated file staged'
    checks['git_archive_bytes'] = {'files':len(archived_files), 'result':'PASS', 'staged_scope':'PASS'}

# The project links this report; create it before checking local links on a first run.
(AUDIT/'验证结果.json').write_text(json.dumps(dict(status='IN_PROGRESS',checks=checks),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for filename, args in [('check_doc_links.py',[]),('merge_docs_compact.py',['--check']),('build_spec_data.py',['--check'])]:
    result = subprocess.run([sys.executable,'-X','utf8',str(ROOT/'tools'/filename),*args],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
    assert result.returncode == 0, result.stdout + result.stderr
    checks[filename] = result.stdout.strip()
result = dict(status='PASS',checks=checks,scope='Documentation and compatibility-input maintenance only; gameplay, art, and human experience not tested.')
(AUDIT/'验证结果.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
