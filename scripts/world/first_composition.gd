extends RefCounted
## A new river-bend composition starts with real young houses. Opportunities
## below are current World queries; they neither reserve nor submit anything.
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const COMMUNITY_IDS := ["west-1","west-2","east-2"]
const HOUSES_PER_COMMUNITY := 8

static func build(world: RefCounted) -> void:
	world.profile = "warm"
	for region in range(COMMUNITY_IDS.size()):
		var cid: String = COMMUNITY_IDS[region]
		var candidates: Array = world.lots.filter(func(lot: Dictionary) -> bool: return str(lot["community_id"]) == cid)
		candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
		var family := "family-%05d" % int(world.next_id)
		world.families[family] = {"root":"","created_phrase":0,"expression":"warm"}
		var count := 0
		for lot: Dictionary in candidates:
			var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
			if not bool(world.placement(p)["allowed"]): continue
			var pitch: int = [48,52,55][region]
			var id: String = world._birth(p,pitch,family,count == 0,0)
			if count == 0: world.families[family]["root"] = id
			count += 1
			if count >= HOUSES_PER_COMMUNITY: break
	world.refresh_fabric()
	world.resonance = world.coupling.resonance(world.buildings,world.musical_edges(world.musicality()))

static func opportunities(world: RefCounted) -> Dictionary:
	var ids: Array[String] = []
	for cid: String in COMMUNITY_IDS:
		if world.communities.has(cid) and not world.communities[cid].get("members",[]).is_empty(): ids.append(cid)
	var public_candidates: Array[Dictionary] = []
	var seed_candidates: Array[Dictionary] = []
	for cid: String in ids:
		var public_choice: Dictionary = {}
		var seed_choice: Dictionary = {}
		for lot: Dictionary in world.lots:
			if str(lot["community_id"]) != cid or not str(lot.get("occupant","")).is_empty(): continue
			var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
			var placement: Dictionary = world.placement(p)
			var public_site: Dictionary = world.planning_candidate(p)
			if public_choice.is_empty() and bool(public_site.get("allowed",false)) and not SpatialPlanning.public_access(world,public_site).is_empty(): public_choice = public_site.duplicate(true)
			if seed_choice.is_empty() and bool(placement.get("allowed",false)) and str(placement.get("lot_id","")) != str(public_choice.get("source_site_id","")):
				seed_choice = placement.duplicate(true)
				seed_choice["position"] = [p.x,p.y]
			if not public_choice.is_empty() and not seed_choice.is_empty(): break
		if seed_choice.is_empty():
			# A growing street can consume every parcel without consuming its
			# continuous surroundings. Query legal land around actual members.
			for raw_id in world.communities[cid].get("members",[]):
				var house: Dictionary = world.by_id.get(str(raw_id),{})
				if house.is_empty(): continue
				var center := Vector2(float(house["position"][0]),float(house["position"][1]))
				for radius: float in [1.15,1.75,2.35,3.1]:
					for step in range(12):
						var p := center+Vector2.from_angle(TAU*float(step)/12.0)*radius
						var placement: Dictionary = world.placement(p)
						if not bool(placement.get("allowed",false)) or str(placement.get("community_id","")) != cid: continue
						seed_choice = placement.duplicate(true)
						seed_choice["position"] = [p.x,p.y]
						break
					if not seed_choice.is_empty(): break
				if not seed_choice.is_empty(): break
		if not public_choice.is_empty(): public_candidates.append(public_choice)
		if not seed_choice.is_empty(): seed_candidates.append(seed_choice)
	return {"community_ids":ids,"public_candidates":public_candidates,"seed_candidates":seed_candidates}

static func polygon(coordinates: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Array in coordinates: result.append(Vector2(float(point[0]),float(point[1])))
	return result

## The warm choice keeps one real nearby parcel available for later planning.
## Coordinates stay ordinary arrays in pending intent for both save formats.
static func warm_reservation(world: RefCounted,position: Vector2) -> Dictionary:
	var cid := str(world.placement(position).get("community_id",""))
	var selected: Dictionary = {}
	var distance := INF
	var radius := float(world.cfg["space"]["residential_radius"])
	var locations: Array = []
	for lot: Dictionary in world.lots:
		if str(lot["community_id"]) == cid and str(lot.get("occupant","")).is_empty(): locations.append(lot["center"])
	for court: Dictionary in world.fabric_cache.get("courtyards",[]):
		if str(court.get("community_id","")) == cid: locations.append(court["center"])
	for raw: Array in locations:
		var p := Vector2(float(raw[0]),float(raw[1]))
		var d := p.distance_squared_to(position)
		if d > 36.0 or d >= distance: continue
		var candidate: Dictionary = world.planning_candidate(p)
		if not bool(candidate.get("allowed",false)) or str(candidate.get("community_id","")) != cid or candidate.has("reservation_id") or candidate.has("public_id"): continue
		var footprint: PackedVector2Array = candidate["polygon"]
		if SpatialPlanning.disc_hits(footprint,position,radius): continue
		if _pending_hits(world,footprint,radius): continue
		selected = _reservation_intent(candidate,cid)
		distance = d
	if not selected.is_empty(): return selected
	# Streets can fill their lots before the player chooses a voice. Preserve
	# actual continuous clear land with the same parcel exclusion and lifecycle.
	for gap: float in [1.6,2.3,3.0,3.8,4.6]:
		for step in range(16):
			var p := position+Vector2.from_angle(TAU*float(step)/16.0)*gap
			if str(world.placement(p).get("community_id","")) != cid: continue
			var candidate := _clear_land(p,cid)
			var footprint: PackedVector2Array = candidate["polygon"]
			if SpatialPlanning.disc_hits(footprint,position,radius) or _pending_hits(world,footprint,radius): continue
			if not SpatialPlanning.site_reason(world,candidate).is_empty(): continue
			return _reservation_intent(candidate,cid)
	return selected

static func _clear_land(position: Vector2,cid: String) -> Dictionary:
	var half := Vector2.ONE*0.55
	return {"position":[position.x,position.y],"community_id":cid,
		"source_site_id":"expression-clear:%.5f:%.5f" % [position.x,position.y],"source_lot_ids":[],
		"polygon":PackedVector2Array([position-half,position+Vector2(half.x,-half.y),position+half,position+Vector2(-half.x,half.y)])}

static func _reservation_intent(candidate: Dictionary,cid: String) -> Dictionary:
	var coordinates: Array = []
	for point in candidate["polygon"]: coordinates.append([point.x,point.y])
	return {"position":candidate["position"].duplicate(),"polygon":coordinates,"community_id":cid,
		"source_site_id":str(candidate["source_site_id"]),"source_lot_ids":candidate.get("source_lot_ids",[]).duplicate()}

static func _pending_hits(world: RefCounted,footprint: PackedVector2Array,radius: float) -> bool:
	for op: Dictionary in world.pending_actions:
		if str(op.get("kind","")) == "seed":
			var raw: Array = op["position"]
			if SpatialPlanning.disc_hits(footprint,Vector2(float(raw[0]),float(raw[1])),radius): return true
			if op.has("expression_reservation") and SpatialPlanning.overlaps(footprint,polygon(op["expression_reservation"]["polygon"])): return true
		elif str(op.get("kind","")) in ["reserve","park","civic","relocate_public"]:
			var pending_polygon: PackedVector2Array = op.get("polygon",op.get("target_polygon",PackedVector2Array()))
			if SpatialPlanning.overlaps(footprint,pending_polygon): return true
	return false

static func commit_expression_reservation(world: RefCounted,reservation: Dictionary,frame: int) -> bool:
	if not str(reservation["source_site_id"]).begins_with("expression-clear:"): return SpatialPlanning.commit(world,reservation,frame)
	var raw: Array = reservation["position"]
	var p := Vector2(float(raw[0]),float(raw[1]))
	var actual := _clear_land(p,str(world.placement(p).get("community_id","")))
	if actual["source_site_id"] != reservation["source_site_id"] or actual["community_id"] != reservation["community_id"] or actual["polygon"] != reservation["polygon"]: return false
	if not SpatialPlanning.site_reason(world,actual).is_empty(): return false
	var id := "reservation-%05d" % int(reservation["event_id"])
	world.planning_reservations.append({"id":id,"reservation_id":id,"polygon":actual["polygon"].duplicate(),"position":raw.duplicate(),
		"source_site_id":actual["source_site_id"],"source_lot_ids":[],"created_phrase":world.phrase_index})
	world._refresh_parcel_index()
	world.events.append({"kind":"reserve","id":id,"source_site_id":actual["source_site_id"],"source_lot_ids":[],"frame":frame})
	return true
