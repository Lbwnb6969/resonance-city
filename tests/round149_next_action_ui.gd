extends SceneTree
## Round 149 UI contract: a confirmed public branch queues a contract-backed
## continuation; the first matching birth opens an executable focus/retune menu.

const Coupling = preload("res://scripts/world/world_coupling.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const NextAction = preload("res://scripts/world/planning_next_action.gd")

var failures: Array[String] = []
var checks := 0

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/continuous_valley.tscn")
	var demo = scene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var guide = demo.planning_guide
	var cid := str(demo.model.world.buildings[0]["community_id"])
	var site: Dictionary = {}
	for lot in demo.model.world.lots:
		if str(lot.get("occupant","")) != "" or str(lot.get("community_id","")) != cid: continue
		var candidate: Dictionary = demo.model.world.planning_candidate(Vector2(float(lot["center"][0]),float(lot["center"][1])))
		if candidate.is_empty() or not bool(candidate.get("allowed",false)): continue
		if not Planning.public_access(demo.model.world,candidate).is_empty():
			site = candidate
			break
	check(not site.is_empty(),"find a real road-accessible public candidate")
	if site.is_empty():
		demo.free()
		quit(1)
		return
	guide.open_tool()
	guide.choose_plan("compact")
	guide.choose_card(guide.drawn_card_ids[0])
	guide.map_click(Coupling.position_of(demo.model.world.buildings[0]),false)
	check(guide.scope.has(cid),"scope selects the affected community")
	guide.commit_scope()
	guide.anchor_kind = "park"
	guide.opened = true
	guide.stage = "anchor"
	guide.scope = [cid]
	guide.candidate = site
	guide.preview = {"access":Planning.public_access(demo.model.world,site)}
	# Feed the same shape returned by PublicPreview; from_comparison is the only
	# source of the queued continuation in the guide.
	var preview := {"choice":"park","accepted":true,"source":{"community_id":cid},
		"source_version":[1,2,3],"source_frame":0,"boundary_frame":1,"world_version":[0,1,0],
		"boundary":{"world_version":[0,1,0]},"affected_communities":[cid],
		"communities":[{"community_id":cid,"roles":{"theme":{"role":"Lead","title":"社区主题","qualified":true,"next":"聚焦听下一拍","current":"当前长音"}}}]}
	var branch := {"accepted":true,"opportunity_preview":preview,"score":{"theme":{}},"theme_events":0,
		"service":{"served":0},"houses":demo.model.world.buildings.size(),"anchor":{},"newly_served_ids":[],"lost_service_ids":[]}
	guide.comparison = {"source_version":[1,2,3],"source_frame":0,"boundary_frame":1,
		"variants":{"none":branch.duplicate(true),"park":branch.duplicate(true),"civic":branch.duplicate(true)}}
	var p := Vector2(float(site["position"][0]),float(site["position"][1]))
	guide.map_click(p,false)
	check(guide.next_action.get("contract","") == NextAction.CONTRACT,"confirmation stores P11 next-action contract")
	check(guide.next_action.get("state","") == "queued","confirmation queues a follow-up")
	check(not guide.visible,"planning panel closes until the result lands")
	var building_id := str(demo.shown_world.by_id.keys()[0])
	guide._activate_next_action({"kind":"birth","district_id":building_id,"plan_id":"compact"})
	check(guide.next_action.get("state","") == "ready" and guide.visible,"matching birth opens the next-action panel")
	guide.next_action_button.emit_signal("pressed")
	check(demo.selected_id == building_id,"button selects the real landed building")
	check(demo.context.get("kind","") == "retune" and demo.menu.visible,"button opens existing focus and retune menu")
	print("ROUND149_NEXT_ACTION_UI checks=%d failures=%s" % [checks,JSON.stringify(failures)])
	demo.free()
	quit(0 if failures.is_empty() else 1)

