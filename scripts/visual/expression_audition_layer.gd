extends Node2D
## The house and rhythm shown here come from the same accepted audition branch.
const Identity = preload("res://scripts/visual/first_expression_identity.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
var queued: Dictionary = {}
var queued_boundary := -1
var queued_event := -1
var ghost: Dictionary = {}
var arrivals: Array[Dictionary] = []
var source_model: RefCounted

func queue_choice(variant: Dictionary,boundary: int,event_id: int) -> void:
	queued = {"accepted":true,"birth":variant["birth"].duplicate(true)}
	queued_boundary = boundary
	queued_event = event_id

func sync(demo: Control) -> void:
	if source_model != demo.model:
		source_model = demo.model
		queued.clear()
		queued_boundary = -1
	var frame: float = demo.clock.renderer.transport.audible_frame
	var rate: float = demo.clock.renderer.transport.sample_rate
	var withdrawn: bool = queued_boundary >= 0 and demo.model.world.phrase_index*demo.model.phrase_frames < queued_boundary and not demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return int(op["event_id"]) == queued_event)
	if queued_boundary >= 0 and (frame >= queued_boundary or withdrawn):
		queued.clear()
		queued_boundary = -1
	visible = demo.first_composition_mode and not demo.black
	ghost.clear()
	arrivals.clear()
	if not visible: return
	var variant: Dictionary = {}
	var mode := ""
	if demo.menu.visible and demo._expression_context() and not demo.expression_choice.is_empty() and not demo.expression_comparison.is_empty() and demo.expression_comparison_key == demo._expression_preview_identity():
		variant = demo.expression_comparison["variants"][demo.expression_choice]
		mode = "试听" if demo.preview_started else "预影"
	elif not queued.is_empty():
		variant = queued
		mode = "待落成"
	if bool(variant.get("accepted",false)):
		var building: Dictionary = variant["birth"]["building"]
		var family: Dictionary = variant["birth"]["family"]
		var identity := Identity.identity(building,family)
		var entry: Dictionary = demo.building_catalog.entry_for(building,demo.assets[building["type"]],family)
		var at: Vector2 = demo.point(Coupling.position_of(building))
		var scale_factor: float = 28.0*sqrt(2.0)*0.8/maxf(float(entry["model_bounds"]["size"][0]),float(entry["model_bounds"]["size"][2]))/float(entry["pixels_per_world"])*demo.view_zoom
		var pulse := 0.0
		var pulse_onset := -1
		var preview_frame := -1.0
		if mode == "试听" and demo.preview_player.playing:
			var seconds := maxf(0.0,demo.preview_player.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())
			preview_frame = float(demo.expression_comparison["boundary_frame"])+seconds*rate
			for event: Dictionary in variant["metrics"]["pulse_events"]:
				if str(event["source_id"]) != str(building["district_id"]): continue
				var age := (preview_frame-float(event["onset"]))/rate
				if age >= 0.0 and age < 0.30 and 1.0-age/0.30 > pulse:
					pulse = 1.0-age/0.30
					pulse_onset = int(event["onset"])
		ghost = {"root_id":building["district_id"],"expression":identity["expression"],"mode":mode,"position":at,
			"texture":demo.building_catalog.texture_for(entry),"entry_id":entry["id"],"scale":scale_factor,
			"origin":Vector2(entry["origin"][0],entry["origin"][1]),"ink":identity["ink"],"pulse":pulse,"pulse_onset":pulse_onset,"preview_frame":preview_frame,
			"polygon":demo._project_polygon(demo.shown_world.building_polygon(Coupling.position_of(building))),
			"text":mode+" · "+str(identity["label"])+( " · %.1f秒" % maxf(0.0,(queued_boundary-frame)/rate) if mode == "待落成" else "")}
	# A real authored birth gets one short arrival gesture on the audible clock.
	if not demo.preview_started:
		for building: Dictionary in demo.shown_world.buildings:
			if not bool(building.get("player_expression",false)): continue
			var age := (frame-float(building["birth_frame"]))/rate
			if age < 0.0 or age >= 1.6: continue
			var identity := Identity.identity(building,demo.shown_world.families.get(str(building["family_id"]),{}))
			arrivals.append({"id":building["district_id"],"at":demo.point(Coupling.position_of(building)),"age":age,"ink":identity["ink"]})
	queue_redraw()

func _draw() -> void:
	if not ghost.is_empty():
		var at: Vector2 = ghost["position"]
		var ink: Color = ghost["ink"]
		var polygon: PackedVector2Array = ghost["polygon"]
		draw_colored_polygon(polygon,Color(ink,0.18))
		for i in range(polygon.size()): draw_dashed_line(polygon[i],polygon[(i+1)%polygon.size()],Color(ink,0.85),1.6,5.0,true)
		draw_set_transform(at,0.0,Vector2.ONE*float(ghost["scale"]))
		draw_texture(ghost["texture"],-ghost["origin"],Color(1.0,1.0,1.0,0.68+float(ghost["pulse"])*0.24))
		draw_set_transform(Vector2.ZERO)
		var pulse: float = ghost["pulse"]
		if pulse > 0.0: draw_arc(at,15.0+12.0*(1.0-pulse),0.0,TAU,40,Color(ink,pulse*0.9),2.0,true)
		var label := str(ghost["text"])
		var label_width := ThemeDB.fallback_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		var badge := Rect2(at+Vector2(-label_width*0.5-8.0,23.0),Vector2(label_width+16.0,24.0))
		draw_rect(badge,Color("f4f0df",0.95))
		draw_string(ThemeDB.fallback_font,badge.position+Vector2(8,17),label,HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink.darkened(0.20))
	for arrival in arrivals:
		var t: float = float(arrival["age"])/1.6
		var ink: Color = arrival["ink"]
		draw_arc(arrival["at"],15.0+31.0*t,0.0,TAU,48,Color(ink,(1.0-t)*0.85),2.3,true)
