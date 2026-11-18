extends "res://tools/check_game_music_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
var trial:Node
var candidates:Array=[]
func start(code:String)->Node:
	var chosen:Dictionary=candidates.filter(func(row):return row.name.begins_with(code))[0]
	for i in range(trial.packs.size()):
		if trial.packs[i].manifest==chosen.manifest:trial.picker.select(i)
	trial.start_selected();var node:Node=trial.conductor
	check(await wait_for(func():return is_instance_valid(node) and node.active,30000),"actual L starts "+code)
	if is_instance_valid(node) and node.active:check(node.prepared.manifest.source_id==chosen.source_id and node.prepared.signature==chosen.manifest_sha256,"actual signed source for "+code)
	return node
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	trial=Trial.new();demo.add_child(trial);check(trial.install(demo),"full candidate controls install")
	var pointer:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/active_game_music.json"));candidates=JSON.parse_string(FileAccess.get_file_as_string(pointer.sparse_trial.catalog)).packs
	check(trial.packs.size()==79 and candidates.size()==22,"all old and new entries retained, including full manual works")
	var node:Node;var record:AudioEffectRecord
	if not OS.get_cmdline_user_args().has("--manual-only"):
		var inland:=State.new();inland.initialize_free();inland.add_house(Fixture.ORIGIN)
		check(inland.add_road([Fixture.ORIGIN+Vector2(-4,3),Fixture.ORIGIN+Vector2(0,4),Fixture.ORIGIN+Vector2(4,3)] as Array[Vector2],"path","none").ok,"real inland curved road")
		await show(inland,Fixture.ORIGIN,"流动语义绑定");quiet();demo.life.set_process(false)
		node=await start("1-04")
		if not is_instance_valid(node) or not node.active:quit(1);return
		check(node.values.body==0. and node.values.motion==0.,"new optional response/lead declarations start silent")
		record=Span.start();demo.vegetation_drawing=true;await create_timer(7.).timeout
		check(node.values.body==0. and node.values.motion==0.,"continuous editing suppresses stable flow observation")
		demo.vegetation_drawing=false;check(node.seek(10.),"synchronized seek during spatial test");await create_timer(16.).timeout
		check(node.expression.flow>.55 and node.values.body>.08 and node.values.motion>.03,"body-id and motion-id both follow actual flow instead of enclosure")
		check(node.prepared.manifest.layers.filter(func(row):return row.layer==3).size()==1,"at most one declared foreground layer in the actual packet")
		var signature:String=node.prepared.signature;var clock:float=node.player.get_playback_position()
		var removed:Dictionary=demo.state.remove_road(demo.state.roads[0].id);check(removed.ok,"public source removal");demo._after_edit(removed,"road");await settle();await create_timer(6.5).timeout
		check(node.values.body==0. and node.values.motion==0.,"flow source removal expires both optional controls to exact zero")
		check(node.prepared.signature==signature and node.player.get_playback_position()>clock,"control withdrawal keeps original source and phase")
		facts.flow_pcm=Span.finish(record,OUT+"/flow_Master.wav");check(facts.flow_pcm.ok,"actual control changes remain unclipped")
		await capture("flow_expired");node.stop();await process_frame
		var artisan:RefCounted
		for fixture:Dictionary in Fixture.other_kinds():
			if fixture.kind=="artisan":artisan=fixture.city
		check(artisan.remove_road(artisan.roads[0].id).ok,"craft fixture has no road qualification")
		await show(artisan,Fixture.ORIGIN,"手作语义绑定");quiet();demo.life.set_process(false)
		node=await start("3-05")
		if not is_instance_valid(node) or not node.active:quit(1);return
		record=Span.start();check(node.seek(10.),"craft synchronized seek");await create_timer(16.).timeout
		check(node.expression.craft>.55 and node.values.body>.10,"body-id can follow real craft observation")
		check(is_equal_approx(node.values.body,.25*float(node.expression.craft)),"actual recipe control reaches the declared cap-scaled craft value")
		facts.craft_pcm=Span.finish(record,OUT+"/craft_Master.wav");check(facts.craft_pcm.ok,"actual craft response PCM unclipped");node.stop();await process_frame
	var manual:=State.new();manual.initialize_free();manual.add_house(Fixture.ORIGIN);var prefs:Dictionary=manual.creative_settings.music.duplicate();prefs.mode="fixed";prefs.style="warm";check(manual.CreationPolicy.set_preferences(manual,{"music":prefs}).ok,"explicit fixed manual preference")
	await show(manual,Fixture.ORIGIN,"含人声原曲仅手选");quiet()
	node=await start("1-10")
	if not is_instance_valid(node) or not node.active:quit(1);return
	check(trial.picker.get_item_text(trial.picker.selected).begins_with("仅手选") and not node.prepared.manifest.automatic_candidate,"human voice-marked entry is visibly manual-only")
	check(node.sequence.rows.filter(func(row):return row.source_id==node.prepared.manifest.source_id).all(func(row):return not row.automatic_candidate),"runtime auto pool keeps manifest exclusion")
	check(node.seek(10.),"full source review cursor");record=Span.start();await create_timer(3.).timeout
	facts.manual_pcm=Span.finish(record,OUT+"/manual_full_Master.wav");check(facts.manual_pcm.ok,"full original manual audition PCM remains available")
	demo.ledger.open_panel();await create_timer(.3).timeout;demo.ledger.refresh();check("仅手选完整曲" in demo.ledger.body.text and "含人声" in demo.ledger.body.text,"actual L caption does not claim voice removal");await capture("manual_only");await key(KEY_ESCAPE)
	var source:String=node.prepared.manifest.source_id;check(node.seek(float(node.prepared.manifest.frames)/44100.-.4),"manual packet actual natural ending")
	check(await wait_for(func():return node.sequence.transitions.size()==1,10000),"explicit fixed manual work can repeat after natural breath")
	check(node.prepared.manifest.source_id==source and not node.prepared.manifest.automatic_candidate,"fixed manual repeat keeps its restriction")
	var other:=State.new();other.initialize_free();await show(other,Vector2.ZERO,"撤回候选");quiet();check(pool()==voices,"12 long/4 short/6 bus identities preserved")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal default save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("MUSIC_CONTROLS_LIVE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
