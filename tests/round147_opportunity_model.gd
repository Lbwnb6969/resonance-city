extends SceneTree

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func _run() -> void:
	var world := World.new()
	world.build_starter("bright")
	var model := Model.new(world)
	var before := world.snapshot()
	var cid := str(world.communities.keys()[0])
	var opportunity := Rules.opportunity(world,cid,model.synth.score_snapshot())
	check(opportunity.has("opportunities") and opportunity["opportunities"].size() == 4,"theme plus three role opportunities are exposed")
	check(opportunity.has("role_opportunities") and opportunity["role_opportunities"].has_all(["Bass","Rhythm","Response"]),"role map exposes bass rhythm response")
	for role in ["Bass","Rhythm","Response"]:
		var entry: Dictionary = opportunity["role_opportunities"][role]
		check(entry.has_all(["current","next","qualification","qualified","affected_role_ids","world_version"]),role+" keeps structured current next qualification")
		check(entry["qualification"].get("qualified",not entry["qualified"] ) == entry["qualified"],role+" qualification mirrors qualified")
	check(world.snapshot() == before,"opportunity model does not mutate world state")

	# A controlled low/deep building proves the bass hint comes from authored
	# world material, without claiming a dedicated bass render lane.
	var low_world: ContinuousWorld = world.fork()
	var low_id := str(low_world.communities[cid]["members"][0])
	low_world.by_id[low_id]["current_midi"] = 36
	low_world.by_id[low_id]["expression"] = "deep"
	var low_score := Model.new(low_world).synth.score_snapshot()
	var low_entry: Dictionary = Rules.opportunity(low_world,cid,low_score)["role_opportunities"]["Bass"]
	check(low_entry["qualified"] and low_entry["current"].contains("低音"),"low pitch/deep expression creates bass material opportunity")

	if not model.synth.rhythms.is_empty():
		var rhythm_cid := str(model.synth.rhythms[0]["cid"])
		var rhythm_entry: Dictionary = Rules.opportunity(world,rhythm_cid,model.synth.score_snapshot())["role_opportunities"]["Rhythm"]
		check(rhythm_entry["qualified"],"actual scheduled rhythm community is qualified")
		check(rhythm_entry["playing"] or rhythm_entry["current"].contains("节奏"),"scheduled rhythm opportunity reports current state")
	else:
		check(false,"starter exposes at least one rhythm candidate")

	var response_entry: Dictionary = opportunity["role_opportunities"]["Response"]
	check(response_entry["river_pairs"] is int and response_entry["river_members"] is int,"response opportunity carries real pair counts")
	var failures: Array = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print("ROUND147_OPPORTUNITY_MODEL checks=%d failures=%s" % [checks.size(),failures])
	quit(0 if failures.is_empty() else 1)
