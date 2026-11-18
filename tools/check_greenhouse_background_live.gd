extends "res://tools/check_creation_shape_palette_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
const Player=preload("res://scripts/audio/city_creation_game_music_player.gd")
const PRIOR="res://数据/音乐资产/游戏音乐包/20261106_sparse_eras_v2/3_02/bundle.json"
const REVISED="res://数据/音乐资产/游戏音乐包/20261108_greenhouse_background_v2/bundle.json"
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var voices:Array=[]
	for voice:AudioStreamPlayer in demo.music._players.values():voices.append(voice.get_instance_id())
	var city:=State.new();city.initialize_free();Brush.select(city,"clockwork");city.add_house(Vector2(-25,-20))
	await show(city,Vector2(-25,-20),"花房背景连续性");await settle();quiet()
	var before:Dictionary=demo.state.snapshot();var trial:=Trial.new();demo.add_child(trial);check(trial.install(demo),"actual L catalog loads revised package")
	check(trial.packs.size()==84,"existing 84 entries retain repertoire size")
	var old_data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PRIOR));var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REVISED))
	check(data.layers[0].sha256==old_data.layers[1].sha256 and data.layers[1].sha256==old_data.layers[0].sha256 and data.layers[2]==old_data.layers[2],"existing synchronized WAVs exchange roles with residual untouched")
	check(data.frames==old_data.frames and data.common_gain==old_data.common_gain and not data.listening_approved and not data.runtime_ready,"timeline gain and approval boundaries retained")
	for label:String in ["prior","revised"]:
		var node:Node
		if label=="prior":node=Player.request(demo.music,PRIOR).node
		else:
			for i in range(trial.packs.size()):
				if trial.packs[i].manifest==REVISED:trial.picker.select(i)
			await key(KEY_L);await settle();quiet();await ui_click(trial.play_button);node=trial.conductor
		check(await wait_for(func():return is_instance_valid(node) and node.active,30000),"native candidate becomes active "+label)
		if not is_instance_valid(node) or not node.active:demo.queue_free();quit(1);return
		await create_timer(.9).timeout
		check(node.prepared.manifest.schema=="city_sparse_music_v2" and node.values=={"background":1.,"body":0.,"detail":0.},"lone house plays only selected independent background "+label)
		check(node.prepared.signature==FileAccess.get_sha256(PRIOR if label=="prior" else REVISED),"actual loaded manifest signed bytes "+label)
		check(node.seek(32.),"all source cursors seek together "+label);await create_timer(.2).timeout
		facts[label]=await Probe.record(OUT+"/"+label+"_Master.wav",11.2)
		check(facts[label].ok and node.player.get_playback_position()>43.,"actual problem interval plays unclipped "+label)
		check(node.values.body==0. and node.values.detail==0. and demo.state.snapshot()==before,"optional parts and author data remain untouched "+label)
		if label=="revised":
			check(node.sequence.rows.any(func(row):return row.manifest==REVISED) and not node.sequence.rows.any(func(row):return row.manifest==PRIOR),"automatic repertoire uses new version once")
			node.set_paused(true);var cursor:float=node.player.get_playback_position();await create_timer(.3).timeout
			check(absf(node.player.get_playback_position()-cursor)<.06,"new background keeps synchronized pause")
			node.set_paused(false)
		node.stop();check(await wait_for(func():return demo.music.get_node_or_null("GameMusicPlayer")==null,30000),"candidate lease fully released "+label)
	var after:Array=[]
	for voice:AudioStreamPlayer in demo.music._players.values():after.append(voice.get_instance_id())
	check(after==voices and demo.music._players.size()==12 and demo.music._effects.size()==4,"original long/short voice pool retained")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save remains byte identical")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts,"persistence":demo.persistence}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("GREENHOUSE_BACKGROUND ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
