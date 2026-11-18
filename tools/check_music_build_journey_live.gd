extends "res://tools/check_game_music_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
var trial:Node
var input_ground:RefCounted
var events:Array=[]
var frame_samples:Array=[]
var sampling:=false
var previous_frame:=0
var trace:Array=[]
func _process(_delta:float)->bool:
	var now:=Time.get_ticks_usec()
	if sampling and previous_frame>0:frame_samples.append((now-previous_frame)/1000.)
	previous_frame=now;return false
func active()->bool:return is_instance_valid(trial.conductor) and trial.conductor.active
func screen(at:Vector2)->Vector2:return demo.camera.unproject_position(Vector3(at.x,input_ground.height_at(at),at.y))
func event_send(event:InputEvent,label:String)->void:
	event.device=92;var began:=Time.get_ticks_usec();var pending:bool=demo.edit_pending();root.push_input(event)
	events.append({"label":label,"queue_ms":(Time.get_ticks_usec()-began)/1000.,"pending_before":pending,"houses":demo.state.houses.size(),"revision":demo.state.revision});await process_frame
func move(at:Vector2)->void:
	var event:=InputEventMouseMotion.new();event.position=screen(at);event.global_position=event.position;await event_send(event,"motion")
func mouse(at:Vector2,down:bool)->void:
	var event:=InputEventMouseButton.new();event.position=screen(at);event.global_position=event.position;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;await event_send(event,"press" if down else "release")
func key_held(code:Key,down:bool)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event);await process_frame
func stat(values:Array)->Dictionary:
	if values.is_empty():return {}
	var ordered:=values.duplicate();ordered.sort();return {"count":ordered.size(),"median_ms":ordered[ordered.size()/2],"p95_ms":ordered[mini(ordered.size()-1,floori(ordered.size()*.95))],"max_ms":ordered.back()}
func image(label:String)->void:
	sampling=false;await capture(label);previous_frame=Time.get_ticks_usec();sampling=true
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	demo.focus=Vector3(-21,.4,26);demo.zoom=34.;demo.yaw=0.;demo.pitch=1.;demo._update_camera()
	input_ground=demo.state._ground_terrain.get_script().new();input_ground.copy_cache_from(demo.state._ground_terrain)
	trial=Trial.new();demo.add_child(trial);check(trial.install(demo),"actual L trial installs in isolated empty creation")
	for i in range(trial.packs.size()):
		if trial.packs[i].name.begins_with("1-04") and "remaining_v2" in trial.packs[i].manifest:trial.picker.select(i);break
	demo.ledger.open_panel();await create_timer(.4).timeout;var recording:=Span.start();await ui_click(trial.play_button);check(await wait_for(active,30000),"actual L button starts sparse full-song candidate from beginning")
	if not active():quit(1);return
	var node:Node=trial.conductor;var first:String=node.prepared.manifest.source_id;var duration:float=float(node.prepared.manifest.frames)/44100.;check(node.player.get_playback_position()<1. and node.values.body==0. and node.values.motion==0.,"actual start is background-only at source zero")
	await key(KEY_ESCAPE);demo.select_tool(0);sampling=true;previous_frame=Time.get_ticks_usec();var placements:Array=[]
	for row in range(4):
		for column in range(5):
			var at:=Vector2(-30+column*4.5,19+row*4.5);var before:int=demo.state.houses.size();await move(at);await mouse(at,true);await mouse(at,false)
			placements.append({"at":at,"before":before,"after":demo.state.houses.size(),"pending":demo.edit_pending(),"source_id":node.prepared.manifest.source_id,"position":node.player.get_playback_position()})
			check(demo.state.houses.size()==before+1,"native house release commits one actual house "+str(row*5+column+1))
			if demo.state.houses.size()!=before+1:break
		check(node.prepared.manifest.source_id==first and node.player.playing,"whole source survives native row "+str(row));print("MUSIC_BUILD houses=",demo.state.houses.size()," cursor=",node.player.get_playback_position())
	check(demo.state.houses.size()==20,"all twenty houses came from actual native gestures")
	await settle();check(demo.town.house_roots.size()==20 and demo.life.last_revision==demo.state.revision,"all twenty house meshes and live network publish latest author revision")
	var road=demo.get_meta("road_tool");demo.select_tool(2);road.set_mode(0);var a:=Vector2(-30,34.8);var b:=Vector2(-12,34.8);var roads_before:int=demo.state.roads.size();var history:int=demo.state._undo.size()
	await move(a);await mouse(a,true)
	for i in range(31):await move(a.lerp(b,float(i)/30.)+Vector2(0,sin(i*.20)*.65));await create_timer(.08).timeout
	check(demo.road_drawing and road.active() and demo.state.roads.size()==roads_before and demo.state._undo.size()==history,"actual held curved stroke stays preview while musical source continues")
	check(node.values.body==0. and node.values.motion==0. and node.prepared.manifest.source_id==first,"continuous native construction cannot preactivate optional colors")
	await mouse(b+Vector2(0,sin(6.)*.65),false);check(demo.state.roads.size()==roads_before+1,"native curved stroke release authors one transaction")
	await settle();await key(KEY_ESCAPE);demo.zoom=24.;demo.focus=Vector3(-21,.4,31.5);demo._update_camera();var road_id:String=demo.state.roads[-1].id
	await create_timer(12.).timeout
	check(node.spatial_facts.flow<.35 and node.values.body==0. and node.values.motion==0.,"one weak local curve across twenty homes preserves sparse background below observation threshold")
	facts.flow_enter={"values":node.values.duplicate(true),"facts":node.spatial_facts.duplicate(true),"position":node.player.get_playback_position()};await image("twenty_houses_flow")
	await key(KEY_Z,true);await settle();check(demo.state.roads.size()==roads_before,"native Undo removes the whole actual road")
	await create_timer(6.5).timeout;check(node.values.body==0. and node.values.motion==0. and node.prepared.manifest.source_id==first,"road withdrawal returns sparse responses to exact zero without restarting source")
	await key(KEY_Y,true);await settle();check(demo.state.roads[-1].id==road_id,"native Redo restores same stable road identity")
	demo.select_tool(5);demo.vegetation_kind="weeping_willow";demo.vegetation_single=true;var plants:int=demo.state.plants.size();var plant_at:=Vector2(-33,34);await move(plant_at);await mouse(plant_at,true);await mouse(plant_at,false);await settle()
	check(demo.state.plants.size()==plants+1,"actual single-plant gesture adds willow while candidate plays")
	await key(KEY_ESCAPE);var focus:Vector3=demo.focus;await key_held(KEY_D,true);await create_timer(.2).timeout;await key_held(KEY_D,false);check(demo.focus.distance_to(focus)>.1 and not Input.is_physical_key_pressed(KEY_D),"actual held WASD responds and releases with music and town alive")
	demo.focus=Vector3(-21,.4,31.5);demo._update_camera();await create_timer(18.).timeout
	check(node.prepared.manifest.source_id==first and node.player.playing and node.values.body==0. and node.values.motion==0.,"Redo and planting preserve weak-context sparseness without changing complete source")
	facts.input_frames=stat(frame_samples);facts.input_events=events;facts.placements=placements;sampling=false;await capture("twenty_houses_after_edits")
	var deadline:=Time.get_ticks_msec()+int((duration+15.)*1000.);var previous:float=node.player.get_playback_position();var monotonic:=true;var last_second:=-1
	while node.prepared.manifest.source_id==first and not node.sequence.breathing and Time.get_ticks_msec()<deadline:
		await create_timer(.15).timeout
		if node.player.playing:var position:float=node.player.get_playback_position();monotonic=monotonic and position>=previous-.06;previous=position
		var second:=floori(node.clock)
		if second!=last_second:
			last_second=second;trace.append({"clock":node.clock,"position":node.player.get_playback_position(),"source_id":node.prepared.manifest.source_id,"values":node.values.duplicate(true)})
			if second%20==0:print("MUSIC_BUILD full=",second,"/",duration)
	check(node.sequence.breathing and monotonic and previous>duration-1.,"actual first complete song naturally finishes after twenty-house construction without seek")
	check(await wait_for(func():return node.prepared.manifest.source_id!=first,15000),"real complete ending and nature breath reach same-era sparse successor")
	check(node.prepared.manifest.schema=="city_sparse_music_v2" and node.prepared.manifest.era=="pastoral" and node.sequence.transitions.size()==1,"actual successor remains sparse and matches city era")
	await create_timer(2.).timeout;facts.pcm=Span.finish(recording,OUT+"/twenty_native_build_full_song_Master.wav");check(facts.pcm.ok,"entire native construction and natural successor Master PCM non-silent and unclipped")
	facts.first_duration=duration;facts.final_first_cursor=previous;facts.no_seek=true;facts.trace=trace;facts.transitions=node.sequence.transitions.duplicate(true)
	var snapshot:Dictionary=demo.state.snapshot();var saved:Dictionary=await demo.gallery._capture("二十屋连续营造","manual");check(saved.ok,"actual viewport collection preserves completed town and current music")
	var kept:Dictionary=demo.gallery.library.read(saved.id) if saved.ok else {};check(kept.get("ok",false) and kept.world.houses.size()==20 and kept.world.roads.size()==demo.state.roads.size() and kept.phonograph_mix.version==2 and kept.phonograph_mix.source_id==node.prepared.manifest.source_id,"actual cold work contains all twenty houses and the successor signed mix")
	var cold:=State.new();check(cold.restore(snapshot).ok and cold.houses==demo.state.houses and cold.roads==demo.state.roads and cold.plants==demo.state.plants,"authored city cold restores houses, road and willow")
	check(pool()==voices and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"original audio pool and personal save bytes remain intact")
	facts.saved_work=saved;facts.final_houses=demo.state.houses.size();facts.final_roads=demo.state.roads.size();facts.final_plants=demo.state.plants.size();var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts,"works":demo.collection_directory,"default_changed":false,"listening_approved":false}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("MUSIC_BUILD_JOURNEY ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
