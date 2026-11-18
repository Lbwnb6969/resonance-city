extends "res://tools/check_sparse_music_live.gd"
const Caption=preload("res://scripts/ui/city_creation_music_trial_caption.gd")
func caption()->String:return "\n".join(Caption.lines(demo.music))
func refresh_caption()->void:
	demo.ledger._last_refresh=-500;demo.ledger.refresh();await create_timer(.5).timeout
	demo.ledger.scroll.scroll_vertical=100000;await create_timer(.15).timeout
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var fixture:=Fixture.courtyard("ring","none");check(fixture.ok,"actual unconnected enclosed house")
	await show(fixture.city,Fixture.ORIGIN+Vector2(3.6,3.6),"围合音乐观察说明");quiet();demo.life.set_process(false)
	var trial:=Trial.new();demo.add_child(trial);check(trial.install(demo),"real L trial installed")
	var node:Node=await start_sparse()
	if node==null or not node.active:demo.queue_free();quit(1);return
	var before:Dictionary=demo.state.snapshot();var signature:String=node.prepared.signature
	demo.ledger.open_panel()
	check(await wait_for(func():return node.envelope_state.get("candidate",false),3000),"real spatial observation starts before voice enters")
	check(node.values.body==0. and "温暖 · 观察中" in caption(),"silent warm voice displays pending observation")
	await refresh_caption();check("温暖 · 观察中" in demo.ledger.body.text,"actual L shows pending observation")
	await capture("court_observing")
	node.set_paused(true);await process_frame
	check("温暖 · 已暂停" in caption() and node.values.body==0.,"pause takes priority without enabling voice")
	node.set_paused(false);demo.music.set_muted(true);await process_frame
	check("温暖 · 已静音" in caption(),"mute takes priority over observation")
	demo.music.set_muted(false)
	check(await wait_for(func():return float(node.values.body)>.01,13000),"same source naturally gains actual bounded warm layer")
	check("温暖 · 正在发声" in caption(),"caption follows actual established envelope")
	check("点缀 · 未发声" in caption(),"unassigned layer stays silent instead of observing")
	await refresh_caption();await capture("court_sounding")
	check(demo.state.snapshot()==before,"reading captions never edits the authored city")
	var position:float=node.player.get_playback_position()
	await key(KEY_ESCAPE);var result:Dictionary=demo.state.remove_house("h1");demo._after_edit(result,"house");await settle();quiet()
	check(node.envelope_state.get("historical_tail",false) and "温暖 · 余韵" in caption(),"real geometry removal displays existing release tail")
	check(await wait_for(func():return float(node.values.body)==0.,8000),"real release reaches exact zero")
	check("温暖 · 未发声" in caption() and node.prepared.signature==signature and node.player.get_playback_position()>position,"after release silence caption preserves advancing source")
	await key(KEY_Z,true);await settle();quiet()
	var restored:Dictionary=demo.state.snapshot();var differences:Array=[]
	for field:String in before:
		if restored.get(field)!=before[field]:differences.append(field)
	FileAccess.open(OUT+"/undo_comparison.json",FileAccess.WRITE).store_string(JSON.stringify({"before":before,"after":restored,"different_fields":differences},"\t"))
	check(restored.houses==before.houses and restored.roads==before.roads and restored.terrain_strokes==before.terrain_strokes,"native Undo restores exact courtyard construction")
	check(await wait_for(func():return node.envelope_state.get("candidate",false),3000) and "温暖 · 观察中" in caption(),"restored court observes again without fabricating sound")
	# Directed caption-only probe: hold the audio packet untouched and simulate
	# flow/craft/highland observations without yielding to the player process.
	var prepared:Dictionary=node.prepared;var values:Dictionary=node.values;var colors:Dictionary=node.color_states;var contour:Dictionary=node.contour_state
	var probe:Dictionary=prepared.duplicate();probe.manifest=prepared.manifest.duplicate(true);probe.ids=["background","motion"]
	for control:String in ["flow","craft","highland"]:
		probe.manifest.layers=[{"id":"background","automatic_max":1.},{"id":"motion","control":control,"automatic_max":.1}]
		node.prepared=probe;node.values={"background":1.,"motion":0.};node.color_states={"flow":{"value":0.,"candidate":false},"craft":{"value":0.,"candidate":false}};node.contour_state={"value":0.,"candidate":true}
		check(("流动 · 观察中" if control=="highland" else "流动 · 未发声") in caption(),"v2 caption follows its declared control only: "+control)
		probe.manifest.layers[1].automatic_max=0.
		check("流动 · 未发声" in caption(),"zero cap never advertises observation: "+control)
	node.prepared=prepared;node.values=values;node.color_states=colors;node.contour_state=contour
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH) and not demo.persistence,"personal save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"scope":"Caption follows real observation/voice/tail. No audio, timing or geometry changes; no listening claim."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("OBSERVATION_CAPTION ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
