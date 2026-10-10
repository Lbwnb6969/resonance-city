extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
var checks: Dictionary = {}
func _initialize() -> void: call_deferred("_run")
func _plan_checks(city: ContinuousWorld,label: String) -> void:
	var ids: Dictionary = {}
	var unique := true
	for group in [city.roads,city.lots,city.blocks,city.centers,city.public_sites,city.green_corridors]:
		for item in group:
			if ids.has(str(item["id"])): unique = false
			ids[str(item["id"])] = true
	checks[label+"_unique_ids"] = unique
	var dry_roads := true
	for road in city.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road["path"]
		for i in range(path.size()-1):
			if not Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([path[i],path[i+1]]),city.terrain.water).is_empty(): dry_roads = false
	checks[label+"_no_unbridged_water_crossings"] = dry_roads
	for side: String in ["west","east"]:
		var route := city.network.route(side+"-1","reach-2-"+side+"-4")
		checks[label+"_"+side+"_reaches_connected"] = not route["path"].is_empty()
	checks[label+"_banks_still_separate"] = city.network.route("west-1","east-1")["path"].is_empty()
	var legal := true
	for building in city.buildings:
		if not city.SpatialPlanning.exclusion(city,city.building_polygon(WorldCoupling.position_of(building))).is_empty(): legal = false
	checks[label+"_all_buildings_legal"] = legal
	var copy := city.fork()
	checks[label+"_snapshot_restore_exact"] = copy.snapshot() == city.snapshot()
	checks[label+"_era_transport"] = city.vehicle_kind() == ("bus" if city.era == 5 else "carriage")
func _run() -> void:
	var original := World.new()
	original.build_expanded_town()
	var original_water := original.terrain.water.duplicate()
	var original_plan: Dictionary = original.snapshot()["plan"]
	for family in ValleyTerrain.family_ids():
		var city := World.new("2026100900000062",true,family)
		city.build_regional_town()
		_plan_checks(city,family)
		var old_snapshot := city.snapshot()
		city.build_regional_town()
		checks[family+"_repeat_has_no_duplicate_plan"] = old_snapshot == city.snapshot()
	var sample := World.regional_sample()
	_plan_checks(sample,"sample1511")
	checks["sample_1500"] = sample.buildings.size() >= 1500 and sample.phrase_index == 52
	checks["sample_8_lines"] = sample.transit_lines.size() == 8
	checks["old_template_unchanged"] = original.terrain.water == original_water and original.snapshot()["plan"] == original_plan and not original.cfg["terrain"].has("template_land_max_y")
	var job := WorldSettlementJobForTest(sample)
	job.join()
	var synchronous := sample.fork()
	synchronous.settle((sample.phrase_index+1)*int(sample.cfg["timing"]["phrase_frames"]))
	checks["worker_matches_synchronous"] = job.result.snapshot() == synchronous.snapshot()
	checks["old_sample_unchanged"] = sample.phrase_index == 52 and sample.buildings.size() == 1511
	var result := {"passed":checks.values().all(func(v: bool) -> bool: return v),"checks":checks,"worker_ms":job.worker_ms,"buildings":sample.buildings.size()}
	FileAccess.open("res://验证记录/连续河谷/第136轮_三河段合同.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("REGIONAL_CONTRACT ",JSON.stringify(result))
	quit(0 if result["passed"] else 1)
func WorldSettlementJobForTest(city: ContinuousWorld) -> RefCounted:
	var job = preload("res://scripts/world/world_settlement_job.gd").new()
	job.start(city,[],(city.phrase_index+1)*int(city.cfg["timing"]["phrase_frames"]))
	return job
