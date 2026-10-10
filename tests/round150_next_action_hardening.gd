extends SceneTree
## Round 150 P11 hardening: retain every affected community and reject a
## missing or stale version token before a focus continuation can be shown.

const NextAction = preload("res://scripts/world/planning_next_action.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func role(name: String,ready: bool,anchors: Array = []) -> Dictionary:
	return {"role":name,"title":name,"qualified":ready,"current":"当前 "+name,
		"next":"下一步 "+name,"qualification":{"qualified":ready},
		"affected_role_ids":[name],"anchor_ids":anchors,"world_version":[4,12,2]}

func record(cid: String,ready: bool,anchor: String) -> Dictionary:
	return {"community_id":cid,"world_version":[4,12,2],"anchor_ids":[anchor],
		"roles":{"theme":role("Lead-"+cid,ready),"commercial":role("Rhythm-"+cid,false,["building-"+cid]),
			"bass":role("Bass-"+cid,ready,["bass-"+cid]),"response":role("Response-"+cid,false)}}

func preview() -> Dictionary:
	return {"source":{"kind":"public_planning_variant","choice":"park"},"choice":"park",
		"accepted":true,"source_version":[4,12,2,"preview"],"source_frame":1200,
		"boundary_frame":2400,"world_version":[4,12,2],
		"boundary":{"frame":2400,"world_version":[4,12,2]},
		"affected_communities":["west-1","east-2"],"anchor_ids":["west-park"],
		"communities":[record("west-1",true,"west-park"),record("east-2",false,"east-civic")]}

func _run() -> void:
	var action := NextAction.from_preview(preview())
	check(action["community_targets"].keys().size() == 2,"all affected communities keep independent targets")
	var east := NextAction.community_target(action,"east-2")
	check(east.get("community_id","") == "east-2" and east.get("roles",{}).get("theme",{}).get("current","") == "当前 Lead-east-2","secondary community target retains its own role rows")
	check(east.get("anchor_id","") == "east-civic" and east.get("adjustable_ids",[]).has("bass-east-2"),"secondary target retains real anchor and adjustable ids")
	check(NextAction.is_current(action,[4,12,2],2400),"version token remains current at its boundary")
	check(not NextAction.is_current(action,[],2400),"missing world version cannot be treated as current")
	check(not NextAction.is_current(action,[4,12,3],2400),"changed world version invalidates the continuation")
	check(not NextAction.is_current(action,[4,12,2],2401),"past presentation boundary invalidates the continuation")

	# A no-preview fallback still has a safe owner target and does not invent
	# secondary role data.
	var fallback := NextAction.from_comparison({"source_version":[4,12,2],"source_frame":1200,
		"boundary_frame":2400,"variants":{"none":{"accepted":true,"choice":"none",
			"opportunities":[{"community_id":"west-1","role":"Lead","qualified":true}]}}},"none")
	check(fallback["community_id"] == "west-1" and fallback["community_targets"].has("west-1"),"legacy fallback keeps one concrete owner")
	check(fallback["community_targets"].size() == 1,"legacy fallback does not fabricate extra communities")

	var failures: Array[String] = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print("ROUND150_NEXT_ACTION_HARDENING checks=%d failures=%s" % [checks.size(),failures])
	quit(0 if failures.is_empty() else 1)
