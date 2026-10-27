from pathlib import Path
import sys,json,copy
sys.path.insert(0,str(Path(__file__).parent/'assets-tools'))
import UnityPy
from UnityPy.helpers.TypeTreeGenerator import TypeTreeGenerator
from UnityPy.helpers.Tpk import get_typetree_node
from UnityPy.enums import ClassIDType
root=Path(r'D:\SteamLibrary\steamapps\common\Nova Roma')
out=Path(__file__).resolve().parent.parent/'outputs'
gen=TypeTreeGenerator('6000.2.10f1')
gen.load_local_game(str(root))
env=UnityPy.load(str(root/'NovaRoma_Data'/'level1'))
env.typetree_generator=gen
result=[]
for path_id,cls in [(33636,'DynamicWater'),(49194,'AqueductFlowDriver'),(49184,'GameState'),(35944,'GameWorkshopUI'),(44447,'TourismModalUI'),(44116,'TwitchIRC'),(44184,'StreamerUI')]:
    obj=next(o for o in env.objects if o.path_id==path_id)
    try:
        nodes=gen.get_nodes_up('Assembly-CSharp',cls)
        nodes.m_Children[:4]=get_typetree_node(ClassIDType.MonoBehaviour,obj.version).m_Children
        d=obj.read_typetree(nodes=nodes)
        rec={'file':'level1','path_id':path_id,'class':cls,'all_field_names':list(d),'selected_values':{k:v for k,v in d.items() if k in ['m_Enabled','SimulationTimeStep','TimeStep','A','L','Gravity','Evaporation','jobInnerloopBatches','width','height']},'parse':'TypeTreeGeneratorAPI schema from installed managed DLLs; canonical UnityPy MonoBehaviour header replaces generator header to correct pointer alignment; strict complete-byte read'}
    except Exception as e:rec={'class':cls,'path_id':path_id,'error':str(e)}
    result.append(rec)
(out/'focus-serialized-fields.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
