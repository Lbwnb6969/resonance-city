"""Immutable same-source repartition with unchanged maximum response endpoint."""
import copy,json,time,wave
import numpy as np
from build_sparse_music_pilot import ROOT,local,read_pcm,save,sha
RECIPE=ROOT/'数据/音乐制作/持续背景分配修订_20261108.json'
def path(value):return ROOT/value.removeprefix('res://')
def audio(row,frames):return read_pcm({**row,'path':str(path(row['path']))},frames)
def write_audio(target,values):
 pcm=np.rint(values*32768)
 assert np.max(pcm)<=32767 and np.min(pcm)>=-32768
 with wave.open(str(target),'wb') as stream:
  stream.setparams((2,2,44100,len(pcm),'NONE','not compressed'));stream.writeframes(pcm.astype('<i2').tobytes())
 return pcm.astype(np.float32)/32768

def build():
 began=time.monotonic();recipe=json.loads(RECIPE.read_text(encoding='utf-8'));prior=path(recipe['prior_catalog']);assert sha(prior)==recipe['prior_catalog_sha256']
 catalog=json.loads(prior.read_text(encoding='utf-8'));out=path(recipe['output']);out.mkdir(parents=True,exist_ok=False);reports=[]
 for row in recipe['songs']:
  old_path=path(row['prior_manifest']);assert sha(old_path)==row['prior_manifest_sha256'];old=json.loads(old_path.read_text(encoding='utf-8'));m=copy.deepcopy(old)
  assert m['schema']=='city_sparse_music_v2' and [v['id'] for v in m['layers']]==['background','body','detail']
  frames=m['frames'];background,body,residual=[audio(v,frames) for v in old['layers']];share=row['response_background_share'];cap=old['layers'][1]['automatic_max'];assert 0<share<cap<1
  folder=out/row['folder'];folder.mkdir();parts=[]
  for i,values in enumerate([background+body*share,body*(1-share)]):
   target=folder/('background.wav' if i==0 else 'body.wav');parts.append(write_audio(target,values));m['layers'][i].update(path=local(target),sha256=sha(target))
  parts.append(residual);new_cap=(cap-share)/(1-share);m['layers'][1]['automatic_max']=new_cap
  master=audio(m['full_mix'],frames);error=float(np.max(np.abs(sum(parts)-master*m['common_gain'])));bound=float(np.max(sum(np.abs(v) for v in parts)))
  endpoint=float(np.max(np.abs(parts[0]+parts[1]*new_cap-(background+body*cap))))
  assert error<=4/32768 and bound<.721 and endpoint<=2/32768
  rms=lambda a:float(np.sqrt(np.mean(a.astype(np.float64)**2)))
  m.update(name=row['name'],prior_version={'path':local(old_path),'sha256':sha(old_path)},recipe={'path':local(RECIPE),'sha256':sha(RECIPE),'selection':row})
  m['evidence'].update(full_endpoint_max_error=error,all_gain_combinations_peak_bound=bound,background_to_master_rms=rms(parts[0])/rms(master),maximum_automatic_endpoint_error=endpoint)
  m['background_repartition']={'fixed_response_share':share,'old_response_cap':cap,'new_response_cap':new_cap,'formula':'background_new=background_old+a*body_old; body_new=(1-a)*body_old; cap_new=(cap_old-a)/(1-a); residual unchanged','instrument_identity_confirmed':False}
  save(folder/'bundle.json',m)
  matched=[r for r in catalog['packs'] if r['manifest']==row['prior_manifest']];assert len(matched)==1;matched[0].update(name=m['name'],manifest=local(folder/'bundle.json'),manifest_sha256=sha(folder/'bundle.json'))
  reports.append({'name':m['name'],'prior_manifest_unchanged':sha(old_path)==row['prior_manifest_sha256'],'full_endpoint_max_error':error,'all_gain_combinations_peak_bound':bound,'maximum_automatic_endpoint_error':endpoint,'old_background_rms':rms(background),'new_background_rms':rms(parts[0]),'old_response_cap':cap,'new_response_cap':new_cap,'residual_reused':m['layers'][2]==old['layers'][2]})
 catalog['prior_catalog']={'path':local(prior),'sha256':sha(prior)};save(out/'catalog.json',catalog);save(out/'production.json',{'seconds':time.monotonic()-began,'songs':reports,'new_wavs':4,'old_catalog_unchanged':sha(prior)==recipe['prior_catalog_sha256'],'listening_approved':False})
 print(json.dumps({'catalog':local(out/'catalog.json'),'sha256':sha(out/'catalog.json'),'reports':reports},ensure_ascii=False))
if __name__=='__main__':build()
