class_name CityRoads
extends RefCounted
const Values = preload("res://scripts/spec_values.gd")
static var cached: Dictionary = {}

static func settings() -> Dictionary:
	if cached.is_empty(): cached = Values.load_values()
	return cached

static func valid(a: Vector2i,b: Vector2i) -> bool:
	var space: Dictionary = settings()["city"]
	return a.x >= 0 and a.y >= 0 and b.x >= 0 and b.y >= 0 and a.x < int(space["width"]) and b.x < int(space["width"]) and a.y < int(space["height"]) and b.y < int(space["height"]) and (a-b).length_squared() == 1

static func key(a: Vector2i,b: Vector2i) -> String:
	var ends := endpoints(a,b)
	return "%d,%d|%d,%d" % [ends[0][0],ends[0][1],ends[1][0],ends[1][1]]

static func endpoints(a: Vector2i,b: Vector2i) -> Array:
	return [[a.x,a.y],[b.x,b.y]] if a.y < b.y or (a.y == b.y and a.x < b.x) else [[b.x,b.y],[a.x,a.y]]

static func count(marks: Dictionary,a: Vector2i,b: Vector2i) -> int:
	return int(marks.get(key(a,b),{}).get("count",0))

static func blocked(marks: Dictionary,a: Vector2i,b: Vector2i) -> bool:
	return count(marks,a,b) >= int(settings()["tread"]["threshold"])
