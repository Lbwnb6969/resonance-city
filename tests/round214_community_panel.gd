extends SceneTree
## Real World content and native UI input/layout; no Demo or audio device.
const Workbench = preload("res://scripts/ui/community_workbench.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const OUTPUT := "res://验证记录/round215_古典联合屋顶/optional_panel_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var requests: Array[Dictionary] = []
var layouts: Array[Dictionary] = []

class HeardModel extends RefCounted:
	var pitches: Dictionary = {}
	var score := {"listener_community":"","focused_community":"","muted_communities":{}}
	func audible_pitches() -> Dictionary: return pitches
	func audible_score() -> Dictionary: return score

class Fixture extends Control:
	var shown_world: RefCounted
	var black := false
	var community_listening_owned := false
	var clock := {"renderer":{"transport":{"audible_frame":0}}}
	var model := HeardModel.new()

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _request(value: String,kind: String) -> void:
	requests.append({"kind":kind,"value":value})

func _mouse(at: Vector2,down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	Input.parse_input_event(event)

func _click(button: Button) -> void:
	_mouse(button.get_global_rect().get_center(),true)
	await process_frame
	_mouse(button.get_global_rect().get_center(),false)
	await process_frame

func _settle_layout(panel: PanelContainer) -> void:
	for step in range(4):
		panel.sync()
		await process_frame

func _layout(panel: PanelContainer,fixture: Control) -> bool:
	var rectangle := panel.get_global_rect()
	var window := Rect2(Vector2.ZERO,fixture.size)
	var usable := Rect2(Vector2(0,76),Vector2(fixture.size.x,fixture.size.y-76))
	var valid: bool = rectangle.size.x == 356.0 and rectangle.size.y <= fixture.size.y-100.0 and rectangle.position == Vector2(fixture.size.x-368.0,76) and window.encloses(rectangle) and usable.encloses(rectangle)
	var shaped: Array[Dictionary] = []
	for label: Label in [panel.title_label,panel.summary_label,panel.status_label,panel.pitch_label]:
		var font_size := label.get_theme_font_size("font_size")
		valid = valid and font_size >= 14 and label.get_minimum_size().y <= label.size.y+0.01 and label.get_line_count() == label.get_visible_line_count()
		shaped.append({"text":label.text,"font_pixels":font_size,"rect":label.get_global_rect(),"minimum":label.get_minimum_size(),"lines":label.get_line_count(),"visible_lines":label.get_visible_line_count()})
	for button: Button in [panel.planning_button,panel.listen_button,panel.all_city_button,panel.close_button]:
		valid = valid and rectangle.encloses(button.get_global_rect()) and button.focus_mode == Control.FOCUS_ALL
		var font: Font = button.get_theme_font("font")
		valid = valid and font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x+28.0 <= button.size.x+0.01
	layouts.append({"window":fixture.size,"panel":rectangle,"scroll":panel.scroll.get_global_rect(),"body_minimum":panel.body.get_combined_minimum_size(),"labels":shaped,"planning_rect":panel.planning_button.get_global_rect(),"listening_rect":panel.listen_button.get_global_rect(),"all_city_rect":panel.all_city_button.get_global_rect()})
	return valid

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_only_without_demo_gpu_or_device_playback")
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	root.size = Vector2i(800,600)
	var fixture := Fixture.new()
	fixture.size = Vector2(800,600)
	fixture.shown_world = city
	root.add_child(fixture)
	var panel := Workbench.new()
	panel.setup(fixture)
	fixture.add_child(panel)
	panel.listen_requested.connect(_request.bind("listen"))
	panel.planning_requested.connect(_request.bind("planning"))
	panel.author_requested.connect(_request.bind("author"))
	panel.closed.connect(func() -> void: requests.append({"kind":"closed","value":""}))
	var before := city.snapshot()
	panel.open_community("west-2")
	await _settle_layout(panel)
	var community_ids: Array[String] = []
	for button: Button in panel.community_rows.get_children(): community_ids.append(str(button.get_meta("community_id")))
	check(panel.opened and panel.state["count"] == 8 and panel.summary_label.text == "8栋 · 住宅7 / 商业1" and panel.pitch_chart.total_count == 8 and panel.state["midi_counts"] == {52:8} and community_ids == ["east-2","west-1","west-2"] and panel.author_rows.get_child_count() == 0 and requests.is_empty() and city.snapshot() == before,"opening_reads_only_three_actual_eight_house_communities_and_current_heard_pitch_without_an_author_or_auto_action")
	var native_fit := _layout(panel,fixture)
	fixture.size = Vector2(1440,900)
	root.size = Vector2i(1440,900)
	await _settle_layout(panel)
	native_fit = _layout(panel,fixture) and native_fit
	check(native_fit,"native_356px_workbench_fits_800x600_and_1440x900_with_complete_14px_body_and_fixed_actions")
	await _click(panel.planning_button)
	await _click(panel.listen_button)
	fixture.model.score["listener_community"] = "west-2"
	panel.sync()
	await process_frame
	var actual_listening: bool = panel.listen_button.disabled and panel.listen_button.text == "正在听这一带" and not panel.all_city_button.disabled
	await _click(panel.all_city_button)
	check(requests == [{"kind":"planning","value":"west-2"},{"kind":"listen","value":"west-2"},{"kind":"listen","value":""}] and actual_listening and city.snapshot() == before,"native_fixed_actions_emit_only_the_selected_cid_and_empty_full_city_request_with_audible_listening_truth")
	fixture.model.score["listener_community"] = ""
	await _click(panel.community_rows.get_child(0))
	await _settle_layout(panel)
	check(panel.community_id == "east-2" and panel.state["id"] == "east-2" and panel.state["count"] == 8 and panel.state["midi_counts"] == {55:8} and requests.size() == 3 and city.snapshot() == before,"switching_an_actual_nonempty_community_only_updates_its_read_only_workbench")
	var frame := int(city.cfg["timing"]["phrase_frames"])
	var candidate: Array = First.opportunities(city)["seed_candidates"][0]["position"]
	var first := city.request(PlayerExpression.operation("deep",candidate),frame)
	city.settle(frame)
	var second_candidate: Array = First.opportunities(city)["seed_candidates"][0]["position"]
	var second := city.request(PlayerExpression.operation("weave",second_candidate),2*frame)
	city.settle(2*frame)
	fixture.clock.renderer.transport.audible_frame = 2*frame
	panel.open_community("west-1")
	await _settle_layout(panel)
	var author_before := city.snapshot()
	var roots: Array[String] = []
	for author: Dictionary in panel.state["authors"]: roots.append(str(author["root_id"]))
	var author_hits := true
	for button: Button in panel.author_rows.get_children():
		var expected := str(button.get_meta("author_root_id"))
		panel.scroll.ensure_control_visible(button)
		await process_frame
		await _click(button)
		author_hits = author_hits and requests[-1] == {"kind":"author","value":expected} and roots.has(expected)
	check(bool(first.get("accepted",false)) and bool(second.get("accepted",false)) and roots.size() == 2 and roots[0] != roots[1] and panel.author_rows.get_child_count() == 2 and author_hits and city.snapshot() == author_before,"every_actual_authored_root_has_its_own_native_scrollable_change_pitch_button_instead_of_a_latest_root_alias")
	var old_chart_count: int = panel.pitch_chart.total_count
	fixture.model.pitches[roots[0]] = 50
	panel.sync()
	await process_frame
	check(panel.state["authors"][0]["current_midi"] == 50 and panel.author_rows.get_child(0).text.contains("D3") and panel.pitch_chart.total_count == old_chart_count and city.snapshot() == author_before,"audible_pitch_override_updates_the_true_note_and_histogram_without_changing_world_members_or_sound")
	fixture.size = Vector2(800,600)
	root.size = Vector2i(800,600)
	await _settle_layout(panel)
	var content_scrolls: bool = panel.author_rows.get_child_count() == 2 and _layout(panel,fixture) and panel.get_global_rect().encloses(panel.planning_button.get_global_rect()) and panel.get_global_rect().encloses(panel.listen_button.get_global_rect()) and (not panel.scroll.get_v_scroll_bar().visible or panel.scroll.get_v_scroll_bar().size.y <= panel.scroll.size.y)
	check(content_scrolls,"real_author_rows_stay_inside_the_scroll_region_while_the_planning_and_listening_actions_remain_visible")
	var close_count := requests.size()
	await _click(panel.close_button)
	panel.close_tool()
	check(not panel.opened and not panel.visible and panel.state.is_empty() and requests.size() == close_count+1 and requests[-1]["kind"] == "closed" and city.snapshot() == author_before,"closing_emits_once_and_preserves_existing_works_without_a_listen_or_world_write")
	panel.open_community("west-3")
	check(not panel.opened and panel.state.is_empty() and not panel.visible,"an_empty_actual_community_cannot_open_a_fake_workbench")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"layouts":layouts,"author_roots":roots,"requests":requests},"scope":"Dummy native 356px workbench over production 24-house World and two actual seed settlements. Read-only UI content, fixed actions, native clicks, actual root identity and audible pitch override; Root owns production listening commits, camera, GPU and human experience."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND215_OPTIONAL_PANEL ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
