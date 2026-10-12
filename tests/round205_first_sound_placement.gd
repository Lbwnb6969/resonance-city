extends SceneTree
## Same real two-segment city as round204: west-2 warm, east-2 civic.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Preview = preload("res://scripts/world/expression_preview.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Duet = preload("res://scripts/world/authored_duet.gd")
const Placement = preload("res://scripts/world/first_sound_placement.gd")
const OUTPUT := "res://验证记录/round205_声音推荐落点/contract.json"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _click(at: Array) -> void:
	var event := InputEventMouseButton.new()
	event.position = demo.point(Vector2(float(at[0]),float(at[1])))
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)

func _scope(cid: String,index: int) -> Dictionary:
	var guide = demo.planning_guide
	guide.cards.get_child(index).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var site: Dictionary = {}
	for candidate: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(candidate["community_id"]) == cid: site = candidate; break
	_click(site["position"])
	guide.confirm.emit_signal("pressed")
	return site

func _advance(to: int) -> void:
	while demo.clock.renderer.transport.rendered_frames < to:
		demo.clock.renderer.render(mini(4096,to-demo.clock.renderer.transport.rendered_frames))
	demo.clock.renderer.transport.audible_frame = float(to)
	demo._process(0.0)

func _fixture() -> String:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	demo.clock.renderer.source = demo.model._mix_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var guide = demo.planning_guide
	guide.open_tool()
	var site := _scope("west-2",0)
	guide.choose_anchor("none")
	_click(site["position"])
	_advance(int(guide.next_action["expected_boundary_frame"])+rate/5)
	guide.next_action_button.emit_signal("pressed")
	demo.expression_choices["warm"].emit_signal("pressed")
	demo.expression_confirm.emit_signal("pressed")
	_advance(demo.model.next_boundary+rate/4)
	var root_id := str(demo._first_authored_state()["root_id"])
	demo.first_composition_guide.emit_signal("pressed")
	(demo.menu.get_meta("care_for_land") as Button).emit_signal("pressed")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	demo._input(escape)
	demo._process(0.0)
	demo.first_composition_guide.emit_signal("pressed")
	(demo.menu.get_meta("compose_more") as Button).emit_signal("pressed")
	site = _scope("east-2",2)
	guide.choose_anchor("civic")
	_click(site["position"])
	_advance(int(guide.next_action["expected_boundary_frame"])+rate/5)
	return root_id

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	check(AudioServer.get_driver_name() == "Dummy","isolated_dummy_driver")
	var root_id := _fixture()
	var pool: Array = Duet.candidates(demo.shown_world,root_id,"east-2",-1)
	check(demo.model.world.by_id[root_id]["expression"] == "warm" and demo.model.world.by_id[root_id]["community_id"] == "west-2" and demo.model.world.public_sites.any(func(site: Dictionary) -> bool: return bool(site.get("active",false)) and site.get("community_id","") == "east-2" and site.get("kind","") == "civic"),"fixture_has_actual_warm_root_and_opposite_civic")
	check(pool.size() >= 2,"existing_sorted_duet_pool_has_multiple_legal_street_candidates")
	var before := demo.model.world.snapshot()
	var pool_before := pool.duplicate(true)
	var boundary := demo.model.next_boundary
	var first_branch: RefCounted = demo.model.world.fork()
	var first_warm: Dictionary = first_branch.request(PlayerExpression.operation("warm",pool[0]["position"]),boundary)
	check(not bool(first_warm["accepted"]) and str(first_warm["reason"]).contains("真实空地"),"original_first_duet_lot_rejects_warm_without_real_reserved_land")
	var started := Time.get_ticks_usec()
	var chosen := Placement.recommend(demo.model.world,pool,boundary)
	var recommendation_ms := float(Time.get_ticks_usec()-started)/1000.0
	check(chosen == pool[1] and chosen != pool[0],"recommendation_uses_first_all_voice_candidate_in_existing_order")
	check(demo.model.world.snapshot() == before and demo.model.world.rng.snapshot() == before["rng"] and demo.model.world.pending_actions == before["pending_actions"],"recommendation_preserves_actual_world_rng_and_pending")
	check(pool == pool_before and not chosen.has("expression") and not chosen.has("midi"),"recommendation_preserves_pool_and_does_not_choose_voice")
	for expression: String in PlayerExpression.IDS:
		var branch: RefCounted = demo.model.world.fork()
		check(bool(branch.request(PlayerExpression.operation(expression,chosen["position"]),boundary)["accepted"]),expression+"_independent_actual_request_is_accepted")
	var reversed_pool: Array = [pool[1],pool[0]]
	check(Placement.recommend(demo.model.world,reversed_pool,boundary) == reversed_pool[0],"existing_order_remains_authoritative_when_first_candidate_is_available")
	check(Placement.recommend(demo.model.world,[pool[0]],boundary) == pool[0],"no_common_legal_voice_lot_falls_back_to_original_candidate")
	check(Placement.recommend(demo.model.world,[],boundary).is_empty(),"empty_pool_has_no_recommendation")
	check(demo.model.world.snapshot() == before and pool == pool_before,"fallback_and_empty_queries_remain_read_only")
	var pending_city: RefCounted = demo.model.world.fork()
	var pending_request: Dictionary = pending_city.request({"kind":"charter","plan_id":"bluegreen","community_ids":["east-2"],"card_refs":[]},boundary)
	var pending_before: Dictionary = pending_city.snapshot()
	check(bool(pending_request["accepted"]) and not pending_city.pending_actions.is_empty() and Placement.recommend(pending_city,pool,boundary) == chosen and pending_city.snapshot() == pending_before,"existing_independent_pending_intent_survives_recommendation")
	var comparison := Preview.build(demo.model.freeze(),chosen["position"],demo.clock.renderer.state.duplicate(true),demo.clock.renderer.transport.rendered_frames)
	var rate := int(comparison["sample_rate"])
	var variants: Dictionary = {}
	for expression: String in PlayerExpression.IDS:
		var variant: Dictionary = comparison["variants"][expression]
		check(bool(variant["accepted"]) and variant["pcm"].size() == rate*4*4 and not variant["birth"].is_empty(),expression+"_chosen_lot_has_complete_real_four_second_preview")
		variants[expression] = {"accepted":variant["accepted"],"reason":variant["reason"],"pcm_bytes":variant["pcm"].size(),"type":variant["consequences"].get("type","")}
	var warm: Dictionary = comparison["variants"]["warm"]
	var reservations: Array = warm["consequences"].get("reservations",[])
	var reservation_id := str(warm["birth"].get("family",{}).get("expression_reservation_id",""))
	check(not reservation_id.is_empty() and int(warm["consequences"].get("reservation_count",0)) == 1 and reservations.size() == 1 and str(reservations[0]["id"]) == reservation_id and not reservations[0]["polygon"].is_empty(),"warm_preview_commits_real_reserved_parcel_owned_by_actual_family")
	check(demo.model.world.snapshot() == before,"complete_preview_keeps_source_world_unchanged")
	evidence = {"seed":demo.model.world.rng.seed_hex,"first_root":root_id,"phrase":demo.model.world.phrase_index,"boundary_frame":boundary,"pool_size":pool.size(),"original_position":pool[0]["position"],"original_warm_rejection":first_warm["reason"],"recommended_position":chosen["position"],"recommendation_ms":recommendation_ms,"variants":variants,"warm_reservation_id":reservation_id,"warm_reservations":reservations}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Dummy real two-segment production planning and request semantics; sorted pool and source World remain unchanged, with actual ExpressionPreview PCM and warm reservation. Single timing sample; no device output or human listening claim."},"\t")+"\n")
	print("ROUND205_FIRST_SOUND_PLACEMENT ",checks.size()-failures.size(),"/",checks.size()," recommendation_ms=",recommendation_ms," ",JSON.stringify(failures))
	demo._stop_preview()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
