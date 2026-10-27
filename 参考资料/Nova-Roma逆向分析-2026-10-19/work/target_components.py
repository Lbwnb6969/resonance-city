from pathlib import Path
import json,sys
sys.path.insert(0,str(Path(__file__).parent/'assets-tools'))
import UnityPy
root=Path(r'D:\SteamLibrary\steamapps\common\Nova Roma\NovaRoma_Data')
out=Path(__file__).resolve().parent.parent/'outputs'
targets=['KCModHelper','ModLoader','ModLoadBootstrapper','WorkshopUI','GameWorkshopUI','TourismModalUI','TwitchIRC','StreamerUI','MainGameLoader','GameState','DynamicWater','AqueductFlowDriver']
catalog=json.loads((out/'unity-object-catalog.json').read_text(encoding='utf-8'))
scripts={x['path_id']:x['m_ClassName'] for x in catalog if x['type']=='MonoScript' and x.get('m_ClassName') in targets}
result={'requested_classes':targets,'matching_scripts':scripts,'files':[],'components':[]}
for name in ['level0','level1','resources.assets','sharedassets0.assets','sharedassets1.assets']:
    env=UnityPy.load(str(root/name)); assets=next(f for f in env.files.values() if hasattr(f,'objects'))
    externals=[{'file_id':i+1,'path':e.path} for i,e in enumerate(assets.externals)]
    result['files'].append({'file':name,'externals':externals})
    objects=assets.objects; go_names={}; transforms={}; go_transforms={}
    for o in objects.values():
        if o.type.name=='GameObject':
            d=o.read_typetree();go_names[o.path_id]=(d.get('m_Name'),d.get('m_IsActive'))
        if o.type.name in ['Transform','RectTransform']:
            d=o.read_typetree();transforms[o.path_id]=d;go_transforms[d['m_GameObject']['m_PathID']]=o.path_id
    def hierarchy(go_id):
        parts=[];seen=set()
        while go_id and go_id not in seen:
            seen.add(go_id);parts.append(go_names.get(go_id,(f'<id:{go_id}>',None))[0]);t=transforms.get(go_transforms.get(go_id),{})
            parent=transforms.get(t.get('m_Father',{}).get('m_PathID'),{})
            go_id=parent.get('m_GameObject',{}).get('m_PathID',0)
        return '/'.join(reversed(parts))
    def inactive_ancestors(go_id):
        inactive=[];seen=set()
        while go_id and go_id not in seen:
            seen.add(go_id)
            if go_names.get(go_id,(None,None))[1] is False:inactive.append(hierarchy(go_id))
            t=transforms.get(go_transforms.get(go_id),{})
            parent=transforms.get(t.get('m_Father',{}).get('m_PathID'),{})
            go_id=parent.get('m_GameObject',{}).get('m_PathID',0)
        return inactive
    for o in objects.values():
        if o.type.name!='MonoBehaviour':continue
        d=o.read_typetree(check_read=False);ptr=d.get('m_Script',{});sp=ptr.get('m_PathID')
        if sp not in scripts:continue
        fid=ptr.get('m_FileID');external=next((x['path'] for x in externals if x['file_id']==fid),'<same file>')
        if 'globalgamemanagers.assets' not in external:continue
        gid=d.get('m_GameObject',{}).get('m_PathID')
        result['components'].append({'file':name,'kind':'build_scene' if name.startswith('level') else 'resource_or_shared_prefab','component_path_id':o.path_id,'class':scripts[sp],'script_ref':{'file_id':fid,'path_id':sp,'file':external},'gameobject_path_id':gid,'gameobject_hierarchy':hierarchy(gid),'component_enabled':d.get('m_Enabled'),'gameobject_active_self':go_names.get(gid,(None,None))[1],'inactive_hierarchy_nodes':inactive_ancestors(gid),'parsed_field_names':list(d),'note':'Header only; custom serialized script fields unavailable from stripped typetree. Scene presence and enabled flag do not prove execution.'})
    del env
(out/'target-component-evidence.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result['components'],ensure_ascii=False,indent=2))
