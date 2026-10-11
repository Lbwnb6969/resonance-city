extends Node2D
## Short musical marks follow contributions already rendered and heard by the device.
const Coupling = preload("res://scripts/world/world_coupling.gd")
const MARK_SECONDS := 0.55
var marks: Array[Dictionary] = []
var audible_frame := 0.0

func sync(demo: Control) -> void:
	audible_frame = float(demo.clock.renderer.transport.audible_frame)
	visible = not demo.black and demo.clock.active and not demo.preview_started
	var next_marks: Array[Dictionary] = []
	if visible:
		var rate: float = demo.clock.renderer.transport.sample_rate
		var viewport := Rect2(Vector2.ZERO,demo.size).grow(32.0)
		for row in demo.model.audible_music_activity(audible_frame):
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
