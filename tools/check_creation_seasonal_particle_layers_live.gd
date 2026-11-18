extends "res://tools/check_creation_mixed_detail_journey_live.gd"

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec()
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input()
	var city:=State.new();check(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/PlayTest/mixed_district_journey_20261109/row.json"))).ok,"same actual mixed row restores")
	await show(city,Vector2(-23.5,-20),"春风效果图层对照");quiet();demo.ui_layer.hide();demo.town.wildlife.hide();demo.weather_visual.update()
	demo.focus=Vector3(-23.5,1.4,-19.5);demo.zoom=12.;demo.pitch=.65;demo.yaw=.25;demo._update_camera();demo.set_process(false);demo.life.set_process(false);demo.town.set_process(false);Engine.time_scale=0.
	var weather:MultiMeshInstance3D=demo.weather_visual.particles;var motes:MultiMeshInstance3D=demo.weather_visual.moment.motes
	var weather_count:=weather.multimesh.visible_instance_count;var moment_count:=motes.multimesh.visible_instance_count;var author:=var_to_bytes(demo.state.snapshot());var rows:Array=[]
	for mode:String in ["both","weather_only","moment_only","neither"]:
		weather.visible=mode in ["both","weather_only"];motes.visible=mode in ["both","moment_only"]
		for i in range(18):await process_frame
		await capture(mode)
		rows.append({"mode":mode,"weather_visible":weather.visible,"weather_instances":weather_count,"moment_visible":motes.visible,"moment_instances":moment_count})
	check(var_to_bytes(demo.state.snapshot())==author,"layer comparison preserves all authored mixed-row state")
	check(not demo.persistence and personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"comparison leaves personal save untouched")
	check(weather_count==192 and moment_count<=96,"reports actual production instance bounds")
	Engine.time_scale=1.
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"microclimate":demo.state.microclimate,"weather_mode":demo.weather_visual._mode,"rows":rows,"seconds":Time.get_ticks_msec()-began,"scope":"Same restored city/camera; existing particle layers toggled only, no count or material change."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SEASONAL_PARTICLE_LAYERS ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
