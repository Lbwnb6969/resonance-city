extends RefCounted
## Secondary doors in a timber residence keep their approach and timber bay.
const Wall = preload("res://scripts/visual/city_creation_wall_material.gd")
const Glass = preload("res://scripts/visual/city_creation_facade_glass.gd")
const WindowGlow = preload("res://scripts/visual/city_creation_roof_window_glow.gd")

static func threshold(renderer, wall: Node3D) -> void:
	renderer._box(wall, Vector3(.96,.10,.54), Vector3(0,.055,.30), renderer._material(Color("d7c8a5")))
	renderer._box(wall, Vector3(1.04,.045,.68), Vector3(0,.022,.55), renderer._material(Color("bdb797")))

static func build(renderer, job, frame, wall: Node3D, active: bool, width: float) -> bool:
	if active or frame.level != 0 or width < 1.79 or not frame.retreats.is_empty():
		return false
	if job.style != "timber" or job.era not in ["pastoral", "renaissance"] or job.house.has("signature"):
		return false
	if job.house.get("role", "residential") != "residential" or job.house.get("architecture", "") != "":
		return false
	var entry: Dictionary = wall.get_meta("entrance")
	var primary: Dictionary = job.primary
	if primary.is_empty() or primary.cell_id == entry.cell_id and primary.side == entry.side:
		return false
	var tangent := Vector2i(entry.side.y, -entry.side.x)
	var adjacent := false
	for side: Vector2i in [tangent, -tangent]:
		var neighbor: Dictionary = renderer.building_context.neighbor(job.house, frame.cell, side)
		if neighbor.get("house_id", "") == job.house.id and job.doors.has([str(neighbor.cell_id), entry.side]):
			adjacent = true
			break
	if not adjacent:
		return false
	var toward := Vector2i(primary.cell_x - frame.x, primary.cell_z - frame.z)
	var light_x := -.54 if Vector2(toward).dot(Vector2(tangent)) < 0 else .54
	var cedar := Wall.component(renderer, Color("826552"), Wall.Kind.TIMBER)
	var door := Wall.component(renderer, Color("694d3c"), Wall.Kind.TIMBER)
	var painted := Wall.component(renderer, job.palette[2], Wall.Kind.TIMBER)
	var limestone := Wall.component(renderer, Color("d8c7a6"), Wall.Kind.STONE)
	renderer._box(wall, Vector3(.60,1.15,.085), Vector3(0,.678,.108), cedar)
	renderer._box(wall, Vector3(.46,1.00,.055), Vector3(0,.630,.166), door)
	for x: float in [-.142,0.,.142]:
		renderer._box(wall, Vector3(.012,.91,.013), Vector3(x,.638,.198), cedar)
	renderer._box(wall, Vector3(.46,.058,.025), Vector3(0,.915,.195), painted)
	renderer._box(wall, Vector3(.46,.055,.025), Vector3(0,.36,.195), painted)
	renderer._box(wall, Vector3(.66,.085,.155), Vector3(0,1.253,.135), limestone)
	renderer._cylinder(wall, .023, .023, .035, Vector3(-signf(light_x)*.16,.61,.22), renderer._material(Color("d6bb74")))
	var pane: MeshInstance3D = renderer._box(wall, Vector3(.29,.48,.028), Vector3(light_x,1.015,.113), Glass.material(renderer, 2))
	pane.name = "TimberEntrySidelight"
	for side: float in [-1.,1.]:
		renderer._box(wall, Vector3(.055,.59,.104), Vector3(light_x+side*.165,1.02,.12), cedar)
	renderer._box(wall, Vector3(.35,.046,.046), Vector3(light_x,1.011,.146), painted)
	renderer._box(wall, Vector3(.057,.51,.050), Vector3(light_x,1.015,.147), painted)
	renderer._box(wall, Vector3(.385,.075,.14), Vector3(light_x,1.302,.129), cedar)
	renderer._box(wall, Vector3(.42,.074,.19), Vector3(light_x,.743,.131), limestone)
	wall.set_meta("timber_service_entry", {"cell_id":entry.cell_id,"side":entry.side,"window_x":light_x})
	WindowGlow.record(job.root, wall, "timber_entry", "TimberEntrySidelight")
	threshold(renderer, wall)
	return true
