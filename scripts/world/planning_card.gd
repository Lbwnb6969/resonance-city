extends RefCounted
## Small, reversible variation cards for a development charter.
## Cards only bias existing candidate relations or their growth timing. They
## never write vitality, resonance, service capacity, or a new land-use rule.

const CARDS := {
	"infill_pulse": {
		"title":"街墙聚拢",
		"tendency":"同社区已有房屋旁的候选更早被看见",
		"tradeoff":"远端空地仍可成长，但不会抢过连片边缘",
		"relation":"聚焦",
		"duration_phrases":3,
		"bonus":"邻居优先"
	},
	"road_echo": {
		"title":"沿路回声",
		"tendency":"真实道路与站点旁的候选更早接入",
		"tradeoff":"道路不通的孤点要等下一次机会",
		"relation":"连接",
		"duration_phrases":4,
		"bonus":"道路优先"
	},
	"anchor_bloom": {
		"title":"锚点回响",
		"tendency":"已有公园或文化馆影响内的候选更有资格",
		"tradeoff":"公共影响外不增加额外优先级",
		"relation":"吸引",
		"duration_phrases":3,
		"bonus":"关系优先"
	}
}

const DEFAULT_ID := "infill_pulse"

static func _stable_hash(value: String) -> int:
	var result := 17
	for character in value:
		result = int((result*31+character.unicode_at(0)) & 0x7fffffff)
	return result

static func choices(world: RefCounted,plan_id: String) -> Array[String]:
	# A tiny deterministic draw: the same seed/phrase/plan always offers the
	# same two or three cards, while a new chapter or seed can rotate the set.
	var ids: Array[String] = ["infill_pulse","road_echo","anchor_bloom"]
	var key := str(world.rng.seed_hex)+":"+str(world.phrase_index)+":"+str(world.action_serial)+":"+plan_id
	var pivot := _stable_hash(key)
	var first := posmod(pivot,ids.size())
	var second := posmod(pivot/7+1,ids.size())
	if second == first: second = posmod(second+1,ids.size())
	var result: Array[String] = [ids[first],ids[second]]
	if posmod(pivot,3) == 0:
		var third := posmod(pivot/13+2,ids.size())
		if not result.has(ids[third]): result.append(ids[third])
	return result

static func valid(id: String) -> bool:
	return CARDS.has(id)

static func definition(id: String) -> Dictionary:
	return CARDS.get(id,{}).duplicate(true)

static func normalize_refs(raw: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw is Array:
		for value in raw:
			var id := str(value)
			if valid(id) and not result.has(id): result.append(id)
	return result

static func active(charter: Dictionary,world: RefCounted,id: String) -> bool:
	if not valid(id): return false
	var refs := normalize_refs(charter.get("card_refs",[]))
	if not refs.has(id): return false
	var duration := int(CARDS[id].get("duration_phrases",0))
	var age := int(world.phrase_index)-int(charter.get("committed_phrase",world.phrase_index))
	return age >= 0 and age < duration

static func active_refs(charter: Dictionary,world: RefCounted) -> Array[String]:
	var result: Array[String] = []
	for id in normalize_refs(charter.get("card_refs",[])):
		if active(charter,world,id): result.append(id)
	return result

static func relation_strength(world: RefCounted,cid: String,p: Vector2) -> float:
	# This mirrors the existing planning influence edge rule but remains local
	# to the card module, avoiding a second growth or acoustic system.
	var strength := 0.0
	for site in world.near_public_sites(p,6.0):
		if not bool(site.get("active",false)): continue
		var center := Vector2(float(site["position"][0]),float(site["position"][1]))
		var radius := float(site.get("influence_config",{}).get("planning_radius",6.0 if site.get("kind","") == "civic" else 5.0))
		var distance := center.distance_to(p)
		if distance > radius: continue
		var entrance := Vector2(float(site["entrance"][0]),float(site["entrance"][1]))
		if world.network.walking_distance(entrance,p) > float(world.cfg["city"]["service_walk_radius"]): continue
		strength = maxf(strength,1.0-distance/radius)
	return strength

static func priority_bonus(world: RefCounted,charter: Dictionary,cid: String,p: Vector2,compact_neighbors: int) -> float:
	var total := 0.0
	for id in active_refs(charter,world):
		match id:
			"infill_pulse":
				if compact_neighbors > 0:
					total += 7000.0*float(mini(compact_neighbors,4))/4.0
			"road_echo":
				var road_strength := 0.0
				for segment in world.near_road_segments(p,2.0):
					var q := Geometry2D.get_closest_point_to_segment(p,segment["a"],segment["b"])
					road_strength = maxf(road_strength,maxf(0.0,1.0-p.distance_to(q)/2.0))
				total += 6000.0*road_strength
				total += 1500.0*minf(1.0,float(world._transit_growth_bonus(p)))
			"anchor_bloom":
				# A full-capacity civic site naturally contributes no strength via
				# the existing growth relation; this card follows that same rule.
				total += 9000.0*relation_strength(world,cid,p)
	return total

static func growth_delay(world: RefCounted,charter: Dictionary,p: Vector2,base_delay: int,tier: String) -> int:
	var result := base_delay
	for id in active_refs(charter,world):
		if id == "road_echo" and not world.near_road_segments(p,2.0).is_empty(): result = maxi(1,result-1)
		if id == "anchor_bloom" and tier == "L3" and relation_strength(world,"",p) <= 0.0: result = maxi(result,base_delay+1)
	return result

static func summary(charter: Dictionary,world: RefCounted) -> String:
	var names: Array[String] = []
	for id in active_refs(charter,world): names.append(str(CARDS[id]["title"]))
	return "、".join(names)
