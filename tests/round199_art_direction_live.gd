extends SceneTree
## One real city, four presentation styles, then the same live WASAPI queue.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Sample = preload("res://scripts/world/art_direction_sample.gd")
const Identity = preload("res://scripts/visual/first_expression_identity.gd")
const Duet = preload("res://scripts/world/authored_duet.gd")
const WorldProjection = preload("res://scripts/world/world_projection.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const OUTPUT := "res://验证记录/round199_美术对照/"
const STYLES := ["baseline","clay","garden","paper"]
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var output_directory := ""
var recording: LiveRecording

class LiveRecording extends RefCounted:
	var model: ContinuousAudioModel
	var begin := 0
	var end := 0
	var samples := PackedVector2Array()
	func _mix_frame(_state: Dictionary,_at: int,_rate: int) -> Vector2: return Vector2.ZERO
	func prepare_settlement(at: int,rate: int) -> void: model.prepare_settlement(at,rate)
	func close_background_settlement() -> void: model.close_background_settlement()
	func render_block(state: Dictionary,start: int,count: int,rate: int) -> PackedVector2Array:
		var block := model.render_block(state,start,count,rate)
		if start < end and start+count > begin:
			samples.append_array(block.slice(maxi(0,begin-start),mini(count,end-start)))
		return block

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _write_json(name: String,data: Dictionary) -> void:
	FileAccess.open(output_directory+name,FileAccess.WRITE).store_string(JSON.stringify(data,"\t")+"\n")

func _hash(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _fixture() -> World:
	var city := Sample.build()
	check(city.phrase_index == 4 and city.development_charters.size() == 1,"fixture_uses_four_real_settlements_and_one_actual_charter")
	check(city.public_sites.any(func(site: Dictionary) -> bool: return bool(site.get("active",false)) and str(site["kind"]) == "civic" and bool(site.get("player_planned",false))),"fixture_contains_actual_authored_civic")
	check(city.public_sites.any(func(site: Dictionary) -> bool: return bool(site.get("active",false)) and str(site["kind"]) == "park" and bool(site.get("player_planned",false))),"fixture_contains_actual_authored_park")
	check(Duet.roots(city).size() == 2 and city.buildings.any(func(building: Dictionary) -> bool: return str(building["type"]) == "commercial" and bool(building.get("player_expression",false))),"fixture_contains_two_real_authors_and_actual_commercial_use")
	return city

func _until(frame: int) -> bool:
	var rate := demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0.0,(frame-demo.clock.renderer.transport.audible_frame)/float(rate))*1000.0)+8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.clock.renderer.transport.audible_frame >= frame: return true
	return false

func _capture(name: String) -> void:
	demo.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	check(demo.get_viewport().get_texture().get_image().save_png(output_directory+name+".png") == OK,"capture_"+name)

func _refresh_frozen_view() -> void:
	demo._sync_buildings()
	demo._sync_daylight()
	demo.street_eaves_layer.sync(demo)
	demo.expression_audition_layer.sync(demo)
	demo.authored_voice_badges.sync(demo)
	demo.music_activity_layer.sync(demo)
	demo.public_space_activity_layer.sync(demo)
	demo.queue_redraw()

func _opaque_point(id: String) -> Vector2:
	var sprite: AudioGrowthMask = demo.sprites[id]
	var image: Image = demo.building_geometry[id]["image"]
	for y in range(1,19):
		for x in range(1,19):
			var pixel := Vector2(float(image.get_width())*x/20.0,float(image.get_height())*y/20.0)
			if image.get_pixelv(Vector2i(pixel)).a < 0.75: continue
			var screen := sprite.to_global(sprite.offset+pixel)
			if demo._hit(screen) == id: return screen
	return Vector2.INF

func _alpha_hit_check(id: String) -> bool:
	if _opaque_point(id) == Vector2.INF: return false
	var sprite: AudioGrowthMask = demo.sprites[id]
	var image: Image = demo.building_geometry[id]["image"]
	var corners := [Vector2(1.5,1.5),Vector2(image.get_width()-1.5,1.5),Vector2(1.5,image.get_height()-1.5),Vector2(image.get_width()-1.5,image.get_height()-1.5)]
	for pixel: Vector2 in corners:
		if image.get_pixelv(Vector2i(pixel)).a <= 0.1:
			return demo._hit(sprite.to_global(sprite.offset+pixel)) != id
	return false

func _style_integration(style: String,author_ids: Array[String]) -> Dictionary:
	var records: Dictionary = {}
	var building_ok := true
	var shadow_ok := true
	var author_ok := true
	for building: Dictionary in demo.shown_world.buildings:
		var id := str(building["district_id"])
		var entry: Dictionary = demo.building_geometry[id]["entry"]
		var family: Dictionary = demo.shown_world.families.get(str(building.get("family_id","")),{})
		var expected: Dictionary = demo.building_catalog.entry_for(building,demo.assets[building["type"]],family)
		building_ok = building_ok and str(entry["id"]) == str(expected["id"]) and demo.sprites[id].texture == demo.building_catalog.texture_for(expected) and demo.building_geometry[id]["image"] == demo.building_catalog.image_for(expected)
		shadow_ok = shadow_ok and str(demo.shadow_records[id]["entry"]["shadow_texture"]) == str(entry["shadow_texture"]) and str(demo.shadow_records[id]["entry"]["contact_texture"]) == str(entry["contact_texture"])
		for kind: String in ["shadow","contact"]:
			var used := false
			for key: Array in demo.shadow_layer.members[kind]:
				if str(key[0]) == str(entry[kind+"_texture"]): used = true; break
			shadow_ok = shadow_ok and used
		var expression := Identity.expression_for(building,family)
		if not expression.is_empty(): author_ok = author_ok and str(entry.get("first_expression_style","")) == expression
		records[id] = {"entry_id":entry["id"],"texture":entry["texture"],"shadow":entry["shadow_texture"],"position":[demo.sprites[id].position.x,demo.sprites[id].position.y],"expression":expression,"actual_type":building["type"]}
	check(building_ok,style+"_cached_geometry_image_and_sprite_show_the_selected_catalogue")
	check(shadow_ok,style+"_selected_building_masks_reach_the_union_layer")
	check(author_ok,style+"_actual_author_route_identity_survives")
	var props: Dictionary = {}
	var prop_ok := true
	var tree_count := 0
	var civic_count := 0
	for key: String in demo.scenery.props:
		var prop: ValleyProp = demo.scenery.props[key]
		if prop.kind not in ["tree","civic"] or not prop.visible: continue
		if prop.kind == "tree": tree_count += 1
		else: civic_count += 1
		var desired: Dictionary = demo.art_direction.prop_entry(prop.kind,prop.tone)
		if style == "baseline":
			prop_ok = prop_ok and prop.art_entry.is_empty() and prop.art_texture == null and prop.art_shadow == null and prop.art_contact == null
		else:
			prop_ok = prop_ok and str(prop.art_entry.get("id","")) == str(desired.get("id","")) and prop.art_texture != null and prop.art_shadow != null and prop.art_contact != null
		props[key] = {"kind":prop.kind,"entry_id":prop.art_entry.get("id","baseline"),"public_scale":prop.get_meta("public_scale",1.0),"position":[prop.position.x,prop.position.y]}
	check(prop_ok and tree_count > 0 and civic_count > 0,style+"_actual_trees_and_civic_show_matching_art_and_masks")
	var ground_ok := str(demo.terrain_layer.art_style_id) == style and str(demo.city_ground_layer.art_style_id) == style
	for part in demo.city_ground_layer.urban_parts.values(): ground_ok = ground_ok and str(part.art_style_id) == style
	check(ground_ok,style+"_terrain_and_retained_urban_parts_refresh")
	var hits_ok := true
	for id: String in author_ids: hits_ok = hits_ok and _alpha_hit_check(id)
	check(hits_ok,style+"_actual_author_images_have_opaque_hits_and_transparent_misses")
	return {"buildings":records,"props":props,"trees":tree_count,"civic":civic_count,"shadow_members":demo.shadow_layer.members["shadow"].size(),"eaves":demo.street_eaves_layer.diagnostics()}

func _offline_pcm(snapshot: Dictionary,rate: int) -> PackedByteArray:
	var city := World.new(str(snapshot["seed_hex"]),false,"river_valley")
	city.restore(snapshot)
	var model := Model.new(city,demo.fixed_gain)
	var renderer := Renderer.new(rate)
	var begin := city.phrase_index*int(city.cfg["timing"]["phrase_frames"])
	model.rendered_until = begin
	renderer.transport.rendered_frames = begin
	renderer.transport.audible_frame = float(begin)
	renderer.source = model._mix_frame
	return Renderer.pcm16(renderer.render(rate*10))

func _click(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)

func _finish() -> void:
	if demo != null:
		demo.clock.stop_output()
		demo.queue_free()
		await process_frame
	_write_json("live.json",{"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Actual Godot/OpenGL city with real World transactions. Four fixed-camera/daylight/cursor screenshots use a short paused device queue; the same renderer and queue resume for WASAPI input PCM and real building retune. No human fun or listening-quality judgment."})
	print("ROUND199_ART_DIRECTION ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," evidence=",output_directory)
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	var timestamp := Time.get_datetime_string_from_system().replace(":","-")
	output_directory = OUTPUT+"run_"+timestamp+"_"+str(Time.get_ticks_msec())+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))
	var city := _fixture()
	if not failures.is_empty():
		evidence["fixture"] = city.snapshot()
		await _finish()
		return
	var fixture := city.snapshot()
	_write_json("fixture.json",fixture)
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	demo.art_study_enabled = true
	root.add_child(demo)
	await process_frame
	demo._start_world({},city)
	demo.clock.start_output(demo.model._mix_frame,{},demo.clock.renderer.snapshot())
	var rate := demo.clock.renderer.transport.sample_rate
	var start := city.phrase_index*int(city.cfg["timing"]["phrase_frames"])
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","physical_window_and_WASAPI_device")
	check(await _until(start+rate),"fixture_enters_the_actual_device_timeline")
	demo.daylight_manual_phase = 0.0
	demo.menu.hide()
	demo.planning_guide.hide_tool()
	demo.pointer_inside = false
	demo.clock.player.stream_paused = true
	demo.clock.set_process(false)
	demo.set_process(false)
	var held_frame := demo.clock.renderer.transport.audible_frame
	var held_renderer := demo.clock.renderer
	var held_playback := demo.clock.playback
	var held_source := demo.clock.renderer.source
	var author_ids: Array[String] = []
	for record: Dictionary in Duet.roots(demo.shown_world): author_ids.append(str(record["root_id"]))
	var held_world := demo.shown_world.snapshot()
	var held_world_hash := JSON.stringify(held_world).sha256_text()
	var held_scenery := demo.scenery.snapshot()
	demo._home_city()
	var wide_zoom := demo.zoom_target
	var wide_pan := demo.pan_target
	var close_center := Vector2.ZERO
	var close_count := 0
	for building: Dictionary in demo.shown_world.buildings:
		if str(building["community_id"]) not in ["west-2","east-2"]: continue
		var p := Coupling.position_of(building)
		close_center += WorldProjection.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),demo.shown_world.terrain.height_at(p))
		close_count += 1
	close_center /= float(close_count)
	var close_zoom := 1.9
	var close_pan := -close_center*close_zoom+Vector2(0,35)
	var style_evidence: Dictionary = {}
	var pcm_hashes: Dictionary = {}
	var reference_pcm := PackedByteArray()
	for style: String in STYLES:
		var saved_before := demo.capture_city()
		demo.art_review_panel.buttons[style].emit_signal("pressed")
		check(demo.capture_city() == saved_before,style+"_style_button_preserves_complete_work_and_audio_state")
		check(demo.art_direction.selected_id == style,style+"_review_button_selects_the_style")
		demo.view_zoom = wide_zoom
		demo.zoom_target = wide_zoom
		demo.pan = wide_pan
		demo.pan_target = wide_pan
		_refresh_frozen_view()
		style_evidence[style] = _style_integration(style,author_ids)
		await _capture("01_"+style+"_同城全景")
		demo.view_zoom = close_zoom
		demo.zoom_target = close_zoom
		demo.pan = close_pan
		demo.pan_target = close_pan
		_refresh_frozen_view()
		await _capture("02_"+style+"_同街近景")
		check(demo.clock.renderer.transport.audible_frame == held_frame and demo.shown_world.snapshot() == held_world and demo.scenery.snapshot() == held_scenery,style+"_screenshots_hold_identical_city_travelers_and_device_cursor")
		var pcm := _offline_pcm(demo.model.world.snapshot(),rate)
		pcm_hashes[style] = _hash(pcm)
		if style == "baseline": reference_pcm = pcm
		check(pcm == reference_pcm and pcm.size() == rate*10*4,style+"_independent_same_world_ten_second_PCM_is_identical")
	demo.set_art_direction("baseline")
	check(demo.scenery.props.values().all(func(prop: ValleyProp) -> bool: return prop.art_entry.is_empty()),"returning_to_baseline_restores_all_original_procedural_props")
	check(demo.clock.renderer == held_renderer and demo.clock.playback == held_playback and demo.clock.renderer.source == held_source,"style_comparison_never_restarts_or_replaces_the_audio_queue")
	evidence["fixed_comparison"] = {"styles":style_evidence,"city_sha256":held_world_hash,"audible_frame":held_frame,"daylight_phase":0.0,"wide_zoom":wide_zoom,"wide_pan":[wide_pan.x,wide_pan.y],"close_zoom":close_zoom,"close_pan":[close_pan.x,close_pan.y],"offline_pcm_sha256":pcm_hashes,"pause_scope":"Device queue and clock/demo processing held for fixed screenshots and isolated PCM comparison, then resumed in place."}
	# Resume the existing queue. Record precisely the next eight rendered
	# seconds and switch all four styles while the live clock continues.
	recording = LiveRecording.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*8
	demo.clock.renderer.source = recording._mix_frame
	var live_renderer := demo.clock.renderer
	var live_playback := demo.clock.playback
	var start_skips := demo.clock.underruns
	demo.set_process(true)
	demo.clock.set_process(true)
	demo.clock.player.stream_paused = false
	var live_start := int(demo.clock.renderer.transport.audible_frame)
	var previous_frame := live_start
	for index in range(STYLES.size()):
		if index > 0: check(await _until(live_start+index*rate*2),"live_clock_reaches_style_"+str(index))
		var before := demo.model.world.snapshot()
		demo.art_review_panel.buttons[STYLES[index]].emit_signal("pressed")
		check(demo.model.world.snapshot() == before and demo.clock.renderer == live_renderer and demo.clock.playback == live_playback,"live_"+STYLES[index]+"_style_changes_only_presentation")
		check(demo.clock.renderer.transport.audible_frame >= previous_frame,"live_"+STYLES[index]+"_cursor_is_monotonic")
		previous_frame = int(demo.clock.renderer.transport.audible_frame)
	# Map hit uses the selected candidate's alpha mask, then the existing note
	# button sends a real retune which must reach the heard pitch dictionary.
	var target := author_ids[0]
	var target_point := _opaque_point(target)
	check(target_point != Vector2.INF,"paper_author_building_has_a_clickable_actual_pixel")
	if target_point != Vector2.INF:
		_click(target_point)
		check(demo.menu.visible and demo.selected_id == target and demo.context.get("kind","") == "retune","clicking_candidate_building_opens_its_real_retune_menu")
		await _capture("03_纸上城镇_真实建筑改音菜单")
		var current := int(demo.model.audible_pitches().get(target,demo.shown_world.by_id[target]["current_midi"]))
		var note := 52 if posmod(current,12) != 4 else 55
		var heard_target := demo._note_pitch(note)
		var choices: Control = demo.menu.get_meta("notes")
		var note_index := [48,50,52,55,57].find(note)
		choices.get_child(note_index).emit_signal("pressed")
		check(await _until(int(demo.clock.renderer.transport.audible_frame)+rate),"real_retune_reaches_the_device_beat")
		check(int(demo.model.audible_pitches().get(target,-1)) == heard_target,"candidate_art_keeps_actual_playable_retune")
		evidence["retune"] = {"id":target,"before":current,"after":demo.model.audible_pitches().get(target,-1),"expected":heard_target,"style":demo.art_direction.selected_id}
	check(await _until(recording.end+rate/10),"eight_second_device_input_recording_finishes")
	check(recording.samples.size() == rate*8,"device_input_contains_exactly_eight_seconds")
	check(demo.clock.underruns == start_skips,"live_style_switches_and_retune_have_no_new_underrun")
	var pcm := Renderer.pcm16(recording.samples)
	var peak := 0.0
	var clipped := 0
	var energy := 0.0
	for sample: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		if absf(sample.x) >= 1.0 or absf(sample.y) >= 1.0: clipped += 1
		energy += sample.x*sample.x+sample.y*sample.y
	check(peak > 0.0001 and clipped == 0,"live_device_input_is_audible_and_has_no_clipped_frame")
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = rate
	audio.stereo = true
	audio.data = pcm
	audio.save_to_wav(output_directory+"四种候选切换与真实改音_设备输入.wav")
	evidence["live_audio"] = {"driver":AudioServer.get_driver_name(),"rate":rate,"samples":recording.samples.size(),"underruns":demo.clock.underruns-start_skips,"peak":peak,"rms":sqrt(energy/maxi(1,recording.samples.size()*2)),"clipped_frames":clipped,"pcm_sha256":_hash(pcm),"renderer_retained":demo.clock.renderer == live_renderer,"queue_retained":demo.clock.playback == live_playback}
	await _capture("04_纸上城镇_真实换音后城市")
	await _finish()
