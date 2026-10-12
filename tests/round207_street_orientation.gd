extends SceneTree
## Real road projections and committed public entrances determine four facades.
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
const Orientation = preload("res://scripts/visual/building_street_orientation.gd")
const FACING := [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]
const OUTPUT := "res://验证记录/round207_临街朝向/orientation_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_audio_only")
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var before := city.snapshot()
	var starter: Array = []
	var all_toward_street := city.buildings.size() == 24
	var repeated := true
	var banks: Dictionary = {}
	for building: Dictionary in city.buildings:
		var raw: Array = building["position"]
		var at := Vector2(float(raw[0]),float(raw[1]))
		var result := Orientation.street_orientation(city,at)
		var street := Fabric.nearest_road(city,at)
		var to_road: Vector2 = street["position"]-at
		all_toward_street = all_toward_street and result >= 0 and result < 4 and FACING[result].dot(to_road) > 0.0
		repeated = repeated and result == Orientation.street_orientation(city,at)
		banks[int(city.communities[str(building["community_id"])]["bank"])] = true
		starter.append({"id":building["district_id"],"position":at,"orientation":result,"road":street["road"],"toward_road":to_road})
	check(all_toward_street and banks.size() == 2,"all_24_real_starter_facades_face_their_street_on_both_banks")
	check(repeated,"same_actual_position_repeats_the_same_orientation")
	check(city.snapshot() == before,"all_starter_queries_preserve_world_save_and_rng_state")
	# Use legal empty land beside actual generated main and branch roads. Both
	# sides of these axes exercise every baked direction without made-up roads.
	var empty := World.new("2026100900000062",true,"river_valley")
	before = empty.snapshot()
	var directions: Dictionary = {}
	for segment: Dictionary in empty.road_segments.values():
		if bool(segment["road"].get("bridge",false)): continue
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		var tangent := (b-a).normalized()
		if absf(tangent.x) > 0.2 and absf(tangent.y) > 0.2: continue
		var entry := (a+b)*0.5
		for side: float in [-1.0,1.0]:
			var normal := Vector2(-tangent.y,tangent.x)*side
			var at := entry-normal*1.15
			if not bool(empty.placement(at).get("allowed",false)): continue
			var bank := -1 if at.x < empty.terrain.river_x(at.y) else 1
			var expected := (1 if normal.x > 0.0 else 3) if absf(normal.x) > absf(normal.y) else (2 if normal.y > 0.0 else 0)
			var key := "%d:%d" % [bank,expected]
			if directions.has(key): continue
			var result := Orientation.street_orientation(empty,at,entry)
			if result == expected: directions[key] = {"position":at,"entrance":entry,"road":segment["road"]["id"],"orientation":result}
	var all_four := true
	for bank: int in [-1,1]:
		for direction in range(4): all_four = all_four and directions.has("%d:%d" % [bank,direction])
	check(all_four,"four_real_road_facing_directions_are_available_on_each_bank")
	var road_axis_wins := false
	for segment: Dictionary in empty.road_segments.values():
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		if absf(a.y-b.y) > 0.00001 or a.distance_to(b) < 4.0: continue
		var at := a.lerp(b,0.3)+Vector2(0,1.15)
		var distant_entrance := a.lerp(b,0.85)
		if not bool(empty.placement(at).get("allowed",false)): continue
		var aim := distant_entrance-at
		road_axis_wins = absf(aim.x) > absf(aim.y) and Orientation.street_orientation(empty,at,distant_entrance) == 0
		if road_axis_wins: break
	check(road_axis_wins,"street_axis_takes_priority_over_a_distant_entrance_diagonal")
	check(empty.snapshot() == before,"empty_land_road_queries_are_read_only")
	var public_candidate: Dictionary = First.opportunities(city)["public_candidates"][0]
	var frame := int(city.cfg["timing"]["phrase_frames"])
	var request := city.request({"kind":"civic","position":public_candidate["position"]},frame)
	city.settle(frame)
	var site: Dictionary = {}
	for candidate: Dictionary in city.public_sites:
		if bool(candidate.get("player_planned",false)) and bool(candidate.get("active",false)): site = candidate
	check(bool(request.get("accepted",false)) and not site.is_empty() and site.has("road_id") and site.has("entrance"),"fixture_is_a_real_committed_public_road_entrance")
	var raw: Array = site["position"]
	var at := Vector2(float(raw[0]),float(raw[1]))
	raw = site["entrance"]
	var entry := Vector2(float(raw[0]),float(raw[1]))
	before = city.snapshot()
	var public_orientation := Orientation.street_orientation(city,at,entry)
	check(public_orientation == Orientation.street_orientation(city,at) and FACING[public_orientation].dot(entry-at) > 0.0,"public_facade_uses_the_actual_committed_entrance")
	check(city.snapshot() == before,"public_entrance_orientation_does_not_change_world")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"starter":starter,"bank_directions":directions,
		"public":{"position":at,"entrance":entry,"road":site["road_id"],"orientation":public_orientation},
		"scope":"Dummy real World road geometry, legal empty land on both banks and a genuinely committed civic entrance. Four baked facades use street normals and entrance side, keep the real footprint and leave World/save/RNG unchanged. No rendering, audio-device or aesthetic approval claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND207_STREET_ORIENTATION ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
