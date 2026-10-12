extends Node2D
## Player names anchor on actual members, including selections across old CID.
var labels: Array[Dictionary] = []
var layout_key: Array = []

func sync(demo: Control) -> void:
	visible = not demo.black and not demo.neighborhood_editor.opened and not demo.menu.visible and not demo.planning_guide.opened and not demo.community_workbench.opened
	if not visible: return
	var city = demo.shown_world
	var frame := int(demo.clock.renderer.transport.audible_frame)
	var candidates: Array[Dictionary] = []
	for record: Dictionary in demo.player_neighborhoods.records():
		var points: Array[Vector2] = []
		var center := Vector2.ZERO
		for id: String in record["member_ids"]:
			if not city.by_id.has(id) or int(city.by_id[id].get("birth_frame",0)) > frame: continue
			var at: Vector2 = demo.Coupling.position_of(city.by_id[id])
			points.append(at)
			center += at
		if points.is_empty(): continue
		center /= points.size()
		var anchor: Vector2 = points[0]
		for at: Vector2 in points:
			if at.distance_squared_to(center) < anchor.distance_squared_to(center): anchor = at
		candidates.append({"id":record["id"],"name":record["name"],"anchor":demo.point(anchor)})
	var key: Array = [demo.size,candidates]
	if key == layout_key: return
	layout_key = key.duplicate(true)
	labels.clear()
	var font := ThemeDB.fallback_font
	var occupied: Array[Rect2] = []
	var clear := Rect2(Vector2(24,110),demo.size-Vector2(48,210))
	for candidate: Dictionary in candidates:
		var full_name := str(candidate["name"])
		var text := full_name if full_name.length() <= 14 else full_name.substr(0,13)+"…"
		var text_size := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13)
		var at: Vector2 = candidate["anchor"]+Vector2(-text_size.x*0.5,30)
		var bounds := Rect2(at-Vector2(0,font.get_ascent(13)),Vector2(text_size.x,font.get_height(13))).grow_individual(9,5,9,5)
		if not clear.encloses(bounds) or occupied.any(func(other: Rect2) -> bool: return other.intersects(bounds)): continue
		occupied.append(bounds)
		labels.append({"id":candidate["id"],"name":full_name,"text":text,"position":at,"bounds":bounds})
	queue_redraw()

func hit(at: Vector2) -> String:
	if visible:
		for label: Dictionary in labels:
			if label["bounds"].has_point(at): return str(label["id"])
	return ""

func _draw() -> void:
	for label: Dictionary in labels:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("eee5cf",0.96)
		box.border_color = Color("8b977d",0.88)
		box.set_border_width_all(1)
		box.set_corner_radius_all(5)
		draw_style_box(box,label["bounds"])
		draw_string(ThemeDB.fallback_font,label["position"],label["text"],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("40594d"))
