"""Canonicalize versioned generated text so recorded hashes survive Git checkout."""
import hashlib
import json
import subprocess
from pathlib import Path

root=Path(__file__).resolve().parents[1]
tracked=subprocess.check_output(['git','ls-files','-z'],cwd=root).decode('utf-8').split('\0')
suffixes={'.md','.json','.py','.js','.java','.tsv','.c','.cs','.h','.hlsl','.asm','.txt'}
changed=0
for name in tracked:
    if name.startswith('outputs/townscaper_extracted_assets/'):
        continue
    path=root/name
    if not path.is_file() or path.suffix.lower() not in suffixes:continue
    raw=path.read_bytes()
    if b'\r\n' in raw:
        path.write_bytes(raw.replace(b'\r\n',b'\n'))
        changed+=1
path=root/'outputs/townscaper_method_inventory.json'
inventory=json.loads(path.read_text(encoding='utf-8'))
for record in inventory['sources']:
    record['sha256']=hashlib.sha256(Path(record['path']).read_bytes()).hexdigest()
path.write_text(json.dumps(inventory,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Canonical LF files:',changed)
