extends SceneTree
## A currently legal route can still conflict with an earlier bridge at its real next phrase.
const World = preload("res://scripts/world/continuous_world.gd")
const OUTPUT := "res://验证记录/round179_公交同源比较/transit_comparison_rejection_ui.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _key(demo: Control,code: Key,pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	demo._input(event)

func _click_road(demo: Control,id: String) -> void:
	var p: Array = demo.model.world.nodes[id]
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = demo.point(Vector2(float(p[0]),float(p[1])))
	demo._gui_input(event)

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	var frame := (city.phrase_index+1)*int(city.cfg["timing"]["phrase_frames"])
	var original := {"kind":"transit_line","source_topology":city.network.topology,
		"stop_positions":[city.nodes["west-1"].duplicate(),city.nodes["west-2"].duplicate(),city.nodes["west-3"].duplicate()]}
	check(bool(city.request(original,frame).get("accepted",false)),"fixture_queues_real_original_line")
	city.settle(frame)
	var line_id := str(city.authored_transit_lines[0]["id"])
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	await process_frame
	var guide = demo.planning_guide
	var bridge: Dictionary = demo.model.submit({"kind":"bridge","source_topology":city.network.topology})
	check(bool(bridge.get("accepted",false)) and not city.bridge,"fixture_has_real_pending_bridge_before_same_phrase_edit")
	demo._begin_transit_edit(line_id)
	guide.transit_redraw_button.emit_signal("pressed")
	_click_road(demo,"west-1")
	_click_road(demo,"west-4")
	guide.sync()
	check(bool(demo._transit_route_preview().get("accepted",false)) and not guide.confirm.disabled,"instant_route_is_legal_before_private_boundary")
	_key(demo,KEY_SPACE)
	var started := Time.get_ticks_msec()
	while demo.preview_thread != null and Time.get_ticks_msec()-started < 60000:
		await create_timer(0.02).timeout
		demo._process(0.0)
	var packet: Dictionary = guide.transit_comparison
	var keep: Dictionary = packet.get("variants",{}).get("keep",{})
	var edit: Dictionary = packet.get("variants",{}).get("edit",{})
	var reason := str(edit.get("reason",""))
	check(guide.transit_comparison_is_current() and bool(keep.get("accepted",false)) and not bool(edit.get("accepted",true)) and reason == "同句规划冲突，改站未落定" and bool(demo._transit_route_preview().get("accepted",false)),"real_private_bridge_settlement_rejects_only_edit_despite_legal_instant_draft")
	var before: Dictionary = demo.model.capture_state()
	check(guide.transit_choice == "edit" and guide.confirm.disabled,"valid_comparison_rejection_disables_edit_confirmation")
	_key(demo,KEY_ENTER)
	check(demo.model.capture_state() == before and guide.opened and demo.notice == reason and not city.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "transit_line"),"enter_reuses_private_rejection_reason_without_requeueing_known_failed_edit")
	var music_message := str(keep.get("music_feedback",{}).get("message","")).replace("pulse_dense","密集脉冲节奏").replace("pulse","脉冲节奏")
	check(not music_message.is_empty() and guide.detail.text.contains(music_message) and not guide.detail.text.contains("pulse"),"comparison_music_conditions_use_player_facing_pulse_names")
	guide.transit_keep_button.emit_signal("pressed")
	check(not guide.confirm.disabled and demo.preview_started,"same_comparison_keep_remains_confirmable_and_audible")
	_key(demo,KEY_SPACE,false)
	before = demo.model.capture_state()
	_key(demo,KEY_ENTER)
	check(not guide.opened and demo.model.capture_state() == before and city.pending_actions.size() == 1 and str(city.pending_actions[0]["kind"]) == "bridge" and city.authored_transit_lines.size() == 1 and str(city.authored_transit_lines[0]["id"]) == line_id,"keep_preserves_original_line_and_independent_pending_bridge_without_event")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Production Guide, real pending bridge and private next-phrase worker rejection; edit confirm/Enter blocked, keep allowed. Dummy, no physical-device claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND179_TRANSIT_COMPARISON_REJECTION_UI "+JSON.stringify(report))
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
