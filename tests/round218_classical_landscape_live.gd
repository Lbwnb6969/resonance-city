extends "res://tests/round209_classical_night_live.gd"
## Actual window proof for the first-era river bank/open-land presentation.
var views: Array[String] = []

func _run() -> void:
	output = "res://验证记录/round218_古典自然地表/live_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var underruns := demo.clock.underruns
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","actual_gpu_wasapi")
	check(await until_frame(rate*5),"opening_reaches_device")
	await capture("00_河岸与大片空地_第一时代")
	views.append("00_河岸与大片空地_第一时代")
	var terrain_layer: Node2D = demo.terrain_layer
	var landscape = terrain_layer.classical_landscape
	check(landscape.land_texture != null and landscape.land_texture.get_width() == 2048,"actual_hd_land_texture")
	check(landscape.geometry["tufts"].size() <= 96 and landscape.geometry["stones"].size() <= 44,"actual_sparse_natural_details")
	var geometry_rebuilds := int(terrain_layer.terrain_geometry_rebuilds)
	var prepare_count := int(landscape.prepare_count)
	var visual_key: Array = terrain_layer.key.duplicate(true)
	var frozen: Dictionary = demo.model.capture_state()
	var world_before: Dictionary = demo.model.world.snapshot()
	var frame := demo.clock.renderer.transport.audible_frame
	var pcm_before_model: ContinuousAudioModel = ContinuousAudioModel.from_state(frozen)
	var before_pcm := pcm_before_model.render_block(frozen.duplicate(true),frame,4096,rate)
	demo.pan_target += Vector2(42,-28)
	demo.zoom_target = 1.18
	demo.daylight_manual_phase = 0.31
	await create_timer(0.8).timeout
	await capture("01_推移与昼光_同一地形")
	views.append("01_推移与昼光_同一地形")
	check(int(terrain_layer.terrain_geometry_rebuilds) == geometry_rebuilds and int(landscape.prepare_count) == prepare_count,"pan_zoom_daylight_reuse_terrain_geometry")
	check(terrain_layer.key == visual_key or terrain_layer.terrain_geometry_rebuilds == geometry_rebuilds,"camera_change_does_not_rebuild_world_geometry")
	var pcm_after_model: ContinuousAudioModel = ContinuousAudioModel.from_state(frozen)
	var after_pcm := pcm_after_model.render_block(frozen.duplicate(true),frame,4096,rate)
	check(before_pcm == after_pcm,"visual_layer_keeps_frozen_pcm_byte_exact")
	check(demo.model.world.snapshot() == world_before,"live_visual_review_keeps_world_snapshot")
	check(demo.clock.underruns == underruns,"no_new_audio_underrun")
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"views":views,"geometry_rebuilds":geometry_rebuilds,"landscape_prepare_count":prepare_count,"tufts":landscape.geometry["tufts"].size(),"stones":landscape.geometry["stones"].size(),"pcm_frames":4096,"underrun_delta":demo.clock.underruns-underruns,"scope":"Windows/OpenGL/WASAPI; first-era river-valley texture/details, camera/daylight cache and frozen PCM. Human aesthetics/fun/hearing remain unverified."},"\t")+"\n")
	print("ROUND218_LANDSCAPE_LIVE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
