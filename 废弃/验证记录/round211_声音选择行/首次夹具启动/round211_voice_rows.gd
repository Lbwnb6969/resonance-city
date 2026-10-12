extends SceneTree
## Compact row geometry and native input, with actual current route textures.
const Card = preload("res://scripts/ui/city_voice_card.gd")
const Catalog = preload("res://scripts/visual/building_variant_catalog.gd")
const Expression = preload("res://scripts/world/player_expression.gd")
const Ui = preload("res://scripts/ui/valley_ui_theme.gd")
const OUTPUT := "res://验证记录/round211_声音选择行/card_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var cards: Array = []
var activations := 0

class CardOwner extends Control:
	var building_catalog := Catalog.new()

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _select_choice(id: String) -> void:
	activations += 1
	for card in cards: card.set_pressed_no_signal(str(card.choice_id) == id)

func _key_space(down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = down
	Input.parse_input_event(event)

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_only_without_a_scene_audio_device_or_world")
	root.size = Vector2i(800,600)
	var owner := CardOwner.new()
	owner.theme = Ui.make_theme()
	root.add_child(owner)
	owner.building_catalog.load_catalog()
	var catalog_hash := FileAccess.get_sha256(Catalog.REFINED_MANIFEST)
	var column := VBoxContainer.new()
	column.position = Vector2(20,20)
	column.size = Vector2(312,240)
	column.add_theme_constant_override("separation",6)
	owner.add_child(column)
	var routes := Expression.catalogue()
	var untouched := routes.duplicate(true)
	var setup_ok := true
	var image_ids: Array[String] = []
	for route: Dictionary in routes:
		var card := Card.new()
		card.setup(route,owner)
		column.add_child(card)
		card.pressed.connect(_select_choice.bind(str(route["id"])))
		cards.append(card)
		var expected: Dictionary = owner.building_catalog.preview_entry(route["id"])
		image_ids.append(str(expected["id"]))
		setup_ok = setup_ok and card.choice == route and card.text == route["label"] and card.tooltip_text.contains(route["city"]) and card.toggle_mode and card.focus_mode == Control.FOCUS_ALL and card.thumbnail_entry == expected and card.thumbnail == owner.building_catalog.texture_for(expected) and expected["category"] == route["type"] and not card.is_processing()
	check(setup_ok and image_ids.size() == 3 and image_ids[0] != image_ids[1] and image_ids[1] != image_ids[2] and image_ids[0] != image_ids[2],"three_native_buttons_preserve_real_route_labels_types_and_distinct_actual_thumbnail_textures")
	var evidence: Array[Dictionary] = []
	for width: int in [312,330]:
		column.size.x = width
		await process_frame
		await process_frame
		var fits := true
		for card in cards:
			var rect: Rect2 = card.get_global_rect()
			var local := Rect2(Vector2.ZERO,card.size)
			var layout: Dictionary = card.content_layout()
			var font: Font = card.get_theme_font("font")
			for part: String in ["thumbnail","motif","title","use","sound","state"]: fits = fits and local.encloses(layout[part])
			var title: Rect2 = layout["title"]
			var use: Rect2 = layout["use"]
			var sound: Rect2 = layout["sound"]
			var state: Rect2 = layout["state"]
			fits = fits and not title.intersects(use) and not use.intersects(state) and not sound.intersects(title) and not sound.intersects(use) and not sound.intersects(state)
			var sound_size := font.get_string_size(str(card.choice["sound"]),HORIZONTAL_ALIGNMENT_LEFT,-1,Card.SOUND_SIZE)
			fits = fits and sound_size.x <= sound.size.x and sound_size.y <= sound.size.y and font.get_string_size("试听",HORIZONTAL_ALIGNMENT_LEFT,-1,12).x <= state.size.x and card.size.y == 76.0 and card.size.x == float(width) and Rect2(column.global_position,Vector2(width,240)).encloses(rect)
			evidence.append({"route":card.choice_id,"width":width,"rect":rect,"sound_pixels":sound_size,"sound_available":sound.size,"title_font_pixels":Card.TITLE_SIZE,"sound_font_pixels":Card.SOUND_SIZE,"use_font_pixels":Card.USE_SIZE,"thumbnail":card.thumbnail_entry["id"],"motif_onsets":card.choice["theme_steps"]})
		check(fits,"three_76px_rows_fit_"+str(width)+"px_with_complete_native_font_sound_labels_and_nonoverlapping_parts")
	var hierarchy_ok := true
	for card in cards:
		var normal: StyleBoxFlat = card.get_theme_stylebox("normal")
		var pressed: StyleBoxFlat = card.get_theme_stylebox("pressed")
		var focus: StyleBoxFlat = card.get_theme_stylebox("focus")
		hierarchy_ok = hierarchy_ok and normal.bg_color.a == 0.0 and normal.border_width_left == 0 and normal.border_width_right == 0 and pressed.bg_color == Card.PINE and pressed.border_width_left == 0 and focus.border_width_left == 1
	check(hierarchy_ok,"unselected_rows_have_no_white_panel_frame_and_selection_alone_has_a_pine_surface_with_native_focus")
	var warm = cards[2]
	warm.grab_focus()
	_key_space(true)
	await process_frame
	_key_space(false)
	await process_frame
	check(activations == 1 and warm.button_pressed and warm.has_focus() and not cards[0].button_pressed and not cards[1].button_pressed and warm.status_text() == "已选","native_space_pressed_signal_allows_the_owner_to_keep_exactly_one_selected_row")
	warm.set_listening(true)
	await process_frame
	var listening_ok: bool = warm.listening and warm.status_text() == "正在试听" and not warm.is_processing()
	warm.set_listening(false)
	check(listening_ok and not warm.listening and warm.status_text() == "已选" and not warm.is_processing(),"real_listening_flag_shows_a_static_short_state_then_restores_selection_without_a_fake_amplitude_animation")
	warm.disabled = true
	_key_space(true)
	await process_frame
	_key_space(false)
	await process_frame
	check(activations == 1,"native_disabled_row_does_not_activate_or_emit_a_new_selection")
	warm.disabled = false
	var actual: Dictionary = owner.building_catalog.preview_entry("warm",3)
	warm.set_building_entry(actual,owner)
	check(warm.thumbnail_entry == actual and warm.thumbnail == owner.building_catalog.texture_for(actual) and warm.choice == routes[2] and warm.button_pressed,"existing_street_orientation_update_replaces_only_the_real_thumbnail_and_preserves_choice_and_toggle")
	check(routes == untouched and FileAccess.get_sha256(Catalog.REFINED_MANIFEST) == catalog_hash,"layout_keyboard_and_texture_updates_keep_all_route_and_asset_data_read_only")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"rows":evidence,"scope":"Dummy standalone native Button rows under the production UI theme, actual current route textures and orientation update. 312/330px complete text and 76px height, selected hierarchy, keyboard/disabled/listening API, no World/PCM mutation. Root owns narrow 356px production panel and real audio/footer/compositing review. No human aesthetic conclusion."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND211_VOICE_ROWS ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	owner.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
