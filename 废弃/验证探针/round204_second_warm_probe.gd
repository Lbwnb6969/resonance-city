extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Preview = preload("res://scripts/world/expression_preview.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Duet = preload("res://scripts/world/authored_duet.gd")
const OUTPUT := "res://验证记录/round204_点击即试听/second_warm_probe.json"
var demo: ContinuousValleyDemo
var report: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

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

func _variants(comparison: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for choice: String in PlayerExpression.IDS:
		var variant: Dictionary = comparison["variants"][choice]
		result[choice] = {"accepted":variant["accepted"],"reason":variant["reason"],"pcm_bytes":variant["pcm"].size(),"operation":variant["operation"],"consequences":variant["consequences"]}
	return result

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
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
	report["first_charter"] = demo.model.world.pending_actions.duplicate(true)
	_advance(int(guide.next_action["expected_boundary_frame"])+rate/5)
	guide.next_action_button.emit_signal("pressed")
	report["first_sound_context"] = demo.context.duplicate(true)
	demo.expression_choices["warm"].emit_signal("pressed")
	demo.expression_confirm.emit_signal("pressed")
	var first_boundary := demo.model.next_boundary
	_advance(first_boundary+rate/4)
	var root_id := str(demo._first_authored_state()["root_id"])
	report["first_root"] = demo._first_authored_state().duplicate(true)
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
	report["second_public_context"] = site.duplicate(true)
	report["second_pending"] = demo.model.world.pending_actions.duplicate(true)
	_advance(int(guide.next_action["expected_boundary_frame"])+rate/5)
	guide.next_action_button.emit_signal("pressed")
	report["second_sound_context"] = demo.context.duplicate(true)
	report["duet_candidates"] = Duet.candidates(demo.shown_world,root_id,"east-2",-1)
	var alternatives: Array[Dictionary] = []
	for candidate: Dictionary in report["duet_candidates"]:
		var warm_branch := demo.model.freeze()
		var alternative_request := warm_branch.submit(PlayerExpression.operation("warm",candidate["position"]))
		alternatives.append({"position":candidate["position"],"accepted":alternative_request["accepted"],"reason":alternative_request.get("reason","")})
	report["warm_duet_alternatives"] = alternatives
	var at := demo.clock.renderer.transport.rendered_frames
	var comparison := Preview.build(demo.model.freeze(),demo.context["position"],demo.clock.renderer.state.duplicate(true),at)
	report["phrase"] = demo.model.world.phrase_index
	report["source_frame"] = at
	report["variants"] = _variants(comparison)
	for alternative: Dictionary in alternatives:
		if not bool(alternative["accepted"]): continue
		var alternate_comparison := Preview.build(demo.model.freeze(),alternative["position"],demo.clock.renderer.state.duplicate(true),at)
		report["warm_accepted_alternative_preview"] = {"position":alternative["position"],"variants":_variants(alternate_comparison)}
		break
	var branch := demo.model.freeze()
	var phases := demo.clock.renderer.state.duplicate(true)
	var warm_request := branch.submit(PlayerExpression.operation("warm",demo.context["position"]))
	report["warm_request"] = warm_request
	report["warm_requested_reservation"] = branch.world.pending_actions.duplicate(true)
	if bool(warm_request.get("accepted",false)):
		for begin in range(at,int(comparison["boundary_frame"])+rate*4,4096):
			branch.render_block(phases,begin,mini(4096,int(comparison["boundary_frame"])+rate*4-begin),rate)
		report["warm_after_events"] = branch.world.events.filter(func(event: Dictionary) -> bool: return int(event.get("event_id",-1)) == int(warm_request["event_id"]) or str(event.get("kind","")) == "planning_rejected")
		report["warm_after_roots"] = Duet.roots(branch.world)
	report["scope"] = "Dummy production planning: compact west-2, no public build, first warm root, bluegreen east-2 civic, actual AuthoredDuet sound candidate and ExpressionPreview."
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("SECOND_WARM_PROBE ",JSON.stringify(report["variants"])," request=",JSON.stringify(warm_request)," events=",JSON.stringify(report.get("warm_after_events",[])))
	demo._stop_preview()
	demo.queue_free()
	await process_frame
	quit()
