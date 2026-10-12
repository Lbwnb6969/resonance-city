extends RefCounted
## Retained masonry on real, heard classical streets. All coordinates are XZ;
## the ground renderer projects every vertex at its actual terrain height.
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const Miniature = preload("res://scripts/visual/miniature_valley_material.gd")
const FRONTAGE_REACH := 2.1
const CURB_WIDTH := 0.035
const CURB_RAISE := 0.014
const MORTAR := 0.007
const LENGTHS := [0.37,0.46,0.31,0.42,0.34,0.49,0.39]
var key: Array = []
var material: Dictionary = {"paving":[],"stones":[],"curbs":[],"joints":[],"diagnostics":{}}
var rebuild_count := 0
var last_build_ms := 0.0

func sync(city: RefCounted,heard_frame: float) -> void:
	var heard: Array[Dictionary] = []
	var sources: Array[Dictionary] = []
	var heard_ids: Dictionary = {}
	var next: Array = [city.terrain.noise_seed,city.terrain.river_phase,city.terrain.family,
		hash(city.cfg["terrain"]),city.road_index_identity,
		float(city.cfg["terrain"]["template_road_half_width"]),float(city.cfg["city"]["branch_road_half_width"])]
	for building: Dictionary in city.buildings:
		if float(building["birth_frame"]) > heard_frame: continue
		heard.append(building)
		heard_ids[str(building["district_id"])] = true
		next.append([building["district_id"],Coupling.position_of(building),int(building.get("era",1)),building["birth_frame"],building["radius"],building.get("lot_id","")])
		if int(building.get("era",1)) == 1: sources.append(building)
	var excluded: Array[PackedVector2Array] = []
	for building: Dictionary in heard: excluded.append(city.building_polygon(Coupling.position_of(building)))
	for lot: Dictionary in city.lots:
		if heard_ids.has(str(lot["occupant"])):
			next.append(["lot",lot["id"],lot["polygon"]])
			excluded.append(lot["polygon"])
	for group: Array in [city.public_sites,city.planning_reservations]:
		for record: Dictionary in group:
			if float(record.get("frame",0)) > heard_frame: continue
			var components := Spatial.footprint_components(record)
			var holes := Spatial.footprint_holes(record)
			next.append(["owned_land",record["id"],components,holes])
			for outer: PackedVector2Array in components:
				excluded.append_array(PartialPublic._subtract_components(outer,holes))
	if key == next: return
	key = next.duplicate(true)
	var began := Time.get_ticks_usec()
	rebuild_count += 1
	material = {"paving":[],"stones":[],"curbs":[],"joints":[],"diagnostics":{}}
	if city.terrain.family == "river_valley" and not sources.is_empty(): _build(city,sources,excluded)
	last_build_ms = float(Time.get_ticks_usec()-began)/1000.0
	material["diagnostics"]["source_ids"] = sources.map(func(building: Dictionary) -> String: return str(building["district_id"]))
	material["diagnostics"]["paving_count"] = material["paving"].size()
	material["diagnostics"]["stone_count"] = material["stones"].size()
	material["diagnostics"]["curb_count"] = material["curbs"].size()

func _build(city: RefCounted,sources: Array[Dictionary],excluded: Array[PackedVector2Array]) -> void:
	var roads: Array[Dictionary] = []
	var degree: Dictionary = {}
	for road: Dictionary in city.roads:
		degree[str(road["from"])] = int(degree.get(str(road["from"]),0))+1
		degree[str(road["to"])] = int(degree.get(str(road["to"]),0))+1
		var masks: Array[PackedVector2Array] = []
		masks.assign(Geometry2D.offset_polyline(road["path"],Miniature.road_width(city,road),Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT))
		roads.append({"road":road,"masks":masks})
	roads.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a["road"]["id"]) < str(b["road"]["id"]))
	var already_paved: Array[PackedVector2Array] = []
	var span_records: Array[Dictionary] = []
	var terminal_count := 0
	for record: Dictionary in roads:
		var road: Dictionary = record["road"]
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road["path"]
		var width := Miniature.road_width(city,road)
		var length := _length(path)
		var spans := _inhabited_spans(path,sources)
		var other_roads: Array[PackedVector2Array] = []
		for other: Dictionary in roads:
			if str(other["road"]["id"]) != str(road["id"]): other_roads.append_array(other["masks"])
		var allowed: Array[PackedVector2Array] = []
		for mask: PackedVector2Array in record["masks"]:
			for bank: PackedVector2Array in [city.terrain.left_bank,city.terrain.right_bank]:
				for land: PackedVector2Array in Geometry2D.intersect_polygons(mask,bank):
					allowed.append_array(_subtract(land,excluded))
		var before_this_road := already_paved.duplicate()
		for span: Vector2 in spans:
			var center := _slice(path,span.x,span.y)
			var fill: Array[PackedVector2Array] = []
			for strip: PackedVector2Array in Geometry2D.offset_polyline(center,width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
				for piece: PackedVector2Array in _intersect(strip,allowed):
					fill.append_array(_subtract(piece,before_this_road))
			if fill.is_empty(): continue
			for piece: PackedVector2Array in fill:
				material["paving"].append({"polygon":piece,"strength":1.0,"road_id":str(road["id"])})
				already_paved.append(piece)
			_make_stones(path,span,width,fill,str(road["id"]))
			var curb_fill: Array[PackedVector2Array] = []
			for piece: PackedVector2Array in fill: curb_fill.append_array(_subtract(piece,other_roads))
			for side: float in [-1.0,1.0]:
				var edge := _offset(center,side*(width-0.003))
				for part: PackedVector2Array in _outside(edge,other_roads):
					_make_curb(part,-side*CURB_WIDTH,curb_fill,str(road["id"]),"side")
			if span.x <= 0.00001 and int(degree[str(road["from"])]) == 1:
				terminal_count += _terminal(path,false,width,curb_fill,other_roads,str(road["id"]))
			if span.y >= length-0.00001 and int(degree[str(road["to"])]) == 1:
				terminal_count += _terminal(path,true,width,curb_fill,other_roads,str(road["id"]))
			span_records.append({"road_id":str(road["id"]),"from":span.x,"to":span.y,"length":length})
	material["diagnostics"]["spans"] = span_records
	material["diagnostics"]["terminal_count"] = terminal_count
	material["diagnostics"]["frontage_reach"] = FRONTAGE_REACH
	material["diagnostics"]["curb_raise"] = CURB_RAISE

static func _inhabited_spans(path: PackedVector2Array,sources: Array[Dictionary]) -> Array[Vector2]:
	var spans: Array[Vector2] = []
	var along := 0.0
	for i in range(path.size()-1):
		var a := path[i]
		var direction := path[i].direction_to(path[i+1])
		var distance := a.distance_to(path[i+1])
		if distance < 0.000001: continue
		for building: Dictionary in sources:
			var delta := Coupling.position_of(building)-a
			var station := delta.dot(direction)
			var across := absf(delta.cross(direction))
			# The old query_circle includes the actual building radius.
			var reach := FRONTAGE_REACH+float(building["radius"])
			if across >= reach: continue
			var run := sqrt(reach*reach-across*across)
			var begin := maxf(0.0,station-run)
			var end := minf(distance,station+run)
			if end > begin+0.00001: spans.append(Vector2(along+begin,along+end))
		along += distance
	spans.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.x < b.x)
	var merged: Array[Vector2] = []
	for span: Vector2 in spans:
		if merged.is_empty() or span.x > merged[-1].y+0.00001: merged.append(span)
		else: merged[-1].y = maxf(merged[-1].y,span.y)
	return merged

func _make_stones(path: PackedVector2Array,span: Vector2,width: float,fill: Array[PackedVector2Array],road_id: String) -> void:
	var inside := width-CURB_WIDTH-0.005
	var rows := 3 if width >= 0.23 else 2
	var course := inside*2.0/float(rows)
	var road_seed := _stable(road_id)
	for row in range(rows):
		var station := -0.21*float(row%2)
		var column := 0
		var offset := -inside+course*(float(row)+0.5)
		# Stone phase continues over the whole road, including unpaved gaps.
		while station < span.y:
			var size: float = LENGTHS[posmod(road_seed+row*3+column,LENGTHS.size())]
			var begin := maxf(station+MORTAR,span.x+float(row%3)*0.055)
			var end := minf(station+size-MORTAR,span.y-float((row+1)%3)*0.055)
			if end-begin > 0.035:
				var center := _offset(_slice(path,begin,end),offset)
				for strip: PackedVector2Array in Geometry2D.offset_polyline(center,course*0.5-MORTAR,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
					for piece: PackedVector2Array in _intersect(strip,fill):
						var tone := float(posmod(road_seed+row*17+column*13,15)-7)*0.005
						material["stones"].append({"polygon":piece,"tone":tone,"strength":1.0,"road_id":road_id,"row":row,"station":begin,"length":end-begin})
			station += size
			column += 1

func _make_curb(edge: PackedVector2Array,inset: float,fill: Array[PackedVector2Array],road_id: String,kind: String) -> int:
	var count := 0
	for part: PackedVector2Array in _inside(edge,fill):
		var inner := _offset(part,inset)
		for i in range(part.size()-1):
			var ribbon := PackedVector2Array([part[i],part[i+1],inner[i+1],inner[i]])
			var side := PackedVector2Array([part[i],part[i+1]])
			for piece: PackedVector2Array in _intersect(ribbon,fill):
				var clipped_edge := _boundary_edge(side,piece)
				if clipped_edge.size() != 2: continue
				material["curbs"].append({"polygon":piece,"edge":clipped_edge,"raise":CURB_RAISE,"strength":1.0,"road_id":road_id,"kind":kind})
				count += 1
	return count

func _terminal(path: PackedVector2Array,at_end: bool,width: float,fill: Array[PackedVector2Array],other_roads: Array[PackedVector2Array],road_id: String) -> int:
	var p := path[-1] if at_end else path[0]
	var into := path[-1].direction_to(path[-2]) if at_end else path[0].direction_to(path[1])
	var normal := Vector2(-into.y,into.x)
	var edge := PackedVector2Array([p+into*0.003+normal*(width-0.004),p+into*0.003-normal*(width-0.004)])
	var count := 0
	for part: PackedVector2Array in _outside(edge,other_roads): count += _make_curb(part,CURB_WIDTH,fill,road_id,"terminal")
	return count

static func _length(path: PackedVector2Array) -> float:
	var length := 0.0
	for i in range(path.size()-1): length += path[i].distance_to(path[i+1])
	return length

static func _slice(path: PackedVector2Array,begin: float,end: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var along := 0.0
	for i in range(path.size()-1):
		var length := path[i].distance_to(path[i+1])
		if length < 0.000001: continue
		var low := maxf(begin,along)
		var high := minf(end,along+length)
		if high > low+0.000001:
			var start := path[i].lerp(path[i+1],(low-along)/length)
			var finish := path[i].lerp(path[i+1],(high-along)/length)
			if result.is_empty() or result[-1].distance_to(start) > 0.000001: result.append(start)
			var steps := maxi(1,ceili(start.distance_to(finish)/0.3))
			for step in range(1,steps+1): result.append(start.lerp(finish,float(step)/float(steps)))
		along += length
	return result

static func _offset(path: PackedVector2Array,distance: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(path.size()):
		var before := path[maxi(0,i-1)].direction_to(path[i]) if i > 0 else Vector2.ZERO
		var after := path[i].direction_to(path[mini(path.size()-1,i+1)]) if i < path.size()-1 else Vector2.ZERO
		var direction := (before+after).normalized()
		result.append(path[i]+Vector2(-direction.y,direction.x)*distance)
	return result

static func _boundary_edge(edge: PackedVector2Array,polygon: PackedVector2Array) -> PackedVector2Array:
	# Polyline/polygon intersection treats a coincident boundary as outside.
	# The clipped polygon itself owns this rail, including clipped junctions.
	var direction := edge[0].direction_to(edge[1])
	var low := INF
	var high := -INF
	for vertex: Vector2 in polygon:
		var closest := Geometry2D.get_closest_point_to_segment(vertex,edge[0],edge[1])
		if vertex.distance_to(closest) > 0.00005: continue
		var along := (closest-edge[0]).dot(direction)
		low = minf(low,along)
		high = maxf(high,along)
	if high-low <= 0.005: return PackedVector2Array()
	return PackedVector2Array([edge[0]+direction*low,edge[0]+direction*high])

static func _intersect(polygon: PackedVector2Array,masks: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if polygon.size() < 3: return result
	var bounds := Spatial.bounds(polygon)
	for mask: PackedVector2Array in masks:
		if not bounds.intersects(Spatial.bounds(mask),true): continue
		for part: PackedVector2Array in Geometry2D.intersect_polygons(polygon,mask):
			if _valid(part): result.append(part)
	return result

static func _subtract(polygon: PackedVector2Array,excluded: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var remaining: Array[PackedVector2Array] = [polygon]
	for other: PackedVector2Array in excluded:
		var next: Array[PackedVector2Array] = []
		for part: PackedVector2Array in remaining:
			if not Spatial.bounds(part).intersects(Spatial.bounds(other),true):
				next.append(part)
				continue
			var clipped: Array[PackedVector2Array] = []
			clipped.assign(Geometry2D.clip_polygons(part,other))
			# Street junctions need the ordinary exact difference, rather than
			# the transaction helper's all-or-nothing residual area threshold.
			# A real interior hole still needs its existing hole-free partition.
			if clipped.any(func(ring: PackedVector2Array) -> bool: return Geometry2D.is_polygon_clockwise(ring)):
				clipped = PartialPublic._residuals(part,other)
			for fragment: PackedVector2Array in clipped:
				if _valid(fragment): next.append(fragment)
		remaining = next
		if remaining.is_empty(): break
	return remaining

static func _inside(line: PackedVector2Array,masks: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for mask: PackedVector2Array in masks:
		for part: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(line,mask):
			if part.size() >= 2 and _length(part) > 0.005:
				if (part[-1]-part[0]).dot(line[-1]-line[0]) < 0.0: part.reverse()
				result.append(part)
	return result

static func _outside(line: PackedVector2Array,masks: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = [line]
	var bounds := Spatial.bounds(line)
	for mask: PackedVector2Array in masks:
		if not bounds.intersects(Spatial.bounds(mask),true): continue
		var next: Array[PackedVector2Array] = []
		for part: PackedVector2Array in result:
			for clipped: PackedVector2Array in Geometry2D.clip_polyline_with_polygon(part,mask):
				# Clipper can reverse an open path. A signed curb inset belongs
				# to the road's original direction, never the returned ring order.
				if (clipped[-1]-clipped[0]).dot(part[-1]-part[0]) < 0.0: clipped.reverse()
				next.append(clipped)
		result = next
	return result

static func _valid(polygon: PackedVector2Array) -> bool:
	return polygon.size() >= 3 and Spatial.polygon_area(polygon) > 0.000001 and not Geometry2D.triangulate_polygon(polygon).is_empty()

static func _stable(value: String) -> int:
	var seed := 0
	for i in range(value.length()): seed = (seed*31+value.unicode_at(i))%2147483647
	return seed
