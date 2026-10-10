extends SceneTree
## Round 154: a confirmed public facility must reopen the planning loop even
## when that phrase has no matching birth event.  The world event is the
## authoritative boundary reveal; this test stays on the UI follow-up seam and
## does not change facility or relocation settlement rules.

const Planning = preload("res://scripts/world/city_spatial_planning.gd")

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func public_candidate(world: RefCounted, cid: String) -> Dictionary:
	for lot in world.lots:
		if not str(lot.get("occupant","")).is_empty(): continue
		if str(lot.get("community_id","")) != cid: continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var candidate: Dictionary = world.planning_candidate(p)
		if candidate.is_empty() or not bool(candidate.get("allowed",false)): continue
		if candidate.has("public_id"): continue
		if not Planning.public_access(world,candidate).is_empty(): return candidate
	return {}

func _run() -> void:
	var scene: PackedScene = load("res://scenes/continuous_valley.tscn")
	var demo = scene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)

	var model = demo.model
	var cid := str(model.world.buildings[0]["community_id"])
	var candidate: Dictionary = public_candidate(model.world,cid)
	check(not candidate.is_empty(),"facility follow-up finds a real accessible parcel")
	if candidate.is_empty():
		demo.queue_free()
		await process_frame
		quit(1)
		return

	var boundary := int(model.next_boundary)
	var guide = demo.planning_guide
	guide.next_action = {
		"state":"queued",
		"choice":"civic",
		"expected_boundary_frame":boundary,
		"community_id":cid,
		"affected_communities":[cid],
		"plan_id":"",
		"target":{},
	}
	check(guide._next_action_event_matches({"kind":"civic","frame":boundary}),"civic boundary event matches queued follow-up")
	check(not guide._next_action_event_matches({"kind":"park","frame":boundary}),"different facility kind cannot consume follow-up")
	check(not guide._next_action_event_matches({"kind":"civic","frame":boundary+1}),"stale facility event cannot consume follow-up")

	var queued: Dictionary = model.submit({"kind":"civic","position":candidate["position"]})
	check(bool(queued.get("accepted",false)),"facility confirmation queues through the production action path")
	model.world.settle(boundary)
	var facility_event: bool = model.world.events.any(func(event: Dictionary) -> bool:
		return str(event.get("kind","")) == "civic" and int(event.get("frame",-1)) == boundary)
	check(facility_event,"facility event is revealed at the phrase boundary")
	guide.sync()
	check(str(guide.next_action.get("state","")) == "ready","facility reveal reopens the next planning action")
	check(bool(guide.opened),"next planning panel is visible after facility-only reveal")

	demo.queue_free()
	await process_frame
	await process_frame
	print("ROUND154_PUBLIC_FOLLOWUP checks=%d failures=%s" % [checks,JSON.stringify(failures)])
	quit(0 if failures.is_empty() else 1)
