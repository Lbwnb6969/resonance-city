"""Locate candidate background rests while the same-source full mix is active.
RMS thresholds locate intervals for review; they are not quality/listening gates.
"""
import argparse, hashlib, json, time, wave
from pathlib import Path
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
def local(value): return ROOT / value.removeprefix('res://')
def sha(path):
 with path.open('rb') as f: return hashlib.file_digest(f, 'sha256').hexdigest()
def windows(row, frames):
 path=local(row['path']); assert sha(path)==row['sha256'], path
 values=[]
 with wave.open(str(path),'rb') as f:
  assert (f.getnchannels(),f.getsampwidth(),f.getframerate(),f.getnframes())==(2,2,44100,frames)
  for _ in range(frames//44100):
   samples=np.frombuffer(f.readframes(44100),dtype='<i2').astype(np.float64)/32768
   values.append(float(np.sqrt(np.mean(samples*samples))))
 return np.array(values)
def runs(mask):
 result=[];start=None
 for i,on in enumerate([*mask,False]):
  if on and start is None:start=i
  if not on and start is not None:
   if i-start>=3:result.append({'start_seconds':start,'end_seconds':i,'seconds':i-start})
   start=None
 return result
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--catalog',required=True);parser.add_argument('--out',required=True);parser.add_argument('--name-prefix',action='append',default=[]);args=parser.parse_args()
 out=Path(args.out);out.mkdir(parents=True,exist_ok=False);began=time.monotonic();catalog=local(args.catalog);data=json.loads(catalog.read_text(encoding='utf-8'));reports=[]
 for row in data['packs']:
  path=local(row['manifest']);assert sha(path)==row['manifest_sha256'];m=json.loads(path.read_text(encoding='utf-8'))
  if m['schema']!='city_sparse_music_v2' or (args.name_prefix and not any(m['name'].startswith(prefix) for prefix in args.name_prefix)):continue
  full=windows(m['full_mix'],m['frames'])*m['common_gain'];layers={layer['id']:windows(layer,m['frames']) for layer in m['layers'] if layer['id'] in ['background','body']}
  entry={'name':m['name'],'manifest':row['manifest'],'manifest_sha256':row['manifest_sha256'],'frames':m['frames'],'assignments':m.get('assignments',m.get('recipe',{})),'gain':m['common_gain'],'full_second_windows':len(full),'layers':{}}
  for name,values in layers.items():
   entry['layers'][name]={'rms':float(np.sqrt(np.mean(values**2))),'active_mix_quiet_runs':runs((values<.0003)&(full>.01)),'relative_weak_runs':runs((values<full*.03)&(full>.01)),'windows':values.tolist()}
  entry['full_windows']=full.tolist();reports.append(entry)
  print(m['name'],json.dumps({k:v['active_mix_quiet_runs'] for k,v in entry['layers'].items()},ensure_ascii=False),flush=True)
 result={'catalog':args.catalog,'catalog_sha256':sha(catalog),'seconds':time.monotonic()-began,'songs':reports,'measurement':'Complete non-overlapping 1s stereo PCM RMS; partial final second excluded. Quiet <.0003 when gain-matched master >.01; weak <3% of active master. Three-second runs are review markers, not listening gates.'}
 (out/'report.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
if __name__=='__main__':main()
