extends SceneTree
## Round 153: a City DNA export can continue its AudioPlan on a stable frame.
##
## The test renders a short live prefix, exports the exact runtime model and
## renderer cursor, then asks CityArchive to rebuild the model twice.  Both
## rebuilt paths must start at the saved frame and match the live continuation
## sample-for-sample.  This is a technical replay contract, not a listening
## or aesthetic judgement.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Archive = preload("res://scripts/world/city_archive.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func _run() -> void:
	var world := World.new("2026101100000153",true)
	world.build_starter("bright")
	var model := Model.new(world,1.3409036)
	var rate := int(world.cfg["timing"]["sample_rate"])
	var prefix_state: Dictionary = {}
	# Queue a real beat-level authored event before the prefix.  It remains in
	# AudioPlan and is applied at its exact sound frame during the prefix.
	var response := model.submit({"kind":"response","enabled":false})
	_check(bool(response.get("accepted",false)),"replay_source_event_accepted")
	model.render_block(prefix_state,0,8192,rate)
	var saved_frame := model.rendered_until
	var renderer := {"transport":{"rendered_frames":saved_frame,"audible_frame":float(saved_frame),"pending":[],"accepted_events":[],"approved_proposals":{}},"state":prefix_state.duplicate(true)}
	var directory := "user://round153_audio_plan_replay_%d" % Time.get_ticks_usec()
	var exported := Archive.export_dna({"model":model.capture_state(),"renderer":renderer,"view":{}},directory)
	_check(bool(exported.get("ok",false)),"replay_dna_export_writes")
	var continuation_state := prefix_state.duplicate(true)
	var direct := model.render_block(continuation_state,saved_frame,1024,rate)
	var max_error := -1.0
	if bool(exported.get("ok",false)):
		var path := str(exported["path"])
		var checked := Archive.validate_audio_plan(path)
		_check(bool(checked.get("ok",false)),"replay_audio_plan_validates")
		_check(int(checked.get("rendered_until",-1)) == saved_frame,"replay_cursor_matches_runtime")
		_check(int(checked.get("sound_event_count",0)) >= 1 and int(checked.get("decision_count",0)) >= 1,"replay_keeps_event_path")
		var replay_a := Archive.replay_audio_plan(path,1024)
		var replay_b := Archive.replay_audio_plan(path,1024)
		_check(bool(replay_a.get("ok",false)) and bool(replay_b.get("ok",false)),"replay_rebuilds_runtime")
		if bool(replay_a.get("ok",false)) and bool(replay_b.get("ok",false)):
			var pcm_a: PackedVector2Array = replay_a["pcm"]
			var pcm_b: PackedVector2Array = replay_b["pcm"]
			max_error = 0.0
			for index in range(mini(pcm_a.size(),direct.size())): max_error = maxf(max_error,pcm_a[index].distance_to(direct[index]))
			_check(int(replay_a["summary"]["start_frame"]) == saved_frame,"replay_starts_at_saved_frame")
			# JSON preserves the saved float state at decimal precision; accept the
			# measured sub-1e-6 PCM quantization while requiring the same frame path.
			_check(max_error <= 0.000001,"replay_matches_live_continuation")
			_check(pcm_a == pcm_b and replay_a["summary"]["sha256"] == replay_b["summary"]["sha256"],"replay_is_deterministic")
			_check(int(replay_a["summary"]["frames"]) == 1024 and float(replay_a["summary"]["peak"]) > 0.0,"replay_returns_pcm_summary")
		DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	var passed := checks.values().all(func(ok: bool) -> bool: return ok)
	print("ROUND153_AUDIO_PLAN_REPLAY ",JSON.stringify({"passed":passed,"checks":checks,"saved_frame":saved_frame,"rate":rate,"max_error":max_error}))
	quit(0 if passed else 1)
