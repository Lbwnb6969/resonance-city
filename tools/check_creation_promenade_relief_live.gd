extends "res://tools/check_creation_three_road_modes_live.gd"
func relief(value:float)->int:
 var found:Dictionary={}
 for node:Node in demo.town.find_children("*","GeometryInstance3D",true,false):
  var materials:Array=[node.material_override]
  if node is MeshInstance3D and node.mesh!=null:
   for i in range(node.mesh.get_surface_count()):materials.append(node.get_active_material(i))
  for mat in materials:
   if mat is ShaderMaterial and mat.shader!=null and mat.shader.resource_path in ["res://scripts/visual/shaders/creation_promenade.gdshader","res://scripts/visual/shaders/creation_road.gdshader","res://scripts/visual/shaders/creation_road_draft.gdshader"]:
    mat.set_shader_parameter("promenade_relief",value);found[mat.shader.resource_path]=true
 return found.size()
func road_shape()->Dictionary:
 var result:Dictionary={}
 for id in demo.town.road_roots:
  var pieces:Array=[]
  for mesh in demo.town.road_roots[id].find_children("*","MeshInstance3D",true,false):
   if mesh.mesh==null:continue
   for i in range(mesh.mesh.get_surface_count()):pieces.append(var_to_bytes(mesh.mesh.surface_get_arrays(i)).hex_encode().sha256_text())
  pieces.sort();result[id]=pieces
 return result
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
 var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
 var city:=State.new();city.initialize_free()
 check(city.add_road([Vector2(-32,-20),Vector2(-12,-20)] as Array[Vector2],"promenade","none").ok,"public dry stone promenade")
 check(city.add_road([Vector2(-12,4),Vector2(12,4)] as Array[Vector2],"promenade","none").ok,"public river promenade bridge")
 await show(city,Vector2(-23,-20),"石板浅倒角");await settle();quiet();demo.ui_layer.hide();demo.weather_visual.hide()
 var saved:Dictionary=demo.state.snapshot();var geometry:=road_shape()
 for view:Array in [["near",Vector2(-23,-20),7.],["normal",Vector2(-23,-20),24.],["bridge",Vector2(0,4),16.],["far",Vector2(-16,-8),65.]]:
  demo.focus=Vector3(view[1].x,.3,view[1].y);demo.zoom=view[2];demo.pitch=.65;demo.yaw=.25;demo._update_camera()
  for phase in [0,2]:
   demo._set_light_phase(phase)
   # Sky radiance updates across frames; settle before paired material captures.
   for i in range(60):await process_frame
   for strength in [0.,1.]:
    check(relief(strength)>=1,"published production material owns relief control")
    for i in range(5):await process_frame
    await capture(view[0]+"_"+str(phase)+"_"+str(int(strength)))
 check(demo.state.snapshot()==saved and road_shape()==geometry,"relief leaves author state and all road mesh arrays unchanged")
 demo.select_tool(2);demo.road_style="promenade";road_tool=demo.get_meta("road_tool");road_tool.set_mode(0)
 demo.focus=Vector3(-23,.3,-17);demo.zoom=16.;demo._update_camera()
 await motion(Vector2(-29,-16));await button(Vector2(-29,-16),true);await motion(Vector2(-19,-16))
 check(demo.road_drawing and demo.state.snapshot()==saved,"real held promenade preview is transient")
 await capture("held_preview");await key(KEY_ESCAPE);await button(Vector2(-19,-16),false)
 check(demo.state.snapshot()==saved,"cancelled preview preserves city")
 var cold:=State.new();check(cold.restore(saved).ok,"independent State restore")
 await show(cold,Vector2(-23,-20),"冷读石板路");await settle()
 check(road_shape()==geometry,"cold renderer retains same complete road geometry")
 check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save bytes unchanged")
 var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"persistence":demo.persistence,"facts":facts}
 FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("PROMENADE_RELIEF ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
