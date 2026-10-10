extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var evidence := {"vsync_mode":DisplayServer.window_get_vsync_mode(),"screen_refresh_hz":DisplayServer.screen_get_refresh_rate(),"engine_max_fps":Engine.max_fps,"configured_vsync":ProjectSettings.get_setting("display/window/vsync/vsync_mode",1),"configured_fps":ProjectSettings.get_setting("application/run/max_fps",0)}
	FileAccess.open("res://验证记录/连续河谷/第126轮_显示预算.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("DISPLAY_BUDGET ",JSON.stringify(evidence))
	quit()
