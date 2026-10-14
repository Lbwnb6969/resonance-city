class_name CityCreationGrassMask
extends RefCounted
## Dirty-block-only spatial index of production vegetation predicates.
## House neighbours are resolved once, not scanned for each grass candidate.
const State := preload("res://scripts/world/city_creation_state.gd")
const BLOCK_SIZE := 8.0
const BIN_SIZE := 1.0
const BIN_COUNT := 8
const BIN_PADDING := 0.0
const MAX_CLEARANCE := 0.42 * 0.25

class Bin extends RefCounted:
	var footprints: Array[Rect2] = []
	var doors := PackedVector2Array()
	var capsules: Array[Capsule] = []

class Capsule extends RefCounted:
	var a: Vector2
	var b: Vector2
	var length_squared: float
	var radius: float
	var water: bool

var _origin := Vector2.ZERO
var _bounds := Rect2()
var _bins: Array[Bin] = []
var _stats: Dictionary = {}

func setup(state: RefCounted, block: Vector2i) -> void:
	var started := Time.get_ticks_usec()
	_origin = Vector2(block) * BLOCK_SIZE
	_bounds = Rect2(_origin, Vector2.ONE * BLOCK_SIZE)
	_bins.clear()
	for index in range(BIN_COUNT * BIN_COUNT):
		_bins.append(Bin.new())
	for house: Dictionary in state.get("houses"):
		for cell: Dictionary in house.cells:
			if int(cell.level) != 0:
				continue
			var at := Vector2(float(house.origin[0]) + int(cell.x) * State.CELL_UNIT, float(house.origin[1]) + int(cell.z) * State.CELL_UNIT)
			var footprint := Rect2(at - Vector2.ONE * State.CELL_UNIT * 0.5, Vector2.ONE * State.CELL_UNIT)
			for index: int in _indices(footprint.grow(MAX_CLEARANCE)):
				_bins[index].footprints.append(footprint)
			if cell.kind == "room":
				var occupied := false
				for neighbor: Dictionary in house.cells:
					if neighbor.level == 0 and neighbor.x == cell.x and neighbor.z == cell.z + 1:
						occupied = true
						break
				if occupied:
					continue
				var radius := 0.95 + MAX_CLEARANCE
				var door := at + Vector2(0, 1.55)
				var doorway := Rect2(door - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
				for index: int in _indices(doorway):
					_bins[index].doors.append(door)
	for road: Dictionary in state.get("roads"):
		for index in range(1, road.points.size()):
			var a := Vector2(float(road.points[index - 1][0]), float(road.points[index - 1][1]))
			var b := Vector2(float(road.points[index][0]), float(road.points[index][1]))
			_add_segment(a, b, float(road.width) * 0.5 + 0.45, false)
	for water: Dictionary in state.get("waters"):
		for index in range(maxi(1, water.points.size() - 1)):
			var a := Vector2(float(water.points[index][0]), float(water.points[index][1]))
			var next := mini(index + 1, water.points.size() - 1)
			var b := Vector2(float(water.points[next][0]), float(water.points[next][1]))
			_add_segment(a, b, float(water.width) * 0.5, true)
	var houses := 0
	var roads := 0
	var waters := 0
	var max_segments := 0
	for bin: Bin in _bins:
		houses += bin.footprints.size()
		for capsule: Capsule in bin.capsules:
			if capsule.water:
				waters += 1
			else:
				roads += 1
		max_segments = maxi(max_segments, bin.capsules.size())
	_stats = {"bins": _bins.size(), "house_references": houses, "road_segments": roads,
		"water_segments": waters, "max_bin_segments": max_segments,
		"setup_ms": float(Time.get_ticks_usec() - started) / 1000.0}

func visible(at: Vector2, scale: float) -> bool:
	if scale <= 0.0 or not _bounds.has_point(at) or not State.WORLD_RECT.has_point(at):
		return false
	var clearance := 0.42 * scale
	if absf(at.x - State.river_x(at.y)) - State.RIVER_HALF_WIDTH <= clearance:
		return false
	var local := at - _origin
	var index := floori(local.y / BIN_SIZE) * BIN_COUNT + floori(local.x / BIN_SIZE)
	var bin: Bin = _bins[index]
	for footprint: Rect2 in bin.footprints:
		if footprint.grow(clearance).has_point(at):
			return false
	for door: Vector2 in bin.doors:
		if at.distance_to(door) <= 0.95 + clearance:
			return false
	for capsule: Capsule in bin.capsules:
		var a := capsule.a
		var b := capsule.b
		var length_squared := capsule.length_squared
		var distance := 0.0
		if length_squared <= 0.000001:
			distance = at.distance_to(a)
		else:
			var t := clampf((at - a).dot(b - a) / length_squared, 0.0, 1.0)
			distance = at.distance_to(a.lerp(b, t))
		# Preserve production operation order at capsule boundaries: water
		# uses distance minus half-width, roads use distance <= width+clearance.
		if capsule.water:
			if distance - capsule.radius <= clearance:
				return false
		elif distance <= capsule.radius + clearance:
			return false
	return true

func _add_segment(a: Vector2, b: Vector2, radius: float, water: bool) -> void:
	var capsule := Capsule.new()
	capsule.a = a
	capsule.b = b
	capsule.length_squared = a.distance_squared_to(b)
	capsule.radius = radius
	capsule.water = water
	for index: int in _indices(_segment_bounds(a, b, radius + MAX_CLEARANCE)):
		_bins[index].capsules.append(capsule)

func stats() -> Dictionary:
	return _stats.duplicate()

func _segment_bounds(a: Vector2, b: Vector2, radius: float) -> Rect2:
	return Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(a.x - b.x), absf(a.y - b.y))).grow(radius)

func _indices(bounds: Rect2) -> Array[int]:
	var result: Array[int] = []
	# Obstacle bounds already contain the maximum supported shrub clearance.
	# Final predicates keep the production inclusive/exclusive edge behavior.
	var expanded := bounds.grow(BIN_PADDING)
	if not expanded.intersects(_bounds, true):
		return result
	var first := Vector2i(floori((expanded.position.x - _origin.x) / BIN_SIZE), floori((expanded.position.y - _origin.y) / BIN_SIZE))
	var last := Vector2i(floori((expanded.end.x - _origin.x) / BIN_SIZE), floori((expanded.end.y - _origin.y) / BIN_SIZE))
	for z in range(maxi(0, first.y), mini(BIN_COUNT - 1, last.y) + 1):
		for x in range(maxi(0, first.x), mini(BIN_COUNT - 1, last.x) + 1):
			result.append(z * BIN_COUNT + x)
	return result
