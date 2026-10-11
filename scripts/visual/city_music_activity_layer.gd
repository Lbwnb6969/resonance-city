extends Node2D
## Short musical marks follow contributions already rendered and heard by the device.
const Coupling = preload("res://scripts/world/world_coupling.gd")
const HeardReplyLinks = preload("res://scripts/visual/heard_reply_links.gd")
const MARK_SECONDS := 0.55
var marks: Array[Dictionary] = []
var trails: Array[Dictionary] = []
var audible_frame := 0.0
var heard_reply_links := HeardReplyLinks.new()
var activity_source: RefCounted
var trail_ground: ReplyTrailGround

class ReplyTrailGround extends Node2D:
	var trails: Array[Dictionary] = []
	func _draw() -> void:
		for trail in trails:
			var path: PackedVector2Array = trail["path"]
			var alpha := float(trail["alpha"])
			var from_ink: Color = trail["from_ink"]
			var to_ink: Color = trail["to_ink"]
			for index in range(path.size()-1):
				var ink := from_ink.lerp(to_ink,float(index)/float(path.size()-2))
				ink.a = alpha*0.38
				draw_line(path[index],path[index+1],ink,1.2,true)
			# The entire gesture starts only once Reply is heard. A brief dot
			# crosses the river then dissolves into the receiver's existing rings.
			var t := clampf(float(trail["age"])/0.42,0.0,1.0)
			var cursor := t*float(path.size()-1)
			var segment := mini(floori(cursor),path.size()-2)
			var at := path[segment].lerp(path[segment+1],cursor-float(segment))
			var dot_ink := from_ink.lerp(to_ink,t)
			draw_circle(at,3.8,Color(dot_ink,alpha*0.12))
			draw_circle(at,1.7,Color(dot_ink,alpha*0.92))

func _trail(demo: Control,link: Dictionary) -> Dictionary:
	var from: Vector2 = demo.point(link["from"])
	var to: Vector2 = demo.point(link["to"])
	var distance := from.distance_to(to)
	var control := (from+to)*0.5+Vector2(0,-clampf(distance*0.20,14,54))
	var path := PackedVector2Array()
	for index in range(25):
		var t := float(index)/24.0
		path.append(from*(1.0-t)*(1.0-t)+control*2.0*(1.0-t)*t+to*t*t)
	var night := float(demo.daylight_state.get("night_strength",0.0))
	var alpha := clampf(float(link["strength"])/0.022,0.0,1.0)*0.88*(1.0-float(link["age"])/MARK_SECONDS)
	var trail := link.duplicate()
	trail.merge({"path":path,"alpha":alpha,
		"from_ink":Color("b18a48").lerp(Color("e6c892"),night*0.70),
		"to_ink":Color("4c8584").lerp(Color("a1d2cc"),night*0.75)})
	return trail

func sync(demo: Control) -> void:
	if trail_ground == null:
		trail_ground = ReplyTrailGround.new()
		trail_ground.name = "HeardReplyTrails"
		trail_ground.z_as_relative = false
		trail_ground.z_index = -26
		add_child(trail_ground)
	audible_frame = float(demo.clock.renderer.transport.audible_frame)
	visible = not demo.black and demo.clock.active and not demo.preview_started
	var next_marks: Array[Dictionary] = []
	var next_trails: Array[Dictionary] = []
	if activity_source != demo.model:
		activity_source = demo.model
		heard_reply_links.clear()
	if visible:
		var rate: float = demo.clock.renderer.transport.sample_rate
		var viewport := Rect2(Vector2.ZERO,demo.size).grow(32.0)
		var rows: Array[Dictionary] = demo.model.audible_music_activity(audible_frame)
		for link in heard_reply_links.observe(rows,demo.shown_world,audible_frame,rate):
			var trail := _trail(demo,link)
			if float(trail["alpha"]) >= 0.015 and viewport.intersects(Rect2(trail["path"][0],Vector2.ZERO).expand(trail["path"][-1]).grow(54)):
				next_trails.append(trail)
		for row in rows:
			var age := (audible_frame-float(row["onset"]))/rate
			if age < 0.0 or age >= MARK_SECONDS: continue
			var answer := int(row["generation"]) == 1
			var performer := str(row["receiver_id"] if answer else row["source_id"])
			var building: Dictionary = demo.shown_world.by_id.get(performer,{})
			if building.is_empty(): continue
			var at: Vector2 = demo.point(Coupling.position_of(building))
			if not viewport.has_point(at): continue
			var strength := clampf(float(row["strength"])/0.022,0.0,1.0)
			var alpha := strength*0.88*(1.0-age/MARK_SECONDS)
			if alpha < 0.015: continue
			var mark: Dictionary = row.duplicate()
			mark.merge({"performer_id":performer,"position":at,"alpha":alpha,
				"radius":(13.0+8.0*age/MARK_SECONDS)*clampf(demo.view_zoom,0.65,1.35),
				"note":demo.note_name(int(row["pitch"])),"role":"reply" if answer else "lead"})
			next_marks.append(mark)
	else:
		heard_reply_links.clear()
	if trails != next_trails:
		trails = next_trails
		trail_ground.trails = next_trails
		trail_ground.queue_redraw()
	if marks == next_marks: return
	marks = next_marks
	queue_redraw()

func _draw() -> void:
	for mark in marks:
		var at: Vector2 = mark["position"]
		var radius: float = mark["radius"]
		var alpha: float = mark["alpha"]
		var answer: bool = mark["role"] == "reply"
		var ink := Color("467678") if answer else Color("9b712d")
		ink.a = alpha
		draw_circle(at,radius,Color(ink.r,ink.g,ink.b,alpha*0.08))
		if answer:
			for i in range(12):
				var angle := TAU*float(i)/12.0
				draw_arc(at,radius,angle,angle+TAU/18.0,5,ink,1.6,true)
				draw_arc(at,radius+4.0,angle,angle+TAU/18.0,5,ink,1.0,true)
		else:
			draw_arc(at,radius,0.0,TAU,40,ink,2.0,true)
		var badge := at+Vector2(radius*0.8,-radius)
		draw_circle(badge,8.0,Color(0.97,0.96,0.89,alpha*0.95))
		draw_string(ThemeDB.fallback_font,badge+Vector2(-4.0,4.0),mark["note"],
			HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
