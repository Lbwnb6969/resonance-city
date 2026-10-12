extends SceneTree
## Real accepted seeds retain a read-only land marker without an audition branch.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Identity = preload("res://scripts/visual/first_expression_identity.gd")
const OUTPUT := "res://验证记录/round204_点击即试听/pending_marker.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var demo: Control

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _prepare() -> World:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	demo.first_composition_mode = true
	demo.shown_world = city.fork()
	demo.expression_audition_layer.sync(demo)
	return city

func _submit(expression: String) -> Dictionary:
	var candidate: Dictionary = First.opportunities(demo.model.world)["seed_candidates"][0]
	var operation := PlayerExpression.operation(expression,candidate["position"])
	var result: Dictionary = demo.model.submit(operation)
	demo.pending_expression_choice = {"operation":operation.duplicate(true),"boundary_frame":int(result["frame"]),
		"event_id":int(result["event_id"]),"source_model":demo.model}
	return result

func _run() -> void:
	demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	check(AudioServer.get_driver_name() == "Dummy","dummy_audio_only")
	var city := _prepare()
	var layer = demo.expression_audition_layer
	var submitted := _submit("warm")
	check(bool(submitted.get("accepted",false)),"real_first_seed_is_accepted")
	var boundary := int(submitted["frame"])
	var rate := float(demo.clock.renderer.transport.sample_rate)
	demo.clock.renderer.transport.audible_frame = float(boundary)/2.0
	var before := city.snapshot()
	layer.sync(demo)
	var marker: Dictionary = layer.pending_marker.duplicate(true)
	var raw: Array = demo.pending_expression_choice["operation"]["position"]
	var position := Vector2(float(raw[0]),float(raw[1]))
	check(layer.queued.is_empty() and layer.ghost.is_empty() and not marker.is_empty(),"immediate_confirmation_needs_no_preview_house")
	check(marker.get("world_position",Vector2.INF) == position and marker.get("event_id",-1) == submitted["event_id"] and marker.get("boundary_frame",-1) == boundary,"marker_uses_accepted_land_and_transaction_identity")
	check(marker.get("ink",Color.BLACK) == Identity.STYLES["warm"]["ink"] and marker.get("text","") == "待落成 · 暖庭 · %.1f秒" % (float(boundary)/2.0/rate) and marker.get("polygon",PackedVector2Array()).size() == 4,"marker_shows_expression_colour_footprint_and_device_countdown")
	check(city.snapshot() == before and not marker.has("root_id") and not marker.has("texture"),"marker_is_read_only_and_does_not_claim_a_future_house")
	city.settle(boundary)
	before = city.snapshot()
	layer.sync(demo)
	check(city.pending_actions.is_empty() and layer.pending_marker.get("world_position",Vector2.INF) == position and layer.pending_marker.get("event_id",-1) == submitted["event_id"] and demo.shown_world.buildings.size() == 24,"render_ahead_keeps_marker_without_revealing_future_root")
	check(city.snapshot() == before,"render_ahead_marker_query_is_read_only")
	demo.clock.renderer.transport.audible_frame = float(boundary)-1.0
	layer.sync(demo)
	check(not layer.pending_marker.is_empty(),"last_unheard_sample_still_has_marker")
	demo.clock.renderer.transport.audible_frame = boundary
	layer.sync(demo)
	check(layer.pending_marker.is_empty(),"heard_boundary_clears_marker")
	city = _prepare()
	_submit("weave")
	demo.model.cancel_pending()
	layer.sync(demo)
	check(not demo.pending_expression_choice.is_empty() and layer.pending_marker.is_empty(),"withdrawal_clears_marker_even_when_ui_identity_remains")
	city = _prepare()
	_submit("deep")
	demo.pending_expression_choice["source_model"] = Model.new(city.fork())
	layer.sync(demo)
	check(layer.pending_marker.is_empty(),"previous_model_identity_cannot_leave_marker")
	city = _prepare()
	submitted = _submit("deep")
	raw = demo.pending_expression_choice["operation"]["position"]
	city._birth(Vector2(float(raw[0]),float(raw[1])),48,str(city.buildings[0]["family_id"]),false,0)
	city.refresh_fabric()
	city.settle(int(submitted["frame"]))
	before = city.snapshot()
	layer.sync(demo)
	check(layer.pending_marker.is_empty() and city.snapshot() == before,"failed_real_seed_settlement_clears_marker_before_device_boundary")
	city = _prepare()
	submitted = _submit("warm")
	var branch: World = city.fork()
	branch.settle(int(submitted["frame"]))
	var birth: Dictionary = {}
	for building: Dictionary in branch.buildings:
		if bool(building.get("player_expression",false)) and bool(building.get("family_anchor",false)):
			birth = {"building":building.duplicate(true),"family":branch.families[str(building["family_id"])].duplicate(true)}
	layer.queue_choice({"accepted":true,"birth":birth},int(submitted["frame"]),int(submitted["event_id"]))
	before = city.snapshot()
	layer.sync(demo)
	check(layer.ghost.get("mode","") == "待落成" and layer.pending_marker.is_empty() and city.snapshot() == before,"normal_accepted_house_ghost_has_priority_without_duplicate_marker")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Dummy production presentation layer over genuine accepted seeds and settlements. Accepted land, expression colour and device countdown survive render-ahead; withdrawal, old models and heard boundaries clear the marker, and a normal audition house is drawn once. No physical device, screenshot or human-fun claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND204_PENDING_EXPRESSION_MARKER ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
