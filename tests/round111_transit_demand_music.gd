extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool,label: String) -> void:
	if not condition:
		failures.append(label)

func _run() -> void:
	var world := World.new("2026101000000117",true,"river_valley")
	world.build_expanded_town()
	var base_zone: Dictionary = {}
	for candidate in world.functional_zones:
		if str(candidate.get("role","")) == "transit":
			base_zone = candidate
			break
	var cid := str(base_zone.get("community_ids",["west-2"])[0])
	var stop := str(world.center_for(cid).get("node_id","west-2"))
	var line: Dictionary = world.transit_lines[0]
	for candidate in world.transit_lines:
		if candidate.get("stops",[]).has(stop):
			line = candidate
			break
	var traveler := Traveler.new("bus",0)
	var before := traveler._stop_demand(world,line,stop)
	for index in range(8):
		world.record_transit_flow(stop,6,4,2)
	var after := traveler._stop_demand(world,line,stop)
	world.refresh_functional_zones()
	var transit_zone: Dictionary = {}
	for zone in world.functional_zones:
		if str(zone.get("role","")) == "transit":
			transit_zone = zone
			break
	_check(world.transit_demand_score(stop) > 0.0,"station flow creates a demand memory")
	_check(after > before,"remembered demand raises later stop demand")
	_check(not transit_zone.is_empty(),"expanded city exposes a transit functional zone")
	_check(float(transit_zone.get("transit_demand",0.0)) > 0.0,"transit zone carries station demand")
	_check(str(transit_zone.get("music_role","")) == "pulse_dense","busy transfer demand changes the rhythm role")
	var forked: World = world.fork()
	_check(is_equal_approx(forked.transit_demand_score(stop),world.transit_demand_score(stop)),"station demand survives world fork")
	_check(forked.functional_zones == world.functional_zones,"demand-derived functional zone survives fork")
	print("TRANSIT_DEMAND ",JSON.stringify({"passed":failures.is_empty(),"stop":stop,"before":before,"after":after,"score":world.transit_demand_score(stop),"music_role":transit_zone.get("music_role",""),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
