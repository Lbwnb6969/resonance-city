extends Node2D
## A cartographic focus for the real land currently owned by the sound menu.
## It reads the audition's accepted branch; it never creates a preview house.
const Coupling = preload("res://scripts/world/world_coupling.gd")
var state: Dictionary = {}
var source_model: RefCounted

func _init() -> void:
	z_index = 53
	visible = false

func sync(demo: Control) -> void:
	var changed_city: bool = source_model != null and source_model != demo.model
	source_model = demo.model
	state.clear()
	visible = false
	if changed_city or demo.black or not demo.first_composition_mode or not demo.menu.visible or not demo._expression_context():
		queue_redraw()
		return
	var raw: Array = demo.context.get("position",[])
	var cid := str(demo.context.get("community_id",""))
	if raw.size() != 2 or not demo.shown_world.communities.has(cid):
		queue_redraw()
		return
	var community: Dictionary = demo.shown_world.communities[cid]
	if not bool(community.get("active",true)):
		queue_redraw()
		return
	var position := Vector2(float(raw[0]),float(raw[1]))
	var footprint: PackedVector2Array = demo.shown_world.building_polygon(position)
	var polygon := _project(demo,footprint)
	var at: Vector2 = demo.point(position)
	var choice := str(demo.expression_choice)
	var ghost: Dictionary = demo.expression_audition_layer.ghost
	var ghost_current: bool = not ghost.is_empty() and str(ghost.get("expression","")) == choice and ghost.get("position",Vector2.INF).is_equal_approx(at) and demo.expression_comparison_key == demo._expression_preview_identity()
	var ink := Color("91724f")
	if ghost_current: ink = ghost["ink"]
	var neighbors: Array[Dictionary] = []
	var frame: int = demo.clock.renderer.transport.audible_frame
	for building: Dictionary in demo.shown_world.buildings:
		if str(building.get("community_id","")) != cid or int(building.get("birth_frame",0)) > frame: continue
		var neighboring_position := Coupling.position_of(building)
		var distance := neighboring_position.distance_squared_to(position)
		if distance < 0.0001:
			# Once this land is an actual building, the old choice is expired.
			queue_redraw()
			return
		if distance <= 9.0:
			neighbors.append({"id":str(building["district_id"]),"distance":distance,
				"world_position":neighboring_position,"polygon":_project(demo,demo.shown_world.building_polygon(neighboring_position))})
	neighbors.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return float(a["distance"]) < float(b["distance"]))
	if neighbors.size() > 3: neighbors.resize(3)
	var label := str(community.get("name",cid))
	var label_width := ThemeDB.fallback_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	var bottom := at.y
	for vertex in polygon: bottom = maxf(bottom,vertex.y)
	var label_y := maxf(bottom+11.0,at.y+55.0) if ghost_current else bottom+11.0
	var badge := Rect2(Vector2(at.x-label_width*0.5-10.0,label_y),Vector2(label_width+20.0,23.0))
	# The camera owns map clearance. The short name also stays out of the panel.
	var panel: Rect2 = demo.menu.get_global_rect().grow(6.0)
	if panel.intersects(badge):
		badge.position.x = panel.position.x-badge.size.x-10.0 if at.x < panel.get_center().x else panel.end.x+10.0
	badge.position.x = clampf(badge.position.x,8.0,maxf(8.0,demo.size.x-badge.size.x-8.0))
	badge.position.y = clampf(badge.position.y,8.0,maxf(8.0,demo.size.y-badge.size.y-16.0))
	var progress := -1.0
	if ghost_current and demo.preview_started and demo.preview_player.playing and float(ghost.get("preview_frame",-1.0)) >= 0.0:
		var duration: float = demo.preview_player.stream.get_length()
		var rate: float = demo.clock.renderer.transport.sample_rate
		progress = clampf((float(ghost["preview_frame"])-float(demo.expression_comparison["boundary_frame"]))/rate/duration,0.0,1.0)
	state = {"world_position":position,"position":at,"footprint":footprint,"polygon":polygon,
		"community_id":cid,"community_name":label,"neighbors":neighbors,"ghost_current":ghost_current,
		"expression":choice,"ink":ink,"badge":badge,"progress":progress}
	visible = true
	queue_redraw()

func _project(demo: Control,polygon: PackedVector2Array) -> PackedVector2Array:
	var projected := PackedVector2Array()
	for vertex in polygon: projected.append(demo.point(vertex))
	return projected

func _corners(polygon: PackedVector2Array,ink: Color,strong := false) -> void:
	var center := Vector2.ZERO
	for vertex in polygon: center += vertex
	center /= polygon.size()
	for i in range(polygon.size()):
		var corner := polygon[i]
		var outside := corner+(corner-center).normalized()*4.0
		var previous := polygon[posmod(i-1,polygon.size())]-corner
		var following := polygon[(i+1)%polygon.size()]-corner
		var length := minf(8.0,minf(previous.length(),following.length())*0.3)
		var mark := PackedVector2Array([outside+previous.normalized()*length,outside,outside+following.normalized()*length])
		if strong: draw_polyline(mark,Color("ddd0ae",0.65),3.2,true)
		draw_polyline(mark,ink,1.6 if strong else 0.9,true)

func _draw() -> void:
	if state.is_empty(): return
	var ink: Color = state["ink"]
	var polygon: PackedVector2Array = state["polygon"]
	for neighbor: Dictionary in state["neighbors"]:
		_corners(neighbor["polygon"],Color("9a805d",0.28))
	draw_colored_polygon(polygon,Color("d6c7a2",0.045 if bool(state["ghost_current"]) else 0.24))
	_corners(polygon,Color(ink,0.93),true)
	var badge: Rect2 = state["badge"]
	draw_style_box(_paper(),badge)
	draw_string(ThemeDB.fallback_font,badge.position+Vector2(10,16),str(state["community_name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("5f5747"))
	var progress: float = state["progress"]
	if progress >= 0.0:
		var start := Vector2(badge.get_center().x-18.0,badge.end.y+5.0)
		draw_line(start,start+Vector2(36,0),Color(ink,0.32),1.0,true)
		draw_line(start,start+Vector2(36.0*progress,0),Color(ink,0.9),1.5,true)
		for i in range(5):
			var tick := start+Vector2(i*9.0,0)
			draw_line(tick+Vector2(0,-2),tick+Vector2(0,2),Color(ink,0.62),1.0,true)

func _paper() -> StyleBoxFlat:
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("e9dfc8",0.95)
	paper.border_color = Color("a6916c",0.5)
	paper.set_border_width_all(1)
	paper.set_corner_radius_all(2)
	return paper
