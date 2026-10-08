class_name P0Main
extends Control

const Generator = preload("res://scripts/city/city_generator.gd")
const RandomStreams = preload("res://scripts/city/named_random.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Preview = preload("res://scripts/proposals/proposal_preview.gd")
const Presentation = preload("res://scripts/ui/proposal_presentation.gd")
const PreviewOutput = preload("res://scripts/audio/preview_audio_output.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")
const Schema = preload("res://scripts/city/district_schema.gd")

@export var start_audio_on_ready := true
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
var prediction: Label

func _ready() -> void:
	var seed := RandomStreams.current_daily_seed()
	var daily := true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed = arg.trim_prefix("--seed=")
			daily = false
	generation = Generator.new().generate(seed,daily)
	model = Model.new(Session.new(generation["city"],generation["seed"],generation["rng"]))
	model.synth.guard_enabled = true
	clock = get_node("/root/AudioClock")
	preview_clock = PreviewOutput.new()
	preview_clock.name = "PreviewClock"
	add_child(preview_clock)
	preview_clock.audition_finished.connect(_audition_finished)
	_build_controls()
	if start_audio_on_ready:
		calibration = Calibration.for_city(model.session.city)
		model.synth.gain = float(calibration["gain"])
		clock.start_output(model._mix_frame,model.synth.initial_state())
	else:
		clock.renderer.source = model._mix_frame
		clock.renderer.state = model.synth.initial_state()
	_rebuild_targets()
	set_black_screen(black_screen)
	print("P0_READY seed=%s districts=%d" % [generation["seed"],model.session.city.size()])

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
	_label("共鸣之城 · P0 声音原型","Title")
	_label("聆听 → solo / mute 定位 → 选择方案 → 长按试听 → 确认。B 黑屏；Esc 返回。","Instructions")
	district_select = OptionButton.new()
	district_select.name = "District"
	for district in model.session.city:
		district_select.add_item("%s · (%d, %d)" % [district["district_id"],Schema.cell(district).x,Schema.cell(district).y])
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
	var assist := CheckButton.new()
	assist.name = "BeatAssist"
	assist.text = "窄带拍频辅助（只在窄带模式激活）"
	assist.set_pressed_no_signal(model.synth.assist_enabled)
	assist.toggled.connect(func(enabled: bool) -> void:
		_cancel_audition()
		model.synth.assist_enabled = enabled)
	controls.add_child(assist)
	var device := OptionButton.new()
	device.name = "DeviceMode"
	device.add_item("标准设备模式 · 辅助不激活")
	device.add_item("手动窄带设备 · 伴音 −6 dB")
	device.item_selected.connect(func(index: int) -> void:
		_cancel_audition()
		model.synth.device_mode = "narrowband" if index == 1 else "standard")
	controls.add_child(device)
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
	preview_button = _button("长按试听 3 秒（或按住空格）","Preview")
	preview_button.button_down.connect(_preview_down)
	preview_button.button_up.connect(_preview_up)
	confirm_button = _button("确认：下一乐句边界落定","Confirm")
	confirm_button.pressed.connect(_confirm)
	_button("取消待提交介入 / 试听","Cancel").pressed.connect(func() -> void:
		model.session.cancel_pending()
		_cancel_audition()
		status.text = "已取消待提交介入。")
	_button("黑屏聆听（B）","Black").pressed.connect(func() -> void: set_black_screen(true))
	status = _label("城市正在响着。","Status")
	prediction = _label("选择方案并长按试听，查看同一副本的收益与代价。","Prediction")

func diagnostic_state() -> Dictionary:
	return {"guard_factor":clock.renderer.state.get("_guard_factor",1.0),"calibration":calibration.duplicate(true),"gain":model.synth.gain,"assist_enabled":model.synth.assist_enabled,"device_mode":model.synth.device_mode,"skips":clock.underruns,"preview_skips":preview_skips,"phase":model.session.phrase_index,
		"black":black_screen,"panel":panel.visible,"mouse_mode":Input.mouse_mode,
		"preview_active":preview_clock.active,"want_preview":want_preview,"worker_alive":worker != null and worker.is_alive(),
		"preview_ready":not preview_data.is_empty(),"pending":model.session.pending.duplicate(true)}

func _selected_id() -> String:
	return str(model.session.city[district_select.selected]["district_id"])

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

func _preview_down() -> void:
	if selected_choice.is_empty() or black_screen or bool(model.session.lifecycle["ended"]):
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
	if model.session.phrase_index != display_phrase:
		display_phrase = model.session.phrase_index
		if display_phrase > 0:
			status.text = "第 %d 乐句已落定%s" % [display_phrase,"；本局已崩盘，重新运行可重试。" if model.session.lifecycle["ended"] else ""]
			if model.session.refresh_cycle != display_cycle or not model.session.last_result.get("choice",{}).is_empty():
				_rebuild_targets()
				display_cycle = model.session.refresh_cycle
		confirm_button.disabled = selected_choice.is_empty() or bool(model.session.lifecycle["ended"])
	if clock.underruns > 0 and not black_screen:
		status.text = "音频下溢 %d 次：本次运行不用于正式听测。" % clock.underruns

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
	if selected_choice.is_empty():
		return
	_cancel_audition()
	var request := model.session.request(selected_choice,clock.renderer.transport.rendered_frames,clock.renderer.transport.audible_frame)
	if request["accepted"]:
		var prediction_copy := model.session.fork()
		while prediction_copy.transport.phrase_frame(prediction_copy.phrase_index+1) <= int(request["frame"]):
			prediction_copy.settle(prediction_copy.transport.phrase_frame(prediction_copy.phrase_index+1))
		prediction.text = Presentation.describe(prediction_copy.last_result)["text"]
		status.text = "已确认，将在 %.2f 秒音频处落定；边界前可更换或取消。" % (float(request["frame"])/clock.renderer.transport.sample_rate)
	else:
		status.text = request["reason"]

func set_black_screen(enabled: bool) -> void:
	_cancel_audition()
	black_screen = enabled
	panel.visible = not enabled
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if enabled else Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo:
		return
	if event.pressed and event.keycode == KEY_B:
		set_black_screen(not black_screen)
	elif event.pressed and event.keycode == KEY_ESCAPE:
		set_black_screen(false)
	elif not black_screen and event.keycode == KEY_SPACE:
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
