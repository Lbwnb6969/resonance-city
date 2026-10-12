extends SceneTree
## One real nightly voice choice, then a legal civic fixture for its new mask.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const Sample = preload("res://scripts/world/art_direction_sample.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var output := "res://验证记录/round209_古典夜景/"
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
	FileAccess.open(output+"progress.json",FileAccess.WRITE).store_string(JSON.stringify({"complete":false,"last_capture":label,"checks":checks,"failures":failures},"\t")+"\n")
func focus(at: Vector2,zoom: float = 3.0) -> void:
	demo.zoom_target = zoom
	demo.pan_target = -demo.Projection2D.to_screen(at-Vector2(16,16),Vector2.ZERO,zoom,Vector2(28,14),demo.shown_world.terrain.height_at(at))
func input_key(key: int) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	demo._input(event)
func facade_count() -> int:
	var count := 0
	for light: Sprite2D in demo.facade_lights.values():
		if light.is_visible_in_tree(): count += 1
	return count

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
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","actual_window_and_output")
	check(demo.building_catalog.emission_textures.size() == 32 and demo.building_catalog.emission_textures.values().all(func(texture: Texture2D) -> bool: return texture != null),"real_four_angle_masks_are_imported_and_prewarmed")
	check(await until_frame(rate*6),"real_opening_reaches_device")
	check(demo.shown_world.buildings.size() == 24 and facade_count() == 0,"real_24_house_daylight_has_no_emission")
	var at := demo.Coupling.position_of(demo.shown_world.buildings[0])
	focus(at)
	await create_timer(0.7).timeout
	await capture("00_古典街坊白昼")
	var before := demo.model.world.snapshot()
	demo.daylight_manual_phase = 0.53
	await process_frame
	await process_frame
	check(facade_count() == 24,"only_real_fully_revealed_houses_emit_at_night")
	var lit_lamps := 0
	for prop: ValleyProp in demo.scenery.props.values():
		if prop.kind == "lamp" and prop.classical_lamp_light != null and prop.classical_lamp_light.is_visible_in_tree(): lit_lamps += 1
	check(lit_lamps > 0,"actual_oil_bowls_have_night_light")
	await capture("01_石街夜色_门洞与陶碗油灯")
	# Same actual GPU scene with the emissive facade layer hidden for comparison.
	demo.set_process(false)
	for light: Sprite2D in demo.facade_lights.values(): light.hide()
	await capture("01a_同景关闭门洞暖光_对照")
	demo.set_process(true)
	await process_frame
	await process_frame
	input_key(KEY_B)
	await process_frame
	await process_frame
	check(facade_count() == 0,"black_mode_hides_actual_facade_lights")
	input_key(KEY_B)
	await process_frame
	await process_frame
	check(facade_count() == 24,"black_mode_returns_to_same_heard_lights")
	check(demo.model.world.snapshot() == before,"day_night_and_black_review_do_not_write_city")
	DisplayServer.window_set_size(Vector2i(800,600))
	await process_frame
	await process_frame
	check(demo._begin_first_sound_choice("west-2"),"night_voice_menu_uses_actual_street_parcel")
	demo.expression_choices["warm"].emit_signal("pressed")
	var deadline := Time.get_ticks_msec()+8000
	while not demo.preview_started and Time.get_ticks_msec() < deadline: await process_frame
	check(demo.preview_started and demo.preview_player.playing and facade_count() == 24,"actual_warm_audition_keeps_existing_city_lit")
	await create_timer(0.7).timeout
	var raw: Array = demo.context["position"]
	var target := demo.point(Vector2(float(raw[0]),float(raw[1])))
	check(Rect2(Vector2.ZERO,demo.size).encloses(demo.menu.get_global_rect()) and not demo.menu.get_global_rect().intersects(Rect2(target-Vector2(90,100),Vector2(180,170))),"night_small_window_keeps_whole_target_clear")
	await capture("02_800x600_夜景暖庭真实试听")
	demo.expression_confirm.emit_signal("pressed")
	var boundary := demo.model.next_boundary
	check(await until_frame(boundary-rate/10),"reaches_render_ahead_before_audible_birth")
	check(demo._first_authored_state().is_empty() and facade_count() == 24,"render_ahead_cannot_light_future_authored_house")
	check(await until_frame(boundary+rate),"authored_root_reaches_actual_audible_reveal")
	var work := demo._first_authored_state()
	var root_id := str(work.get("root_id",""))
	check(not root_id.is_empty() and demo.facade_lights[root_id].is_visible_in_tree() and demo.facade_lights[root_id].get_parent() == demo.sprites[root_id],"heard_authored_root_lights_its_own_sorted_facade")
	DisplayServer.window_set_size(Vector2i(1440,900))
	focus(demo.Coupling.position_of(demo.shown_world.by_id[root_id]))
	await create_timer(0.7).timeout
	await capture("03_你的暖庭_可听落成后的夜色")
	var visible_after_birth := facade_count()
	demo.daylight_manual_phase = 0.0
	await process_frame
	await process_frame
	check(facade_count() == 0,"returning_daylight_extinguishes_doorway_emission")
	# Legal transactions supply a civic, park and two authored roots; not scenery.
	demo.daylight_manual_phase = 0.53
	var sample := Sample.build()
	demo._start_world({},sample)
	demo.clock.start_output(demo.model._mix_frame,{},demo.clock.renderer.snapshot())
	await create_timer(1.0).timeout
	check(demo.facade_lights.size() == demo.shown_world.buildings.size() and demo.facade_lights.keys().all(func(id: String) -> bool: return demo.facade_lights[id].get_parent() == demo.sprites[id]),"switching_city_discards_all_old_light_children")
	var civic: ValleyProp
	for prop: ValleyProp in demo.scenery.props.values():
		if prop.kind == "civic" and prop.visible: civic = prop; break
	check(civic != null and civic.classical_facade_light != null and civic.classical_facade_light.is_visible_in_tree(),"actual_legal_civic_uses_its_projected_emission_mask")
	if civic != null: focus(civic.get_meta("world_position"),2.4)
	await create_timer(0.7).timeout
	await capture("04_实际文化馆_柱廊与石街夜色")
	recording = DeviceInput.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*4
	demo.clock.renderer.source = recording._mix_frame
	check(await until_frame(recording.end),"night_scene_four_seconds_reach_device")
	var peak := 0.0
	var clipped := 0
	for sample_frame: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample_frame.x),absf(sample_frame.y)))
		if absf(sample_frame.x) >= 1 or absf(sample_frame.y) >= 1: clipped += 1
	check(recording.samples.size() == rate*4 and clipped == 0,"night_scene_device_input_is_complete_and_unclipped")
	check(demo.clock.underruns == underruns,"night_presentation_adds_no_output_underrun")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = Renderer.pcm16(recording.samples)
	wav.save_to_wav(output+"古典夜景_设备输入.wav")
	demo.clock.stop_output()
	var evidence := {"opening_houses":24,"authored_houses":visible_after_birth,"actual_oil_lamps":lit_lamps,"civic_fixture_houses":demo.shown_world.buildings.size(),"sample_rate":rate,"samples":recording.samples.size(),"peak":peak,"clipped":clipped,"underruns":demo.clock.underruns-underruns}
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Actual window/audio, one voice choice and a legal civic fixture. Technical, screenshot, human aesthetic/fun/listening judgements remain separate."},"\t")+"\n")
	print("ROUND209_CLASSICAL_NIGHT ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
