import hashlib
import json
import subprocess
from pathlib import Path

def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for block in iter(lambda:f.read(1048576),b''):h.update(block)
    return h.hexdigest()

root=Path(__file__).resolve().parents[1]
backup=root/'work/runtime/user_backup_20261013'
user=Path(r'C:\Users\Administrator\AppData\LocalLow\Oskar Stalberg\Townscaper')
files=[]
for original in sorted((backup/'Townscaper').rglob('*')):
    if original.is_file():
        relative=original.relative_to(backup/'Townscaper')
        current=user/relative
        files.append({'relative_path':str(relative),'before_sha256':sha(original),'after_sha256':sha(current) if current.exists() else None})
baseline={'Townscaper.exe':'4bcb61b1afd9db11df9cbfe7d94317dabc8b0d1f2e58c7a385db953551722116','GameAssembly.dll':'4aa99a8deaa9a322026094186ed283020a8b6d897f2777dbb330ebf0ca89532c','UnityPlayer.dll':'0fe94ef87e762fe81076334ba656538a137ac66d5b1a4f31749cb313d802f764'}
binary=[]
for name,expected in baseline.items():
    actual=sha(Path(r'D:\SteamLibrary\steamapps\common\Townscaper')/name)
    binary.append({'file':name,'sha256':actual,'unchanged':actual==expected})
current_reg=backup/'rawfury-playerprefs-after.reg'
subprocess.run(['reg','export',r'HKCU\Software\Raw Fury\Townscaper',str(current_reg),'/y'],check=True,capture_output=True)
before_reg=backup/'rawfury-playerprefs.reg'
def registry_values(path):
    text=path.read_text(encoding='utf-16').replace('\\\n','').replace('\\\r\n','')
    return sorted(line.strip() for line in text.splitlines() if line.startswith('"') or line.startswith('['))
result={'game_binaries':binary,'existing_user_files':files,'existing_user_files_unchanged':all(f['before_sha256']==f['after_sha256'] for f in files),'registry_unchanged':registry_values(before_reg)==registry_values(current_reg),'registry_restored_after_runtime':(backup/'rawfury-playerprefs-runtime-changes.reg').exists(),'scope':'Three original game PE inputs, all pre-existing Oskar Stalberg/Townscaper files, Raw Fury/Townscaper registry values compared semantically. Unity changed session identifiers and screen settings during headless and D3D11 launches; pre-run registry backup restored after all probes. Both registry snapshots remain outside Git.'}
(root/'outputs/townscaper_integrity_verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'binaries_unchanged':all(b['unchanged'] for b in binary),'user_files_unchanged':result['existing_user_files_unchanged'],'registry_unchanged':result['registry_unchanged']}))
