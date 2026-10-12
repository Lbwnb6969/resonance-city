import bpy, json, hashlib
from pathlib import Path
out=Path(__file__).resolve().parent
cube=bpy.data.objects['Cube']
cube.name='CLI_Probe'
cube.scale=(1.0, 0.75, 1.25)
material=bpy.data.materials.new('ProbeMaterial')
material.diffuse_color=(0.55, 0.7, 0.8, 1.0)
cube.data.materials.append(material)
bpy.context.view_layer.objects.active=cube
bpy.ops.object.select_all(action='DESELECT')
cube.select_set(True)
assert tuple(cube.scale)==(1.0, 0.75, 1.25)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'probe.blend'))
bpy.ops.export_scene.gltf(filepath=str(out/'probe.glb'), export_format='GLB', use_selection=True)
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.device='CPU'
scene.cycles.samples=1
scene.render.resolution_x=64
scene.render.resolution_y=64
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.filepath=str(out/'probe.png')
bpy.ops.render.render(write_still=True)
outputs={}
for name in ['probe.blend','probe.glb','probe.png']:
    raw=(out/name).read_bytes()
    assert raw
    outputs[name]={'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
assert (out/'probe.glb').read_bytes()[:4]==b'glTF'
result={'status':'PASS','blender_version':bpy.app.version_string,'build_hash':bpy.app.build_hash.decode(),'tested':['background Python','create material and modify mesh object','save .blend','export selected GLB','64x64 CPU render'],'outputs':outputs,'scope':'standalone factory-startup verification only; no project assets replaced; no MCP configured'}
(out/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('BLENDER_CLI_PROBE PASS '+bpy.app.version_string)
