extends SceneTree

## Round 148 P11 contract: each real public-choice branch carries structured
## opportunities for every community touched by that branch.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func sites(world: RefCounted,cid: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lot in world.lots:
		if not str(lot.get("occupant","")).is_empty() or str(lot.get("community_id","")) != cid: continue
		var candidate: Dictionary = world.planning_candidate(Vector2(float(lot["center"][0]),float(lot["center"][1])))
		if candidate.is_empty() or not bool(candidate.get("allowed",false)) or candidate.has("public_id"): continue
		if not Planning.public_access(world,candidate).is_empty(): result.append(candidate)
	return result

func _owner_record(preview: Dictionary,cid: String) -> Dictionary:
	for raw in preview.get("communities",[]):
		if str(raw.get("community_id","")) == cid: return raw
	return {}

func _run() -> void:
	var world := World.new()
	world.build_starter("bright")
	for i in range(2): world.settle((world.phrase_index+1)*int(world.cfg["timing"]["phrase_frames"]))
	var available := sites(world,"west-1")
	check(available.size() >= 2,"real public candidate exists")
	if available.size() < 2:
		print("ROUND148_OPPORTUNITY_PREVIEW checks=%d failures=%s" % [checks.size(),["real public candidate exists"]])
		quit(1)
		return
	var model := Model.new(world)
	var rate: int = world.cfg["timing"]["sample_rate"]
	var at := world.phrase_index*int(world.cfg["timing"]["phrase_frames"])
	var phases: Dictionary = {}
	model.render_block(phases,at,64,rate)
	at += 64
	model.submit({"kind":"charter","plan_id":"bluegreen","community_ids":["west-1"]})
	model.submit({"kind":"retune","id":world.communities["west-1"]["members"][0],"midi":52})
	var before := model.capture_state()
	var comparison := Preview.build(model.freeze(),available[0],phases,at)
	check(model.capture_state() == before,"opportunity preview leaves live model and RNG unchanged")
	check(comparison["variants"].size() == 3,"three real public branches are present")
	var owner := "west-1"
	for kind: String in ["none","park","civic"]:
		var variant: Dictionary = comparison["variants"][kind]
		var preview: Dictionary = variant.get("opportunity_preview",{})
		check(preview.has_all(["source","source_version","source_frame","boundary_frame","world_version","boundary","affected_communities","communities","rules"]),kind+" carries preview source boundary and version")
		check(preview["source_version"] == comparison["source_version"] and int(preview["source_frame"]) == at and int(preview["boundary_frame"]) == comparison["boundary_frame"],kind+" shares captured source cursor")
		check(preview["world_version"] == preview["boundary"]["world_version"],kind+" boundary retains branch world version")
		check(preview["affected_communities"].has(owner),kind+" includes source community")
		var record := _owner_record(preview,owner)
		check(not record.is_empty(),kind+" has source community record")
		var roles: Dictionary = record.get("roles",{})
		check(roles.has_all(["theme","bass","commercial","response"]),kind+" exposes theme bass commercial response")
		for alias in ["theme","bass","commercial","response"]:
			var role: Dictionary = roles[alias]
			check(role.has_all(["current","next","qualified","qualification","affected_role_ids","world_version"]),kind+" "+alias+" keeps current next qualification")
			check(role["world_version"] == record["world_version"],kind+" "+alias+" uses branch world version")
			check(record["qualification"][alias] == role["qualified"],kind+" "+alias+" qualification map mirrors role")
		var schedule: Dictionary = record.get("schedule",{})
		check(schedule.has_all(["theme","rhythm_slot_assigned","commercial_rhythm","response","consistency"]),kind+" exposes actual score schedule")
		check(schedule["consistency"].get("theme",false) and schedule["consistency"].get("commercial",false) and schedule["consistency"].get("response",false),kind+" role playing state matches actual schedule")
		check(preview["rules"].has("P11-BASS-EXPRESSION") and preview["rules"].has("P11-COMMERCIAL-RHYTHM") and preview["rules"].has("P11-RIVER-RESPONSE"),kind+" names structured P11 role rules")
	var civic_preview: Dictionary = comparison["variants"]["civic"]["opportunity_preview"]
	var civic_anchor: Dictionary = comparison["variants"]["civic"].get("anchor",{})
	var civic_records: Array = civic_preview.get("communities",[])
	var civic_affected := {}
	for raw_id in civic_anchor.get("served",[]):
		if world.by_id.has(str(raw_id)): civic_affected[str(world.by_id[str(raw_id)]["community_id"])] = true
	for cid in civic_affected: check(civic_preview["affected_communities"].has(cid),"civic preview includes every served community")
	check(comparison["variants"]["none"]["opportunity_preview"]["communities"].size() >= 1 and civic_records.size() >= 1,"all branches have nonempty opportunity records")
	var failures: Array = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print("ROUND148_OPPORTUNITY_PREVIEW checks=%d failures=%s" % [checks.size(),failures])
	quit(0 if failures.is_empty() else 1)
