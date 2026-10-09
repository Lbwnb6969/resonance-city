extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
func _initialize() -> void:
	var world := World.new()
	world.build_starter("bright")
	var continuity := true
	var road_water := true
	for road in world.roads:
		if road["bridge"]: continue
		road_water = road_water and Geometry2D.intersect_polyline_with_polygon(road["path"],world.terrain.water).is_empty()
	for leg in world.transit["legs"]:
		var path: PackedVector2Array = leg["path"]
		continuity = continuity and path.size() >= 2 and absf(float(leg["length"])) > 0.001
	var samples := 0
	var on_road := 0
	for i in range(24):
		var bus := world.bus_position(float(i)*3.7)
		if bus.is_empty(): continue
		samples += 1
		on_road += 1 if not world.network.access(bus["position"]).is_empty() else 0
	var result := {"road_water_clear":road_water,"transit_legs":world.transit["legs"].size(),"continuous_legs":continuity,"bus_samples":samples,"bus_on_road":on_road}
	var file := FileAccess.open("res://验证记录/连续河谷/第63轮_道路公交.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")+"\n")
	file.close()
	print("ROUTES ",JSON.stringify(result))
	quit(0 if road_water and continuity and samples == on_road and samples >= 20 else 1)
