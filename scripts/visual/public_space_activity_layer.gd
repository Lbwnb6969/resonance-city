extends Node2D
## A short visual echo for public space that is present in the *audible*
## theme event.  House Lead/Reply marks remain in city_music_activity_layer;
## this layer only projects the same rendered row onto its authored park/civic
## site so planning has a visible, spatially anchored result.

const MARK_SECONDS := 0.55
var marks: Array[Dictionary] = []
var audible_frame := 0.0

func _site(world: Variant,site_id: String) -> Dictionary:
	for site in world.public_sites:
		if str(site.get("id","")) == site_id and bool(site.get("active",false)): return site
	return {}

func sync(demo: Control) -> void:
	audible_frame = float(demo.clock.renderer.transport.audible_frame)
	visible = not demo.black and demo.clock.active and not demo.preview_started
	var next_marks: Array[Dictionary] = []
	if visible:
		var rate: float = demo.clock.renderer.transport.sample_rate
		var viewport := Rect2(Vector2.ZERO,demo.size).grow(32.0)
		var activity: Array[Dictionary] = []
		activity.append_array(demo.model.audible_music_activity(audible_frame))
		activity.append_array(demo.model.audible_public_activity(audible_frame))
		for row in activity:
			var ids: Array = row.get("public_site_ids",[])
			if ids.is_empty(): continue
			var age := (audible_frame-float(row["onset"]))/rate
			if age < 0.0 or age >= MARK_SECONDS: continue
			var strength := clampf(float(row["strength"])/0.022,0.0,1.0)
			var alpha := strength*0.78*(1.0-age/MARK_SECONDS)
			if alpha < 0.015: continue
			for index in range(ids.size()):
				var site := _site(demo.shown_world,str(ids[index]))
				if site.is_empty(): continue
				var raw_position: Array = site.get("position",[])
				if raw_position.size() != 2: continue
				var at: Vector2 = demo.point(Vector2(float(raw_position[0]),float(raw_position[1])))
				if not viewport.has_point(at): continue
				var kinds: Array = row.get("public_site_kinds",[])
				var kind := str(kinds[index]) if index < kinds.size() else str(site.get("kind","park"))
				var mark := {"event_id":str(row["event_id"]),"site_id":str(site["id"]),
					"site_kind":kind,"position":at,"alpha":alpha,"pitch":int(row["pitch"]),
					"onset":int(row["onset"]),"end_frame":int(row["end_frame"]),
					"render_start":int(row["render_start"]),"render_end":int(row["render_end"]),
					"note":demo.note_name(int(row["pitch"]))}
				next_marks.append(mark)
	if marks == next_marks: return
	marks = next_marks
	queue_redraw()

func _draw() -> void:
	for mark in marks:
		var at: Vector2 = mark["position"]
		var alpha := float(mark["alpha"])
		var zoom := 1.0
		var parent := get_parent()
		if parent != null and parent.get("view_zoom") != null: zoom = float(parent.get("view_zoom"))
		var radius := (17.0+6.0*(1.0-alpha))*clampf(zoom,0.65,1.35)
		var civic := str(mark["site_kind"]) == "civic"
		var ink := Color("a47739") if civic else Color("4a876b")
		ink.a = alpha
		draw_circle(at,radius,Color(ink.r,ink.g,ink.b,alpha*0.09))
		if civic:
			draw_arc(at,radius,0.0,TAU,28,ink,2.2,true)
			draw_arc(at,radius-4.0,0.0,TAU,28,ink,1.0,true)
		else:
			for i in range(10):
				var angle := TAU*float(i)/10.0
				draw_arc(at,radius,angle,angle+TAU/22.0,4,ink,2.0,true)
		var badge := at+Vector2(radius*0.72,-radius*0.9)
		draw_circle(badge,8.0,Color(0.97,0.96,0.89,alpha*0.95))
		draw_string(ThemeDB.fallback_font,badge+Vector2(-4.0,4.0),"C" if civic else "P",
			HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
