from pathlib import Path
import json,sys,struct,hashlib,copy
sys.path.insert(0,str(Path(__file__).parent/'assets-tools'))
import UnityPy
from UnityPy.helpers.TypeTreeGenerator import TypeTreeGenerator
from UnityPy.helpers.Tpk import get_typetree_node
from UnityPy.enums import ClassIDType
root=Path(r'D:\SteamLibrary\steamapps\common\Nova Roma');out=Path(__file__).resolve().parent.parent/'outputs'
gen=TypeTreeGenerator('6000.2.10f1');gen.load_local_game(str(root))
summary={}
for name in ['resources.assets','level1','sharedassets1.assets']:
    env=UnityPy.load(str(root/'NovaRoma_Data'/name));env.typetree_generator=gen
    focus={52605:('Assembly-CSharp-firstpass','I2.Loc.LanguageSourceAsset'),52636:('Assembly-CSharp','ResourceDefinitions'),52637:('Assembly-CSharp','ScenarioWorlds'),52638:('Assembly-CSharp','SeasonDefinition'),52639:('Assembly-CSharp','SeasonDefinition'),52640:('Assembly-CSharp','SeasonDefinition'),52641:('Assembly-CSharp','SeasonDefinition')} if name=='resources.assets' else {}
    for o in env.objects:
        if o.type.name=='TextAsset':
            raw=o.get_raw_data();endian=o.reader.endian;n=struct.unpack_from(endian+'i',raw)[0];pos=(4+n+3)&~3;ln=struct.unpack_from(endian+'i',raw,pos)[0];b=raw[pos+4:pos+4+ln]
            d=o.read_typetree();rec={'file':name,'path_id':o.path_id,'name':d['m_Name'],'exact_payload_bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'first32_hex':b[:32].hex()}
            summary.setdefault('embedded_text',[]).append(rec)
        if o.type.name!='MonoBehaviour':continue
        h=o.read_typetree(nodes=get_typetree_node(ClassIDType.MonoBehaviour,o.version),check_read=False);script=h.get('m_Script',{})
        if name=='level1' and script.get('m_FileID')==1 and script.get('m_PathID')==2501:focus[o.path_id]=('Assembly-CSharp','TimeManager')
        if o.path_id not in focus:continue
        asm,cls=focus[o.path_id]
        try:
            nodes=gen.get_nodes_up(asm,cls)
            nodes.m_Children[:4]=get_typetree_node(ClassIDType.MonoBehaviour,o.version).m_Children
            d=o.read_typetree(nodes=nodes)
            key=f'{name}:{o.path_id}:{cls}';summary[key]={'field_names':list(d)}
            if cls in ['ResourceDefinitions','SeasonDefinition','TimeManager']:
                summary[key]['data']=d
            elif cls=='ScenarioWorlds':
                summary[key]['structure']={k: {'type':type(v).__name__,'length':len(v) if isinstance(v,(list,dict,str)) else None} for k,v in d.items()}
            elif cls=='I2.Loc.LanguageSourceAsset':
                source=d.get('mSource',{})
                summary[key].update({'source_field_names':list(source),'languages':source.get('mLanguages'),'term_count':len(source.get('mTerms',[]))})
        except Exception as e:summary[f'{name}:{o.path_id}:{cls}']={'error':str(e)}
(out/'resource-values-intermediate.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
for k,v in summary.items():
    if k=='embedded_text':continue
    print(k, list(v))
(out/'embedded-text-assets.json').write_text(json.dumps(summary['embedded_text'],ensure_ascii=False,indent=2),encoding='utf-8')
