extends Button
## One small entry follows a real first composition from planning to its own theme.
const FirstAuthoredContinuation = preload("res://scripts/world/first_authored_continuation.gd")
var demo: Control
var origin_frame := 0.0
var entered := false
var action := "planning"
var authored_state: Dictionary = {}
var continuation_state: Dictionary = {}
var heard_root := ""
const EXPRESSIONS := {"deep":"深流","weave":"织机","warm":"留地"}

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	name = "FirstCompositionGuide"
	text = "塑造第一段 · 选择发展方向"
	tooltip_text = "选一片街坊和一种生长方向，再安排公共空间；城市会沿道路自动长出回应"
	theme = demo.planning_guide.theme
	add_theme_font_size_override("font_size",16)
	custom_minimum_size = Vector2(318,44)
	var entry_style := StyleBoxFlat.new()
	entry_style.bg_color = Color("e6dfc7",0.96)
	entry_style.border_color = Color("b19263")
	entry_style.set_border_width_all(1)
	entry_style.set_corner_radius_all(9)
	entry_style.content_margin_left = 14
	entry_style.content_margin_right = 14
	entry_style.content_margin_top = 8
	entry_style.content_margin_bottom = 8
	add_theme_stylebox_override("normal",entry_style)
	var entry_hover := entry_style.duplicate()
	entry_hover.bg_color = Color("f1e4bf",0.99)
	entry_hover.border_color = Color("9d7d4d")
	add_theme_stylebox_override("hover",entry_hover)
	z_index = 115
	pressed.connect(_begin)
	hide()

func reset_for_city() -> void:
	origin_frame = demo.clock.renderer.transport.audible_frame
	entered = false
	action = "planning"
	authored_state.clear()
	continuation_state.clear()
	heard_root = ""
	disabled = false
	hide()

func sync() -> void:
	if not bool(demo.get("first_composition_mode")):
		hide()
		return
	if demo.planning_guide.opened: entered = true
	if demo.planning_guide.has_method("ready_sound_community"):
		var ready_cid: String = demo.planning_guide.ready_sound_community()
		if not ready_cid.is_empty():
			entered = true
			action = "sound"
			text = "给"+str(demo.shown_world.communities[ready_cid]["name"])+"选一个声音"
			tooltip_text = "公共空间已经落成，继续选择声音；确认才种下"
			disabled = false
			visible = not _blocked()
			_place_entry()
			return
	authored_state = demo._first_authored_state()
	var root_id := str(authored_state.get("root_id",""))
	if not root_id.is_empty():
		entered = true
		continuation_state.clear()
		# The continuation is derived from the live World.  Test doubles and
		# older callers without a ContinuousWorld stay on the existing status
		# path instead of inventing a target.
		if demo.shown_world != null and demo.shown_world.has_method("snapshot"):
			var score: Dictionary = demo.model.audible_score() if demo.model != null and demo.model.has_method("audible_score") else {}
			continuation_state = FirstAuthoredContinuation.state(demo.shown_world,authored_state,score)
		if bool(authored_state.get("root_heard_retune",false)):
			heard_root = root_id
		if heard_root == root_id and bool(authored_state.get("theme_eligible",false)):
			if bool(continuation_state.get("reservation_active",false)):
				action = "continuation"
				text = "照看你留下的空地 · "+str(authored_state["community_name"])
				tooltip_text = "保留留白，或亲自把它营造成公共空间"
			else:
				action = "compose"
				text = "下一段 · 街坊 / 公共空间 / 声音 · P"
				tooltip_text = "点击这里或按 P：重新选发展方向与社区，再选择公共空间和下一段声音"
			disabled = false
			visible = not _blocked()
			_place_entry()
			return
		var community := str(authored_state["community_name"])
		var expression := str(EXPRESSIONS.get(str(authored_state["expression"]),"声音"))
		if bool(authored_state.get("theme_eligible",false)):
			action = "theme"
			disabled = false
			text = "%s · 改写你种下的%s" % [community,expression]
			tooltip_text = "回到你亲自种下的房屋，改一个音并听见它；听见后开放下一段规划"
		else:
			var continuation: Dictionary = continuation_state.get("action",{})
			if bool(continuation.get("available",false)) and str(continuation.get("kind","")) in ["root","reservation","community","child"]:
				action = "continuation"
				disabled = false
				var continuation_kind := str(continuation.get("kind",""))
				var continuation_label := "定位真实留地" if continuation_kind == "reservation" else ("沿社区继续组合" if continuation_kind == "community" else ("定位最近新屋" if continuation_kind == "child" else "定位首作房屋"))
				text = "%s · %s" % [community,continuation_label]
				tooltip_text = str(continuation.get("text","沿真实结果继续组合"))
			else:
				action = "growth"
				disabled = true
				text = "%s · 你种下的%s在生长" % [community,expression]
				tooltip_text = "同一家族已有%d栋房屋；社区至少六栋成熟房屋后才能形成主题" % int(authored_state.get("family_houses",1))
		visible = not _blocked()
	elif _has_started_work():
		entered = true
		hide()
		return
	else:
		action = "planning"
		disabled = false
		text = "继续塑造第一段" if entered else "塑造第一段 · 选择发展方向"
		tooltip_text = "选一片街坊和一种生长方向，再安排公共空间；城市会沿道路自动长出回应"
		var audible_seconds: float = (demo.clock.renderer.transport.audible_frame-origin_frame)/float(demo.clock.renderer.transport.sample_rate)
		visible = not _blocked() and audible_seconds >= 5.0
	_place_entry()

func _place_entry() -> void:
	reset_size()
	position = Vector2(24,90)

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
	if action == "sound":
		demo.planning_guide._take_next_action()
		return
	if action == "compose":
		hide()
		if demo.has_method("_begin_next_composition"): demo._begin_next_composition()
		else: demo.planning_guide.open_tool()
		return
	if action == "theme":
		var current: Dictionary = demo._first_authored_state()
		if str(current.get("root_id","")) != str(authored_state.get("root_id","")) or not bool(current.get("theme_eligible",false)):
			sync()
			return
		if bool(demo._begin_first_authored_theme()): hide()
		return
	if action == "continuation":
		var current: Dictionary = demo._first_authored_state()
		if current.is_empty():
			sync()
			return
		if demo.has_method("_begin_first_authored_continuation") and bool(demo._begin_first_authored_continuation()):
			hide()
		return
	entered = true
	hide()
	demo.planning_guide.open_tool()
	demo.queue_redraw()
