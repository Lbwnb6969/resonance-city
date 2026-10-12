extends Node2D
## A short, read-only link from a heard authored house to its real next family child.
##
## The audition layer already shows the chosen branch before it is committed and
## the arrival ring marks a building at its boundary.  This layer supplies the
## missing spatial sentence afterwards: the new house grew out of the player's
## already-heard family.  It only reads presented World births and never submits
## an operation, changes a family, or predicts a future building.
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Identity = preload("res://scripts/visual/first_expression_identity.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")

const SHOW_SECONDS := 2.8
const LINE_WIDTH := 2.1
const FONT_SIZE := 12

var trails: Array[Dictionary] = []
var _seen: Dictionary = {}
var _source_model: RefCounted

func _reset_for_model(model: RefCounted,world,frame: float) -> void:
	if _source_model == model: return
	_source_model = model
	_seen.clear()
	trails.clear()
	# A loaded city may have been saved seconds after a birth. Its already
	# heard events are the starting state, even when they are still recent.
	if world == null: return
	for event: Dictionary in world.events:
		if str(event.get("kind","")) != "birth": continue
		var event_frame := int(event.get("frame",-1))
		if event_frame >= 0 and float(event_frame) <= frame:
			_seen[str(event.get("district_id",""))+":"+str(event_frame)] = true

func sync(demo: Control) -> void:
	var frame := float(demo.clock.renderer.transport.audible_frame)
	var world = demo.shown_world
	_reset_for_model(demo.model,world,frame)
	# Keep the layer out of planning and audition panels; the real birth remains
	# in the World event log and will be picked up once the player sees the city.
	visible = bool(demo.first_composition_mode) and not bool(demo.black) and not demo.menu.visible and not demo.planning_guide.opened and not bool(demo.preview_started)
	if not visible:
		queue_redraw()
		return
	var rate := maxf(1.0,float(demo.clock.renderer.transport.sample_rate))
	if world == null:
		trails.clear()
		queue_redraw()
		return
	var active: Array[Dictionary] = []
	for existing: Dictionary in trails:
		var age := (frame-float(existing["birth_frame"]))/rate
		if age >= 0.0 and age < SHOW_SECONDS:
			existing["age"] = age
			active.append(existing)
	trails = active
	for raw_event: Dictionary in world.events:
		if str(raw_event.get("kind","")) != "birth": continue
		var id := str(raw_event.get("district_id",""))
		if id.is_empty() or not world.by_id.has(id): continue
		var event_frame := int(raw_event.get("frame",-1))
		if event_frame < 0 or float(event_frame) > frame: continue
		var key := id+":"+str(event_frame)
		if _seen.has(key): continue
		_seen[key] = true
		# Restored cities contain their historical births. Never replay them as
		# fresh growth just because this visual layer was instantiated now.
		var age := (frame-float(event_frame))/rate
		if age < 0.0 or age >= SHOW_SECONDS: continue
		var building: Dictionary = world.by_id[id]
		if int(building.get("birth_frame",event_frame)) != event_frame: continue
		var family_id := str(building.get("family_id",""))
		var family: Dictionary = world.families.get(family_id,{})
		if not bool(building.get("player_expression",false)) and not bool(family.get("player_expression",false)): continue
		var from_building: Dictionary = _nearest_heard_family_member(world,building,event_frame,frame)
		if from_building.is_empty(): continue
		var expression := str(building.get("expression",family.get("expression","")))
		var identity := Identity.identity(building,family)
		var index := _family_index(world,building,event_frame)
		active.append({"from":Coupling.position_of(from_building),"from_id":str(from_building["district_id"]),"to":Coupling.position_of(building),
			"birth_frame":event_frame,"age":maxf(0.0,(frame-float(event_frame))/rate),"ink":identity.get("ink",Color("aa8956")),
			"label":"你的%s · 第%d栋" % [str(PlayerExpression.definition(expression).get("label",expression)),index],
			"id":id})
	trails = active
	queue_redraw()

func _nearest_heard_family_member(world, building: Dictionary, event_frame: int, frame: float) -> Dictionary:
	var family_id := str(building.get("family_id",""))
	var target := Coupling.position_of(building)
	var nearest: Dictionary = {}
	var nearest_distance := INF
	for candidate: Dictionary in world.buildings:
		if str(candidate.get("district_id","")) == str(building.get("district_id","")): continue
		if str(candidate.get("family_id","")) != family_id: continue
		var candidate_birth := int(candidate.get("birth_frame",-1))
		if candidate_birth < 0 or candidate_birth >= event_frame or float(candidate_birth) > frame: continue
		var distance := target.distance_squared_to(Coupling.position_of(candidate))
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	return nearest

func _family_index(world, building: Dictionary, event_frame: int) -> int:
	var family_id := str(building.get("family_id",""))
	var count := 0
	for candidate: Dictionary in world.buildings:
		if str(candidate.get("family_id","")) != family_id: continue
		if int(candidate.get("birth_frame",event_frame)) <= event_frame: count += 1
	return maxi(1,count)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for trail: Dictionary in trails:
		var age := float(trail.get("age",0.0))
		var ink: Color = trail.get("ink",Color("aa8956"))
		var from := _screen_position(trail.get("from",Vector2.ZERO))
		var to := _screen_position(trail.get("to",Vector2.ZERO))
		var alpha := 0.78*clampf(1.0-age/SHOW_SECONDS,0.0,1.0)
		draw_dashed_line(from,to,Color(ink,alpha),LINE_WIDTH,5.0,true)
		draw_circle(from,3.0,Color(ink,alpha))
		draw_circle(to,5.0,Color(ink,alpha))
		var midpoint := from.lerp(to,0.5)+Vector2(0,-11)
		var label := str(trail.get("label","你的声音在生长"))
		var width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE).x
		draw_rect(Rect2(midpoint-Vector2(width*0.5+6,14),Vector2(width+12,19)),Color("f4f0df",alpha*1.15),true)
		draw_string(font,midpoint+Vector2(-width*0.5,4),label,HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE,Color(ink,alpha*1.18))

func _screen_position(world_position: Vector2) -> Vector2:
	# The owning Demo is the parent.  Keep the helper independent of gameplay
	# state so a headless contract can inspect trails without a renderer.
	var owner := get_parent()
	if owner != null and owner.has_method("point"): return owner.point(world_position)
	return world_position
