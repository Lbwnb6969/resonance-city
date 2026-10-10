extends SceneTree
## Round 149 P11 contract: a confirmed public branch exposes one stale-aware
## continuation that the UI can execute without mutating the forecast.

const NextAction = preload("res://scripts/world/planning_next_action.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const PublicPreview = preload("res://scripts/world/public_planning_preview.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func role(name: String,ready: bool,anchors: Array = []) -> Dictionary:
	return {"role":name,"title":name,"qualified":ready,"current":"当前 "+name,"next":"下一步 "+name,
		"qualification":{"qualified":ready,"missing_conditions":[] if ready else ["继续形成"]},
		"affected_role_ids":[name],"anchor_ids":anchors,"world_version":[3,11,7]}

func preview(choice: String,ready: bool = true) -> Dictionary:
	var record := {"community_id":"west-1","world_version":[3,11,7],
		"anchor_ids":["west-park"] if choice == "park" else [],
		"roles":{"theme":role("Lead",ready),"commercial":role("Rhythm",false,["building-0002"]),
			"bass":role("Bass",ready,["building-0001"]),"response":role("Response",false)},
		"current":{"theme":"正在唱主题"},"next":{"theme":"聚焦听下一拍"}}
	return {"source":{"kind":"public_planning_variant","choice":choice},"choice":choice,
		"accepted":true,"source_version":[3,11,7,"token"],"source_frame":4800,"boundary_frame":9600,
		"world_version":[3,11,7],"boundary":{"frame":9600,"world_version":[3,11,7]},
		"affected_communities":["west-1","east-2"],"anchor_ids":record["anchor_ids"],"communities":[record],
		"rules":["P11-COMMUNITY-THEME"]}

func real_sites(world: RefCounted,cid: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lot in world.lots:
		if not str(lot.get("occupant","")).is_empty() or str(lot.get("community_id","")) != cid: continue
		var candidate: Dictionary = world.planning_candidate(Vector2(float(lot["center"][0]),float(lot["center"][1])))
		if candidate.is_empty() or not bool(candidate.get("allowed",false)) or candidate.has("public_id"): continue
		if not Planning.public_access(world,candidate).is_empty(): result.append(candidate)
	return result

func _run() -> void:
	var park := NextAction.from_preview(preview("park"))
	check(park["contract"] == "P11-NEXT-ACTION/v1","versioned contract")
	check(park["status"] == "ready","qualified role is ready")
	check(park["action_kind"] == "focus_community" and park["operation"] == {"kind":"focus","community":"west-1"},"next action is executable focus operation")
	check(park["target"]["community_ids"] == ["west-1","east-2"],"target retains affected communities")
	check(park["target"]["anchor_id"] == "west-park" and park["target"]["adjustable_ids"] == ["building-0001","building-0002"],"target retains real anchor and adjustable objects")
	check(park["token"]["source_frame"] == 4800 and park["token"]["boundary_frame"] == 9600,"presentation frame boundary is retained")
	check(park["token"]["source_version"] == [3,11,7,"token"] and park["presentation_token"]["boundary_world_version"] == [3,11,7],"source and boundary versions are retained")
	check(NextAction.is_current(park,[3,11,7],9600),"action remains current through boundary")
	check(not NextAction.is_current(park,[3,11,8],9600),"world revision invalidates stale action")
	check(not NextAction.is_current(park,[3,11,7],9601),"past boundary invalidates stale presentation")

	var waiting_preview := preview("none",false)
	# A secondary role can be ready while the community's headline theme is
	# still waiting; status must continue to follow the theme qualification.
	waiting_preview["communities"][0]["roles"]["bass"]["qualified"] = true
	waiting_preview["communities"][0]["roles"]["bass"]["qualification"]["qualified"] = true
	var waiting := NextAction.from_preview(waiting_preview)
	check(waiting["status"] == "waiting" and waiting["action_kind"] == "focus_community","unqualified opportunity still gives an executable focus")
	check(waiting["target"]["anchor_id"] == "" and waiting["target"]["role"] == "bass","waiting action points at first actionable role without fabricating anchor")

	var comparison := {"source_version":[3,11,7,"token"],"source_frame":4800,"boundary_frame":9600,
		"variants":{"park":{"accepted":true,"opportunity_preview":preview("park")}}}
	var from_comparison := NextAction.from_comparison(comparison,"park")
	check(from_comparison["operation"] == park["operation"] and from_comparison["token"] == park["token"],"comparison helper preserves branch contract")

	# Exercise the same contract against the real three-branch preview source.
	var world := World.new()
	world.build_starter("bright")
	for i in range(2): world.settle((world.phrase_index+1)*int(world.cfg["timing"]["phrase_frames"]))
	var candidates := real_sites(world,"west-1")
	check(not candidates.is_empty(),"real public candidate exists for next-action integration")
	if not candidates.is_empty():
		var model := Model.new(world)
		var phases: Dictionary = {}
		var at := world.phrase_index*int(world.cfg["timing"]["phrase_frames"])
		model.render_block(phases,at,64,int(world.cfg["timing"]["sample_rate"]))
		var real_comparison: Dictionary = PublicPreview.build(model.freeze(),candidates[0],phases,at)
		var real_action := NextAction.from_comparison(real_comparison,"park")
		check(real_action["contract"] == "P11-NEXT-ACTION/v1" and real_action["token"]["source_frame"] == at,"real preview yields versioned next action")
		check(real_action["target"]["community_id"] != "" and real_action["operation"]["kind"] == "focus","real preview yields community focus operation")

	var failures: Array = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print("ROUND149_NEXT_ACTION_CONTRACT checks=%d failures=%s" % [checks.size(),failures])
	quit(0 if failures.is_empty() else 1)

