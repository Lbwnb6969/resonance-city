extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
var checks: Dictionary = {}
var cases := 0
var fleet_samples := 0
var query_old_us := 0
var query_new_us := 0
var fleet_old_us := 0
var fleet_new_us := 0

func _initialize() -> void: call_deferred("_run")

func _reference(world: ContinuousWorld) -> RefCounted:
	var script := GDScript.new()
	script.source_code = FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第123轮交通查询前/city_road_network.gd.txt").replace("class_name CityRoadNetwork","")
	assert(script.reload() == OK)
	var network := RefCounted.new()
	network.set_script(script)
	network.rebuild(world.nodes,world.roads.duplicate(true),world.terrain)
	return network

func _queries(world: ContinuousWorld, label: String) -> void:
	var reference := _reference(world)
	var equal := true
	var position_cache_before := world.network.access_cache.size()
	var points: Array[Vector2] = []
	for i in range(130):
		points.append(Vector2(-3.0+float((i*71)%397)/10.0,-3.0+float((i*47)%397)/10.0))
	for road in world.roads:
		var path: PackedVector2Array = road["path"]
		for p in [path[0],path[path.size()/2],path[-1]]:
			for offset in [Vector2.ZERO,Vector2(0.07,-0.09),Vector2(-0.3,0.4)]:
				points.append(p+offset)
	for p in points:
		var started := Time.get_ticks_usec()
		var expected: Dictionary = reference.access(p,false)
		query_old_us += Time.get_ticks_usec()-started
		started = Time.get_ticks_usec()
		var actual := world.network.access(p,false)
		query_new_us += Time.get_ticks_usec()-started
		if actual != expected and equal: print("ACCESS_MISMATCH ",label," ",p," actual=",actual," expected=",expected)
		equal = equal and actual == expected
		cases += 1
	checks[label] = equal
	checks[label+"_no_position_cache"] = world.network.access_cache.size() == position_cache_before

func _fleet(reference: bool = false) -> Array:
	var result: Array = []
	var script := GDScript.new()
	if reference:
		script.source_code = FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第123轮交通查询前/city_traveler.gd.txt").replace("class_name CityTraveler","")
		assert(script.reload() == OK)
	for kind in ["bus","car","walker"]:
		for i in range(6 if kind == "bus" else (3 if kind == "car" else 10)):
			var traveler: RefCounted = CityTraveler.new(kind,i+8 if kind == "car" else i)
			if reference:
				traveler.set_script(script)
				traveler.kind = kind
				traveler.ordinal = i+8 if kind == "car" else i
			result.append(traveler)
	return result

func _step(world: ContinuousWorld,fleet: Array,seconds: float) -> Array:
	var traffic: Array = []
	var accesses: Array = []
	for traveler in fleet:
		var access: Dictionary = world.network.access(traveler.position,false) if traveler.initialized else {}
		accesses.append({"position":traveler.position,"topology":world.network.topology,"access":access})
		if not traveler.initialized: continue
		traffic.append({"kind":traveler.kind,"ordinal":traveler.ordinal,"position":traveler.position,"direction":traveler.direction,
			"road":str(access.get("road","")),"road_from":str(access.get("from","")),"road_to":str(access.get("to","")),
			"road_along":float(access.get("along",0.0)),"road_length":float(access.get("length",0.0)),"priority":traveler._priority()})
	var result: Array = []
	for i in range(fleet.size()): result.append(fleet[i].advance(world,seconds,traffic,accesses[i]))
	return result

func _run() -> void:
	for family in ["river_valley","lake_basin","forest_ridge","coastal_plain","highland_pass"]:
		var world := World.new("2026100900000062",true,family)
		world.build_expanded_town()
		_queries(world,family)
		# Rebuilding the same topology retains candidate sets.
		var count := world.network.mobile_candidates.size()
		world.network.rebuild(world.nodes,world.roads,world.terrain)
		checks[family+"_reuse"] = world.network.mobile_candidates.size() == count
		world.request({"kind":"bridge"},352800)
		world.settle(352800)
		checks[family+"_topology_clear"] = world.network.mobile_candidates.is_empty()
		_queries(world,family+"_bridge")
	var actual := World.new("2026100900000062")
	actual.build_expanded_town()
	actual.era = 5
	var reference := World.new("2026100900000062",false)
	reference.restore(actual.snapshot())
	reference.network.mobile_lookup_enabled = false
	var a := _fleet()
	var b := _fleet(true)
	var fleet_equal := true
	for step in range(1201):
		if step == 450:
			actual.request({"kind":"bridge"},352800)
			reference.request({"kind":"bridge"},352800)
			actual.settle(352800)
			reference.settle(352800)
			actual.era = 5
			reference.era = 5
		var started := Time.get_ticks_usec()
		var expected := _step(reference,b,step*0.1)
		fleet_old_us += Time.get_ticks_usec()-started
		started = Time.get_ticks_usec()
		var observed := _step(actual,a,step*0.1)
		fleet_new_us += Time.get_ticks_usec()-started
		if observed != expected and fleet_equal: print("FLEET_MISMATCH step=",step)
		fleet_equal = fleet_equal and observed == expected
		fleet_samples += a.size()
	checks["fleet_120_seconds"] = fleet_equal
	checks["flow_and_world"] = actual.snapshot() == reference.snapshot()
	checks["saved_journeys"] = a.map(func(t: RefCounted) -> Dictionary: return t.snapshot()) == b.map(func(t: RefCounted) -> Dictionary: return t.snapshot())
	var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"query_cases":cases,
		"query_old_ms":query_old_us/1000.0,"query_new_ms":query_new_us/1000.0,"fleet_samples":fleet_samples,
		"fleet_old_ms":fleet_old_us/1000.0,"fleet_new_ms":fleet_new_us/1000.0,"mobile_cells":actual.network.mobile_candidates.size()}
	FileAccess.open("res://验证记录/连续河谷/第123轮_交通查询.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("MOBILE_ACCESS ",JSON.stringify(result))
	quit(0 if result["passed"] else 1)
