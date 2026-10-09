extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)

func _run() -> void:
	var world := World.new("2026101000000104",true,"river_valley")
	world.build_starter("bright")
	_check(world.functional_zones.size() >= 2,"starter exposes at least two functional zones")
	var ids: Dictionary = {}
	var role_set: Dictionary = {}
	for zone in world.functional_zones:
		var zone_id := str(zone.get("id",""))
		ids[zone_id] = int(ids.get(zone_id,0))+1
		role_set[str(zone.get("role",""))] = true
		_check(not zone_id.is_empty(),"zone has stable id")
		_check(zone.get("community_ids",[]).size() > 0,"zone has communities")
		for cid in zone.get("community_ids",[]):
			_check(bool(world.communities.get(cid,{}).get("active",true)),"zone only points at active communities")
	_check(ids.values().all(func(value: int) -> bool: return value == 1),"zone ids are unique")
	_check(role_set.has("residential") or role_set.has("commercial"),"starter has a usage zone")
	var model := Model.new(world)
	var score: Dictionary = model.synth.score_snapshot()
	var rhythm_roles := false
	for part in score.get("rhythms",[]):
		if not part.get("zone_roles",[]).is_empty(): rhythm_roles = true
	_check(rhythm_roles,"rhythm nodes carry functional roles")
	var snapshot := world.snapshot()
	var restored: World = world.fork()
	_check(restored.functional_zones == world.functional_zones,"functional zones survive snapshot")
	_check(restored.snapshot().get("functional_zones",[]) == snapshot.get("functional_zones",[]),"snapshot stores functional zones")
	world.settle(1)
	_check(world.functional_zones.size() >= 1,"zones remain after phrase settle")
	var expanded := World.new("2026101000000105",true,"river_valley")
	expanded.build_expanded_town()
	var expanded_roles: Dictionary = {}
	for zone in expanded.functional_zones: expanded_roles[str(zone.get("role",""))] = true
	_check(expanded_roles.has("transit"),"expanded town exposes a transit zone")
	_check(expanded_roles.has("civic_green"),"expanded town exposes a civic green zone")
	print("FUNCTIONAL_ZONES ",JSON.stringify({"passed":failures.is_empty(),"zones":world.functional_zones,"expanded_roles":expanded_roles,"roles":role_set,"rhythms":score.get("rhythms",[]),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
