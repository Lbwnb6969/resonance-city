extends RefCounted
## Natural groves derive from the real banks. No occupancy or city RNG writes.
const Planning = preload("res://scripts/world/city_spatial_planning.gd")

static func build(city: RefCounted) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var length := float(city.terrain.cfg.get("template_land_max_y",city.terrain.cfg["template_land_max"]))
	var phase := float(posmod(hash(str(city.terrain.noise_seed)),1000))*0.001*TAU
	var ordinal := 0
	for side: float in [-1.0,1.0]:
		for cluster in range(5):
			var y := 3.0+(length-6.0)*(float(cluster)+0.18)/5.0
			var centre := Vector2(city.terrain.river_x(y)+side*(float(city.cfg["terrain"]["template_road_bank_offset"])+4.5+sin(phase+cluster)*0.9),y)
			for member in range(9):
				var angle := float(member)*2.399963+phase+cluster*0.7
				var radius := sqrt(float(member)+0.25)*0.72
				var p := centre+Vector2(cos(angle)*radius,sin(angle)*radius*0.75)
				if not clear(city,p): continue
				if records.any(func(record: Dictionary) -> bool: return p.distance_squared_to(record["position"]) < 0.45*0.45): continue
				records.append({"id":"grove-%d" % ordinal,"position":p,"kind":"rock" if member == 0 and cluster%2 == 0 else "tree","tone":cluster+member,"scale":0.82+float(posmod(cluster*7+member*3,5))*0.055})
				ordinal += 1
	return records

static func clear(city: RefCounted,p: Vector2) -> bool:
	if not city.terrain.land_at(p): return false
	for offset: Vector2 in [Vector2(0.38,0),Vector2(-0.38,0),Vector2(0,0.38),Vector2(0,-0.38)]:
		if not city.terrain.land_at(p+offset): return false
	for id: String in city.index.query_circle(p,0.95):
		var raw: Array = city.by_id[id]["position"]
		if p.distance_to(Vector2(float(raw[0]),float(raw[1]))) < 0.9: return false
	for id: String in city.parcel_index.query_circle(p,0.4):
		if id.begins_with("lot-") and Planning.disc_hits(city.lots[int(city.parcel_records[id])]["polygon"],p,0.40): return false
		if id.begins_with("reservation-") and Planning.disc_hits(city.planning_reservations[int(city.parcel_records[id])]["polygon"],p,0.40): return false
	for site: Dictionary in city.near_public_sites(p,0.4):
		for offset: Vector2 in [Vector2.ZERO,Vector2(0.4,0),Vector2(-0.4,0),Vector2(0,0.4),Vector2(0,-0.4)]:
			if Planning.point_in_footprint(site,p+offset): return false
	var access: Dictionary = city.network.access(p)
	return access.is_empty() or float(access["gap"]) >= 0.65
