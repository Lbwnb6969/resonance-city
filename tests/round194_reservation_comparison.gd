extends SceneTree
## Focused proof for the main planning panel's deliberate quiet-space branch.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Starter = preload("res://tests/round171_rework_planning_audio.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")

const SEED := "2026100900000062"
const OUT := "res://验证记录/round194_留地试听/"

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _run() -> void:
	var city: World = World.new(SEED,true,"river_valley")
	city.build_rework_starter("bright")
	var helper = Starter.new()
	var site: Dictionary = helper._candidate(city)
	check(not site.is_empty(),"real_candidate_exists")
	if site.is_empty():
		_finish()
		return
	var cid := str(site.get("community_id",""))
	site["planning_scope"] = [cid]
	var gain_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))
	var gain := float(gain_data.get("gain",0.0))
	var model: Model = Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var state: Dictionary = {}
	var cursor := city.phrase_index*phrase
	model.render_block(state,cursor,64,rate)
	cursor += 64
	var focus: Dictionary = model.submit({"kind":"focus","community":cid})
	check(bool(focus.get("accepted",false)),"focus_accepts_real_community")
	while cursor < model.next_boundary-128:
		var count := mini(1024,model.next_boundary-128-cursor)
		model.render_block(state,cursor,count,rate)
		cursor += count
	var captured := model.capture_state()
	var phases := state.duplicate(true)
	state["include_reserve"] = true
	var comparison: Dictionary = Preview.build(model.freeze(),site,state,cursor)
	var variants: Dictionary = comparison.get("variants",{})
	check(variants.has("none") and variants.has("reserve") and variants.has("park") and variants.has("civic"),"reserve_preview_keeps_existing_three_branches")
	var none: Dictionary = variants.get("none",{})
	var reserve: Dictionary = variants.get("reserve",{})
	check(bool(none.get("accepted",false)),"none_branch_accepted")
	check(bool(reserve.get("accepted",false)),"reserve_branch_accepted")
	var none_pcm: PackedByteArray = none.get("pcm",PackedByteArray())
	var reserve_pcm: PackedByteArray = reserve.get("pcm",PackedByteArray())
	check(none_pcm.size() == rate*3*4 and reserve_pcm.size() == rate*3*4,"reserve_has_three_second_stereo_pcm")
	check(not none_pcm.is_empty() and not reserve_pcm.is_empty(),"reserve_has_no_direct_sound_gap")
	check(reserve.get("newly_served_ids",[]).is_empty(),"reserve_adds_no_public_service_voice")
	var anchor: Dictionary = reserve.get("anchor",{})
	check(str(anchor.get("reservation_id",anchor.get("id",""))).begins_with("reservation-"),"reserve_preview_has_real_reservation_identity")
	check(int(reserve.get("reservation_count",0)) > int(none.get("reservation_count",0)),"reserve_branch_adds_real_reservation")
	check(int(reserve.get("houses",0)) <= int(none.get("houses",0)),"reserve_does_not_add_more_growth_than_none")
	var formal: Model = Model.from_state(captured)
	formal.cancel_planning()
	var submit: Dictionary = formal.submit({"kind":"reserve","position":site["position"].duplicate()})
	check(bool(submit.get("accepted",false)),"formal_reserve_submission_accepts_same_candidate")
	check(formal.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "reserve"),"formal_reserve_persists_until_boundary")
	var formal_phases := phases.duplicate(true)
	formal.render_block(formal_phases,cursor,model.next_boundary-cursor,rate)
	var formal_pcm: PackedByteArray = Renderer.pcm16(formal.render_block(formal_phases,model.next_boundary,rate*3,rate))
	check(formal_pcm == reserve_pcm,"reserve_preview_matches_formal_continuation")
	check(model.capture_state() == captured,"comparison_does_not_mutate_live_model")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var report := {"contract":"ROUND194_RESERVATION_COMPARISON/v1","seed":SEED,"community_id":cid,
		"checks":checks,"failures":failures,"passed":failures.is_empty(),
		"pcm_bytes_equal":none_pcm == reserve_pcm,"none_houses":int(none.get("houses",0)),"reserve_houses":int(reserve.get("houses",0)),
		"reservation_id":str(anchor.get("reservation_id",anchor.get("id",""))),"reservation_count":int(reserve.get("reservation_count",0))}
	var file := FileAccess.open(OUT+"reservation_comparison.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ROUND194_RESERVATION_COMPARISON "+JSON.stringify(report))
	_finish()

func _finish() -> void:
	quit(0 if failures.is_empty() else 1)
