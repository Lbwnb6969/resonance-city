extends RefCounted
## A new river-bend composition starts with real young houses. Opportunities
## below are current World queries; they neither reserve nor submit anything.
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const AuthoredStreetGrowth = preload("res://scripts/world/authored_street_growth.gd")
const AuthoredDuet = preload("res://scripts/world/authored_duet.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
const COMMUNITY_IDS := ["west-1","west-2","east-2"]
const HOUSES_PER_COMMUNITY := 8

static func build(world: RefCounted) -> void:
	world.profile = "warm"
	for region in range(COMMUNITY_IDS.size()):
		var cid: String = COMMUNITY_IDS[region]
		var positions := _street_starter_positions(world,cid)
		var family := "family-%05d" % int(world.next_id)
		# These three planted blocks frame the small composition. The player's
		# new sound families own its expansion instead of background sprawl.
		world.families[family] = {"root":"","created_phrase":0,"expression":"warm","growth_house_limit":HOUSES_PER_COMMUNITY}
		var count := 0
		for p: Vector2 in positions:
			if not bool(world.placement(p)["allowed"]): continue
			var pitch: int = [48,52,55][region]
			var id: String = world._birth(p,pitch,family,count == 0,0)
			if count == 0: world.families[family]["root"] = id
			count += 1
			if count >= HOUSES_PER_COMMUNITY: break
	world.refresh_fabric()
	world.resonance = world.coupling.resonance(world.buildings,world.musical_edges(world.musicality()))

static func _street_starter_positions(world: RefCounted,cid: String) -> Array[Vector2]:
	var bank := int(world.communities[cid]["bank"])
	var terrain: Dictionary = world.cfg["terrain"]
	var road_offset := float(terrain["template_road_bank_offset"])
	var frontage := float(terrain["template_lot_road_offset"])
	var radius := float(world.cfg["space"]["residential_radius"])
	var lots: Array = world.lots.filter(func(lot: Dictionary) -> bool: return str(lot["community_id"]) == cid)
	lots.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if not is_equal_approx(float(a["center"][1]),float(b["center"][1])): return float(a["center"][1]) < float(b["center"][1])
		return float(a["center"][0]) < float(b["center"][0]))
	var main_lots: Array[Dictionary] = []
	for lot: Dictionary in lots:
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var entrance: Array = lot["entrance"]
		if absf(float(entrance[0])-world.terrain.river_x(p.y)-float(bank)*road_offset) < 0.1: main_lots.append(lot)
	# Keep two existing parcels clear: the first public anchor and its separate
	# sound root remain actual planning choices beside the young street.
	var clear_lots: Array[Dictionary] = []
	for lot: Dictionary in main_lots:
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var site: Dictionary = world.planning_candidate(p)
		if not bool(site.get("allowed",false)) or SpatialPlanning.public_access(world,site).is_empty(): continue
		clear_lots.append(lot)
		if clear_lots.size() == 2: break
	var chosen: Array[Vector2] = []
	var fallback: Array[Vector2] = []
	var best := INF
	if not main_lots.is_empty():
		var spacing := radius*2.0+0.06
		var end := float(main_lots[-1]["center"][1])+radius
		for phase: float in [0.0,spacing*0.5]:
			var candidates: Array[Vector2] = []
			var y := float(main_lots[0]["center"][1])+phase
			while y <= end:
				for side: int in [-1,1]:
					var p := Vector2(world.terrain.river_x(y)+float(bank)*road_offset+float(side)*frontage,y)
					var clear := clear_lots.all(func(lot: Dictionary) -> bool: return not SpatialPlanning.disc_hits(lot["polygon"],p,radius))
					if not clear: continue
					var check: Dictionary = world.placement(p)
					if bool(check.get("allowed",false)) and str(check.get("community_id","")) == cid: candidates.append(p)
				y += spacing
			if candidates.size() > fallback.size(): fallback = candidates
			for start in range(maxi(0,candidates.size()-HOUSES_PER_COMMUNITY+1)):
				var street: Array[Vector2] = []
				var center := Vector2.ZERO
				var separation := 0.0
				for index in range(start,start+HOUSES_PER_COMMUNITY):
					street.append(candidates[index])
					center += candidates[index]
				center /= float(HOUSES_PER_COMMUNITY)
				for p: Vector2 in street:
					var nearest := INF
					for q: Vector2 in street:
						if p != q: nearest = minf(nearest,p.distance_to(q))
					separation = maxf(separation,nearest)
				var score := street[-1].y-street[0].y+separation
				if not clear_lots.is_empty():
					var raw: Array = clear_lots[0]["center"]
					score += center.distance_to(Vector2(float(raw[0]),float(raw[1])))*0.15
				if score < best:
					best = score
					chosen = street
	# Non-template river terrain still uses legal existing parcels if its small
	# frontage does not contain a complete eight-house window.
	if chosen.is_empty():
		chosen = fallback
		for lot: Dictionary in lots:
			if clear_lots.has(lot): continue
			var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
			if chosen.all(func(q: Vector2) -> bool: return p.distance_to(q) >= radius*2.0): chosen.append(p)
	return chosen

static func opportunities(world: RefCounted) -> Dictionary:
	var ids: Array[String] = []
	for cid: String in COMMUNITY_IDS:
		if world.communities.has(cid) and not world.communities[cid].get("members",[]).is_empty(): ids.append(cid)
	var public_candidates: Array[Dictionary] = []
	var seed_candidates: Array[Dictionary] = []
	var authors := AuthoredDuet.roots(world)
	for cid: String in ids:
		var public_choice: Dictionary = {}
		if not authors.is_empty(): public_choice = AuthoredDuet.public_candidate(world,str(authors[-1]["root_id"]),cid)
		var seed_choice: Dictionary = {}
		var seed_rank := -INF
		var anchored: bool = world.public_sites.any(func(site: Dictionary) -> bool:
			return bool(site.get("active",false)) and bool(site.get("player_planned",false)) and str(site.get("community_id","")) == cid)
		for lot: Dictionary in world.lots:
			if str(lot["community_id"]) != cid or not str(lot.get("occupant","")).is_empty(): continue
			var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
			var placement: Dictionary = world.placement(p)
			var public_site: Dictionary = world.planning_candidate(p)
			if public_choice.is_empty() and bool(public_site.get("allowed",false)) and not SpatialPlanning.public_access(world,public_site).is_empty(): public_choice = public_site.duplicate(true)
			# Once the real public anchor exists, use its adjacent free parcel for
			# the voice instead of yielding it to a second, unchosen public site.
			if bool(placement.get("allowed",false)) and (anchored or str(placement.get("lot_id","")) != str(public_choice.get("source_site_id",""))):
				# Recommend a connected street corner with room to extend, rather
				# than the first parcel at the very end of the road template.
				var nearest_house := INF
				for id: String in world.communities[cid]["members"]:
					var raw: Array = world.by_id[id]["position"]
					nearest_house = minf(nearest_house,p.distance_to(Vector2(float(raw[0]),float(raw[1]))))
				var roads: Dictionary = {}
				for segment: Dictionary in world.near_road_segments(p,1.35):
					if not bool(segment["road"].get("bridge",false)): roads[str(segment["road"]["id"])] = true
				var rank := float(roads.size())*10.0-nearest_house+(100.0 if nearest_house <= 2.4 else 0.0)
				if rank > seed_rank:
					seed_rank = rank
					seed_choice = placement.duplicate(true)
					seed_choice["position"] = [p.x,p.y]
		if seed_rank < 100.0:
			# A template parcel may sit far from this young block. Extend an
			# actual frontage before offering a disconnected first sound.
			var frontage: Array[Vector2] = []
			for id: String in world.communities[cid]["members"]:
				var raw: Array = world.by_id[id]["position"]
				frontage.append(Vector2(float(raw[0]),float(raw[1])))
			var best_frontage := INF
			for candidate: Dictionary in AuthoredStreetGrowth.candidates(world,frontage,"warm"):
				var p: Vector2 = candidate["position"]
				var placement: Dictionary = world.placement(p)
				if not bool(placement.get("allowed",false)) or str(placement.get("community_id","")) != cid: continue
				if Fabric.frontage_directions(world,p).is_empty(): continue
				if not anchored and not public_choice.is_empty() and SpatialPlanning.disc_hits(public_choice["polygon"],p,float(world.cfg["space"]["residential_radius"])): continue
				var distance := absf(p.x-world.terrain.river_x(p.y))
				if distance < best_frontage:
					best_frontage = distance
					seed_choice = placement.duplicate(true)
					seed_choice["position"] = [p.x,p.y]
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
