extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Job = preload("res://scripts/world/world_settlement_job.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var city := World.new()
	city.build_expanded_town()
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	for i in range(1,42): city.settle(i*phrase)
	var published_cache := city.fabric_anchor_cache
	var immutable_hash := hash(published_cache)
	var job := Job.new()
	var started := Time.get_ticks_usec()
	job.start(city,[city.phrase_index,city.action_serial],42*phrase)
	var capture_ms := float(Time.get_ticks_usec()-started)/1000.0
	# A late-input fallback can settle live data while an obsolete task is still running.
	city.settle(42*phrase)
	while not job.completed(): await process_frame
	job.join()
	var checks := {"large_city":city.buildings.size() >= 400,"world_identical":job.result.snapshot() == city.snapshot(),
		"fabric_identical":job.result.fabric_cache == city.fabric_cache,"published_cache_unchanged":hash(published_cache) == immutable_hash}
	var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,
		"buildings":city.buildings.size(),"capture_ms":capture_ms,"worker_ms":job.worker_ms}
	job.retire()
	while not job.completed(): await process_frame
	job.join()
	FileAccess.open("res://验证记录/连续河谷/第121轮_大城缓存隔离.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("CACHE_ISOLATION ",JSON.stringify(result))
	quit(0 if result["passed"] else 1)
