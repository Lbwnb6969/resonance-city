extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
var checks: Dictionary = {}
var timings: Array = []
var reference_script: GDScript
var max_pcm_error := 0.0

func _initialize() -> void: call_deferred("_run")

func _reference() -> GDScript:
	var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第127轮快照索引前/continuous_world.gd.txt")
	var script := GDScript.new()
	script.source_code = "extends \"res://scripts/world/continuous_world.gd\"\nfunc restore"+source.get_slice("func restore",1).get_slice("func fork",0)
	assert(script.reload() == OK)
	return script

func _compare(saved: Dictionary,name: String,rebuild: bool) -> ContinuousWorld:
	var current := World.new(saved["seed_hex"],false)
	var original: ContinuousWorld = reference_script.new(saved["seed_hex"],false)
	var started := Time.get_ticks_usec()
	original.restore(saved,rebuild)
	var old_ms := float(Time.get_ticks_usec()-started)/1000.0
	started = Time.get_ticks_usec()
	current.restore(saved,rebuild)
	var new_ms := float(Time.get_ticks_usec()-started)/1000.0
	checks[name+"_snapshot"] = current.snapshot() == original.snapshot()
	checks[name+"_derived"] = current.fabric_cache == original.fabric_cache and current.edge_cache == original.edge_cache and current.public_service_cache == original.public_service_cache and current.resonance == original.resonance
	checks[name+"_physical_graph"] = current.network.topology == original.network.topology and current.network.roads == original.network.roads
	checks[name+"_identity_lookup"] = current.by_id == original.by_id
	timings.append({"name":name,"buildings":current.buildings.size(),"lots":current.lots.size(),"reference_ms":old_ms,"indexed_ms":new_ms})
	return current

func _run() -> void:
	reference_script = _reference()
	for family in ValleyTerrain.family_ids():
		var city := World.new("2026100900000062",true,family)
		city.build_starter("bright")
		city.request({"kind":"bridge"},int(city.cfg["timing"]["phrase_frames"]))
		city.settle(int(city.cfg["timing"]["phrase_frames"]))
		var saved := city.snapshot()
		var before := saved.duplicate(true)
		_compare(saved,family,true)
		_compare(saved,family+"_no_derived",false)
		checks[family+"_source_isolation"] = saved == before
	# Multiple lots with the same ID must all be updated; later buildings and
	# landmarks retain their original overwrite order, including empty IDs.
	var contested := World.new()
	contested.build_starter("bright")
	var duplicate := contested.snapshot()
	duplicate["plan"]["lots"].append(duplicate["plan"]["lots"][0].duplicate(true))
	var member: Dictionary = duplicate["buildings"][0].duplicate(true)
	member["district_id"] = "restore-duplicate"
	member["lot_id"] = duplicate["buildings"][0]["lot_id"]
	duplicate["buildings"].append(member)
	duplicate["landmarks"] = [{"id":"landmark-a"},{"id":""},{"id":"landmark-b"},{"id":"landmark-b"}]
	duplicate["plan"]["lots"][0]["landmark_id"] = "landmark-b"
	_compare(duplicate,"duplicate_occupants",false)
	# A legally grown city exercises the path used by worker, old audible view,
	# and DNA. Large scale here is real planning, without overlapping replicas.
	var grown := World.new()
	grown.build_expanded_town()
	var phrase := int(grown.cfg["timing"]["phrase_frames"])
	for i in range(1,72): grown.settle(i*phrase)
	var saved := grown.snapshot()
	_compare(saved,"legal_607",false)
	var model := Model.new(grown,1.3409036)
	var at := model.next_boundary
	var before := grown.snapshot()
	var fabric := grown.fabric_cache.duplicate(true)
	var edges := grown.edge_cache.duplicate(true)
	var service := grown.public_service_cache.duplicate(true)
	var state: Dictionary = {}
	model.render_block(state,at-128,256,22050)
	var shown := model.presentation_world(at-1)
	checks["audible_old_city"] = shown.snapshot() == before and shown.fabric_cache == fabric and shown.edge_cache == edges and shown.public_service_cache == service
	var captured := model.capture_state()
	var resumed := Model.from_state(captured)
	checks["dna_old_city"] = resumed.presentation_world(at-1).snapshot() == before
	var resumed_state := state.duplicate(true)
	var continued := model.render_block(state,at+128,512,22050)
	var playback := resumed.render_block(resumed_state,at+128,512,22050)
	for i in range(continued.size()): max_pcm_error = maxf(max_pcm_error,continued[i].distance_to(playback[i]))
	checks["dna_pcm"] = max_pcm_error == 0.0 and state == resumed_state
	checks["exact_reveal"] = model.presentation_world(at) == grown and model.presentation_copy == null
	var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"timings":timings,"max_pcm_error":max_pcm_error}
	FileAccess.open("res://验证记录/连续河谷/第127轮_快照索引等价.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("RESTORE_INDEX ",JSON.stringify(result))
	quit(0 if result["passed"] else 1)
