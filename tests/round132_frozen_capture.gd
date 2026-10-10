extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Job = preload("res://scripts/world/world_settlement_job.gd")
const Reference = preload("res://tests/round132_capture_reference.gd")
var checks: Dictionary = {}
var cases: Array = []
var max_pcm_error := 0.0
func _initialize() -> void: call_deferred("_run")
func _prepare(model: ContinuousAudioModel) -> void:
 model.enable_background_settlement()
 model.prepare_settlement(model.next_boundary-22050,22050)
 while not model.settlement_job.completed(): await process_frame
 model.prepare_settlement(model.next_boundary-22050,22050)
func _pair(family: String,late: String = "") -> void:
 var models: Array[ContinuousAudioModel] = []
 for script in [Model,Reference.model_script()]:
  var city := World.new("2026100900000062",true,family)
  city.build_starter("bright")
  var model: ContinuousAudioModel = script.new(city,1.3409036)
  model.rendered_until = model.next_boundary-2*model.beat_frames
  model.submit({"kind":"bridge"})
  model.submit({"kind":"retune","id":city.buildings[0]["district_id"],"midi":55})
  models.append(model)
 for model in models: await _prepare(model)
 var actual := models[0]
 var reference := models[1]
 for model in models:
  if late == "retune": model.submit({"kind":"retune","id":model.world.buildings[0]["district_id"],"midi":43})
  elif late == "flow": model.world.record_transit_flow("west-2",5,3,1)
  elif late == "cancel": model.cancel_pending()
 var at := actual.next_boundary
 var state: Dictionary = {}
 var other_state: Dictionary = {}
 var a := actual.render_block(state,at-256,512,22050)
 var b := reference.render_block(other_state,at-256,512,22050)
 var error := 0.0
 for i in range(a.size()): error = maxf(error,a[i].distance_to(b[i]))
 max_pcm_error = maxf(max_pcm_error,error)
 var name := family+"_"+late
 checks[name+"_world"] = actual.world.snapshot() == reference.world.snapshot()
 checks[name+"_pcm"] = error == 0.0 and state == other_state
 var shown := actual.presentation_world(at-1)
 var other := reference.presentation_world(at-1)
 checks[name+"_audible_old"] = shown.snapshot() == other.snapshot() and shown.edge_cache == other.edge_cache and shown.fabric_cache == other.fabric_cache
 var saved := actual.capture_state()
 checks[name+"_dna"] = saved == reference.capture_state() and not saved["world"].has("environment_pending")
 checks[name+"_gate"] = actual.settlement_stats["adopted"] == (1 if late.is_empty() else 0) and actual.settlement_stats["fallbacks"] == (0 if late.is_empty() else 1)
 var resumed := Model.from_state(saved)
 var resume_state := state.duplicate(true)
 a = actual.render_block(state,at+256,256,22050)
 b = resumed.render_block(resume_state,at+256,256,22050)
 checks[name+"_resume_pcm"] = a == b and state == resume_state
 actual.close_background_settlement()
 reference.close_background_settlement()
 resumed.close_background_settlement()
 cases.append({"name":name,"error":error,"background":actual.settlement_stats.duplicate()})
func _isolation() -> void:
 var city := World.new()
 city.build_expanded_town()
 var phrase: int = city.cfg["timing"]["phrase_frames"]
 for i in range(1,42): city.settle(i*phrase)
 var before := city.snapshot()
 var old_job: RefCounted = Reference.job_script().new()
 var job := Job.new()
 old_job.start(city,[city.phrase_index],42*phrase)
 var capture := Time.get_ticks_usec()
 job.start(city,[city.phrase_index],42*phrase)
 var capture_ms := float(Time.get_ticks_usec()-capture)/1000.0
 var base := city.environment_cache
 var edges := city.edge_cache
 var base_hash := hash(base)
 var edge_hash := hash(edges)
 checks["frozen_containers"] = base.is_read_only() and edges.is_read_only()
 var queries_exact := true
 for i in range(40):
  var a := Vector2(3.31,float(i)*0.37+1.23)
  var b := Vector2(10.15,float(i)*0.27+2.31)
  queries_exact = queries_exact and city.road_environment(a,b) == city._road_environment(a,b)
 checks["queries_exact"] = queries_exact
 checks["private_query_overlay"] = city.environment_pending.size() == 40 and hash(base) == base_hash and hash(edges) == edge_hash
 while not job.completed() or not old_job.completed(): await process_frame
 job.join()
 old_job.join()
 checks["worker_result_exact"] = job.result.snapshot() == old_job.result.snapshot()
 checks["private_mature_caches"] = not job.result.environment_cache.is_read_only() and not job.result.edge_cache.is_read_only()
 checks["query_did_not_change_snapshot"] = job.snapshot == before and city.snapshot() == before
 checks["old_view_exact"] = job.presentation_view.snapshot() == old_job.presentation_view.snapshot() and job.presentation_view.edge_cache == old_job.presentation_view.edge_cache
 # A second capture includes earlier queries but isolates subsequent misses.
 var previous_delta := city.environment_pending
 var delta_hash := hash(previous_delta)
 var next_job := Job.new()
 next_job.start(city,[city.phrase_index],42*phrase)
 checks["delta_frozen"] = previous_delta.is_read_only()
 city.road_environment(Vector2(1.123,4.567),Vector2(6.789,9.123))
 checks["delta_copy_is_small"] = hash(previous_delta) == delta_hash and previous_delta.size() == 40 and city.environment_pending.size() == 41
 while not next_job.completed(): await process_frame
 next_job.join()
 var contains_delta := true
 for key in previous_delta:
  contains_delta = contains_delta and next_job.result.environment_cache.has(key) and next_job.result.environment_cache[key] == previous_delta[key]
 checks["worker_includes_previous_delta"] = contains_delta and next_job.result.environment_pending.is_empty()
 # Live fallback must leave captured roots intact, including a full graph reset.
 city.settle(42*phrase)
 checks["concurrent_fallback_exact"] = city.snapshot() == job.result.snapshot() and hash(base) == base_hash and hash(edges) == edge_hash
 city.rebuild_graph()
 checks["graph_reset_private"] = not city.environment_cache.is_read_only() and city.environment_pending.is_empty() and hash(base) == base_hash
 var restored := World.new(before["seed_hex"],false)
 restored.restore(before)
 checks["dna_runtime_cache_absent"] = restored.environment_pending.is_empty()
 var view := job.presentation_view
 var retained_before := view.snapshot()
 var saved := job.snapshot
 for task in [job,old_job,next_job]:
  task.retire()
  while not task.completed(): await process_frame
  task.join()
 checks["retained_old_view"] = saved == before and view.snapshot() == retained_before
 cases.append({"name":"concurrent_400_plus","buildings":city.buildings.size(),"capture_ms":capture_ms})
func _run() -> void:
 for family in ValleyTerrain.family_ids(): await _pair(family)
 for late in ["retune","flow","cancel"]: await _pair("river_valley",late)
 await _isolation()
 var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"cases":cases,"max_pcm_error":max_pcm_error}
 FileAccess.open("res://验证记录/连续河谷/第132轮_冻结捕获等价.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
 print("FROZEN_CAPTURE ",JSON.stringify(result))
 quit(0 if result["passed"] else 1)
