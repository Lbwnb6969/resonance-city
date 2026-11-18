extends "res://tools/check_game_music_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var trial:=Trial.new();demo.add_child(trial);check(trial.install(demo),"actual L installed")
	var packs:Array=trial.packs;trial.packs=packs.filter(func(row):return not row.get("automatic_candidate",true));trial.start_background()
	check("保留自然声" in trial.status.text,"unavailable era displays nature status");trial.packs=packs
	for i in range(packs.size()):
		if packs[i].name.begins_with("3-06") and "remaining_v2" in packs[i].manifest:trial.picker.select(i)
	demo.ledger.open_panel();await create_timer(.4).timeout;await ui_click(trial.play_button)
	check(await wait_for(func():return is_instance_valid(trial.conductor) and trial.conductor.active,30000),"actual hand selection starts after unavailable entry")
	check(not "保留自然声" in trial.status.text and "待听评" in trial.status.text,"new request clears stale unavailable status")
	await create_timer(.6).timeout;demo.ledger._last_refresh=-500;demo.ledger.refresh()
	check("3-06" in demo.ledger.body.text and "高处回应" in demo.ledger.body.text and not "尚未接管" in demo.ledger.body.text,"actual L caption describes active highland packet")
	check(demo.ledger.paper.get_global_rect().encloses(trial.background_button.get_global_rect()),"era entry fits 1024 L")
	await capture("active_caption");trial.stop();await process_frame;check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal default save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("BACKGROUND_CAPTION ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
