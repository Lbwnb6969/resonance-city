extends Node2D
## Small lived-in objects belong to real, audible classical houses, never previews.
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Projection2D = preload("res://scripts/world/world_projection.gd")
const Orientation = preload("res://scripts/visual/building_street_orientation.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
const MAX_HOUSES := 28
const AXES := Vector2(28,14)
const VERTICAL := 28.0*sqrt(1.5)
var layouts: Dictionary = {}
var geometry_key: Array = []
var rebuild_count := 0
var placement_query_count := 0

class FrontagePiece extends Node2D:
	var house_id := ""
	var kind := ""
	var world_position := Vector2.ZERO
	var footprint := PackedVector2Array()
	var orientation := 0
	var faces: Array[Dictionary] = []
	var shadows: Array[PackedVector2Array] = []
	func _draw() -> void:
		for shadow in shadows: draw_colored_polygon(shadow,Color(0.16,0.22,0.18,0.15))
		for face: Dictionary in faces: draw_colored_polygon(face["polygon"],face["color"])

func setup(owner: Control) -> void:
	position = Vector2.ZERO
	scale = Vector2.ONE
	y_sort_enabled = true
	sync(owner)

func sync(owner: Control) -> void:
	visible = not owner.black
	var city: RefCounted = owner.shown_world
	if city == null:
		_clear()
		geometry_key.clear()
		return
	# These identities are maintained by World. No per-frame road/parcel scan.
	var key: Array = owner._shown_city_key()+[city.era,city.buildings.size(),city.road_index_identity,city.parcel_index_identity]
	var sources: Array[Dictionary] = []
	for building: Dictionary in city.buildings:
		var id := str(building["district_id"])
		if int(building.get("era",1)) != 1 or str(building["type"]) not in ["residential","commercial"]: continue
		if not owner.building_geometry.has(id): continue
		var geometry: Dictionary = owner.building_geometry[id]
		var entry: Dictionary = geometry["entry"]
		if not bool(entry.get("refined_valley",false)): continue
		key.append([id,geometry["key"]])
		sources.append(building)
		if sources.size() == MAX_HOUSES: break
	if key != geometry_key:
		_clear()
		geometry_key = key
		rebuild_count += 1
		for building: Dictionary in sources: _make_frontage(city,owner,building)
	var frame: int = owner.clock.renderer.transport.audible_frame
	for id: String in layouts:
		var heard: bool = city.by_id.has(id) and owner.sprites.has(id)
		if heard:
			heard = int(city.by_id[id]["birth_frame"]) <= frame and float(owner.sprites[id].progress) >= 1.0
		for piece: FrontagePiece in layouts[id]["pieces"]: piece.visible = heard

func _clear() -> void:
	for layout: Dictionary in layouts.values():
		for piece: FrontagePiece in layout["pieces"]:
			remove_child(piece)
			piece.queue_free()
	layouts.clear()

func _make_frontage(city: RefCounted,owner: Control,building: Dictionary) -> void:
	var id := str(building["district_id"])
	var root := Coupling.position_of(building)
	var geometry: Dictionary = owner.building_geometry[id]
	var entry: Dictionary = geometry["entry"]
	var direction := int(entry["orientation"]) if entry.has("orientation") else Orientation.street_orientation(city,root)
	var front: Vector2 = Orientation.FACING[direction]
	var along := Vector2(-front.y,front.x)
	var source: Dictionary = Orientation._source_access(city,root)
	var lot := PackedVector2Array()
	if str(source.get("id","")) == str(building.get("lot_id","")) and source.has("polygon"): lot = source["polygon"]
	var tone := _stable_tone(id)
	var specs: Array[Dictionary]
	if str(building["type"]) == "residential":
		specs = [{"kind":"leaf_pot","side":-0.14,"front":0.348,"half":Vector2(0.055,0.055)},
			{"kind":"low_planter","side":0.14,"front":0.344,"half":Vector2(0.047,0.047)}]
	else:
		specs = [{"kind":"wood_crate","side":-0.145,"front":0.342,"half":Vector2(0.061,0.05)},
			{"kind":"terracotta_jar","side":0.15,"front":0.345,"half":Vector2(0.049,0.049)}]
		if tone == 1: specs[0] = {"kind":"terracotta_jar","side":-0.15,"front":0.345,"half":Vector2(0.049,0.049)}
		if tone != 0: specs[1] = {"kind":"low_bench","side":0.145,"front":0.354,"half":Vector2(0.072,0.024)}
	var made: Array[FrontagePiece] = []
	for spec: Dictionary in specs:
		# Alter the shape/material by stable identity, never the legal placement.
		var at: Vector2 = root+front*float(spec["front"])+along*float(spec["side"])
		var footprint := _rectangle(at,along,front,spec["half"])
		if not _legal_frontage(city,building,footprint,lot): continue
		var piece := FrontagePiece.new()
		piece.name = "Frontage_"+id+"_"+str(spec["kind"])
		piece.house_id = id
		piece.kind = str(spec["kind"])
		piece.world_position = at
		piece.footprint = footprint
		piece.orientation = direction
		piece.position = Projection2D.to_screen(at-Vector2(16,16),Vector2.ZERO,1.0,AXES,city.terrain.height_at(at))
		piece.visible = false
		_bake_piece(piece,along,front,tone)
		add_child(piece)
		made.append(piece)
	if not made.is_empty():
		layouts[id] = {"root":root,"type":str(building["type"]),"orientation":direction,"entrance":source.get("entrance",[]),"pieces":made}

func _legal_frontage(city: RefCounted,building: Dictionary,polygon: PackedVector2Array,lot: PackedVector2Array = PackedVector2Array()) -> bool:
	placement_query_count += 1
	var root := Coupling.position_of(building)
	# The saved building radius is its actual owned ground. Keep every object
	# corner inside it, and inside the committed lot when the house has one.
	for corner in polygon:
		if corner.distance_to(root) > float(building["radius"])-0.002: return false
		if not lot.is_empty() and not Geometry2D.is_point_in_polygon(corner,lot): return false
	if not Spatial.exclusion(city,polygon).is_empty(): return false
	var box := Spatial.bounds(polygon)
	var reach := box.size.length()*0.5
	for segment: Dictionary in city.near_road_segments(box.get_center(),reach+0.55):
		for strip in Geometry2D.offset_polyline(PackedVector2Array([segment["a"],segment["b"]]),Fabric._road_width(city,segment["road"])+0.015,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
			if Spatial.overlaps(polygon,strip): return false
	for nearby: String in city.index.query_circle(box.get_center(),reach):
		if nearby == str(building["district_id"]): continue
		var other: Dictionary = city.by_id[nearby]
		if Spatial.disc_hits(polygon,Coupling.position_of(other),float(other["radius"])): return false
	return true

static func _stable_tone(id: String) -> int:
	var value := 0
	for index in range(id.length()): value = (value*31+id.unicode_at(index))%2147483647
	return posmod(value^(value>>6)^(value>>13),3)

static func _rectangle(at: Vector2,along: Vector2,front: Vector2,half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([at-along*half.x-front*half.y,at+along*half.x-front*half.y,at+along*half.x+front*half.y,at-along*half.x+front*half.y])

static func _project(point: Vector3,along: Vector2,front: Vector2) -> Vector2:
	var ground := along*point.x+front*point.z
	return Vector2((ground.x-ground.y)*AXES.x,(ground.x+ground.y)*AXES.y-point.y*VERTICAL)

static func _face(piece: FrontagePiece,points: Array[Vector3],color: Color,along: Vector2,front: Vector2) -> void:
	var polygon := PackedVector2Array()
	var depth := 0.0
	for point in points:
		polygon.append(_project(point,along,front))
		var ground := along*point.x+front*point.z
		depth += 0.612372*(ground.x+ground.y)+0.5*point.y
	# Shade from the same world-fixed northwest light as the stone buildings.
	var normal := (points[1]-points[0]).cross(points[2]-points[0]).normalized()
	var world_normal := Vector3(along.x*normal.x+front.x*normal.z,normal.y,along.y*normal.x+front.y*normal.z)
	var light := clampf(0.79+0.22*world_normal.dot(Vector3(-0.45,0.82,-0.35).normalized()),0.68,1.02)
	piece.faces.append({"polygon":polygon,"color":Color(color.r*light,color.g*light,color.b*light,color.a),"depth":depth/float(points.size())})

static func _box(piece: FrontagePiece,center: Vector3,half: Vector3,color: Color,along: Vector2,front: Vector2) -> void:
	var a := center+Vector3(-half.x,-half.y,-half.z)
	var b := center+Vector3(half.x,-half.y,-half.z)
	var c := center+Vector3(half.x,-half.y,half.z)
	var d := center+Vector3(-half.x,-half.y,half.z)
	var up := Vector3(0,half.y*2.0,0)
	_face(piece,[a,d,d+up,a+up],color,along,front)
	_face(piece,[b,a,a+up,b+up],color,along,front)
	_face(piece,[c,b,b+up,c+up],color,along,front)
	_face(piece,[d,c,c+up,d+up],color,along,front)
	_face(piece,[a+up,d+up,c+up,b+up],color.lightened(0.08),along,front)

static func _bake_piece(piece: FrontagePiece,along: Vector2,front: Vector2,tone: int) -> void:
	var clay: Color = [Color("bb7f5e"),Color("ae7054"),Color("c38f69")][tone]
	var wood: Color = [Color("92724f"),Color("8c6948"),Color("a08055")][tone]
	var shadow := PackedVector2Array()
	for corner in piece.footprint: shadow.append(_project(Vector3((corner-piece.world_position).dot(along),0.002,(corner-piece.world_position).dot(front)),along,front))
	piece.shadows.append(shadow)
	match piece.kind:
		"wood_crate":
			_box(piece,Vector3(0,0.051,0),Vector3(0.057,0.051,0.046),wood,along,front)
			for x: float in [-0.039,0.0,0.039]:
				_box(piece,Vector3(x,0.051,0.048),Vector3(0.012,0.048,0.003),wood.lightened(0.08),along,front)
			_box(piece,Vector3(0,0.021,0.052),Vector3(0.057,0.005,0.003),wood.darkened(0.16),along,front)
			_box(piece,Vector3(0,0.081,0.052),Vector3(0.057,0.005,0.003),wood.darkened(0.16),along,front)
		"low_bench":
			for x: float in [-0.049,0.049]:
				_box(piece,Vector3(x,0.04,0),Vector3(0.009,0.04,0.019),wood.darkened(0.12),along,front)
			_box(piece,Vector3(0,0.083,0),Vector3(0.068,0.01,0.022),wood.lightened(0.07),along,front)
			_box(piece,Vector3(0,0.038,0),Vector3(0.049,0.005,0.005),wood,along,front)
		_:
			_pottery(piece,clay,along,front,tone)
	piece.faces.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return float(a["depth"]) < float(b["depth"]))

static func _pottery(piece: FrontagePiece,clay: Color,along: Vector2,front: Vector2,tone: int) -> void:
	var radius := 0.048 if piece.kind == "leaf_pot" else 0.041
	var height := 0.112 if piece.kind != "low_planter" else 0.073
	var rings := [Vector2(radius*0.59,0.006),Vector2(radius, height*0.46),Vector2(radius*0.74,height*0.86),Vector2(radius*0.82,height)]
	const SIDES := 10
	for level in range(rings.size()-1):
		var lower: Vector2 = rings[level]
		var upper: Vector2 = rings[level+1]
		for index in range(SIDES):
			var a := TAU*float(index)/float(SIDES)
			var b := TAU*float(index+1)/float(SIDES)
			_face(piece,[Vector3(cos(b)*lower.x,lower.y,sin(b)*lower.x),Vector3(cos(a)*lower.x,lower.y,sin(a)*lower.x),Vector3(cos(a)*upper.x,upper.y,sin(a)*upper.x),Vector3(cos(b)*upper.x,upper.y,sin(b)*upper.x)],clay,along,front)
	var opening: Array[Vector3] = []
	for index in range(SIDES):
		var a := TAU*float(index)/float(SIDES)
		opening.append(Vector3(cos(a)*radius*0.65,height-0.003,sin(a)*radius*0.65))
	_face(piece,opening,Color("5e5340"),along,front)
	# Three distinct lance leaves, rooted inside the soil rather than scattered.
	if piece.kind == "terracotta_jar": return
	for leaf in range(3):
		var a := float(leaf)*TAU/3.0+float(tone)*0.44
		var reach := 0.051 if leaf != 1 else 0.037
		var rise := 0.089 if piece.kind == "leaf_pot" else 0.062
		var tip := Vector3(cos(a)*reach,height+rise*(0.82+0.09*float(leaf)),sin(a)*reach)
		var across := Vector3(-sin(a)*0.013,0,cos(a)*0.013)
		var base := Vector3(0,height-0.003,0)
		var middle := base.lerp(tip,0.53)
		var green: Color = [Color("77805c"),Color("6c825b"),Color("859066")][(leaf+tone)%3]
		_face(piece,[base,middle-across,tip,middle],green.darkened(0.12),along,front)
		_face(piece,[base,middle,tip,middle+across],green.lightened(0.08),along,front)

func diagnostics() -> Dictionary:
	var homes: Array = []
	var visible_pieces := 0
	for id: String in layouts:
		var layout: Dictionary = layouts[id]
		var objects: Array = []
		for piece: FrontagePiece in layout["pieces"]:
			objects.append({"kind":piece.kind,"position":piece.world_position,"footprint":piece.footprint,"visible":piece.visible,"faces":piece.faces.size()})
			if piece.visible: visible_pieces += 1
		homes.append({"id":id,"root":layout["root"],"type":layout["type"],"orientation":layout["orientation"],"entrance":layout["entrance"],"objects":objects})
	return {"houses":homes,"visible_pieces":visible_pieces,"rebuild_count":rebuild_count,"placement_query_count":placement_query_count,"house_limit":MAX_HOUSES}
