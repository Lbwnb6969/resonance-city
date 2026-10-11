extends SceneTree
## Round 169: a station route can supply a multi-community planning scope.
## Every charter/card/public branch must keep one captured audio source,
## expose every scoped community, and retain a concrete boundary continuation.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Card = preload("res://scripts/world/planning_card.gd")
const NextAction = preload("res://scripts/world/planning_next_action.gd")
const TransitPlanning = preload("res://scripts/world/transit_planning.gd")

const PLANS := ["compact","corridor","bluegreen"]
const PUBLIC_KINDS := ["none","park","civic"]

var checks := 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _public_candidate(world: RefCounted,cid: String) -> Dictionary:
	for lot in world.lots:
		if not str(lot.get("occupant","" )).is_empty() or str(lot.get("community_id","")) != cid: continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var candidate: Dictionary = world.planning_candidate(p)
		if candidate.is_empty() or not bool(candidate.get("allowed",false)) or candidate.has("public_id"): continue
		if not Planning.public_access(world,candidate).is_empty(): return candidate
	return {}

func _road_candidates(world: RefCounted) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var seen: Array[String] = []
	for road in world.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road.get("path",PackedVector2Array())
		if path.size() < 2: continue
		var stop := TransitPlanning.stop_preview(world,path[path.size()/2])
		if not bool(stop.get("accepted",false)): continue
		var id := str(stop.get("id",""))
		if id.is_empty() or seen.has(id): continue
		seen.append(id)
		result.append(Vector2(float(stop["position"][0]),float(stop["position"][1])))
	return result

func _find_route(world: RefCounted,candidates: Array[Vector2]) -> Array[Vector2]:
	for i in range(candidates.size()):
		for j in range(i+1,candidates.size()):
			for k in range(j+1,candidates.size()):
				var route: Array[Vector2] = [candidates[i],candidates[j],candidates[k]]
				var preview := TransitPlanning.preview(world,route)
				if bool(preview.get("accepted",false)) and preview.get("community_ids",[]).size() >= 2: return route
	return []

func _queue_route(world: RefCounted,route: Array[Vector2],frame: int) -> Dictionary:
	var preview := TransitPlanning.preview(world,route)
	if not bool(preview.get("accepted",false)): return preview
	var queued: Dictionary = world.request({"kind":"transit_line","stop_positions":preview["stop_positions"],"source_topology":preview["source_topology"]},frame)
	if bool(queued.get("accepted",false)): world.settle(frame)
	return queued

func _records(preview: Dictionary) -> Dictionary:
	var result := {}
	for raw in preview.get("communities",[]):
		if raw is Dictionary: result[str(raw.get("community_id",""))] = raw
	return result

func _render_boundary(branch: Model,at: int,boundary: int,rate: int) -> void:
	var phases: Dictionary = {}
	var cursor := at
	while cursor < boundary:
		var amount := mini(1024,boundary-cursor)
		branch.render_block(phases,cursor,amount,rate)
		cursor += amount

func _boundary_contract(source: Model,candidate: Dictionary,scope: Array[String],at: int,boundary: int,rate: int) -> void:
	for kind: String in PUBLIC_KINDS:
		var branch := source.freeze()
		branch.cancel_planning()
		var queued: Dictionary = {"accepted":true}
		if kind != "none": queued = branch.submit({"kind":kind,"position":candidate["position"].duplicate()})
		check(bool(queued.get("accepted",false)),"boundary/"+kind+" accepts the scoped public operation")
		_render_boundary(branch,at,boundary,rate)
		var pcm := branch.render_block({},boundary,rate*3,rate)
		var boundary_events: Array = branch.world.events.filter(func(event: Dictionary) -> bool:
			return int(event.get("frame",-1)) == boundary
		)
		check(boundary_events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "charter"),"boundary/"+kind+" keeps the charter event")
		if kind != "none":
			check(boundary_events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == kind),"boundary/"+kind+" exposes the public event")
			check(branch.world.public_sites.any(func(site: Dictionary) -> bool: return bool(site.get("active",false)) and str(site.get("kind","")) == kind),"boundary/"+kind+" activates the chosen public anchor")
		check(pcm.size() == rate*3,"boundary/"+kind+" continues one three-second audio segment")
		check(branch.synth.max_voice_count <= int(branch.synth.score.get("render_voice_limit",70)),"boundary/"+kind+" stays within the render voice budget")

func _run() -> void:
	var world := World.new("2026101100000169",true,"river_valley")
	world.build_starter("bright")
	var route := _find_route(world,_road_candidates(world))
	check(route.size() == 3,"starter city exposes a real multi-community route")
	if route.size() != 3:
		_finish()
		return
	var phrase := int(world.cfg["timing"]["phrase_frames"])
	var queued_route := _queue_route(world,route,phrase)
	check(bool(queued_route.get("accepted",false)),"station route settles through the real transit contract")
	var line: Dictionary = {}
	for candidate_line in world.transit_lines:
		if bool(candidate_line.get("authored",false)):
			line = candidate_line
			break
	check(not line.is_empty(),"settled route exposes an authored line")
	if line.is_empty():
		_finish()
		return
	var scope: Array[String] = []
	for raw in line.get("community_ids",[]):
		var cid := str(raw)
		if not cid.is_empty() and not scope.has(cid): scope.append(cid)
	scope.sort()
	check(scope.size() >= 2,"station route supplies at least two communities")
	var station_id := str(line.get("stops",[])[0])
	var station := world.transit_stop_record(station_id)
	check(not station.is_empty() and station.get("community_ids",[]).any(func(raw: Variant) -> bool: return scope.has(str(raw))),"station carries authoritative community scope")
	var candidate := _public_candidate(world,scope[0])
	check(not candidate.is_empty(),"route scope has a real road-accessible public candidate")
	if candidate.is_empty() or scope.size() < 2:
		_finish()
		return
	candidate["planning_scope"] = scope.duplicate()

	var rate := int(world.cfg["timing"]["sample_rate"])
	var source := Model.new(world)
	var at := world.phrase_index*phrase
	var phases: Dictionary = {}
	var boundary := source.next_boundary
	var cursor := at
	while cursor < boundary-128:
		var amount := mini(1024,boundary-128-cursor)
		source.render_block(phases,cursor,amount,rate)
		cursor += amount
	at = source.rendered_until
	var card_ids: Array[String] = []
	for raw in Card.CARDS.keys(): card_ids.append(str(raw))
	card_ids.sort()
	for plan: String in PLANS:
		for card_id: String in card_ids:
			var model := source.freeze()
			var charter_result := model.submit({"kind":"charter","plan_id":plan,"community_ids":scope.duplicate(),"card_refs":[card_id]})
			check(bool(charter_result.get("accepted",false)),"%s/%s charter queues" % [plan,card_id])
			var comparison: Dictionary = Preview.build(model.freeze(),candidate,phases,at)
			var source_identity: Array = comparison.get("source_version",[])
			check(source_identity == Preview.identity(model,candidate),"%s/%s comparison keeps its captured source identity" % [plan,card_id])
			for kind: String in PUBLIC_KINDS:
				var variant: Dictionary = comparison.get("variants",{}).get(kind,{})
				var preview: Dictionary = variant.get("opportunity_preview",{})
				var records := _records(preview)
				check(bool(variant.get("accepted",false)),"%s/%s/%s branch accepted" % [plan,card_id,kind])
				check(preview.get("source_version",[]) == source_identity,"%s/%s/%s branch shares the captured source identity" % [plan,card_id,kind])
				check((variant.get("pcm",PackedByteArray()) as PackedByteArray).size() == rate*3*4,"%s/%s/%s branch renders three seconds" % [plan,card_id,kind])
				check(int(preview.get("source_frame",-1)) == at and int(preview.get("boundary_frame",-1)) == int(comparison.get("boundary_frame",-2)),"%s/%s/%s source and boundary frames agree" % [plan,card_id,kind])
				check(scope.all(func(cid: String) -> bool: return preview.get("affected_communities",[]).has(cid) and records.has(cid)),"%s/%s/%s retains every station-scoped community" % [plan,card_id,kind])
				check(scope.all(func(cid: String) -> bool:
					var record: Dictionary = records.get(cid,{})
					return record.get("roles",{}).has_all(["theme","bass","commercial","response"])
				),"%s/%s/%s keeps four opportunity roles for every scoped community" % [plan,card_id,kind])
				var action := NextAction.from_comparison(comparison,kind)
				check(str(action.get("contract","")) == NextAction.CONTRACT,"%s/%s/%s yields the versioned next action" % [plan,card_id,kind])
				check(scope.all(func(cid: String) -> bool: return action.get("community_targets",{}).has(cid)),"%s/%s/%s next action targets every scoped community" % [plan,card_id,kind])
	# Exercise actual boundary events once for all three public choices. The
	# branch loop above proves every plan/card combination remains comparable;
	# this direct continuation proves the event/audio seam is still real.
	var boundary_source := source.freeze()
	boundary_source.submit({"kind":"charter","plan_id":"compact","community_ids":scope.duplicate(),"card_refs":[card_ids[0]]})
	_boundary_contract(boundary_source,candidate,scope,at,boundary,rate)
	var scope_audit := boundary_source.world.fork()
	scope_audit.settle(boundary)
	var local_site := candidate.duplicate(true)
	local_site.erase("planning_scope")
	var owner := str(candidate["community_id"])
	check(Preview._affected_communities(scope_audit,local_site,{}) == [owner],"historical charter does not expand an unrelated local preview")
	var partial_site := candidate.duplicate(true)
	partial_site["partial"] = true
	check(Preview._affected_communities(scope_audit,partial_site,{}) == [owner],"partial preview keeps its actual footprint scope")
	check(Preview._affected_communities(scope_audit,candidate,{}).size() == scope.size(),"normal guide explicitly preserves its current planning scope")
	check(Preview.identity(source,candidate) != Preview.identity(source,local_site),"editing planning scope invalidates the comparison identity")
	check(phrase > 0,"phrase boundary remains positive")
	_finish()

func _finish() -> void:
	print("ROUND169_TRANSIT_SCOPE_PUBLIC_AUDIO ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
