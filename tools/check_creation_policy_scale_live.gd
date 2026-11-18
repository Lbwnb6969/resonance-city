extends "res://tools/check_creation_free_music_route_live.gd"
## Current policy scale probe; caller supplies the same authored 300-house worlds.
var scale_rows:Array=[]
var frame_samples:Array=[]
var sampling:=false
var last_frame_usec:=0
var observed_phase:=""
func _process(_delta:float)->bool:
	var now:=Time.get_ticks_usec()
	if sampling and last_frame_usec>0:frame_samples.append((now-last_frame_usec)/1000.)
	last_frame_usec=now
	if demo!=null and demo.gallery.load_phase!=observed_phase:
		observed_phase=demo.gallery.load_phase;print("POLICY_LOAD_PHASE ",observed_phase," ",now/1000000.)
	return false
func distribution(values:Array)->Dictionary:
	if values.is_empty():return {}
	values.sort();var total:=0.
	for value:float in values:total+=value
	return {"samples":values.size(),"mean_ms":total/values.size(),"p95_ms":values[int(values.size()*.95)],"max_ms":values[-1]}
func open_scale(world:Dictionary,label:String)->Dictionary:
	var chosen:={"ok":true,"id":label,"title":label,"world":world.duplicate(true),"view":{"focus":[-14.,1.,-2.],"zoom":30.,"yaw":.4,"pitch":.7,"evening":false,"light_phase":0}}
	var forest_before:int=demo.ambience._forest_skips;var at_frame:=frame_samples.size()
	var began:=Time.get_ticks_usec();await demo.gallery._open_chosen(chosen);await settle();quiet()
	return {"wall_ms":(Time.get_ticks_usec()-began)/1000.,"stages":demo.gallery.load_stats.duplicate(true),"life":demo.life.budget_commit_stats.duplicate(true),"network_prepare":demo.life._network.prepare_stats.duplicate(true),"attachments":demo.life._network.attachment_stats.duplicate(true),"route_cache":demo.life._network.route_cache_stats.duplicate(true),"frames":distribution(frame_samples.slice(at_frame)),"forest_skips":demo.ambience._forest_skips-forest_before}
func command(result:Dictionary,kind:String,label:String)->Dictionary:
	check(result.ok,label);var at:=Time.get_ticks_usec();demo._after_edit(result,kind);await settle();quiet()
	return {"publish_wall_ms":(Time.get_ticks_usec()-at)/1000.,"budget":demo.edit_budget_report().duplicate(true),"life":demo.life.budget_commit_stats.duplicate(true)}
static func first_seat_fixture(source:Dictionary)->Dictionary:
	var author:=State.new();var restored:Dictionary=author.restore(source)
	if not restored.ok:return restored
	var layout:Dictionary=preload("res://scripts/world/city_creation_cafe_layout_context.gd").new().layout(author,"h4")
	return {"ok":not layout.is_empty(),"world":source.duplicate(true),"relocations":[],"cafe_id":"h4","seats":layout.get("seats",[]).size()}
func remote_bridge_points()->Array[Vector2]:
	var anchor:=Vector2(-38,38)
	for road:Dictionary in demo.state.roads:
		for point:Array in road.points:
			if is_equal_approx(float(point[0]),-38.):anchor.y=minf(anchor.y,float(point[1]))
	return [anchor,Vector2(-38,-38.5),Vector2(16,-38.5)]
func first_seat(mode:String,opening_purchases:int)->Dictionary:
	var at:=Time.get_ticks_usec();var initial:float=demo.life.time;var purchases:int=demo.state.life_progress.purchases;var samples:Array=[];var before:Dictionary=demo.state.life_progress.duplicate()
	var status:Dictionary=demo.life.cafe.status("h4")
	if mode=="free_quiet":
		await create_timer(.3).timeout
		check(demo.life.time==initial and demo.state.life_progress==before,"paused300 cafe query invents no visits or purchases")
		return {"paused":true,"query_ms":(Time.get_ticks_usec()-at)/1000.,"status":status}
	demo.life.set_process(false)
	for i in range(1500):
		if int(demo.life.cafe.status("h4").seated_count)>0:break
		var tick:=Time.get_ticks_usec();demo.life._process(.1);samples.append((Time.get_ticks_usec()-tick)/1000.);await process_frame
	demo.life.set_process(true);status=demo.life.cafe.status("h4")
	check(int(status.seated_count)>0 and int(demo.state.life_progress.purchases)>opening_purchases,"actual300 resident buys bread and walks into the first real seat "+mode)
	return {"paused":false,"wall_ms":(Time.get_ticks_usec()-at)/1000.,"logical_seconds":demo.life.time-initial,"tick_ms":distribution(samples),"status":status,"purchases_at_query":purchases,"purchases_at_open":opening_purchases,"purchases_after":demo.state.life_progress.purchases}
func run()->void:
	var fixture_dir:="";var selected_mode:="";var single_load:=false
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--fixture-dir="):fixture_dir=arg.trim_prefix("--fixture-dir=")
		if arg.begins_with("--mode="):selected_mode=arg.trim_prefix("--mode=")
		if arg=="--single-load":single_load=true
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT) or fixture_dir.is_empty():quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);var began:=Time.get_ticks_usec()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	for mode:String in ["legacy","free_active","free_quiet"]:
		if not selected_mode.is_empty() and selected_mode!=mode:continue
		print("POLICY_NATIVE_BEGIN ",mode)
		var path:=fixture_dir.path_join("quiet.json" if mode=="free_quiet" else "free_active_epoch.json")
		if mode=="legacy":path=fixture_dir.path_join("legacy.json")
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path));check(data.houses.size()==300,"same authored 300-house source "+mode)
		var fixture:Dictionary=first_seat_fixture(data);check(fixture.ok,"same300 fixture has actual legal outdoor seats")
		if not fixture.ok:push_error(str(fixture));quit(1);return
		data=fixture.world;await process_frame;await process_frame
		frame_samples.clear();sampling=true;last_frame_usec=Time.get_ticks_usec();var loaded:Dictionary=await open_scale(data,mode);demo.life.set_process(true)
		if "--process-profile" in OS.get_cmdline_user_args():preload("res://tools/fixtures/city_creation_process_probe.gd").install(demo)
		check(demo.state.houses.size()==300 and demo.town.house_roots.size()==300,"all 300 houses actually publish "+mode)
		var refreshed:Dictionary={}
		if not single_load:refreshed=await open_scale(data,mode+"_cached")
		demo.life.set_process(true)
		var trial:Node=null
		if mode!="legacy":
			trial=TrialControls.new();demo.add_child(trial);check(trial.install(demo),"original pending background controls install "+mode);trial.start_selected();check(await wait_for(func():return is_instance_valid(trial.conductor) and trial.conductor.active,30000),"actual background packet ready "+mode)
		var source_node:Node=trial.conductor if trial!=null else null;var source_id:int=source_node.player.get_instance_id() if source_node!=null else 0;var start_clock:float=source_node.clock if source_node!=null else demo.music._playback_clock()
		if "--long-listen" in OS.get_cmdline_user_args():await long_listen(data,loaded,trial,personal,voices,began);return
		var forest_before:int=demo.ambience._forest_skips;var capture:=Span.start();var house:Dictionary=demo.state.houses[-1];var top:=0
		for cell:Dictionary in house.cells:top=maxi(top,int(cell.level))
		var at:=Time.get_ticks_usec();var result:Dictionary=demo.state.add_cell(str(house.id),0,0,top+1);var edit_ms:=(Time.get_ticks_usec()-at)/1000.;var room:Dictionary=await command(result,"room","real upper room "+mode)
		at=Time.get_ticks_usec();await key(KEY_Z,true);await settle();var undo_ms:=(Time.get_ticks_usec()-at)/1000.;await key(KEY_Y,true);await settle();quiet()
		at=Time.get_ticks_usec();result=demo.state.add_road(remote_bridge_points(),"promenade","none");var road_ms:=(Time.get_ticks_usec()-at)/1000.;var road:Dictionary=await command(result,"road","real remote connected bridge "+mode)
		var bridge_road:Dictionary=demo.state.roads.filter(func(r):return r.id==result.road_id)[0]
		check(bridge_road.bridge and not demo.state.road_profile(bridge_road).bridge_runs.is_empty(),"actual new remote stone span publishes "+mode)
		var network:RefCounted=demo.life._network;check(not network._route(network.connected_houses.h1,network._key(Vector2(16,-38.5))).is_empty(),"real current home route reaches new far bridge endpoint "+mode)
		var seat:Dictionary=await first_seat(mode,int(data.life_progress.purchases))
		await create_timer(3.).timeout
		check(not demo.edit_pending() and demo.life.last_revision==demo.state.revision,"latest real network is published "+mode)
		if source_node!=null:check(is_instance_valid(source_node) and source_node.active and source_node.player.get_instance_id()==source_id and source_node.clock>start_clock,"same full-song player clock advances across edits "+mode)
		sampling=false;var forest_skips:int=demo.ambience._forest_skips-forest_before
		var audio:Dictionary=Span.finish(capture,OUT+"/"+mode+"_continuous_Master.wav");check(audio.ok,"actual ongoing Master PCM "+mode)
		demo.focus=Vector3(0,0,0);demo.zoom=94.;demo._update_camera();await capture(mode+"_overview")
		await key(KEY_J);await settle();check(demo.journal.panel.is_visible_in_tree(),"original J opens at scale "+mode);await key(KEY_ESCAPE);await key(KEY_L);await settle();check(demo.ledger.visible(),"original L opens at scale "+mode);await key(KEY_ESCAPE)
		if mode=="free_quiet":check(demo.life.quiet_walk.actors.size()<=24 and demo.life.time==0.,"paused city retains bounded presentation and economic clock")
		sampling=false;scale_rows.append({"mode":mode,"source":path,"source_sha256":FileAccess.get_sha256(path),"cold_load":loaded,"cached_load":refreshed,"room_command_ms":edit_ms,"room_publish":room,"native_undo_ms":undo_ms,"road_command_ms":road_ms,"road_publish":road,"frames":distribution(frame_samples),"pcm":audio,"first_seat":seat,"fixture_role_patch":{"house_id":"h4","role":"garden_cafe","through_public_api":true,"validated_fixture_relocations":fixture.relocations,"seats":fixture.seats},"forest_skips":forest_skips,"quiet_actors":demo.life.quiet_walk.actors.size(),"static_memory_bytes":OS.get_static_memory_usage(),"peak_static_memory_bytes":OS.get_static_memory_peak_usage()})
		FileAccess.open(OUT+"/partial.json",FileAccess.WRITE).store_string(JSON.stringify(scale_rows,"\t"));print("POLICY_NATIVE_ROW ",JSON.stringify({"mode":mode,"frames":scale_rows[-1].frames,"forest_skips":forest_skips,"room_command_ms":edit_ms,"road_command_ms":road_ms}))
		if trial!=null:trial.stop();trial.queue_free();await settle()
	check(pool()==voices and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"voice pool and personal city remain unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_usec()-began)/1000000.,"rows":scale_rows,"works":demo.collection_directory,"listening_approved":false,"measurement_boundary":"Frame and forest sampling stop before synchronous WAV analysis, screenshot export and report serialization. Cold/cached loads include their real GUI/first-frame phases."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("POLICY_SCALE_NATIVE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)

func long_listen(data:Dictionary,loaded:Dictionary,trial:Node,personal:PackedByteArray,voices:Dictionary,began:int)->void:
	var initial_time:float=demo.life.time;var initial_receipts:Dictionary=demo.state.life_progress.duplicate(true)
	if "--clock-only" in OS.get_cmdline_user_args():
		await create_timer(3.).timeout
		check(demo.life.time==initial_time and demo.state.life_progress==initial_receipts,"quiet300 preserves the loaded economic clock and exact existing receipts")
		check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH) and pool()==voices,"targeted clock check preserves personal file and voice pool")
		var clock_report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"loaded_time":initial_time,"after_time":demo.life.time,"receipts_before":initial_receipts,"receipts_after":demo.state.life_progress,"cold_load":loaded,"seconds":(Time.get_ticks_usec()-began)/1000000.,"works":demo.collection_directory,"boundary":"targeted unresolved economic baseline only; full unseeked song and cross-city evidence remain in long300_cross_city_v1"}
		FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(clock_report,"\t"));print("LONG300_CLOCK ",JSON.stringify(clock_report));trial.stop();demo.queue_free();await process_frame;quit(0 if clock_report.ok else 1);return
	var node:Node=trial.conductor;var source:String=node.prepared.manifest.source_id;var identity:int=node.player.get_instance_id()
	var duration:float=float(node.prepared.manifest.frames)/44100.;var trace:Array=[];var capture_record:=Span.start();var start:=Time.get_ticks_msec();var heartbeat:=0
	check(node.clock<1. and node.player.get_playback_position()<1.,"full real source begins at its natural start without seek")
	await key(KEY_J);await settle();check(demo.journal.panel.is_visible_in_tree(),"real J responds at300 during continuous source");await key(KEY_ESCAPE)
	await key(KEY_L);await settle();check(demo.ledger.visible() and trial.picker.is_visible_in_tree(),"original L candidate controls respond at300");await key(KEY_ESCAPE)
	var end:=Time.get_ticks_msec()+int((duration+15.)*1000.)
	while Time.get_ticks_msec()<end:
		await create_timer(.5).timeout
		trace.append({"wall":(Time.get_ticks_msec()-start)/1000.,"clock":node.clock,"position":node.player.get_playback_position(),"source":node.prepared.manifest.source_id,"breathing":node.sequence.breathing,"memory":OS.get_static_memory_usage()})
		var elapsed:=int((Time.get_ticks_msec()-start)/1000.)
		if elapsed>=heartbeat:print("LONG300_HEARTBEAT ",elapsed," source=",node.prepared.manifest.source_id);heartbeat+=30
	check(not node.sequence.transitions.is_empty() and node.prepared.manifest.source_id!=source,"uninterrupted300 whole song really finishes and naturally continues to the next pending candidate")
	check(node.sequence.transitions.all(func(t):return t.breath_seconds>=3. and t.wall_seconds>=2.8),"actual full-song transitions retain declared natural breath")
	check(node.player.get_instance_id()==identity and node.active and node.prepared.manifest.source_id in trial.background.map(func(row):return row.source_id),"same pooled player stays inside declared two pending background candidates")
	check(demo.life.time==initial_time and demo.state.life_progress==initial_receipts,"quiet300 long session preserves loaded economic time and service receipts")
	sampling=false;var frames:Dictionary=distribution(frame_samples);var transitions:Array=node.sequence.transitions.duplicate(true)
	var pcm:Dictionary=Span.finish(capture_record,OUT+"/whole_song_300_Master.wav");check(pcm.ok and pcm.seconds>duration,"actual WASAPI PCM covers the complete song and natural continuation")
	await capture("whole_song_300")
	var small:=State.new();small.initialize_free();check(small.add_house(Vector2(-28,-20)).ok,"cross-city fixture uses real public first house")
	await show(small,Vector2(-28,-20),"长听后换城");quiet();await process_frame
	check(not is_instance_valid(node) and not demo.music.has_meta("game_music") and no_old_long(),"switching city retires former candidate without reviving rejected long voices")
	var return_load:Dictionary=await open_scale(data,"300屋重新打开");demo.life.set_process(true)
	check(demo.state.houses.size()==300 and demo.town.house_roots.size()==300 and demo.life.last_revision==demo.state.revision,"independent cold restore publishes all300 after cross-city switch")
	trial.start_selected();check(await wait_for(func():return is_instance_valid(trial.conductor) and trial.conductor.active,30000),"existing L starts a fresh candidate in restored300 context")
	var current:Node=trial.conductor;check(current.city_id==demo.state.get_instance_id() and current.player.get_instance_id()==identity,"only current city owns the same conserved player")
	var pending:Dictionary=GamePlayer.request(demo.music,trial.background[-1].manifest)
	check(not pending.ok,"existing owner excludes a simultaneous competing audition")
	trial.stop();await process_frame
	var request:Dictionary=GamePlayer.request(demo.music,trial.background[-1].manifest);check(request.ok,"real asynchronous request starts before a city replacement")
	var stale:Node=request.node;var empty:=State.new();empty.initialize_free();await show(empty,Vector2.ZERO,"后台准备期间换空城");quiet();await create_timer(.5).timeout
	check(not is_instance_valid(stale) and demo.state.houses.is_empty() and not demo.music.has_meta("game_music") and no_old_long(),"pending old-city preparation cannot publish into a new empty city")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH) and pool()==voices,"long300 and cross-city chain preserves personal file and original audio pool")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_usec()-began)/1000000.,"duration":duration,"cold_load":loaded,"return_load":return_load,"frames":frames,"trace":trace,"transitions":transitions,"pcm":pcm,"works":demo.collection_directory,"listening_approved":false,"boundary":"unseeked complete source at300 then natural continuation, actual J/L and cross-city current/pending retirement; no subjective quality or fixed performance claim"}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("LONG300_DONE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
