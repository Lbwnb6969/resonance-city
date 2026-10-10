extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Reference = preload("res://tests/round128_presentation_reference.gd")

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var models: Array[ContinuousAudioModel] = []
	for script in [Model,Reference.make_script()]:
		var city := World.new()
		city.build_starter("bright")
		var model: ContinuousAudioModel = script.new(city,1.3409036)
		model.submit({"kind":"bridge"})
		models.append(model)
	var actual := models[0]
	var expected := models[1]
	# Hold a real worker before computation, so the boundary cannot race a fast job.
	var delayed := GDScript.new()
	delayed.source_code = "extends \"res://scripts/world/world_settlement_job.gd\"\nvar gate := Semaphore.new()\nfunc _compute() -> void:\n\tgate.wait()\n\tsuper._compute()\n"
	assert(delayed.reload() == OK)
	actual.enable_background_settlement()
	actual.settlement_job = delayed.new()
	actual.settlement_job.start(actual.world,actual._settlement_version(),actual.next_boundary)
	var input_snapshot: Dictionary = actual.settlement_job.snapshot
	var input_before := input_snapshot.duplicate(true)
	var at := actual.next_boundary
	var state: Dictionary = {}
	var expected_state: Dictionary = {}
	var block := actual.render_block(state,at-128,256,22050)
	var reference := expected.render_block(expected_state,at-128,256,22050)
	var error := 0.0
	for i in range(block.size()): error = maxf(error,block[i].distance_to(reference[i]))
	var shown := actual.presentation_world(at-1)
	var old := expected.presentation_world(at-1)
	var checks := {"waiting_worker_falls_back":actual.settlement_stats["fallbacks"] == 1 and actual.presentation_stats["prepared"] == 0,
		"pcm_exact":error == 0.0 and state == expected_state,"world_exact":actual.world.snapshot() == expected.world.snapshot(),
		"old_city_exact":shown.snapshot() == old.snapshot() and shown.fabric_cache == old.fabric_cache}
	actual.settlement_job.gate.post()
	actual.close_background_settlement()
	checks["close_joins_worker"] = actual.settlement_job == null and actual.retiring_settlements.is_empty()
	checks["input_reference_survives_disposal"] = input_snapshot == input_before
	var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"max_pcm_error":error}
	FileAccess.open("res://验证记录/连续河谷/第128轮_未就绪回退.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("PENDING_WORKER ",JSON.stringify(result))
	quit(0 if result["passed"] else 1)
