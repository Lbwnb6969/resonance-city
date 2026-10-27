"""Run a bounded, persistence-redirected original IL2CPP codec probe."""
import json
import sys
import time
import argparse
import subprocess
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent / 'runtime_pydeps'))
import frida

root = Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--name',default='codec_probe')
parser.add_argument('--observe-seconds',type=float,default=0)
parser.add_argument('--scenario',action='store_true')
parser.add_argument('--snapshots',action='store_true')
parser.add_argument('--boundaries',action='store_true')
parser.add_argument('--layouts',action='store_true')
parser.add_argument('--graphloads',action='store_true')
parser.add_argument('--graphics',action='store_true')
parser.add_argument('--grid',action='store_true')
args=parser.parse_args()
run = root / 'work/runtime' / args.name
run.mkdir(parents=True, exist_ok=True)
events = []
device = frida.get_local_device()
launch=[r'D:\SteamLibrary\steamapps\common\Townscaper\Townscaper.exe']
launch+=['-force-d3d11','-screen-fullscreen','0','-screen-width','960','-screen-height','640'] if args.graphics else ['-batchmode','-nographics']
launch+=['-logFile',str(run/'Player.log')]
pid = device.spawn(launch, cwd=r'D:\SteamLibrary\steamapps\common\Townscaper')
session = None
try:
    session = device.attach(pid)
    script = session.create_script((root/'work/runtime_grid_helpers.js').read_text(encoding='utf-8')+'\n'+(root / 'work/runtime_probe.js').read_text(encoding='utf-8'))
    script.on('message', lambda message, data: events.append(message))
    script.load()
    # suffixPc ascends twice from Raw Fury/Townscaper. Use a nested sandbox.
    persistent = run / 'profile/Raw Fury/Townscaper'
    persistent.mkdir(parents=True, exist_ok=True)
    script.exports_sync.configure(str(persistent))
    device.resume(pid)
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        status = script.exports_sync.status()
        if status['ready']:
            fixtures = json.loads((root / 'outputs/townscaper_codec_fixtures.json').read_text(encoding='utf-8'))
            result = script.exports_sync.codec(fixtures)
            if args.layouts:
                recovered=script.exports_sync.layouts(['Assembly-CSharp','Assembly-CSharp-firstpass','FuryStudios.FurySDK','FuryStudios.FurySDK.Internal','FuryStudios.FurySDK.StandalonePC','FuryStudios.FurySDK.Noop','FuryStudios.BuildSystem'])
                layoutOutput={'source':'Original IL2CPP runtime exported reflection APIs. Field flags must determine static/literal semantics; instance offsets do not apply to static fields. Not REA Evidence.','pointerSize':4,'types':recovered}
                (root/'outputs/townscaper_runtime_layouts.json').write_text(json.dumps(layoutOutput,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
            for f, actual in zip(fixtures, result['results']):
                actual['matches_fixture'] = actual['accepted'] and actual['data'] == f['data'] and actual['reencoded'] == f['text']
            result['provenance'] = {'kind': 'instrumented-original-runtime', 'target': r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll', 'target_sha256': '4aa99a8deaa9a322026094186ed283020a8b6d897f2777dbb330ebf0ca89532c', 'frida_version': frida.__version__, 'modifications': ['persistentDataPath redirected to workspace', 'SaveMetaSaveToDisk suppressed', 'codec implementations unmodified'], 'not_rea_evidence': True}
            if args.observe_seconds:
                time.sleep(args.observe_seconds)
            if args.scenario:
                sys.dont_write_bytecode=True
                sys.path.insert(0,str(root / 'outputs'))
                from townscaper_codec import decode
                def scenario(task):
                    script.exports_sync.enqueue(task)
                    scenario_deadline=time.monotonic()+15
                    while time.monotonic()<scenario_deadline:
                        value=script.exports_sync.scenarioresult()
                        if value is not None:
                            if not value['ok']:raise RuntimeError(value['error'])
                            return value['result']
                        time.sleep(0.05)
                    raise RuntimeError('scenario task deadline: '+task['kind'])
                capture_results=[]
                def capture(label):
                    if not args.graphics:return
                    path=root/'outputs'/('townscaper_runtime_render_'+label+'.png')
                    capture_results.append(scenario({'kind':'capture','path':str(path)}))
                    limit=time.monotonic()+15
                    while time.monotonic()<limit:
                        if path.exists() and path.stat().st_size>1000:return
                        time.sleep(0.1)
                    raise RuntimeError('original capture deadline: '+label)
                if args.graphics:
                    limit=time.monotonic()+45
                    while time.monotonic()<limit:
                        if scenario({'kind':'worldstatus'})['state']==42:break
                        time.sleep(0.1)
                    else:raise RuntimeError('graphical world initialization deadline')
                    time.sleep(1)
                before=scenario({'kind':'save'})
                capture('before')
                snapshots={}
                def snapshot(label):
                    if args.snapshots:
                        time.sleep(0.3)
                        snapshots[label]=scenario({'kind':'snapshot'})
                snapshot('before')
                data=decode(before)
                corner=data['corners'][0]
                height=max((v['h'] for v in data['voxels'][:corner['count']]),default=0)+1
                task={'kind':'action','x':corner['x'],'y':corner['y'],'h':height,'before':18,'after':0}
                scenario(task)
                after=scenario({'kind':'save'})
                if args.graphics:time.sleep(0.5)
                capture('after')
                snapshot('after')
                undo=scenario({'kind':'undo'})
                undone=scenario({'kind':'save'})
                if args.graphics:time.sleep(0.5)
                capture('undone')
                snapshot('undone')
                redo=scenario({'kind':'redo'})
                redone=scenario({'kind':'save'})
                if args.graphics:time.sleep(0.5)
                capture('redone')
                snapshot('redone')
                result['scenario']={'task':task,'before':before,'after':after,'undo':undo,'undone':undone,'redo':redo,'redone':redone,'checks':{'changed':after!=before,'undo_restores':undo and undone==before,'redo_restores':redo and redone==after}}
                result['scenario']['storage']=scenario({'kind':'storage'})
                if args.graphics:result['graphical_capture']={'launch_arguments':launch[1:],'captures':capture_results,'method':'Original Unity ScreenCapture API invoked on original WorldMaster.Update main thread; no desktop UI automation.'}
                if args.grid:
                    result['grid_probe']={'math':scenario({'kind':'gridmath'}),'bits':scenario({'kind':'gridbits'}),'flowBefore':scenario({'kind':'flowstatus'}),'snapshots':[]}
                    def grid_snapshot(label):
                        time.sleep(0.7)
                        limit=time.monotonic()+45
                        while time.monotonic()<limit:
                            if scenario({'kind':'worldstatus'})['state']==42:break
                            time.sleep(0.1)
                        else:raise RuntimeError('grid settle deadline: '+label)
                        result['grid_probe']['snapshots'].append({'label':label,'graph':scenario({'kind':'gridgraph','hex':[72,-36]})})
                    grid_snapshot('before')
                    for label,h,old,new in [('ground_added',0,18,15),('house_added',1,18,3),('house_removed',1,3,18),('ground_removed',0,15,18)]:
                        scenario({'kind':'action','x':72,'y':-36,'h':h,'before':old,'after':new})
                        grid_snapshot(label)
                    result['grid_probe']['flowAfter']=scenario({'kind':'flowstatus'})
                additional=[]
                for label,old_type,new_type in [('paint',0,5),('remove',5,18)]:
                    previous=scenario({'kind':'save'})
                    action=dict(task,before=old_type,after=new_type)
                    scenario(action)
                    changed=scenario({'kind':'save'})
                    did_undo=scenario({'kind':'undo'})
                    restored=scenario({'kind':'save'})
                    did_redo=scenario({'kind':'redo'})
                    redone=scenario({'kind':'save'})
                    additional.append({'name':label,'task':action,'before':previous,'after':changed,'undo':did_undo,'undone':restored,'redo':did_redo,'redone':redone,'checks':{'changed':changed!=previous,'undo_restores':did_undo and restored==previous,'redo_restores':did_redo and redone==changed}})
                result['scenario']['additional']=additional
                if args.snapshots:
                    result['scenario']['generation_snapshots']=snapshots
                    result['scenario']['generation_checks']={'undo_restores_modules':snapshots['before']['qubes']==snapshots['undone']['qubes'],'redo_restores_modules':snapshots['after']['qubes']==snapshots['redone']['qubes']}
                if args.boundaries:
                    result['boundaries']={'dirty':scenario({'kind':'dirtyprobe'}),'history':scenario({'kind':'historyprobe'}),'loads':[]}
                    plan=json.loads((root/'work/history_probe_plan.json').read_text(encoding='utf-8'))
                    for case in plan['probes'][0]['cases']:
                        initial=scenario({'kind':'worldload','text':case['text']})
                        loading_deadline=time.monotonic()+45
                        while time.monotonic()<loading_deadline:
                            status=scenario({'kind':'worldstatus'})
                            if status['state']==42:break
                            time.sleep(0.1)
                        else:raise RuntimeError('worldload did not reach Done: '+case['name'])
                        encoded=scenario({'kind':'save'})
                        result['boundaries']['loads'].append({'name':case['name'],'input':case['text'],'loadResult':initial,'finalStatus':status,'reencoded':encoded,'data':decode(encoded)})
                if args.graphloads:
                    result['graph_load_cases']=[]
                    cases=json.loads((root/'outputs/townscaper_graph_load_fixtures.json').read_text(encoding='utf-8'))
                    if isinstance(cases,dict):cases=cases['cases']
                    for case in cases:
                        initial=scenario({'kind':'worldload','text':case['text']})
                        loading_deadline=time.monotonic()+45
                        while time.monotonic()<loading_deadline:
                            status=scenario({'kind':'worldstatus'})
                            if status['state']==42:break
                            time.sleep(0.1)
                        else:raise RuntimeError('worldload deadline: '+case['name'])
                        encoded=scenario({'kind':'save'})
                        result['graph_load_cases'].append({'name':case['name'],'input':case['text'],'loadResult':initial,'finalStatus':status,'reencoded':encoded,'data':decode(encoded)})
            result['final_runtime_status']=script.exports_sync.status()
            result['events']=events
            destination='townscaper_runtime_grid.json' if args.grid else ('townscaper_runtime_graphics.json' if args.graphics else ('townscaper_runtime_graph_load.json' if args.graphloads else ('townscaper_runtime_boundaries.json' if args.boundaries else ('townscaper_runtime_scenario.json' if args.scenario else ('townscaper_runtime_startup.json' if args.observe_seconds else 'townscaper_runtime_codec.json')))))
            (root / 'outputs' / destination).write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
            print(json.dumps({'fixtures': len(result['results']), 'matches': sum(r['matches_fixture'] for r in result['results'])}))
            break
        time.sleep(0.5)
    else:
        raise RuntimeError('IL2CPP initialization deadline exceeded')
finally:
    (run / 'events.json').write_text(json.dumps(events, ensure_ascii=False, indent=2), encoding='utf-8')
    if session:
        try: session.detach()
        except Exception: pass
    try: device.kill(pid)
    except frida.ProcessNotFoundError: pass
    registry_backup=root/'work/runtime/user_backup_20261013/rawfury-playerprefs.reg'
    if registry_backup.exists():
        subprocess.run(['reg','export',r'HKCU\Software\Raw Fury\Townscaper',str(run/'registry-after.reg'),'/y'],check=True,capture_output=True)
        subprocess.run(['reg','import',str(registry_backup)],check=True,capture_output=True)
