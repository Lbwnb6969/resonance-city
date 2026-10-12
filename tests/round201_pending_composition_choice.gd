extends SceneTree
## Genuine World requests and settlements, with only the device clock controlled.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Pending = preload("res://scripts/ui/pending_composition_choice.gd")
const OUTPUT := "res://验证记录/round201_选择等待/pending_choice.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var demo: Dictionary

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label); push_error(label)

func _prepare() -> World:
	var world := World.new("2026100900000062",true,"river_valley")
	world.build_first_composition_starter()
	var model := Model.new(world)
	demo = {"first_composition_mode":true,"model":model,
		"clock":{"renderer":{"transport":{"audible_frame":0.0,"sample_rate":world.cfg["timing"]["sample_rate"]}}},
		"planning_guide":{"next_action":{}},"pending_expression_choice":{},
		"expression_audition_layer":{"source_model":model,"queued":{},"queued_boundary":-1,"queued_event":-1}}
	return world

func _frame(frame: float) -> void:
	demo["clock"]["renderer"]["transport"]["audible_frame"] = frame

func _public(kind: String) -> Dictionary:
	var world = demo["model"].world
	var site: Dictionary = First.opportunities(world)["public_candidates"][0]
	var charter: Dictionary = demo["model"].submit({"kind":"charter","plan_id":"compact","community_ids":[site["community_id"]]})
	var action := {"first_composition_anchor":true,"state":"queued","choice":kind,
		"community_id":site["community_id"],"expected_boundary_frame":int(charter["frame"]),
		"charter_id":"charter-%05d" % int(charter["event_id"])}
	if kind != "none":
		var submitted: Dictionary = demo["model"].submit({"kind":kind,"position":site["position"]})
		check(bool(submitted.get("accepted",false)),kind+"_genuine_request_accepted")
		action["event_id"] = int(submitted["event_id"])
		action["public_id"] = "reservation-%05d" % int(submitted["event_id"]) if kind == "reserve" else "player-"+kind+"-%05d" % int(submitted["event_id"])
	demo["planning_guide"]["next_action"] = action
	return site

func _expression(expression: String) -> Dictionary:
	var model = demo["model"]
	var site: Dictionary = First.opportunities(model.world)["seed_candidates"][0]
	var operation := PlayerExpression.operation(expression,site["position"])
	var submitted: Dictionary = model.submit(operation)
	check(bool(submitted.get("accepted",false)),expression+"_genuine_request_accepted")
	var branch = model.world.fork()
	branch.settle(int(submitted["frame"]))
	var birth: Dictionary = {}
	for root: Dictionary in branch.buildings:
		if bool(root.get("player_expression",false)) and bool(root.get("family_anchor",false)) and root["position"] == site["position"]:
			birth = {"building":root.duplicate(true),"family":branch.families[str(root["family_id"])].duplicate(true)}
	demo["expression_audition_layer"]["queued"] = {"accepted":true,"birth":birth}
	demo["expression_audition_layer"]["queued_boundary"] = int(submitted["frame"])
	demo["expression_audition_layer"]["queued_event"] = int(submitted["event_id"])
	return site

func _run() -> void:
	for kind: String in ["none","park","civic","reserve"]:
		var world := _prepare()
		var site := _public(kind)
		var boundary: int = demo["model"].next_boundary
		_frame(float(boundary)/2.0)
		var before := world.snapshot()
		var queued := Pending.state(demo)
		check(queued.get("kind","") == kind and queued.get("community_id","") == site["community_id"] and queued.get("community","") == world.communities[site["community_id"]]["name"] and queued.get("progress",0.0) == 0.5 and queued.get("time_to_boundary",0.0) == float(boundary)/2.0/float(world.cfg["timing"]["sample_rate"]),kind+"_choice_names_real_community_and_device_progress")
		check(world.snapshot() == before and demo["planning_guide"]["next_action"]["state"] == "queued",kind+"_query_leaves_world_and_ui_state_unchanged")
		world.settle(boundary)
		check(world.pending_actions.is_empty() and not Pending.state(demo).is_empty(),kind+"_render_ahead_retains_unheard_choice")
		_frame(float(boundary)-1.0)
		check(not Pending.state(demo).is_empty() and Pending.state(demo)["progress"] < 1.0,kind+"_last_queued_sample_still_waits")
		_frame(boundary)
		check(Pending.state(demo).is_empty(),kind+"_actual_device_boundary_clears_choice")
		world = _prepare()
		_public(kind)
		demo["model"].cancel_pending()
		check(Pending.state(demo).is_empty(),kind+"_withdrawn_identity_cannot_reappear")
	for expression: String in PlayerExpression.IDS:
		var world := _prepare()
		var site := _expression(expression)
		var boundary: int = demo["model"].next_boundary
		_frame(float(boundary)/4.0)
		var state := Pending.state(demo)
		check(state.get("kind","") == expression and state.get("choice","") == expression and state.get("label","") == PlayerExpression.definition(expression)["label"] and state.get("position",Vector2.ZERO) == Vector2(float(site["position"][0]),float(site["position"][1])) and state.get("progress",0.0) == 0.25,expression+"_confirmed_branch_and_true_phrase_progress")
		var before := world.snapshot()
		Pending.state(demo)
		check(world.snapshot() == before,expression+"_query_is_read_only")
		world.settle(boundary)
		check(world.pending_actions.is_empty() and not Pending.state(demo).is_empty(),expression+"_settled_real_root_keeps_unheard_choice")
		_frame(boundary)
		check(Pending.state(demo).is_empty(),expression+"_heard_boundary_clears_choice")
		world = _prepare()
		_expression(expression)
		demo["model"].cancel_pending()
		check(Pending.state(demo).is_empty(),expression+"_withdrawn_queue_is_not_authority")
	# A real pending public operation can be rejected as its land changes.
	var world := _prepare()
	var site := _public("park")
	var boundary: int = demo["model"].next_boundary
	world._birth(Vector2(float(site["position"][0]),float(site["position"][1])),48,str(world.buildings[0]["family_id"]),false,0)
	world.refresh_fabric()
	world.settle(boundary)
	check(world.events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "planning_rejected" and int(event.get("event_id",-1)) == int(demo["planning_guide"]["next_action"]["event_id"])) and Pending.state(demo).is_empty(),"real_rejection_clears_before_device_boundary")
	world = _prepare()
	_expression("deep")
	demo["expression_audition_layer"]["source_model"] = Model.new(world.fork())
	check(Pending.state(demo).is_empty(),"previous_model_queue_cannot_leak_to_new_city")
	# Confirmation can succeed without a visual preview branch. Its runtime
	# identity is enough; it still has to match World before becoming visible.
	world = _prepare()
	site = First.opportunities(world)["seed_candidates"][0]
	var operation := PlayerExpression.operation("weave",site["position"])
	var submitted: Dictionary = demo["model"].submit(operation)
	demo["pending_expression_choice"] = {"operation":operation.duplicate(true),"boundary_frame":int(submitted["frame"]),"event_id":int(submitted["event_id"]),"source_model":demo["model"]}
	check(demo["expression_audition_layer"]["queued"].is_empty() and Pending.state(demo).get("kind","") == "weave", "accepted_confirmation_without_preview_branch_waits")
	world.settle(int(submitted["frame"]))
	check(not Pending.state(demo).is_empty(),"unpreviewed_confirmation_survives_render_ahead")
	_frame(int(submitted["frame"]))
	check(Pending.state(demo).is_empty(),"unpreviewed_confirmation_clears_on_device_boundary")
	world = _prepare()
	site = _expression("deep")
	boundary = demo["model"].next_boundary
	world._birth(Vector2(float(site["position"][0]),float(site["position"][1])),48,str(world.buildings[0]["family_id"]),false,0)
	world.refresh_fabric()
	check(Pending.state(demo).get("kind","") == "deep","changed_land_does_not_turn_wait_query_into_placement_error")
	world.settle(boundary)
	check(Pending.state(demo).is_empty(),"unfulfilled_seed_clears_after_actual_settlement")
	world = _prepare()
	_public("civic")
	demo["planning_guide"]["next_action"]["state"] = "expired"
	check(Pending.state(demo).is_empty(),"expired_ui_action_is_not_authority")
	demo["first_composition_mode"] = false
	check(Pending.state(demo).is_empty(),"ordinary_city_has_no_first_composition_wait")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Real World submissions and settlements with controlled audible transport and read-only UI identity records. No rendering, physical audio, or human-fun claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND201_PENDING_CHOICE "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
