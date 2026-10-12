extends SceneTree
## A real authored house reopens its existing menu before theme maturity or retuning.
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const OUTPUT := "res://验证记录/round201_作品接续/authored_reentry.json"
const SEED := "2026100900000062"
var checks: Dictionary = {}
var failures: Array[String] = []
var demo: Control

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _source() -> World:
	var city := World.new(SEED,true,"river_valley")
	city.build_first_composition_starter()
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	city.request({"kind":"charter","plan_id":"compact","community_ids":["west-1"],"card_refs":["infill_pulse"]},phrase)
	city.settle(phrase)
	return city

func _prepare(city: World) -> void:
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	demo.clock.active = true
	demo.first_composition_mode = true
	demo.planning_guide.reset_for_city()
	demo.first_composition_guide.reset_for_city()

func _run() -> void:
	demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	var source := _source()
	var phrase := int(source.cfg["timing"]["phrase_frames"])
	var position: Array = First.opportunities(source)["seed_candidates"][0]["position"]
	for route: String in PlayerExpression.IDS:
		var city: World = source.fork()
		var request: Dictionary = city.request(PlayerExpression.operation(route,position),phrase*2)
		check(bool(request.get("accepted",false)),route+"_actual_seed_request_accepted")
		_prepare(city)
		var entry = demo.first_composition_guide
		entry.sync()
		check(not entry.visible and demo._first_authored_state().is_empty(),route+"_pending_seed_has_no_authored_entry")
		var unheard: World = city.fork()
		city.settle(phrase*2)
		demo.shown_world = unheard
		entry.sync()
		check(not entry.visible and demo._first_authored_state().is_empty(),route+"_render_ahead_root_has_no_authored_entry")
		demo.shown_world = city
		var work: Dictionary = demo._first_authored_state()
		var root_id := str(work.get("root_id",""))
		check(not root_id.is_empty() and not bool(work.get("theme_eligible",true)) and not bool(work.get("retuned",true)),route+"_fixture_is_real_unretuned_immature_root")
		entry.sync()
		check(entry.visible and not entry.disabled and entry.action == "authored" and entry.text == "你的"+str(PlayerExpression.definition(route)["label"])+" · 改音与继续",route+"_initial_root_has_direct_authored_entry")
		var before: Dictionary = city.snapshot()
		entry.emit_signal("pressed")
		check(demo.menu.visible and demo.selected_id == root_id and demo.context.get("kind","") == "retune" and not entry.visible,route+"_entry_opens_actual_root_menu")
		check((demo.menu.get_meta("notes") as Control).visible and (demo.menu.get_meta("compose_more") as Control).visible and city.snapshot() == before,route+"_existing_notes_and_next_composition_need_no_retune_or_world_change")
		entry.sync()
		check(not entry.visible,route+"_root_menu_has_priority_over_light_entry")
		(demo.menu.get_meta("compose_more") as Button).emit_signal("pressed")
		check(demo.planning_guide.opened and demo.planning_guide.stage == "charter" and demo.planning_guide.scope.is_empty() and city.snapshot() == before,route+"_player_can_start_next_composition_without_retuning")
		if route == "warm":
			check(not str(work.get("reservation_id","")).is_empty() and not city.planning_reservations.is_empty(),"warm_real_reservation_does_not_divert_entry_from_authored_house")
		# The new house can also be the latest real family result. The root
		# remains the stable re-entry target throughout automatic growth.
		city.request({"kind":"civic","position":First.opportunities(city)["public_candidates"][0]["position"]},phrase*3)
		while city.phrase_index < 5: city.settle((city.phrase_index+1)*phrase)
		_prepare(city)
		entry.sync()
		work = demo._first_authored_state()
		check(str(work.get("root_id","")) == root_id and int(work.get("family_houses",0)) > 1 and bool(work.get("theme_eligible",false)) and not bool(work.get("root_heard_retune",true)) and entry.action == "authored",route+"_mature_unretuned_family_growth_keeps_same_root_entry")
		entry.emit_signal("pressed")
		check(demo.menu.visible and demo.selected_id == root_id and (demo.menu.get_meta("compose_more") as Control).visible,route+"_mature_entry_keeps_actual_root_and_optional_next_composition")
		# The presentation can change between sync and a click. Never substitute
		# an unrelated/future house for the label the player just chose.
		demo.menu.hide()
		entry.sync()
		demo.shown_world = source
		demo.context.clear()
		demo.selected_id = ""
		entry.emit_signal("pressed")
		check(not demo.menu.visible and demo.selected_id.is_empty() and not entry.visible,route+"_disappeared_root_is_not_reopened_or_replaced")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Dummy production UI over real seeded and naturally matured Worlds. Controlled presentation proves no render-ahead claim and direct root/menu/next-composition re-entry; no physical audio, screenshot or human-fun claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND201_AUTHORED_REENTRY ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo.clock.active = false
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
