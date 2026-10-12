extends RefCounted
## The transient guide owns its keys while it is visible. Native Tab remains
## available; city solo and landmark confirmation must not steal that input.

static func route(demo: Control,event: InputEventKey) -> bool:
	var guide: Control = demo.planning_guide
	if guide == null or not guide.opened or not guide.visible or demo.black: return false
	if event.keycode == KEY_TAB:
		if demo.partial_polygon_mode and demo.partial_multi_component_mode: return false
		return true
	if event.keycode == KEY_SPACE:
		if not event.echo and guide.stage in ["anchor","partial_anchor","reuse_anchor","transit_anchor","transit_edit"]: return false
		demo.get_viewport().set_input_as_handled()
		return true
	if event.keycode not in [KEY_ENTER,KEY_KP_ENTER]: return false
	if guide.stage not in ["charter","card","scope","anchor","feedback"]: return false
	demo.get_viewport().set_input_as_handled()
	if not event.pressed or event.echo: return true
	match guide.stage:
		"charter", "card":
			focus_stage(guide)
			var button := _focused_button(guide)
			if button != null: button.pressed.emit()
		"scope":
			var button := _focused_button(guide)
			if button != null and button != guide.confirm: button.pressed.emit()
			elif guide.scope.is_empty(): demo._message("先选一个社区，再确认范围")
			else: guide.commit_scope()
		"anchor":
			var button := _focused_button(guide)
			if button != null and not button.has_meta("anchor_kind"):
				button.pressed.emit()
			elif button != null and str(button.get_meta("anchor_kind")) != str(guide.anchor_kind):
				button.pressed.emit()
			else:
				guide.map_click(demo.world_at(demo.pointer),false)
		"feedback":
			var button := _focused_button(guide)
			if button != null and button != guide.next_action_button: button.pressed.emit()
			elif guide.next_action.get("state","") == "ready": guide._take_next_action()
	return true

## Call once after a stage/layout change. A still-visible native focus is kept
## so hovering the map or refreshing a forecast never resets keyboard choice.
static func focus_stage(guide: Control) -> void:
	if not guide.opened or not guide.visible: return
	if _focused_button(guide) != null: return
	var button: Button
	match guide.stage:
		"charter": button = _choice_button(guide.cards,str(guide.plan_id))
		"card": button = _choice_button(guide.card_choices,str(guide.card_id))
		"scope":
			if not guide.confirm.disabled: button = guide.confirm
		"anchor":
			for raw in guide.actions.get_children():
				if raw is Button and raw.visible and not raw.disabled and raw.has_meta("anchor_kind") and str(raw.get_meta("anchor_kind")) == str(guide.anchor_kind):
					button = raw
					break
		"feedback":
			if guide.next_action.get("state","") == "ready": button = guide.next_action_button
	if button != null: button.grab_focus()

static func _focused_button(guide: Control) -> Button:
	var control := guide.get_viewport().gui_get_focus_owner()
	if control is Button and guide.is_ancestor_of(control) and control.is_visible_in_tree() and not control.disabled:
		return control
	return null

static func _first_button(container: Control) -> Button:
	for raw in container.get_children():
		if raw is Button and raw.is_visible_in_tree() and not raw.disabled: return raw
	return null

static func _choice_button(container: Control,id: String) -> Button:
	for raw in container.get_children():
		if raw is Button and raw.is_visible_in_tree() and not raw.disabled and str(raw.get_meta("planning_choice_id","")) == id: return raw
	return _first_button(container)
