extends SceneTree
## Round 161: a concave public conversion reaches the audible boundary.
##
## The planned model is rendered through the phrase boundary.  The conversion
## event must enter the structural audio seam while keeping the PCM continuous;
## world/audio identity is checked separately from subjective listening.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const NeighborhoodPlan = preload("res://scripts/world/neighborhood_plan.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const FabricRelations = preload("res://scripts/world/fabric_relations.gd")

var failures: Array[String] = []
var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _freeze_growth(city: World) -> void:
	for family in city.families.values(): family["next_growth_phrase"] = 1000

func _find_anchor(city: World) -> Dictionary:
	var half := Vector2(float(city.cfg["city"]["civic_half_width"])*0.28,float(city.cfg["city"]["civic_half_length"])*0.28)
	for y in range(-36,37):
		for x in range(-36,37):
			var center := Vector2(float(x)*0.25,float(y)*0.25)
			var box := NeighborhoodPlan.box(center,half)
			if not city.terrain.valid_footprint(box): continue
			var candidate := {"source_site_id":"round161-audio-source","reservation_id":"round161-audio-reservation",
				"position":[center.x,center.y],"polygon":box,"community_id":FabricRelations.community_for_position(city,center)}
			if not Planning.site_reason(city,candidate,"round161-audio-reservation").is_empty(): continue
			if Planning.public_access(city,candidate).is_empty(): continue
			var community_id := str(candidate["community_id"])
			if city.public_sites.any(func(site: Dictionary)->bool:
				return bool(site.get("active",false)) and str(site.get("community_id","")) == community_id): continue
			return {"center":center,"box":box}
	return {}

func _target(center: Vector2,bounds: Rect2) -> PackedVector2Array:
	var width := bounds.size.x*0.27
	var height := bounds.size.y*0.27
	return PackedVector2Array([center+Vector2(-width,-height),center+Vector2(width,-height),center+Vector2(width,height),center+Vector2(width*0.18,height*0.18),center+Vector2(-width,height)])

func _max_difference(a: PackedVector2Array,b: PackedVector2Array,from_index: int) -> float:
	var result := 0.0
	for index in range(from_index,min(a.size(),b.size())): result = maxf(result,a[index].distance_to(b[index]))
	return result

func _render_to(model: ContinuousAudioModel,end_frame: int,rate: int) -> Dictionary:
	var state := {}
	var at := 0
	while at < end_frame:
		var amount := mini(4096,end_frame-at)
		model.render_block(state,at,amount,rate)
		at += amount
	return state

func _run() -> void:
	var city := World.new("2026101100000161",true,"river_valley")
	city.build_starter("bright")
	_freeze_growth(city)
	var found := _find_anchor(city)
	_check(not found.is_empty(),"finds_audio_fixture_anchor")
	if found.is_empty():
		_finish()
		return
	var center: Vector2 = found["center"]
	var base: PackedVector2Array = found["box"]
	var source := NeighborhoodPlan.box(Planning.bounds(base).get_center(),Planning.bounds(base).size*0.5+Vector2.ONE*1.2)
	var reservation_id := "round161-audio-reservation"
	city.planning_reservations.append({"id":reservation_id,"reservation_id":reservation_id,"source_site_id":"round161-audio-source",
		"polygon":source,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var target := _target(center,Planning.bounds(base))
	var preview := PartialPublic.preview_footprint(city,reservation_id,"civic",target)
	_check(bool(preview.get("accepted",false)),"audio_fixture_accepts_concave_target")
	if not bool(preview.get("accepted",false)):
		_finish()
		return
	var planned := Model.new(city,1.3409036)
	var boundary := planned.next_boundary
	var rate := int(city.cfg["timing"]["sample_rate"])
	var start := boundary-128
	# Advance one initialized model through the same PCM blocks first.  Clone at
	# that exact phase point so the control path differs only by the queued plan.
	var planned_state := _render_to(planned,start,rate)
	var control: ContinuousAudioModel = planned.freeze()
	var control_state: Dictionary = planned_state.duplicate(true)
	var queued := planned.submit({"kind":"civic","partial":true,"source_reservation_id":reservation_id,
		"target_polygon":target,"source_revision":preview["source_revision"]})
	_check(bool(queued.get("accepted",false)),"concave_target_queues_for_audio_boundary")
	var planned_pcm := planned.render_block(planned_state,start,256,rate)
	var control_pcm := control.render_block(control_state,start,256,rate)
	var pre_difference := _max_difference(planned_pcm,control_pcm,0)
	var post_difference := _max_difference(planned_pcm,control_pcm,128)
	_check(planned.transition_total == roundi(0.08*rate),"concave_conversion_uses_80ms_structural_seam")
	_check(planned_pcm[128].distance_to(planned_pcm[127]) < 0.000001,"concave_conversion_pcm_boundary_is_continuous")
	_check(planned.world.events.any(func(event: Dictionary)->bool:
		return bool(event.get("partial",false)) and str(event.get("facility_kind","")) == "civic"),"concave_conversion_event_reaches_audio_model")
	var facility := planned.world.public_sites.any(func(site: Dictionary)->bool:
		return bool(site.get("active",false)) and str(site.get("source_reservation_id","")) == reservation_id and str(site.get("kind","")) == "civic")
	_check(facility,"concave_conversion_facility_is_active_at_audio_boundary")
	_finish({"pre_difference":pre_difference,"post_difference":post_difference})

func _finish(extra: Dictionary = {}) -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures}
	report.merge(extra,true)
	print("ROUND161_AUDIO_BOUNDARY_CONCAVE ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
