extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool,label: String) -> void:
	if not condition: failures.append(label)

func _count_type(world: ContinuousWorld,kind: String) -> int:
	var count := 0
	for building in world.buildings:
		if str(building.get("type","")) == kind: count += 1
	return count

func _run() -> void:
	var world := World.new("2026101000000115",true,"river_valley")
	world.build_expanded_town()
	var initial_industrial := _count_type(world,"industrial")
	var initial_residential := _count_type(world,"residential")
	_check(initial_industrial >= 4,"expanded town starts with industrial anchors")
	for phrase in range(72):
		world.settle((phrase+1)*int(world.cfg["timing"]["phrase_frames"]))
	var final_industrial := _count_type(world,"industrial")
	var final_residential := _count_type(world,"residential")
	var industrial_communities := 0
	for cid in world.communities:
		var quota: Dictionary = world.community_land_use_quota(str(cid))
		var usage: Dictionary = world._community_usage(str(cid))
		if int(quota.get("industrial",0)) > 0:
			industrial_communities += 1
			_check(int(usage.get("industrial",0)) <= int(quota.get("industrial",0)) or int(usage.get("industrial",0)) >= initial_industrial,"industrial usage stays bounded or grows from anchor budget")
	_check(final_industrial > initial_industrial,"long growth fills industrial quota instead of freezing at authored anchors")
	_check(final_residential > initial_residential,"residential growth continues alongside industrial quota")
	_check(not world.functional_zones.filter(func(zone: Dictionary) -> bool: return str(zone.get("role","")) == "industrial").is_empty(),"industrial functional zone remains derived")
	print("LAND_USE_QUOTA ",JSON.stringify({"passed":failures.is_empty(),"initial_industrial":initial_industrial,"final_industrial":final_industrial,"initial_residential":initial_residential,"final_residential":final_residential,"industrial_communities":industrial_communities,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
