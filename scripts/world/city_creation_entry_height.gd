extends RefCounted
## Ordinary door-to-street support, sampled on the existing terrain/step mesh.
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const Frontage=preload("res://scripts/world/city_creation_frontage.gd")
const Roads=preload("res://scripts/world/city_creation_road_heights.gd")
const Deck=preload("res://scripts/world/city_creation_alpine_deck_plan.gd")
const EPS:=.002
const SAMPLE:=.04
const MODERN_SILL_DROP:=.18 # Doorway allowance; road treads still use STEP_HEIGHT.

static func assess(city:RefCounted,house:Dictionary,entry:Dictionary,target:Vector2,road:Dictionary,prepared_obstacles:Variant=null)->Dictionary:
	# Through arches keep their existing road-floor semantics in this batch.
	if entry.get("passage",false):return {"ok":true,"kind":"existing_passage","scope":"unchanged"}
	var modern:bool=not entry.active and city.house_era(house)=="modern_eco"
	var plan:Dictionary=Frontage.porch_plan(city,house,entry) if entry.active else {}
	var deck:Dictionary=Deck.for_entry(city,house,entry) if modern and city.CreationPolicy.is_free(city) else {}
	if modern and Deck.facing(house) and not city.CreationPolicy.is_free(city):return {"ok":true,"kind":"existing_modern_deck","scope":"unchanged"}
	city.road_profile(road)
	var sampler=preload("res://scripts/world/city_creation_entry_surface.gd").create(city,house,entry,road,plan)
	var base:float=house.get("base_y",0.)
	sampler.steps.append_array(Deck.surfaces(deck,base))
	var start_offset:float=.18 if deck.is_empty() else Deck.ENTRY_START
	var start:Vector2=entry.wall_at+Frame.normal(entry)*start_offset
	var previous:Dictionary=sampler.sample(start)
	var top:float=base+(Deck.DECK_TOP if not deck.is_empty() else .15 if entry.active or modern else .105)
	var kind:="modern_terrace_deck" if not deck.is_empty() else "modern_ground_door" if modern else "ordinary_door"
	var result:={"ok":false,"kind":kind,"sill_y":top,"street_y":city.street_height(target),"active_steps":bool(entry.active),"step_count":int(plan.get("count",0))+int(deck.get("tread",false)),"max_rise":0.,"max_grade":0.,"samples":0,"reason":"door_buried"}
	if float(previous.y)>top+EPS:result.blocked_at=start;return _diagnostic(result)
	# Modern facades have a .15m room plinth, no classical exterior steps.
	# The existing facade coping tops out at .18m; a larger drop has no step.
	if modern and top-float(previous.y)>MODERN_SILL_DROP+EPS:
		result.reason="unsupported_sill_drop";result.blocked_at=start;return _diagnostic(result)
	var count:=maxi(1,ceili(start.distance_to(target)/SAMPLE));var last:=start
	for i in range(1,count+1):
		var at:=start.lerp(target,float(i)/count);var surface:Dictionary=sampler.sample(at)
		var rise:float=absf(surface.y-previous.y);var distance:=at.distance_to(last)
		result.max_rise=maxf(result.max_rise,rise);result.samples=i
		if rise>Roads.STEP_HEIGHT+Roads.MAX_GRADE*distance+EPS:
			result.reason="unsupported_height_break";result.blocked_at=at;return _diagnostic(result)
		if surface.kind==previous.kind and surface.kind in ["ground","road"]:
			var grade:=rise/maxf(distance,.000001);result.max_grade=maxf(result.max_grade,grade)
			if rise>Roads.MAX_GRADE*distance+EPS:result.reason="steep_unstepped_ground";result.blocked_at=at;return _diagnostic(result)
		previous=surface;last=at
	if absf(float(previous.y)-float(result.street_y))>Roads.STEP_HEIGHT+EPS:
		result.reason="steps_miss_street";result.blocked_at=target;return _diagnostic(result)
	result.corridor=preload("res://scripts/world/city_creation_entry_corridor.gd").assess(city,house,entry,target,road,sampler.sample,prepared_obstacles,start_offset)
	if not result.corridor.ok:result.reason=result.corridor.reason;return _diagnostic(result)
	result.ok=true;result.reason="supported";return _diagnostic(result)

static func _diagnostic(result:Dictionary)->Dictionary:
	# Canonical diagnostics exclude sub-micron profile interpolation noise.
	# All access decisions above still use the original, unrounded heights.
	for key:String in ["sill_y","street_y","max_rise","max_grade"]:result[key]=snappedf(float(result[key]),.000001)
	return result

static func _surface(city:RefCounted,house:Dictionary,entry:Dictionary,at:Vector2,road:Dictionary,profile:Dictionary,plan:Dictionary)->Dictionary:
	return preload("res://scripts/world/city_creation_entry_surface.gd").create(city,house,entry,road,plan).sample(at)
