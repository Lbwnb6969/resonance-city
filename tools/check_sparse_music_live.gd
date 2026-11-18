extends "res://tools/check_game_music_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
const Sparse=preload("res://scripts/audio/city_creation_sparse_music_bundle.gd")
const PATH="res://数据/音乐资产/游戏音乐包/20261106_sparse_v2/1_02/bundle.json"
func start_sparse()->Node:
	var trial:Node=demo.get_meta("music_trial")
	for i in range(trial.packs.size()):
		if trial.packs[i].manifest==PATH:trial.picker.select(i)
	trial.start_selected();var node:Node=trial.conductor
	check(is_instance_valid(node),"actual L selected v2 starts through its existing action")
	if not is_instance_valid(node):return null
	check(await wait_for(func():return is_instance_valid(node) and node.active,30000),"actual v2 streams prepared on the original player")
	return node
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	var trial:=Trial.new();demo.add_child(trial);check(trial.install(demo),"existing L candidate page includes sparse catalog")
	check(trial.packs.any(func(row):return row.manifest==PATH),"versioned sparse candidate is actually selectable")
	var empty:=State.new();empty.initialize_free();await show(empty,Vector2(12,18),"稀疏背景空城");quiet()
	var node:Node=await start_sparse()
	if node==null or not node.active:demo.queue_free();quit(1);return
	await create_timer(1.).timeout
	check(node.values.background==1. and node.values.body==0. and node.values.detail==0.,"empty city plays background only, optional voices exact zero")
	check(node.player==demo.music._players.foundation and node.prepared.stream.stream_count==3,"three synchronized layers borrow one of original twelve players")
	check(node.prepared.stream.get_sync_stream_volume(1)==-INF and node.prepared.stream.get_sync_stream_volume(2)==-INF,"real native optional gains are negative infinity")
	check(node.seek(10.),"same-clock seek for all layers");var record:=Span.start();await create_timer(3.).timeout;facts.empty_pcm=Span.finish(record,OUT+"/empty_Master.wav");check(facts.empty_pcm.ok,"actual background-only Master PCM non-silent/unclipped")
	demo.ledger.open_panel();await create_timer(.3).timeout;demo.ledger.refresh();check("同源背景分层候选" in demo.ledger.body.text and "背景" in demo.ledger.body.text,"actual L caption distinguishes v2 candidate and background")
	await capture("empty_v2");await key(KEY_ESCAPE)
	var position:float=node.player.get_playback_position();node.set_paused(true);await create_timer(.35).timeout;check(absf(node.player.get_playback_position()-position)<.08,"native pause freezes all synchronized streams");node.set_paused(false)
	node.stop();await process_frame
	var fixture:=Fixture.courtyard("ring","none");check(fixture.ok,"public unconnected courtyard fixture")
	await show(fixture.city,Fixture.ORIGIN+Vector2(3.6,3.6),"围合中的稀疏回应");quiet();demo.life.set_process(false)
	node=await start_sparse()
	if node==null or not node.active:demo.queue_free();quit(1);return
	check(node.values.body==0. and node.values.detail==0.,"courtyard starts with no optional layer before stable observation")
	check(node.seek(10.),"court same-clock seek");record=Span.start();await create_timer(16.).timeout
	check(node.values.body>.25 and node.values.body<=.45 and node.values.detail==0.,"real stable courtyard introduces bounded response, unassigned residual stays silent")
	var signature:String=node.prepared.signature;var clock:float=node.player.get_playback_position();var houses:Array=demo.state.houses.duplicate(true)
	var result:Dictionary={}
	for house:Dictionary in houses:result=demo.state.remove_house(house.id)
	demo._after_edit(result,"house");await settle();await create_timer(6.5).timeout
	check(node.values.body==0. and node.values.detail==0.,"actual removed courtyard returns optional layers to exact zero")
	check(node.player.get_playback_position()>clock and node.prepared.signature==signature,"source removal keeps the original song and advancing phase")
	for i in range(houses.size()):result=demo.state.undo()
	demo._after_edit(result,"history");await settle();await create_timer(16.).timeout
	check(node.values.body>.25 and node.values.detail==0. and node.prepared.signature==signature,"native State Undo restores spatial response on the same source")
	facts.spatial_pcm=Span.finish(record,OUT+"/court_remove_undo_Master.wav");check(facts.spatial_pcm.ok,"actual spatial gain/withdrawal/Undo PCM non-silent/unclipped")
	await capture("court_v2");demo.music.set_muted(true);await process_frame;await process_frame;check(node.player.volume_linear==0.,"ordinary mute covers complete synchronized packet");demo.music.set_muted(false)
	var old_id:int=node.get_instance_id();var other:=State.new();other.initialize_free();await show(other,Vector2(12,18),"换城撤回背景");quiet();check(await wait_for(func():return not is_instance_id_valid(old_id),10000),"new city retires old v2 player and its packet")
	check(pool()==voices,"12 long/4 short/6 bus identities unchanged");check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal default save bytes unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SPARSE_LIVE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
