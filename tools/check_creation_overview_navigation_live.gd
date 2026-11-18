extends "res://tools/check_creation_playtest_edit_live.gd"
func held(code:Key,pressed:bool)->void:
 var e:=InputEventKey.new();e.device=92;e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e)
 await process_frame
func mouse(at:Vector2,pressed:bool)->void:
 var e:=InputEventMouseButton.new();e.device=92;e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;root.push_input(e)
 await process_frame
func move_screen(at:Vector2,relative:Vector2)->void:
 var e:=InputEventMouseMotion.new();e.device=92;e.position=at;e.global_position=at;e.relative=relative;root.push_input(e)
 await process_frame
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
 var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();road_tool=demo.get_meta("road_tool")
 var before:Dictionary=demo.state.snapshot();var history:int=demo.state._undo.size()
 demo.select_tool(5);await key(KEY_ESCAPE);await process_frame
 check(demo.tool==-1 and not demo.vegetation_panel.visible and not demo.tactile_dock.popup.visible,"Escape leaves empty hand and hides tool context")
 check(demo.tool_buttons.all(func(b):return not b.active),"empty hand has no active tool seal")
 check(demo.candidate.is_empty() and not demo.house_drawing and not demo.vegetation_drawing,"empty hand has no authoring candidate or stroke")
 var focus:Vector3=demo.focus;var at:=Vector2(500,420)
 await mouse(at,true);await move_screen(at+Vector2(80,35),Vector2(80,35));await mouse(at+Vector2(80,35),false)
 check(demo.focus.distance_to(focus)>.1 and not demo.camera_rig.navigation.dragging,"native left drag pans empty hand then releases")
 focus=demo.focus;await move_screen(at+Vector2(120,35),Vector2(40,0))
 check(demo.focus==focus,"released pointer motion cannot continue panning")
 for code:Key in [KEY_W,KEY_A,KEY_S,KEY_D]:
  focus=demo.focus;await held(code,true)
  for i in range(8):await process_frame
  await held(code,false)
  check(demo.focus.distance_to(focus)>.01,"native WASD moves overview "+str(code))
 focus=demo.focus
 for i in range(3):await process_frame
 check(demo.focus==focus,"released WASD stops immediately")
 var field:=LineEdit.new();field.position=Vector2(400,150);field.size=Vector2(200,40);root.add_child(field);field.grab_focus();await process_frame
 focus=demo.focus;await held(KEY_W,true)
 for i in range(4):await process_frame
 await held(KEY_W,false)
 check(demo.focus==focus,"text focus owns WASD and prevents camera movement")
 field.release_focus();field.queue_free();await process_frame
 await key(KEY_J);await process_frame;focus=demo.focus
 await held(KEY_D,true)
 for i in range(4):await process_frame
 await held(KEY_D,false)
 check(demo.focus==focus,"journal owns keys without moving the camera")
 await key(KEY_ESCAPE);await process_frame
 check(not demo.journal.panel.visible and demo.tool==-1,"Escape closes journal while retaining empty hand")
 var button:Button=demo.tool_buttons[5];await mouse(button.get_global_rect().get_center(),true);await mouse(button.get_global_rect().get_center(),false)
 check(demo.tool==5 and button.active,"native tool seal resumes planting after empty hand")
 demo.select_tool(2);await motion(Vector2(-20,25));await button(Vector2(-20,25),true);trace(Vector2(-16,26));await process_frame
 check(demo.road_drawing,"native road draft starts before Escape")
 await key(KEY_ESCAPE);await button(Vector2(-16,26),false)
 check(demo.tool==-1 and not demo.road_drawing and demo.state.roads.is_empty(),"Escape cancels held road and enters empty hand without authoring")
 check(demo.state.snapshot()==before and demo.state._undo.size()==history,"all navigation and cancellation preserve exact world and history")
 await capture("empty_hand_overview")
 await complete_report(personal)
