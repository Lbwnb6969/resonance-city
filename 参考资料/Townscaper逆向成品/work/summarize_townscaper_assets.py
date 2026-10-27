import collections
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent/'outputs'
a = json.loads((OUT/'townscaper_assets.json').read_text(encoding='utf8'))
c = json.loads((OUT/'townscaper_asset_components.json').read_text(encoding='utf8'))
obj = {(x['file'],x['path_id']):x for x in a['objects']}
comp = {(x['file'],x['path_id']):x for x in c}
external = {f['file']:{x['file_id']:Path(x['path']).name for x in f['externals']} for f in a['serialized_files']}

def resolve(file,p):
    if p['m_PathID'] == 0:
        return None
    f = file if p['m_FileID']==0 else external[file].get(p['m_FileID'])
    x = obj.get((f,p['m_PathID']))
    return {'file':f,'path_id':p['m_PathID'],'type':x.get('type') if x else None,'name':x.get('name') if x else None,'script':x.get('script') if x else None}

selected = ['PlatformSettings','WorldMaster','SaveSystem','Maker','GridGenerator','MasterClicker','ActionInputManager','FlyCamera','ModuleBuilder','WaveFunctionCollapse','PropPlacer','BirdFlock','ButterflyFlock','MaterialMaster','WorldMeshes','SaveCamera','ScreenshotCamera','UiMaster']
core = []
for x in c:
    if x['script']['class'] in selected:
        d = x['data']
        core.append({'file':x['file'],'path_id':x['path_id'],'script':x['script'], 'references':{k:resolve(x['file'],v) for k,v in d.items() if isinstance(v,dict) and 'm_FileID' in v},'field_names':list(d)})

inputdata = next(x['data']['_userData'] for x in c if x['file']=='level0' and x['script']['class']=='InputManager')
actions = {x['_id']:x['_name'] for x in inputdata['actions']}
keys = {27:'Escape',308:'LeftAlt',307:'RightAlt',306:'LeftControl',305:'RightControl',310:'LeftCommand',309:'RightCommand'}
bindings = []
for m in inputdata['keyboardMaps']:
    for b in m['actionElementMaps']:
        k=b['_keyboardKeyCode']
        bindings.append({'key':keys.get(k,chr(k) if 32<=k<127 else str(k)), 'key_code':k,'action':actions.get(b['_actionId']), 'pole':'positive' if b['_axisContribution']==0 else 'negative','raw':b})

library = next(x for x in c if x['script']['class']=='ModuleLibrary')
d = library['data']
module = {'file':library['file'],'path_id':library['path_id'],'counts':{k:len(v) for k,v in d.items() if isinstance(v,list)},'groundUv0':d['groundUv0'],'groundUv1':d['groundUv1'],'cost_distribution':dict(collections.Counter(x['cost'] for x in d['modules'])), 'module_examples':d['modules'][:5], 'corner_lookup_examples':d['cornerLookups'][:5], 'side_lookup_examples':d['sideLookups'][:5], 'module_mesh_example_keys':list(d['moduleMeshes'][0]),'decor_example':d['decorModules'][0]}
prop = next(x for x in c if x['script']['class']=='PropPlacer')
module['prop_placer'] = prop
(OUT/'townscaper_module_asset_summary.json').write_text(json.dumps(module,ensure_ascii=False,indent=2),encoding='utf8')
localization = next(x for x in c if x['script']['class']=='LanguageSourceAsset')
(OUT/'townscaper_localization.json').write_text(json.dumps(localization,ensure_ascii=False,indent=2),encoding='utf8')
summary={'scenes':{f:dict(collections.Counter(r['type'] for r in a['objects'] if r['file']==f)) for f in ['level0','level1','level2']},'core_components':core,'platform_settings':next(x for x in c if x['script']['class']=='PlatformSettings'),'keyboard_bindings':bindings,'rewired_actions':inputdata['actions'],'rewired_mouse_maps':inputdata['mouseMaps'],'rewired_joystick_maps':inputdata['joystickMaps'],'input_manager_config':inputdata['configVars'],'hardware_map_names':[x['data']['m_Name'] for x in c if x['script']['class']=='HardwareJoystickMap'],'palette':next(x for x in c if x['script']['class']=='Palette'),'module_summary':module,'localization':{'file':localization['file'],'path_id':localization['path_id'],'language_count':len(localization['data']['mSource']['mLanguages']),'term_count':len(localization['data']['mSource']['mTerms'])}}
(OUT/'townscaper_asset_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf8')
lines=['# Townscaper 资源、场景和序列化配置逆向','', '本报告来自发行包实际Unity序列化对象，原安装只读；不是从字符串猜测运行时结果。完整对象与逐对象SHA-256保存在 `townscaper_assets.json`，完整MonoBehaviour字段在 `townscaper_asset_components.json`。','', '## 覆盖和验证','',f"- 读取{len(a['input_files'])}个serialized file和{len(a['stream_files'])}个伴随资源流，枚举{len(a['objects'])}对象；保存文件哈希、PathID、原对象字节偏移/长度/哈希。",'- UnityPy 1.25.4，TypeTreeGeneratorAPI 0.0.10，从Il2CppDumper DummyDll元数据恢复游戏类型树。修复基础m_Enabled对齐和string[]根节点标签；每个成功对象严格消耗完整字节，MonoBehaviour m_Script额外与标准头交叉校验。',f"- 游戏9个主serialized file解析8,239对象，2,516个脚本组件完整恢复。唯一无脚本对象为globalgamemanagers.assets:1127，保留原payload哈希。额外纳入2个Unity内置资源文件，总计8,363对象、2,517个完整脚本组件；6个Unity内置Shader转换失败并单独保留二进制。",'- 重跑：`python work/analyze_townscaper_assets.py`；`python work/export_townscaper_assets.py`；`python work/summarize_townscaper_assets.py`。','', '## 场景及实际引用','', '| Scene | GameObject | MonoBehaviour | Transform/RectTransform |', '|---|---:|---:|---:|']
for f,s in summary['scenes'].items():
    lines.append(f"| {f} | {s.get('GameObject',0)} | {s.get('MonoBehaviour',0)} | {s.get('Transform',0)+s.get('RectTransform',0)} |")
lines += ['', '`BuildSettings.scenes`严格列出Boot、Placemaker和FlatscreenUi，顺序与level0/1/2一致。level0的PlatformManager:99通过FileID2/PathID45指向sharedassets0.assets的MainGamePlatformSettings。level1的WorldMaster:316持有Graph:344、Maker:337、WaveFunctionCollapse:330、ModuleBuilder:354、PropPlacer:332、SaveSystem:345以及sharedassets1的模块库/颜色库/默认存档。序列化uiMaster为空，跨场景运行时绑定应查代码，不能据此宣称UI不存在。','', '## 平台和保存目录','', '实际MainGamePlatformSettings为sharedassets0.assets:45：storageRoot=2（PersistentDataPath）、storageRootSuffixPc=`/../../Oskar Stalberg/Townscaper`、storageContainerBehaviour=0（Ignore）。因此Standalone路径拼接不加storage容器子目录。PlayerSettings的companyName=`Raw Fury`、productName=`Townscaper`。结合既有FilePathRootExtensions/Standalone代码，Windows标准persistentDataPath下该suffix把Raw Fury/Townscaper规范化为LocalLow/Oskar Stalberg/Townscaper；当前会话实际绝对路径与SDK使用仍需运行时证据。','', '这些是资产值；Steam参数appId=0、useSteamDrm=1，不能以此证明Steam服务是否在当前运行中连接。','', '## 物理输入映射','', 'Boot Rewired InputManager:100明确动作Id、键码、正负轴贡献，键码按恢复的Unity KeyCode与Rewired Pole枚举解释。Player0的默认keyboard/mouse/joystick category0/layout0 enabled；用户存储加载/重映射会改变当前实际绑定。','', '| Key | Action | Pole |','|---|---|---|']
for b in bindings:
    lines.append(f"| `{b['key']}` ({b['key_code']}) | {b['action']} | {b['pole']} |")
lines += ['', '键盘共34条；颜色0–9对应1–9/0，颜色10–14对应Y/U/I/O/P。Mouse map只有actionId=-1的空占位，不能从此声称鼠标建造未实现；MasterClicker的Pointer事件和手动鼠标路径是另一入口，需与原生伪代码合并。10个joystick action map以及167个HardwareJoystickMap、6个HardwareJoystickTemplateMap都完整恢复。Windows配置useXInput/useNativeMouse/useEnhancedDeviceSupport/useSteamControllerSupport=1，240Hz joystickRefreshRate；ignoreInputWhenAppNotInFocus=1。','', '## 建筑模块和渲染资源','',f"ModuleLibrary sharedassets1.assets:1119保存{len(d['modules'])}个modules、{len(d['decorModules'])}个decorModules、{len(d['cornerLookups'])}个cornerLookups、{len(d['sideLookups'])}个sideLookups、{len(d['moduleMeshes'])}个嵌入moduleMeshes、{len(d['decorOverlaps'])}个decorOverlaps，以及2个waterSides。这些是WFC候选/邻接查找的实际数据，不是独立Mesh对象计数。完整字段和每项cost/profileIndexes等已保留，精简统计见townscaper_module_asset_summary.json。",'','Palette sharedassets1.assets:1120含15个Color32 rgba值。CustomGridLibrary:1116含allCustomPatches/genericPatches/straightPatches/centroidPatches/centroidCurvePatches，GridGenerator:351预置初始patch、verts/quads和focus状态；工作区已保存完整坐标和索引。','', '资产共127个Mesh（其中游戏主资源114个）、76个Texture2D（主资源35个）、54个Material、94个Shader（主资源46个）、92个AudioClip。含Doors/Windows/Plants/Fence/Water/Bird等小型装饰网格，Placemaker/* shader，建造plop/tile、撤销重做、鸟起飞、水声、菜单和音乐音频。组件引用通过FileID外部表精确关联，完整ResourceManager/Material属性和Particle/Camera配置保存于对象索引。','', '## 导出媒体','', 'townscaper_extracted_assets/index.json记录每一导出结果、来源PathID和输出SHA-256。127/127 Mesh转OBJ，74个静态纹理转PNG，2个零尺寸动态字体纹理没有静态像素；92/92音频保留FSB并转WAV；88/94 Shader输出UnityPy重建文本，其余6个内置Shader保留原对象bin。文本Shader不等于原作者HLSL，OBJ不包含完整Unity运行时行为。','', '## 默认世界和本地化','', 'DefaultSaveData = sharedassets1.assets:1117，原发行文本`GSB0RARueC6Snc9E0lO5B`，7corners/13voxels以及cam=(68,142,178)、sun=(127,127)完整保留在townscaper_default_save_asset.json。这提供与静态编码算法相互独立的真实游戏样本。','', f"LanguageSourceAsset = resources.assets:47，含92个Term和46个LanguageData（各自Flags也保留，不能把全部条目等同于已启用语言），简体/繁体中文分别zh-CN/zh-TW。菜单、商店页和翻译ReadMe的文本数组完整恢复在townscaper_localization.json。Google同步服务URL和Spreadsheet标识为发行资产的静态配置，未访问这些端点。",'', '## 剩余边界','', '- 序列化对象恢复证明构建内的默认值与引用，不证明当前用户运行时状态、重映射或SDK连接。','- 原HLSL、原Unity工程GUID/source .meta与编辑器场景层级的全部作者信息不在发行格式内；重建资产与配置需使用已保留PathID外部引用表。','- 6个Unity内置Shader保留原payload，当前UnityPy类型解析未支持；业务shader/音频/mesh/静态像素导出已完成。']
(OUT/'townscaper_assets.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(json.dumps({'core_components':len(core),'keyboard_bindings':len(bindings),'hardware_maps':len(summary['hardware_map_names'])}))
