extends Control
## One status for the current selection, timed by the actual preview player.
const Ui = preload("res://scripts/ui/valley_ui_theme.gd")
var state: Dictionary = {}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(250,36)

func sync(demo: Control) -> void:
	state.clear()
	if not demo.menu.visible or not demo._expression_context(): return
	var choice := str(demo.expression_choice)
	var text := "点一个声音，听四秒合奏"
	var ink := Ui.MUTED
	var elapsed := 0.0
	var duration := 4.0
	var playing: bool = demo.preview_started and demo.preview_player.playing
	if not choice.is_empty():
		var definition: Dictionary = demo.PlayerExpression.definition(choice)
		ink = demo.FirstExpressionIdentity.STYLES[choice]["ink"]
		text = str(definition["label"])+" · "+("正在试听" if playing else "准备试听" if demo.preview_requested else "已选")
	if playing:
		duration = demo.preview_player.stream.get_length()
		elapsed = clampf(demo.preview_player.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency(),0.0,duration)
	state = {"text":text,"ink":ink,"playing":playing,"elapsed":elapsed,"duration":duration,"progress":elapsed/duration if playing else -1.0}
	queue_redraw()

func _draw() -> void:
	if state.is_empty(): return
	var font := ThemeDB.fallback_font
	var ink: Color = state["ink"]
	draw_string(font,Vector2(0,17),str(state["text"]),HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink.darkened(0.2))
	if not bool(state["playing"]): return
	var time := "%.1f / %.0f 秒" % [state["elapsed"],state["duration"]]
	var width := font.get_string_size(time,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	draw_string(font,Vector2(size.x-width,17),time,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Ui.MUTED)
	draw_line(Vector2(0,30),Vector2(size.x,30),Color(ink,0.18),2,true)
	draw_line(Vector2(0,30),Vector2(size.x*float(state["progress"]),30),ink,2,true)
