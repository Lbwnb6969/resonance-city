extends SceneTree
## Native planning rows: current content, shaped text and actual input only.
const Card = preload("res://scripts/ui/planning_direction_card.gd")
const Charter = preload("res://scripts/world/development_charter.gd")
const PlanningCard = preload("res://scripts/world/planning_card.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const Ui = preload("res://scripts/ui/valley_ui_theme.gd")
const OUTPUT := "res://验证记录/round213_规划选择行/rows_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var activations: Array[String] = []
var evidence: Array[Dictionary] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _activated(id: String) -> void: activations.append(id)

func _mouse(at: Vector2,down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	Input.parse_input_event(event)

func _space(down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = down
	Input.parse_input_event(event)

func _card(id: String,spec: Dictionary,variation: bool,column: VBoxContainer) -> Button:
	var card := Card.new()
	card.setup(id,spec,variation)
	card.pressed.connect(_activated.bind(id))
	column.add_child(card)
	return card

func _fits(card: Button,width: int) -> bool:
	var valid := card.size.x == float(width) and card.size.y >= 104.0 and card.size.y <= 116.0
	var local := Rect2(Vector2.ZERO,card.size)
	var labels: Array[Label] = [card.title_label,card.tendency_label,card.tradeoff_label]
	if card.is_variation: labels.append(card.duration_label)
	var shaped: Array[Dictionary] = []
	for label: Label in labels:
		var font: Font = label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		var required := label.get_minimum_size()
		valid = valid and font_size >= 14 and local.encloses(label.get_rect()) and required.y <= label.size.y+0.01 and label.get_line_count() == label.get_visible_line_count() and label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING and label.mouse_filter == Control.MOUSE_FILTER_IGNORE
		if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			valid = valid and font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x <= label.size.x+0.01
		shaped.append({"text":label.text,"font_pixels":font_size,"rect":label.get_rect(),"minimum":required,"lines":label.get_line_count(),"visible_lines":label.get_visible_line_count()})
	for i in range(labels.size()):
		for j in range(i+1,labels.size()): valid = valid and not labels[i].get_rect().intersects(labels[j].get_rect())
	evidence.append({"id":card.choice_id,"variation":card.is_variation,"width":width,"row":card.get_global_rect(),"shaped_text":shaped})
	return valid

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_without_production_scene_or_audio_device")
	root.size = Vector2i(800,600)
	var holder := Control.new()
	holder.theme = Ui.make_theme()
	root.add_child(holder)
	var column := VBoxContainer.new()
	column.position = Vector2(20,20)
	column.add_theme_constant_override("separation",6)
	holder.add_child(column)
	var original_plans := Charter.PLANS.duplicate(true)
	var original_variations := PlanningCard.CARDS.duplicate(true)
	var plans: Array[Button] = []
	for id: String in ["compact","corridor","bluegreen"]: plans.append(_card(id,Charter.PLANS[id],false,column))
	column.size = Vector2(324,360)
	await process_frame
	await process_frame
	var actual_content := activations.is_empty()
	for card: Button in plans:
		var spec: Dictionary = Charter.PLANS[card.choice_id]
		actual_content = actual_content and card.text == spec["title"] and card.title_label.text == spec["title"] and card.tendency_label.text == spec["tendency"] and card.tradeoff_label.text == "取舍 · "+str(spec["tradeoff"]) and not card.duration_label.visible and not card.button_pressed and card.focus_mode == Control.FOCUS_ALL
	check(actual_content and plans[0].direction != plans[1].direction and plans[1].direction != plans[2].direction and plans[0].direction != plans[2].direction,"three_distinct_native_directions_keep_actual_titles_tendencies_tradeoffs_without_an_automatic_charter")
	var plans_fit := true
	for width: int in [312,324]:
		column.size = Vector2(width,360)
		await process_frame
		await process_frame
		for card: Button in plans: plans_fit = _fits(card,width) and plans_fit
	check(plans_fit and column.get_child_count() == 3 and column.get_minimum_size().y <= 360,"three_charters_fit_312_and_324px_with_complete_native_14px_body_and_readable_116px_rows")
	column.size = Vector2(324,360)
	await process_frame
	var clicks_ok := true
	for card: Button in plans:
		# Both title and tradeoff child regions must hit the native full row.
		for label: Label in [card.title_label,card.tradeoff_label]:
			var count := activations.size()
			var at := label.get_global_rect().get_center()
			_mouse(at,true)
			await process_frame
			_mouse(at,false)
			await process_frame
			clicks_ok = clicks_ok and activations.size() == count+1 and activations.back() == card.choice_id
	check(clicks_ok,"title_and_wrapped_tradeoff_regions_click_their_actual_native_row_once")
	var key_count := activations.size()
	plans[1].grab_focus()
	_space(true)
	await process_frame
	_space(false)
	await process_frame
	var key_ok: bool = activations.size() == key_count+1 and activations.back() == "corridor"
	plans[1].disabled = true
	_space(true)
	await process_frame
	_space(false)
	await process_frame
	check(key_ok and activations.size() == key_count+1,"native_keyboard_focus_activates_the_real_direction_and_disabled_rows_do_not_activate")
	for card: Button in plans: card.free()
	var variations: Array[Button] = []
	for id: String in PlanningCard.CARDS: variations.append(_card(id,PlanningCard.CARDS[id],true,column))
	var variations_fit := true
	var variations_content := true
	for width: int in [312,324]:
		column.size = Vector2(width,360)
		await process_frame
		await process_frame
		for card: Button in variations:
			variations_fit = _fits(card,width) and variations_fit
			var spec: Dictionary = PlanningCard.CARDS[card.choice_id]
			variations_content = variations_content and card.title_label.text == spec["title"] and card.tendency_label.text == spec["tendency"] and card.tradeoff_label.text == "取舍 · "+str(spec["tradeoff"]) and card.duration_label.text == "%d句" % int(spec["duration_phrases"]) and card.duration_label.visible
	check(variations_fit and variations_content,"all_current_variations_show_complete_real_tendency_tradeoff_and_3_or_4_phrase_duration_at_narrow_widths")
	for card: Button in variations: card.free()
	var world := World.new("2026100900000062",false,"river_valley")
	var draws: Dictionary = {}
	for phrase in range(24):
		world.phrase_index = phrase
		for plan_id: String in Charter.PLANS:
			var ids := PlanningCard.choices(world,plan_id)
			if not draws.has(ids.size()): draws[ids.size()] = ids
	var draws_ok := draws.has(2) and draws.has(3)
	for count: int in draws:
		var ids: Array = draws[count]
		for id: String in ids: _card(id,PlanningCard.definition(id),true,column)
		column.size = Vector2(324,360)
		await process_frame
		await process_frame
		draws_ok = draws_ok and column.get_child_count() == count
		for card: Button in column.get_children():
			draws_ok = draws_ok and ids.has(card.choice_id) and _fits(card,324)
			card.free()
	check(draws_ok,"native_column_uses_exactly_the_actual_two_or_three_drawn_variations_without_extra_cards")
	check(Charter.PLANS == original_plans and PlanningCard.CARDS == original_variations,"layout_and_native_input_preserve_planning_definitions_and_add_no_outcomes")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"rows":evidence,"actual_draws":draws,"scope":"Dummy native VBox/Button rows under production theme, current Charter/PlanningCard content, shaped complete >=14px body at 312/324px, 116px rows, actual mouse hits and keyboard/disabled behavior, real 2/3-card draws. Root owns narrow production panel/scroll/actual world placement and GPU review; no claimed player aesthetic judgement."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND213_PLANNING_ROWS ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	holder.free()
	quit(0 if failures.is_empty() else 1)
