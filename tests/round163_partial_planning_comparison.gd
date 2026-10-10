extends SceneTree
## One painted partial target must be the same decision in all P11 branches.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const NeighborhoodPlan = preload("res://scripts/world/neighborhood_plan.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func _anchor(city: World) -> Dictionary:
	for y in range(-36,37):
		for x in range(-36,37):
			var p := Vector2(float(x)*0.25,float(y)*0.25)
			var outer := NeighborhoodPlan.box(p,Vector2(0.42,0.42))
			var candidate := {"polygon":outer,"position":[p.x,p.y]}
			if not city.terrain.valid_footprint(outer) or not Planning.site_reason(city,candidate).is_empty() or Planning.public_access(city,candidate).is_empty(): continue
			return {"position":p,"outer":outer}
	return {}

func _run() -> void:
	var city := World.new("2026101100000162",true,"river_valley")
	city.build_starter("bright")
	var found := _anchor(city)
	check(not found.is_empty(),"finds_real_road_accessible_target")
	if found.is_empty():
		_finish()
		return
	var p: Vector2 = found["position"]
	var outer: PackedVector2Array = found["outer"]
	var hole := NeighborhoodPlan.box(p,Vector2(0.14,0.14))
	var source := NeighborhoodPlan.box(p,Vector2(1.2,1.2))
	var rid := "round163-source-reservation"
	city.planning_reservations.append({"id":rid,"reservation_id":rid,"source_site_id":"round163-source","polygon":source,"position":[p.x,p.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var components: Array = []
	var geometry: Dictionary = {}
	for offset in [Vector2(0.75,0),Vector2(-0.75,0),Vector2(0,0.75),Vector2(0,-0.75)]:
		var second := NeighborhoodPlan.box(p+offset,Vector2(0.1,0.1))
		var candidate := PartialPublic.preview_footprints(city,rid,"park",[outer,second],[hole])
		if bool(candidate.get("accepted",false)):
			geometry = candidate
			components = [outer,second]
			break
	check(not geometry.is_empty(),"finds_disjoint_component_and_courtyard")
	if geometry.is_empty():
		_finish()
		return
	# An older sibling from this same source must not be returned as the new
	# branch's anchor. Its footprint stays outside the painted target.
	for kind in ["park","civic"]:
		var older_position := p+Vector2(0,3)
		city.public_sites.insert(0,{"id":"older-"+kind,"kind":kind,"active":true,"source_site_id":"round163-source","polygon":NeighborhoodPlan.box(older_position,Vector2(0.1,0.1)),"position":[older_position.x,older_position.y],"entrance":[older_position.x,older_position.y],"community_id":"west-1","service_level":1})
	city._refresh_parcel_index()
	var model := Model.new(city)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var at := model.next_boundary-1
	var state: Dictionary = {}
	model.render_block(state,at-64,64,rate)
	var site := geometry.duplicate(true)
	site["partial"] = true
	site["reservation_id"] = rid
	site["polygon"] = source.duplicate()
	site["position"] = geometry["target_position"].duplicate()
	site["community_id"] = geometry["target_community_id"]
	var identity := Preview.identity(model,site)
	for key in ["source_revision","target_holes","hole_polygons","target_polygons","footprint_components","target_position"]:
		var changed := site.duplicate(true)
		if key == "source_revision": changed[key] = "outdated-source"
		elif key == "target_position": changed[key] = [p.x+0.01,p.y]
		else: changed[key] = []
		check(Preview.identity(model,changed) != identity,"identity_invalidates_"+key)
	var prior := model.capture_state()
	var original_phases := state.duplicate(true)
	var comparison := Preview.build(model,site,state,at)
	check(model.capture_state() == prior and state == original_phases,"comparison_does_not_mutate_live_model_rng_or_pcm_phase")
	check(comparison.get("source_version",[]) == identity,"comparison_keeps_exact_source_identity")
	var variants: Dictionary = comparison.get("variants",{})
	check(variants.size() == 3,"three_real_partial_branches")
	for kind: String in ["none","park","civic"]:
		var variant: Dictionary = variants.get(kind,{})
		check(bool(variant.get("accepted",false)),kind+"_branch_accepts")
		if not bool(variant.get("accepted",false)): continue
		var pcm: PackedByteArray = variant.get("pcm",PackedByteArray())
		check(pcm.size() == rate*3*4,kind+"_renders_exact_three_seconds")
		var opportunity: Dictionary = variant.get("opportunity_preview",{})
		check(opportunity.get("source_version",[]) == identity and int(opportunity.get("source_frame",-1)) == at and int(opportunity.get("boundary_frame",-1)) == model.next_boundary,kind+"_opportunity_uses_shared_boundary")
		check(not opportunity.get("communities",[]).is_empty() and variant.has_all(["service","score","opportunities"]),kind+"_keeps_existing_p11_format")
		var direct_source := model.freeze()
		direct_source.cancel_planning()
		var direct := direct_source.freeze()
		if kind != "none":
			var submitted := direct.submit({"kind":kind,"partial":true,"source_reservation_id":rid,"source_revision":geometry["source_revision"],"target_polygons":components,"target_holes":[hole]})
			check(bool(submitted.get("accepted",false)),kind+"_direct_commit_accepts")
		var phases := state.duplicate(true)
		direct.render_block(phases,at,model.next_boundary-at,rate)
		var expected := Renderer.pcm16(direct.render_block(phases,model.next_boundary,rate*3,rate))
		check(pcm == expected,kind+"_pcm_equals_direct_exact_geometry_commit")
		if kind == "none":
			check(direct.world.planning_reservations.any(func(reservation: Dictionary)->bool: return str(reservation.get("reservation_id","")) == rid and reservation.get("polygon",PackedVector2Array()) == source),"none_preserves_whole_source_reservation")
			check(variant.get("anchor",{}).is_empty(),"none_does_not_claim_public_anchor")
		else:
			var anchor: Dictionary = variant.get("anchor",{})
			check(str(anchor.get("id","")).begins_with("partial-"+kind+"-"),kind+"_anchor_is_this_event_not_older_sibling")
			check(anchor.get("target_polygons",[]) == components and anchor.get("hole_polygons",[]) == [hole],kind+"_anchor_preserves_every_component_and_hole")
			check(anchor.get("polygon",PackedVector2Array()) != source and anchor.get("polygon",PackedVector2Array()) == outer,kind+"_does_not_expand_to_source_reservation")
			check(str(anchor.get("source_reservation_id","")) == rid,kind+"_anchor_keeps_source_reservation")
			var source_event: Dictionary = {}
			for event in direct.world.events:
				if str(event.get("id","")) == str(anchor.get("id","")) and int(event.get("frame",-1)) == model.next_boundary: source_event = event
			check(source_event.get("remaining_polygons",[]).has(hole),kind+"_courtyard_remains_plannable")
	var aliases := site.duplicate(true)
	aliases.erase("source_reservation_id")
	aliases.erase("target_polygons")
	aliases.erase("target_polygon")
	aliases.erase("hole_polygons")
	aliases.erase("position")
	var alias_operation := Preview._operation(aliases,"civic")
	var alias_model := model.freeze()
	check(bool(alias_model.submit(alias_operation).get("accepted",false)) and alias_model.world.pending_actions.back().get("target_polygons",[]) == components and alias_model.world.pending_actions.back().get("hole_polygons",[]) == [hole],"reservation_component_hole_position_aliases_keep_exact_geometry")
	var single := site.duplicate(true)
	single["target_polygons"] = [outer]
	single["footprint_components"] = [outer]
	single["hole_polygons"] = []
	single["target_holes"] = []
	var single_model := model.freeze()
	check(bool(single_model.submit(Preview._operation(single,"park")).get("accepted",false)) and single_model.world.pending_actions.back().get("target_polygons",[]) == [outer],"single_component_target_keeps_exact_geometry")
	var stale := site.duplicate(true)
	stale["source_revision"] = "expired"
	var stale_comparison := Preview.build(model,stale,state,at)
	check(bool(stale_comparison["variants"]["none"]["accepted"]),"stale_geometry_still_allows_no_conversion")
	for kind in ["park","civic"]:
		check(not bool(stale_comparison["variants"][kind]["accepted"]) and str(stale_comparison["variants"][kind]["reason"]).contains("留地已经变化"),kind+"_stale_revision_rejected_without_whole_site_fallback")
	_finish()

func _finish() -> void:
	print("ROUND163_PARTIAL_PLANNING_COMPARISON checks=%d failures=%s" % [checks,JSON.stringify(failures)])
	quit(0 if failures.is_empty() else 1)
