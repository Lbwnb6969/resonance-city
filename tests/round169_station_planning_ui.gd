extends SceneTree
## Round 169: a shared station can hand its real community catchment into the
## ordinary P planning guide without bypassing charter/card/anchor contracts.

const DemoScene = preload("res://scenes/continuous_valley.tscn")
const TransitPlanning = preload("res://scripts/world/transit_planning.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _road_candidates(demo: Control) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var seen: Array[String] = []
	for road in demo.shown_world.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road.get("path",PackedVector2Array())
		if path.size() < 2: continue
		var stop := TransitPlanning.stop_preview(demo.model.world,path[path.size()/2])
		if not bool(stop.get("accepted",false)): continue
		var id := str(stop.get("id",""))
		if id.is_empty() or seen.has(id): continue
		seen.append(id)
		result.append(Vector2(float(stop["position"][0]),float(stop["position"][1])))
	return result

func _find_route(demo: Control,candidates: Array[Vector2]) -> Array:
	for i in range(candidates.size()):
		for j in range(i+1,candidates.size()):
			for k in range(j+1,candidates.size()):
				var route := [candidates[i],candidates[j],candidates[k]]
				if bool(TransitPlanning.preview(demo.model.world,route).get("accepted",false)): return route
	return []

func _find_second_route(demo: Control,anchor: Vector2,candidates: Array[Vector2]) -> Array:
	for i in range(candidates.size()):
		if candidates[i].distance_to(anchor) <= 0.18: continue
		for j in range(i+1,candidates.size()):
			if candidates[j].distance_to(anchor) <= 0.18: continue
			var route := [anchor,candidates[i],candidates[j]]
			if bool(TransitPlanning.preview(demo.model.world,route).get("accepted",false)): return route
	return []

func _append_route(demo: Control,route: Array) -> void:
	for position in route: demo._append_transit_stop(position)

func _settle_pending(demo: Control) -> bool:
	for operation in demo.model.world.pending_actions:
		if str(operation.get("kind","")) != "transit_line": continue
		demo.model.world.settle(int(operation.get("frame",-1)))
		demo.shown_world = demo.model.world
		return true
	return false

func _find_station_with_scope(demo: Control,route: Array) -> Dictionary:
	for position in route:
		var station: Dictionary = demo._transit_station_at(position)
		if station.is_empty(): continue
		var record: Dictionary = station.get("record",{})
		if not record.get("community_ids",[]).is_empty(): return station
	return {}

func _center_for_community(world: RefCounted,cid: String) -> Vector2:
	for center in world.centers:
		if str(center.get("community_id",center.get("id",""))) == cid:
			var raw: Variant = center.get("position",[])
			if raw is Vector2: return raw
			if raw is Array and raw.size() == 2: return Vector2(float(raw[0]),float(raw[1]))
	return Vector2.INF

func _run() -> void:
	var demo: Control = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)

	var candidates := _road_candidates(demo)
	var first_route: Array = _find_route(demo,candidates)
	check(first_route.size() == 3,"finds_first_authored_route")
	if first_route.size() != 3:
		quit(1)
		return
	demo._verb("plan_transit")
	_append_route(demo,first_route)
	demo._submit_transit_route()
	check(_settle_pending(demo),"first_line_settles")

	var second_route: Array = _find_second_route(demo,first_route[1],candidates)
	check(second_route.size() == 3,"finds_second_route")
	if second_route.size() != 3:
		quit(1)
		return
	demo._verb("plan_transit")
	_append_route(demo,second_route)
	demo._submit_transit_route()
	check(_settle_pending(demo),"second_line_settles")

	var station := _find_station_with_scope(demo,second_route)
	var record: Dictionary = station.get("record",{})
	var station_scope: Array = record.get("community_ids",[]).duplicate()
	check(not station.is_empty(),"finds_station_with_covered_communities")
	check(not station_scope.is_empty(),"station_exposes_community_scope")
	if station.is_empty() or station_scope.is_empty():
		demo.queue_free()
		await process_frame
		quit(1)
		return

	var click := InputEventMouseButton.new()
	click.position = demo.point(station["position"])
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	demo._gui_input(click)
	check(str(demo.context.get("kind","")) == "transit_station","station_click_keeps_station_context")
	check(demo.menu_info.text.contains("P规划社区") and demo.menu_info.text.contains("覆盖范围"),"station_context_explains_growth_to_planning")
	demo._verb("planning")
	check(demo.planning_guide.opened,"station_planning_opens_guide")
	check(demo.planning_guide.stage == "charter","station_planning_keeps_charter_stage")
	check(demo.planning_guide.scope_source.get("station_id","") == str(station.get("id","")),"planning_source_keeps_station_id")
	check(demo.planning_guide.scope_seed == station_scope,"planning_seed_matches_authoritative_communities")

	demo.planning_guide.choose_plan("corridor")
	check(demo.planning_guide.stage == "card","charter_step_remains_in_contract")
	check(demo.planning_guide.scope == station_scope,"scope_seed_survives_charter_choice")
	var card_id: String = str(demo.planning_guide.card_id)
	demo.planning_guide.choose_card(card_id)
	check(demo.planning_guide.stage == "scope","change_card_step_remains_in_contract")
	check(demo.planning_guide.scope == station_scope,"scope_prefills_at_editable_stage")
	check(demo.planning_guide.detail.text.contains("Shift点击继续多选"),"scope_detail_explains_editable_multiselect")

	# Replace/add with ordinary map clicks to prove the seed is a suggestion,
	# while the existing scope editing semantics remain unchanged.
	var alternate_ids: Array[String] = []
	for center in demo.model.world.centers:
		var cid := str(center.get("community_id",center.get("id","")))
		if cid.is_empty() or alternate_ids.has(cid) or station_scope.has(cid): continue
		alternate_ids.append(cid)
		if alternate_ids.size() >= 2: break
	if not alternate_ids.is_empty():
		var first_position := _center_for_community(demo.model.world,alternate_ids[0])
		if first_position != Vector2.INF:
			demo.planning_guide.map_click(first_position,false)
			check(demo.planning_guide.scope == [alternate_ids[0]],"scope_click_can_replace_station_seed")
		if alternate_ids.size() > 1:
			var second_position := _center_for_community(demo.model.world,alternate_ids[1])
			if second_position != Vector2.INF:
				demo.planning_guide.map_click(second_position,true)
				check(demo.planning_guide.scope.has(alternate_ids[0]) and demo.planning_guide.scope.has(alternate_ids[1]),"scope_shift_click_keeps_multiselect")

	# Restore the station suggestion and submit through the same charter request.
	demo.planning_guide.choose_card(card_id)
	check(demo.planning_guide.scope == station_scope,"scope_can_restore_station_seed_before_submit")
	demo.planning_guide.commit_scope()
	var charter_pending: Dictionary = {}
	for operation in demo.model.world.pending_actions:
		if str(operation.get("kind","")) == "charter": charter_pending = operation
	check(not charter_pending.is_empty(),"station_scope_submits_existing_charter_operation")
	check(charter_pending.get("community_ids",[]) == station_scope,"submitted_charter_uses_selected_scope")
	check(not charter_pending.has("scope_source"),"submitted_charter_keeps_transient_source_out_of_world")

	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"station_id":str(station.get("id","")),"station_scope":station_scope}
	print("ROUND169_STATION_PLANNING_UI ",JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
