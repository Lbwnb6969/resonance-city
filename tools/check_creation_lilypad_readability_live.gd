extends "res://tools/check_creation_shape_palette_live.gd"
const Garden=preload("res://tools/fixtures/city_creation_space_contract_fixture.gd")
const Before=preload("res://tests/fixtures/city_creation_lilypad_legacy.gdshader")
const After=preload("res://scripts/visual/shaders/creation_lilypad.gdshader")
func material(after:bool)->void:
 for part:String in ["leaf","flower"]:demo.town.lilypads._material(part).shader=After if after else Before
func records()->String:
 var rows:Array=[];var keys:Array=demo.town.lilypads.blocks.keys();keys.sort()
 for key in keys:
  var node:Node3D=demo.town.lilypads.blocks[key];rows.append([key,node.get_meta("candidates")])
  for child in node.get_children():rows.append([str(child.name),child.multimesh.buffer,child.multimesh.mesh.surface_get_arrays(0)])
 return var_to_bytes(rows).hex_encode().sha256_text()
func isolated_masks()->void:
 var viewport:=SubViewport.new();viewport.size=Vector2i(256,256);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=1.;viewport.add_child(env)
 var camera:=Camera3D.new();viewport.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.9;camera.position=Vector3(0,2,0);camera.look_at(Vector3.ZERO,Vector3.FORWARD)
 var node:=MultiMeshInstance3D.new();var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_custom_data=true;multi.use_colors=true;multi.mesh=demo.town.lilypads._mesh("leaf");multi.instance_count=1;multi.set_instance_transform(0,Transform3D.IDENTITY);multi.set_instance_color(0,Color.WHITE);node.multimesh=multi;viewport.add_child(node)
 var mat:ShaderMaterial=demo.town.lilypads._material("leaf").duplicate();node.material_override=mat;facts.masks=[]
 for seed:float in [0.,.18524452582589457,1.]:
  multi.set_instance_custom_data(0,Color(seed,0,0,0));var counts:Array=[]
  for stage:int in [0,1]:
   mat.shader=Before if stage==0 else After
   await process_frame;await process_frame;await RenderingServer.frame_post_draw
   var image:=viewport.get_texture().get_image();image.save_png(OUT+"/mask_"+str(seed)+"_"+str(stage)+".png");var count:=0
   for y in range(256):
    for x in range(256):
     if image.get_pixel(x,y).a>.5:count+=1
   counts.append(count)
   # UV(.5,.15) is model z=-.2333: the notch must be open at every seed.
   if stage==1:
    var pixel:Vector2=camera.unproject_position(Vector3(0,0,-.2333333));check(image.get_pixelv(Vector2i(pixel)).a<.5,"real GPU cleft remains open at seed "+str(seed))
  if seed<.2:check(counts[1]<counts[0]-100,"low-seed circular disc loses intended cleft pixels "+str(seed))
  facts.masks.append({"seed":seed,"before_pixels":counts[0],"after_pixels":counts[1]})
 viewport.queue_free();await process_frame
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
 var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
 var city:RefCounted=Garden.courtyard("ring","none").city
 check(city.add_water([Vector2(-33,-17)] as Array[Vector2],2.,"pond").ok,"real single-stroke pond")
 await show(city,Vector2(-33,-17),"睡莲辨识度");quiet();demo.life.set_process(false);demo.ui_layer.hide();demo.weather_visual.hide();demo.town.wildlife.hide();demo.town.clear_preview();demo.set_process(false)
 var author:Dictionary=demo.state.snapshot();var original:=records();var terrain:=var_to_bytes(demo.state._ground_terrain.vertices).hex_encode().sha256_text()
 for view:Array in [["close",5.],["normal",18.]]:
  demo.focus=Vector3(-33,-.16,-17);demo.zoom=view[1];demo.pitch=.9;demo.yaw=.25;demo._update_camera()
  for phase:int in [0,2]:
   demo._set_light_phase(phase)
   for i in range(60):await process_frame
   for stage:int in [0,1]:
    material(stage==1)
    for i in range(4):await process_frame
    await capture(view[0]+"_"+str(phase)+"_"+str(stage))
 material(true);await isolated_masks()
 check(records()==original and demo.state.snapshot()==author,"shader leaves all source meshes transforms seeds and authored data unchanged")
 check(terrain==var_to_bytes(demo.state._ground_terrain.vertices).hex_encode().sha256_text(),"actual pond bed remains byte-identical")
 demo.set_process(true)
 demo._after_edit(demo.state.remove_water_at(Vector2(-33,-17)),"water");await settle();quiet();check(demo.town.lilypads.diagnostics().leaves==0,"filling actual pond withdraws derived leaf")
 await key(KEY_Z,true);await settle();quiet();check(records()==original,"native Undo restores exact derived records and mesh buffers")
 var path:=OUT+"/pond.json";check(demo.state.save_city(path).ok,"isolated work saves");var cold:=State.new();check(cold.load_city(path).ok,"independent State reads actual saved work");await show(cold,Vector2(-33,-17),"冷读睡莲");await settle();quiet();check(records()==original,"independent cold renderer reproduces all leaf source geometry and buffers")
 check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save bytes unchanged")
 var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-began)/1000.,"persistence":demo.persistence}
 FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("LILYPAD_READABILITY ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
