class_name StreetEavesLayer
extends Node2D
## A small cornice across a real shared-wall seam; each house stays a separate Sprite.
const Coupling = preload("res://scripts/world/world_coupling.gd")
var patches: Dictionary = {}
var relation_key: Array = []
var rebuild_count := 0

class EavePatch extends Node2D:
	var pair: Array[String] = []
	var top := PackedVector2Array()
	var lip := PackedVector2Array()
	func _draw() -> void:
		draw_colored_polygon(lip,Color("bebfb0"))
		draw_colored_polygon(top,Color("e4dccf"))

func _ready() -> void:
	y_sort_enabled = true

func clear() -> void:
	for patch: Node2D in patches.values(): patch.queue_free()
	patches.clear()
	relation_key.clear()

func sync(owner: Control) -> void:
	visible = not owner.black
	var city = owner.shown_world
	if city == null:
		clear()
		return
	var next_key: Array = [city.get_instance_id(),city.terrain.noise_seed,city.terrain.river_phase,city.terrain.family,
		city.buildings.size(),city.fabric_cache.get("shared_walls",[]).hash()]
	# Geometry is independent of pitch, focus, preview choice and wall-clock time.
	if next_key != relation_key:
		clear()
		relation_key = next_key
		rebuild_count += 1
		for relation: Dictionary in city.fabric_cache.get("shared_walls",[]):
			var aid := str(relation["a"])
			var bid := str(relation["b"])
			if not owner.building_geometry.has(aid) or not owner.building_geometry.has(bid): continue
			var a: Dictionary = owner.building_geometry[aid]
			var b: Dictionary = owner.building_geometry[bid]
			var ae: Dictionary = a.get("entry",{})
			var be: Dictionary = b.get("entry",{})
			if not ae.has("roof_eave_y") or not be.has("roof_eave_y"): continue
			var delta: Vector2 = Coupling.position_of(city.by_id[bid])-Coupling.position_of(city.by_id[aid])
			if delta.is_zero_approx(): continue
			var direction := delta.normalized()
			var first := _roof_edge(a,ae,direction)
			var second := _roof_edge(b,be,-direction)
			var along := _ground_vector(direction)
			if (second-first).dot(along) < 0.0:
				var middle := (first+second)*0.5
				first = middle-along*0.035
				second = middle+along*0.035
			var across := _ground_vector(Vector2(-direction.y,direction.x))*0.065
			if across.y < 0.0: across = -across
			var patch := EavePatch.new()
			patch.name = "SharedEave_"+aid+"_"+bid
			patch.pair = [aid,bid]
			# Sort at the nearer house's ground, so rear cornices cannot cover a front house.
			patch.position = Vector2((a["position"].x+b["position"].x)*0.5,maxf(a["position"].y,b["position"].y)+0.02)
			patch.top = PackedVector2Array([first-across,second-across,second+across,first+across])
			patch.lip = PackedVector2Array([first+across,second+across,second+across+Vector2(0,1.15),first+across+Vector2(0,1.15)])
			for index in range(patch.top.size()): patch.top[index] -= patch.position
			for index in range(patch.lip.size()): patch.lip[index] -= patch.position
			add_child(patch)
			patches[aid+":"+bid] = patch
	for patch: EavePatch in patches.values():
		patch.visible = owner.sprites.has(patch.pair[0]) and owner.sprites.has(patch.pair[1])
		if patch.visible:
			patch.visible = owner.sprites[patch.pair[0]].progress >= 1.0 and owner.sprites[patch.pair[1]].progress >= 1.0

static func _ground_vector(value: Vector2) -> Vector2:
	return Vector2((value.x-value.y)*28.0,(value.x+value.y)*14.0)

static func _roof_edge(geometry: Dictionary,entry: Dictionary,direction: Vector2) -> Vector2:
	var half: Array = entry["roof_half_extents"]
	var reach := INF
	if absf(direction.x) > 0.0001: reach = minf(reach,float(half[0])/absf(direction.x))
	if absf(direction.y) > 0.0001: reach = minf(reach,float(half[1])/absf(direction.y))
	var p := Vector3(direction.x*reach,float(entry["roof_eave_y"]),direction.y*reach)
	var projected := Vector2((p.x-p.z)/sqrt(2.0),(p.x+p.z)/sqrt(2.0)*0.5-p.y*sqrt(3.0)*0.5)
	return geometry["position"]+projected*float(geometry["scale"])*float(entry["pixels_per_world"])

func diagnostics() -> Dictionary:
	var pairs: Array = []
	var visible_count := 0
	for patch: EavePatch in patches.values():
		pairs.append(patch.pair.duplicate())
		if patch.visible: visible_count += 1
	return {"pairs":pairs,"visible_pairs":visible_count,"rebuild_count":rebuild_count}
