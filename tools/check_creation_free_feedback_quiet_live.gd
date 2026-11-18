extends SceneTree
const Scene=preload("res://scenes/city_creation.tscn")
var failures:Array[String]=[]
var demo:Node3D
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	if not ok:failures.append(label);push_error(label)
func run()->void:
	if not OS.get_cmdline_user_args().has("--isolated-session"):quit(1);return
	root.size=Vector2i(1024,768);demo=Scene.instantiate();demo.persistence=false;root.add_child(demo);await process_frame;await process_frame
	demo.toast.hide();demo.toast_time=0.;var juice:Node=demo.get_meta("juice_feedback");juice.clear();var serial:int=juice.serial
	demo._message("♫ 共鸣品质 2 / 5 · 安居花舍");demo._message("♫ 邻屋收到书院送来的艺术挂毯");await create_timer(.6).timeout
	check(not demo.toast.visible and juice.serial==serial,"free success captions and spatial feedback stay quiet")
	demo._message("房屋与道路冲突，请调整落点。");check(demo.toast.visible and demo.toast.text.contains("冲突"),"free actionable failure feedback remains visible")
	check(not demo.has_meta("reward_whisper"),"free quiet path does not create reward whisper producer")
	print("FREE_FEEDBACK_QUIET_LIVE ",JSON.stringify({"ok":failures.is_empty(),"checks":3,"failures":failures}))
	demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
