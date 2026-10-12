extends RefCounted
## Fine natural ground for the first-era river valley.
##
## This helper owns only derived presentation geometry.  Terrain vertices,
## roads, lots, public footprints and the audio/world snapshot remain owned by
## their callers.  The large texture is generated from a small real-terrain
## sample grid, then filtered to keep preparation bounded and zoomed views
## stable.
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const TEXTURE_SIZE := 2048
const SAMPLE_SIZE := 192
const MAX_TUFTS := 96
const MAX_STONES := 44
const TUFT_RADIUS := 0.11
const STONE_RADIUS := 0.075

var terrain_cache_key: Array = []
var terrain_bounds := Rect2()
var land_material: Array[Dictionary] = []
var land_texture: Texture2D
var prepare_count := 0
var prepare_ms := 0.0
var key: Array = []
var geometry: Dictionary = {"tufts":[],"stones":[]}
var rebuild_count := 0
var spatial_query_count := 0
var _terrain: RefCounted

func prepare_terrain(terrain: RefCounted,surfaces: Array) -> void:
	var next := [terrain.family,terrain.noise_seed,terrain.river_phase,
		hash(terrain.cfg),surfaces]
	if next == terrain_cache_key: return
	var started := Time.get_ticks_usec()
	terrain_cache_key = next.duplicate(true)
	_terrain = terrain
	land_material.clear()
	land_texture = null
	if surfaces.is_empty():
		prepare_count += 1
		prepare_ms = float(Time.get_ticks_usec()-started)/1000.0
		return
	terrain_bounds = _surface_bounds(surfaces)
	if terrain_bounds.size.x <= 0.001 or terrain_bounds.size.y <= 0.001:
		prepare_count += 1
		prepare_ms = float(Time.get_ticks_usec()-started)/1000.0
		return
	var sample := Image.create(SAMPLE_SIZE,SAMPLE_SIZE,false,Image.FORMAT_RGBA8)
	for y in range(SAMPLE_SIZE):
		for x in range(SAMPLE_SIZE):
			var p := terrain_bounds.position+Vector2(
				(float(x)+0.5)/float(SAMPLE_SIZE)*terrain_bounds.size.x,
				(float(y)+0.5)/float(SAMPLE_SIZE)*terrain_bounds.size.y)
			sample.set_pixel(x,y,_surface_color(terrain,p))
	# The authored terrain contract requires an HD texture.  Resampling from a
	# bounded real-height grid avoids millions of duplicate height queries while
	# preserving continuous low-frequency relief and mip-friendly filtering.
	sample.resize(TEXTURE_SIZE,TEXTURE_SIZE,Image.INTERPOLATE_BILINEAR)
	sample.generate_mipmaps()
	land_texture = ImageTexture.create_from_image(sample)
	for surface: Dictionary in surfaces:
		var polygon: PackedVector2Array = surface["polygon"]
		var uvs := PackedVector2Array()
		var colors := PackedColorArray()
		for p: Vector2 in polygon:
			uvs.append(Vector2(
				clampf((p.x-terrain_bounds.position.x)/terrain_bounds.size.x,0.0,1.0),
				clampf((p.y-terrain_bounds.position.y)/terrain_bounds.size.y,0.0,1.0)))
			colors.append(Color.WHITE)
		land_material.append({"polygon":polygon,"side":int(surface.get("side",0)),"colors":colors,"uvs":uvs})
	prepare_count += 1
	prepare_ms = float(Time.get_ticks_usec()-started)/1000.0

func sync(city: RefCounted,heard_frame: int) -> bool:
	var next := _city_key(city,heard_frame)
	if next == key: return false
	key = next.duplicate(true)
	var started := Time.get_ticks_usec()
	geometry = {"tufts":[],"stones":[]}
	rebuild_count += 1
	if city == null or int(city.era) != 1 or city.terrain.family != "river_valley":
		return true
	var blocked := _blocked_geometry(city,heard_frame)
	var bounds := terrain_bounds if _terrain == city.terrain and terrain_bounds.size.x > 0.001 else _terrain_bounds(city.terrain)
	var phase := int(city.terrain.noise_seed)
	var tuft_index := 0
	var stone_index := 0
	# Candidate samples are stable world-space presentation data. They never
	# call a World RNG stream and stop as soon as the strict caps are reached.
	for index in range(1700):
		var p := _candidate(bounds,phase,index,0.17)
		if _clear_disc(city,p,TUFT_RADIUS,blocked):
			var tuft := _tuft(p,phase,index)
			var valid := true
			for path: PackedVector2Array in tuft["paths"]:
				for point in path:
					if not _clear_disc(city,point,0.018,blocked): valid = false
			if valid:
				geometry["tufts"].append(tuft)
				tuft_index += 1
				if tuft_index >= MAX_TUFTS: break
		if tuft_index >= MAX_TUFTS: break
		var stone_p := _candidate(bounds,phase,index,0.61)
		if stone_index < MAX_STONES and _clear_disc(city,stone_p,STONE_RADIUS,blocked):
			var stone := _stone(stone_p,phase,index)
			var valid_stone := true
			for point in stone["polygon"]:
				if not _clear_disc(city,point,0.012,blocked): valid_stone = false
			if valid_stone:
				geometry["stones"].append(stone)
				stone_index += 1
		if tuft_index >= MAX_TUFTS and stone_index >= MAX_STONES: break
	# Keep diagnostics available to the owner without adding a World field.
	geometry["tuft_count"] = geometry["tufts"].size()
	geometry["stone_count"] = geometry["stones"].size()
	geometry["build_ms"] = float(Time.get_ticks_usec()-started)/1000.0
	return true

func _city_key(city: RefCounted,heard_frame: int) -> Array:
	if city == null: return ["empty"]
	var result: Array = [city.terrain.family,city.terrain.noise_seed,city.terrain.river_phase,
		hash(city.terrain.cfg),int(city.era),city.road_index_identity,city.parcel_index_identity]
	var heard_ids: Array[String] = []
	for building: Dictionary in city.buildings:
		if int(building.get("birth_frame",0)) > heard_frame: continue
		var id := str(building["district_id"])
		heard_ids.append(id)
		result.append([id,building.get("position",[]),building.get("radius",0.0),building.get("lot_id","")])
	result.append(heard_ids)
	for road: Dictionary in city.roads:
		result.append([road.get("id",""),road.get("path",PackedVector2Array()),road.get("bridge",false),road.get("kind","")])
	for group: Array in [city.public_sites,city.planning_reservations]:
		for record: Dictionary in group:
			if int(record.get("frame",0)) > heard_frame: continue
			result.append([record.get("id",""),record.get("active",true),
				Spatial.footprint_components(record),Spatial.footprint_holes(record)])
	return result

func _blocked_geometry(city: RefCounted,heard_frame: int) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for building: Dictionary in city.buildings:
		if int(building.get("birth_frame",0)) > heard_frame: continue
		result.append(city.building_polygon(_position(building)))
		var lot_id := str(building.get("lot_id",""))
		for lot: Dictionary in city.lots:
			if str(lot.get("id","")) == lot_id and str(lot.get("occupant","")) == str(building["district_id"]): result.append(lot["polygon"])
	for road: Dictionary in city.roads:
		if bool(road.get("bridge",false)): continue
		for polygon in Geometry2D.offset_polyline(road["path"],_road_width(city,road),Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT): result.append(polygon)
	for group: Array in [city.public_sites,city.planning_reservations]:
		for record: Dictionary in group:
			if int(record.get("frame",0)) > heard_frame: continue
			var components := Spatial.footprint_components(record)
			var holes := Spatial.footprint_holes(record)
			if holes.is_empty():
				result.append_array(components)
			else:
				for component: PackedVector2Array in components: result.append_array(PartialPublic._subtract_components(component,holes))
	return result

func _clear_disc(city: RefCounted,p: Vector2,radius: float,blocked: Array[PackedVector2Array]) -> bool:
	spatial_query_count += 1
	if not city.terrain.land_at(p): return false
	var disc := Spatial.circle_polygon(p,radius)
	for polygon: PackedVector2Array in blocked:
		if Spatial.overlaps(disc,polygon): return false
	return true

func _surface_bounds(surfaces: Array) -> Rect2:
	var result := Rect2()
	var first := true
	for surface: Dictionary in surfaces:
		for p: Vector2 in surface["polygon"]:
			if first: result = Rect2(p,Vector2.ZERO); first = false
			else: result = result.expand(p)
	return result.grow(0.05)

func _terrain_bounds(terrain: RefCounted) -> Rect2:
	var points: PackedVector2Array = terrain.left_bank.duplicate()
	points.append_array(terrain.right_bank)
	return _surface_bounds([{"polygon":points}])

func _position(building: Dictionary) -> Vector2:
	var raw: Array = building.get("position",[0.0,0.0])
	return Vector2(float(raw[0]),float(raw[1]))

func _candidate(bounds: Rect2,phase: int,index: int,offset: float) -> Vector2:
	var a := fposmod(float(index)*0.754877666+float(phase)*0.000013+offset,1.0)
	var b := fposmod(float(index)*0.569840291+float(phase)*0.000021+offset*1.7,1.0)
	return bounds.position+Vector2(a,b)*bounds.size

func _tuft(p: Vector2,phase: int,index: int) -> Dictionary:
	var scale := 0.75+_noise(p*2.0+Vector2(phase%31,index%17))*0.35
	var paths: Array[PackedVector2Array] = []
	for branch in range(3):
		var angle := -0.75+float(branch)*0.72+_noise(p+Vector2(branch,index))*0.18
		var tip := p+Vector2(cos(angle),sin(angle))*0.13*scale
		paths.append(PackedVector2Array([p,p.lerp(tip,0.55)+Vector2(0,-0.01),tip]))
	var c := Color("788763").lerp(Color("a9b28d"),0.35+_noise(p)*0.22)
	return {"paths":paths,"color":Color(c,0.28)}

func _stone(p: Vector2,phase: int,index: int) -> Dictionary:
	var r := 0.035+0.025*(0.5+_noise(p+Vector2(index,phase))*0.5)
	var polygon := PackedVector2Array()
	for i in range(5):
		var rr := r*(0.82+0.28*_noise(p+Vector2(i,index)))
		polygon.append(p+Vector2(cos(TAU*float(i)/5.0),sin(TAU*float(i)/5.0))*rr)
	var color := Color("aaa58d").lerp(Color("c5b898"),0.35+_noise(p)*0.25)
	return {"polygon":polygon,"color":Color(color,0.54)}

func _surface_color(terrain: RefCounted,p: Vector2) -> Color:
	var height: float = terrain.height_at(p)
	var dx: float = terrain.height_at(p+Vector2(0.18,0))-terrain.height_at(p-Vector2(0.18,0))
	var dy: float = terrain.height_at(p+Vector2(0,0.18))-terrain.height_at(p-Vector2(0,0.18))
	var slope: float = clampf(Vector2(dx,dy).length()/0.36,0.0,1.0)
	var river_center: float = terrain.river_x(p.y)
	var shore_distance: float = absf(p.x-river_center)-terrain.river_width(p.y)
	var wet := 1.0-smoothstep(0.05,1.35,maxf(0.0,shore_distance))
	var grass := Color("aeb690")
	var soil := Color("d1c3a2")
	var high := smoothstep(0.2,1.6,height)
	var color := soil.lerp(grass,clampf(high*0.62+slope*0.12,0.0,1.0))
	color = Color("aeb49b").lerp(color,1.0-wet*0.38)
	var grain := (_noise(p*3.7)-0.5)*0.045
	return Color(clampf(color.r+grain,0.0,1.0),clampf(color.g+grain,0.0,1.0),clampf(color.b+grain*0.75,0.0,1.0))

func _noise(p: Vector2) -> float:
	return fposmod(sin(p.dot(Vector2(12.9898,78.233)))*43758.5453,1.0)

func _road_width(city: RefCounted,road: Dictionary) -> float:
	return float(city.cfg["city"]["branch_road_half_width"]) if str(road.get("kind","")) == "branch" else float(city.cfg["terrain"]["template_road_half_width"])
