extends Control
## Audible-time presentation; never advances the city or consumes RNG.
var title: Label
var body: Label
var badge: Label
var card_alpha := 0.0
var dismissed_start := -1
var active_start := -1
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	title = _label(36)
	body = _label(19)
	badge = _label(18)
func _label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("526473"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
func dismiss() -> bool:
	if active_start < 0 or card_alpha <= 0.0: return false
	dismissed_start = active_start
	return true
func sample(session: Object, audible: float, black: bool) -> void:
	visible = not black and not session.run.is_empty()
	if not visible: return
	var run: Dictionary = session.run
	badge.position = Vector2(270,26)
	badge.size = Vector2(maxf(200,size.x-770),30)
	var prefix := "跨越体验 · " if run.get("preview",false) else ""
	badge.text = prefix+("古典 · 石与弦" if int(run["era"]) == 1 else "中世纪 · 钟与木")
	card_alpha = 0.0
	active_start = -1
	if run["phase"] == "transition":
		var transition: Dictionary = run["transition"]
		active_start = int(transition["start"])
		var seconds: float = (audible-active_start)/session.transport.sample_rate
		if seconds >= 2.0 and seconds < 6.0 and dismissed_start != active_start:
			card_alpha = minf(clampf((seconds-2.0)/0.8,0.0,1.0),clampf((6.0-seconds)/0.6,0.0,1.0))
		badge.text = prefix+"从石到钟 · %.1f 秒后开始新乐章" % maxf(0.0,16.0-seconds)
		title.text = "你赢得了中世纪" if transition["perfect"] else "城市迈入中世纪"
		body.text = "%s · 第%d乐章末 · R %.0f

新增 F、B · 木骨住宅、行会市场、水车磨坊
音乐仍在流动，城市在等待新的篇章。

任意键收起时代卡；可平移、缩放观看。" % ["完满终止" if transition["perfect"] else "平淡跨越",transition["chapter"],transition["r"]]
	elif run["phase"] == "finished":
		badge.text = "本局抵达：%s · 重新开始可再谱一座城" % ("古典" if int(run["era"]) == 1 else "中世纪")
	var center := Vector2(size.x*0.61,size.y*0.43)
	title.position = center+Vector2(-325,-108)
	title.size = Vector2(650,60)
	body.position = center+Vector2(-325,-36)
	body.size = Vector2(650,195)
	title.visible = card_alpha > 0.0
	body.visible = card_alpha > 0.0
	title.modulate.a = card_alpha
	body.modulate.a = card_alpha
	queue_redraw()
func _draw() -> void:
	if card_alpha <= 0.0: return
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.91,0.92,0.92,card_alpha*0.56))
	var center := Vector2(size.x*0.61,size.y*0.43)
	var box := Rect2(center+Vector2(-355,-138),Vector2(710,322))
	draw_style_box(_card_style(),box)
func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97,0.96,0.92,card_alpha*0.96)
	style.border_color = Color(0.78,0.71,0.58,card_alpha*0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	return style
