extends SceneTree
## Small Dummy contract for real Guide APIs, native focus, and routed keys.
const Navigation = preload("res://scripts/ui/planning_keyboard_navigation.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const OUTPUT := "res://验证记录/round213_规划键盘/keyboard_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var use_button_activations := 0

class RoutedDemo extends "res://scripts/ui/continuous_valley_demo.gd":
	const Keyboard = preload("res://scripts/ui/planning_keyboard_navigation.gd")
	var comparison_requests := 0
	var component_finishes := 0
	func _input(event: InputEvent) -> void:
		if event is InputEventKey and Keyboard.route(self,event): return
		super._input(event)
	func _request_preview() -> void:
		comparison_requests += 1
	func _finish_partial_component() -> bool:
		component_finishes += 1
		return true

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func key(code: Key,down: bool,shift := false,repeat := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	event.shift_pressed = shift
	event.echo = repeat
	Input.parse_input_event(event)

func tap(code: Key,shift := false) -> void:
	key(code,true,shift)
	await process_frame
	key(code,false,shift)
	await process_frame

func _run() -> void:
	check(DisplayServer.get_name() == "headless" and AudioServer.get_driver_name() == "Dummy","dummy_only_without_gpu_or_sound_device")
	root.size = Vector2i(800,900)
	var demo := RoutedDemo.new()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var guide = demo.planning_guide
	guide.open_tool()
	await process_frame
	Navigation.focus_stage(guide)
	var before := demo.model.world.snapshot()
	var first := root.gui_get_focus_owner()
	check(first != null and guide.cards.is_ancestor_of(first),"charter_stage_starts_on_actual_native_card")
	await tap(KEY_TAB)
	var second := root.gui_get_focus_owner()
	check(second != null and second != first and guide.is_ancestor_of(second),"native_tab_moves_inside_guide")
	check(demo.model.world.snapshot() == before and demo.model.synth.listener_community.is_empty(),"tab_does_not_submit_city_solo_or_mutate_world")
	await tap(KEY_SPACE)
	check(guide.stage == "charter" and demo.model.world.snapshot() == before and not demo.preview_requested,"space_in_charter_does_not_activate_focused_card_or_prepare_pcm")
	await tap(KEY_ENTER)
	check(guide.stage == "card" and not guide.plan_id.is_empty(),"enter_activates_the_focused_real_charter")
	await process_frame
	Navigation.focus_stage(guide)
	check(guide.card_choices.is_ancestor_of(root.gui_get_focus_owner()),"change_card_stage_gets_actual_native_card_focus")
	await tap(KEY_SPACE)
	check(guide.stage == "card" and not demo.preview_requested,"space_in_change_card_does_not_choose_a_default_card")
	await tap(KEY_ENTER)
	check(guide.stage == "scope" and not guide.card_id.is_empty(),"enter_activates_real_change_card_and_advances_scope")
	var serial := demo.model.world.action_serial
	await tap(KEY_ENTER)
	check(guide.stage == "scope" and demo.model.world.action_serial == serial and demo.model.world.pending_actions.is_empty(),"enter_without_community_does_not_submit_charter_or_landmark")
	var position := Coupling.position_of(demo.model.world.buildings[0])
	guide.map_click(position,false)
	await process_frame
	root.gui_release_focus()
	Navigation.focus_stage(guide)
	check(root.gui_get_focus_owner() == guide.confirm and not guide.confirm.disabled,"selected_scope_focuses_actual_enabled_confirm")
	await tap(KEY_ENTER)
	var queued: Dictionary = demo.model.world.pending_actions.back() if not demo.model.world.pending_actions.is_empty() else {}
	check(guide.stage == "anchor" and queued.get("kind","") == "charter" and queued.get("card_refs",[]) == [guide.card_id],"enter_queues_exactly_real_charter_with_selected_change_card")
	root.gui_release_focus()
	Navigation.focus_stage(guide)
	var chosen := root.gui_get_focus_owner()
	check(chosen is Button and chosen.has_meta("anchor_kind") and str(chosen.get_meta("anchor_kind")) == str(guide.anchor_kind),"anchor_stage_focuses_current_real_use")
	var anchor_before := demo.model.world.snapshot()
	await tap(KEY_TAB)
	check(demo.model.world.snapshot() == anchor_before and demo.model.synth.listener_community.is_empty(),"tab_in_anchor_keeps_city_solo_unchanged")
	guide.choose_anchor("park")
	root.gui_release_focus()
	Navigation.focus_stage(guide)
	var use_button: Button = root.gui_get_focus_owner()
	use_button.pressed.connect(func() -> void: use_button_activations += 1)
	key(KEY_SPACE,true)
	await process_frame
	key(KEY_SPACE,true,false,true)
	await process_frame
	key(KEY_SPACE,false)
	await process_frame
	check(demo.comparison_requests == 1 and use_button_activations == 0 and guide.stage == "anchor" and demo.model.world.snapshot() == anchor_before,"space_requests_one_public_comparison_without_activating_focused_use_button")
	demo.partial_polygon_mode = true
	demo.partial_multi_component_mode = true
	var geometry_focus := root.gui_get_focus_owner()
	await tap(KEY_TAB)
	check(demo.component_finishes == 1 and root.gui_get_focus_owner() == geometry_focus and demo.model.world.snapshot() == anchor_before,"tab_keeps_existing_multi_component_geometry_finish_instead_of_native_navigation")
	demo.partial_polygon_mode = false
	demo.partial_multi_component_mode = false
	var site: Dictionary = {}
	for lot in demo.model.world.lots:
		if not str(lot.get("occupant","")).is_empty() or not guide.scope.has(str(lot.get("community_id",""))): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var candidate: Dictionary = demo.model.world.planning_candidate(p)
		if not candidate.is_empty() and bool(candidate.get("allowed",false)) and not Planning.public_access(demo.model.world,candidate).is_empty():
			site = candidate
			break
	check(not site.is_empty(),"real_selected_community_has_a_road_accessible_public_candidate")
	if not site.is_empty():
		var p := Vector2(float(site["position"][0]),float(site["position"][1]))
		demo.pointer = demo.point(p)
		guide.update_candidate(p)
		await tap(KEY_ENTER)
		check(not guide.opened and demo.model.world.pending_actions.size() == 2 and str(demo.model.world.pending_actions.back().get("kind","")) == "park","enter_on_current_use_confirms_actual_pointer_and_queues_one_public_space")
	guide.hide_tool()
	check(not Navigation.route(demo,InputEventKey.new()),"closed_guide_releases_global_input")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Dummy actual Guide/model with a minimal route adapter; native Tab/Enter/Space, real charter/public queue and card refs. The public-preview method is counted instead of rendering PCM, to isolate double-activation. Root owns production Demo integration and actual GPU/WASAPI full planning chain; no human usability verdict."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND213_PLANNING_KEYBOARD checks=",checks.size()," failures=",JSON.stringify(failures))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
