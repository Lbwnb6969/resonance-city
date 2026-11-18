extends "res://tools/check_game_music_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
var trial:Node
func active()->bool:return is_instance_valid(trial.conductor) and trial.conductor.active
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();demo.life.set_process(false);var voices:=pool()
	demo.focus=Vector3(Fixture.ORIGIN.x,.8,Fixture.ORIGIN.y);demo._update_camera()
	trial=Trial.new();demo.add_child(trial);check(trial.install(demo),"actual L trial installs current signed catalogs")
	var index:=-1
	for i in range(trial.packs.size()):
		if trial.packs[i].name.begins_with("1-05") and "remaining_v2" in trial.packs[i].manifest:index=i
	check(index>=0,"real new sparse 1-05 present")
	if index<0:quit(1);return
	trial.picker.select(index);demo.ledger.open_panel();await create_timer(.35).timeout;var record:=Span.start();await ui_click(trial.play_button)
	check(await wait_for(active,30000),"actual native L audition action activates sparse packet")
	if not active():quit(1);return
	var node:Node=trial.conductor;var source:String=node.prepared.manifest.source_id;var duration:float=float(node.prepared.manifest.frames)/44100.
	check(node.prepared.manifest.schema=="city_sparse_music_v2" and node.player.get_playback_position()<1.,"full-length new sparse source begins at zero without seek")
	await create_timer(3.).timeout;var sparse_silent:=true
	for id:String in node.values:
		if id!="background":sparse_silent=sparse_silent and node.values[id]==0.
	check(node.values.background==1. and sparse_silent,"empty city keeps independent background and all optional layers exactly zero")
	node.set_paused(true);var paused_at:float=node.player.get_playback_position();var paused_clock:float=node.clock;await create_timer(.75).timeout
	check(absf(node.player.get_playback_position()-paused_at)<.06 and node.clock==paused_clock,"real pause freezes complete source and observation");node.set_paused(false)
	demo.music.set_muted(true);await create_timer(.3).timeout;check(node.player.volume_linear==0.,"existing mute silences all synchronized layers");demo.music.set_muted(false)
	await create_timer(1.).timeout;await capture("empty_sparse")
	check(demo.state.add_house(Fixture.ORIGIN).ok,"actual public lone house")
	var road:Dictionary=demo.state.add_road([Fixture.ORIGIN+Vector2(-4,3),Fixture.ORIGIN+Vector2(0,4),Fixture.ORIGIN+Vector2(4,3)] as Array[Vector2],"path","none")
	check(road.ok,"actual curved inland road supplies flow");demo._after_edit(road,"road");await settle();var author:=var_to_bytes(demo.state.snapshot())
	var trace:Array=[];var continuous:=true;var previous:float=node.player.get_playback_position();var end:=Time.get_ticks_msec()+int((duration+15.)*1000.);var last_report:=-1
	while not node.sequence.breathing and Time.get_ticks_msec()<end:
		await create_timer(.2).timeout
		if node.player.playing:
			var position:float=node.player.get_playback_position();continuous=continuous and position>=previous-.06 and node.prepared.manifest.source_id==source;previous=position
		var second:=floori(node.clock)
		if second!=last_report:
			last_report=second;trace.append({"clock":node.clock,"position":node.player.get_playback_position(),"source_id":node.prepared.manifest.source_id,"values":node.values.duplicate(),"mean":node.sequence.average()})
			if second%20==0:print("SPARSE_FULL_PROGRESS ",second,"/",duration)
	check(node.sequence.breathing and previous>duration-1. and continuous,"entire source reaches actual finished signal with monotonic cursor and no seek")
	check(node.sequence.next_row.get("name","").begins_with("1-04") and node.spatial_facts.get("flow",0.)>.5,"real thirty-second flow history chooses flow response rather than first catalog row")
	check(not node.player.playing and node.saved.foundation.stream!=node.player.stream,"natural full ending retains leased synchronized player")
	var all_stopped:=true
	for player:AudioStreamPlayer in demo.music._players.values():all_stopped=all_stopped and not player.playing
	check(all_stopped and demo.ambience.players.size()==2,"twelve long voices stop while original two nature voices remain")
	node.set_paused(true);var breath:float=node.sequence.remaining;await create_timer(1.1).timeout;check(node.sequence.remaining==breath,"pause freezes natural breath in sparse queue");node.set_paused(false)
	check(await wait_for(func():return node.prepared.manifest.source_id!=source,12000),"natural breath publishes actual same-era sparse successor")
	check(node.prepared.manifest.name.begins_with("1-04") and node.prepared.manifest.schema=="city_sparse_music_v2" and node.prepared.manifest.era=="pastoral","selected real successor keeps era and sparse protocol")
	check(node.sequence.transitions.size()==1 and node.sequence.transitions[0].breath_seconds>=2.5 and node.sequence.transitions[0].breath_seconds<=4.,"actual active breath respects three-second design")
	await create_timer(3.).timeout;facts.pcm=Span.finish(record,OUT+"/full_song_and_flow_successor_Master.wav");check(facts.pcm.ok,"full first source plus nature gap and real successor PCM is non-silent and unclipped")
	facts.transitions=node.sequence.transitions.duplicate(true);facts.trace=trace;facts.first_duration=duration;facts.final_cursor=previous;facts.no_seek=true;facts.spatial=node.spatial_facts.duplicate(true)
	check(var_to_bytes(demo.state.snapshot())==author,"audio and selection leave public edited author state intact");await capture("flow_successor")
	var old_id:=node.get_instance_id();var other:=State.new();other.initialize_free();await show(other,Vector2.ZERO,"换城撤回稀疏续播");quiet()
	check(await wait_for(func():return not is_instance_id_valid(old_id),30000) and not demo.music.has_meta("game_music"),"real city switch retires complete sparse queue")
	check(pool()==voices,"12 long / 4 short / 6 buses retain original player identities");check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save bytes unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts,"default_changed":false,"listening_approved":false}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SPARSE_FULL_SEQUENCE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
