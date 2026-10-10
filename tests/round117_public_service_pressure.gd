extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool,label: String) -> void:
	if not condition: failures.append(label)

func _run() -> void:
	var world := World.new("2026101000000117",true,"river_valley")
	world.build_expanded_town()
	var summary := world.public_service_summary()
	var civic_count := world.public_sites.filter(func(site: Dictionary) -> bool: return bool(site["active"]) and site["kind"] == "civic").size()
	_check(int(summary["facilities"]) == civic_count,"count civic sites once across community catchments")
	_check(int(summary["covered"]) <= world.buildings.size(),"public coverage counts distinct houses")
	_check(int(summary["served"]) <= int(summary["reachable"]),"capacity cannot serve unreachable houses")
	_check(int(summary["served"]) <= int(summary["capacity"]),"capacity bounds cultural service")
	var served_ids: Dictionary = {}
	var chosen: Dictionary = {}
	for site in world.public_sites:
		if site["kind"] != "civic" or not site["active"]: continue
		_check(site["served"].size() <= int(site["service_capacity"]),"individual facility respects capacity")
		for id in site["served"]:
			_check(not served_ids.has(id),"overlapping cultural catchments never duplicate users")
			_check(site["covered"].has(id),"served users follow actual road coverage")
			served_ids[id] = true
		if chosen.is_empty() or int(site["service_demand"]) > int(chosen["service_demand"]): chosen = site
	_check(not chosen.is_empty(),"cultural facility is available to expand")
	# A town with only one commissioned cultural facility exposes real capacity
	# pressure; other public reserves remain available for later player planning.
	for site in world.public_sites:
		if site["kind"] == "civic": site["active"] = site["id"] == chosen["id"]
	world._refresh_public_network()
	summary = world.public_service_summary()
	_check(int(chosen["service_demand"]) > 18,"single commissioned facility is oversubscribed")
	_check(int(summary["served"]) < int(summary["reachable"]),"capacity pressure differs from road reachability")
	var model := Model.new(world)
	_check(model.synth.rhythms.all(func(part: Dictionary) -> bool: return part.has("service_pressure")),"service signal reaches rhythm metadata")
	var frame := int(world.cfg["timing"]["phrase_frames"])
	# Freeze family expansion so capacity improvement is measured at fixed demand.
	for family in world.families.values(): family["next_growth_phrase"] = 100
	var before := int(summary["served"])
	var accepted := world.request({"kind":"civic","id":chosen["id"]},frame)
	_check(bool(accepted["accepted"]),"active civic facility accepts expansion")
	_check(int(chosen.get("service_level",1)) == 1,"expansion waits for the phrase boundary")
	world.settle(frame)
	_check(int(chosen["service_level"]) == 2 and int(chosen["service_capacity"]) == 36,"expansion commits with doubled capacity")
	var after := world.public_service_summary()
	_check(int(after["served"]) >= before,"expanded capacity never reduces service")
	if int(chosen["service_demand"]) > 18:
		_check(int(after["served"]) > before,"oversubscribed facility serves more houses after expansion")
	var frame_two := frame*2
	_check(bool(world.request({"kind":"civic","id":chosen["id"]},frame_two)["accepted"]),"second expansion is playable")
	world.settle(frame_two)
	_check(int(chosen["service_level"]) == 3 and int(chosen["service_capacity"]) == 54,"third level commits")
	_check(not bool(world.request({"kind":"civic","id":chosen["id"]},frame*3)["accepted"]),"completed facility has a clear expansion limit")
	var restored: World = world.fork()
	_check(restored.public_service_summary() == world.public_service_summary(),"service allocation survives fork")
	_check(restored.functional_zones == world.functional_zones,"cultural quota fields survive fork")
	var legacy := world.snapshot()
	for site in legacy["public_sites"]:
		site.erase("service_level")
		site.erase("service_capacity")
		site.erase("served")
		site.erase("service_demand")
	restored.restore(legacy)
	_check(restored.public_service_summary()["capacity"] == 18,"old snapshots restore level one capacity")
	var west_node: Array = world.nodes["west-2"]
	var east_node: Array = world.nodes["east-2"]
	var west := Vector2(west_node[0],west_node[1])
	var east := Vector2(east_node[0],east_node[1])
	_check(is_inf(world.network.walking_distance(west,east)),"cached walking distance cannot cross an unbridged river")
	_check(bool(world.request({"kind":"bridge"},frame*3)["accepted"]),"bridge is accepted after service expansion")
	world.settle(frame*3)
	_check(is_finite(world.network.walking_distance(west,east)),"bridge topology invalidates disconnected distance cache")
	_check(is_equal_approx(world.network.walking_distance(west,east),world.network.walking_distance(east,west)),"physical walking distance remains symmetric")
	print("PUBLIC_SERVICE_PRESSURE ",JSON.stringify({"passed":failures.is_empty(),"before":summary,"after":world.public_service_summary(),"settle_profile":world.settle_profile,"expanded_site":chosen["id"],"demand":chosen["service_demand"],"failures":failures}))
	quit(0 if failures.is_empty() else 1)
