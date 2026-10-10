extends SceneTree
## Round 147 contract: expose the existing score roles used by P11 previews.
## This test deliberately records that there is no dedicated bass lane.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func community_has_type(world: ContinuousWorld, cid: String, kind: String) -> bool:
	if not world.communities.has(cid): return false
	for id in world.communities[cid].get("members",[]):
		if world.by_id.has(str(id)) and str(world.by_id[str(id)].get("type","")) == kind:
			return true
	return false

func _run() -> void:
	var world := World.new("2026101100000147",true,"river_valley")
	world.build_expanded_town()
	var model := Model.new(world)
	var score: Dictionary = model.synth.score_snapshot()
	var rhythms: Array = score.get("rhythms",[])
	check(rhythms.size() <= int(model.synth.score["rhythm_slot_limit"]),"rhythms respect the configured slot limit")
	var rhythm_roles: Dictionary = {}
	var commercial_rhythm := false
	for part in rhythms:
		check(part.has_all(["cid","midi","stereo","expression","facility","zone_roles","service_pressure"]),"rhythm exposes stable role metadata")
		var cid := str(part.get("cid",""))
		check(not cid.is_empty() and world.communities.has(cid),"rhythm community resolves in world")
		check(float(part.get("service_pressure",-1.0)) >= 0.0,"rhythm service pressure is bounded data")
		var roles: Array = part.get("zone_roles",[])
		for role in roles: rhythm_roles[str(role)] = true
		if roles.has("market") or community_has_type(world,cid,"commercial"): commercial_rhythm = true
	check(commercial_rhythm,"expanded town exposes a real commercial rhythm candidate")
	var theme: Dictionary = score.get("theme",{})
	check(not theme.is_empty(),"expanded town exposes one authored theme")
	check(theme.has_all(["cid","notes","expression","park","civic","center","zone_roles","stereo","source_ids"]),"theme exposes stable role metadata")
	check(int(model.synth.score["theme_slot_limit"]) == 1,"theme remains one authored slot")
	var response: Dictionary = score.get("response",{})
	if not response.is_empty():
		check(int(response.get("generation",0)) == 1,"response is one derived generation")
		check(response.has_all(["source","source_ids","receiver_ids","notes","pair_count","stereo"]),"response exposes source and receiver metadata")
		check(str(response.get("source","")) == str(theme.get("cid","")),"response source follows the authored theme")
		check(response.get("source_ids",[]).size() == response.get("receiver_ids",[]).size(),"response keeps paired source and receiver identities")
	check(int(model.synth.score["response_slot_limit"]) == 1,"response remains one derived slot")
	check(not score.has("bass"),"score has no dedicated bass lane")
	check(rhythms.all(func(part: Dictionary) -> bool: return not part.has("bass")),"rhythm metadata has no hidden bass lane")
	var report := {"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"rhythm_roles":rhythm_roles,"rhythms":rhythms,"theme":theme,"response":response,"dedicated_bass":false}
	print("ROUND147_SYNTH_ROLE ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
