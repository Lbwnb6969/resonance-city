from pathlib import Path
from collections import Counter, defaultdict
import sys, json, csv, hashlib, struct, re
sys.path.insert(0,str(Path(__file__).parent/'assets-tools'))
import UnityPy, pefile

root=Path(r'D:\SteamLibrary\steamapps\common\Nova Roma')
out=Path(__file__).resolve().parent.parent/'outputs'
out.mkdir(exist_ok=True)

def write_json(name,data):
    (out/name).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')

inventory=[]
for p in sorted(root.rglob('*')):
    if not p.is_file(): continue
    h=hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda:f.read(8*1024*1024),b''): h.update(chunk)
    inventory.append({'path':str(p.relative_to(root)),'size':p.stat().st_size,'sha256':h.hexdigest()})
with (out/'file-inventory.csv').open('w',newline='',encoding='utf-8-sig') as f:
    w=csv.DictWriter(f,fieldnames=['path','size','sha256']);w.writeheader();w.writerows(inventory)
write_json('file-inventory-summary.json',{'root':str(root),'file_count':len(inventory),'total_bytes':sum(x['size'] for x in inventory),'extensions':dict(Counter(Path(x['path']).suffix or '<none>' for x in inventory)),'largest_files':sorted(inventory,key=lambda x:x['size'],reverse=True)[:20]})

native=[]
for p in sorted(root.rglob('*')):
    if p.suffix.lower() not in ('.exe','.dll') or 'Managed' in p.parts:continue
    try:
        pe=pefile.PE(str(p),fast_load=True)
        pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_IMPORT'],pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_RESOURCE']])
        version={}
        for group in getattr(pe,'FileInfo',[]):
            for node in group:
                for tab in getattr(node,'StringTable',[]):
                    for k,v in tab.entries.items():
                        version[k.decode(errors='replace')]=v.decode(errors='replace')
        native.append({'path':str(p.relative_to(root)),'machine':hex(pe.FILE_HEADER.Machine),'version':version,'imports':[x.dll.decode(errors='replace') for x in getattr(pe,'DIRECTORY_ENTRY_IMPORT',[])]})
        pe.close()
    except Exception as e:native.append({'path':str(p.relative_to(root)),'error':str(e)})
write_json('native-dependencies.json',native)

asset_paths=[p for p in (root/'NovaRoma_Data').iterdir() if p.name in ('globalgamemanagers','globalgamemanagers.assets','resources.assets','sharedassets0.assets','sharedassets1.assets','level0','level1')]
asset_paths+=list((root/'NovaRoma_Data'/'Resources').iterdir())
asset_files=[];objects=[];selected={};errors=[]
for p in asset_paths:
    print('Parsing',p.name,flush=True)
    try:
        env=UnityPy.load(str(p))
        counts=Counter()
        for o in env.objects:
            counts[o.type.name]+=1
            row={'file':p.name,'path_id':o.path_id,'type':o.type.name,'size':o.byte_size}
            # Only decode metadata-bearing classes, never image/audio payloads.
            if o.type.name in ('GameObject','MonoScript','Shader','Mesh','Material','Texture2D','AudioClip','TextAsset','Font','Sprite','ComputeShader','MonoBehaviour','PlayerSettings','BuildSettings','ResourceManager','GraphicsSettings','QualitySettings'):
                try:
                    d=o.read_typetree()
                    if 'm_Name' in d:row['name']=d['m_Name']
                    if o.type.name=='MonoScript':row.update({k:d.get(k) for k in ['m_ClassName','m_Namespace','m_AssemblyName']})
                    if o.type.name=='Texture2D':row.update({k:d.get(k) for k in ['m_Width','m_Height','m_TextureFormat','m_MipCount']})
                    if o.type.name=='AudioClip':row.update({k:d.get(k) for k in ['m_Frequency','m_Channels','m_Length','m_CompressionFormat']})
                    if o.type.name=='TextAsset':
                        txt=d.get('m_Script','');row['text_length']=len(txt)
                    if o.type.name in ('PlayerSettings','BuildSettings','GraphicsSettings','QualitySettings'):
                        selected[f'{p.name}:{o.path_id}:{o.type.name}']=d
                    if o.type.name=='ResourceManager':
                        # Just Resource path to pointer map, no media export.
                        selected[f'{p.name}:{o.path_id}:{o.type.name}']=d
                except Exception as e:
                    row['metadata_error']=str(e)[:240]
            objects.append(row)
        asset_files.append({'file':p.name,'unity_versions':sorted(set(str(getattr(f,'unity_version','')) for f in env.files.values())),'object_count':sum(counts.values()),'types':dict(counts)})
        del env
    except Exception as e: errors.append({'file':p.name,'error':str(e)})
write_json('unity-asset-summary.json',{'parser':'UnityPy '+UnityPy.__version__,'files':asset_files,'errors':errors,'total_objects':len(objects),'total_types':dict(Counter(x['type'] for x in objects))})
write_json('unity-object-catalog.json',objects)
write_json('unity-settings.json',selected)

# FMOD RIFF section inventory proves packaging; strings are only names, no media export.
banks=[]
for p in (root/'NovaRoma_Data'/'StreamingAssets').glob('*.bank'):
    b=p.read_bytes(); rec={'file':p.name,'size':len(b),'header_hex':b[:32].hex(),'chunks':[]}
    if b[:4]==b'RIFF':
        rec['riff_size']=struct.unpack_from('<I',b,4)[0];rec['riff_type']=b[8:12].decode('ascii',errors='replace')
        pos=12
        while pos+8<=len(b):
            tag=b[pos:pos+4];size=struct.unpack_from('<I',b,pos+4)[0]
            rec['chunks'].append({'offset':pos,'tag':tag.decode('ascii',errors='replace'),'size':size})
            if pos+8+size>len(b):break
            pos+=8+size+(size%2)
    banks.append(rec)
write_json('audio-bank-inventory.json',banks)
print(json.dumps({'files':len(inventory),'bytes':sum(x['size'] for x in inventory),'objects':len(objects),'asset_errors':errors},ensure_ascii=False),flush=True)
