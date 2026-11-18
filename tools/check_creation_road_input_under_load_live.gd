extends "res://tools/check_creation_policy_scale_live.gd"
var input_ground:RefCounted
var input_trace:Array=[]
func screen(at:Vector2)->Vector2:
	# Read the published field directly; never prepare the edited live State.
	return demo.camera.unproject_position(Vector3(at.x,input_ground.height_at(at),at.y))
func send_event(event:InputEvent,label:String)->void:
	event.device=92
	var began:=Time.get_ticks_usec();var pending:bool=demo.edit_pending();var ground_before:int=demo.state._ground_revision
	Input.parse_input_event(event)
	var row:Dictionary={"label":label,"return_ms":(Time.get_ticks_usec()-began)/1000.,"pending_before":pending,"ground_before":ground_before,"pending_after":demo.edit_pending(),"revision":demo.state.revision,"roads":demo.state.roads.size(),"draft":road_tool.phase}
	input_trace.append(row)
	await process_frame
	row.ground_after=demo.state._ground_revision;row.profile=road_tool.get_meta("input_profile",{}).duplicate(true);row.frame_ms=(Time.get_ticks_usec()-began)/1000.;row.after_frame_draft=road_tool.phase;row.after_frame_roads=demo.state.roads.size();row.after_frame_pending=demo.edit_pending()
func move_to(at:Vector2,label:String)->void:
	var event:=InputEventMouseMotion.new();event.position=screen(at);event.global_position=event.position
	await send_event(event,label)
func mouse_at(at:Vector2,down:bool,label:String)->void:
	var event:=InputEventMouseButton.new();event.position=screen(at);event.global_position=event.position;event.pressed=down;event.button_index=MOUSE_BUTTON_LEFT
	await send_event(event,label)
func key_state(code:Key,down:bool,label:String)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	await send_event(event,label)
func escape()->void:
	await key_state(KEY_ESCAPE,true,"Escape pressed");await key_state(KEY_ESCAPE,false,"Escape released")
func draft(from:Vector2,to:Vector2,label:String)->void:
	demo.select_tool(2);road_tool.set_mode(0)
	await move_to(from,label+" hover");await mouse_at(from,true,label+" press")
	for i in range(1,9):await move_to(from.lerp(to,float(i)/8.),label+" move"+str(i))
func screenshot(label:String)->void:
	# Verification GPU readback/export is excluded from the input frame window.
	sampling=false;await process_frame;await capture(label)
	last_frame_usec=Time.get_ticks_usec();sampling=true
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);var began:=Time.get_ticks_usec()
	var source:="res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json";var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	var loaded:=await open_scale(data,"300屋后台输入");demo.life.set_process(false);road_tool=demo.get_meta("road_tool")
	check(demo.state.houses.size()==300 and demo.town.house_roots.size()==300,"original300 actually published")
	input_ground=demo.state._ground_terrain.get_script().new();input_ground.copy_cache_from(demo.state._ground_terrain)
	var before:Dictionary=demo.state.snapshot();demo.focus=Vector3(-31,0,33);demo.zoom=22.;demo.yaw=.4;demo.pitch=.8;demo._update_camera();root.grab_focus()
	await process_frame;await process_frame;check(root.has_focus(),"actual native input window focused")
	var recording:=Span.start();var started:=Time.get_ticks_usec();var first:Dictionary=demo.state.add_road(remote_bridge_points(),"promenade","none");demo._after_edit(first,"road")
	check(first.ok and demo.edit_pending(),"real connected bridge starts background rebuild")
	var first_roads:Array=demo.state.roads.duplicate(true);frame_samples.clear();sampling=true;last_frame_usec=Time.get_ticks_usec()
	var focus:Vector3=demo.focus;await key_state(KEY_D,true,"WASD down")
	check(Input.is_physical_key_pressed(KEY_D),"native parsed physical key is held")
	for i in range(4):await process_frame
	await key_state(KEY_D,false,"WASD up")
	check(demo.focus.distance_to(focus)>.01 and not Input.is_physical_key_pressed(KEY_D),"WASD moves camera and releases during real rebuild")
	await escape();check(demo.tool==-1,"Escape enters actual empty hand during rebuild")
	focus=demo.focus;var at:=Vector2(-31,35);await move_to(at,"empty hand hover");await mouse_at(at,true,"empty hand press")
	var move:=InputEventMouseMotion.new();move.position=screen(at)+Vector2(24,16);move.global_position=move.position;move.relative=Vector2(24,16);await send_event(move,"empty hand drag")
	await mouse_at(at,false,"empty hand release")
	check(demo.focus.distance_to(focus)>.01 and not demo.camera_rig.navigation.dragging,"empty hand left drag responds and releases")
	check(demo.state.roads==first_roads,"camera and Escape never author roads")
	var cancel_start:=Vector2(-34,35);var cancel_end:=Vector2(-29,35)
	await draft(cancel_start,cancel_end,"cancelled stroke")
	var first_press:Dictionary={}
	for event_row:Dictionary in input_trace:
		if event_row.label=="cancelled stroke press":first_press=event_row;break
	check(not first_press.is_empty() and first_press.pending_before and first_press.after_frame_pending and first_press.ground_before==first_press.ground_after and first_press.ground_after!=first_press.revision,"first native road press during rebuild never prepares live protected terrain")
	check(road_tool.active() and demo.road_drawing and road_tool.valid.get("ok",false),"held freehand creates valid draft during real rebuild")
	check(demo.town.preview.find_children("*","MeshInstance3D",true,false).size()>0 and demo.state.roads==first_roads,"held draft has actual meshes and no author transaction")
	await screenshot("held_road_during_rebuild")
	await escape();await mouse_at(cancel_end,false,"cancelled stroke release")
	check(not road_tool.active() and not demo.road_drawing and demo.state.roads==first_roads,"Escape cancels held stroke without late release commit")
	var commit_start:=Vector2(-34,36.5);var commit_end:=Vector2(-28,36.5)
	await draft(commit_start,commit_end,"committed stroke")
	var pending_at_release:bool=demo.edit_pending();await mouse_at(commit_end,false,"commit while prior rebuild pending")
	check(pending_at_release and demo.state.roads.size()==before.roads.size()+2,"real second stroke commits while first rebuild pending")
	check(not road_tool.active() and not road_tool.pending_roads.rows.is_empty(),"committed stroke retains pending visible surface")
	await escape();await screenshot("committed_road_during_rebuild")
	await settle();quiet();sampling=false
	var sequence_to_publish_ms:float=(Time.get_ticks_usec()-started)/1000.
	var published:Dictionary=demo.town.budget_rebuild._published_snapshot
	check(not demo.edit_pending() and published.roads==demo.state.roads and demo.life.last_revision==demo.state.revision,"only latest complete geometry and network publish")
	check(demo.state.roads.all(func(r):return demo.town.road_roots.has(r.id)),"every authored road has actual final scene root")
	check(road_tool.pending_roads.rows.is_empty() and demo.town.get_meta("pending_road_masks",[]).is_empty(),"publication retires committed preview and grass masks")
	check(not demo.town.preview.has_node("ChemistryGhost") and demo.state.roads.size()==before.roads.size()+2,"cancelled or expired preview cannot reappear as author data")
	check(demo.state.houses==before.houses and demo.state.waters==before.waters and demo.state.terrain_strokes==before.terrain_strokes,"all original houses water and terrain preserved")
	var route:RefCounted=demo.life._network
	check(not route._route(route.connected_houses.h1,route._key(Vector2(16,-38.5))).is_empty(),"real home route still reaches first bridge endpoint")
	check(pool()==voices and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"player pool and personal save unchanged")
	var frames:=distribution(frame_samples);var pcm:=Span.finish(recording,OUT+"/input_Master.wav");check(pcm.ok,"actual ongoing natural Master PCM unclipped")
	await capture("latest_roads_published")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_usec()-began)/1000000.,"load":loaded,"input_to_publish_ms":sequence_to_publish_ms,"events":input_trace,"frames":frames,"pcm":pcm,"final_budget":demo.edit_budget_report(),"life_cancelled_jobs":demo.life.budget_cancelled_jobs,"life_final_prepare":demo.life._network.prepare_stats.duplicate(true),"works":demo.collection_directory,"source":source,"source_sha256":FileAccess.get_sha256(source),"boundary":"Published terrain used for projection; no live ground preparation by test. Image readback/export and PCM analysis excluded from frame window. Input return times are queue costs; frame_ms records event-to-next-frame processing, not an FPS approval or subjective art/audio claim."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_INPUT_UNDER_LOAD ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
