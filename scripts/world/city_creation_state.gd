class_name CityCreationState
extends RefCounted

## Authoritative, immediate state for the independent city creation slice.
const SCHEMA := 1
const CELL_UNIT := 1.8
const FLOOR_HEIGHT := 1.7
const DEFAULT_PATH := "user://city_creation_v1.json"
const WORLD_RECT := Rect2(-18.0, -15.0, 35.0, 30.0)
const RIVER_HALF_WIDTH := 2.3
const HOUSE_ROLES := ["residential", "bakery", "venue"]
const DIRECTIONS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var houses: Array[Dictionary] = []
var roads: Array[Dictionary] = []
var revision := 0
var dirty := false
var _next_house_id := 1
var _next_cell_id := 1
var _next_road_id := 1
var _high_watermark := {"house": 0, "cell": 0, "road": 0}
var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []


func initialize() -> void:
	houses.clear()
	roads.clear()
	_next_house_id = 1
	_next_cell_id = 1
	_next_road_id = 1
	_high_watermark = {"house": 0, "cell": 0, "road": 0}
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
	_high_watermark = {"house": _next_house_id - 1, "cell": _next_cell_id - 1, "road": _next_road_id - 1}
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
	var house := {"id": "h%d" % house_number, "name": "石榴巷%d号" % house_number, "role": "residential", "origin": [position.x, position.y], "cells": [{"id": "c%d" % cell_number, "x": 0, "z": 0, "level": 0, "kind": "room", "source": "new_house"}], "palette": (house_number - 1) % 6, "seed": 81000 + house_number * 977}
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
	return {"schema": SCHEMA, "revision": revision, "houses": houses.duplicate(true), "roads": roads.duplicate(true), "next_house_id": _next_house_id, "next_cell_id": _next_cell_id, "next_road_id": _next_road_id, "high_watermark": _high_watermark.duplicate()}


func restore(data: Dictionary) -> Dictionary:
	var result := _validate_snapshot(data)
	if not result.ok:
		return result
	_apply_snapshot(data)
	revision = int(data.revision)
	dirty = false
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
	return {"ok": true, "message": "城市已保存", "path": path}


func load_city(path: String = DEFAULT_PATH) -> Dictionary:
	var result := _read_snapshot(path)
	if not result.ok:
		return result
	return restore(result.data)


func _make_house(position: Vector2, palette: int) -> Dictionary:
	var id := "h%d" % _next_house_id
	_next_house_id += 1
	return {"id": id, "name": "石榴巷%d号" % (_next_house_id - 1), "role": "residential", "origin": [position.x, position.y], "cells": [_make_cell(0, 0, 0, "room")], "palette": palette, "seed": 81000 + palette * 977}


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
	houses.assign(data.houses.duplicate(true))
	roads.assign(data.roads.duplicate(true))
	# JSON numbers enter as floats; restore the authoritative integer fields.
	for house in houses:
		house.name = house.get("name", "石榴巷%s号" % house.id.substr(1))
		house.role = house.get("role", "residential")
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
	_next_house_id = int(data.next_house_id)
	_next_cell_id = int(data.next_cell_id)
	_next_road_id = int(data.next_road_id)
	var issued: Dictionary = data.get("high_watermark", {"house": _next_house_id - 1, "cell": _next_cell_id - 1, "road": _next_road_id - 1})
	for kind in ["house", "cell", "road"]:
		_high_watermark[kind] = maxi(int(_high_watermark[kind]), int(issued[kind])) if preserve_issued_ids else int(issued[kind])


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
	if data.get("schema") != SCHEMA:
		return _fail("不支持的城市存档版本")
	for key in ["revision", "next_house_id", "next_cell_id", "next_road_id"]:
		if not _is_integer(data.get(key)) or data[key] < (0 if key == "revision" else 1):
			return _fail("城市存档计数无效")
	var issued: Variant = data.get("high_watermark", {"house": data.next_house_id - 1, "cell": data.next_cell_id - 1, "road": data.next_road_id - 1})
	if not issued is Dictionary:
		return _fail("城市存档身份高水位无效")
	for kind in ["house", "cell", "road"]:
		if not _is_integer(issued.get(kind)) or issued[kind] < data["next_%s_id" % kind] - 1:
			return _fail("城市存档身份高水位无效")
	if not data.get("houses") is Array or not data.get("roads") is Array:
		return _fail("城市存档结构无效")
	var ids: Dictionary = {}
	var max_house := 0
	var max_cell := 0
	var max_road := 0
	for house in data.houses:
		if not house is Dictionary or not _valid_id(house.get("id"), "h", ids):
			return _fail("城市存档房屋身份无效")
		max_house = maxi(max_house, int(house.id.substr(1)))
		if not _valid_point(house.get("origin")) or not house.get("cells") is Array or not _is_integer(house.get("palette")) or house.palette < 0 or not _is_integer(house.get("seed")):
			return _fail("城市存档房屋字段无效")
		if not house.get("name", "默认名字") is String or house.get("name", "默认名字").strip_edges().is_empty() or house.get("role", "residential") not in HOUSE_ROLES:
			return _fail("城市存档名字或用途无效")
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
	if data.next_house_id <= max_house or data.next_cell_id <= max_cell or data.next_road_id <= max_road:
		return _fail("城市存档身份计数冲突")
	# Validate the candidate world, never the currently open city. Restoring
	# may not bypass the same land, wall-clearance and bridge rules as edits.
	for house in data.houses:
		var site := _validate_house_site(house, [])
		if not site.ok:
			return site
	for road in data.roads:
		var site := _validate_road_site(road.points, float(road.width), data.houses)
		if not site.ok:
			return site
		if road.get("bridge", false) != site.bridge:
			return _fail("城市存档桥梁标记与占地不一致")
	return {"ok": true, "message": ""}


func _validate_house_site(house: Dictionary, road_rows: Variant = null) -> Dictionary:
	var scene_roads: Array = roads if road_rows == null else road_rows
	for cell in house.cells:
		var center := Vector2(float(house.origin[0]) + cell.x * CELL_UNIT, float(house.origin[1]) + cell.z * CELL_UNIT)
		var footprint := Rect2(center - Vector2.ONE * CELL_UNIT * 0.5, Vector2.ONE * CELL_UNIT)
		if not WORLD_RECT.encloses(footprint):
			return _fail("这里超出了河湾范围")
		for i in range(5):
			var sample_z := lerpf(footprint.position.y, footprint.end.y, float(i) / 4.0)
			if footprint.position.x < river_x(sample_z) + RIVER_HALF_WIDTH and footprint.end.x > river_x(sample_z) - RIVER_HALF_WIDTH:
				return _fail("房屋不能建在河水中")
		if cell.level == 0:
			for road in scene_roads:
				for i in range(1, road.points.size()):
					if _segment_hits_rect(Vector2(road.points[i - 1][0], road.points[i - 1][1]), Vector2(road.points[i][0], road.points[i][1]), footprint.grow(float(road.width) * 0.5 - 0.05)):
						return _fail("这里需要给道路留出空间")
	return {"ok": true, "message": ""}


func _validate_road_site(points: Array, width: float, house_rows: Variant = null) -> Dictionary:
	var scene_houses: Array = houses if house_rows == null else house_rows
	var bridge := false
	var length := 0.0
	for point in points:
		if not WORLD_RECT.has_point(Vector2(point[0], point[1])):
			return _fail("道路超出了河湾范围")
	for i in range(1, points.size()):
		var a := Vector2(points[i - 1][0], points[i - 1][1])
		var b := Vector2(points[i][0], points[i][1])
		length += a.distance_to(b)
		for sample in range(33):
			var point := a.lerp(b, float(sample) / 32.0)
			if absf(point.x - river_x(point.y)) < RIVER_HALF_WIDTH + width * 0.5:
				bridge = true
				if absf(b.x - a.x) < absf(b.y - a.y) * 1.5 or absf(b.x - a.x) < 0.001:
					return _fail("桥梁需要横向跨河，不能沿水面铺路")
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
	if bridge:
		var first := Vector2(points[0][0], points[0][1])
		var last := Vector2(points[-1][0], points[-1][1])
		var first_side := first.x - river_x(first.y)
		var last_side := last.x - river_x(last.y)
		if absf(first_side) < RIVER_HALF_WIDTH + width * 0.5 or absf(last_side) < RIVER_HALF_WIDTH + width * 0.5 or first_side * last_side >= 0:
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
