"""Build the portable core opening without the obsolete large-city contract."""
from pathlib import Path
import argparse
import json
import re
import shutil
import subprocess
import zipfile

from build_demo_bundle import ROOT, audit, run, sha

NATIVE = Path('addons/city_audio/bin/city_audio.windows.template_release.x86_64.dll')
PROBE = Path('tests/core_slice_bundle_probe.gd')


def script_hashes():
    return {p.relative_to(ROOT).as_posix(): sha(p)
            for p in sorted((ROOT / 'scripts').rglob('*.gd'))}


def check_engine_log(path):
    text = path.read_text(encoding='utf-8', errors='replace')
    if re.search(r'SCRIPT ERROR:|\bERROR:|Assertion failed', text):
        raise RuntimeError(f'Engine startup failed; retained evidence: {path}')


def launcher(output, name, isolated):
    command = ('@echo off\r\nchcp 65001 >nul\r\n'
               'start "" "%~dp0运行环境\\Godot.exe" --path "%~dp0运行环境" '
               '--main-pack "%~dp0运行环境\\共鸣之城.zip"')
    if isolated:
        command += ' -- --isolated-session'
    (output / name).write_bytes((command + '\r\n').encode('utf-8'))


def build(engine, output, evidence):
    engine = engine.resolve(strict=True)
    output = output.resolve()
    evidence = evidence.resolve()
    shipping = output.with_suffix('.zip')
    if output.exists() or evidence.exists() or shipping.exists():
        raise FileExistsError('Use new output/evidence paths; existing builds are preserved')
    output.mkdir(parents=True)
    evidence.mkdir(parents=True)
    runtime = output / '运行环境'
    runtime.mkdir()
    packaged_engine = runtime / 'Godot.exe'
    shutil.copy2(engine, packaged_engine)
    console = engine.with_name(engine.stem + '_console.exe')
    if not console.is_file():
        console = engine
    scripts = script_hashes()
    source_commit = subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    pack = runtime / '共鸣之城.zip'
    run([console, '--headless', '--path', ROOT, '--export-pack', 'Demo本地运行包', pack],
        evidence / '导出.log', ROOT)
    if scripts != script_hashes():
        raise RuntimeError('Runtime scripts changed during export; retained partial output')
    target = runtime / NATIVE
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / NATIVE, target)
    audit_result = audit(pack)
    isolated = evidence / '空隔离目录'
    isolated.mkdir()
    result_path = evidence / '隔离结果.json'
    probe_log = evidence / '隔离引擎.log'
    run([packaged_engine, '--audio-driver', 'Dummy', '--path', runtime,
         '--main-pack', pack, '--log-file', probe_log, '--script', ROOT / PROBE,
         '--', '--isolated-session', '--result=' + str(result_path)],
        evidence / '隔离运行.log', isolated)
    check_engine_log(probe_log)
    result = json.loads(result_path.read_text(encoding='utf-8'))
    if result['status'] != 'PASS':
        raise RuntimeError('Core opening failed: ' + str(result_path))
    direct_log = evidence / '直接启动引擎.log'
    run([packaged_engine, '--audio-driver', 'Dummy', '--path', runtime,
         '--main-pack', pack, '--log-file', direct_log, '--quit-after', '180',
         '--', '--isolated-session'], evidence / '直接启动.log', isolated)
    check_engine_log(direct_log)
    launcher(output, '启动Demo.cmd', True)
    launcher(output, '继续城市.cmd', False)
    (output / '先读我.txt').write_text(
        '双击启动Demo.cmd，从24栋新河湾开始；听5秒后按提示创作。\n'
        '选发展方向和社区 → 安排公园、文化馆或留地 → 试听并确认声音；下一句看街坊生长，点你种下的房屋改音，再试试对岸。\n'
        '继续城市.cmd进入已有作品；P规划，滚轮缩放，中键拖动，按面板提示用空格试听。保持运行环境文件夹完整，无需安装Godot。\n',
        encoding='utf-8')
    licenses = output / '许可'
    licenses.mkdir()
    shutil.copy2(ROOT / '资产/许可记录/Godot/LICENSE.txt', licenses / 'Godot-MIT.txt')
    shutil.copy2(evidence / 'Godot及第三方许可.json', licenses / 'Godot及第三方许可.json')
    for name in ['LICENSE-GDSiON', 'LICENSE-godot-cpp']:
        shutil.copy2(ROOT / 'native/city_audio' / name, licenses / name)
    for package in ['roads', 'commercial', 'industrial', 'suburban']:
        shutil.copy2(ROOT / f'资产/许可记录/CityKits/{package}/License.txt',
                     licenses / (package + '-CC0.txt'))
    (licenses / '项目原创说明.txt').write_text(
        '统一连宅与历史建筑SVG为本项目原创；源码、合成声音及原创资产归项目。\n'
        'Godot MIT适用于引擎，不是整个游戏的许可。\n'
        'Godot许可来源：https://godotengine.org/license/\n', encoding='utf-8')
    build_inputs = ['project.godot', 'export_presets.cfg',
                    'tools/build_core_slice_bundle.py', 'tools/build_demo_bundle.py',
                    PROBE.as_posix()] + [p.relative_to(ROOT).as_posix()
                                       for p in sorted((ROOT / '数据').glob('*.json'))]
    record = {
        'status': 'PASS', 'source_commit': source_commit,
        'source_identity_scope': 'Git base commit plus exact working-tree script and build-input fingerprints; includes uncommitted production changes',
        'build_inputs_sha256': {p: sha(ROOT / p) for p in build_inputs},
        'script_sources_sha256': scripts,
        'native_audio_sha256': sha(ROOT / NATIVE),
        'engine_version': result['engine'], 'engine_sha256': sha(engine),
        'pack_sha256': sha(pack), 'pack_size_bytes': pack.stat().st_size,
        'engine_size_bytes': engine.stat().st_size,
        'output': str(output), 'portable_zip': str(shipping),
        'checks': result['checks'], 'opening': result['opening'],
        **audit_result,
        'scope': 'Portable Windows x86_64 engine + audited resources + native DLL; 24-building GPU opening with Dummy audio clock, not physical listening or large-city stress',
    }
    (evidence / '构建记录.json').write_text(
        json.dumps(record, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    identity_keys = ['source_commit', 'source_identity_scope', 'build_inputs_sha256',
                     'script_sources_sha256', 'native_audio_sha256', 'engine_version',
                     'engine_sha256', 'pack_sha256', 'scope']
    (output / '构建身份.json').write_text(json.dumps(
        {key: record[key] for key in identity_keys}, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8')
    with zipfile.ZipFile(shipping, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(output.rglob('*')):
            if path.is_file():
                archive.write(path, Path(output.name) / path.relative_to(output))
    print(f'CORE_SLICE_BUNDLE PASS checks={len(result["checks"])} textures={len(record["textures"])} portable={shipping}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--engine', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    args = parser.parse_args()
    build(args.engine, args.output, args.evidence)
