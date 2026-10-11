extends VBoxContainer
## Each button returns to a surviving player family, never a guessed motif.
const Duet = preload("res://scripts/world/authored_duet.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const MusicRules = preload("res://scripts/world/community_music_rules.gd")
var demo: Control
var version: Array = []

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	name = "AuthoredCompositionChoices"
	hide()

func sync() -> void:
	visible = demo.first_composition_mode and demo._authored_retune()
	if not visible: return
	var world: RefCounted = demo.shown_world
	var pitches: Dictionary = demo.model.audible_pitches()
	var score: Dictionary = demo.model.audible_score()
	var next: Array = [world.phrase_index,demo.selected_id,hash(pitches),str(score.get("focused_community","")),str(score.get("listener_community","")),bool(score.get("response_enabled",true))]
	if version == next:
		visible = get_child_count() > 0
		return
	version = next
	for child in get_children(): child.free()
	var roots: Array = Duet.roots(world,pitches)
	if roots.size() < 2:
		hide()
		return
	var family_id := str(world.by_id[demo.selected_id]["family_id"])
	var label := Label.new()
	label.text = "你写下的街坊 · 点一段继续改音"
	label.add_theme_font_size_override("font_size",14)
	add_child(label)
	var choices := HFlowContainer.new()
	for root: Dictionary in roots:
		var button := Button.new()
		var pitch := int(root["current_midi"])
		button.text = "%s · %s %s%d" % [root["community_name"],PlayerExpression.definition(str(root["expression"]))["label"],demo.note_name(pitch),pitch/12-1]
		button.disabled = not bool(MusicRules.status(world,str(root["community_id"]))["theme_eligible"])
		button.pressed.connect(demo._begin_authored_theme.bind(str(root["root_id"])))
		button.set_meta("root_id",str(root["root_id"]))
		button.tooltip_text = "定位这段真实根屋，保留它自己的音与街坊"
		choices.add_child(button)
	add_child(choices)
	var relations: Array = Duet.relations(world,pitches).filter(func(pair: Dictionary) -> bool:
		return str(pair["a_family_id"]) == family_id or str(pair["b_family_id"]) == family_id)
	var qualified: bool = relations.any(func(pair: Dictionary) -> bool: return bool(pair["qualified"]))
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "两岸已有协和音 · 一边唱，另一边延两拍回答" if qualified else ("两段已隔岸相望 · 选带“呼应”的音，试着让对岸接话" if not relations.is_empty() else "两段保留不同性格；沿河靠近的房屋可以继续组合应答")
	if not bool(score.get("response_enabled",true)): hint.text += "\n应答当前关闭 · 原跨河应答按钮可开启"
	hint.add_theme_font_size_override("font_size",14)
	add_child(hint)
	var actions := HFlowContainer.new()
	if qualified:
		var listen := Button.new()
		listen.text = "听这段呼唤对岸"
		listen.pressed.connect(demo._listen_authored_duet.bind(str(world.families[family_id]["root"])))
		listen.set_meta("duet_listen",true)
		actions.add_child(listen)
	var full := Button.new()
	full.text = "回到全城合奏"
	full.pressed.connect(demo._resume_full_composition)
	actions.add_child(full)
	add_child(actions)
