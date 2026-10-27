"""Read-only export of decoded Unity media and shader representations."""
import hashlib
import json
from pathlib import Path
import re
import sys

WORK = Path(__file__).resolve().parent
sys.path.insert(0, str(WORK/'asset_pydeps'))
import UnityPy
from UnityPy.helpers.ResourceReader import get_resource_data
from fmod_toolkit.fmod import get_pyfmodex_system_instance, sound_to_wav, pyfmodex

ROOT = Path(r'D:\SteamLibrary\steamapps\common\Townscaper\Townscaper_Data')
OUT = WORK.parent/'outputs/townscaper_extracted_assets'

def clean(s):
    return re.sub(r'[^a-zA-Z0-9_\-.]', '_', s)[:100]

def main():
    paths = sorted(p for p in ROOT.iterdir() if p.suffix == '.assets')
    paths += sorted(p for p in (ROOT/'Resources').iterdir() if p.is_file())
    env = UnityPy.load(*(str(p) for p in paths))
    env.path = str(ROOT)
    for p in ROOT.iterdir():
        if p.suffix in ('.resS','.resource'):
            env.load_file(str(p))
    OUT.mkdir(parents=True, exist_ok=True)
    records = []
    for o in env.objects:
        if o.type.name not in ('Mesh','Texture2D','AudioClip','Shader'):
            continue
        r = {'source_file': Path(o.assets_file.name).name, 'path_id':o.path_id,'type':o.type.name}
        stem = clean(r['source_file'])+'__'+str(o.path_id)
        try:
            v = o.read()
            r['name'] = v.m_Name
            dest = OUT/o.type.name
            dest.mkdir(exist_ok=True)
            stem += '__'+clean(v.m_Name)
            produced = []
            if o.type.name == 'Mesh':
                p = dest/(stem+'.obj')
                p.write_text(v.export(),encoding='utf8')
                produced.append(p)
            elif o.type.name == 'Texture2D':
                if v.m_Width == 0 or v.m_Height == 0:
                    r['success'] = True
                    r['outputs'] = []
                    r['status'] = 'Zero-size dynamic font texture; no static pixels to export'
                    records.append(r)
                    continue
                p = dest/(stem+'.png')
                v.image.save(p)
                produced.append(p)
            elif o.type.name == 'Shader':
                p = dest/(stem+'.shader.txt')
                p.write_text(v.export(),encoding='utf8')
                produced.append(p)
            elif o.type.name == 'AudioClip':
                resource = v.m_Resource
                # Bind source exactly, avoid the parser's fuzzy fallback between
                # similarly named .resource and .assets.resS companions.
                source_path = ROOT/Path(resource.m_Source.replace('\\','/')).name
                with source_path.open('rb') as source:
                    source.seek(resource.m_Offset)
                    raw = source.read(resource.m_Size)
                if len(raw) != resource.m_Size:
                    raise ValueError('Audio resource range is outside exact source file')
                r['resource'] = {'file':source_path.name,'offset':resource.m_Offset,'size':resource.m_Size,'sha256':hashlib.sha256(raw).hexdigest()}
                p = dest/(stem+'.fsb')
                p.write_bytes(raw)
                produced.append(p)
                # pyfmodex OPENMEMORY wrapper fails with this Python ABI. A
                # filename-bound FMOD sound reads the same preserved FSB bytes.
                system, lock = get_pyfmodex_system_instance(v.m_Channels, pyfmodex.flags.INIT_FLAGS.NORMAL)
                with lock:
                    sound = system.create_sound(str(p.resolve()))
                    samples = sound_to_wav(sound, v.m_Name)
                    sound.release()
                for i,(name,data) in enumerate(samples.items()):
                    p = dest/(stem+'__'+str(i)+Path(name).suffix)
                    p.write_bytes(data)
                    produced.append(p)
            r['outputs'] = [{'file':str(p.relative_to(OUT)), 'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in produced]
            r['success'] = True
        except Exception as ex:
            r['success'] = False
            r['error'] = str(ex)
            dest = OUT/o.type.name
            dest.mkdir(exist_ok=True)
            p = dest/(stem+'.unity-object.bin')
            p.write_bytes(o.get_raw_data())
            r['outputs'] = [{'file':str(p.relative_to(OUT)), 'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}]
            r['status'] = 'Original object payload preserved; format-aware text conversion unavailable'
        records.append(r)
    index = {'target':str(ROOT), 'records':records,'limitations':['OBJ mesh export is a static rendering representation; rigging and Unity serialization remain in original asset records.', 'Shader text export is reconstructed by UnityPy, not recovered original HLSL source.']}
    (OUT/'index.json').write_text(json.dumps(index,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps({'items':len(records),'success':sum(r['success'] for r in records),'failures':[{k:v for k,v in r.items() if k!='outputs'} for r in records if not r['success']]},ensure_ascii=False))

if __name__ == '__main__':
    main()
