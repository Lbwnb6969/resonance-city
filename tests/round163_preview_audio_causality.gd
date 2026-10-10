extends SceneTree
## Preview branches must equal the independently restored, formal continuation.
## The live PCM cursor/state and authored city remain untouched by comparison.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const NeighborhoodPlan = preload("res://scripts/world/neighborhood_plan.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")

var checks: Dictionary = {}
var failures: Array[String] = []
var differences: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _fixture(city: World) -> Dictionary:
	var rid := "round163-causal-reservation"
	for y in range(-36,37):
		for x in range(-36,37):
			var p := Vector2(float(x)*0.25,float(y)*0.25)
			var outer := NeighborhoodPlan.box(p,Vector2(0.42,0.42))
			var candidate := {"polygon":outer,"position":[p.x,p.y]}
			if not city.terrain.valid_footprint(outer) or not Planning.site_reason(city,candidate).is_empty() or Planning.public_access(city,candidate).is_empty(): continue
			var source := NeighborhoodPlan.box(p,Vector2(1.2,1.2))
			var hole := NeighborhoodPlan.box(p,Vector2(0.14,0.14))
			city.planning_reservations.append({"id":rid,"reservation_id":rid,"source_site_id":"round163-causal-source","polygon":source,"position":[p.x,p.y],"created_phrase":city.phrase_index})
			city._refresh_parcel_index()
			var park := PartialPublic.preview_footprints(city,rid,"park",[outer],[hole])
			var civic := PartialPublic.preview_footprints(city,rid,"civic",[outer],[hole])
			if bool(park.get("accepted",false)) and bool(civic.get("accepted",false)):
				park["partial"] = true
				park["reservation_id"] = rid
				park["polygon"] = source
				park["position"] = park["target_position"].duplicate()
				park["community_id"] = park["target_community_id"]
				return park
			city.planning_reservations.pop_back()
			city._refresh_parcel_index()
	return {}

func _operation(site: Dictionary,kind: String) -> Dictionary:
	# Do not call Preview._operation: this is an independent formal submission.
	return {"kind":kind,"partial":true,"source_reservation_id":site["source_reservation_id"],
		"source_revision":site["source_revision"],"target_polygons":site["target_polygons"].duplicate(true),
		"target_holes":site["target_holes"].duplicate(true)}

func _renderer(model: Model,snapshot: Dictionary = {}) -> Renderer:
	var result := Renderer.new(int(model.world.cfg["timing"]["sample_rate"]))
	result.source = model._mix_frame
	if not snapshot.is_empty(): result.restore(snapshot)
	return result

func _max_difference(a: PackedVector2Array,b: PackedVector2Array) -> float:
	if a.size() != b.size(): return INF
	var difference := 0.0
	for index in range(a.size()): difference = maxf(difference,a[index].distance_to(b[index]))
	return difference

func _run() -> void:
	var city := World.new("2026101100000163",true,"river_valley")
	city.build_starter("bright")
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	for index in range(2): city.settle((city.phrase_index+1)*phrase)
	var site := _fixture(city)
	_check(not site.is_empty(),"finds_partial_target_with_real_road_entry")
	if site.is_empty():
		_finish()
		return
	# Hold spontaneous growth constant so the three choices differ only by
	# the authored public conversion; their ordinary sound controls are shared.
	for family in city.families.values(): family["next_growth_phrase"] = 1000
	var model := Model.new(city,1.3409036)
	var rate := int(city.cfg["timing"]["sample_rate"])
	model.synth.focused_community = "west-1"
	model.synth.muted_communities["east-1"] = true
	model.synth.response_enabled = false
	model.synth.configure_score(city,{},city.phrase_index*phrase)
	var live_renderer := _renderer(model)
	live_renderer.transport.rendered_frames = city.phrase_index*phrase
	live_renderer.transport.audible_frame = float(live_renderer.transport.rendered_frames)
	while live_renderer.transport.rendered_frames < model.next_boundary-256:
		live_renderer.render(mini(4096,model.next_boundary-256-live_renderer.transport.rendered_frames))
	model.synth.ducking = true
	model.synth.duck_release_at = model.next_boundary+rate
	live_renderer.render(128)
	var at := live_renderer.transport.rendered_frames
	var boundary := model.next_boundary
	_check(at == model.rendered_until and at == boundary-128,"renderer_model_and_comparison_share_exact_frame")
	_check(float(live_renderer.state.get("_score_duck",1.0)) < 1.0,"source_has_real_nonunity_bus_gain_state")
	var building_id := str(city.communities["west-1"]["members"][0])
	_check(bool(model.submit({"kind":"retune","id":building_id,"midi":52}).get("accepted",false)) and bool(model.submit({"kind":"response","enabled":true}).get("accepted",false)),"shared_authored_controls_queue_at_boundary")
	_check(bool(model.submit(_operation(site,"park")).get("accepted",false)),"source_keeps_older_replaceable_public_intent")
	var captured := model.capture_state()
	var immutable := captured.duplicate(true)
	var renderer_snapshot := live_renderer.snapshot()
	var before := model.capture_state()
	var frozen := model.freeze()
	_check(frozen.synth.ducking == model.synth.ducking and frozen.synth.duck_release_at == model.synth.duck_release_at,"freeze_keeps_bus_ducking_and_release_frame")
	_check(frozen.synth.score_snapshot() == model.synth.score_snapshot(),"freeze_keeps_captured_score_and_voice_state")
	_check(frozen.synth.gain == model.synth.gain and frozen.synth.score["render_voice_limit"] == model.synth.score["render_voice_limit"],"freeze_keeps_same_gain_and_voice_budget")
	var reference := Model.from_state(captured)
	var reference_renderer := _renderer(reference,renderer_snapshot)
	var frozen_renderer := _renderer(frozen,renderer_snapshot)
	var reference_prefix := reference_renderer.render(boundary-at)
	var frozen_prefix := frozen_renderer.render(boundary-at)
	var prefix_difference := _max_difference(reference_prefix,frozen_prefix)
	differences["freeze_vs_restored_before_boundary"] = prefix_difference
	_check(prefix_difference <= 0.000001,"freeze_pcm_matches_formal_continuation_before_boundary")
	_check(model.capture_state() == before and captured == immutable,"restored_and_frozen_rendering_keep_source_and_snapshot_immutable")
	# This is the same extra freeze used when the UI dispatches to a worker.
	var comparison := Preview.build(model.freeze(),site,live_renderer.state,at)
	_check(comparison.get("source_version",[]) == Preview.identity(model,site) and int(comparison.get("source_frame",-1)) == at and int(comparison.get("boundary_frame",-1)) == boundary,"three_branches_share_source_frame_boundary_and_identity")
	_check(float(comparison.get("gain",0.0)) == model.synth.gain and int(comparison.get("sample_rate",0)) == rate,"comparison_retains_gain_and_sample_rate")
	_check(model.capture_state() == before and live_renderer.snapshot() == renderer_snapshot,"building_or_discarding_comparison_keeps_live_rng_cursor_and_pcm_phase")
	var variants: Dictionary = comparison.get("variants",{})
	for kind: String in ["none","park","civic"]:
		var variant: Dictionary = variants.get(kind,{})
		_check(bool(variant.get("accepted",false)),kind+"_comparison_accepts")
		if not bool(variant.get("accepted",false)): continue
		var direct := Model.from_state(captured)
		direct.cancel_planning()
		if kind != "none":
			_check(bool(direct.submit(_operation(site,kind)).get("accepted",false)),kind+"_formal_submission_accepts")
		var direct_renderer := _renderer(direct,renderer_snapshot)
		# Match the producer's block boundaries. The state and model come only
		# from the captured formal runtime, never from preview's private clones.
		while direct_renderer.transport.rendered_frames < boundary:
			direct_renderer.render(mini(1024,boundary-direct_renderer.transport.rendered_frames))
		var direct_pcm := Renderer.pcm16(direct_renderer.render(rate*3))
		var actual: PackedByteArray = variant.get("pcm",PackedByteArray())
		_check(actual.size() == rate*3*4 and actual == direct_pcm,kind+"_three_second_pcm_equals_formal_continuation")
		_check(int(variant.get("max_voices",0)) == direct.synth.max_voice_count and direct.synth.max_voice_count <= int(model.synth.score["render_voice_limit"]),kind+"_uses_same_voice_budget_and_peak_count")
		_check(variant.get("score",{}) == direct.synth.score_snapshot(),kind+"_reported_schedule_equals_formal_score")
	_check(model.capture_state() == before and captured == immutable and live_renderer.snapshot() == renderer_snapshot,"all_branches_and_discard_leave_live_and_saved_snapshot_unchanged")
	# Exercise the capture direction too: actual live rendering must not change
	# the already captured snapshot's pad levels, schedules or mutable controls.
	live_renderer.render(64)
	_check(captured == immutable,"later_live_rendering_does_not_mutate_captured_snapshot")
	var backend := model.synth.native_enabled
	model.synth.native_enabled = not backend
	var backend_copy := model.freeze()
	_check(backend_copy.synth.native_enabled == model.synth.native_enabled,"freeze_keeps_selected_render_backend")
	model.synth.native_enabled = backend
	backend_copy.synth.score["theme_gain"] = float(backend_copy.synth.score["theme_gain"])+0.01
	_check(backend_copy.synth.score["theme_gain"] != model.synth.score["theme_gain"],"private_frozen_score_does_not_alias_live_configuration")
	_finish()

func _finish() -> void:
	print("ROUND163_PREVIEW_AUDIO_CAUSALITY ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"differences":differences,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
