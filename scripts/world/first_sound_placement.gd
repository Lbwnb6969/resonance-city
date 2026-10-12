extends RefCounted
## Keep the existing spatial order; prefer a lot where every authored voice
## can be requested against the same current city. The private copy never settles.
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const CHECK_ORDER := ["warm","deep","weave"]

static func recommend(world: RefCounted,candidates: Array,boundary_frame: int) -> Dictionary:
	if candidates.is_empty(): return {}
	var branch: RefCounted = world.fork()
	var baseline_actions: Array = branch.pending_actions.duplicate(true)
	var baseline_pending: Dictionary = branch.pending.duplicate(true)
	var baseline_serial: int = branch.action_serial
	for candidate: Dictionary in candidates:
		var available := true
		# Warm also needs a real parcel; reject that common failure before
		# checking the two ordinary house requests. Seed request only writes
		# this bookkeeping, so each voice sees the identical pending intent.
		for expression: String in CHECK_ORDER:
			branch.pending_actions.assign(baseline_actions)
			branch.pending = baseline_pending
			branch.action_serial = baseline_serial
			var result: Dictionary = branch.request(PlayerExpression.operation(expression,candidate["position"]),boundary_frame)
			if not bool(result["accepted"]):
				available = false
				break
		if available: return candidate.duplicate(true)
	return candidates[0].duplicate(true)
