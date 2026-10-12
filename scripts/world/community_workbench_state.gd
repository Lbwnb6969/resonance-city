extends RefCounted
## A community is its heard planning members, not a source family or forecast.
## Call with presentation_world and audible_pitches. Birth guards also reject
## render-ahead additions; they cannot reconstruct an old moved/absorbed World.
const MusicRules = preload("res://scripts/world/community_music_rules.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
const Frontage = preload("res://scripts/world/community_frontage.gd")

class HeardView extends RefCounted:
	const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
	var source: RefCounted
	var communities: Dictionary = {}
	var by_id: Dictionary = {}
	var families: Dictionary = {}
	var buildings: Array = []
	var public_sites: Array = []
	var planning_reservations: Array = []
	var landmarks: Array = []
	var green_corridors: Array = []
	var fabric_cache: Dictionary = {}
	var lots: Array = []
	var terrain: RefCounted
	func near_road_segments(p: Vector2,reach: float) -> Array[Dictionary]:
		return source.near_road_segments(p,reach)
	func building_polygon(p: Vector2) -> PackedVector2Array:
		return source.building_polygon(p)
	func near_public_sites(_p: Vector2,_reach: float = 0.0) -> Array:
		return public_sites
	func near_planning_reservations(_p: Vector2,_reach: float = 0.0) -> Array:
		return planning_reservations

static func _position(record: Dictionary) -> Vector2:
	var p: Variant = record.get("position",[0.0,0.0])
	return p if p is Vector2 else Vector2(float(p[0]),float(p[1]))

static func _reserve_frames(world: RefCounted) -> Dictionary:
	var frames: Dictionary = {}
	for event: Dictionary in world.events:
		if str(event.get("kind","")) == "reserve":
			frames[str(event.get("id",""))] = int(event.get("frame",0))
	return frames

static func _record_frame(world: RefCounted,record: Dictionary,reserve_frames: Dictionary = {}) -> int:
	if record.has("frame"): return int(record["frame"])
	var id := str(record.get("reservation_id",record.get("id","")))
	if reserve_frames.has(id): return int(reserve_frames[id])
	return int(record.get("created_phrase",0))*int(world.cfg["timing"]["phrase_frames"])

static func _view(world: RefCounted,audible_frame: int,reserve_frames: Dictionary,pitches: Dictionary) -> HeardView:
	var view := HeardView.new()
	view.source = world
	view.terrain = world.terrain
	view.lots = world.lots
	view.green_corridors = world.green_corridors
	var future := false
	# Upgrade events allow the qualification guard to omit unheard maturity
	# even when a caller supplies the renderer's newer World by mistake.
	var future_upgrades: Dictionary = {}
	var heard_forms: Dictionary = {}
	for event: Dictionary in world.events:
		if str(event.get("kind","")) != "upgrade": continue
		var id := str(event.get("district_id",""))
		if int(event.get("frame",0)) > audible_frame: future_upgrades[id] = true
		else: heard_forms[id] = str(event["form"])
	for building: Dictionary in world.buildings:
		if int(building.get("birth_frame",0)) > audible_frame:
			future = true
			continue
		var id := str(building["district_id"])
		var heard := building
		if future_upgrades.has(id) or pitches.has(id):
			heard = building.duplicate()
		if future_upgrades.has(id):
			heard["form"] = str(heard_forms.get(id,"胚"))
		if pitches.has(id): heard["current_midi"] = int(pitches[id])
		view.by_id[id] = heard
		view.buildings.append(heard)
	for cid: String in world.communities:
		var members: Array[String] = []
		for raw in world.communities[cid].get("members",[]):
			var id := str(raw)
			if view.by_id.has(id) and str(view.by_id[id].get("community_id","")) == cid and not members.has(id): members.append(id)
		members.sort()
		view.communities[cid] = {"members":members}
	for family_id: String in world.families:
		var family: Dictionary = world.families[family_id]
		if view.by_id.has(str(family.get("root",""))): view.families[family_id] = family
	for site: Dictionary in world.public_sites:
		if _record_frame(world,site) > audible_frame:
			future = true
			continue
		view.public_sites.append(site)
	for reservation: Dictionary in world.planning_reservations:
		if _record_frame(world,reservation,reserve_frames) > audible_frame:
			future = true
			continue
		if bool(reservation.get("active",true)): view.planning_reservations.append(reservation)
	for landmark: Dictionary in world.landmarks:
		if _record_frame(world,landmark) <= audible_frame: view.landmarks.append(landmark)
		else: future = true
	var walls: Array = []
	for wall: Dictionary in world.fabric_cache.get("shared_walls",[]):
		if view.by_id.has(str(wall["a"])) and view.by_id.has(str(wall["b"])): walls.append(wall)
	var courts: Array = []
	for court: Dictionary in world.fabric_cache.get("courtyards",[]):
		var heard := true
		for id in court.get("members",[]):
			if not view.by_id.has(str(id)): heard = false; break
		if heard: courts.append(court)
	# The normal shown_world path reuses published geometry. Only a newer World
	# needs the same frontage measurement over this lightweight private view.
	var frontage: Dictionary = Frontage.measure(view) if future else world.fabric_cache.get("community_wall",{})
	view.fabric_cache = {"shared_walls":walls,"courtyards":courts,"community_wall":frontage}
	return view

static func describe(world: RefCounted,cid: String,audible_frame: int,pitches: Dictionary = {}) -> Dictionary:
	var result := {"available":false,"id":cid,"name":str(world.communities.get(cid,{}).get("name",cid)),
		"member_ids":Array([],TYPE_STRING,"",null),"count":0,"type_counts":{},"center":Vector2.ZERO,"midi_counts":{},
		"authors":Array([],TYPE_DICTIONARY,"",null),"public_sites":Array([],TYPE_DICTIONARY,"",null),
		"reservations":Array([],TYPE_DICTIONARY,"",null),"authored_member_ids":Array([],TYPE_STRING,"",null),
		"status":{},"status_text":"这里还没有房屋"}
	if not world.communities.has(cid) or not bool(world.communities[cid].get("active",true)): return result
	var reserve_frames := _reserve_frames(world)
	var view := _view(world,audible_frame,reserve_frames,pitches)
	var ids: Array[String] = view.communities[cid]["members"]
	result["member_ids"] = ids.duplicate()
	result["count"] = ids.size()
	result["available"] = not ids.is_empty()
	var center := Vector2.ZERO
	var family_members: Dictionary = {}
	for id: String in ids:
		var building: Dictionary = view.by_id[id]
		center += _position(building)
		var kind := str(building["type"])
		result["type_counts"][kind] = int(result["type_counts"].get(kind,0))+1
		var midi := int(pitches.get(id,building["current_midi"]))
		result["midi_counts"][midi] = int(result["midi_counts"].get(midi,0))+1
		var family_id := str(building.get("family_id",""))
		if not family_members.has(family_id): family_members[family_id] = Array([],TYPE_STRING,"",null)
		family_members[family_id].append(id)
		if bool(view.families.get(family_id,{}).get("player_expression",false)): result["authored_member_ids"].append(id)
	result["center"] = center/float(ids.size()) if not ids.is_empty() else Vector2.ZERO
	var reservation_owners: Dictionary = {}
	for family_id: String in view.families:
		var family: Dictionary = view.families[family_id]
		if not bool(family.get("player_expression",false)): continue
		var root_id := str(family.get("root",""))
		var building: Dictionary = view.by_id.get(root_id,{})
		if str(building.get("family_id","")) != family_id: continue
		var reservation_id := str(family.get("expression_reservation_id",""))
		if not reservation_id.is_empty(): reservation_owners[reservation_id] = root_id
		if not ids.has(root_id): continue
		result["authors"].append({"root_id":root_id,"family_id":family_id,"expression":str(family.get("expression","")),
			"current_midi":int(pitches.get(root_id,building["current_midi"])),"position":_position(building),
			"family_members":family_members.get(family_id,Array([],TYPE_STRING,"",null)).duplicate(),"birth_frame":int(building.get("birth_frame",0))})
	result["authors"].sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a["birth_frame"] != b["birth_frame"]: return a["birth_frame"] < b["birth_frame"]
		return str(a["root_id"]) < str(b["root_id"]))
	for site: Dictionary in view.public_sites:
		if bool(site.get("active",false)) and str(site.get("community_id","")) == cid and str(site.get("kind","")) in ["park","civic"]:
			result["public_sites"].append(site.duplicate(true))
	result["public_sites"].sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	for reservation: Dictionary in view.planning_reservations:
		var id := str(reservation.get("reservation_id",reservation.get("id","")))
		if not reservation_owners.has(id): continue
		var reservation_cid := str(reservation.get("community_id",""))
		if reservation_cid.is_empty(): reservation_cid = Fabric.community_for_position(world,_position(reservation))
		if reservation_cid != cid: continue
		var record := reservation.duplicate(true)
		record["root_id"] = reservation_owners[id]
		record["community_id"] = reservation_cid
		record["frame"] = _record_frame(world,reservation,reserve_frames)
		result["reservations"].append(record)
	result["reservations"].sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	var status := MusicRules.status(view,cid)
	var missing: Array[String] = []
	if int(status["members"]) < 4: missing.append("还需%d栋房屋" % (4-int(status["members"])))
	if not bool(status["street_formed"]): missing.append("沿街成形")
	if int(status["courtyards"]) < 1 and not bool(status["public_anchor"]): missing.append("内院或你的公共空间")
	if int(status["mature"]) < 6: missing.append("还需%d栋成熟房屋" % (6-int(status["mature"])))
	status["missing_conditions"] = missing
	status["text"] = "主题可用" if bool(status["theme_eligible"]) else ("主题未成形 · "+"、".join(missing))
	if ids.is_empty(): status["text"] = "这里还没有房屋"
	result["status"] = status
	result["status_text"] = status["text"]
	return result
