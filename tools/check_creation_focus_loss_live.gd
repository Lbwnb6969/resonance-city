extends "res://tools/check_creation_unified_build_live.gd"
var outside:Window
var lost:=0
func lose_focus()->void:
 outside.show();outside.grab_focus()
 check(await wait_for(func():return not root.has_focus(),2000),"native auxiliary window takes focus")
 await process_frame;await process_frame
func return_focus()->void:
 outside.hide();root.grab_focus()
 check(await wait_for(func():return root.has_focus(),2000),"actual game window regains focus")
 await process_frame
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60;root.gui_embed_subwindows=false
 var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
 root.focus_exited.connect(func():lost+=1)
 outside=Window.new();outside.title="Focus verification";outside.size=Vector2i(260,100);outside.position=Vector2i(20,20);outside.visible=false;root.add_child(outside)
 var city:=State.new();city.initialize_free();await show(city,Vector2(-25,-20),"失焦取消笔画");await settle();quiet();root.grab_focus();await wait_for(func():return root.has_focus(),2000)
 var modes:Array=[0] if "--baseline" in OS.get_cmdline_user_args() else [0,2,5,6,8]
 for tool:int in modes:
  demo.select_tool(tool)
  if tool==2:demo.get_meta("road_tool").set_mode(0)
  if tool==5:demo.vegetation_kind="olive";demo.vegetation_single=false
  var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();var at:=Vector3(-25,0,-20)
  await point(at);await click3(at,true);await point(at+Vector3(3,0,0));await process_frame
  var active:bool=demo.house_drawing or demo.road_drawing or demo.vegetation_drawing or demo.water_drawing or demo.terrain_brush.drawing
  check(active and demo.state.snapshot()==before,"real held gesture is transient tool"+str(tool))
  await lose_focus()
  check(not demo.house_drawing and not demo.road_drawing and not demo.vegetation_drawing and not demo.water_drawing and not demo.terrain_brush.drawing and not demo.get_meta("road_tool").active(),"native focus loss cancels held gesture tool"+str(tool))
  await return_focus();await click3(at+Vector3(3,0,0),false);await settle();quiet()
  check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"late native release cannot author or add history tool"+str(tool))
  if "--baseline" in OS.get_cmdline_user_args():break
 if not "--baseline" in OS.get_cmdline_user_args():
  demo.select_tool(0);await point(Vector3(-25,0,-20));await click3(Vector3(-25,0,-20),true);await click3(Vector3(-25,0,-20),false);await settle();quiet()
  check(demo.state.houses.size()==1,"fresh gesture after returning still builds normally")
  var built:Array=demo.state.houses.duplicate(true);await key(KEY_Z,true);await settle();check(demo.state.houses.is_empty(),"native Undo removes fresh gesture");await key(KEY_Y,true);await settle();check(demo.state.houses==built,"native Redo restores fresh gesture")
  demo.selected_house="h1";demo.select_tool(4);demo.selected_house="h1";await key(KEY_R);await process_frame
  var rotate=demo.get_meta("house_rotation_input");check(not rotate.target.is_empty(),"actual free rotation enters transient preview")
  var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();await lose_focus();check(rotate.target.is_empty() and demo.town.visible,"loss cancels free rotation and restores published city")
  await return_focus();await click3(Vector3(-25,0,-20),true);await click3(Vector3(-25,0,-20),false);await settle();check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"return click cannot commit stale rotation")
 if not "--baseline" in OS.get_cmdline_user_args():
  var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();demo.spatial_popover.close();demo.select_tool(-1)
  await point(Vector3(-28,0,-24));await click3(Vector3(-28,0,-24),true);check(demo.camera_rig.navigation.dragging,"native empty-hand pointer capture starts")
  await lose_focus();check(not demo.camera_rig.navigation.dragging,"native focus loss releases empty-hand camera capture");await return_focus();await click3(Vector3(-28,0,-24),false)
  demo.select_tool(0);await point(Vector3(-28,0,-24))
  var event:=InputEventMouseButton.new();event.device=92;event.position=demo.camera.unproject_position(Vector3(-28,0,-24));event.global_position=event.position;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.ctrl_pressed=true;event.shift_pressed=true;root.push_input(event);await process_frame
  var batch=demo.get_meta("batch_edit");check(batch.selection.dragging,"native modified pointer starts selection rectangle")
  await lose_focus();check(not batch.selection.dragging,"native focus loss releases selection rectangle");await return_focus();await click3(Vector3(-28,0,-24),false)
  demo.orbiting=true;demo.panning=true;await lose_focus();check(not demo.orbiting and not demo.panning,"focus release clears both legacy camera flags");await return_focus()
  check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"camera and box selection focus transitions leave authored history unchanged")
 check(lost>0 and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"real native focus notifications and personal bytes preserved")
 await capture("after_focus_return")
 var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"focus_exits":lost,"seconds":(Time.get_ticks_msec()-began)/1000.,"persistence":demo.persistence}
 FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("FOCUS_LOSS ",JSON.stringify(report));outside.queue_free();demo.queue_free();await process_frame;quit(0 if report.ok else 1)
