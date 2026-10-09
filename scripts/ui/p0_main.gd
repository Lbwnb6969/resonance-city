class_name P0Main
extends Control

const Era = preload("res://scripts/city/city_era.gd")
const EraPresentation = preload("res://scripts/ui/era_presentation.gd")
const Ring = preload("res://scripts/city/city_ring.gd")
const Notice = preload("res://scripts/ui/formation_notice.gd")
const Roads = preload("res://scripts/city/city_roads.gd")
const CityView = preload("res://scripts/visual/city_demo_view.gd")
const Growth = preload("res://scripts/city/city_growth.gd")
const Generator = preload("res://scripts/city/city_generator.gd")
const RandomStreams = preload("res://scripts/city/named_random.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Preview = preload("res://scripts/proposals/proposal_preview.gd")
const Presentation = preload("res://scripts/ui/proposal_presentation.gd")
const PreviewOutput = preload("res://scripts/audio/preview_audio_output.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")
const Values = preload("res://scripts/spec_values.gd")
const Schema = preload("res://scripts/city/district_schema.gd")

@export var start_audio_on_ready := true
@export var growth_demo := true
@export var black_screen := false
var model: CityAudioModel
var clock: AudibleAudioClock
var preview_clock: PreviewAudioOutput
var worker: Thread
var preview_data: Dictionary = {}
var selected_choice: Dictionary = {}
var job_choice: Dictionary = {}
var job_phrase := 0
var want_preview := false
var restart_job := false
var display_phrase := -1
var display_cycle := 0
var generation: Dictionary
var preview_skips := 0
var closed := false
var calibration: Dictionary = {}
var city_view: CityDemoView
var release_pitch: OptionButton
var selected_empty := Vector2i(-1,-1)
var map_notice: Label
var city_summary: Label
var condition_text: Label
var beat_progress: ProgressBar
var population := 0
var release_armed := false
var release_button: CheckButton
var tread_button: CheckButton
var tread_choice: Dictionary = {}
var forecast_available := false
var draft_button: CheckButton
var draft_bias: OptionButton
var draft_state: Label
var focus_button: Button
var map_tool: OptionButton
var tool_hint: Label
var details_button: Button
var formation_notice: Control
var era_presentation: Control
var era_display_key := ""
var formation_button: CheckButton
var diagnosis_button: CheckButton
var reduced_motion_button: CheckButton
var diagnosis_legend: Label
var condition_selection := ""
var condition_phrase := -1

@onready var panel: MarginContainer = $Panel
@onready var controls: VBoxContainer = $Panel/Controls
var district_select: OptionButton
var verb_select: OptionButton
var target_select: OptionButton
var solo: CheckButton
var mute: CheckButton
var preview_button: Button
var confirm_button: Button
var status: Label
var forecast_summary: Label
var forecast_key := ""
var prediction: Label
var audible_resonance_key := ""
var audible_resonance := 100.0
var selected_growth_key := ""
var selected_growth_description := ""

func _ready() -> void:
	if "--performance-fixture=700" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file.call_deferred("res://scenes/performance_fixture.tscn")
		return
	theme = _demo_theme()
	var seed := RandomStreams.current_daily_seed()
	var daily := true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed = arg.trim_prefix("--seed=")
			daily = false
	generation = Generator.new().generate(seed,daily)
	var initial_session := Session.new(generation["city"],generation["seed"],generation["rng"])
	if growth_demo: Era.enable(initial_session,"--era-preview" in OS.get_cmdline_user_args())
	model = Model.new(initial_session)
	model.synth.guard_enabled = true
	model.synth.voice_grouping = growth_demo
	model.session.growth_enabled = growth_demo
	Growth.assign_assets(model.session.city)
	Era.apply_assets(model.session.city)
	_build_city_view()
	clock = get_node("/root/AudioClock")
	preview_clock = PreviewOutput.new()
	preview_clock.name = "PreviewClock"
	add_child(preview_clock)
	preview_clock.audition_finished.connect(_audition_finished)
	_build_controls()
	era_presentation = EraPresentation.new()
	era_presentation.name = "EraPresentation"
	add_child(era_presentation)
	formation_notice = Notice.new()
	formation_notice.name = "FormationNotice"
	city_view.add_child(formation_notice)
	var notice_cfg: Dictionary = Values.load_values()["formation_notice"]
	formation_notice.position = Vector2(notice_cfg["left"],Values.load_values()["camera"]["header_height"]+notice_cfg["top_gap"])
	formation_notice.focus_requested.connect(func(id: String) -> void:
		_select_district(id)
		city_view.selected_id = id
		city_view.focus_selected())
	formation_button.toggled.connect(formation_notice.set_enabled)
	if start_audio_on_ready:
		calibration = Calibration.for_synth(model.synth) if growth_demo else Calibration.for_city(model.session.city)
		model.synth.gain = float(calibration["gain"])
		clock.start_output(model._mix_frame,model.synth.initial_state())
	else:
		clock.renderer.source = model._mix_frame
		clock.renderer.state = model.synth.initial_state()
	_rebuild_targets()
	set_black_screen(black_screen)
	print("P0_READY seed=%s districts=%d" % [generation["seed"],model.session.city.size()])

func _demo_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	for kind in ["Label","Button","OptionButton","CheckButton"]:
		result.set_color("font_color",kind,Color("526473"))
		result.set_color("font_hover_color",kind,Color("40586b"))
		result.set_color("font_pressed_color",kind,Color("40586b"))
		result.set_color("font_hover_pressed_color",kind,Color("40586b"))
		result.set_color("font_disabled_color",kind,Color("9eabb4"))
	for state in ["normal","hover","pressed","disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("f6f5f1") if state == "normal" else (Color("efe2d4") if state in ["hover","pressed"] else Color("e4e9ec"))
		box.border_color = Color(1.0,1.0,1.0,0.7)
		box.set_border_width_all(1)
		box.set_corner_radius_all(6)
		box.content_margin_left = 9
		box.content_margin_right = 9
		box.content_margin_top = 5
		box.content_margin_bottom = 5
		result.set_stylebox(state,"Button",box)
		result.set_stylebox(state,"OptionButton",box)
	for state in ["background","fill"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("d6dfe5") if state == "background" else Color("bca99a")
		box.set_corner_radius_all(3)
		result.set_stylebox(state,"ProgressBar",box)
	for state in ["grabber","grabber_highlight","grabber_pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("b6c3cb")
		box.set_corner_radius_all(3)
		result.set_stylebox(state,"VScrollBar",box)
	return result

func _label(text: String, node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_child(label)
	return label

func _button(text: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	controls.add_child(button)
	return button

func _build_controls() -> void:
	_label("共鸣之城 · 从石到钟" if growth_demo else "共鸣之城 · P0","Title").add_theme_font_size_override("font_size",24)
	city_summary = _label("城市先响着。","CitySummary")
	if growth_demo: _label("本章目标：把三条大二度 / 小三度邻接调成协和，章末 R≥70。古典至少两章；第三章末保底跨越。","EraGoal")
	beat_progress = ProgressBar.new()
	beat_progress.show_percentage = false
	beat_progress.custom_minimum_size.y = 8
	controls.add_child(beat_progress)
	var camera_actions := HBoxContainer.new()
	camera_actions.name = "CameraActions"
	controls.add_child(camera_actions)
	var reset := _button("复位视角（Home）","ResetView")
	reset.reparent(camera_actions)
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(func() -> void: city_view.reset_view())
	focus_button = _button("聚焦选中","FocusSelected")
	focus_button.reparent(camera_actions)
	focus_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_button.pressed.connect(city_view.focus_selected)
	map_tool = OptionButton.new()
	map_tool.name = "MapTool"
	for text in ["地图工具 · 浏览与选择","地图工具 · 释放共鸣点","地图工具 · 划定引力","地图工具 · 踩路径"]:
		map_tool.add_item(text)
	controls.add_child(map_tool)
	map_tool.item_selected.connect(_set_map_tool)
	release_button = CheckButton.new()
	release_button.name = "ReleaseMode"
	release_button.text = "释放共鸣点：开启后点击地图空格"
	release_button.toggled.connect(func(enabled: bool) -> void:
		release_armed = enabled
		city_view.release_mode = enabled
		if enabled and is_instance_valid(draft_button):
			draft_button.set_pressed_no_signal(false)
			city_view.draft_mode = false
			city_view.draft_start = Vector2i(-1,-1)
		if enabled and is_instance_valid(tread_button):
			tread_button.set_pressed_no_signal(false)
			city_view.tread_mode = false
			city_view.tread_start = Vector2i(-1,-1)
			city_view.tread_candidate.clear()
			forecast_key = "")
	controls.add_child(release_button)
	release_pitch = OptionButton.new()
	release_pitch.name = "ReleasePitch"
	var names := {48:"C",50:"D",52:"E",53:"F",55:"G",57:"A",59:"B"}
	for midi in model.session.settings["allowed_pitches"]:
		release_pitch.add_item("%s · %s共鸣" % [names[int(midi)],"商业" if int(midi) == 52 else "住宅"])
		release_pitch.set_item_metadata(release_pitch.item_count-1,int(midi))
	controls.add_child(release_pitch)
	draft_button = CheckButton.new()
	draft_button.name = "DraftMode"
	draft_button.text = "划定引力：拖动地图画方向箭头"
	draft_button.toggled.connect(func(enabled: bool) -> void:
		city_view.draft_mode = enabled
		city_view.draft_start = Vector2i(-1,-1)
		if enabled:
			release_button.set_pressed_no_signal(false)
			release_armed = false
			city_view.release_mode = false
			if is_instance_valid(tread_button):
				tread_button.set_pressed_no_signal(false)
				city_view.tread_mode = false
				city_view.tread_candidate.clear()
			forecast_key = "")
	controls.add_child(draft_button)
	draft_bias = OptionButton.new()
	draft_bias.name = "DraftBias"
	draft_bias.add_item("引力偏向 · 住宅")
	draft_bias.add_item("引力偏向 · 商业")
	controls.add_child(draft_bias)
	draft_state = _label("暂无引力带；首次划线不暂停扩张。","DraftState")
	tread_button = CheckButton.new()
	tread_button.name = "TreadMode"
	tread_button.text = "踩路径：划过相邻格，再确认足迹"
	tread_button.toggled.connect(func(enabled: bool) -> void:
		_cancel_audition()
		city_view.tread_mode = enabled
		city_view.tread_start = Vector2i(-1,-1)
		forecast_key = ""
		if enabled:
			release_button.set_pressed_no_signal(false)
			draft_button.set_pressed_no_signal(false)
			release_armed = false
			city_view.release_mode = false
			city_view.draft_mode = false
			city_view.draft_start = Vector2i(-1,-1)
		else:
			city_view.tread_candidate.clear())
	controls.add_child(tread_button)
	tool_hint = _label("点击建筑，听它的声音或调整方案。","ToolHint")
	tool_hint.add_theme_font_size_override("font_size",14)
	_button("重新开始这座城市","Restart").pressed.connect(func() -> void: get_tree().reload_current_scene())
	_label("释放：点空格。引力：拖动划线。迁移：选迁移后点空格。B黑屏，Esc返回。","Instructions")
	district_select = OptionButton.new()
	district_select.name = "District"
	_refresh_district_list()
	controls.add_child(district_select)
	district_select.item_selected.connect(func(_index: int) -> void:
		solo.set_pressed_no_signal(model.synth.solo_id == _selected_id())
		mute.set_pressed_no_signal(model.synth.muted.get(_selected_id(),false))
		_rebuild_targets())
	solo = CheckButton.new()
	solo.name = "Solo"
	solo.text = "Solo 选中街区"
	solo.toggled.connect(func(enabled: bool) -> void:
		model.synth.set_solo(_selected_id() if enabled else "")
		_cancel_audition())
	controls.add_child(solo)
	mute = CheckButton.new()
	mute.name = "Mute"
	mute.text = "Mute 选中街区"
	mute.toggled.connect(func(enabled: bool) -> void:
		model.synth.set_mute(_selected_id(),enabled)
		_cancel_audition())
	controls.add_child(mute)
	diagnosis_button = CheckButton.new()
	diagnosis_button.name = "BoundaryDiagnosis"
	diagnosis_button.text = "失谐边界 · 看见抖 / 刺"
	controls.add_child(diagnosis_button)
	reduced_motion_button = CheckButton.new()
	reduced_motion_button.name = "ReducedMotion"
	reduced_motion_button.text = "减弱运动 · 保留静态形状"
	reduced_motion_button.visible = false
	reduced_motion_button.toggled.connect(func(enabled: bool) -> void: city_view.reduced_motion = enabled)
	controls.add_child(reduced_motion_button)
	diagnosis_legend = _label("波纹＝抖 · 短齿＝刺 · 点选看邻接","DiagnosisLegend")
	diagnosis_legend.add_theme_font_size_override("font_size",14)
	diagnosis_legend.visible = false
	diagnosis_button.toggled.connect(func(enabled: bool) -> void:
		city_view.diagnosis_enabled = enabled
		reduced_motion_button.visible = enabled
		diagnosis_legend.visible = enabled
		_update_map_notice())
	var assist := CheckButton.new()
	assist.name = "BeatAssist"
	assist.text = "窄带拍频辅助（只在窄带模式激活）"
	assist.set_pressed_no_signal(model.synth.assist_enabled)
	assist.toggled.connect(func(enabled: bool) -> void:
		_cancel_audition()
		model.synth.assist_enabled = enabled)
	controls.add_child(assist)
	assist.visible = false
	var device := OptionButton.new()
	device.name = "DeviceMode"
	device.add_item("标准设备模式 · 辅助不激活")
	device.add_item("手动窄带设备 · 伴音 −6 dB")
	device.item_selected.connect(func(index: int) -> void:
		_cancel_audition()
		model.synth.device_mode = "narrowband" if index == 1 else "standard")
	controls.add_child(device)
	device.visible = false
	verb_select = OptionButton.new()
	verb_select.name = "Verb"
	verb_select.add_item("retune · 调音")
	verb_select.add_item("relocate · 迁移")
	verb_select.item_selected.connect(func(_index: int) -> void: _rebuild_targets())
	controls.add_child(verb_select)
	target_select = OptionButton.new()
	target_select.name = "Target"
	target_select.item_selected.connect(func(_index: int) -> void: _choice_changed())
	controls.add_child(target_select)
	forecast_summary = _label("选择方案可查看收益和代价。","ForecastSummary")
	forecast_summary.add_theme_font_size_override("font_size",14)
	preview_button = _button("长按试听 3 秒（或按住空格）","Preview")
	preview_button.button_down.connect(_preview_down)
	preview_button.button_up.connect(_preview_up)
	confirm_button = _button("确认：下一乐句边界落定","Confirm")
	confirm_button.pressed.connect(_confirm)
	_button("取消待提交介入 / 试听","Cancel").pressed.connect(func() -> void:
		model.session.cancel_pending()
		city_view.preview_cell = Vector2i(-1,-1)
		city_view.draft_start = Vector2i(-1,-1)
		city_view.tread_candidate.clear()
		tread_choice.clear()
		forecast_key = ""
		_refresh_prediction()
		_cancel_audition()
		status.text = "已取消待提交介入。"
		_update_map_notice())
	_button("黑屏聆听（B）","Black").pressed.connect(func() -> void: set_black_screen(true))
	var listening := _button("正式黑屏听测（6练习 + 10正式）","ListeningTest")
	listening.visible = false
	listening.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/listening_session.tscn"))
	formation_button = CheckButton.new()
	formation_button.name = "FormationHints"
	formation_button.text = "成形提示"
	formation_button.set_pressed_no_signal(true)
	controls.add_child(formation_button)
	var advanced := _button("聆听设置 / 正式听测","AdvancedListening")
	advanced.toggle_mode = true
	advanced.toggled.connect(func(enabled: bool) -> void:
		assist.visible = enabled
		device.visible = enabled
		listening.visible = enabled)
	status = _label("从地图工具选择释放共鸣点，或点击建筑调整声音。","Status")
	condition_text = _label("点击建筑查看它等待的生长条件。","Conditions")
	prediction = _label("选择方案并长按试听，查看同一副本的收益与代价。","Prediction")
	details_button = _button("详细信息 / 设置","Details")
	details_button.toggle_mode = true
	controls.move_child(details_button,status.get_index())
	for item in [controls.get_node("Restart"),controls.get_node("Instructions"),advanced,assist,device,listening,condition_text,prediction,formation_button]:
		controls.move_child(item,controls.get_child_count()-1)
	for item in [controls.get_node("Restart"),controls.get_node("Instructions"),condition_text,prediction,advanced,formation_button]:
		item.visible = false
	details_button.toggled.connect(func(enabled: bool) -> void:
		for item in [controls.get_node("Restart"),controls.get_node("Instructions"),condition_text,prediction,advanced,formation_button]:
			item.visible = enabled
		for item in [assist,device,listening]: item.visible = enabled and advanced.button_pressed)
	for item in [release_button,draft_button,tread_button]:
		item.visible = false
		item.toggled.connect(func(_enabled: bool) -> void: _sync_map_tool())
	_sync_map_tool()

func _set_map_tool(index: int) -> void:
	_cancel_audition()
	release_button.button_pressed = index == 1
	draft_button.button_pressed = index == 2
	tread_button.button_pressed = index == 3
	_sync_map_tool()
	_update_map_notice()

func _sync_map_tool() -> void:
	var index := 1 if release_armed else (2 if city_view.draft_mode else (3 if city_view.tread_mode else 0))
	map_tool.select(index)
	release_pitch.visible = index == 1
	draft_bias.visible = index == 2
	draft_state.visible = index == 2
	tool_hint.visible = index != 0
	tool_hint.text = ["点击建筑，听它的声音或调整方案。","选择音级，再点击地图空格；下一乐句落定。","选择偏向，在地图按住左键划出方向。","划过相邻格，先看收益与代价，再确认足迹。"][index]
	for item in [verb_select,target_select,preview_button]: item.visible = index == 0
	forecast_summary.visible = index in [0,3]
	confirm_button.visible = index in [0,3]


func _build_city_view() -> void:
	var atmosphere: Dictionary = Values.load_values()["terrain"]
	var background := ShaderMaterial.new()
	background.shader = load("res://资源/着色器/柔和背景.gdshader")
	background.set_shader_parameter("top_color",Color(atmosphere["background_top"]))
	background.set_shader_parameter("bottom_color",Color(atmosphere["background_bottom"]))
	$Background.material = background
	$Background.color = Color.WHITE
	panel.anchor_left = 0.69
	panel.offset_left = 12
	panel.offset_top = 20
	panel.offset_right = -20
	panel.offset_bottom = -20
	var scroll := ScrollContainer.new()
	scroll.name = "DemoScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.remove_child(controls)
	panel.add_child(scroll)
	scroll.add_child(controls)
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_font_size_override("font_size",16)
	controls.add_theme_constant_override("separation",7)
	city_view = CityView.new()
	city_view.name = "CityView"
	city_view.anchor_right = 0.69
	city_view.anchor_bottom = 1.0
	city_view.session = model.session
	add_child(city_view)
	move_child(city_view,1)
	city_view.district_clicked.connect(_select_district)
	city_view.empty_clicked.connect(_select_empty)
	city_view.draft_requested.connect(_submit_draft)
	city_view.tread_selected.connect(_select_tread)
	var header := ColorRect.new()
	header.name = "MapHeader"
	header.color = Color("e9edf2")
	header.anchor_right = 1.0
	header.offset_bottom = float(Values.load_values()["camera"]["header_height"])
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	city_view.add_child(header)
	var title := Label.new()
	title.text = "共 鸣 之 城"
	title.position = Vector2(38,34)
	title.add_theme_font_size_override("font_size",30)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	city_view.add_child(title)
	var hint := Label.new()
	hint.text = "释放声音，让城市回应。\n住宅 C / 商业 E / 工业 F♯；新增共鸣只来自系统允许音级。\n滚轮缩放 · 中键拖动 · Home复位视角"
	hint.position = Vector2(40,85)
	hint.add_theme_font_size_override("font_size",15)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	city_view.add_child(hint)
	var notice_card := PanelContainer.new()
	notice_card.name = "MapNotice"
	notice_card.anchor_top = 1.0
	notice_card.anchor_right = 1.0
	notice_card.anchor_bottom = 1.0
	notice_card.offset_left = 24
	notice_card.offset_right = -24
	notice_card.offset_top = -136
	notice_card.offset_bottom = -18
	var box := StyleBoxFlat.new()
	box.bg_color = Color("f6f5f1")
	box.set_corner_radius_all(8)
	box.set_content_margin_all(14)
	notice_card.add_theme_stylebox_override("panel",box)
	city_view.add_child(notice_card)
	map_notice = Label.new()
	map_notice.name = "MapNoticeText"
	map_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_notice.add_theme_font_size_override("font_size",15)
	notice_card.add_child(map_notice)

func _audible_session() -> CityInterventions:
	return model.presentation_session(clock.renderer.transport.audible_frame)

func _refresh_district_list() -> void:
	var shown := _audible_session()
	var selected := _selected_id() if district_select.item_count > 0 and district_select.selected < shown.city.size() else ""
	district_select.clear()
	for d in shown.city:
		var type_name := "住宅" if d["type"] == "residential" else ("商业" if d["type"] == "commercial" else "工业")
		district_select.add_item("%s · %s · MIDI %d · (%d,%d)" % [type_name,d["district_id"],d["current_midi"],Schema.cell(d).x,Schema.cell(d).y])
		district_select.set_item_metadata(district_select.item_count-1,d["district_id"])
		if d["district_id"] == selected: district_select.select(district_select.item_count-1)
	population = shown.city.size()

func _select_district(id: String) -> void:
	var shown := _audible_session()
	if population != shown.city.size(): _refresh_district_list()
	for index in range(shown.city.size()):
		if shown.city[index]["district_id"] == id:
			district_select.select(index)
			solo.set_pressed_no_signal(model.synth.solo_id == id)
			mute.set_pressed_no_signal(model.synth.muted.get(id,false))
			_rebuild_targets()
			break

func _select_empty(cell: Vector2i) -> void:
	selected_empty = cell
	if release_armed:
		var feedback := model.session.release_feedback(int(release_pitch.get_item_metadata(release_pitch.selected)),cell)
		if not feedback["allowed"]:
			status.text = feedback["reason"]
			return
		_cancel_audition()
		var request := model.session.request_release(int(release_pitch.get_item_metadata(release_pitch.selected)),cell,clock.renderer.transport.rendered_frames,clock.renderer.transport.audible_frame)
		status.text = "共鸣点已选 (%d,%d)，将在下一乐句落定；可点击另一空格替换。" % [cell.x,cell.y] if request["accepted"] else "该位置无法释放，或声音预算已满。"
	elif verb_select.selected == 1:
		city_view.preview_cell = cell
		for index in range(target_select.item_count):
			if target_select.get_item_metadata(index)["target"] == [cell.x,cell.y]:
				target_select.select(index)
				_choice_changed()
				status.text = "迁移目标 (%d,%d)：可长按试听，然后确认。" % [cell.x,cell.y]
				return
	else:
		status.text = "这是空格。开启释放模式，或选迁移后点击。"

func _submit_draft(start: Vector2i, end: Vector2i) -> void:
	_cancel_audition()
	var bias := "residential" if draft_bias.selected == 0 else "commercial"
	var request := model.session.request_draft(start,end,bias,clock.renderer.transport.rendered_frames,clock.renderer.transport.audible_frame)
	if request["accepted"]:
		status.text = "引力箭头已提交，下个乐句生效；重划会暂停扩张一个乐句。"
	else:
		status.text = "引力线未提交：请在地图内拖动到不同格子。"

func _select_tread(start: Vector2i,end: Vector2i) -> void:
	_cancel_audition()
	tread_choice = {"verb":"tread","proposal_id":"tread","start":[start.x,start.y],"end":[end.x,end.y]}
	city_view.tread_candidate = tread_choice.duplicate(true)
	forecast_key = ""
	_refresh_prediction()
	_update_map_notice()
	status.text = "足迹已选：查看收益与代价，再按确认。第三次成路后本局不可撤销。"

func diagnostic_state() -> Dictionary:
	return {"guard_factor":clock.renderer.state.get("_guard_factor",1.0),"calibration":calibration.duplicate(true),"gain":model.synth.gain,"assist_enabled":model.synth.assist_enabled,"device_mode":model.synth.device_mode,"skips":clock.underruns,"preview_skips":preview_skips,"phase":model.session.phrase_index,
		"black":black_screen,"panel":panel.visible,"mouse_mode":Input.mouse_mode,
		"preview_active":preview_clock.active,"want_preview":want_preview,"worker_alive":worker != null and worker.is_alive(),
		"preview_ready":not preview_data.is_empty(),"pending":model.session.pending.duplicate(true)}

func _selected_id() -> String:
	return str(district_select.get_item_metadata(district_select.selected))

func _rebuild_targets() -> void:
	_cancel_audition()
	target_select.clear()
	var verb := "retune" if verb_select.selected == 0 else "relocate"
	var id := "p0:%d:%s:%s" % [model.session.refresh_cycle,_selected_id(),verb]
	var item := model.session.proposal(id)
	for target in item.get("targets",[]):
		target_select.add_item("MIDI %d" % int(target) if verb == "retune" else "空格 (%d, %d)" % [int(target[0]),int(target[1])])
		target_select.set_item_metadata(target_select.item_count-1,{"proposal_id":id,"target":int(target) if verb == "retune" else target.duplicate()})
	_choice_changed()

func _choice_changed() -> void:
	_cancel_audition()
	selected_choice = target_select.get_item_metadata(target_select.selected).duplicate(true) if target_select.item_count > 0 else {}
	preview_button.disabled = selected_choice.is_empty()
	confirm_button.disabled = selected_choice.is_empty()
	prediction.text = "该街区暂无此类合法提案。" if selected_choice.is_empty() else "长按试听可听未来；确认只在下一乐句生效。"
	forecast_key = ""
	_refresh_prediction()

func _refresh_prediction() -> void:
	if model.session.run.get("phase","") == "transition":
		forecast_available = false
		preview_button.disabled = true
		confirm_button.disabled = true
		forecast_summary.text = "时代跨越中，城市计时保持。"
		return
	var choice: Dictionary = tread_choice if city_view.tread_mode else selected_choice
	preview_button.disabled = city_view.tread_mode or choice.is_empty()
	confirm_button.text = "确认足迹：下一乐句落定" if city_view.tread_mode else "确认：下一乐句边界落定"
	if choice.is_empty():
		forecast_available = false
		forecast_summary.text = "划过相邻格，查看累计足迹及成路影响。" if city_view.tread_mode else "该街区暂无此类合法提案。"
		confirm_button.disabled = true
		return
	var period := clock.renderer.transport.phrase_frame(1)
	var on_grid := model.session.is_on_grid(clock.renderer.transport.audible_frame)
	var key := "%s:%d:%d:%d:%s" % [JSON.stringify(choice),model.session.phrase_index,int(model.session.run.get("offset",0)),clock.renderer.transport.rendered_frames/period,on_grid]
	if key == forecast_key: return
	forecast_key = key
	var expected := Preview.forecast(model.session,choice,clock.renderer.transport.rendered_frames,clock.renderer.transport.audible_frame)
	forecast_available = bool(expected["accepted"])
	confirm_button.disabled = not forecast_available or bool(model.session.lifecycle["ended"])
	if expected["accepted"]:
		forecast_summary.text = Presentation.summary(expected["result"])
		prediction.text = Presentation.describe(expected["result"])["text"]
	else:
		var reason: String = expected["reason"]
		if city_view.tread_mode and Roads.blocked(model.session.road_marks,Vector2i(choice["start"][0],choice["start"][1]),Vector2i(choice["end"][0],choice["end"][1])): reason = "该边已成路，本局不可撤销。可选择另一条边。"
		forecast_summary.text = reason
		prediction.text = reason

func _preview_down() -> void:
	if city_view.tread_mode or selected_choice.is_empty() or black_screen or bool(model.session.lifecycle["ended"]):
		return
	want_preview = true
	_start_job()

func _preview_up() -> void:
	want_preview = false
	_cancel_audition()

func _start_job() -> void:
	if worker != null:
		restart_job = true
		return
	preview_data.clear()
	job_choice = selected_choice.duplicate(true)
	job_phrase = model.session.phrase_index
	var model_saved := model.snapshot()
	var renderer_saved := clock.renderer.snapshot()
	var requested := clock.renderer.transport.audible_frame
	worker = Thread.new()
	worker.start(func() -> Dictionary: return Preview.build(model_saved,renderer_saved,job_choice,requested,true))
	status.text = "正在模拟下一乐句的声音；松开可取消。"

func _process(_delta: float) -> void:
	if model == null or closed:
		return
	var shown := _audible_session()
	_refresh_era_ui(shown)
	era_presentation.sample(shown,clock.renderer.transport.audible_frame,black_screen)
	if not black_screen and not shown.run.is_empty(): $Background.color = Color("f4efe6") if int(shown.run["era"]) == 1 else Color("e8eef2")
	formation_notice.consume(model.growth_history+model.ring_history,clock.renderer.transport.audible_frame)
	formation_notice.tick(_delta,clock.renderer.transport.audible_frame,shown,black_screen,city_view.reduced_motion)
	if worker != null and not worker.is_alive():
		var result: Dictionary = worker.wait_to_finish()
		worker = null
		if want_preview and (restart_job or job_choice != selected_choice or job_phrase != model.session.phrase_index):
			restart_job = false
			_start_job()
		elif want_preview and result.get("accepted",false):
			preview_data = result
			prediction.text = Presentation.describe(result["result"])["text"]
			AudioServer.lock()
			model.synth.begin_duck()
			clock.player.volume_db = -INF
			preview_clock.begin(result["pcm"])
			AudioServer.unlock()
			status.text = "试听中：真实城市继续计时，松开恢复原混音。"
		elif want_preview:
			status.text = result.get("reason","此方案已失效。")
	if not want_preview and not preview_clock.active: _refresh_prediction()
	city_view.session = shown
	city_view.selected_id = _selected_id()
	city_view.release_midi = int(release_pitch.get_item_metadata(release_pitch.selected))
	_update_map_notice()
	var resonance_key := "%d:%d" % [shown.get_instance_id(),shown.phrase_index]
	if resonance_key != audible_resonance_key:
		audible_resonance_key = resonance_key
		audible_resonance = shown.harmony.resonance(shown.city,shown.harmony.adjacency(shown.city))
	var resonance := audible_resonance
	var bar := clock.renderer.transport.phrase_frame(1)
	var remaining := maxf(0.0,float(shown.next_city_boundary())-clock.renderer.transport.audible_frame)
	city_summary.text = "R %.0f · %d/%d 声部 · 第%d乐句\n下一次回应 %.1f 秒" % [resonance,shown.city.size(),model.session.growth_values["growth"]["max_entities"],shown.phrase_index+1,remaining/clock.renderer.transport.sample_rate]
	if not shown.run.is_empty():
		var run: Dictionary = shown.run
		city_summary.text = "%s · 第%d/7乐章 · %d/12乐句\nR %.0f · 本章协和解决 %d/3\n%s" % ["古典" if int(run["era"]) == 1 else "中世纪",run["chapter"],run["phrase"],resonance,run["resolved"].size(),"时代跨越中 · 城市计时保持" if run["phase"] == "transition" else ("本局结束 · 可重新开始" if run["phase"] == "finished" else "下一次回应 %.1f秒 · %d/%d声部" % [remaining/clock.renderer.transport.sample_rate,shown.city.size(),shown.growth_values["growth"]["max_entities"]])]
	if not shown.gravity_band.is_empty():
		var band: Dictionary = shown.gravity_band
		var paused := maxf(0.0,float(shown.draft_pause_until)-clock.renderer.transport.audible_frame)/clock.renderer.transport.sample_rate
		draft_state.text = "%s引力 (%d,%d)→(%d,%d)%s" % ["住宅" if band["bias"] == "residential" else "商业",band["start"][0],band["start"][1],band["end"][0],band["end"][1]," · 扩张暂停 %.1f秒" % paused if paused > 0.0 else ""]
	beat_progress.value = fposmod(clock.renderer.transport.audible_frame,float(clock.renderer.transport.beat_frame(1)))/clock.renderer.transport.beat_frame(1)*100.0
	if condition_selection != _selected_id() or condition_phrase != shown.phrase_index:
		condition_selection = _selected_id()
		condition_phrase = shown.phrase_index
		condition_text.text = _growth_description(shown)
	if shown.phrase_index != display_phrase:
		display_phrase = shown.phrase_index
		_refresh_district_list()
		city_view.preview_cell = Vector2i(-1,-1)
		if display_phrase > 0:
			status.text = "第 %d 乐句已落定%s" % [display_phrase,"；本局已崩盘，重新运行可重试。" if shown.lifecycle["ended"] else ""]
			if shown.last_result.get("choice",{}).get("verb","") == "draft":
				status.text = "引力已生效；扩张暂停一个乐句，声音与已有建筑继续。" if shown.last_result["choice"].get("redrawn",false) else "引力已生效；城市继续按和声条件生长。"
			if shown.refresh_cycle != display_cycle or not shown.last_result.get("choice",{}).is_empty():
				_rebuild_targets()
				display_cycle = shown.refresh_cycle
		confirm_button.disabled = not forecast_available or bool(shown.lifecycle["ended"]) or shown.run.get("phase","") == "transition"
	if clock.underruns > 0 and not black_screen:
		status.text = "音频下溢 %d 次：本次运行不用于正式听测。" % clock.underruns

func _refresh_era_ui(shown: CityInterventions) -> void:
	if shown.run.is_empty(): return
	var key := "%d:%s:%d" % [shown.run["era"],shown.run["phase"],shown.city.size()]
	if key == era_display_key: return
	era_display_key = key
	var previous := int(release_pitch.get_item_metadata(release_pitch.selected))
	release_pitch.clear()
	var names := {48:"C",50:"D",52:"E",53:"F",55:"G",57:"A",59:"B"}
	for midi in shown.settings["allowed_pitches"]:
		release_pitch.add_item("%s · %s共鸣" % [names[int(midi)],"商业" if int(midi) == 52 else "住宅"])
		release_pitch.set_item_metadata(release_pitch.item_count-1,int(midi))
		if int(midi) == previous: release_pitch.select(release_pitch.item_count-1)
	_refresh_district_list()
	_rebuild_targets()
	forecast_key = ""
	if shown.run["phase"] == "transition":
		_cancel_audition()
		status.text = "城市正在跨越；新乐章开始后恢复介入。"
	elif int(shown.run["era"]) == 2:
		status.text = "F、B 来客已抵达新土地：选中来客，可调音、迁移，或让城市向它们生长。"

func _growth_description(shown: CityInterventions) -> String:
	# City and road changes commit on a phrase boundary. Read the audible
	# session identity, so pre-rendered future changes cannot invalidate early.
	var key := "%d:%d:%s" % [shown.get_instance_id(),shown.phrase_index,_selected_id()]
	if key != selected_growth_key:
		selected_growth_key = key
		selected_growth_description = Growth.describe(shown.city,shown._district(_selected_id()),shown.road_marks)
	return selected_growth_description

func _update_map_notice() -> void:
	var shown := _audible_session()
	var text := ""
	city_view.get_node("MapNotice").offset_top = -176 if city_view.tread_mode else (-252 if city_view.diagnosis_enabled and not release_armed and not city_view.draft_mode else -136)
	if city_view.tread_mode:
		text = forecast_summary.text+"\n划过先预览，确认才计数；累计3次成路，本局不可撤销。"
	elif release_armed:
		var cell := city_view.hover_cell
		text = "释放 %s · 将鼠标移到地图格子上查看是否可放置。" % release_pitch.get_item_text(release_pitch.selected)
		if city_view.pointer_inside:
			text = "释放 %s · (%d,%d)\n%s" % [release_pitch.get_item_text(release_pitch.selected),cell.x,cell.y,model.session.release_feedback(city_view.release_midi,cell)["reason"]]
	elif city_view.draft_mode:
		text = "划定引力：在地图内拖出方向箭头。偏向只影响合法扩张位置；重划暂停一乐句。"
	else:
		var district: Dictionary = shown._district(_selected_id())
		var kind := "住宅" if district["type"] == "residential" else ("商业" if district["type"] == "commercial" else "工业")
		var details: PackedStringArray = _growth_description(shown).split("\n")
		text = "%s · %s · 活力 %.0f\n%s" % [kind,district.get("form","胚"),district["vitality"],"\n".join(details.slice(0,mini(2,details.size())))]
		var ring_text := Ring.describe(shown.rings,_selected_id(),model.synth.muted,model.synth.solo_id,shown.silent_until,clock.renderer.transport.audible_frame)
		if not ring_text.is_empty():
			text += "\n"+ring_text
			city_view.get_node("MapNotice").offset_top = -292 if city_view.diagnosis_enabled else -228
		if city_view.diagnosis_enabled:
			var rows: Array[Dictionary] = city_view.diagnosis.edges(shown,model.synth,clock.renderer.transport.audible_frame)
			text += "\n"+city_view.diagnosis.describe(rows,_selected_id())
			if want_preview or preview_clock.active: text += "\n边界来自当前城市；试听是未来声音。"

	var pending: Dictionary = shown.pending
	if not pending.is_empty():
		var wait := maxf(0.0,float(pending["frame"])-clock.renderer.transport.audible_frame)/clock.renderer.transport.sample_rate
		var item: Dictionary = shown.proposal(str(pending.get("proposal_id","")))
		if item.is_empty(): item = model.session.proposal(str(pending.get("proposal_id","")))
		var verb: String = pending.get("verb",item.get("verb",""))
		var action := "调音" if verb == "retune" else ("迁移" if verb == "relocate" else ("引力带" if verb == "draft" else ("足迹" if verb == "tread" else "共鸣点")))
		if verb == "release": action += " (%d,%d)" % [pending["target"][0],pending["target"][1]]
		var baked: bool = int(pending["frame"]) < clock.renderer.transport.rendered_frames
		text += "\n已排入声音：%s · %.1f秒后可听；可提交下一次介入。" % [action,wait] if baked else "\n待落定：%s · %.1f秒；可更换或取消。" % [action,wait]
	map_notice.text = text

func _audition_finished(skips: int) -> void:
	preview_skips = skips
	clock.player.volume_db = 0.0
	model.synth.release_duck(clock.renderer.transport.rendered_frames)
	want_preview = false
	status.text = "3 秒试听结束，已恢复原混音；可确认或更换方案。"

func _cancel_audition() -> void:
	want_preview = false
	restart_job = false
	AudioServer.lock()
	if is_instance_valid(preview_clock):
		preview_clock.stop_output()
	if is_instance_valid(clock) and is_instance_valid(clock.player):
		clock.player.volume_db = 0.0
		if model != null:
			model.synth.release_duck(clock.renderer.transport.rendered_frames)
	AudioServer.unlock()

func _confirm() -> void:
	var choice: Dictionary = tread_choice if city_view.tread_mode else selected_choice
	if choice.is_empty():
		return
	_cancel_audition()
	var request := model.session.request(choice,clock.renderer.transport.rendered_frames,clock.renderer.transport.audible_frame)
	if request["accepted"]:
		var prediction_copy := model.session.fork()
		while prediction_copy.next_city_boundary() <= int(request["frame"]):
			prediction_copy.settle(prediction_copy.next_city_boundary())
		prediction.text = Presentation.describe(prediction_copy.last_result)["text"]
		forecast_summary.text = Presentation.summary(prediction_copy.last_result)
		status.text = "已确认，将在 %.2f 秒音频处落定；边界前可更换或取消。" % (float(request["frame"])/clock.renderer.transport.sample_rate)
	else:
		status.text = request["reason"]

func set_black_screen(enabled: bool) -> void:
	_cancel_audition()
	black_screen = enabled
	panel.visible = not enabled
	if is_instance_valid(city_view): city_view.visible = not enabled
	$Background.color = Color.BLACK if enabled else Color.WHITE
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if enabled else Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo:
		return
	if event.pressed and event.keycode == KEY_B:
		set_black_screen(not black_screen)
	elif event.pressed and event.keycode == KEY_ESCAPE:
		set_black_screen(false)
	elif event.pressed and not black_screen and era_presentation.dismiss():
		get_viewport().set_input_as_handled()
	elif event.pressed and not black_screen and event.keycode == KEY_HOME:
		city_view.reset_view()
		get_viewport().set_input_as_handled()
	elif not black_screen and event.keycode == KEY_SPACE and preview_button.is_visible_in_tree() and not preview_button.disabled:
		if get_viewport().gui_get_focus_owner() is OptionButton: return
		_preview_down() if event.pressed else _preview_up()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	closed = true
	_cancel_audition()
	if worker != null:
		worker.wait_to_finish()
		worker = null
	if is_instance_valid(clock):
		clock.stop_output()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
