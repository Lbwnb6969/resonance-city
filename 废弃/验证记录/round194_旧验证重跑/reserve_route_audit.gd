extends SceneTree

const Planning = preload("res://scripts/world/city_spatial_planning.gd")
var demo: Control
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _run() -> void:
	demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var guide = demo.planning_guide
	guide.open_tool()
	guide.choose_plan("compact")
	guide.choose_card("infill_pulse")
	var site: Dictionary = {}
	for lot in demo.model.world.lots:
		if not str(lot.get("occupant","")).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var candidate: Dictionary = demo.model.world.planning_candidate(p)
		if candidate.is_empty() or not bool(candidate.get("allowed",false)): continue
		if candidate.has("reservation_id") or candidate.has("public_id"): continue
		site = candidate
		break
	check(not site.is_empty(),"real_first_reserve_candidate")
	if site.is_empty():
		_finish()
		return
	var p := Vector2(float(site["position"][0]),float(site["position"][1]))
	check(guide.map_click(p,false),"scope_click_accepts_candidate")
	check(guide.scope.has(str(site["community_id"])),"scope_contains_candidate_community")
	guide.commit_scope()
	demo.pointer = demo.point(p)
	guide.choose_anchor("reserve")
	check(guide.stage == "anchor", "reserve_keeps_anchor_stage")
	check(guide.map_click(p,false),"reserve_map_click_submits")
	check(demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "reserve"),"reserve_pending_before_boundary")
	var expected_event_id := int(demo.model.world.pending_actions.filter(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "reserve")[0].get("event_id",-1))
	var boundary := int(demo.model.next_boundary)
	demo.model.world.settle(boundary)
	demo.shown_world = demo.model.world
	demo._sync_buildings()
	guide.sync()
	check(demo.shown_world.planning_reservations.any(func(item: Dictionary) -> bool: return str(item.get("reservation_id",item.get("id",""))) == "reservation-%05d" % expected_event_id),"reserve_commits_real_boundary_reservation")
	check(str(guide.next_action.get("choice","")) == "reserve" and str(guide.next_action.get("state","")) == "ready","reserve_opens_feedback")
	var cid: String = guide.ready_sound_community()
	check(not cid.is_empty(),"reserve_exposes_sound_community")
	demo.first_composition_guide.sync()
	check(str(demo.first_composition_guide.action) == "sound","first_guide_offers_sound_after_reserve")
	guide._take_next_action()
	check(str(demo.context.get("kind","")) == "seed" and bool(demo.context.get("first_composition",false)),"reserve_continues_into_sound_choice")
	check(str(demo.context.get("community_id","")) == cid,"sound_choice_targets_reserved_community")
	print("RESERVE_ROUTE_AUDIT "+JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"reservation_count":demo.shown_world.planning_reservations.size(),"community_id":cid}))
	_finish()

func _finish() -> void:
	if demo != null: demo.free()
	quit(0 if failures.is_empty() else 1)
