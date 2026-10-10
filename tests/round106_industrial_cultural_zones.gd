extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _run() -> void:
	var world := World.new("2026101000000108",true,"river_valley")
	world.build_expanded_town()
	var industrial_buildings := 0
	for building in world.buildings:
		if str(building.get("type","")) == "industrial":
			industrial_buildings += 1
	_check(industrial_buildings >= 4,"expanded town creates a real industrial building belt")
	var industrial_zone: Dictionary = {}
	var cultural_zone: Dictionary = {}
	for zone in world.functional_zones:
		var role := str(zone.get("role",""))
		if role == "industrial":
			industrial_zone = zone
		elif role == "cultural":
			cultural_zone = zone
	_check(not industrial_zone.is_empty(),"industrial functional zone is derived")
	_check(not cultural_zone.is_empty(),"cultural functional zone is derived")
	_check(industrial_zone.get("music_role","") == "workshop","industrial zone maps to workshop music")
	_check(cultural_zone.get("music_role","") == "choir","cultural zone maps to choir music")
	_check(industrial_zone.get("community_ids",[]).size() >= 2,"industrial zone spans multiple communities")
	_check(cultural_zone.get("site_ids",[]).size() >= 2,"cultural zone spans multiple civic sites")
	for cid in industrial_zone.get("community_ids",[]):
		_check(world.communities.has(str(cid)),"industrial zone community exists")
	for site_id in cultural_zone.get("site_ids",[]):
		var site_exists := false
		for site in world.public_sites:
			if str(site.get("id","")) == str(site_id):
				site_exists = true
				break
		_check(site_exists,"cultural zone site exists")
	var model := Model.new(world)
	var score: Dictionary = model.synth.score_snapshot()
	var score_has_new_role := false
	for part in score.get("rhythms",[]):
		for role in part.get("zone_roles",[]):
			if str(role) in ["workshop","choir"]:
				score_has_new_role = true
	for part in score.get("themes",[]):
		for role in part.get("zone_roles",[]):
			if str(role) in ["workshop","choir"]:
				score_has_new_role = true
	_check(score_has_new_role,"score metadata carries workshop or choir role")
	var snapshot := world.snapshot()
	var restored: World = world.fork()
	_check(restored.functional_zones == world.functional_zones,"industrial and cultural zones survive fork")
	_check(restored.snapshot().get("functional_zones",[]) == snapshot.get("functional_zones",[]),"snapshot stores new functional zones")
	var restored_industrial := 0
	for building in restored.buildings:
		if str(building.get("type","")) == "industrial":
			restored_industrial += 1
	_check(restored_industrial == industrial_buildings,"industrial buildings survive fork")
	print("INDUSTRIAL_CULTURAL_ZONES ",JSON.stringify({"passed":failures.is_empty(),"industrial_buildings":industrial_buildings,"industrial_zone":industrial_zone,"cultural_zone":cultural_zone,"score":score,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
