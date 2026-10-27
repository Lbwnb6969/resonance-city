from pathlib import Path
from collections import Counter
import json,sys,hashlib
sys.path.insert(0,str(Path(__file__).parent/'assets-tools'))
import UnityPy
root=Path(r'D:\SteamLibrary\steamapps\common\Nova Roma\NovaRoma_Data')
out=Path(__file__).resolve().parent.parent/'outputs'
settings=json.loads((out/'unity-settings.json').read_text(encoding='utf-8'))
for k,v in settings.items():
    if 'm_AuthToken' in v: v['m_AuthToken']='[redacted shipped build token]'
texts=[];mono_counts=Counter();scene_objects={};ps={}
for name in ['globalgamemanagers','level0','level1','resources.assets','sharedassets0.assets','sharedassets1.assets']:
    env=UnityPy.load(str(root/name))
    file_map={0: next(iter(env.files.values()))}
    for file in env.files.values():
        if not hasattr(file,'objects'):continue
        for o in file.objects.values():
            if o.type.name=='MonoBehaviour':
                d=o.read_typetree(check_read=False); ptr=d.get('m_Script',{})
                mono_counts[(name,ptr.get('m_FileID'),ptr.get('m_PathID'))]+=1
            elif o.type.name=='GameObject' and name.startswith('level'):
                d=o.read_typetree();scene_objects.setdefault(name,[]).append(d.get('m_Name',''))
            elif o.type.name=='PlayerSettings':
                ps=o.read_typetree(check_read=False)
                # No values used as runtime keys/tokens are distributed in evidence.
                for k in list(ps):
                    if any(s in k.lower() for s in ['token','secret','key','password']):ps[k]='[redacted]'
            elif o.type.name=='TextAsset':
                d=o.read_typetree();s=d.get('m_Script',''); b=s.encode('utf-8',errors='surrogateescape') if isinstance(s,str) else bytes(s)
                rec={'file':name,'path_id':o.path_id,'name':d.get('m_Name'),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'first32_hex':b[:32].hex()}
                if d.get('m_Name') in ['summary','eosPluginVersion','BillingMode','PerformanceTestRunSettings']:
                    try:rec['parsed_json']=json.loads(s)
                    except:rec['text']=s[:500]
                texts.append(rec)
    del env
settings['globalgamemanagers:PlayerSettings:partial']={'parser_note':'check_read=False; UnityPy consumed 884 of 888 bytes. Fields parsed before trailing mismatch are retained; final field coverage incomplete.','data':ps}
(out/'unity-settings.json').write_text(json.dumps(settings,ensure_ascii=False,indent=2),encoding='utf-8')
(out/'embedded-text-assets.json').write_text(json.dumps(texts,ensure_ascii=True,indent=2),encoding='utf-8')
(out/'scene-gameobject-names.json').write_text(json.dumps(scene_objects,ensure_ascii=False,indent=2),encoding='utf-8')
(out/'monobehaviour-pointer-counts.json').write_text(json.dumps([{'file':k[0],'script_file_id':k[1],'script_path_id':k[2],'count':v} for k,v in mono_counts.items()],ensure_ascii=False,indent=2),encoding='utf-8')
print('PlayerSettings selected:',{k:v for k,v in ps.items() if k in ['companyName','productName','bundleVersion','defaultScreenWidth','defaultScreenHeight','colorSpace','scriptingBackend','usePlayerLog','resizableWindow','runInBackground']})
print('TextAssets',[(x['name'],x['bytes'],x['first32_hex']) for x in texts])
