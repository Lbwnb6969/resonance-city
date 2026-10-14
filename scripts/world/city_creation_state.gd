class_name CityCreationState
extends RefCounted

## Authoritative, immediate state for the independent city creation slice.
const SCHEMA := 1
const CELL_UNIT := 1.8
const FLOOR_HEIGHT := 1.7
const DEFAULT_PATH := "user://city_creation_v1.json"
const WORLD_RECT := Rect2(-18.0, -15.0, 35.0, 30.0)
const RIVER_HALF_WIDTH := 2.3
const MAX_PLANTS_PER_STROKE := 160
const HOUSE_ROLES := ["residential", "bakery", "venue"]
const DISTRICT_STYLES := ["warm", "deep", "weave"]
const DISTRICT_STYLE_NAMES := {"warm": "暖声街坊", "deep": "低吟街坊", "weave": "织音街坊"}
const DIRECTIONS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var houses: Array[Dictionary] = []
var roads: Array[Dictionary] = []
var plants: Array[Dictionary] = []
var waters: Array[Dictionary] = []
var districts: Array[Dictionary] = []
var revision := 0
var dirty := false
var life_progress := {"purchases":0,"gatherings":0,"concerts":0}
var bakery_supply: Dictionary = {}
var journey_checkpoint: Dictionary = {}
var life_progress_dirty := false
var _next_house_id := 1
var _next_cell_id := 1
var _next_road_id := 1
var _next_plant_id := 1
var _next_water_id := 1
var _next_district_id := 1
var _high_watermark := {"house": 0, "cell": 0, "road": 0, "plant": 0, "water": 0, "district": 0}
var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []


func initialize() -> void:
	life_progress = {"purchases":0,"gatherings":0,"concerts":0}
	bakery_supply.clear()
	journey_checkpoint.clear()
	life_progress_dirty = false
	houses.clear()
	roads.clear()
	plants.clear()
	waters.clear()
	districts.clear()
	_next_house_id = 1
	_next_cell_id = 1
	_next_road_id = 1
	_next_plant_id = 1
	_next_water_id = 1
	_next_district_id = 1
	_high_watermark = {"house": 0, "cell": 0, "road": 0, "plant": 0, "water": 0, "district": 0}
	var positions := [Vector2(-8.0, -6.0), Vector2(-2.4, -5.0), Vector2(-8.0, 0.0), Vector2(-2.4, 1.0), Vector2(-7.0, 6.0), Vector2(9.0, 3.0)]
	for i in range(positions.size()):
		var house := _make_house(positions[i], i)
		if i == 1:
			house.role = "bakery"
		elif i == 3:
			house.role = "venue"
		if i == 0 or i == 2:
			house.cells.append(_make_cell(1, 0, 0, "room"))
		if i == 1 or i == 3:
			house.cells.append(_make_cell(0, 0, 1, "room"))
		if i == 4:
			house.cells.append(_make_cell(1, 0, 0, "terrace"))
		houses.append(house)
	roads.append({"id": "r1", "points": [[-11.0, -9.0], [-11.0, 9.0]], "width": 1.25, "bridge": false, "source": "seed"})
	_next_road_id = 2
	for house in houses:
		if house.origin[0] > river_x(float(house.origin[1])):
			continue
		var door_z: float = Vector2(0.0, float(house.origin[1]) + 1.55).y
		roads.append({"id": "r%d" % _next_road_id, "points": [[-11.0, door_z], [house.origin[0], door_z]], "width": 1.25, "bridge": false, "source": "seed"})
		_next_road_id += 1
	_high_watermark = {"house": _next_house_id - 1, "cell": _next_cell_id - 1, "road": _next_road_id - 1, "water": 0, "district": 0}
	_generate_initial_plants()
	revision = 0
	dirty = false
	_undo.clear()
	_redo.clear()


func add_cell(house_id: String, x: int, z: int, level: int, kind: String = "room") -> Dictionary:
	var result := validate_add_cell(house_id, x, z, level, kind)
	if not result.ok:
		return result
	var index := _house_index(house_id)
	var before := snapshot()
	var candidate: Dictionary = houses[index].duplicate(true)
	var cell_number := maxi(_next_cell_id, int(_high_watermark.cell) + 1)
	candidate.cells.append({"id": "c%d" % cell_number, "x": x, "z": z, "level": level, "kind": kind, "source": "player"})
	houses[index] = candidate
	_next_cell_id = cell_number + 1
	_high_watermark.cell = cell_number
	_commit(before, "添加露台" if kind == "terrace" else "扩展房屋")
	return {"ok": true, "message": "露台已建成" if kind == "terrace" else "房屋已扩展", "cell_id": candidate.cells[-1].id, "house_id": house_id}


func validate_add_cell(house_id: String, x: int, z: int, level: int, kind: String = "room") -> Dictionary:
	var index := _house_index(house_id)
	if index < 0:
		return _fail("房屋不存在")
	if level < 0 or kind not in ["room", "terrace"]:
		return _fail("无效的房屋模块")
	var candidate: Dictionary = houses[index].duplicate(true)
	for cell in candidate.cells:
		if cell.x == x and cell.z == z and cell.level == level:
			return _fail("这里已经有模块")
	candidate.cells.append({"id": "c%d" % maxi(_next_cell_id, int(_high_watermark.cell) + 1), "x": x, "z": z, "level": level, "kind": kind, "source": "player"})
	var result := _validate_house(candidate)
	if not result.ok:
		return result
	if _house_overlaps(candidate, house_id):
		return _fail("这里与另一栋房屋重叠")
	return _validate_house_site(candidate)


func remove_cell(house_id: String, cell_id: String) -> Dictionary:
	var index := _house_index(house_id)
	if index < 0:
		return _fail("房屋不存在")
	var candidate: Dictionary = houses[index].duplicate(true)
	var found := false
	for i in range(candidate.cells.size() - 1, -1, -1):
		if candidate.cells[i].id == cell_id:
			candidate.cells.remove_at(i)
			found = true
	if not found:
		return _fail("模块不存在")
	# Resolve support dependants in the same transaction, topological order.
	var changed := true
	while changed:
		changed = false
		for i in range(candidate.cells.size() - 1, -1, -1):
			var cell: Dictionary = candidate.cells[i]
			if cell.level > 0 and not _supported(cell, candidate.cells):
				candidate.cells.remove_at(i)
				changed = true
	var result := _validate_house(candidate)
	if not result.ok:
		return result
	var before := snapshot()
	var removed_count: int = houses[index].cells.size() - candidate.cells.size()
	houses[index] = candidate
	_commit(before, "移除模块")
	return {"ok": true, "message": "已移除 %d 个模块" % removed_count, "removed_count": removed_count}


func add_house(position: Vector2) -> Dictionary:
	var result := validate_add_house(position)
	if not result.ok:
		return result
	var before := snapshot()
	var house_number := maxi(_next_house_id, int(_high_watermark.house) + 1)
	var cell_number := maxi(_next_cell_id, int(_high_watermark.cell) + 1)
	var house := {"id": "h%d" % house_number, "name": "石榴巷%d号" % house_number, "role": "residential", "bakery_open":true, "origin": [position.x, position.y], "cells": [{"id": "c%d" % cell_number, "x": 0, "z": 0, "level": 0, "kind": "room", "source": "new_house"}], "palette": (house_number - 1) % 6, "seed": 81000 + house_number * 977}
	houses.append(house)
	_next_house_id = house_number + 1
	_next_cell_id = cell_number + 1
	_high_watermark.house = house_number
	_high_watermark.cell = cell_number
	_commit(before, "新建房屋")
	return {"ok": true, "message": "新房屋已建成", "house_id": house.id}


func validate_add_house(position: Vector2) -> Dictionary:
	if not is_finite(position.x) or not is_finite(position.y):
		return _fail("无效的位置")
	var house := {"origin": [position.x, position.y], "cells": [{"x": 0, "z": 0, "level": 0, "kind": "room"}]}
	if _house_overlaps(house):
		return _fail("这里与另一栋房屋重叠")
	return _validate_house_site(house)


func set_house_role(house_id: String, role: String) -> Dictionary:
	var index := _house_index(house_id)
	if index < 0:
		return _fail("房屋不存在")
	if role not in HOUSE_ROLES:
		return _fail("未知的建筑用途")
	if houses[index].role == role:
		return {"ok": true, "message": "建筑用途未变"}
	var before := snapshot()
	houses[index].role = role
	_commit(before, "更改建筑用途")
	return {"ok": true, "message": "建筑用途已更改"}


func set_house_name(house_id: String, house_name: String) -> Dictionary:
	var index := _house_index(house_id)
	if index < 0:
		return _fail("房屋不存在")
	var clean := house_name.strip_edges()
	if clean.is_empty():
		return _fail("请填写建筑名字")
	if houses[index].name == clean:
		return {"ok": true, "message": "建筑名字未变"}
	var before := snapshot()
	houses[index].name = clean
	_commit(before, "命名建筑")
	return {"ok": true, "message": "建筑名字已保存"}


## A painted community expresses musical intent, separate from construction
## occupancy and road connectivity. Latest stroke owns overlapping origins.
func add_district(points: Array[Vector2], width: float = 5.6, style: String = "warm") -> Dictionary:
	if not is_finite(width) or width < 3.2 or width > 10.0:
		return _fail("街坊宽度应为3.2至10米")
	var number := maxi(_next_district_id, int(_high_watermark.get("district", 0)) + 1)
	var rows: Array = []
	for point in points:
		rows.append([point.x, point.y])
	var district := {"id": "d%d" % number, "name": "%s%d" % [DISTRICT_STYLE_NAMES.get(style, ""), number], "style": style, "points": rows, "width": Vector2(width, 0).x}
	var valid := _validate_district_fields(district)
	if not valid.ok:
		return valid
	var before := snapshot()
	districts.append(district)
	_next_district_id = number + 1
	_high_watermark.district = number
	_commit(before, "划定音乐街坊")
	return {"ok": true, "message": "音乐街坊已划定", "district_id": district.id}


func district_at(position: Vector2) -> Dictionary:
	if not is_finite(position.x) or not is_finite(position.y):
		return {}
	for index in range(districts.size() - 1, -1, -1):
		var district: Dictionary = districts[index]
		if _water_stroke_distance(position, district.points) <= float(district.width) * 0.5:
			return district.duplicate(true)
	return {}


func district_for_house(house_id: String) -> Dictionary:
	var index := _house_index(house_id)
	if index < 0:
		return {}
	return district_at(Vector2(float(houses[index].origin[0]), float(houses[index].origin[1])))


func district_members(district_id: String) -> Array[String]:
	var members: Array[String] = []
	if _district_index(district_id) < 0:
		return members
	for house in houses:
		if district_for_house(house.id).get("id", "") == district_id:
			members.append(house.id)
	return members


func set_district_name(district_id: String, district_name: String) -> Dictionary:
	var index := _district_index(district_id)
	if index < 0:
		return _fail("街坊不存在")
	var clean := district_name.strip_edges()
	if not _valid_district_name(clean):
		return _fail("街坊名字应为1至48个字，不含换行或控制字符")
	if districts[index].name == clean:
		return {"ok": true, "message": "街坊名字未变"}
	var before := snapshot()
	districts[index].name = clean
	_commit(before, "命名音乐街坊")
	return {"ok": true, "message": "街坊名字已保存"}


func set_district_style(district_id: String, style: String) -> Dictionary:
	var index := _district_index(district_id)
	if index < 0:
		return _fail("街坊不存在")
	if style not in DISTRICT_STYLES:
		return _fail("未知的街坊音乐风格")
	if districts[index].style == style:
		return {"ok": true, "message": "街坊风格未变"}
	var before := snapshot()
	districts[index].style = style
	_commit(before, "更改街坊音乐风格")
	return {"ok": true, "message": "街坊音乐风格已更改"}


func remove_district(district_id: String) -> Dictionary:
	var index := _district_index(district_id)
	if index < 0:
		return _fail("街坊不存在")
	var before := snapshot()
	districts.remove_at(index)
	_commit(before, "移除音乐街坊")
	return {"ok": true, "message": "音乐街坊已移除", "district_id": district_id}


func remove_district_at(position: Vector2) -> Dictionary:
	var district := district_at(position)
	if district.is_empty():
		return _fail("这里没有音乐街坊")
	return remove_district(district.id)


func _district_index(district_id: String) -> int:
	for index in range(districts.size()):
		if districts[index].id == district_id:
			return index
	return -1


func _valid_district_name(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 48 or value.strip_edges() != value:
		return false
	for index in range(value.length()):
		if value.unicode_at(index) < 32 or value.unicode_at(index) == 127:
			return false
	return true


func _validate_district_fields(district: Dictionary) -> Dictionary:
	for field in district:
		if field not in ["id", "name", "style", "points", "width"]:
			return _fail("街坊存在未知字段")
	if not _valid_district_name(district.get("name")) or district.get("style") not in DISTRICT_STYLES:
		return _fail("街坊名字或音乐风格无效")
	if not _is_number(district.get("width")) or float(district.width) < 3.2 or float(district.width) > 10.0:
		return _fail("街坊宽度应为3.2至10米")
	if not district.get("points") is Array or district.points.is_empty():
		return _fail("街坊范围需要至少一个点")
	var previous: Vector2
	for index in range(district.points.size()):
		var point: Variant = district.points[index]
		if not _valid_point(point):
			return _fail("街坊位置无效")
		var position := Vector2(float(point[0]), float(point[1]))
		if not WORLD_RECT.has_point(position):
			return _fail("街坊笔画超出创作范围")
		if index > 0 and position == previous:
			return _fail("街坊笔画包含重复相邻点")
		previous = position
	return {"ok": true, "message": ""}


## Water is an editable continuous mask, inspired by Tiny Glade's separate
## WaterRas / Terrain fields. Author strokes; derive occupancy and shoreline.
func water_clearance(position: Vector2) -> float:
	return _water_clearance_in(position, waters)


func street_height(position: Vector2) -> float:
	return 0.055 + 0.185 * (1.0 - smoothstep(-0.05, 0.65, water_clearance(position)))


func _water_clearance_in(position: Vector2, rows: Array) -> float:
	var distance := absf(position.x - river_x(position.y)) - RIVER_HALF_WIDTH
	for water in rows:
		distance = minf(distance, _water_stroke_distance(position, water.points) - float(water.width) * 0.5)
	return distance


func _water_stroke_distance(position: Vector2, points: Array) -> float:
	var distance := position.distance_to(Vector2(points[0][0], points[0][1]))
	for index in range(1, points.size()):
		distance = minf(distance, _distance_to_segment(position, Vector2(points[index - 1][0], points[index - 1][1]), Vector2(points[index][0], points[index][1])))
	return distance


func preview_water(points: Array[Vector2], width: float = 2.4, kind: String = "channel") -> Dictionary:
	var encoded: Array = []
	for point in points:
		encoded.append([point.x, point.y])
	var valid := _validate_water_fields({"points": encoded, "width": width, "kind": kind})
	if not valid.ok:
		valid.conflicts = []
		return valid
	if kind == "channel":
		if water_clearance(points[0]) > 0.0:
			return {"ok": false, "message": "引水需要从已有水域起笔", "conflicts": []}
		if points.size() < 2 or water_clearance(points[-1]) <= 0.0:
			return {"ok": false, "message": "请将水渠拖到干地", "conflicts": []}
	var conflicts := _water_conflicts(encoded, width, houses, roads)
	return {"ok": conflicts.is_empty(), "message": "水岸可建" if conflicts.is_empty() else "水岸与现有%s冲突" % ("房屋" if conflicts[0].kind == "house" else "道路"), "conflicts": conflicts}


func add_water(points: Array[Vector2], width: float = 2.4, kind: String = "channel") -> Dictionary:
	var valid := preview_water(points, width, kind)
	if not valid.ok:
		return valid
	var before := snapshot()
	var number := maxi(_next_water_id, int(_high_watermark.get("water", 0)) + 1)
	var encoded: Array = []
	for point in points:
		encoded.append([point.x, point.y])
	var water := {"id": "w%d" % number, "kind": kind, "points": encoded, "width": width, "seed": 261014 + number * 977, "source": "player"}
	waters.append(water)
	_next_water_id = number + 1
	_high_watermark.water = number
	_commit(before, "开挖池塘" if kind == "pond" else "引水")
	return {"ok": true, "message": "池塘已挖好" if kind == "pond" else "水渠已引入", "water_id": water.id, "seed": water.seed, "conflicts": []}


func remove_water_at(position: Vector2) -> Dictionary:
	if not is_finite(position.x) or not is_finite(position.y):
		return _fail("无效的水域位置")
	for index in range(waters.size() - 1, -1, -1):
		var water: Dictionary = waters[index]
		if _water_stroke_distance(position, water.points) > float(water.width) * 0.5:
			continue
		var remaining_waters: Array = waters.duplicate(true)
		remaining_waters.remove_at(index)
		var bridge_flags: Array[bool] = []
		for road in roads:
			var valid := _validate_road_site(road.points, float(road.width), houses, remaining_waters)
			if not valid.ok:
				return _fail("填回后道路 %s 无法完整跨岸：%s" % [road.id, valid.message])
			bridge_flags.append(valid.bridge)
		var before := snapshot()
		waters.remove_at(index)
		# A crossing becomes a ground path after filling. Other crossings keep
		# their bridge flag, and the original river remains immutable.
		for road_index in range(roads.size()):
			roads[road_index].bridge = bridge_flags[road_index]
		_commit(before, "填回水域")
		return {"ok": true, "message": "水域已填回", "water_id": water.id}
	return _fail("这里没有可填回的自建水域")


func _validate_water_fields(water: Dictionary) -> Dictionary:
	if water.get("kind") not in ["channel", "pond"] or not _is_number(water.get("width")) or float(water.width) < 1.2 or float(water.width) > 6.0:
		return _fail("水岸宽度需为 1.2—6 米")
	if not water.get("points") is Array or water.points.is_empty() or (water.kind == "channel" and water.points.size() < 2):
		return _fail("水域笔画无效")
	var inset := WORLD_RECT.grow(-float(water.width) * 0.5)
	var length := 0.0
	for index in range(water.points.size()):
		var point: Variant = water.points[index]
		if not _valid_point(point):
			return _fail("水域位置无效")
		var position := Vector2(float(point[0]), float(point[1]))
		if not inset.has_point(position):
			return _fail("整条水岸需要留在河湾范围内")
		if index > 0:
			length += position.distance_to(Vector2(water.points[index - 1][0], water.points[index - 1][1]))
	if water.kind == "channel" and length < 0.2:
		return _fail("水渠太短")
	return {"ok": true, "message": ""}


func _water_conflicts(points: Array, width: float, house_rows: Array, road_rows: Array) -> Array[Dictionary]:
	var conflicts: Array[Dictionary] = []
	for house in house_rows:
		for cell in house.cells:
			var center := Vector2(float(house.origin[0]) + int(cell.x) * CELL_UNIT, float(house.origin[1]) + int(cell.z) * CELL_UNIT)
			var rect := Rect2(center - Vector2.ONE * CELL_UNIT * 0.5, Vector2.ONE * CELL_UNIT)
			if _stroke_hits_rect(points, width * 0.5, rect):
				conflicts.append({"kind": "house", "id": house.id, "name": house.get("name", house.id), "position":[center.x,center.y], "source": cell.get("source", "seed")})
				break
	for road in road_rows:
		var found := false
		var conflict_at := Vector2.ZERO
		for index in range(maxi(1, points.size() - 1)):
			var a := Vector2(points[index][0], points[index][1])
			var b := Vector2(points[mini(index + 1, points.size() - 1)][0], points[mini(index + 1, points.size() - 1)][1])
			for road_index in range(1, road.points.size()):
				var c := Vector2(road.points[road_index - 1][0], road.points[road_index - 1][1])
				var d := Vector2(road.points[road_index][0], road.points[road_index][1])
				if _segment_distance(a, b, c, d) <= (width + float(road.width)) * 0.5:
					found = true
					conflict_at = Geometry2D.get_closest_point_to_segment(a,c,d)
		if found:
			conflicts.append({"kind": "road", "id": road.id, "position":[conflict_at.x,conflict_at.y], "source": road.get("source", "seed")})
	return conflicts


func _stroke_hits_rect(points: Array, radius: float, rect: Rect2) -> bool:
	for index in range(maxi(1, points.size() - 1)):
		var a := Vector2(points[index][0], points[index][1])
		var b := Vector2(points[mini(index + 1, points.size() - 1)][0], points[mini(index + 1, points.size() - 1)][1])
		if _segment_hits_rect(a, b, rect):
			return true
		var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for corner_index in range(4):
			if _segment_distance(a, b, corners[corner_index], corners[(corner_index + 1) % 4]) <= radius:
				return true
	return false


func _segment_distance(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
		return 0.0
	return minf(minf(_distance_to_segment(a, c, d), _distance_to_segment(b, c, d)), minf(_distance_to_segment(c, a, b), _distance_to_segment(d, a, b)))


func preview_road(points: Array[Vector2]) -> Dictionary:
	var encoded: Array = []
	for point in points: encoded.append([point.x,point.y])
	if encoded.size() < 2: return _fail("拖出一条路，松开铺好")
	return _validate_road_site(encoded,1.25)

func add_road(points: Array[Vector2]) -> Dictionary:
	if points.size() < 2:
		return _fail("道路需要两个以上的点")
	var encoded: Array = []
	var length := 0.0
	for i in range(points.size()):
		if not is_finite(points[i].x) or not is_finite(points[i].y):
			return _fail("无效的道路位置")
		encoded.append([points[i].x, points[i].y])
		if i > 0:
			length += points[i - 1].distance_to(points[i])
	if length < 0.2:
		return _fail("道路太短")
	var valid := _validate_road_site(encoded, 1.25)
	if not valid.ok:
		return valid
	var before := snapshot()
	var road_number := maxi(_next_road_id, int(_high_watermark.road) + 1)
	var road := {"id": "r%d" % road_number, "points": encoded, "width": 1.25, "bridge": valid.bridge, "source": "player"}
	roads.append(road)
	_next_road_id = road_number + 1
	_high_watermark.road = road_number
	_commit(before, "铺设道路")
	return {"ok": true, "message": "道路已铺好", "road_id": road.id}


## Plants are authored in continuous world coordinates. A complete brush
## stroke is one history entry, so deterministic seeds survive undo/redo and
## save/load without re-sampling the scene.
func add_vegetation_stroke(points: Array[Vector2], kind: String, radius: float = 1.4) -> Dictionary:
	var check := _validate_vegetation_stroke(points, kind, radius)
	if not check.ok:
		return check
	var stroke_seed := _vegetation_stroke_seed(points, kind, radius)
	var rng := RandomNumberGenerator.new()
	rng.seed = stroke_seed
	var candidates: Array[Vector2] = _stroke_samples(points, radius)
	var before := snapshot()
	var accepted: Array[Dictionary] = []
	var plant_number := maxi(_next_plant_id, int(_high_watermark.get("plant", 0)) + 1)
	for center in candidates:
		if accepted.size() >= MAX_PLANTS_PER_STROKE:
			break
		# Three nearby samples create a small Tiny Glade-like clump while the
		# spacing gate keeps a stroke bounded and avoids visual overlap.
		var cluster_count := 1 + int(rng.randf() * 3.0)
		for cluster_index in range(cluster_count):
			var angle := rng.randf_range(0.0, TAU)
			var spread := radius * (0.20 + rng.randf() * 0.48)
			var position := center + Vector2(cos(angle), sin(angle)) * spread
			if not WORLD_RECT.has_point(position):
				continue
			var scale_value := _plant_scale(kind, rng)
			var plant_seed := int(rng.randi())
			var candidate := _make_plant("p%d" % plant_number, position, kind, scale_value, plant_seed, "player")
			if not _plant_geometry_compatible(candidate, accepted, true):
				continue
			accepted.append(candidate)
			plant_number += 1
	if accepted.is_empty():
		return _fail("这里没有可种植的空间")
	for plant in accepted:
		plants.append(plant)
	_next_plant_id = plant_number
	_high_watermark["plant"] = maxi(int(_high_watermark.get("plant", 0)), plant_number - 1)
	_commit(before, "种植植被")
	var ids: Array[String] = []
	for plant in accepted:
		ids.append(plant.id)
	return {"ok": true, "message": "已种下 %d 株植被" % accepted.size(), "plant_ids": ids, "added_count": accepted.size(), "seed": stroke_seed}


func erase_vegetation_stroke(points: Array[Vector2], radius: float) -> Dictionary:
	var check := _validate_erase_stroke(points, radius)
	if not check.ok:
		return check
	var before := snapshot()
	var removed: Array[String] = []
	var kept: Array[Dictionary] = []
	for plant in plants:
		if _distance_to_polyline(Vector2(float(plant.position[0]), float(plant.position[1])), points) <= radius:
			removed.append(plant.id)
		else:
			kept.append(plant)
	if removed.is_empty():
		return {"ok": true, "message": "笔画范围内没有植被", "removed_count": 0, "plant_ids": []}
	plants.assign(kept)
	_commit(before, "移除植被")
	return {"ok": true, "message": "已移除 %d 株植被" % removed.size(), "removed_count": removed.size(), "plant_ids": removed}


## Visibility is intentionally derived. A house or road built after planting
## can hide an instance, while the plant record remains available to undo and
## deterministic replay.
func vegetation_visible(plant: Dictionary) -> bool:
	if not _valid_plant_fields(plant):
		return false
	return _plant_geometry_compatible(plant, [])


func undo() -> Dictionary:
	if _undo.is_empty():
		return _fail("没有可撤销的操作")
	var entry: Dictionary = _undo.pop_back()
	_apply_snapshot(entry.before, true)
	_redo.append(entry)
	revision += 1
	dirty = true
	return {"ok": true, "message": "已撤销：" + entry.label}


func redo() -> Dictionary:
	if _redo.is_empty():
		return _fail("没有可重做的操作")
	var entry: Dictionary = _redo.pop_back()
	_apply_snapshot(entry.after, true)
	_undo.append(entry)
	revision += 1
	dirty = true
	return {"ok": true, "message": "已重做：" + entry.label}


func snapshot() -> Dictionary:
	return {"schema": SCHEMA, "revision": revision, "houses": houses.duplicate(true), "roads": roads.duplicate(true), "plants": plants.duplicate(true), "waters": waters.duplicate(true), "districts": districts.duplicate(true), "next_district_id": _next_district_id, "next_water_id": _next_water_id, "next_house_id": _next_house_id, "next_cell_id": _next_cell_id, "next_road_id": _next_road_id, "next_plant_id": _next_plant_id, "high_watermark": _high_watermark.duplicate(), "life_progress":life_progress.duplicate(),"bakery_supply":bakery_supply.duplicate(true),"journey_checkpoint":journey_checkpoint.duplicate(true)}


func restore(data: Dictionary) -> Dictionary:
	var result := _validate_snapshot(data)
	if not result.ok:
		return result
	_apply_snapshot(data)
	revision = int(data.revision)
	dirty = false
	life_progress_dirty = false
	_undo.clear()
	_redo.clear()
	return {"ok": true, "message": "城市已恢复"}


func save_city(path: String = DEFAULT_PATH) -> Dictionary:
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return _fail("无法写入城市存档")
	file.store_string(JSON.stringify(snapshot(), "\t", true, true))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return _fail("城市存档写入失败")
	var check := _read_snapshot(temp_path)
	if not check.ok:
		return _fail("城市存档回读失败")
	var absolute := ProjectSettings.globalize_path(path)
	var backup_dir := absolute.get_base_dir().path_join("废弃/城市存档")
	if DirAccess.make_dir_recursive_absolute(backup_dir) != OK:
		return _fail("无法创建城市备份目录")
	var backup := backup_dir.path_join(absolute.get_file() + ".previous")
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup):
			var archive := backup + ".%d" % Time.get_ticks_usec()
			if DirAccess.rename_absolute(backup, archive) != OK:
				return _fail("无法保留上一份城市备份")
		if DirAccess.rename_absolute(absolute, backup) != OK:
			return _fail("无法备份当前城市")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), absolute) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, absolute)
		return _fail("无法发布城市存档")
	dirty = false
	life_progress_dirty = false
	return {"ok": true, "message": "城市已保存", "path": path}

func record_life_event(kind: String) -> void:
	if kind not in ["purchases", "gatherings", "concerts"]: return
	life_progress[kind] = int(life_progress[kind])+1
	life_progress_dirty = true
	dirty = true


func bakery_capacity(house_id: String) -> int:
	return bakery_batch_size(house_id) * 6


func bakery_batch_size(house_id: String) -> int:
	var index := _house_index(house_id)
	if index < 0 or houses[index].role != "bakery":
		return 0
	var rooms := 0
	for cell in houses[index].cells:
		if cell.kind == "room":
			rooms += 1
	return maxi(1, rooms)


func bakery_status(house_id: String) -> Dictionary:
	var row: Dictionary = bakery_supply.get(house_id, {})
	var index := _house_index(house_id)
	var opened: bool = index >= 0 and houses[index].role == "bakery" and houses[index].get("bakery_open", true)
	return {"stock":int(row.get("stock", 0)), "produced":int(row.get("produced", 0)), "served":int(row.get("served", 0)), "capacity":bakery_capacity(house_id), "batch_size":bakery_batch_size(house_id), "open":opened}


func set_bakery_open(house_id: String, opened: bool) -> Dictionary:
	var index := _house_index(house_id)
	if index < 0 or houses[index].role != "bakery":
		return _fail("只有面包坊可以开关烘焙")
	if houses[index].get("bakery_open", true) == opened:
		return {"ok":true,"message":""}
	var before := snapshot()
	houses[index].bakery_open = opened
	_commit(before, "继续开炉" if opened else "暂停烘焙")
	return {"ok":true,"message":"已继续开炉" if opened else "已暂停烘焙，现有面包继续供应"}


func produce_bread(house_id: String, quantity: int) -> bool:
	var capacity := bakery_capacity(house_id)
	var current := bakery_status(house_id)
	if capacity == 0 or not current.open or quantity <= 0 or quantity > capacity - int(current.stock):
		return false
	bakery_supply[house_id] = {"stock":int(current.stock) + quantity, "produced":int(current.produced) + quantity, "served":int(current.served)}
	life_progress_dirty = true
	dirty = true
	return true


func serve_bread(house_id: String) -> bool:
	var current := bakery_status(house_id)
	if bakery_capacity(house_id) == 0 or int(current.stock) <= 0:
		return false
	bakery_supply[house_id] = {"stock":int(current.stock) - 1, "produced":int(current.produced), "served":int(current.served) + 1}
	record_life_event("purchases")
	return true


func load_city(path: String = DEFAULT_PATH) -> Dictionary:
	var result := _read_snapshot(path)
	if not result.ok:
		return result
	return restore(result.data)

func set_journey_checkpoint(data: Dictionary) -> Dictionary:
	var check := _validate_journey_checkpoint(data)
	if not check.ok: return check
	if journey_checkpoint != data:
		journey_checkpoint = data.duplicate(true)
		dirty = true
	return {"ok":true,"message":""}

func _validate_journey_checkpoint(data: Variant, house_rows: Variant = null) -> Dictionary:
	if not data is Dictionary: return _fail("居民行程结构无效")
	if data.is_empty(): return {"ok":true}
	if data.get("schema") != 1 or not data.get("residents") is Array or not data.get("concert") is Dictionary:
		return _fail("居民行程版本或结构无效")
	var homes := {}
	for resident in data.residents:
		if not resident is Dictionary or not resident.get("home_id") is String or homes.has(resident.home_id): return _fail("居民行程身份无效")
		homes[resident.home_id] = true
		if not _valid_point(resident.get("position")) or not WORLD_RECT.grow(2).has_point(Vector2(resident.position[0],resident.position[1])): return _fail("居民行程位置无效")
		if not _is_number(resident.get("yaw")) or not _is_number(resident.get("wait")) or resident.wait < 0 or not resident.get("paused") is bool: return _fail("居民行程时间无效")
		if not _is_number(resident.get("phase")): return _fail("居民行程相位无效")
		for key in ["destination_id","dwell_id","service_pending"]:
			if not resident.get(key) is String: return _fail("居民行程目标无效")
		if resident.has("daily_snapshot") and not resident.daily_snapshot is Dictionary: return _fail("居民日常行程无效")
		if resident.has("daily_snapshot"):
			var daily: Dictionary = resident.daily_snapshot
			if daily.has("daily_snapshot"): return _fail("居民日常行程不能递归")
			var daily_check := _validate_journey_checkpoint({"schema":1,"residents":[daily],"concert":{}}, house_rows)
			if not daily_check.ok or daily.get("home_id") != resident.home_id: return _fail("居民日常行程字段无效")
		if resident.has("stops"):
			if not resident.stops is Array: return _fail("居民日常目的地无效")
			for stop in resident.stops:
				if not stop is String: return _fail("居民日常目的地身份无效")
	var concert: Dictionary = data.concert
	if concert.get("phase","idle") not in ["idle","gathering","playing"]: return _fail("街坊演出状态无效")
	if concert.get("phase","idle") != "idle":
		if not concert.get("venue_id") is String or not concert.get("participants") is Array or concert.participants.is_empty(): return _fail("街坊演出成员无效")
		if not _is_number(concert.get("elapsed")) or concert.elapsed < 0 or not _is_number(concert.get("duration")) or concert.duration <= 0 or concert.elapsed > concert.duration: return _fail("街坊演出时间无效")
		var participants := {}
		for home in concert.participants:
			if not home is String or participants.has(home) or not homes.has(home): return _fail("街坊演出成员身份无效")
			participants[home] = true
	if data.has("bakery_workers"):
		if not data.bakery_workers is Array:
			return _fail("面包坊工人行程结构无效")
		var worker_homes := {}
		var worker_bakeries := {}
		var existing := {}
		var rows: Variant = houses if house_rows == null else house_rows
		if not rows is Array:
			return _fail("面包坊工人房屋结构无效")
		for house in rows:
			if house is Dictionary and house.get("id") is String:
				existing[house.id] = true
		for worker in data.bakery_workers:
			if not worker is Dictionary or worker.size() != 8:
				return _fail("面包坊工人行程字段无效")
			for key in ["home_id", "bakery_id"]:
				if not worker.get(key) is String or not existing.has(worker[key]):
					return _fail("面包坊工人房屋身份无效")
			if worker_homes.has(worker.home_id) or worker_bakeries.has(worker.bakery_id):
				return _fail("面包坊工人分配重复")
			worker_homes[worker.home_id] = true
			worker_bakeries[worker.bakery_id] = true
			if not _valid_point(worker.get("position")) or not WORLD_RECT.grow(2).has_point(Vector2(worker.position[0], worker.position[1])) or not _is_number(worker.get("yaw")):
				return _fail("面包坊工人位置无效")
			if worker.get("phase") not in ["walking", "baking", "returning", "resting", "paused"] or worker.get("resume_phase") not in ["walking", "baking", "returning", "resting"]:
				return _fail("面包坊工人阶段无效")
			if worker.phase != "paused" and worker.resume_phase != worker.phase:
				return _fail("面包坊工人恢复阶段无效")
			if not _is_number(worker.get("elapsed")) or worker.elapsed < 0 or worker.elapsed > 6:
				return _fail("面包坊工人工作时间无效")
			if worker.resume_phase == "resting" and worker.elapsed > 4 or worker.resume_phase in ["walking", "returning"] and worker.elapsed != 0:
				return _fail("面包坊工人阶段时间无效")
			if not _is_integer(worker.get("batches")) or worker.batches < 0 or worker.batches > 3:
				return _fail("面包坊工人批次无效")
	return {"ok":true}


func _generate_initial_plants() -> void:
	# Keep the renderer's authored grove layout deterministic. Consume the same
	# random streams used by _build_landscape before reaching its eight groves.
	var rng := RandomNumberGenerator.new()
	rng.seed = 261014
	for ignored in range(75):
		var x := rng.randf_range(-27.0, 27.0)
		var z := rng.randf_range(-25.0, 25.0)
		if water_clearance(Vector2(x, z)) < 0.3:
			continue
		rng.randf_range(1.0, 3.4)
		for contour in range(10):
			rng.randf_range(0.78, 1.20)
	for ignored in range(34):
		rng.randf_range(-26.0, 26.0)
		rng.randf_range(-1.55, 1.55)
		rng.randf_range(0.15, 0.65)
	var groves := [Vector2(-14, -9), Vector2(-16, 7), Vector2(13, -9), Vector2(14, 8), Vector2(-7, 14), Vector2(8, 17), Vector2(-19, -18), Vector2(18, -19)]
	var number := 1
	for grove: Vector2 in groves:
		for index in range(7):
			var position := grove + Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(-2.7, 2.7))
			var scale_value := rng.randf_range(0.75, 1.3)
			if not WORLD_RECT.has_point(position):
				continue
			var kind := "cypress" if index % 3 == 0 else "olive"
			var plant := _make_plant("p%d" % number, position, kind, scale_value, 261014 + number * 977, "seed")
			if not _plant_geometry_compatible(plant, plants):
				continue
			plants.append(plant)
			number += 1
	_next_plant_id = number
	_high_watermark["plant"] = number - 1


func _make_plant(id: String, position: Vector2, kind: String, scale_value: float, plant_seed: int, source: String) -> Dictionary:
	return {"id": id, "position": [position.x, position.y], "kind": kind, "scale": scale_value, "seed": plant_seed, "source": source}


func _validate_vegetation_stroke(points: Array[Vector2], kind: String, radius: float) -> Dictionary:
	if points.is_empty() or kind not in ["olive", "cypress", "shrub"] or not is_finite(radius) or radius <= 0.0 or radius > 8.0:
		return _fail("无效的植被笔画")
	for point in points:
		if not is_finite(point.x) or not is_finite(point.y) or not WORLD_RECT.has_point(point):
			return _fail("植被笔画超出了河湾范围")
	return {"ok": true, "message": ""}


func _validate_erase_stroke(points: Array[Vector2], radius: float) -> Dictionary:
	if points.is_empty() or not is_finite(radius) or radius <= 0.0 or radius > 12.0:
		return _fail("无效的植被擦除笔画")
	for point in points:
		if not is_finite(point.x) or not is_finite(point.y) or not WORLD_RECT.has_point(point):
			return _fail("植被擦除笔画超出了河湾范围")
	return {"ok": true, "message": ""}


func _stroke_samples(points: Array[Vector2], radius: float) -> Array[Vector2]:
	var samples: Array[Vector2] = []
	samples.append(points[0])
	var spacing := maxf(0.65, radius * 0.78)
	var remaining := spacing
	for index in range(1, points.size()):
		var start: Vector2 = points[index - 1]
		var finish: Vector2 = points[index]
		var length := start.distance_to(finish)
		while length >= remaining:
			start = start.move_toward(finish, remaining)
			samples.append(start)
			length = start.distance_to(finish)
			remaining = spacing
			if samples.size() >= MAX_PLANTS_PER_STROKE * 2:
				return samples
		remaining -= length
	if samples[-1].distance_to(points[-1]) >= spacing * 0.5:
		samples.append(points[-1])
	return samples


func _vegetation_stroke_seed(points: Array[Vector2], kind: String, radius: float) -> int:
	var seed_value := 261014 + int(_high_watermark.get("plant", 0)) * 977 + kind.hash() % 997
	seed_value += int(round(radius * 100.0)) * 37
	for point in _stroke_samples(points, radius):
		seed_value = posmod(seed_value * 131 + int(round(point.x * 100.0)) * 17 + int(round(point.y * 100.0)) * 31, 2147483647)
	return maxi(1, seed_value)


func _plant_scale(kind: String, rng: RandomNumberGenerator) -> float:
	if kind == "shrub":
		return rng.randf_range(0.65, 1.05)
	return rng.randf_range(0.78, 1.22)


func _valid_plant_fields(plant: Dictionary) -> bool:
	if not plant.get("id", "") is String or not plant.get("id", "").begins_with("p"):
		return false
	if not _valid_point(plant.get("position")) or plant.get("kind") not in ["olive", "cypress", "shrub"]:
		return false
	if not _is_number(plant.get("scale")) or float(plant.scale) <= 0.0 or not _is_integer(plant.get("seed")):
		return false
	return plant.get("source", "seed") in ["seed", "player"]


func _plant_geometry_compatible(plant: Dictionary, extra: Array, include_existing: bool = false) -> bool:
	if not _valid_plant_fields(plant):
		return false
	var position := Vector2(float(plant.position[0]), float(plant.position[1]))
	var scale_value := float(plant.scale)
	var clearance := 0.42 * scale_value if plant.kind == "shrub" else 0.72 * scale_value
	if not WORLD_RECT.has_point(position):
		return false
	if water_clearance(position) <= clearance:
		return false
	for house in houses:
		for cell in house.cells:
			if cell.level != 0:
				continue
			var center := Vector2(float(house.origin[0]) + int(cell.x) * CELL_UNIT, float(house.origin[1]) + int(cell.z) * CELL_UNIT)
			var footprint := Rect2(center - Vector2.ONE * CELL_UNIT * 0.5, Vector2.ONE * CELL_UNIT).grow(clearance)
			if footprint.has_point(position):
				return false
			if cell.kind == "room":
				var front_occupied := false
				for neighbor in house.cells:
					if neighbor.level == 0 and neighbor.x == cell.x and neighbor.z == cell.z + 1:
						front_occupied = true
						break
				if not front_occupied and position.distance_to(center + Vector2(0, 1.55)) <= 0.95 + clearance:
					return false
	for road in roads:
		for index in range(1, road.points.size()):
			var a := Vector2(float(road.points[index - 1][0]), float(road.points[index - 1][1]))
			var b := Vector2(float(road.points[index][0]), float(road.points[index][1]))
			if _distance_to_segment(position, a, b) <= float(road.width) * 0.5 + 0.45 + clearance:
				return false
	var all_plants: Array = []
	if include_existing:
		all_plants.append_array(plants)
	all_plants.append_array(extra)
	for other in all_plants:
		if other.get("id", "") == plant.get("id", ""):
			continue
		if not _valid_point(other.get("position")):
			continue
		var other_position := Vector2(float(other.position[0]), float(other.position[1]))
		var other_clearance := 0.42 * float(other.get("scale", 1.0)) if other.get("kind", "olive") == "shrub" else 0.72 * float(other.get("scale", 1.0))
		if position.distance_to(other_position) < clearance + other_clearance + 0.18:
			return false
	return true


func _distance_to_polyline(point: Vector2, points: Array[Vector2]) -> float:
	if points.size() == 1:
		return point.distance_to(points[0])
	var nearest := INF
	for index in range(1, points.size()):
		nearest = minf(nearest, _distance_to_segment(point, points[index - 1], points[index]))
	return nearest


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var length_squared := a.distance_squared_to(b)
	if length_squared <= 0.000001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(b - a) / length_squared, 0.0, 1.0)
	return point.distance_to(a.lerp(b, t))


func _make_house(position: Vector2, palette: int) -> Dictionary:
	var id := "h%d" % _next_house_id
	_next_house_id += 1
	return {"id": id, "name": "石榴巷%d号" % (_next_house_id - 1), "role": "residential", "bakery_open":true, "origin": [position.x, position.y], "cells": [_make_cell(0, 0, 0, "room")], "palette": palette, "seed": 81000 + palette * 977}


static func river_x(z: float) -> float:
	return 3.0 + sin(z * 0.17) * 0.52


func _make_cell(x: int, z: int, level: int, kind: String) -> Dictionary:
	var id := "c%d" % _next_cell_id
	_next_cell_id += 1
	return {"id": id, "x": x, "z": z, "level": level, "kind": kind, "source": "seed"}


func _commit(before: Dictionary, label: String) -> void:
	revision += 1
	dirty = true
	_undo.append({"before": before, "after": snapshot(), "label": label})
	_redo.clear()


func _house_index(id: String) -> int:
	for i in range(houses.size()):
		if houses[i].id == id:
			return i
	return -1


func _supported(cell: Dictionary, cells: Array) -> bool:
	for other in cells:
		if other.kind != "room":
			continue
		if other.x == cell.x and other.z == cell.z and other.level == cell.level - 1:
			return true
		if cell.kind == "terrace" and other.level == cell.level and abs(other.x - cell.x) + abs(other.z - cell.z) == 1:
			return true
	return false


func _validate_house(house: Dictionary) -> Dictionary:
	if house.cells.is_empty():
		return _fail("保留房屋的最后一块")
	var grounds: Dictionary = {}
	var locations: Dictionary = {}
	for cell in house.cells:
		var location := "%d:%d:%d" % [cell.x, cell.z, cell.level]
		if locations.has(location):
			return _fail("房屋模块重叠")
		locations[location] = true
		if cell.level == 0:
			grounds[Vector2i(int(cell.x), int(cell.z))] = true
		elif not _supported(cell, house.cells):
			return _fail("上层需要下方房间支撑")
	if grounds.is_empty():
		return _fail("房屋需要地基")
	var visited: Dictionary = {}
	var queue: Array = [grounds.keys()[0]]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_back()
		if visited.has(current):
			continue
		visited[current] = true
		for direction in DIRECTIONS:
			var neighbor: Vector2i = current + direction
			if grounds.has(neighbor) and not visited.has(neighbor):
				queue.append(neighbor)
	if visited.size() != grounds.size():
		return _fail("房屋地基需要保持相连")
	return {"ok": true, "message": ""}


func _house_overlaps(candidate: Dictionary, except_id: String = "") -> bool:
	for house in houses:
		if house.id == except_id:
			continue
		if _pair_overlaps(candidate, house):
			return true
	return false


func _pair_overlaps(first: Dictionary, second: Dictionary) -> bool:
	for a in first.cells:
		for b in second.cells:
			if a.level != b.level:
				continue
			var dx: float = abs(float(first.origin[0]) + int(a.x) * CELL_UNIT - float(second.origin[0]) - int(b.x) * CELL_UNIT)
			var dz: float = abs(float(first.origin[1]) + int(a.z) * CELL_UNIT - float(second.origin[1]) - int(b.z) * CELL_UNIT)
			if dx < CELL_UNIT - 0.001 and dz < CELL_UNIT - 0.001:
				return true
	return false


func _apply_snapshot(data: Dictionary, preserve_issued_ids: bool = false) -> void:
	# Editing history restores geometry; completed daily visits remain history.
	if not preserve_issued_ids:
		var progress: Dictionary = data.get("life_progress", {"purchases":0,"gatherings":0})
		life_progress = {"purchases":int(progress.get("purchases",0)),"gatherings":int(progress.get("gatherings",0)),"concerts":int(progress.get("concerts",0))}
		bakery_supply = data.get("bakery_supply", {}).duplicate(true)
		for row in bakery_supply.values():
			for key in ["stock", "produced", "served"]:
				row[key] = int(row[key])
		journey_checkpoint = data.get("journey_checkpoint",{}).duplicate(true)
		if not journey_checkpoint.is_empty():
			journey_checkpoint.schema = 1
			for worker in journey_checkpoint.get("bakery_workers", []):
				worker.batches = int(worker.batches)
	houses.assign(data.houses.duplicate(true))
	roads.assign(data.roads.duplicate(true))
	waters.assign(data.get("waters", []).duplicate(true))
	for water in waters:
		water.seed = int(water.seed)
		water.width = float(water.width)
		for index in range(water.points.size()):
			var point := Vector2(float(water.points[index][0]), float(water.points[index][1]))
			water.points[index] = [point.x, point.y]
	_next_water_id = int(data.get("next_water_id", 1))
	districts.assign(data.get("districts", []).duplicate(true))
	for district in districts:
		district.width = Vector2(float(district.width), 0).x
		for index in range(district.points.size()):
			var point := Vector2(float(district.points[index][0]), float(district.points[index][1]))
			district.points[index] = [point.x, point.y]
	_next_district_id = int(data.get("next_district_id", 1))
	# JSON numbers enter as floats; restore the authoritative integer fields.
	for house in houses:
		house.name = house.get("name", "石榴巷%s号" % house.id.substr(1))
		house.role = house.get("role", "residential")
		house.bakery_open = house.get("bakery_open", true)
		house.palette = int(house.palette)
		house.seed = int(house.seed)
		var origin := Vector2(float(house.origin[0]), float(house.origin[1]))
		house.origin = [origin.x, origin.y]
		for cell in house.cells:
			cell.source = cell.get("source", "seed")
			cell.x = int(cell.x)
			cell.z = int(cell.z)
			cell.level = int(cell.level)
	for road in roads:
		road.source = road.get("source", "seed")
		road.width = float(road.width)
		road.bridge = road.get("bridge", false)
		for i in range(road.points.size()):
			var point := Vector2(float(road.points[i][0]), float(road.points[i][1]))
			road.points[i] = [point.x, point.y]
	var had_plants := data.get("plants") is Array
	plants.clear()
	if had_plants:
		plants.assign(data.plants.duplicate(true))
		for plant in plants:
			var position := Vector2(float(plant.position[0]), float(plant.position[1]))
			plant.position = [position.x,position.y]
			plant.kind = str(plant.kind)
			plant.scale = Vector2(float(plant.scale),0).x
			plant.seed = int(plant.seed)
			plant.source = plant.get("source", "seed")
	_next_house_id = int(data.next_house_id)
	_next_cell_id = int(data.next_cell_id)
	_next_road_id = int(data.next_road_id)
	var max_plant := 0
	for plant in plants:
		max_plant = maxi(max_plant, int(str(plant.id).substr(1)))
	var issued: Dictionary = data.get("high_watermark", {"house": _next_house_id - 1, "cell": _next_cell_id - 1, "road": _next_road_id - 1, "plant": max_plant})
	for kind in ["house", "cell", "road", "plant", "water", "district"]:
		var default_issued := max_plant if kind == "plant" else (int(data.get("next_%s_id" % kind, 1)) - 1)
		var issued_value := int(issued.get(kind, default_issued))
		_high_watermark[kind] = maxi(int(_high_watermark.get(kind, 0)), issued_value) if preserve_issued_ids else issued_value
	if data.has("next_plant_id"):
		_next_plant_id = int(data.next_plant_id)
	else:
		_next_plant_id = max_plant + 1
	if not had_plants:
		var preserved_plant_watermark := int(_high_watermark.get("plant", 0))
		_generate_initial_plants()
		_high_watermark["plant"] = maxi(int(_high_watermark.get("plant", 0)), preserved_plant_watermark)
		_next_plant_id = maxi(_next_plant_id, int(_high_watermark["plant"]) + 1)


func _read_snapshot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _fail("还没有保存的城市")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("无法读取城市存档")
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK or not json.data is Dictionary:
		return _fail("城市存档损坏，当前城市已保留")
	var result := _validate_snapshot(json.data)
	if result.ok:
		result.data = json.data
	return result


func _validate_snapshot(data: Dictionary) -> Dictionary:
	var progress: Variant = data.get("life_progress", {"purchases":0,"gatherings":0})
	if not progress is Dictionary: return _fail("城市存档生活进展无效")
	for key in ["purchases", "gatherings", "concerts"]:
		if not _is_integer(progress.get(key,0)) or progress.get(key,0) < 0:
			return _fail("城市存档生活进展无效")
	var journeys := _validate_journey_checkpoint(data.get("journey_checkpoint",{}), data.get("houses"))
	if not journeys.ok: return journeys
	if data.get("schema") != SCHEMA:
		return _fail("不支持的城市存档版本")
	for key in ["revision", "next_house_id", "next_cell_id", "next_road_id"]:
		if not _is_integer(data.get(key)) or data[key] < (0 if key == "revision" else 1):
			return _fail("城市存档计数无效")
	if not _is_integer(data.get("next_plant_id", 1)):
		return _fail("城市存档植被身份计数无效")
	var next_plant_id := int(data.get("next_plant_id", 1))
	if not _is_integer(data.get("next_water_id", 1)) or int(data.get("next_water_id", 1)) < 1:
		return _fail("城市存档水域身份计数无效")
	var next_water_id := int(data.get("next_water_id", 1))
	if not _is_integer(data.get("next_district_id", 1)) or int(data.get("next_district_id", 1)) < 1:
		return _fail("城市存档街坊身份计数无效")
	var next_district_id := int(data.get("next_district_id", 1))
	var issued: Variant = data.get("high_watermark", {"house": data.next_house_id - 1, "cell": data.next_cell_id - 1, "road": data.next_road_id - 1, "plant": next_plant_id - 1})
	if not issued is Dictionary:
		return _fail("城市存档身份高水位无效")
	for kind in ["house", "cell", "road"]:
		if not _is_integer(issued.get(kind)) or issued[kind] < data["next_%s_id" % kind] - 1:
			return _fail("城市存档身份高水位无效")
	if next_plant_id < 1 or not _is_integer(issued.get("plant", 0)) or int(issued.get("plant", 0)) < next_plant_id - 1:
		return _fail("城市存档植被身份高水位无效")
	if not _is_integer(issued.get("water", next_water_id - 1)) or int(issued.get("water", next_water_id - 1)) < next_water_id - 1:
		return _fail("城市存档水域身份高水位无效")
	if not _is_integer(issued.get("district", next_district_id - 1)) or int(issued.get("district", next_district_id - 1)) < next_district_id - 1:
		return _fail("城市存档街坊身份高水位无效")
	if not data.get("districts", []) is Array:
		return _fail("城市存档街坊结构无效")
	if not data.get("waters", []) is Array:
		return _fail("城市存档水域结构无效")
	if not data.get("houses") is Array or not data.get("roads") is Array:
		return _fail("城市存档结构无效")
	var ids: Dictionary = {}
	var max_house := 0
	var max_cell := 0
	var max_road := 0
	var max_plant := 0
	var max_water := 0
	var max_district := 0
	for district in data.get("districts", []):
		if not district is Dictionary or not _valid_id(district.get("id"), "d", ids):
			return _fail("城市存档街坊身份无效")
		var district_valid := _validate_district_fields(district)
		if not district_valid.ok:
			return district_valid
		max_district = maxi(max_district, int(district.id.substr(1)))
	if next_district_id <= max_district:
		return _fail("城市存档街坊身份计数冲突")
	var water_rows: Array = data.get("waters", [])
	for water in water_rows:
		if not water is Dictionary or not _valid_id(water.get("id"), "w", ids):
			return _fail("城市存档水域身份无效")
		if not _is_integer(water.get("seed")) or water.get("source") != "player":
			return _fail("城市存档水域来源或种子无效")
		var water_valid := _validate_water_fields(water)
		if not water_valid.ok:
			return water_valid
		max_water = maxi(max_water, int(water.id.substr(1)))
	if next_water_id <= max_water:
		return _fail("城市存档水域身份计数冲突")
	for house in data.houses:
		if not house is Dictionary or not _valid_id(house.get("id"), "h", ids):
			return _fail("城市存档房屋身份无效")
		max_house = maxi(max_house, int(house.id.substr(1)))
		if not _valid_point(house.get("origin")) or not house.get("cells") is Array or not _is_integer(house.get("palette")) or house.palette < 0 or not _is_integer(house.get("seed")):
			return _fail("城市存档房屋字段无效")
		if not house.get("name", "默认名字") is String or house.get("name", "默认名字").strip_edges().is_empty() or house.get("role", "residential") not in HOUSE_ROLES:
			return _fail("城市存档名字或用途无效")
		if not house.get("bakery_open", true) is bool:
			return _fail("城市存档烘焙开关无效")
		for cell in house.cells:
			if not cell is Dictionary or not _valid_id(cell.get("id"), "c", ids):
				return _fail("城市存档模块身份无效")
			max_cell = maxi(max_cell, int(cell.id.substr(1)))
			for key in ["x", "z", "level"]:
				if not _is_integer(cell.get(key)):
					return _fail("城市存档模块坐标无效")
			if cell.level < 0 or cell.get("kind") not in ["room", "terrace"]:
				return _fail("城市存档模块类型无效")
			if cell.get("source", "seed") not in ["seed", "player", "new_house"]:
				return _fail("城市存档模块来源无效")
		var valid := _validate_house(house)
		if not valid.ok:
			return valid
	for i in range(data.houses.size()):
		for j in range(i):
			if _pair_overlaps(data.houses[i], data.houses[j]):
				return _fail("城市存档房屋重叠")
	var supply: Variant = data.get("bakery_supply", {})
	if not supply is Dictionary:
		return _fail("城市存档面包供给结构无效")
	for house_id in supply:
		var supply_ids := {}
		if not _valid_id(house_id, "h", supply_ids) or int(house_id.substr(1)) > int(issued.house):
			return _fail("城市存档面包供给房屋无效")
		var row: Variant = supply[house_id]
		if not row is Dictionary or row.size() != 3:
			return _fail("城市存档面包供给字段无效")
		for key in ["stock", "produced", "served"]:
			if not _is_integer(row.get(key)) or row[key] < 0:
				return _fail("城市存档面包供给计数无效")
		if row.served > row.produced or row.stock != row.produced - row.served:
			return _fail("城市存档面包供给收支不一致")
	for road in data.roads:
		if not road is Dictionary or not _valid_id(road.get("id"), "r", ids):
			return _fail("城市存档道路身份无效")
		max_road = maxi(max_road, int(road.id.substr(1)))
		if not road.get("points") is Array or road.points.size() < 2 or not _is_number(road.get("width")) or road.width <= 0:
			return _fail("城市存档道路字段无效")
		if not road.get("bridge", false) is bool:
			return _fail("城市存档桥梁字段无效")
		if road.get("source", "seed") not in ["seed", "player"]:
			return _fail("城市存档道路来源无效")
		for point in road.points:
			if not _valid_point(point):
				return _fail("城市存档道路位置无效")
	if data.has("plants"):
		if not data.plants is Array:
			return _fail("城市存档植被结构无效")
		for plant in data.plants:
			if not plant is Dictionary or not _valid_id(plant.get("id"), "p", ids):
				return _fail("城市存档植被身份无效")
			max_plant = maxi(max_plant, int(str(plant.id).substr(1)))
			if not _valid_point(plant.get("position")) or not WORLD_RECT.has_point(Vector2(float(plant.position[0]), float(plant.position[1]))):
				return _fail("城市存档植被位置无效")
			if plant.get("kind") not in ["olive", "cypress", "shrub"] or not _is_number(plant.get("scale")) or float(plant.scale) <= 0.0 or float(plant.scale) > 8.0 or not _is_integer(plant.get("seed")):
				return _fail("城市存档植被字段无效")
			if plant.get("source", "seed") not in ["seed", "player"]:
				return _fail("城市存档植被来源无效")
			# Authored plants may be submerged by a later player stroke and
			# retained as hidden intent. The immutable original river has no
			# such edit history, so an initial plant inside it is invalid.
			if _water_clearance_in(Vector2(float(plant.position[0]), float(plant.position[1])), []) <= 0.0:
				return _fail("城市存档植被不能位于河水中")
	if data.next_house_id <= max_house or data.next_cell_id <= max_cell or data.next_road_id <= max_road or next_plant_id <= max_plant:
		return _fail("城市存档身份计数冲突")
	# Validate the candidate world, never the currently open city. Restoring
	# may not bypass the same land, wall-clearance and bridge rules as edits.
	for house in data.houses:
		var site := _validate_house_site(house, [], water_rows)
		if not site.ok:
			return site
	for road in data.roads:
		var site := _validate_road_site(road.points, float(road.width), data.houses, water_rows)
		if not site.ok:
			return site
		if road.get("bridge", false) != site.bridge:
			return _fail("城市存档桥梁标记与占地不一致")
	return {"ok": true, "message": ""}


func _validate_house_site(house: Dictionary, road_rows: Variant = null, water_rows: Variant = null) -> Dictionary:
	var scene_roads: Array = roads if road_rows == null else road_rows
	var scene_waters: Array = waters if water_rows == null else water_rows
	for cell in house.cells:
		var center := Vector2(float(house.origin[0]) + cell.x * CELL_UNIT, float(house.origin[1]) + cell.z * CELL_UNIT)
		var footprint := Rect2(center - Vector2.ONE * CELL_UNIT * 0.5, Vector2.ONE * CELL_UNIT)
		if not WORLD_RECT.encloses(footprint):
			return _fail("这里超出了河湾范围")
		for i in range(5):
			var sample_z := lerpf(footprint.position.y, footprint.end.y, float(i) / 4.0)
			var nearest_to_river := Vector2(clampf(river_x(sample_z), footprint.position.x, footprint.end.x), sample_z)
			if _water_clearance_in(nearest_to_river, scene_waters) < 0.0:
				return _fail("房屋不能建在河水中")
		for water in scene_waters:
			if _stroke_hits_rect(water.points, float(water.width) * 0.5, footprint):
				return _fail("房屋不能建在水域中")
		if cell.level == 0:
			for road in scene_roads:
				for i in range(1, road.points.size()):
					if _segment_hits_rect(Vector2(road.points[i - 1][0], road.points[i - 1][1]), Vector2(road.points[i][0], road.points[i][1]), footprint.grow(float(road.width) * 0.5 - 0.05)):
						return _fail("这里需要给道路留出空间")
	return {"ok": true, "message": ""}


func _validate_road_site(points: Array, width: float, house_rows: Variant = null, water_rows: Variant = null) -> Dictionary:
	var scene_houses: Array = houses if house_rows == null else house_rows
	var scene_waters: Array = waters if water_rows == null else water_rows
	var bridge_valid := _road_water_crossings(points, width, scene_waters)
	if not bridge_valid.ok:
		return bridge_valid
	var bridge: bool = bridge_valid.bridge
	var length := 0.0
	for point in points:
		if not WORLD_RECT.has_point(Vector2(point[0], point[1])):
			return _fail("道路超出了河湾范围")
	for i in range(1, points.size()):
		var a := Vector2(points[i - 1][0], points[i - 1][1])
		var b := Vector2(points[i][0], points[i][1])
		length += a.distance_to(b)
		for house in scene_houses:
			for cell in house.cells:
				if cell.level != 0:
					continue
				var center := Vector2(float(house.origin[0]) + cell.x * CELL_UNIT, float(house.origin[1]) + cell.z * CELL_UNIT)
				var wall := Rect2(center - Vector2.ONE * CELL_UNIT * 0.5, Vector2.ONE * CELL_UNIT)
				if _segment_hits_rect(a, b, wall.grow(-0.03)):
					return _fail("道路不能穿过房屋")
				var check_a := a
				var check_b := b
				# A terminal on an exterior wall can join the doorway. Trim its
				# cap for clearance testing, but never permit the line inside.
				if i == 1 and wall.grow(0.1).has_point(a) and not wall.grow(-0.03).has_point(a):
					check_a = a.move_toward(b, minf(width * 0.55, a.distance_to(b)))
				if i == points.size() - 1 and wall.grow(0.1).has_point(b) and not wall.grow(-0.03).has_point(b):
					check_b = b.move_toward(a, minf(width * 0.55, a.distance_to(b)))
				if _segment_hits_rect(check_a, check_b, wall.grow(width * 0.5 - 0.04)):
					return _fail("道路需要避开房屋墙面")
	if length < 0.2:
		return _fail("道路太短")
	return {"ok": true, "message": "", "bridge": bridge}


## Sample contact over the whole stroke, rather than requiring the entire
## road to start and finish on opposite sides of the immutable base river.
## Each contact run must have dry abutments and cross actual water; a bank
## skim or longitudinal canal path cannot masquerade as a bridge.
func _road_water_crossings(points: Array, width: float, rows: Array) -> Dictionary:
	var samples: Array[Dictionary] = []
	for index in range(1, points.size()):
		var a := Vector2(points[index - 1][0], points[index - 1][1])
		var b := Vector2(points[index][0], points[index][1])
		var count := maxi(1, int(ceil(a.distance_to(b) / 0.12)))
		var direction := (b - a).normalized()
		for step in range(count + 1):
			if index > 1 and step == 0:
				continue
			var position := a.lerp(b, float(step) / float(count))
			var clearance := _water_clearance_in(position, rows)
			if clearance < width * 0.5:
				var base_clearance := absf(position.x - river_x(position.y)) - RIVER_HALF_WIDTH
				if base_clearance < width * 0.5 and (absf(direction.x) < absf(direction.y) * 1.5 or absf(direction.x) < 0.001):
					return _fail("桥梁需要横向跨河，不能沿水面铺路")
				for water in rows:
					if water.points.size() < 2 or _water_stroke_distance(position, water.points) >= (float(water.width) + width) * 0.5:
						continue
					var nearest := INF
					var tangent := Vector2.ZERO
					for water_index in range(1, water.points.size()):
						var c := Vector2(water.points[water_index - 1][0], water.points[water_index - 1][1])
						var d := Vector2(water.points[water_index][0], water.points[water_index][1])
						var distance := _distance_to_segment(position, c, d)
						if distance < nearest and c.distance_squared_to(d) > 0.00001:
							nearest = distance
							tangent = (d - c).normalized()
					if tangent != Vector2.ZERO and absf(direction.dot(tangent)) > 0.8:
						return _fail("桥梁需要横跨水岸，不能沿水域铺路")
			samples.append({"position": position, "clearance": clearance})
	var bridge := false
	var run_start := -1
	var entered_water := false
	for index in range(samples.size()):
		if float(samples[index].clearance) < width * 0.5:
			bridge = true
			if run_start < 0:
				run_start = index
				entered_water = false
			entered_water = entered_water or float(samples[index].clearance) < -0.05
		elif run_start >= 0:
			if run_start == 0 or not entered_water:
				return _fail("桥梁需要完整连接两岸，不能停在水中或擦过岸边")
			run_start = -1
	if run_start >= 0:
		return _fail("桥梁需要完整连接两岸")
	return {"ok": true, "message": "", "bridge": bridge}


func _segment_hits_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var lower := 0.0
	var upper := 1.0
	for axis in range(2):
		var delta := b[axis] - a[axis]
		if absf(delta) < 0.00001:
			if a[axis] < rect.position[axis] or a[axis] > rect.end[axis]:
				return false
		else:
			var first := (rect.position[axis] - a[axis]) / delta
			var second := (rect.end[axis] - a[axis]) / delta
			lower = maxf(lower, minf(first, second))
			upper = minf(upper, maxf(first, second))
			if lower > upper:
				return false
	return true


func _valid_id(value: Variant, prefix: String, ids: Dictionary) -> bool:
	if not value is String or not value.begins_with(prefix):
		return false
	var suffix: String = value.substr(1)
	if not suffix.is_valid_int() or int(suffix) < 1 or value != prefix + str(int(suffix)) or ids.has(value):
		return false
	ids[value] = true
	return true


func _valid_point(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _is_number(value[0]) and _is_number(value[1])


func _is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


func _is_integer(value: Variant) -> bool:
	return _is_number(value) and float(value) == floor(float(value))


func _fail(message: String) -> Dictionary:
	return {"ok": false, "message": message}
