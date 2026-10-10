extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
var failures: Array[String] = []

func _initialize() -> void:
	var world := World.new("2026101000000118")
	world.build_expanded_town()
	var before := world.fork()
	var before_resonance := world.resonance
	var model := Model.new(world)
	var at := model.next_boundary
	model.render_block({},at-128,256,int(world.cfg["timing"]["sample_rate"]))
	var shown := model.presentation_world(at-1)
	_check(shown.snapshot() == before.snapshot(),"before-audible snapshot unchanged")
	_check(shown.fabric_cache == before.fabric_cache,"courtyard and street geometry exact")
	_check(shown.edge_cache == before.edge_cache,"acoustic edges exact")
	_check(shown.public_service_cache == before.public_service_cache,"coverage and capacity exact")
	_check(shown.resonance == before_resonance,"source resonance preserved exactly")
	_check(shown.network.walking_distance(Vector2(8,8),Vector2(24,8)) == before.network.walking_distance(Vector2(8,8),Vector2(24,8)),"physical route exact")
	var saved := model.capture_state()
	_check(not saved["presentation_history"][0].has("derived"),"derived live cache omitted from DNA")
	var restored := Model.from_state(saved)
	_check(restored.presentation_world(at-1).snapshot() == before.snapshot(),"older history reconstructs before-audible city")
	_check(model.presentation_world(at) == world and model.presentation_copy == null,"exact audible frame releases old city")
	# A bridge must enter the physical graph before this phrase's growth queries.
	world.request({"kind":"bridge"},model.next_boundary)
	world.settle(model.next_boundary)
	_check(world.network.roads.all(func(road: Dictionary) -> bool: return road.has("length")),"bridge has physical length before growth")
	_check(is_finite(world.network.walking_distance(Vector2(world.nodes["west-2"][0],world.nodes["west-2"][1]),Vector2(world.nodes["east-2"][0],world.nodes["east-2"][1]))),"bridge walking graph connects banks")
	var evidence := {"passed":failures.is_empty(),"failures":failures}
	FileAccess.open("res://验证记录/连续河谷/第118轮_呈现缓存.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("PRESENTATION_CACHE ",JSON.stringify(evidence))
	quit(0 if failures.is_empty() else 1)

func _check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
