extends Button
## One small entry follows a real first composition from planning to its own house.
var demo: Control
var origin_frame := 0.0
var entered := false
var action := "planning"
var authored_state: Dictionary = {}
const EXPRESSIONS := {"deep":"深流","weave":"织机","warm":"暖庭"}

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
			tooltip_text = "发展方向已经落定，继续选择声音；确认才种下"
			disabled = false
			visible = not _blocked()
			_place_entry()
			return
	if demo.planning_guide.has_method("unfinished_public_choice") and demo.planning_guide.unfinished_public_choice():
		entered = true
		action = "public"
		text = "继续塑造这一段 · 公共空间"
		tooltip_text = "发展方向与社区已选好；继续安排公园、文化馆、留地，或选择暂不建设"
		disabled = false
		visible = not _blocked()
		_place_entry()
		return
	authored_state = demo._first_authored_state()
	var root_id := str(authored_state.get("root_id",""))
	if not root_id.is_empty():
		entered = true
		# A surviving house in the audible World is enough to return to one's
		# work. Theme qualification and a heard retune describe the music; they
		# do not lock the existing house menu or the player's next composition.
		var expression := str(EXPRESSIONS.get(str(authored_state["expression"]),"声音"))
		action = "authored"
		disabled = false
		text = "你的%s · 改音与继续" % expression
		tooltip_text = "%s · 回到你种下的房屋，改音、照看留白，或开始下一段" % str(authored_state["community_name"])
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
	if action == "authored":
		var current: Dictionary = demo._first_authored_state()
		var root_id := str(authored_state.get("root_id",""))
		if root_id.is_empty() or str(current.get("root_id","")) != root_id:
			sync()
			return
		demo._open_authored_root(root_id)
		hide()
		return
	entered = true
	hide()
	demo.planning_guide.open_tool()
	demo.queue_redraw()
