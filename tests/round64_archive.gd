extends SceneTree
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
var checks: Dictionary = {}
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world := World.new()
	world.build_starter("bright")
	var model := Model.new(world,1.3409036225)
	var state: Dictionary = {}
	model.render_block(state,0,4410,22050)
	model.submit({"kind":"retune","id":world.buildings[0]["district_id"],"midi":57})
	model.submit({"kind":"bridge"})
	model.submit({"kind":"park","id":"east-park"})
	var lot: Dictionary = world.lots.filter(func(p: Dictionary) -> bool: return p["occupant"] == "")[0]
	model.submit({"kind":"seed","position":lot["center"],"midi":52})
	model.render_block(state,model.rendered_until,11025-model.rendered_until+1024,22050)
	var saved := {"model":model.capture_state(),"renderer":{"state":state.duplicate(true)},"view":{}}
	var directory := "res://验证记录/连续河谷/第64轮_存档探针/"+str(Time.get_ticks_usec())
	var written := Archive.save(saved,"测试版本一",directory)
	var second := Archive.save(saved,"测试版本二",directory)
	var loaded := Archive.latest(directory)
	checks["save_read_and_versions"] = written["ok"] and second["ok"] and loaded["ok"] and written["path"] != second["path"] and DirAccess.get_files_at(directory).size() == 2
	var copy := Model.from_state(loaded["city"]["model"])
	var copy_state: Dictionary = loaded["city"]["renderer"]["state"]
	checks["plan_and_pending_preserved"] = copy.world.snapshot() == world.snapshot() and copy.sound_events == model.sound_events
	checks["rng_and_music_cursor_preserved"] = copy.world.rng.snapshot() == world.rng.snapshot() and copy.rendered_until == model.rendered_until and copy.next_boundary == model.next_boundary
	var difference := 0.0
	var begin := model.rendered_until
	for at in range(begin,model.next_boundary+2048,512):
		var original := model.render_block(state,at,512,22050)
		var resumed := copy.render_block(copy_state,at,512,22050)
		for i in range(original.size()): difference = maxf(difference,(original[i]-resumed[i]).length())
	checks["same_pcm_through_next_growth"] = difference < 0.0000001
	checks["same_future_city_and_rng"] = copy.world.snapshot() == model.world.snapshot()
	# A damaged newest checkpoint cannot replace the previous complete city.
	var bad := directory+"/999999999999_9999999999999999.city"
	FileAccess.open(bad,FileAccess.WRITE).store_string("interrupted checkpoint")
	var recovered := Archive.latest(directory)
	checks["recover_previous_without_deleting_bad_file"] = recovered["ok"] and recovered["skipped"] == 1 and FileAccess.file_exists(bad)
	var evidence := {"checks":checks,"pcm_max_difference":difference,"buildings":model.world.buildings.size(),"decisions":copy.decisions.size(),"archive_directory":directory}
	FileAccess.open("res://验证记录/连续河谷/第64轮_存档.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ARCHIVE ",JSON.stringify(evidence))
	quit(0 if checks.values().all(func(value: bool) -> bool: return value) else 1)
