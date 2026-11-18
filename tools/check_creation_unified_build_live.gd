extends "res://tools/check_creation_playtest_edit_live.gd"
func point(at:Vector3)->void:
 var pos:Vector2=demo.camera.unproject_position(at);var e:=InputEventMouseMotion.new();e.device=92;e.position=pos;e.global_position=pos;root.push_input(e);await process_frame;await process_frame
func click3(at:Vector3,pressed:bool)->void:
 var pos:Vector2=demo.camera.unproject_position(at);var e:=InputEventMouseButton.new();e.device=92;e.position=pos;e.global_position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;root.push_input(e);await process_frame
func tap_control(control:Control)->void:
 var pos:=control.get_global_rect().get_center()
 for down:bool in [true,false]:
  var event:=InputEventMouseButton.new();event.device=92;event.position=pos;event.global_position=pos;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event);await process_frame
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
 var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();road_tool=demo.get_meta("road_tool")
 var city:=State.new();city.initialize_free();city.add_house(Vector2(-22,-20));var id:String=city.houses[0].id
 city.add_cells(id,[{"x":1,"z":0,"level":0,"kind":"room"},{"x":0,"z":0,"level":1,"kind":"room"},{"x":1,"z":0,"level":1,"kind":"room"}])
 var chosen:={"ok":true,"id":"unified","title":"Unified building","world":city.snapshot(),"view":{"focus":[-21.,1.,-20.],"zoom":13.,"yaw":0.,"pitch":.65,"evening":false,"light_phase":0}}
 await demo.gallery._open_chosen(chosen);await settle();quiet();demo.select_tool(0)
 if "--narrow" in OS.get_cmdline_user_args():
  root.size=Vector2i(800,540);await settle();await tap_control(demo.tool_buttons[0]);await settle()
  var palette:Control=demo.tactile_dock.bubble_rows.get_node("NewHousePalette")
  var timber:Button=palette.cards["style/timber"]
  check(timber.is_visible_in_tree() and root.get_visible_rect().encloses(timber.get_global_rect()),"timber card visible and on screen")
  facts.panel=palette.get_global_rect();await capture("narrow_chooser");await tap_control(timber);await settle()
  check(not palette.is_visible_in_tree() and demo.tool==0,"choosing a shape clears the placement area and keeps the brush")
  var site:=Vector3(-21.,0.,-16.);await point(site);await capture("narrow_place")
  check(demo.candidate.get("new_house",false) and demo.candidate.valid,"standalone placement preview ready")
  await click3(site,true);await click3(site,false);await settle()
  check(demo.state.houses.size()==2 and demo.state.houses[-1].get("style","")=="timber","screen tap builds the chosen timber house")
  await key(KEY_Z,true);await settle();check(demo.state.houses.size()==1,"Undo removes only the new house")
  await tap_control(demo.tool_buttons[0]);await settle()
  check(timber.is_visible_in_tree() and timber.button_pressed,"reopening the narrow chooser retains the selected timber card")
  root.size=Vector2i(1440,900);await settle();await tap_control(palette.cards["style/stone"]);await settle()
  check(palette.is_visible_in_tree() and palette.cards["style/stone"].button_pressed,"roomy window keeps the chooser open for repeated choices")
  await complete_report(personal);return
 var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size()
 var wall:=Vector3(-22,2.5,-19.1)
 await point(wall);facts["wall_candidate"]=demo.candidate.duplicate(true)
 check(demo.candidate.has("cell") and demo.candidate.cell.kind=="terrace" and demo.candidate.cell.level==1 and demo.candidate.valid,"same building tool automatically previews a second-floor side terrace")
 check(not demo.candidate.has("select") and demo.tool==0,"side building needs no house selection or terrace mode")
 check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"hover preview changes no authoring data or history")
 await capture("upper_side_automatic_preview")
 await click3(wall,true);check(demo.house_drawing and demo.house_stroke.cells[0].kind=="terrace","native press starts terrace through normal house stroke")
 await point(Vector3(-20.2,2.5,-19.1));check(demo.state.snapshot()==before,"held terrace stroke remains transient")
 await click3(Vector3(-20.2,2.5,-19.1),false);await settle();quiet()
 var added:Array=demo.state.houses[0].cells.filter(func(c):return c.kind=="terrace")
 check(added.size()==2 and added.all(func(c):return c.level==1 and c.z==1),"native drag commits both supported upper terraces in one gesture")
 check(demo.state._undo.size()==depth+1 and demo.state.houses.size()==1,"automatic attachment retains one house and one history entry")
 var built:Array=demo.state.houses.duplicate(true);await capture("upper_terraces_committed")
 await key(KEY_Z,true);await settle();check(demo.state.houses==before.houses,"one native Undo removes complete terrace gesture")
 await key(KEY_Y,true);await settle();check(demo.state.houses==built,"one native Redo restores exact terrace cells")
 demo.select_tool(0);await point(Vector3(-22,0,-18.2));facts["ground_candidate"]=demo.candidate.duplicate(true)
 check(demo.candidate.has("cell") and demo.candidate.cell.kind=="room" and demo.candidate.cell.level==0,"ground near the same house automatically previews room extension")
 before=demo.state.snapshot();await click3(Vector3(-22,0,-18.2),true);await key(KEY_ESCAPE);await click3(Vector3(-22,0,-18.2),false)
 check(demo.state.snapshot()==before and demo.tool==-1,"Escape cancels automatic ground extension and leaves empty hand")
 demo.select_tool(0);await point(Vector3(-22,0,-18.2));before=demo.state.snapshot()
 await click3(Vector3(-22,0,-18.2),true);await click3(Vector3(-22,0,-18.2),false);await settle();quiet()
 check(demo.state.houses.size()==1 and demo.state.houses[0].cells.any(func(c):return c.level==0 and c.z==1 and c.kind=="room"),"same tool commits ground extension into existing house")
 await key(KEY_Z,true);await settle();check(demo.state.houses==before.houses,"ground extension Undo restores all earlier upper terraces")
 demo.select_tool(0);await point(Vector3(-28,0,-18));facts["empty_candidate"]=demo.candidate.duplicate(true)
 check(demo.candidate.has("new_house") and demo.candidate.valid,"same tool previews standalone house away from neighbours")
 await capture("standalone_preview")
 before=demo.state.snapshot();await click3(Vector3(-28,0,-18),true);await click3(Vector3(-28,0,-18),false);await settle();quiet()
 check(demo.state.houses.size()==2,"same tool commits a separate house on distant empty ground")
 await key(KEY_Z,true);await settle();check(demo.state.houses==before.houses,"standalone Undo preserves original attached house")
 await complete_report(personal)
