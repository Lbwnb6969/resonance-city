"""Link recovered prop components to precise asset hierarchy, without runtime claims."""
from pathlib import Path
import json, collections
BASE=Path(__file__).resolve().parent.parent
inventory=json.loads((BASE/'outputs/townscaper_assets.json').read_text(encoding='utf8'))
objects={(o['file'],o['path_id']):o for o in inventory['objects']}
components=json.loads((BASE/'outputs/townscaper_asset_components.json').read_text(encoding='utf8'))
go_transform={}
for key,o in objects.items():
    if o['type']=='Transform': go_transform[(key[0],o['data']['m_GameObject']['m_PathID'])]=key
def hierarchy(file,go):
    chain=[]; seen=set(); key=(file,go)
    while key not in seen and key in objects:
        seen.add(key); obj=objects[key]; chain.append(obj.get('name',''))
        tr=objects.get(go_transform.get(key),{}).get('data',{})
        parent=tr.get('m_Father',{}).get('m_PathID',0)
        if not parent: break
        po=objects.get((file,parent),{}).get('data',{})
        key=(file,po.get('m_GameObject',{}).get('m_PathID',0))
    return list(reversed(chain))
records=[]
for c in components:
    if c['script']['namespace']!='Placemaker.Props':continue
    data=c['data'];go=data['m_GameObject']['m_PathID'];file=c['file']
    chain=hierarchy(file,go)
    records.append({'file':file,'path_id':c['path_id'],'class':c['script']['class'],'game_object':go,
                    'name':objects.get((file,go),{}).get('name',''),'hierarchy':chain,'root':chain[0] if chain else '',
                    'configuration':{k:v for k,v in data.items() if k not in ('m_Name','m_GameObject','m_Script','m_Enabled')}})
counts=collections.Counter(r['class'] for r in records)
result={'source':'Recovered shipped Unity player components + file-local GameObject/Transform hierarchy',
        'counts':dict(counts),'limitations':['Serialized state is a prefab/scene snapshot, not generated instance runtime state.',
        'Names group actual resources; no inferred semantic family assigned from name substrings.',
        'Bounds are half extents, not radii. Engine BoxCollider is distinct from custom PropCollider.'],'components':records}
(BASE/'outputs/townscaper_prop_configurations.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
rows=['# 道具资源与连接配置','', '来源为发布的 GameObject/Transform 层级和真实 Placemaker.Props 组件。154 个自定义 PropCollider、159 个 PropNode 均保留完整数值；localBounds 的 m_Extent 是半尺寸，worldBounds 的零值是序列化初始状态，不能当生成后空间位置。','', '[逐组件数值 JSON](townscaper_prop_configurations.json) 保存 collider 的 layer/中心/半尺寸、节点 priority/motivations/计数、PropTransformer 变异幅度和 wire 端点引用。','', '| 组件类型 | 数量 |','|---|---:|']
rows += [f'| {name} | {n} |' for name,n in sorted(counts.items())]
rows += ['', '## 各实际资源名称的 collider 与节点', '', '| 文件/节点资源 | collider 层/局部中心/半尺寸 | Node priority / motivation / hideCount |','|---|---|---|']
groups=collections.defaultdict(list)
for r in records:
    if r['class'] in ('PropCollider','PropNode'):groups[(r['file'],r['game_object'],r['name'])].append(r)
for (file,go,name),rs in sorted(groups.items()):
    coll=[r for r in rs if r['class']=='PropCollider']; nodes=[r for r in rs if r['class']=='PropNode']
    def vec(v):return '('+','.join(format(v[a],'.5g') for a in 'xyz')+')'
    ctext='; '.join(str(r['configuration']['layer'])+' / '+vec(r['configuration']['localBounds']['m_Center'])+' / '+vec(r['configuration']['localBounds']['m_Extent']) for r in coll) or '—'
    ntext='; '.join(' / '.join(str(r['configuration'].get(a)) for a in ('priority','motivations','hideCount')) for r in nodes) or '—'
    rows.append(f'| {file}:{go} `{name}` | {ctext} | {ntext} |')
rows+=['','## 连线资源','','这些字段是源配置；anchor0/anchor1 为零的 wire prefab 在放置时由原生逻辑接到两个实际 anchor。','', '| 组件 | 层级 | 引用/参数 |','|---|---|---|']
for r in records:
    if r['class'].startswith('PropWire'):
        rows.append(f"| {r['file']}:{r['path_id']} {r['class']} | {' / '.join(r['hierarchy'])} | `{json.dumps(r['configuration'],ensure_ascii=False,separators=(',',':'))}` |")
(BASE/'outputs/townscaper_prop_configurations.md').write_text('\n'.join(rows)+'\n',encoding='utf8')
print(json.dumps({'components':len(records),'classes':dict(counts),'distinct_node_objects':len(groups)}))
