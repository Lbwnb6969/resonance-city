"""Verify original captured frames without asserting animated pixel equality."""
import hashlib
import json
import sys
from pathlib import Path

root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'work/asset_pydeps'))
from PIL import Image

rows=[]
for label in ('before','after','undone','redone'):
    path=root/'outputs'/f'townscaper_runtime_render_{label}.png'
    with Image.open(path) as im:
        im.load()
        rgb=im.convert('RGB')
        colors=len(rgb.getcolors(rgb.width*rgb.height) or [])
        assert im.format=='PNG' and im.size==(2560,1440) and colors>1000
        rows.append({'label':label,'file':str(path.relative_to(root/'outputs')).replace('\\','/'),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'size':list(im.size),'distinct_rgb_colors':colors})
log=(root/'work/runtime/grid_graphics_probe/Player.log').read_text(encoding='utf-8',errors='replace')
lines=log.splitlines()
result={'kind':'instrumented-original-runtime','observation_record':'townscaper_runtime_grid.json','capture_api':'UnityEngine.ScreenCapture.CaptureScreenshot on original main thread','graphics_backend':'Direct3D 11','backend_log':[line.strip() for line in lines if any(t in line for t in ('Forcing GfxDevice:','Version:  Direct3D','Renderer:','Driver:'))],'frames':rows,'checks':{'all_png_decoded':True,'all_non_flat':True,'d3d11_logged':'Forcing GfxDevice: Direct3D 11' in log},'visual_review':'Original full game scene: buildings, roof/windows, decorations, birds, sea/reflection, sandbank, shadow and palette/settings UI visible in after frame. First run captured startup logo and is preserved in discarded/runtime-first-render-splash.','limits':'These four frames come from the latest grid_graphics_probe, whose operation/capture record is townscaper_runtime_grid.json. The earlier graphics_ready_probe reused the same output paths; townscaper_runtime_graphics.json retains its separate native operation observations but its four image files were superseded by this run. This confirms original D3D11 rendering and captured output. Recompiled HLSL has not replaced original shader programs. Water, birds and other time-dependent visuals prevent asserting pixel-identical Undo/Redo; generated module snapshots and save strings have independent equality checks. Requested command-line size960x640 was overridden by game settings; actual captured size2560x1440 is recorded.'}
(root/'outputs/townscaper_runtime_render_verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'frames':len(rows),'checks':result['checks']}))
