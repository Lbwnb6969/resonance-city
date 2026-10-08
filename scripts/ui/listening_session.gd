class_name ListeningSession
extends Control

const Fixtures = preload("res://scripts/audio/listening_fixtures.gd")
const Output = preload("res://scripts/audio/preview_audio_output.gd")
const Values = preload("res://scripts/spec_values.gd")
const CONDITIONS := ["headphones_standard","speaker_standard","speaker_narrowband"]
const FIELDS := ["protocol","tester_id","stage","trial_id","seed","layout_id","device","device_notes","assist_state","device_mode","truth_direction","truth_type","answer_direction","answer_type","correct","skips","origin","pcm_sha256","notes"]

var diagnostic_mode := false
var output_enabled := true
var panel: MarginContainer
var box: VBoxContainer
var player: PreviewAudioOutput
var tester_input: LineEdit
var device_input: LineEdit
var condition_input: OptionButton
var message: Label
var submit: Button
var trial_index := 0
var tester_id := ""
var condition := ""
var device_notes := ""
var playing := false
var trials: Array
var audio: Dictionary = {}
var answer_direction := ""
var answer_type := ""
var last_skips := 0
var result_file: FileAccess
var result_path := ""
var saved_formal := 0

func _ready() -> void:
	player = Output.new()
	player.name = "ListeningOutput"
	add_child(player)
	player.audition_finished.connect(_ended)
	panel = MarginContainer.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_constant_override("margin_left",32)
	panel.add_theme_constant_override("margin_top",24)
	panel.add_theme_constant_override("margin_right",32)
	panel.add_theme_constant_override("margin_bottom",24)
	add_child(panel)
	box = VBoxContainer.new()
	panel.add_child(box)
	trials = Fixtures.protocol()["trials"]
	_setup()

func _clear() -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

func _label(text: String) -> Label:
	var item := Label.new()
	item.text = text
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(item)
	return item

func _button(text: String, action: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.pressed.connect(action)
	box.add_child(item)
	return item

func _setup() -> void:
	_clear()
	_label("共鸣之城 · P0 黑屏听测")
	_label("6题练习后10题正式；每题播放8秒，全黑后回答左/中/右与抖/刺。正式题不重放、不显示真值。请确认实际耳机或内置扬声器，并保持本组音量。Esc中止会话。")
	tester_input = LineEdit.new()
	tester_input.placeholder_text = "测试者编号，例如 T01"
	box.add_child(tester_input)
	device_input = LineEdit.new()
	device_input.placeholder_text = "实际设备型号 / 连接方式"
	box.add_child(device_input)
	condition_input = OptionButton.new()
	condition_input.add_item("耳机 · 标准 · 辅助OFF")
	condition_input.add_item("内置扬声器 · 标准 · 辅助OFF")
	condition_input.add_item("内置扬声器 · 窄带补充 · 辅助ON")
	box.add_child(condition_input)
	message = _label("每个设备条件需3名测试者；自动工具检查不能计入真人成绩。")
	_button("开始练习与正式听测",func() -> void: begin_session(tester_input.text,CONDITIONS[condition_input.selected],device_input.text))
	_button("返回声音原型",func() -> void: get_tree().change_scene_to_file("res://scenes/p0_main.tscn"))

func begin_session(id: String, selected_condition: String, notes: String) -> bool:
	if id.strip_edges().is_empty() or notes.strip_edges().is_empty() or not CONDITIONS.has(selected_condition):
		message.text = "请填写测试者编号和实际设备，并选择监听条件。"
		return false
	tester_id = id.strip_edges()
	device_notes = notes.strip_edges()
	condition = selected_condition
	trial_index = 0
	saved_formal = 0
	var directory := "user://人测结果"
	DirAccess.make_dir_recursive_absolute(directory)
	var suffix := str(Time.get_unix_time_from_system())+"_"+str(Time.get_ticks_usec())
	result_path = directory.path_join(("automation_" if diagnostic_mode else "human_")+condition+"_"+suffix+".csv")
	result_file = FileAccess.open(result_path,FileAccess.WRITE)
	result_file.store_csv_line(PackedStringArray(FIELDS))
	result_file.flush()
	_listen()
	return true

func _listen() -> void:
	answer_direction = ""
	answer_type = ""
	last_skips = 0
	playing = true
	panel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	audio = Fixtures.render(trials[trial_index],condition)
	if output_enabled:
		player.begin(audio["pcm"])

func _ended(skips: int) -> void:
	playing = false
	last_skips = skips
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.show()
	_clear()
	var trial: Dictionary = trials[trial_index]
	_label(("练习" if trial["stage"] == "practice" else "正式")+"第"+str(trial["trial_id"])+"题")
	message = _label("声音已结束，请同时回答方位和类型。"+(" 本题有音频下溢，记录将标为无效。" if skips > 0 else ""))
	for item in [["左","left"],["中","center"],["右","right"]]:
		_button(item[0],_direction.bind(item[1]))
	for item in [["抖","minor"],["刺","tritone"]]:
		_button(item[0],_type.bind(item[1]))
	submit = _button("提交两项答案",_submit)
	submit.disabled = true

func _direction(value: String) -> void:
	answer_direction = value
	_selected()

func _type(value: String) -> void:
	answer_type = value
	_selected()

func _selected() -> void:
	message.text = "所选："+{"left":"左","center":"中","right":"右"}.get(answer_direction,"未选方位")+" / "+{"minor":"抖","tritone":"刺"}.get(answer_type,"未选类型")
	submit.disabled = answer_direction.is_empty() or answer_type.is_empty()

func _submit() -> void:
	if playing or answer_direction.is_empty() or answer_type.is_empty():
		return
	var trial: Dictionary = trials[trial_index]
	var correct: bool = answer_direction == trial["truth_direction"] and answer_type == trial["truth_type"]
	var row: Array = [Fixtures.protocol()["version"],tester_id,trial["stage"],trial["trial_id"],trial["seed"],trial["layout_id"],condition,device_notes,
		audio["assist_state"],audio["device_mode"],trial["truth_direction"],trial["truth_type"],answer_direction,answer_type,1 if correct else 0,last_skips,
		"automation" if diagnostic_mode else "human",audio["pcm_sha256"],"invalid_underrun" if last_skips > 0 else ""]
	var strings := PackedStringArray()
	for value in row:
		strings.append(str(value))
	result_file.store_csv_line(strings)
	result_file.flush()
	if trial["stage"] == "formal":
		saved_formal += 1
	_clear()
	if trial["stage"] == "practice":
		_label(("答对。" if correct else "这题未同时答对。")+" 真值："+{"left":"左","center":"中","right":"右"}[trial["truth_direction"]]+" / "+{"minor":"抖","tritone":"刺"}[trial["truth_type"]])
	else:
		_label("正式答案已记录。")
	_button("继续",_next)

func _next() -> void:
	trial_index += 1
	if trial_index < trials.size():
		_listen()
	else:
		result_file.close()
		_clear()
		_label("本组完成："+str(saved_formal)+"题正式。")
		_label("结果："+ProjectSettings.globalize_path(result_path))
		_label("这只完成一个测试者/设备条件；须独立统计3人各10题，不能从工具运行自动宣布听觉PASS。")
		_button("新测试者 / 新设备条件",_setup)
		_button("返回声音原型",func() -> void: get_tree().change_scene_to_file("res://scenes/p0_main.tscn"))

func diagnostic_state() -> Dictionary:
	return {"playing":playing,"panel":panel.visible,"mouse_mode":Input.mouse_mode,"trial_index":trial_index,
		"sample_count":audio.get("pcm",PackedVector2Array()).size(),"skips":player.underruns,
		"condition":condition,"origin":"automation" if diagnostic_mode else "human","result_path":result_path,"saved_formal":saved_formal}

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		player.stop_output()
		playing = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		panel.show()
		if result_file != null:
			result_file.close()
		_clear()
		_label("会话已中止；缺题记录不能通过正式验收。")
		_button("返回准备",_setup)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(player):
		player.stop_output()
	if result_file != null:
		result_file.close()
