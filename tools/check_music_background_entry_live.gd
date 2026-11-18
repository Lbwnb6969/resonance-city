extends "res://tools/check_game_music_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
var trial:Node
func active()->bool:return is_instance_valid(trial.conductor) and trial.conductor.active
func select_code(code:String)->void:
	for i in range(trial.packs.size()):
		if trial.packs[i].name.begins_with(code) and "remaining_v2" in trial.packs[i].manifest:trial.picker.select(i);return
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	trial=Trial.new();demo.add_child(trial);check(trial.install(demo),"actual L installs background entry")
	demo.ledger.open_panel();await create_timer(.4).timeout;await ui_click(trial.background_button)
	check(await wait_for(active,30000),"real background button starts empty-city candidate")
	if not active():quit(1);return
	check(trial.conductor.manifest_path.contains("remaining_v2") and trial.conductor.prepared.manifest.name.begins_with("1-01"),"empty-city pastoral sparse opening")
	var optional_silent:=true
	for id:String in trial.conductor.values:
		if id!="background":optional_silent=optional_silent and trial.conductor.values[id]==0.
	check(trial.conductor.values.background==1. and optional_silent,"simple city opens background only")
	await capture("background_entry");trial.stop();await process_frame
	var modern:=State.new();modern.initialize_free();check(Brush.select(modern,"modern_eco") and modern.add_house(Fixture.ORIGIN).ok,"real modern house supplies era")
	await show(modern,Fixture.ORIGIN,"现代背景入口");quiet()
	if not demo.ledger.visible():demo.ledger.open_panel()
	await create_timer(.4).timeout;await ui_click(trial.background_button)
	check(await wait_for(active,30000),"modern background actual native activation")
	if not active():quit(1);return
	check(trial.conductor.prepared.manifest.schema=="city_sparse_music_v2" and trial.conductor.prepared.manifest.era=="modern_eco","same-source v1 cannot replace sparse modern choice")
	# Cancel a request while the existing real player is waiting to retire.
	trial.start_selected();check(trial.pending_request,"replacement enters cancellable frame wait");trial.stop()
	check(await wait_for(func():return demo.music.get_node_or_null("GameMusicPlayer")==null,30000),"actual old player retires")
	for i in range(5):await process_frame
	check(not active() and not trial.pending_request and demo.music.get_node_or_null("GameMusicPlayer")==null,"cancelled wait cannot start a new player")
	var all_packs:Array=trial.packs;trial.packs=all_packs.filter(func(row):return not row.get("automatic_candidate",true))
	trial.start_background();await process_frame
	check(not active() and "保留自然声" in trial.status.text,"manual-only pool leaves nature instead of full-song fallback");trial.packs=all_packs
	var hill:=State.new();hill.initialize_free();check(Brush.select(hill,"clockwork"),"highland clockwork brush")
	var plan:Dictionary=hill.plan_terrain_target([Vector2(-28,-20)] as Array[Vector2],5.,3.2,true)
	check(plan.ok and hill.apply_terrain_target(plan).ok and hill.add_house(Vector2(-28,-20)).ok and hill.add_house(Vector2(-19,-20)).ok,"actual high and low house foundations")
	await show(hill,Vector2(-24,-20),"高地分层回应");quiet();demo.life.set_process(false);select_code("3-06");trial.start_selected()
	check(await wait_for(active,30000),"new highland v2 selected through actual L")
	if not active():quit(1);return
	var node:Node=trial.conductor;check(node.prepared.manifest.layers.filter(func(row):return row.id=="body")[0].control=="highland","body layer explicitly follows highland control")
	var record:=Span.start();await create_timer(5.).timeout;check(node.contour_value==0. and node.values.body==0.,"short focus does not bypass stable observation")
	await create_timer(13.).timeout;facts.highland_before={"contour":node.contour_value,"body":node.values.body,"spatial":node.spatial_facts}
	check(node.spatial_facts.flow==0. and node.contour_value>.55 and node.values.body>.12,"highland enters optional body without road flow")
	var signature:String=node.prepared.signature;var cursor:float=node.player.get_playback_position();await capture("highland_entered")
	var removed:Dictionary=demo.state.remove_house("h1");check(removed.ok,"public removal withdraws elevated house");demo._after_edit(removed,"house");await settle();await create_timer(6.5).timeout
	check(node.contour_value==0. and node.values.body==0.,"highland disappears to exact zero after source removal")
	check(node.prepared.signature==signature and node.player.get_playback_position()>cursor,"withdrawal keeps source and musical cursor")
	var restored:Dictionary=demo.state.undo();check(restored.ok,"public Undo restores elevated geometry");demo._after_edit(restored,"house");await settle();await create_timer(18.).timeout
	check(node.contour_value>.55 and node.values.body>.12 and node.prepared.signature==signature,"Undo restores highland response without restarting music")
	facts.highland_pcm=Span.finish(record,OUT+"/highland_Master.wav");check(facts.highland_pcm.ok,"actual highland response PCM non-silent and unclipped");trial.stop();await process_frame
	check(pool()==voices,"12 long / 4 short / 6 buses keep original player identities")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save byte-identical")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts,"default_changed":false,"listening_approved":false};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("BACKGROUND_ENTRY_LIVE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
