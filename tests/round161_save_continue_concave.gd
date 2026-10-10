extends SceneTree
## Round 161: a concave public conversion survives both the binary checkpoint
## (Ctrl+S/F9) and the readable City DNA path, then remains plannable.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const NeighborhoodPlan = preload("res://scripts/world/neighborhood_plan.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const FabricRelations = preload("res://scripts/world/fabric_relations.gd")
const Archive = preload("res://scripts/world/city_archive.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _find_target(city: World) -> Dictionary:
	var half := Vector2(float(city.cfg["city"]["civic_half_width"])*0.28,float(city.cfg["city"]["civic_half_length"])*0.28)
	for y in range(-36,37):
		for x in range(-36,37):
			var center := Vector2(float(x)*0.25,float(y)*0.25)
			var box := NeighborhoodPlan.box(center,half)
			if not city.terrain.valid_footprint(box): continue
			var candidate := {"source_site_id":"round161-source","reservation_id":"round161-reservation",
				"position":[center.x,center.y],"polygon":box,"community_id":FabricRelations.community_for_position(city,center)}
			if not Planning.site_reason(city,candidate,"round161-reservation").is_empty(): continue
			var access := Planning.public_access(city,candidate)
			if access.is_empty(): continue
			return {"center":center,"box":box}
	return {}

func _concave_target(center: Vector2,bounds: Rect2) -> PackedVector2Array:
	var width := bounds.size.x*0.27
	var height := bounds.size.y*0.27
	return PackedVector2Array([
		center+Vector2(-width,-height),
		center+Vector2(width,-height),
		center+Vector2(width,height),
		center+Vector2(width*0.18,height*0.18),
		center+Vector2(-width,height)])

func _same_polygon(raw: Variant, expected: PackedVector2Array) -> bool:
	var polygon := Planning.normalize_polygon(raw)
	return polygon == expected

func _find_next_public_preview(city: World) -> Dictionary:
	# Residuals retain the source road boundary in at least one fragment. Search
	# their interior rather than assuming a particular sorted fragment index.
	for reservation in city.planning_reservations:
		var polygon: PackedVector2Array = reservation.get("polygon",PackedVector2Array())
		if polygon.size() < 3: continue
		var bounds := Planning.bounds(polygon)
		for yi in range(0,17):
			for xi in range(0,17):
				var point := Vector2(lerpf(bounds.position.x+0.01,bounds.end.x-0.01,float(xi)/16.0),lerpf(bounds.position.y+0.01,bounds.end.y-0.01,float(yi)/16.0))
				if not Geometry2D.is_point_in_polygon(point,polygon): continue
				for kind in ["park","civic"]:
					var preview := PartialPublic.preview(city,str(reservation.get("reservation_id",reservation.get("id",""))),kind,point)
					if bool(preview.get("accepted",false)): return preview
	return {}

func _cleanup(directory: String, paths: Array[String]) -> void:
	for path in paths:
		if not path.is_empty() and FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var exports := directory+"/exports"
	if DirAccess.dir_exists_absolute(exports): DirAccess.remove_absolute(exports)
	if DirAccess.dir_exists_absolute(directory): DirAccess.remove_absolute(directory)

func _run() -> void:
	var directory := "user://round161_save_continue_%d" % Time.get_ticks_usec()
	var dna_directory := directory+"/exports"
	var paths: Array[String] = []
	var city := World.new("2026101100000161",true,"river_valley")
	city.build_starter("bright")
	var found := _find_target(city)
	_check(not found.is_empty(),"finds_save_fixture_target")
	if found.is_empty():
		_cleanup(directory,paths)
		_finish()
		return
	var center: Vector2 = found["center"]
	var base: PackedVector2Array = found["box"]
	var source := NeighborhoodPlan.box(Planning.bounds(base).get_center(),Planning.bounds(base).size*0.5+Vector2.ONE*1.2)
	var reservation_id := "round161-reservation"
	city.planning_reservations.append({"id":reservation_id,"reservation_id":reservation_id,"source_site_id":"round161-source",
		"polygon":source,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var target := _concave_target(center,Planning.bounds(base))
	var preview := PartialPublic.preview_footprint(city,reservation_id,"civic",target)
	_check(bool(preview.get("accepted",false)),"fixture_accepts_concave_target")
	if not bool(preview.get("accepted",false)):
		_cleanup(directory,paths)
		_finish()
		return
	var model := Model.new(city,1.3409036)
	var queued := model.submit({"kind":"civic","partial":true,"source_reservation_id":reservation_id,
		"target_polygon":target,"source_revision":preview["source_revision"]})
	_check(bool(queued.get("accepted",false)),"queues_concave_target_before_checkpoint")
	var pending_before: Dictionary = city.pending_actions[0] if not city.pending_actions.is_empty() else {}
	_check(_same_polygon(pending_before.get("target_polygon",PackedVector2Array()),target),"pending_target_geometry_is_present")
	_check(pending_before.get("target_entrance",[]).size() == 2 and pending_before.get("target_access_path",PackedVector2Array()).size() >= 2,"pending_target_access_is_present")
	var checkpoint := Archive.save({"model":model.capture_state(),"renderer":{},"view":{}},"round161 concave checkpoint",directory)
	_check(bool(checkpoint.get("ok",false)),"ctrl_s_checkpoint_writes")
	if bool(checkpoint.get("ok",false)): paths.append(str(checkpoint["path"]))
	var loaded := Archive.latest(directory)
	_check(bool(loaded.get("ok",false)),"f9_finds_checkpoint")
	var resumed: Model = Model.from_state(loaded["city"]["model"]) if bool(loaded.get("ok",false)) else model
	var resumed_pending: Dictionary = resumed.world.pending_actions[0] if not resumed.world.pending_actions.is_empty() else {}
	_check(_same_polygon(resumed_pending.get("target_polygon",PackedVector2Array()),target),"f9_restores_pending_concave_geometry")
	_check(resumed_pending.get("target_entrance",[]).size() == 2 and resumed_pending.get("target_access_path",PackedVector2Array()).size() >= 2,"f9_restores_target_access")
	var boundary := resumed.next_boundary
	var rate := int(resumed.world.cfg["timing"]["sample_rate"])
	resumed.render_block({},boundary-1,2,rate)
	var site: Dictionary = {}
	for candidate in resumed.world.public_sites:
		if str(candidate.get("source_reservation_id","")) == reservation_id: site = candidate
	_check(not site.is_empty(),"f9_continues_to_boundary_commit")
	_check(_same_polygon(site.get("polygon",PackedVector2Array()),target),"f9_keeps_concave_site_geometry")
	_check(site.get("entrance",[]).size() == 2 and site.get("access_path",PackedVector2Array()).size() >= 2,"f9_keeps_target_road_entry")
	var conversion_event: Dictionary = {}
	for event in resumed.world.events:
		if bool(event.get("partial",false)) and str(event.get("source_reservation_id","")) == reservation_id: conversion_event = event
	_check(not conversion_event.is_empty(),"f9_restores_conversion_event")
	_check(conversion_event.get("target_entrance",[]).size() == 2 and conversion_event.get("target_access_path",PackedVector2Array()).size() >= 2,"f9_restores_event_access")
	_check(resumed.transition_total > 0,"f9_restores_audio_structural_seam")
	var before_sound_events := resumed.sound_events.size()
	var renderer := {"transport":{"rendered_frames":resumed.rendered_until,"audible_frame":float(resumed.rendered_until),"pending":[],"accepted_events":[],"approved_proposals":{}},"state":{}}
	var exported := Archive.export_dna({"model":resumed.capture_state(),"renderer":renderer,"view":{}},dna_directory)
	_check(bool(exported.get("ok",false)),"ctrl_shift_e_exports_dna")
	if bool(exported.get("ok",false)): paths.append(str(exported["path"]))
	var dna := Archive.latest_dna(dna_directory)
	_check(bool(dna.get("ok",false)),"dna_reader_finds_export")
	var continued: Model = Model.from_state(dna["model"]) if bool(dna.get("ok",false)) else resumed
	var dna_site: Dictionary = {}
	for candidate in continued.world.public_sites:
		if str(candidate.get("source_reservation_id","")) == reservation_id: dna_site = candidate
	_check(not dna_site.is_empty(),"dna_restores_concave_site")
	_check(_same_polygon(dna_site.get("polygon",PackedVector2Array()),target),"dna_restores_target_geometry")
	_check(dna_site.get("entrance",[]).size() == 2 and dna_site.get("access_path",PackedVector2Array()).size() >= 2,"dna_restores_target_road_entry")
	_check(continued.world.planning_reservations.size() >= 1,"dna_restores_residual_reservations")
	_check(continued.world.planning_reservations.all(func(item: Dictionary)->bool:
		return str(item.get("parent_reservation_id","")) == reservation_id and item.get("polygon",PackedVector2Array()).size() >= 3),"dna_restores_residual_geometry_and_lineage")
	_check(continued.world.events.any(func(event: Dictionary)->bool:
		return bool(event.get("partial",false)) and str(event.get("source_reservation_id","")) == reservation_id),"dna_restores_conversion_event")
	_check(continued.sound_events.size() == before_sound_events,"dna_restores_pending_audio_events")
	_check(continued.world.snapshot().get("public_sites",[]).size() == resumed.world.snapshot().get("public_sites",[]).size(),"dna_world_snapshot_keeps_public_sites")
	# The decisive continuation check: after JSON hydration the residual is still
	# a legal source for another player planning action.
	var next_preview := _find_next_public_preview(continued.world)
	_check(bool(next_preview.get("accepted",false)),"dna_residual_remains_plannable")
	if bool(next_preview.get("accepted",false)):
		var next_id := str(next_preview.get("source_reservation_id",""))
		var next_queued := continued.submit({"kind":str(next_preview.get("kind","park")),"partial":true,
			"source_reservation_id":next_id,"target_polygon":next_preview["target_polygon"],"source_revision":next_preview["source_revision"]})
		_check(bool(next_queued.get("accepted",false)),"dna_continues_with_next_public_plan")
	_cleanup(directory,paths)
	_finish()

func _finish() -> void:
	print("ROUND161_SAVE_CONTINUE_CONCAVE ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
