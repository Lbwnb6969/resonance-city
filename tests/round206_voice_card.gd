extends SceneTree
## Native Button behaviour and genuine catalogue thumbnails in a narrow menu.
const VoiceCard = preload("res://scripts/ui/city_voice_card.gd")
const Catalog = preload("res://scripts/visual/building_variant_catalog.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const OUTPUT := "res://验证记录/round206_精细声音卡/voice_card.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class CardOwner extends Control:
	var building_catalog := Catalog.new()

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _key_space(down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = down
	Input.parse_input_event(event)

func _run() -> void:
	root.size = Vector2i(800,600)
	check(AudioServer.get_driver_name() == "Dummy","dummy_audio_only")
	var owner := CardOwner.new()
	root.add_child(owner)
	owner.building_catalog.load_catalog()
	var column := VBoxContainer.new()
	column.position = Vector2(24,20)
	column.size = Vector2(392,310)
	column.add_theme_constant_override("separation",8)
	owner.add_child(column)
	var cards: Array[Button] = []
	var entry_ids: Array[String] = []
	var thumbnail_paths: Array[String] = []
	var evidence: Dictionary = {}
	for route: Dictionary in PlayerExpression.catalogue():
		var unchanged := route.duplicate(true)
		var card := VoiceCard.new()
		card.setup(route,owner)
		column.add_child(card)
		cards.append(card)
		var id := str(route["id"])
		var expected: Dictionary = owner.building_catalog.preview_entry(id)
		entry_ids.append(str(card.thumbnail_entry["id"]))
		thumbnail_paths.append(str(card.thumbnail_entry["texture"]))
		check(card.thumbnail_entry == expected and card.thumbnail == owner.building_catalog.texture_for(expected) and card.thumbnail.get_width() > 0 and card.thumbnail.get_height() > 0,id+"_thumbnail_is_the_actual_route_catalogue_texture")
		check(str(card.thumbnail_entry["category"]) == str(route["type"]),id+"_thumbnail_preserves_real_residential_or_commercial_use")
		check(route == unchanged and card.text == route["label"] and card.toggle_mode and card.focus_mode == Control.FOCUS_ALL and card.tooltip_text.contains(route["city"]),id+"_native_label_toggle_focus_tooltip_and_route_data_survive_setup")
	await process_frame
	await process_frame
	var column_bounds := Rect2(column.global_position,Vector2(392,310))
	for card in cards:
		check(column_bounds.encloses(card.get_global_rect()) and card.size.y >= 84.0 and card.size.y <= 100.0,str(card.choice_id)+"_full_card_fits_the_compact_menu")
		evidence[str(card.choice_id)] = {"entry":card.thumbnail_entry["id"],"texture":card.thumbnail_entry["texture"],"rect":card.get_global_rect()}
	check(entry_ids[0] != entry_ids[1] and entry_ids[1] != entry_ids[2] and entry_ids[0] != entry_ids[2] and thumbnail_paths[0] != thumbnail_paths[1] and thumbnail_paths[1] != thumbnail_paths[2],"all_three_routes_have_distinct_real_building_thumbnails")
	var warm = cards[2]
	var activations := [0]
	warm.pressed.connect(func() -> void: activations[0] += 1)
	warm.grab_focus()
	_key_space(true)
	await process_frame
	_key_space(false)
	await process_frame
	check(activations[0] == 1 and warm.button_pressed and warm.has_focus() and warm.status_text().begins_with("已选"),"native_keyboard_activation_selects_and_keeps_focus")
	warm.set_listening(true)
	await process_frame
	check(warm.listening and warm.status_text().begins_with("正在试听") and warm.is_processing(),"listening_state_is_visible_and_animates_only_while_playing")
	warm.set_listening(false)
	check(not warm.is_processing() and warm.status_text().begins_with("已选"),"ended_preview_returns_to_the_selected_card_without_an_idle_animation")
	warm.disabled = true
	_key_space(true)
	await process_frame
	_key_space(false)
	await process_frame
	check(activations[0] == 1 and warm.disabled,"native_disabled_card_does_not_activate")
	warm.disabled = false
	warm.set_pressed_no_signal(false)
	check(activations[0] == 1 and warm.status_text() == "点击试听 · 4秒","silent_selection_updates_preserve_button_api_and_idle_status")
	column.size.x = 250
	await process_frame
	await process_frame
	var narrow_bounds := Rect2(column.global_position,Vector2(250,310))
	for card in cards:
		check(narrow_bounds.encloses(card.get_global_rect()),str(card.choice_id)+"_card_shrinks_for_a_small_window")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"routes":evidence,
		"scope":"Dummy standalone production Button cards using current real catalogue route textures. Covers native keyboard activation, toggle/focus/disabled behaviour, 94px rows in 392px and 250px columns, distinct real building uses and local listening status. No physical device, World mutation or human art-quality claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND206_VOICE_CARD ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	owner.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
