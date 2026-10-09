extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new("2026101000000069",true,"river_valley")
	world.build_expanded_town()
	world.era = 5
	var travelers: Array = []
	for i in range(6): travelers.append(Traveler.new("bus",i))
	for i in range(3): travelers.append(Traveler.new("car",i+8))
	var line_ids: Dictionary = {}
	var max_step := 0.0
	var max_gap := 0.0
	var previous: Dictionary = {}
	for step in range(1201):
		var seconds := float(step)*0.05
		for i in range(travelers.size()):
			var traveler: Traveler = travelers[i]
			var result := traveler.advance(world,seconds)
			check(not result.is_empty(),"traveler remains routed")
			if result.is_empty(): continue
			line_ids[traveler.line_index] = str(traveler._line(world).get("id",""))
			if previous.has(i): max_step = maxf(max_step,result["position"].distance_to(previous[i]))
			previous[i] = result["position"]
			var access := world.network.access(result["position"])
			if not access.is_empty():
				max_gap = maxf(max_gap,float(access["gap"]))
			check(not access.is_empty() and float(access["gap"]) <= 0.18,"traveler stays on a road")
	check(line_ids.values().has("terrace-line"),"a vehicle uses the terrace line")
	check(travelers.filter(func(t: CityTraveler) -> bool: return t.kind == "car" and t.initialized).size() == 3,"modern cars remain routed")
	check(max_step <= 0.15,"line assignment keeps continuous movement at modern car speed")
	print("EXPANDED_ROUTES ",JSON.stringify({"failures":failures,"line_ids":line_ids,"max_step":max_step,"max_gap":max_gap,"cars":travelers.filter(func(t: CityTraveler) -> bool: return t.kind == "car" and t.initialized).size()}))
	quit(0 if failures.is_empty() else 1)
