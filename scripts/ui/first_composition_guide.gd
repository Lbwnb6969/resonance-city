extends Button
## One invitation after the audible overture; all authoring uses the ordinary Guide.
var demo: Control
var origin_frame := 0.0
var entered := false

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
	hide()

func sync() -> void:
	if not bool(demo.get("first_composition_mode")):
		hide()
		return
	if demo.planning_guide.opened: entered = true
	var audible_seconds: float = (demo.clock.renderer.transport.audible_frame-origin_frame)/float(demo.clock.renderer.transport.sample_rate)
	visible = not entered and not demo.black and not demo.menu.visible and audible_seconds >= 10.0
	reset_size()
	position = Vector2(24,maxf(24,demo.size.y-size.y-24))

func _begin() -> void:
	if not bool(demo.get("first_composition_mode")): return
	entered = true
	hide()
	demo.planning_guide.open_tool()
	demo.queue_redraw()
