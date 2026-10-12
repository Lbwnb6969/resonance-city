extends RefCounted
## Actual classical public land, retained in World coordinates. No new site or service.
const PublicGeometry = preload("res://scripts/visual/public_space_visual_geometry.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Miniature = preload("res://scripts/visual/miniature_valley_material.gd")
var courts: Dictionary = {}
var key: Array = []
var rebuild_count := 0
var last_build_ms := 0.0

static func applies(world: RefCounted,site: Dictionary,style: String = "baseline") -> bool:
	if style != "baseline" or world.terrain.family != "river_valley": return false
	if str(site["kind"]) != "civic" or not bool(site["active"]): return false
	var phrase := int(site.get("created_phrase",int(site["frame"])/int(world.cfg["timing"]["phrase_frames"])))
	return world.era_for_phrase(phrase) == 1

func sync(world: RefCounted,audible_frame: float,style: String = "baseline") -> void:
	var sites: Array[Dictionary] = []
	var next: Array = [world.terrain.noise_seed,world.terrain.river_phase,world.terrain.family,
		hash(world.cfg["terrain"]),world.road_index_identity,world.parcel_index_identity,style]
	for site: Dictionary in world.public_sites:
		if not applies(world,site,style) or float(site["frame"]) > audible_frame: continue
		sites.append(site)
		next.append([site["id"],PublicGeometry.identity(site),site["position"],site["entrance"],site["frame"],site.get("created_phrase",-1)])
	for building: Dictionary in world.buildings:
		next.append([building["district_id"],Coupling.position_of(building)])
	if key == next: return
	key = next
	courts.clear()
	rebuild_count += 1
	var began := Time.get_ticks_usec()
	if not sites.is_empty():
		var excluded := _exclusions(world)
		for site: Dictionary in sites:
			var layouts: Array[Dictionary] = []
			var component_index := 0
			for component: Dictionary in PublicGeometry.components(site):
				var fill: Array[PackedVector2Array] = []
				for piece: PackedVector2Array in component["pieces"]:
					fill.append_array(PartialPublic._subtract_components(piece,excluded))
				if not fill.is_empty(): layouts.append(_layout(site,component,fill,component_index))
				component_index += 1
			if not layouts.is_empty(): courts[str(site["id"])] = layouts
	last_build_ms = float(Time.get_ticks_usec()-began)/1000.0

static func _exclusions(world: RefCounted) -> Array[PackedVector2Array]:
	var excluded: Array[PackedVector2Array] = [world.terrain.water]
	for road: Dictionary in world.roads:
		excluded.append_array(Geometry2D.offset_polyline(road["path"],Miniature.road_width(world,road),Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT))
	for building: Dictionary in world.buildings:
		excluded.append(world.building_polygon(Coupling.position_of(building)))
	for lot: Dictionary in world.lots:
		if not str(lot["occupant"]).is_empty(): excluded.append(lot["polygon"])
	for reservation: Dictionary in world.planning_reservations:
		excluded.append_array(Spatial.footprint_components(reservation))
	return excluded

static func _layout(site: Dictionary,component: Dictionary,fill: Array[PackedVector2Array],component_index: int) -> Dictionary:
	var p: Vector2 = component["position"]
	var entrance := Vector2(float(site["entrance"][0]),float(site["entrance"][1]))
	var front := p.direction_to(entrance)
	# A real entrance normally lies on the road. Coincident legacy entrances
	# have no invented approach path; the stone courses use the World axes.
	var along := Vector2(-front.y,front.x) if front != Vector2.ZERO else Vector2.RIGHT
	var courses := front if front != Vector2.ZERO else Vector2.DOWN
	var first: Vector2 = fill[0][0]-p
	var bounds := Rect2(Vector2(first.dot(along),first.dot(courses)),Vector2.ZERO)
	for piece: PackedVector2Array in fill:
		for vertex: Vector2 in piece:
			bounds = bounds.expand(Vector2((vertex-p).dot(along),(vertex-p).dot(courses)))
	var joints: Array[PackedVector2Array] = []
	const COURSE := 0.32
	const STONE := 0.44
	for row in range(floori(bounds.position.y/COURSE),ceili(bounds.end.y/COURSE)+1):
		var y := float(row)*COURSE
		if y > bounds.position.y+0.015 and y < bounds.end.y-0.015:
			joints.append_array(_clip_line(PackedVector2Array([p+along*bounds.position.x+courses*y,p+along*bounds.end.x+courses*y]),fill))
		for column in range(floori(bounds.position.x/STONE)-1,ceili(bounds.end.x/STONE)+1):
			var x := float(column)*STONE+(STONE*0.5 if posmod(row,2) == 1 else 0.0)
			joints.append_array(_clip_line(PackedVector2Array([p+along*x+courses*y,p+along*x+courses*(y+COURSE)]),fill))
	var paths: Array[PackedVector2Array] = []
	if front != Vector2.ZERO:
		var walk := PackedVector2Array([p,p+front*minf(p.distance_to(entrance),1.35)])
		for strip: PackedVector2Array in Geometry2D.offset_polyline(walk,0.115,Geometry2D.JOIN_MITER,Geometry2D.END_BUTT):
			for piece: PackedVector2Array in fill:
				paths.append_array(Geometry2D.intersect_polygons(strip,piece))
	return {"site_id":str(site["id"]),"component_index":component_index,"position":p,
		"entrance":entrance,"front":front,"pieces":fill,"joints":joints,"paths":paths}

static func _clip_line(line: PackedVector2Array,fill: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for piece: PackedVector2Array in fill:
		for part: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(line,piece):
			if part.size() < 2 or part[0].distance_squared_to(part[-1]) <= 0.000001: continue
			# Keep the half-width of a fine stone joint off the outer/hole edge.
			var trim := minf(0.015,part[0].distance_to(part[-1])*0.25)
			var direction := part[0].direction_to(part[-1])
			part[0] += direction*trim
			part[-1] -= direction*trim
			result.append(part)
	return result
