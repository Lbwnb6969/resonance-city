extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
var checks: Dictionary = {}
func _initialize() -> void:
	var world := World.new()
	world.build_starter("bright")
	var travelers: Array[CityTraveler] = []
	for i in range(2): travelers.append(CityTraveler.new("bus",i))
	for i in range(10): travelers.append(CityTraveler.new("walker",i))
	var previous: Dictionary = {}
	var max_step := {"bus":0.0,"walker":0.0}
	var max_bus_gap := 0.0
	var same_bank := true
	var finite_walk := true
	# Two minutes, including a bridge opening while both buses are mid-journey.
	for step in range(2401):
		var seconds := float(step)*0.05
		if step == 581:
			world.request({"kind":"bridge"},352800)
			world.settle(352800)
		for index in range(travelers.size()):
			var traveler := travelers[index]
			var result := traveler.advance(world,seconds)
			if result.is_empty():
				finite_walk = false
				continue
			var p: Vector2 = result["position"]
			if previous.has(index):
				var gap: float = p.distance_to(previous[index])
				max_step[traveler.kind] = maxf(max_step[traveler.kind],gap)
			previous[index] = p
			if traveler.kind == "bus":
				# Bridge surface is traversable even though it overlays water.
				var nearest := world.network.access(p)
				if not nearest.is_empty(): max_bus_gap = maxf(max_bus_gap,float(nearest["gap"]))
				if step < 581: same_bank = same_bank and world.terrain.land_at(p) and p.x < world.terrain.river_x(p.y)
	checks = {"no_teleport_bus":max_step["bus"] <= 0.091,"no_teleport_walker":max_step["walker"] <= 0.025,
		"bus_inside_road":max_bus_gap <= 0.18,"no_water_before_bridge":same_bank,"all_travelers_routed":finite_walk}
	var evidence := {"checks":checks,"samples":2401,"max_step":max_step,"max_bus_road_gap":max_bus_gap,"bridge_open_seconds":29.05}
	FileAccess.open("res://验证记录/连续河谷/第63轮_道路公交.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ROUTES ",JSON.stringify(evidence))
	quit(0 if checks.values().all(func(value: bool) -> bool: return value) else 1)
