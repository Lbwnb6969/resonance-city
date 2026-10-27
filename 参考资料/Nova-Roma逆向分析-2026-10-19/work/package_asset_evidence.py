from pathlib import Path
import json,gzip,shutil
from collections import Counter,defaultdict
workspace=Path(__file__).resolve().parent.parent;out=workspace/'outputs';archive=workspace/'work'/'evidence';archive.mkdir(exist_ok=True)
def dump(name,data): (out/name).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
values=json.loads((out/'resource-values-intermediate.json').read_text(encoding='utf-8'))
resource=values['resources.assets:52636:ResourceDefinitions']['data']['initialResourceDefinitions']
dump('resource-definition-summary.json',{'source':'NovaRoma_Data/resources.assets:52636 ResourceDefinitionList','method':'Generated managed serialization schema, strict byte coverage; selected scalar fields only; references excluded.','resources':[{k:x[k] for k in ['ID','name','carryCapacity','isSecondary','timeExpire','thoughtWhenMissing']} for x in resource]})
season=[]
for k,v in values.items():
    if k.endswith(':SeasonDefinition'):
        season.append({'source':k,**{f:v['data'][f] for f in ['m_Name','name','id','duration','transitionTime','nights','nightRatio','markNewYear']}})
dump('season-settings.json',{'method':'Generated managed serialization schema, strict byte coverage; selected scalar fields only. Values are serialized asset configuration, not elapsed runtime observations.','seasons':season,'time_manager':{'source':'level1:35793','playSpeeds':values['level1:35793:TimeManager']['data']['playSpeeds']},'localization':{'source':'resources.assets:52605','resource_name':'i2languages','class':'I2.Loc.LanguageSourceAsset','parse_error':values['resources.assets:52605:I2.Loc.LanguageSourceAsset']['error']}})
settings=json.loads((out/'unity-settings.json').read_text(encoding='utf-8'))
(out/'unity-settings.json').rename(archive/'unity-settings-full-redacted.json')
g=settings['globalgamemanagers:7:GraphicsSettings'];b=settings['globalgamemanagers:11:BuildSettings'];q=settings['globalgamemanagers:12:QualitySettings'];r=settings['globalgamemanagers:13:ResourceManager'];p=settings['globalgamemanagers:PlayerSettings:partial']
selected={'note':'Selected readable fields; large pointer arrays and shader define bitfields archived in work/evidence. Build token excluded.','globalgamemanagers:7:GraphicsSettings':{k:g[k] for k in ['m_CustomRenderPipeline','m_LightsUseLinearIntensity','m_LightsUseColorTemperature','m_CurrentRenderPipelineGlobalSettings']},'globalgamemanagers:11:BuildSettings':{k:b[k] for k in ['scenes','preloadedPlugins','enabledVRDevices','m_Version','m_GraphicsAPIs','enableDynamicBatching']},'globalgamemanagers:12:QualitySettings':q,'globalgamemanagers:13:ResourceManager':{'resource_entry_count':len(r['m_Container']),'dependent_asset_count':len(r['m_DependentAssets'])},'globalgamemanagers:PlayerSettings:partial':{'parser_note':p['parser_note'],'data':{k:p['data'][k] for k in ['companyName','productName','bundleVersion','runInBackground','usePlayerLog','forceSingleInstance','resizableWindow','defaultIsNativeResolution','defaultScreenWidth','defaultScreenHeight','m_ActiveColorSpace','allowHDRDisplaySupport','useHDRDisplay','activeInputHandler']}}}
dump('unity-settings.json',selected)
dump('unity-resource-path-index.json',[{'path':x[0],'reference':x[1]} for x in r['m_Container']])
catalog_path=out/'unity-object-catalog.json'
with catalog_path.open('rb') as src,gzip.open(out/'unity-object-catalog.json.gz','wb') as dest:shutil.copyfileobj(src,dest)
catalog_path.rename(archive/'unity-object-catalog.json')
(out/'resource-values-intermediate.json').rename(archive/'resource-values-intermediate.json')
gitignore=workspace/'.gitignore'
text=gitignore.read_text(encoding='utf-8') if gitignore.exists() else ''
if 'work/assets-tools/' not in text:gitignore.write_text(text.rstrip()+'\nwork/assets-tools/\n',encoding='utf-8')
print('Resources',[(x['ID'],x['name'],x['carryCapacity']) for x in resource])
print('Seasons',[(x['name'],x['duration'],x['transitionTime']) for x in season])
print('PlaySpeeds',values['level1:35793:TimeManager']['data']['playSpeeds'])
print('Output catalog gzip bytes',(out/'unity-object-catalog.json.gz').stat().st_size)
