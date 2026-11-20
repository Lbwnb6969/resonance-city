extends RefCounted
## Resolve ledger links only against the same published city revision.
const PREFIX := "space_focus"

static func link(city: RefCounted, index: int, space: Dictionary) -> String:
	return "[url=%s/%d/%d/%d/%d/%d]定位[/url]" % [PREFIX, city.get_instance_id(), city._wish_epoch, city.revision, index, hash(space)]

static func follow(meta: Variant, widget: RefCounted) -> void:
	var parts := str(meta).split("/")
	if parts.size() != 6 or parts[0] != PREFIX or not parts[4].is_valid_int(): return
	var demo: Node3D = widget.demo
	var city: RefCounted = demo.state
	if not widget.visible() or demo.edit_pending() or demo.gallery.busy: return
	if parts[1] != str(city.get_instance_id()) or parts[2] != str(city._wish_epoch) or parts[3] != str(city.revision): return
	var spaces: Array = city.functional_zones().spaces
	var index := int(parts[4])
	if index < 0 or index >= spaces.size(): return
	if parts[5] != str(hash(spaces[index])): return
	var point: Variant = locate(city, spaces[index])
	if point == null: return
	if demo.camera_rig.strolling: demo.camera_rig.toggle(demo)
	demo.focus = point
	demo.zoom = minf(demo.zoom, 16.)
	demo._update_camera()
	widget.close_panel()

static func locate(city: RefCounted, space: Dictionary) -> Variant:
	var evidence: Dictionary = space.evidence
	if evidence.geometry == "closed_ground_ring":
		for court: Dictionary in city.courtyard_plans():
			if court.id == evidence.court_id: return _ground(city, court.center)
	if evidence.geometry == "narrow_lane": return _ground(city, (evidence.from + evidence.to) * .5)
	var polygon: PackedVector2Array = evidence.get("polygon", PackedVector2Array())
	for field: String in ["forecourts", "shore_faces"]:
		var surfaces: Array = evidence.get(field, [])
		if polygon.is_empty() and not surfaces.is_empty(): polygon = surfaces[0].polygon
	if not polygon.is_empty():
		var bounds := Rect2(polygon[0], Vector2.ZERO)
		for vertex: Vector2 in polygon: bounds = bounds.expand(vertex)
		return _ground(city, bounds.get_center())
	if space.members.is_empty(): return null
	var id: String = space.members[0]
	var index: int = city._house_index(id)
	if index >= 0:
		var house: Dictionary = city.houses[index]
		return Vector3(house.origin[0], float(house.get("base_y", 0.)) + 1., house.origin[1])
	var landmark: Dictionary = city.PlacedLandmarks.row(city, id)
	return _ground(city, city.PlacedLandmarks.position(landmark)) if not landmark.is_empty() else null

static func _ground(city: RefCounted, point: Vector2) -> Vector3:
	return Vector3(point.x, city.ground_height(point) + .7, point.y)
