"""Build a local portable Demo, preserving old outputs and recording real evidence."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(args, log, cwd):
    with log.open('w', encoding='utf-8') as stream:
        result = subprocess.run([str(x) for x in args], cwd=cwd, stdout=stream,
                                stderr=subprocess.STDOUT, timeout=180)
    text = log.read_text(encoding='utf-8', errors='replace')
    if result.returncode or re.search(r'SCRIPT ERROR:|\bERROR:|Assertion failed', text):
        raise RuntimeError(f'Build check failed; retained evidence: {log}')


def audit(pack):
    textures = []
    with zipfile.ZipFile(pack) as archive:
        names = archive.namelist()
        forbidden = [x for x in names if x.startswith(
            ('资产/', 'tests/', 'tools/', 'native/', '文档/', '验证记录/', '废弃/', '备份/', '交付/', '.git/', '资源/测试/'))
            or (x.startswith('addons/') and not x.startswith('addons/city_audio/'))]
        if forbidden or len(names) != len(set(names)) or archive.testzip():
            raise RuntimeError(f'Invalid resource archive: {forbidden}')
        for folder in ['P0城市', 'Demo城市', '风格小景', '古典建筑候选']:
            manifest_path = '资源/' + folder + '/manifest.json'
            source = ROOT / manifest_path
            if archive.read(manifest_path) != source.read_bytes():
                raise RuntimeError('Stale manifest: ' + manifest_path)
            for entry in json.loads(source.read_text(encoding='utf-8'))['entries']:
                path = entry['texture']
                if sha(ROOT / path) != entry['texture_sha256']:
                    raise RuntimeError('Source texture changed: ' + path)
                imported = archive.read(path + '.import').decode('utf-8')
                target = re.search(r'^path="res://([^"]+)"', imported, re.M).group(1)
                digest = hashlib.sha256(archive.read(target)).hexdigest()
                if digest != sha(ROOT / target):
                    raise RuntimeError('Stale imported texture: ' + path)
                textures.append({'id': entry['id'], 'path': path,
                                 'source_sha256': entry['texture_sha256'],
                                 'packed_path': target, 'packed_sha256': digest,
                                 'license': entry['license']})
        for path in ['数据/spec_values.json', '数据/listening_fixtures.json']:
            if archive.read(path) != (ROOT / path).read_bytes():
                raise RuntimeError('Stale runtime data: ' + path)
    return {'files': names, 'textures': textures, 'forbidden': forbidden}


def build(engine, output, evidence):
    engine = engine.resolve(strict=True)
    output = output.resolve()
    evidence = evidence.resolve()
    shipping = output.with_suffix('.zip')
    if output.exists() or evidence.exists() or shipping.exists():
        raise FileExistsError('Use new output and evidence directories; old builds are preserved')
    output.mkdir(parents=True)
    evidence.mkdir(parents=True)
    runtime = output / '运行环境'
    runtime.mkdir()
    packaged_engine = runtime / 'Godot.exe'
    shutil.copy2(engine, packaged_engine)
    console = engine.with_name(engine.stem + '_console.exe')
    if not console.is_file():
        console = engine
    pack = runtime / '共鸣之城.zip'
    run([console, '--headless', '--path', ROOT, '--export-pack', 'Demo本地运行包', pack],
        evidence / '导出.log', ROOT)
    # --export-pack omits external GDExtension libraries. Place the DLL beside
    # the resource pack at its declared res:// path, independent of launch cwd.
    native_relative = Path('addons/city_audio/bin/city_audio.windows.template_release.x86_64.dll')
    native_target = runtime / native_relative
    native_target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / native_relative, native_target)
    audit_result = audit(pack)
    isolated = evidence / '空隔离目录'
    isolated.mkdir()
    probe = ROOT / 'tests/native_bundle_contract.gd'
    result_path = evidence / '隔离结果.json'
    run([packaged_engine, '--audio-driver', 'Dummy', '--path', runtime, '--main-pack', pack,
         '--script', probe, '--', '--result=' + str(result_path)],
        evidence / '隔离运行.log', isolated)
    result = json.loads(result_path.read_text(encoding='utf-8'))
    if result['status'] != 'PASS':
        raise RuntimeError('Isolated scene checks failed: ' + str(result_path))
    # Normal entry uses the actual default audio setup, independently of the external probe.
    run([packaged_engine, '--audio-driver', 'Dummy', '--path', runtime, '--main-pack', pack,
         '--quit-after', '180'], evidence / '直接启动.log', isolated)
    # The isolated probe checks the current main scene; the ordinary startup
    # independently proves that its default entry can run without script errors.
    run([packaged_engine, '--audio-driver', 'Dummy', '--path', runtime, '--main-pack', pack,
         'res://scenes/style_frame.tscn', '--quit-after', '3'], evidence / '风格入口.log', isolated)
    for filename, scene, extra in [
        ('启动Demo.cmd', '', ''),
        ('启动风格小景.cmd', 'res://scenes/style_frame.tscn', ''),
        ('启动古典小景.cmd', 'res://scenes/style_frame.tscn', '-- --classical-frame'),
    ]:
        # %~dp0 is the unpacked bundle root, regardless of the caller's working directory.
        text = ('@echo off\r\nchcp 65001 >nul\r\n'
                'start "" "%~dp0运行环境\\Godot.exe" --path "%~dp0运行环境" '
                '--main-pack "%~dp0运行环境\\共鸣之城.zip" ' + scene + ' ' + extra + '\r\n')
        (output / filename).write_bytes(text.encode('utf-8'))
    licenses = output / '许可'
    licenses.mkdir()
    shutil.copy2(ROOT / '资产/许可记录/Godot/LICENSE.txt', licenses / 'Godot-MIT.txt')
    shutil.copy2(evidence / 'Godot及第三方许可.json', licenses / 'Godot及第三方许可.json')
    for filename in ['LICENSE-GDSiON', 'LICENSE-godot-cpp']:
        shutil.copy2(ROOT / 'native/city_audio' / filename, licenses / filename)
    for package in ['roads', 'commercial', 'industrial', 'suburban']:
        shutil.copy2(ROOT / f'资产/许可记录/CityKits/{package}/License.txt', licenses / (package + '-CC0.txt'))
    (licenses / '项目原创说明.txt').write_text(
        '统一连宅与历史建筑SVG为本项目原创；源码、合成声音及原创资产归项目。\n'
        'Godot MIT仅适用于引擎，不是整个游戏的许可。\n'
        'Godot许可来源：https://godotengine.org/license/\n', encoding='utf-8')
    shutil.copy2(ROOT / '文档/Demo快速开始.md', output / 'Demo快速开始.md')
    (output / '先读我.txt').write_text(
        '双击启动Demo.cmd；风格/古典小景为独立艺术样稿入口。\n'
        '请保持运行环境文件夹完整；无需Godot安装或开发工程。\n'
        '本地Windows x86_64运行包，附带现有Godot引擎；不是发行模板生成的EXE。\n'
        '滚轮缩放，中键拖动，Home复位；选中房屋后可聚焦。B黑屏，Esc返回。\n'
        '真人测试结果使用Godot原user://位置，与开发机共享同名应用数据。\n'
        '艺术/音乐时代候选状态见快速开始；真人体验仍待用户组织。\n', encoding='utf-8')
    record = {'rule_id': 'ASSET-001', 'status': 'PASS', 'source_commit': subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'source_identity_scope': 'Git base commit plus exact working-file fingerprints; runtime data may contain concurrent design updates',
        'build_inputs_sha256': {p:sha(ROOT / p) for p in ['project.godot', 'export_presets.cfg', '数据/spec_values.json', '数据/world_v2.json', 'tools/build_demo_bundle.py', 'tests/native_bundle_contract.gd']},
        'native_audio_sha256': sha(ROOT / 'addons/city_audio/bin/city_audio.windows.template_release.x86_64.dll'),
        'engine_version': result['engine'], 'engine_sha256': sha(engine),
        'pack_sha256': sha(pack), 'pack_size_bytes': pack.stat().st_size,
        'engine_size_bytes': engine.stat().st_size, 'output': str(output),
        'checks': result['checks'], **audit_result,
        'script_sources_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted((ROOT / 'scripts').rglob('*.gd'))},
        'scope': 'Local portable engine + resource pack; actual GPU isolated scenes and default entry; Dummy, not human listening or long stress'}
    (evidence / '构建记录.json').write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (output / '构建身份.json').write_text(json.dumps({k:record[k] for k in (
        'source_commit', 'source_identity_scope', 'build_inputs_sha256', 'engine_version', 'engine_sha256', 'pack_sha256', 'scope')}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with zipfile.ZipFile(shipping, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(output.rglob('*')):
            if path.is_file():
                archive.write(path, Path(output.name) / path.relative_to(output))
    print(f'DEMO_BUNDLE PASS checks={len(result["checks"])} textures={len(record["textures"])} portable={shipping}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--engine', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    args = parser.parse_args()
    build(args.engine, args.output, args.evidence)
