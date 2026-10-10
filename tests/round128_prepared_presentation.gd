extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Job = preload("res://scripts/world/world_settlement_job.gd")
const Reference = preload("res://tests/round128_presentation_reference.gd")
var checks: Dictionary = {}
var cases: Array = []
var max_pcm_error := 0.0
var old_script: GDScript

func _initialize() -> void: call_deferred("_run")

func _prepare(model: ContinuousAudioModel) -> void:
	model.enable_background_settlement()
	model.prepare_settlement(model.next_boundary-22050,22050)
	while not model.settlement_job.completed(): await process_frame
	model.prepare_settlement(model.next_boundary-22050,22050)

func _pair(family: String,late: String = "") -> void:
	var models: Array[ContinuousAudioModel] = []
	for script in [Model,old_script]:
		var city := World.new("2026100900000062",true,family)
		city.build_starter("bright")
		var model: ContinuousAudioModel = script.new(city,1.3409036)
		model.rendered_until = model.next_boundary-2*model.beat_frames
		model.submit({"kind":"bridge"})
		if late.is_empty():
			model.submit({"kind":"retune","id":city.buildings[0]["district_id"],"midi":55})
			model.submit({"kind":"solo","community":city.buildings[0]["community_id"]})
		models.append(model)
	var actual := models[0]
	var reference := models[1]
	await _prepare(actual)
	await _prepare(reference)
	for model in models:
		if late == "retune": model.submit({"kind":"retune","id":model.world.buildings[0]["district_id"],"midi":55})
		elif late == "flow": model.world.record_transit_flow("west-2",5,3,1)
		elif late == "cancel": model.cancel_pending()
	var at := actual.next_boundary
	var state: Dictionary = {}
	var expected_state: Dictionary = {}
	var block := actual.render_block(state,at-256,512,22050)
	var expected := reference.render_block(expected_state,at-256,512,22050)
	var error := 0.0
	for i in range(block.size()): error = maxf(error,block[i].distance_to(expected[i]))
	max_pcm_error = maxf(max_pcm_error,error)
	var name := family+("_late_"+late if not late.is_empty() else "")
	checks[name+"_pcm"] = error == 0.0 and state == expected_state
	checks[name+"_world"] = actual.world.snapshot() == reference.world.snapshot()
	var shown := actual.presentation_world(at-1)
	var old_shown := reference.presentation_world(at-1)
	checks[name+"_old_city"] = shown.snapshot() == old_shown.snapshot()
	checks[name+"_derived"] = shown.fabric_cache == old_shown.fabric_cache and shown.edge_cache == old_shown.edge_cache and shown.public_service_cache == old_shown.public_service_cache and shown.resonance == old_shown.resonance
	checks[name+"_physical_routes"] = shown.network.roads == old_shown.network.roads and shown.network.walking_distance(Vector2(8,8),Vector2(24,8)) == old_shown.network.walking_distance(Vector2(8,8),Vector2(24,8))
	var saved := actual.capture_state()
	checks[name+"_dna_exact"] = saved == reference.capture_state()
	checks[name+"_no_runtime_objects"] = saved["presentation_history"].all(func(entry: Dictionary) -> bool: return not entry.has("view") and not entry.has("derived"))
	var resumed := Model.from_state(saved)
	checks[name+"_dna_old_city"] = resumed.presentation_world(at-1).snapshot() == old_shown.snapshot()
	var resumed_state := state.duplicate(true)
	var continued := actual.render_block(state,at+256,512,22050)
	var playback := resumed.render_block(resumed_state,at+256,512,22050)
	var resume_error := 0.0
	for i in range(continued.size()): resume_error = maxf(resume_error,continued[i].distance_to(playback[i]))
	max_pcm_error = maxf(max_pcm_error,resume_error)
	checks[name+"_dna_pcm"] = resume_error == 0.0 and state == resumed_state
	checks[name+"_prepared_gate"] = actual.presentation_stats["prepared"] == (1 if late.is_empty() else 0) and actual.settlement_stats["fallbacks"] == (0 if late.is_empty() else 1)
	var saved_history: Array = saved["presentation_history"].duplicate(true)
	actual.close_background_settlement()
	reference.close_background_settlement()
	checks[name+"_retirement_preserves_history"] = actual.capture_state()["presentation_history"] == saved_history
	# Transit in the old display and live pending updates must never mutate DNA's input.
	var old_before: Dictionary = actual.presentation_history[-1]["before"].duplicate(true)
	shown.record_transit_flow("west-2",4,1,1)
	actual.world.pending = {"kind":"seed","frame":at+actual.phrase_frames}
	actual.presentation_world(at-1)
	checks[name+"_display_isolation"] = actual.presentation_history[-1]["before"] == old_before
	checks[name+"_exact_reveal"] = actual.presentation_world(at) == actual.world and actual.presentation_copy == null
	cases.append({"name":name,"pcm_error":error,"resume_pcm_error":resume_error,"presentation":actual.presentation_stats.duplicate(),"background":actual.settlement_stats.duplicate()})

func _run() -> void:
	old_script = Reference.make_script()
	for family in ValleyTerrain.family_ids(): await _pair(family)
	for change in ["retune","flow","cancel"]: await _pair("river_valley",change)
	# A live fallback can proceed while the obsolete worker reads its own old city.
	var city := World.new()
	city.build_expanded_town()
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	for i in range(1,42): city.settle(i*phrase)
	var before := city.snapshot()
	var before_fabric := city.fabric_cache.duplicate(true)
	var before_edges := city.edge_cache.duplicate(true)
	var before_service := city.public_service_cache.duplicate(true)
	var before_resonance := city.resonance
	var cache := city.fabric_anchor_cache
	var cache_hash := hash(cache)
	var job := Job.new()
	job.start(city,[city.phrase_index,city.action_serial],42*phrase)
	city.settle(42*phrase)
	while not job.completed(): await process_frame
	job.join()
	var old_world := World.new(before["seed_hex"],false)
	# Match the published old cache, which intentionally refreshes every other
	# natural-growth phrase; a fresh full rebuild is a different reference.
	old_world.restore(before,false)
	old_world.fabric_cache = before_fabric
	old_world.edge_cache = before_edges
	old_world.public_service_cache = before_service
	old_world.resonance = before_resonance
	checks["concurrent_large_city"] = city.buildings.size() >= 400 and job.result.snapshot() == city.snapshot()
	checks["concurrent_prepared_old_city"] = job.snapshot == before and job.presentation_view.snapshot() == old_world.snapshot() and job.presentation_view.fabric_cache == old_world.fabric_cache
	checks["published_cache_isolation"] = hash(cache) == cache_hash
	var retained_view := job.presentation_view
	var retained_snapshot := job.snapshot
	job.retire()
	while not job.completed(): await process_frame
	job.join()
	checks["retired_view_alive"] = retained_view.snapshot() == old_world.snapshot() and retained_snapshot == before
	var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"cases":cases,"max_pcm_error":max_pcm_error,"concurrent_buildings":city.buildings.size()}
	FileAccess.open("res://验证记录/连续河谷/第128轮_后台呈现等价.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("PREPARED_PRESENTATION ",JSON.stringify(result))
	quit(0 if result["passed"] else 1)
