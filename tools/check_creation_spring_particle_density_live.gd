extends "res://tools/check_creation_mixed_detail_journey_live.gd"

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec()
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input()
	var city:=State.new();check(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/PlayTest/mixed_district_journey_20261109/row.json"))).ok,"actual authored mixed row restores")
	await show(city,Vector2(-23.5,-20),"春风花瓣密度对照");quiet();demo.ui_layer.hide();demo.town.wildlife.hide();demo.town.clear_preview()
	demo.focus=Vector3(-23.5,1.4,-19.5);demo.zoom=12.;demo.pitch=.65;demo.yaw=.25;demo._update_camera();demo.weather_visual.update()
	demo.process_mode=Node.PROCESS_MODE_DISABLED;Engine.time_scale=0.
	var weather:MultiMeshInstance3D=demo.weather_visual.particles;var material:ShaderMaterial=demo.weather_visual.material;var original:Shader=material.shader;var frozen:=Shader.new();frozen.code=original.code.replace("TIME","2.0");material.shader=frozen
	demo.weather_visual.moment.hide()
	var author:=var_to_bytes(demo.state.snapshot());var buffer:PackedFloat32Array=weather.multimesh.buffer;var house_buffers:=row_arrays();var rows:Array=[]
	for phase:int in [0,2]:
		demo._set_light_phase(phase)
		for count:int in [192,64]:
			weather.multimesh.visible_instance_count=count
			for i in range(12):await process_frame
			await capture(str(phase)+"_"+str(count));rows.append({"phase":phase,"draw_count":weather.multimesh.visible_instance_count})
	check(weather.multimesh.buffer==buffer and row_arrays()==house_buffers,"density comparison retains every prepared particle and building GPU buffer")
	check(var_to_bytes(demo.state.snapshot())==author,"spring density comparison keeps authored city unchanged")
	material.shader=original
	var modes:Array=[]
	for mode:String in ["spring_breeze","sun_shower","autumn_gold","starlight_fireflies"]:
		check(demo.state.set_microclimate(mode).ok,"existing authored weather selection "+mode);demo.weather_visual.update()
		var expected_count:=64 if mode=="spring_breeze" else 192
		check(weather.multimesh.visible_instance_count==expected_count and weather.visible,"actual weather publishes its authored mode particle allowance "+mode)
		modes.append({"mode":mode,"draw_count":weather.multimesh.visible_instance_count,"buffer_count":weather.multimesh.instance_count})
	check(weather.multimesh.instance_count==192 and weather.multimesh.buffer==buffer,"all 192 deterministic particles remain prepared across weather modes")
	check(not demo.persistence and personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"only isolated works; personal save unchanged")
	Engine.time_scale=1.
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"views":rows,"production_modes":modes,"seconds":(Time.get_ticks_msec()-began)/1000.,"persistence":demo.persistence,"scope":"Fixed TIME=2 in the existing weather shader for same-pose A/B; both use original other uniforms. No motion/performance/audio claim."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SPRING_PARTICLE_DENSITY ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
