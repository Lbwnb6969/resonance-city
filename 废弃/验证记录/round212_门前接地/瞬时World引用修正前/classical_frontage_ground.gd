extends RefCounted
## Thin thresholds and worn soil inside an actual heard house's existing lot.
## These surfaces create no road, parcel, occupancy or pedestrian connection.
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Orientation = preload("res://scripts/visual/building_street_orientation.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
# Outermost bottom step, authored in build_refined_valley_art.py::steps.
# Courtyard uses the open court's outer steps, never its recessed inner door.
const STEPS := {
	"terrace":{"center":Vector2(-0.26,0.63),"width":0.29},
	"gabled":{"center":Vector2(-0.25,0.645),"width":0.30},
	"courtyard":{"center":Vector2(0,0.57),"width":0.29},
	"commercial":{"center":Vector2(0,0.64),"width":0.25},
}
var key: Array = []
var pads: Array[Dictionary] = []
var rebuild_count := 0
var spatial_query_count := 0

func sync(demo: Control) -> bool:
	var city: RefCounted = demo.shown_world
	var style := str(demo.art_direction.selected_id)
	var next_key: Array = [city,style]
	var sources: Array[Dictionary] = []
	if city != null and city.terrain.family == "river_valley" and style == "baseline":
		next_key.append([city.terrain.noise_seed,city.terrain.river_phase,city.road_index_identity,city.parcel_index_identity])
		var heard_frame: int = demo.clock.renderer.transport.audible_frame
		for building: Dictionary in city.buildings:
			var id := str(building["district_id"])
			if int(building.get("era",1)) != 1 or not demo.building_geometry.has(id) or not demo.sprites.has(id): continue
			if int(building["birth_frame"]) > heard_frame or float(demo.sprites[id].progress) < 1.0: continue
			var geometry: Dictionary = demo.building_geometry[id]
			var entry: Dictionary = geometry["entry"]
			if not bool(entry.get("refined_valley",false)) or not STEPS.has(str(entry.get("role",""))): continue
			next_key.append([id,Coupling.position_of(building),building["radius"],str(building.get("lot_id","")),entry["id"],entry["orientation"],geometry["scale"],entry["pixels_per_world"]])
			sources.append({"building":building,"geometry":geometry})
	if next_key == key: return false
	key = next_key
	pads.clear()
	rebuild_count += 1
	for source: Dictionary in sources: _make(city,source["building"],source["geometry"])
	return true

func _make(city: RefCounted,building: Dictionary,geometry: Dictionary) -> void:
	var entry: Dictionary = geometry["entry"]
	var root := Coupling.position_of(building)
	var spec: Dictionary = STEPS[str(entry["role"])]
	var factor := float(geometry["scale"])*float(entry["pixels_per_world"])/(28.0*sqrt(2.0))
	var orientation := int(entry["orientation"])
	var front: Vector2 = Orientation.FACING[orientation]
	var along := _rotated(Vector2.RIGHT,orientation)
	var foot := root+_rotated(spec["center"],orientation)*factor
	var width := float(spec["width"])*factor
	var source: Dictionary = {}
	var lot_id := str(building.get("lot_id",""))
	spatial_query_count += 1
	for lot: Dictionary in city.near_lots(root):
		if str(lot["id"]) == lot_id and str(lot.get("occupant","")) == str(building["district_id"]):
			source = lot
			break
	# Free land receives only a threshold inside the already-owned radius.
	# A committed lot can receive short wear, but its external gap stays bare.
	var owned: PackedVector2Array = source["polygon"] if not source.is_empty() else Spatial.circle_polygon(root,float(building["radius"])-0.002)
	var road_masks := _road_masks(city,owned)
	var base := {"building_id":str(building["district_id"]),"entry_id":str(entry["id"]),"orientation":orientation,"lot_id":lot_id,
		"step_front":foot,"entrance":source.get("entrance",[]),"road_id":str(source.get("road_id",""))}
	var threshold := _strip(foot-front*0.009,foot+front*0.062,along,width*0.5,width*0.5)
	if not _append(city,threshold,owned,road_masks,base,"threshold",Color("cfbf9e",0.68)): return
	var raw: Array = source.get("entrance",[])
	if raw.size() != 2: return
	var entrance := Vector2(float(raw[0]),float(raw[1]))
	var access := _road_access(city,foot,entrance,str(source.get("road_id","")))
	if access.is_empty(): return
	var toward := entrance-foot
	if toward.length() < 0.08 or toward.normalized().dot(front) < 0.65: return
	var direction := toward.normalized()
	var across := Vector2(-direction.y,direction.x)
	# Limit the worn apron to a small extension of the threshold, not a path.
	var length := minf(0.18,maxf(0.0,float(access["gap"])-0.075))
	if length < 0.07: return
	base["road_id"] = access["road_id"]
	for index in range(3):
		var t0 := float(index)/3.0
		var t1 := float(index+1)/3.0
		var start := foot+direction*(0.040+length*t0)
		var finish := foot+direction*(0.040+length*t1)
		var candidate := _strip(start,finish,across,width*lerpf(0.48,0.28,t0),width*lerpf(0.48,0.28,t1))
		if not _append(city,candidate,owned,road_masks,base,"wear",Color("a99370",lerpf(0.20,0.06,t1))): break

func _append(city: RefCounted,candidate: PackedVector2Array,owned: PackedVector2Array,road_masks: Array[PackedVector2Array],base: Dictionary,kind: String,color: Color) -> bool:
	var before := pads.size()
	for polygon: PackedVector2Array in Geometry2D.intersect_polygons(candidate,owned):
		if polygon.size() < 3 or Spatial.polygon_area(polygon) < 0.00001: continue
		if not _legal(city,polygon,str(base["building_id"]),road_masks): continue
		var pad := base.duplicate()
		pad["polygon"] = polygon
		pad["kind"] = kind
		pad["color"] = color
		pads.append(pad)
	return pads.size() > before

func _legal(city: RefCounted,polygon: PackedVector2Array,owner_id: String,road_masks: Array[PackedVector2Array]) -> bool:
	spatial_query_count += 1
	if not Spatial.exclusion(city,polygon).is_empty(): return false
	var box := Spatial.bounds(polygon)
	var center := box.get_center()
	var reach := box.size.length()*0.5
	# Public holes are deliberately empty; exclusion() treats them as outside
	# the public solid, so they require a separate presentation exclusion here.
	for site: Dictionary in city.near_public_sites(center,reach):
		for hole: PackedVector2Array in Spatial.footprint_holes(site):
			if Spatial.overlaps(polygon,hole): return false
	for road: PackedVector2Array in road_masks:
		if Spatial.overlaps(polygon,road): return false
	for id: String in city.index.query_circle(center,reach):
		if id == owner_id: continue
		var other: Dictionary = city.by_id[id]
		if Spatial.disc_hits(polygon,Coupling.position_of(other),float(other["radius"])): return false
	return true

func _road_masks(city: RefCounted,owned: PackedVector2Array) -> Array[PackedVector2Array]:
	spatial_query_count += 1
	var box := Spatial.bounds(owned)
	var roads: Dictionary = {}
	var result: Array[PackedVector2Array] = []
	for segment: Dictionary in city.near_road_segments(box.get_center(),box.size.length()*0.5+0.55):
		var road: Dictionary = segment["road"]
		roads[str(road["id"])] = road
	for road: Dictionary in roads.values():
		for polygon: PackedVector2Array in Geometry2D.offset_polyline(road["path"],Fabric._road_width(city,road),Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT): result.append(polygon)
	return result

func _road_access(city: RefCounted,foot: Vector2,entrance: Vector2,preferred: String) -> Dictionary:
	spatial_query_count += 1
	var best: Dictionary = {}
	var distance := INF
	for segment: Dictionary in city.near_road_segments(entrance,1.0):
		var road: Dictionary = segment["road"]
		if bool(road.get("bridge",false)) or (not preferred.is_empty() and str(road["id"]) != preferred): continue
		var q := Geometry2D.get_closest_point_to_segment(entrance,segment["a"],segment["b"])
		var gap := entrance.distance_squared_to(q)
		if gap >= distance: continue
		if not Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([foot,q]),city.terrain.water).is_empty(): continue
		distance = gap
		var nearest := Geometry2D.get_closest_point_to_segment(foot,segment["a"],segment["b"])
		best = {"road_id":str(road["id"]),"gap":foot.distance_to(nearest)-Fabric._road_width(city,road)}
	return best

static func _rotated(p: Vector2,orientation: int) -> Vector2:
	var angle := PI-float(orientation)*PI*0.5
	return Vector2(cos(angle)*p.x+sin(angle)*p.y,-sin(angle)*p.x+cos(angle)*p.y)

static func _strip(start: Vector2,finish: Vector2,across: Vector2,half_start: float,half_finish: float) -> PackedVector2Array:
	return PackedVector2Array([start-across*half_start,start+across*half_start,finish+across*half_finish,finish-across*half_finish])

func diagnostics() -> Dictionary:
	return {"pads":pads.size(),"rebuild_count":rebuild_count,"spatial_query_count":spatial_query_count}
