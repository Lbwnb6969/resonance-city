extends SceneTree
## Round 154: malformed AudioPlan exports fail with stable, readable reasons.
##
## The valid fixture uses the real City DNA exporter and renderer cursor.  Each
## malformed copy is then checked through both validation and replay entry
## points; replay must return the same refusal instead of reaching from_state.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Archive = preload("res://scripts/world/city_archive.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func _reason(source: Variant, expected: String) -> bool:
	var checked := Archive.validate_audio_plan(source)
	var replayed := Archive.replay_audio_plan(source,128)
	return not bool(checked.get("ok",false)) and str(checked.get("reason","")) == expected and not bool(replayed.get("ok",false)) and str(replayed.get("reason","")) == expected

func _run() -> void:
	var world := World.new("2026101100000154",true)
	world.build_starter("bright")
	var model := Model.new(world,1.3409036)
	var rate := int(world.cfg["timing"]["sample_rate"])
	var state: Dictionary = {}
	var response := model.submit({"kind":"response","enabled":false})
	model.render_block(state,0,4096,rate)
	var saved_frame := model.rendered_until
	var renderer := {"transport":{"rendered_frames":saved_frame,"audible_frame":float(saved_frame),"pending":[],"accepted_events":[],"approved_proposals":{}},"state":state.duplicate(true)}
	var directory := "user://round154_audio_archive_hardening_%d" % Time.get_ticks_usec()
	var exported := Archive.export_dna({"model":model.capture_state(),"renderer":renderer,"view":{}},directory)
	_check(bool(exported.get("ok",false)),"hardening_fixture_exports")
	if not bool(exported.get("ok",false)):
		print("ROUND154_AUDIO_ARCHIVE_HARDENING ",JSON.stringify({"passed":false,"checks":checks}))
		quit(1)
		return
	var path := str(exported["path"])
	var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(payload is Dictionary,"hardening_fixture_is_json")
	var valid := Archive.validate_audio_plan(payload)
	_check(bool(valid.get("ok",false)),"hardening_valid_plan_accepts_complete_renderer")
	var valid_replay := Archive.replay_audio_plan(payload,128)
	_check(bool(valid_replay.get("ok",false)),"hardening_valid_plan_replays")

	var old_schema: Dictionary = payload.duplicate(true)
	old_schema["audio_plan"]["schema"] = "resonance_audio_plan_v0"
	_check(_reason(old_schema,"AudioPlan版本不支持"),"hardening_rejects_old_schema")
	var bad_plan: Dictionary = payload.duplicate(true)
	bad_plan["audio_plan"] = "broken"
	_check(_reason(bad_plan,"AudioPlan字段格式不支持"),"hardening_rejects_non_dictionary_plan")
	var bad_timing: Dictionary = payload.duplicate(true)
	bad_timing["audio_plan"]["phrase_frames"] = "352800"
	_check(_reason(bad_timing,"AudioPlan时间基准格式不支持"),"hardening_rejects_coerced_timing")
	var bad_event: Dictionary = payload.duplicate(true)
	bad_event["audio_plan"]["sound_events"] = [{"kind":"response","sound_frame":"12"}]
	_check(_reason(bad_event,"AudioPlan声音事件字段格式不支持"),"hardening_rejects_bad_sound_event_field")
	var negative_event: Dictionary = payload.duplicate(true)
	negative_event["audio_plan"]["sound_events"] = [{"kind":"response","sound_frame":-1}]
	_check(_reason(negative_event,"AudioPlan声音事件帧无效"),"hardening_rejects_negative_sound_frame")
	var missing_state: Dictionary = payload.duplicate(true)
	missing_state["runtime"]["renderer"].erase("state")
	_check(_reason(missing_state,"AudioPlan渲染器状态不完整"),"hardening_rejects_missing_renderer_state")
	var missing_transport: Dictionary = payload.duplicate(true)
	missing_transport["runtime"]["renderer"].erase("transport")
	_check(_reason(missing_transport,"AudioPlan渲染器状态不完整"),"hardening_rejects_missing_renderer_transport")
	var malformed_transport: Dictionary = payload.duplicate(true)
	malformed_transport["runtime"]["renderer"]["transport"]["pending"] = ["broken"]
	_check(_reason(malformed_transport,"AudioPlan渲染器队列格式不支持"),"hardening_rejects_bad_renderer_queue")
	var cursor_mismatch: Dictionary = payload.duplicate(true)
	cursor_mismatch["runtime"]["renderer"]["transport"]["rendered_frames"] = saved_frame+1
	_check(_reason(cursor_mismatch,"AudioPlan与PCM渲染游标不一致"),"hardening_rejects_cursor_mismatch")
	var malformed_model: Dictionary = payload.duplicate(true)
	malformed_model["runtime"]["model"]["world"] = []
	_check(_reason(malformed_model,"AudioPlan缺少WorldSnapshot"),"hardening_rejects_bad_world_snapshot")
	var malformed_runtime: Dictionary = payload.duplicate(true)
	malformed_runtime["runtime"] = []
	_check(_reason(malformed_runtime,"AudioPlan运行时容器格式不支持"),"hardening_rejects_bad_runtime_container")

	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	var passed := checks.values().all(func(ok: bool) -> bool: return ok)
	print("ROUND154_AUDIO_ARCHIVE_HARDENING ",JSON.stringify({"passed":passed,"checks":checks,"saved_frame":saved_frame}))
	quit(0 if passed else 1)
