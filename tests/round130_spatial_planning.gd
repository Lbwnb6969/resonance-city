extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
var checks: Dictionary = {}
var growth: Array = []

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)
func _position(item: Dictionary) -> Vector2:
	var raw: Array = item["position"]
	return Vector2(float(raw[0]),float(raw[1]))
func _pick(world: ContinuousWorld) -> Dictionary:
	for lot in world.lots:
		if not str(lot["occupant"]).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var site := world.planning_candidate(p)
		if site.is_empty() or not bool(site["allowed"]) or site.has("reservation_id") or site.has("public_id"): continue
		if not Planning.public_access(world,site).is_empty(): return site
	return {}

func _spatial_cases() -> void:
	var city := World.new()
	var site := _pick(city)
	var p := _position(site)
	var frame: int = city.cfg["timing"]["phrase_frames"]
	city.request({"kind":"seed","position":[p.x,p.y],"midi":48},frame)
	city.request({"kind":"reserve","position":[p.x,p.y]},frame)
	city.settle(frame)
	_check(city.buildings.is_empty() and city.planning_reservations.size() == 1,"reservation_filters_same_phrase_seed")
	city.request({"kind":"release_reservation","id":city.planning_reservations[0]["reservation_id"]},frame*2)
	city.settle(frame*2)
	city.request({"kind":"reserve","position":[p.x,p.y]},frame*3)
	city.request({"kind":"park","position":[p.x,p.y]},frame*3)
	_check(city.pending_actions.size() == 1 and city.pending_actions[0]["kind"] == "park","planning_intent_replaces_previous")
	# Full polygon validation catches a house even when its center is outside the candidate.
	var radius := float(city.cfg["space"]["residential_radius"])
	var box := Planning.bounds(site["polygon"])
	_check(Planning.disc_hits(site["polygon"],Vector2(box.end.x+radius*0.5,p.y),radius),"polygon_disc_edge_overlap")
	# Terrain grade is tested against a controlled slope, not a fabricated map flag.
	var terrain_script := GDScript.new()
	terrain_script.source_code = "extends \"res://scripts/world/valley_terrain.gd\"\nfunc height_at(point: Vector2) -> float:\n\treturn point.x*0.8\n"
	_check(terrain_script.reload() == OK,"steep_terrain_fixture")
	var steep: ValleyTerrain = terrain_script.new()
	steep.configure(1,0.0)
	_check(steep.building_footprint_reason(city.building_polygon(Vector2(4,4))).contains("太陡"),"steep_footprint_rejected")
	var y := 4.0
	var shore_x: float = city.terrain.river_x(y)-city.terrain.river_width(y)
	var shore_polygon := NeighborhoodPlan.box(Vector2(shore_x-0.08,y),Vector2(0.03,0.03))
	_check(city.terrain.valid_footprint(shore_polygon) and city.terrain.building_footprint_reason(shore_polygon).contains("缓冲"),"dry_shore_buffer_rejected")
	city.landmarks.append({"id":"test-landmark","position":[p.x,p.y],"radius":1.0})
	_check(not bool(city.placement(p+Vector2(1.1,0))["allowed"]),"landmark_whole_footprint_protected")
	city.landmarks.clear()
	# Revalidate against current geometry, rejecting the whole action if its footprint changed.
	var op := city.pending_actions[0].duplicate(true)
	for lot in city.lots:
		if str(lot["id"]) == str(op["source_site_id"]):
			lot["polygon"] = NeighborhoodPlan.box(p,Vector2(0.55,0.55))
	city._refresh_parcel_index()
	city.settle(frame*3)
	_check(city.public_at(p).is_empty() and city.events.any(func(event:Dictionary)->bool:return event["kind"] == "planning_rejected"),"changed_geometry_rejects_entire_action")

func _run() -> void:
	_spatial_cases()
	for family in ValleyTerrain.family_ids():
		var city := World.new("2026100900000062",true,family)
		city.expand_plan()
		city.build_starter("bright")
		var site := _pick(city)
		var inactive_legal := 0
		for public_site in city.public_sites:
			if bool(public_site["active"]): continue
			var public_candidate := city.planning_candidate(_position(public_site))
			if not public_candidate.is_empty() and bool(public_candidate["allowed"]): inactive_legal += 1
		_check(inactive_legal > 0,family+"_authored_public_candidates_remain")
		_check(not site.is_empty(),family+"_player_location")
		if site.is_empty(): continue
		var p := _position(site)
		var phrase: int = city.cfg["timing"]["phrase_frames"]
		var prior := city.buildings.size()
		_check(bool(city.request({"kind":"reserve","position":[p.x,p.y]},phrase)["accepted"]),family+"_reserve_accepted")
		city.settle(phrase)
		var id := str(city.planning_reservations[0]["reservation_id"])
		_check(not bool(city.placement(p)["allowed"]),family+"_seed_blocked")
		var box := Planning.bounds(site["polygon"])
		var outside := Vector2(box.end.x+0.2,box.get_center().y)
		_check(not bool(city.placement(outside)["allowed"]),family+"_whole_footprint_excluded")
		var restored := World.new(city.rng.seed_hex,false)
		restored.restore(city.snapshot())
		_check(restored.planning_reservations == city.planning_reservations and not bool(restored.placement(p)["allowed"]),family+"_snapshot_roundtrip")
		var old := city.snapshot()
		old.erase("planning_reservations")
		var legacy := World.new(city.rng.seed_hex,false)
		legacy.restore(old)
		_check(legacy.planning_reservations.is_empty(),family+"_old_snapshot")
		for step in range(6):
			city.settle((city.phrase_index+1)*phrase)
		var no_intrusion := true
		var compact := 0
		for i in range(prior,city.buildings.size()):
			var building: Dictionary = city.buildings[i]
			var bp := WorldCoupling.position_of(building)
			if not Planning.exclusion(city,city.building_polygon(bp)).is_empty(): no_intrusion = false
			var neighbors := 0
			for other_id in city.index.query_circle(bp,1.35):
				if other_id == str(building["district_id"]): continue
				if bp.distance_to(WorldCoupling.position_of(city.by_id[other_id])) <= 1.8: neighbors += 1
			if neighbors >= 2: compact += 1
		_check(no_intrusion and city.buildings.size()>prior,family+"_growth_respects_spaces")
		growth.append({"family":family,"before":prior,"after":city.buildings.size(),"new_with_two_neighbors":compact})
		var polygon: PackedVector2Array = city.planning_reservations[0]["polygon"].duplicate()
		var request := city.request({"kind":"civic","position":[p.x,p.y]},(city.phrase_index+1)*phrase)
		_check(bool(request["accepted"]),family+"_convert_accepted")
		city.settle((city.phrase_index+1)*phrase)
		var facility := city.public_at(p)
		_check(city.planning_reservations.is_empty() and not facility.is_empty() and bool(facility.get("player_planned",false)) and facility["polygon"] == polygon,family+"_explicit_full_conversion")
		_check(not facility.is_empty() and not city.network.access(Vector2(facility["entrance"][0],facility["entrance"][1])).is_empty(),family+"_real_entrance")
		_check(city.events.any(func(event: Dictionary)->bool:return event.get("converted_reservation","") == id),family+"_conversion_replay_identity")
		var greens_blocked := true
		for corridor in city.green_corridors:
			var path: PackedVector2Array = corridor["path"]
			var gp := path[path.size()/2]
			greens_blocked = greens_blocked and not bool(city.placement(gp)["allowed"])
		_check(greens_blocked,family+"_greenways")
		# A legal player-selected house outside a street remains an available expression.
		var isolated := false
		for y in range(0,35,2):
			for x in range(0,35,2):
				var check := city.placement(Vector2(x,y))
				if bool(check["allowed"]) and str(check["tier"]) == "L3": isolated = true; break
			if isolated: break
		_check(isolated,family+"_legal_solo_house")
	# Reservation carries no voice, acoustic occlusion or direct R/V reward.
	var city := World.new()
	city.build_starter("bright")
	for item in city.families.values(): item["next_growth_phrase"] = 1000
	var base := city.fork()
	var model := Model.new(city,1.3409036)
	var baseline := Model.new(base,1.3409036)
	var site := _pick(city)
	var p := _position(site)
	var before_rng := city.rng.snapshot()
	var boundary := model.next_boundary
	_check(bool(model.submit({"kind":"reserve","position":[p.x,p.y]})["accepted"]),"queued_reservation")
	var old_count := city.planning_reservations.size()
	_check(old_count == 0,"pending_is_not_truth")
	model.cancel_pending()
	_check(city.planning_reservations.is_empty() and city.rng.snapshot() == before_rng,"cancel_does_not_commit_or_draw_rng")
	model.submit({"kind":"reserve","position":[p.x,p.y]})
	model.enable_background_settlement()
	model.prepare_settlement(boundary-22050,22050)
	while not model.settlement_job.completed(): await process_frame
	model.prepare_settlement(boundary-22050,22050)
	var state: Dictionary = {}
	var other_state: Dictionary = {}
	var a := model.render_block(state,boundary-128,256,22050)
	var b := baseline.render_block(other_state,boundary-128,256,22050)
	var error := 0.0
	for i in range(a.size()): error = maxf(error,a[i].distance_to(b[i]))
	var resonance_error := absf(model.world.resonance-baseline.world.resonance)
	_check(error == 0.0 and resonance_error < 1e-9,"silent_reservation_pcm_and_resonance")
	_check(model.world.buildings == baseline.world.buildings,"reservation_no_vitality_reward")
	if model.world.buildings != baseline.world.buildings: print("RESERVATION_DIFF ",model.world.resonance,"/",baseline.world.resonance," ",JSON.stringify(model.world.buildings[0])," / ",JSON.stringify(baseline.world.buildings[0]))
	_check(model.settlement_stats["adopted"] == 1 and model.world.planning_reservations.size() == 1,"worker_commits_reservation")
	var saved := model.capture_state()
	_check(model.presentation_world(boundary-1).planning_reservations.is_empty(),"not_shown_before_audible")
	_check(model.presentation_world(boundary).planning_reservations.size() == 1,"shown_at_audible")
	var resumed := Model.from_state(saved)
	_check(resumed.world.planning_reservations == model.world.planning_reservations,"model_dna_roundtrip")
	var exported := CityArchive.export_dna({"model":saved,"renderer":{},"view":{}},"res://验证记录/连续河谷/第130轮_DNA")
	_check(bool(exported["ok"]),"json_dna_export")
	var imported := CityArchive.read_dna(exported["path"])
	var json_model := Model.from_state(imported["model"])
	var json_reservation: Dictionary = json_model.world.planning_reservations[0]
	var original: Dictionary = model.world.planning_reservations[0]
	_check(json_reservation["reservation_id"] == original["reservation_id"] and json_reservation["source_site_id"] == original["source_site_id"] and int(json_reservation["created_phrase"]) == int(original["created_phrase"]) and json_reservation["polygon"] == original["polygon"] and not bool(json_model.world.placement(p)["allowed"]),"json_dna_restores_typed_geometry")
	_check(json_model.presentation_world(boundary-1).planning_reservations.is_empty(),"json_dna_historical_geometry")
	json_model.close_background_settlement()
	model.world.request({"kind":"release_reservation","id":model.world.planning_reservations[0]["reservation_id"]},boundary*2)
	model.world.settle(boundary*2)
	_check(model.world.planning_reservations.is_empty() and bool(model.world.placement(p)["allowed"]),"release_restores_eligibility")
	model.close_background_settlement()
	baseline.close_background_settlement()
	resumed.close_background_settlement()
	var result := {"passed":checks.values().all(func(ok:bool)->bool:return ok),"checks":checks,"growth":growth,"max_pcm_error":error,"resonance_roundoff":resonance_error}
	FileAccess.open("res://验证记录/连续河谷/第130轮_空间规划.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("SPATIAL_PLANNING ",JSON.stringify(result))
	quit(0 if result["passed"] else 1)
