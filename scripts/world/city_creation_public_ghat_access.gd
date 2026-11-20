extends RefCounted
## A live street can lead to the dry treads of a real water-facing stone landing.
const Ghat = preload("res://scripts/world/city_creation_water_ghat.gd")
const Boundary = preload("res://scripts/world/city_creation_shore_boundary.gd")
const Street = preload("res://scripts/world/city_creation_public_shore_route.gd")

static func entries(city: RefCounted, house: Dictionary, component: String, faces: Array, ports: Array, context: Dictionary) -> Array:
	var result: Array = []
	if ports.is_empty(): return result
	if not context.has("public_stone_landings"):
		context.public_stone_landings = _landings(city)
	for landing: Dictionary in context.public_stone_landings:
		if landing.component != component: continue
		var plan: Dictionary = landing.plan
		var relevant := faces.filter(func(face): return _same_shore(face, landing))
		if relevant.is_empty(): continue
		var face: Dictionary = relevant[0]
		for port: Dictionary in ports:
			var route := Street.find(city, component, port.street_at, plan.at, port.road_id, plan.road_id, context.obstacles)
			if not route.ok: continue
			result.append({
				"house_id": house.id, "cell_id": port.entry.cell_id, "face_cell_id": face.cell_id,
				"road_id": port.road_id, "face_road_id": plan.road_id, "water_id": face.water_id,
				"at": port.entry.at, "street_at": port.street_at, "face_street_at": plan.at,
				"height_access": port.height_access, "street_path": route, "ground_access": true,
				"surface": "public_stone_steps", "ghat_id": plan.id, "dry_treads": plan.steps.slice(0, 2),
				"water_boundary": landing.bank, "water_ids": landing.water_ids,
			})
	return result

static func _landings(city: RefCounted) -> Array:
	var result: Array = []
	for attachment: Dictionary in city._region_network.get("stone_landings", []):
		var plan: Dictionary = attachment.plan
		var dry: Dictionary = plan.steps[1]
		var last: Dictionary = plan.steps[-1]
		if dry.y <= Ghat.WATER + .04 or last.y >= Ghat.WATER: continue
		var land: Vector2 = plan.at - Vector2(plan.normal) * .35
		var wet: Vector2 = last.center
		if city.water_clearance(land) <= 0. or city.water_clearance(wet) >= 0.: continue
		for i in range(16):
			var middle := land.lerp(wet, .5)
			if city.water_clearance(middle) > 0.: land = middle
			else: wet = middle
		var bank := land.lerp(wet, .5)
		var waters := Boundary.sources(city, bank)
		if not waters.is_empty():
			result.append({"plan": plan, "bank": bank, "water_ids": waters, "component": attachment.component})
	return result

static func _same_shore(face: Dictionary, landing: Dictionary) -> bool:
	var to_bank: Vector2 = face.bank - face.wall_at
	var to_landing: Vector2 = landing.bank - face.wall_at
	return (
		to_landing.length() <= 5.2
		and to_bank.normalized().dot(to_landing.normalized()) >= .72
		and to_bank.normalized().dot(landing.plan.normal) >= .72
		and face.water_ids.any(func(id): return id in landing.water_ids)
	)
