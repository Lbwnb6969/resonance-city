extends "res://tools/check_game_music_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
var trial:Node
func active()->bool:return is_instance_valid(trial.conductor) and trial.conductor.active
func focus_at(at:Vector2)->void:
	demo.focus=Vector3(at.x,.8,at.y);demo._update_camera()
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=60;var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	var town:=State.new();town.initialize_free();check(Brush.select(town,"pastoral") and town.add_house(Fixture.ORIGIN).ok,"actual pastoral house")
	var clock_at:=Vector2(12,18);check(Brush.select(town,"clockwork") and town.add_house(clock_at).ok,"actual separated clockwork house")
	await show(town,Fixture.ORIGIN,"曲尾施工与时代观察");quiet();demo.life.set_process(false);trial=Trial.new();demo.add_child(trial);check(trial.install(demo),"actual trial installs")
	for i in range(trial.packs.size()):
		if trial.packs[i].name.begins_with("1-01") and "remaining_v2" in trial.packs[i].manifest:trial.picker.select(i);break
	demo.ledger.open_panel();await create_timer(.4).timeout;await ui_click(trial.play_button);check(await wait_for(active,30000),"actual L action activates sparse first source")
	if not active():quit(1);return
	var node:Node=trial.conductor;var first:String=node.prepared.manifest.source_id
	check(await wait_for(func():return node.sequence.era_observation.established=="pastoral" and node.spatial_facts.weights.get("h1",0.)>.9,3000),"first established era follows actual focused pastoral geometry")
	var original:=var_to_bytes(demo.state.snapshot());var cursor:float=node.player.get_playback_position();focus_at(clock_at);await create_timer(2.).timeout
	check(node.sequence.era_observation.established=="pastoral" and node.sequence.era_observation.candidate=="clockwork","actual two-second camera sweep stays pending")
	focus_at(Fixture.ORIGIN);await process_frame;await process_frame;check(node.sequence.era_observation.candidate=="pastoral" and node.prepared.manifest.source_id==first and node.player.get_playback_position()>cursor,"return cancels wrong-era sweep without cutting source")
	var record:=Span.start();demo.vegetation_drawing=true;await process_frame;await process_frame;check(demo.music.attention.dragging,"real production drawing signal reaches shared attention")
	check(node.seek(float(node.prepared.manifest.frames)/44100.-.5),"all real synchronized streams seek only to target natural ending")
	check(await wait_for(func():return node.sequence.breathing,5000),"actual finished starts nature breath")
	focus_at(clock_at);await create_timer(3.5).timeout
	check(node.sequence.breathing and node.sequence.worker==null and node.prepared.manifest.source_id==first and not node.player.playing,"continuous drawing holds expired breath without loading or publishing a successor")
	check(node.spatial_facts.weights.get("h2",0.)>.9 and node.sequence.era_observation.candidate=="clockwork","breathing refreshes actual new focus geometry")
	demo.ledger._last_refresh=-500;demo.ledger.refresh();await create_timer(.3).timeout;check("营造中" in demo.ledger.body.text,"existing L explains construction nature hold");await capture("construction_hold")
	node.set_paused(true);var elapsed:float=node.sequence.era_observation.elapsed;var remaining:float=node.sequence.remaining;await create_timer(.8).timeout
	check(node.sequence.era_observation.elapsed==elapsed and node.sequence.remaining==remaining,"native pause freezes both scheduling and breath clocks");node.set_paused(false)
	demo.vegetation_drawing=false;var road:Dictionary=demo.state.add_road([clock_at+Vector2(-4,3),clock_at+Vector2(0,4),clock_at+Vector2(4,3)] as Array[Vector2],"path","none")
	check(road.ok,"actual public discrete road edit restarts idle gate");demo._after_edit(road,"road");await settle();original=var_to_bytes(demo.state.snapshot())
	check(await wait_for(func():return node.sequence.wait_reason()=="era_observation",5000),"after three-second idle the new era begins observation")
	check(node.sequence.era_observation.observed<.5 and node.sequence.era_observation.established=="pastoral" and node.sequence.worker==null,"drawing time never banks six-second era observation")
	demo.ledger._last_refresh=-500;demo.ledger.refresh();await create_timer(.3).timeout;check("风貌观察中" in demo.ledger.body.text,"existing L explains stable-era nature hold");await capture("era_observation")
	check(await wait_for(func():return node.prepared.manifest.source_id!=first,12000),"stable new era prepares and naturally publishes successor")
	check(node.prepared.manifest.era=="clockwork" and node.prepared.manifest.schema=="city_sparse_music_v2" and node.sequence.transitions.size()==1,"actual successor follows established clockwork and same sparse protocol")
	check(node.sequence.transitions[0].breath_seconds>12. and node.sequence.era_observation.established=="clockwork","extended active breath records real construction and observation hold")
	# Prepare an actual old-era packet, then change focus while paused before publication.
	check(node.seek(float(node.prepared.manifest.frames)/44100.-.5),"second real natural ending target")
	check(await wait_for(func():return node.sequence.breathing and (node.sequence.worker!=null or not node.sequence.ready.is_empty()),5000),"actual clockwork successor worker starts in ordinary breath")
	node.set_paused(true);check(await wait_for(func():return not node.sequence.ready.is_empty(),30000),"actual signed old-era packet finishes loading while paused")
	var held:String=node.sequence.next_row.source_id;check(node.sequence.selected_era=="clockwork","held real packet was selected for previous era");focus_at(Fixture.ORIGIN);await create_timer(.3).timeout;var previous:String=node.prepared.manifest.source_id;node.set_paused(false)
	await create_timer(2.).timeout;check(node.sequence.breathing and node.prepared.manifest.source_id==previous and node.sequence.ready.manifest.source_id==held,"resumed camera sweep cannot publish already prepared old-era packet")
	check(await wait_for(func():return node.prepared.manifest.source_id!=previous,12000),"new stable era replaces obsolete prepared packet")
	check(node.prepared.manifest.era=="pastoral" and node.prepared.manifest.source_id!=held and node.prepared.manifest.schema=="city_sparse_music_v2","actual publication uses pastoral replacement rather than loaded clockwork packet")
	await create_timer(2.).timeout;facts.pcm=Span.finish(record,OUT+"/held_era_transitions_Master.wav");check(facts.pcm.ok,"actual held-gap and both successor PCM non-silent and unclipped");facts.transitions=node.sequence.transitions.duplicate(true);facts.held_discarded_source=held;facts.observation={"established":node.sequence.era_observation.established,"candidate":node.sequence.era_observation.candidate,"observed":node.sequence.era_observation.observed};facts.ending_seek_used=true
	check(var_to_bytes(demo.state.snapshot())==original,"scheduling leaves real author edits unchanged");await capture("pastoral_replacement")
	var old_id:=node.get_instance_id();var other:=State.new();other.initialize_free();await show(other,Vector2.ZERO,"换城撤回时代观察");quiet();check(await wait_for(func():return not is_instance_id_valid(old_id),30000) and not demo.music.has_meta("game_music"),"actual city replacement retires observer and queued source")
	check(pool()==voices,"original 12 long / 4 short / 6 buses player identities preserved");check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save bytes unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts,"default_changed":false,"listening_approved":false};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ERA_OBSERVATION_LIVE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
