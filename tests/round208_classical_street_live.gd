extends SceneTree
## Physical presentation, one real voice choice and four seconds of device input.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var output := "res://验证记录/round208_古典街景/"
var recording: DeviceInput

class DeviceInput extends RefCounted:
	var model: ContinuousAudioModel
	var begin: int
	var end: int
	var samples := PackedVector2Array()
	func _mix_frame(_state: Dictionary,_at: int,_rate: int) -> Vector2: return Vector2.ZERO
	func prepare_settlement(at: int,rate: int) -> void: model.prepare_settlement(at,rate)
	func close_background_settlement() -> void: model.close_background_settlement()
	func render_block(state: Dictionary,start: int,count: int,rate: int) -> PackedVector2Array:
		var block := model.render_block(state,start,count,rate)
		if start < end and start+count > begin: samples.append_array(block.slice(maxi(0,begin-start),mini(count,end-start)))
		return block

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label); push_error(label)
func until_frame(frame: int) -> bool:
	var rate := demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0,(frame-demo.clock.renderer.transport.audible_frame)/float(rate))*1000)+8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.clock.renderer.transport.audible_frame >= frame: return true
	return false
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+label+".png")

func _run() -> void:
	output += "run_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var underruns := demo.clock.underruns
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","physical_window_and_output")
	check(await until_frame(rate*6),"opening_reaches_actual_audible_city")
	check(demo.shown_world.buildings.size() == 24 and demo.sprites.values().all(func(sprite: Node2D) -> bool: return sprite.progress >= 0.99),"opening_contains_24_real_revealed_houses")
	check(demo.view_zoom > 1.2,"opening_frames_real_town_closer_than_previous_distant_view")
	await capture("00_古典河湾_连续坡地与沿街焦点")
	var first_house: Dictionary = demo.shown_world.buildings[0]
	var first_position := demo.Coupling.position_of(first_house)
	demo.zoom_target = 3.0
	demo.pan_target = -demo.Projection2D.to_screen(first_position-Vector2(16,16),Vector2.ZERO,3,Vector2(28,14),demo.shown_world.terrain.height_at(first_position))
	await create_timer(0.9).timeout
	demo.pointer = demo.point(first_position)
	demo.pointer_inside = true
	await process_frame
	await process_frame
	check(demo.tooltip.visible and demo.tooltip.has_theme_stylebox_override("normal") and Rect2(Vector2.ZERO,demo.size).encloses(demo.tooltip.get_global_rect()),"context_tooltip_has_readable_surface_and_stays_in_view")
	await capture("01_真实街面_陶盆木器与新树形")
	check(demo._begin_first_sound_choice("west-2"),"voice_menu_opens_at_actual_street_parcel")
	demo.expression_choices["warm"].emit_signal("pressed")
	var deadline := Time.get_ticks_msec()+8000
	while not demo.preview_started and Time.get_ticks_msec() < deadline: await process_frame
	check(demo.preview_started and demo.preview_player.playing,"real_warm_voice_still_auditions")
	check(demo.expression_audition_layer.ghost.get("entry_id","") == demo.expression_choices["warm"].thumbnail_entry["id"],"voice_card_and_preview_keep_identical_street_facing_asset")
	await capture("02_暖庭真实试听_街面与声音卡")
	demo.expression_confirm.emit_signal("pressed")
	var frame := demo.model.next_boundary
	check(await until_frame(frame+rate),"confirmed_warm_root_reaches_audible_boundary_and_reveal")
	var work := demo._first_authored_state()
	check(not work.is_empty() and str(work.get("expression","")) == "warm","actual_player_root_exists_after_confirmation")
	var root_id := str(work.get("root_id",""))
	check(demo.frontage_details.layouts.has(root_id),"heard_player_root_receives_its_actual_classical_frontage")
	var root_position := demo.Coupling.position_of(demo.shown_world.by_id[root_id])
	demo.zoom_target = 3.0
	demo.pan_target = -demo.Projection2D.to_screen(root_position-Vector2(16,16),Vector2.ZERO,3,Vector2(28,14),demo.shown_world.terrain.height_at(root_position))
	demo.pointer_inside = false
	await create_timer(0.9).timeout
	await capture("03_你的暖庭_临街生活细节")
	recording = DeviceInput.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*4
	demo.clock.renderer.source = recording._mix_frame
	check(await until_frame(recording.end),"four_seconds_reach_actual_output")
	var peak := 0.0
	var clipped := 0
	for sample: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		if absf(sample.x) >= 1 or absf(sample.y) >= 1: clipped += 1
	check(recording.samples.size() == rate*4 and clipped == 0,"four_second_device_input_is_complete_and_unclipped")
	check(demo.clock.underruns == underruns,"new_street_presentation_causes_no_audio_underrun")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = Renderer.pcm16(recording.samples)
	wav.save_to_wav(output+"古典街景_设备输入.wav")
	var before := demo.model.world.snapshot()
	demo.daylight_manual_phase = 0.53
	await process_frame
	await capture("04_古典街景夜色")
	demo.daylight_manual_phase = 0.0
	DisplayServer.window_set_size(Vector2i(800,600))
	await process_frame
	await process_frame
	demo._begin_first_sound_choice("east-2")
	await create_timer(0.9).timeout
	var raw: Array = demo.context["position"]
	var target := demo.point(Vector2(float(raw[0]),float(raw[1])))
	check(Rect2(Vector2.ZERO,demo.size).encloses(demo.menu.get_global_rect()) and not demo.menu.get_global_rect().intersects(Rect2(target-Vector2(90,100),Vector2(180,170))),"small_window_menu_keeps_whole_target_clear")
	await capture("05_800x600_古典街景与声音选择")
	check(demo.model.world.snapshot() == before,"daylight_and_native_window_review_preserve_city")
	demo.clock.stop_output()
	var evidence := {"houses":demo.shown_world.buildings.size(),"natural_groves":demo.scenery.grove_clearance.size(),"frontage_houses":demo.frontage_details.layouts.size(),"root_id":root_id,"audio_samples":recording.samples.size(),"sample_rate":rate,"peak":peak,"clipped":clipped,"underruns":demo.clock.underruns-underruns}
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Real Windows/OpenGL/WASAPI street presentation and warm voice interaction; screenshot review and human aesthetic/fun/listening judgement are separate."},"\t")+"\n")
	print("ROUND208_CLASSICAL_STREET ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
