extends Button
## One small entry follows a real first composition from planning to its own theme.
var demo: Control
var origin_frame := 0.0
var entered := false
var action := "planning"
var authored_state: Dictionary = {}
var heard_root := ""
const EXPRESSIONS := {"deep":"深流","weave":"织机","warm":"留地"}

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	name = "FirstCompositionGuide"
	text = "写第一段 · 选择发展章程"
	tooltip_text = "先决定一片社区怎样生长，再亲自放置公园或文化馆"
	theme = demo.planning_guide.theme
	add_theme_font_size_override("font_size",16)
	z_index = 115
	pressed.connect(_begin)
	hide()

func reset_for_city() -> void:
	origin_frame = demo.clock.renderer.transport.audible_frame
	entered = false
	action = "planning"
	authored_state.clear()
	heard_root = ""
	disabled = false
	hide()

func sync() -> void:
	if not bool(demo.get("first_composition_mode")):
		hide()
		return
	if demo.planning_guide.opened: entered = true
	authored_state = demo._first_authored_state()
	var root_id := str(authored_state.get("root_id",""))
	if not root_id.is_empty():
		entered = true
		if bool(authored_state.get("root_heard_retune",false)):
			heard_root = root_id
		if heard_root == root_id:
			hide()
			return
		var community := str(authored_state["community_name"])
		var expression := str(EXPRESSIONS.get(str(authored_state["expression"]),"声音"))
		if bool(authored_state.get("theme_eligible",false)):
			action = "theme"
			disabled = false
			text = "%s · 改写你种下的%s" % [community,expression]
			tooltip_text = "回到你亲自种下的房屋，改一个音；不替你选择或提交"
		else:
			action = "growth"
			disabled = true
			text = "%s · 你种下的%s在生长" % [community,expression]
			tooltip_text = "同一家族已有%d栋房屋；社区至少六栋成熟房屋后才能形成主题" % int(authored_state.get("family_houses",1))
		visible = not _blocked()
	elif entered or _has_started_work():
		entered = true
		hide()
		return
	else:
		action = "planning"
		disabled = false
		text = "写第一段 · 选择发展章程"
		tooltip_text = "先决定一片社区怎样生长，再亲自放置公园或文化馆"
		var audible_seconds: float = (demo.clock.renderer.transport.audible_frame-origin_frame)/float(demo.clock.renderer.transport.sample_rate)
		visible = not _blocked() and audible_seconds >= 10.0
	reset_size()
	position = Vector2(24,maxf(24,demo.size.y-size.y-24))

func _blocked() -> bool:
	return demo.black or demo.menu.visible or demo.planning_guide.opened or get_tree().paused or not demo.clock.active or demo.clock.player.stream_paused

func _has_started_work() -> bool:
	var world = demo.shown_world
	if not world.development_charters.is_empty() or not world.planning_reservations.is_empty(): return true
	for site: Dictionary in world.public_sites:
		if bool(site.get("active",false)): return true
	for operation: Dictionary in demo.model.world.pending_actions:
		if str(operation.get("kind","")) in ["charter","seed","park","civic"]: return true
	return false

func _begin() -> void:
	if not bool(demo.get("first_composition_mode")) or disabled or _blocked(): return
	if action == "theme":
		var current: Dictionary = demo._first_authored_state()
		if str(current.get("root_id","")) != str(authored_state.get("root_id","")) or not bool(current.get("theme_eligible",false)):
			sync()
			return
		if bool(demo._begin_first_authored_theme()): hide()
		return
	entered = true
	hide()
	demo.planning_guide.open_tool()
	demo.queue_redraw()
