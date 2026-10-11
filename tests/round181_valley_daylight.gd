extends SceneTree
## Pure visual clock/continuity proof. Root owns actual screenshots/devices.
const Daylight = preload("res://scripts/visual/valley_daylight.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const OUTPUT := "res://验证记录/round181_河谷昼夜/valley_daylight.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)
func _color_difference(a: Color,b: Color) -> float:
	return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),maxf(absf(a.b-b.b),absf(a.a-b.a))))
func _difference(a: Dictionary,b: Dictionary) -> float:
	var maximum := absf(float(a["night_strength"])-float(b["night_strength"]))
	for field in ["world_tint","backdrop","water_tint","ui_ink"]: maximum = maxf(maximum,_color_difference(a[field],b[field]))
	return maximum
func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var model := Model.new(city)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var day := Daylight.sample(0,rate)
	var dusk := Daylight.sample(rate*Daylight.CYCLE_SECONDS*0.28,rate)
	var night := Daylight.sample(rate*Daylight.CYCLE_SECONDS*0.5,rate)
	var dawn := Daylight.sample(rate*Daylight.CYCLE_SECONDS*0.78,rate)
	check(Daylight.CYCLE_SECONDS >= 120.0 and Daylight.CYCLE_SECONDS <= 180.0 and day["phase"] == 0.0 and day["label"] == "白昼" and day["world_tint"] == Color.WHITE and day["night_strength"] == 0.0,"new_work_starts_in_daylight_with_a_two_to_three_minute_visual_cycle")
	check(dusk["label"] == "黄昏" and night["label"] == "夜晚" and dawn["label"] == "晨光" and dusk["world_tint"].r > dusk["world_tint"].b and night["world_tint"].b > night["world_tint"].r,"audible_time_progresses_through_warm_dusk_cool_night_and_dawn")
	var tint: Color = night["world_tint"]
	check(minf(tint.r,minf(tint.g,tint.b)) >= 0.46 and float(night["shadow_strength"]) >= 0.5 and float(night["night_strength"]) >= 0.95 and night["water_tint"].g > tint.g,"night_keeps_geometry_and_water_readable_with_nonzero_grounding")
	check(_difference(day,Daylight.sample(rate*Daylight.CYCLE_SECONDS,rate)) == 0.0 and _difference(night,Daylight.sample(rate*Daylight.CYCLE_SECONDS*1.5,rate)) == 0.0,"cycle_wrap_repeats_without_an_accumulated_visual_clock")
	check(_difference(night,Daylight.sample(44100*Daylight.CYCLE_SECONDS*0.5,44100)) == 0.0,"visual_time_uses_the_supplied_sample_rate")
	var maximum_join := 0.0
	for stop: float in Daylight.STOPS:
		var frame := stop*rate*Daylight.CYCLE_SECONDS
		maximum_join = maxf(maximum_join,_difference(Daylight.sample(frame-1,rate),Daylight.sample(frame+1,rate)))
		maximum_join = maxf(maximum_join,_difference(Daylight.sample(frame+rate*Daylight.CITY_DELAY_SECONDS-1,rate),Daylight.sample(frame+rate*Daylight.CITY_DELAY_SECONDS+1,rate)))
	check(maximum_join < 0.00001,"all_curve_joins_and_the_next_day_are_continuous_at_sample_precision")
	check(_difference(Daylight.sample(0,rate,0.5),Daylight.sample(rate*61,rate,0.5)) == 0.0 and Daylight.sample(0,rate,0.5)["label"] == "夜晚" and Daylight.sample(0,rate)["label"] == "白昼","manual_screenshot_phase_is_runtime_only_and_does_not_change_future_sampling")
	var phases: Dictionary = {}
	model.render_block(phases,0,777,rate)
	var captured := model.capture_state()
	var captured_phases := phases.duplicate(true)
	var rng := city.rng.snapshot()
	for index in range(301): Daylight.sample(float(index)*rate*0.5,rate)
	check(model.capture_state() == captured and phases == captured_phases and city.rng.snapshot() == rng,"visual_sampling_does_not_change_model_world_rng_pending_or_audio_phases")
	var restored := Model.from_state(captured)
	check(Daylight.sample(model.rendered_until,rate) == Daylight.sample(restored.rendered_until,int(restored.world.cfg["timing"]["sample_rate"])),"existing_saved_absolute_audio_frame_restores_the_same_visual_phase_without_new_fields")
	var baseline := model.freeze()
	var visual := model.freeze()
	var baseline_phases := phases.duplicate(true)
	var visual_phases := phases.duplicate(true)
	var baseline_pcm := PackedByteArray()
	var visual_pcm := PackedByteArray()
	for index in range(3):
		var frame := 777+index*777
		baseline_pcm.append_array(Renderer.pcm16(baseline.render_block(baseline_phases,frame,777,rate)))
		Daylight.sample(frame,rate)
		visual_pcm.append_array(Renderer.pcm16(visual.render_block(visual_phases,frame,777,rate)))
	check(baseline_pcm == visual_pcm and baseline_phases == visual_phases and baseline.world.snapshot() == visual.world.snapshot(),"same_formal_audio_and_city_continuation_are_byte_identical_with_visual_sampling")
	evidence = {"sample_rate":rate,"cycle_seconds":Daylight.CYCLE_SECONDS,"day":day,"dusk":dusk,"night":night,"dawn":dawn,
		"maximum_one_sample_join_difference":maximum_join,"saved_audio_frame":model.rendered_until,"compared_pcm_frames":2331,"pcm_bytes_equal":baseline_pcm == visual_pcm,
		"scope":"Pure visual clock, smooth tint, existing frame restore and unchanged real PCM/World. Layer integration, black-screen hiding and pixel readability are Root's Windows screenshot checks; this is not a human art verdict."}
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND181_VALLEY_DAYLIGHT "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
