extends SceneTree
## A mature, naturally grown community can hear an exact partial public choice.
## The source reservation is created on a real empty lot through production
## request/settlement. No forms, eligibility, notes or growth timing are edited.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const NeighborhoodPlan = preload("res://scripts/world/neighborhood_plan.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const OUT := "res://验证记录/round163_局部规划声音闭环/"
const SEED := "2026101100000150"

var checks: Dictionary = {}
var failures: Array[String] = []
var report: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _fixture(base: World) -> Dictionary:
	for lot in base.lots:
		if not str(lot.get("occupant","")).is_empty() or str(lot.get("community_id","")) != "west-1": continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var candidate := base.planning_candidate(p)
		if candidate.is_empty() or not bool(candidate.get("allowed",false)) or candidate.has("public_id") or Planning.public_access(base,candidate).is_empty(): continue
		var city: World = base.fork()
		var boundary := (city.phrase_index+1)*int(city.cfg["timing"]["phrase_frames"])
		var request := city.request({"kind":"reserve","position":candidate["position"].duplicate()},boundary)
		if not bool(request.get("accepted",false)): continue
		city.settle(boundary)
		var reservation: Dictionary = {}
		for item in city.planning_reservations:
			if str(item.get("source_site_id","")) == str(candidate["source_site_id"]): reservation = item
		if reservation.is_empty(): continue
		var source: PackedVector2Array = reservation["polygon"]
		var center := Planning.bounds(source).get_center()
		var outer := PackedVector2Array()
		for point in source: outer.append(center+(point-center)*0.56)
		var half := Planning.bounds(outer).size*0.16
		var hole := NeighborhoodPlan.box(center,half)
		var rid := str(reservation["reservation_id"])
		var park := PartialPublic.preview_footprints(city,rid,"park",[outer],[hole])
		var civic := PartialPublic.preview_footprints(city,rid,"civic",[outer],[hole])
		if not bool(park.get("accepted",false)) or not bool(civic.get("accepted",false)): continue
		var cid := str(park["target_community_id"])
		if not bool(Rules.status(city,cid).get("theme_eligible",false)): continue
		park["partial"] = true
		park["reservation_id"] = rid
		park["polygon"] = source.duplicate()
		park["position"] = park["target_position"].duplicate()
		park["community_id"] = cid
		return {"city":city,"site":park,"lot_id":str(lot["id"]),"reserve_frame":boundary}
	return {}

func _operation(site: Dictionary,kind: String) -> Dictionary:
	return {"kind":kind,"partial":true,"source_reservation_id":site["source_reservation_id"],
		"source_revision":site["source_revision"],"target_polygons":site["target_polygons"].duplicate(true),
		"target_holes":site["target_holes"].duplicate(true)}

func _difference(a: PackedByteArray,b: PackedByteArray) -> Dictionary:
	if a.is_empty() or a.size() != b.size(): return {"max_abs":INF,"rms":INF}
	var maximum := 0.0
	var square := 0.0
	for offset in range(0,a.size(),2):
		var value := float(a.decode_s16(offset)-b.decode_s16(offset))/32767.0
		maximum = maxf(maximum,absf(value))
		square += value*value
	return {"max_abs":maximum,"rms":sqrt(square/float(a.size()/2))}

func _run() -> void:
	var base := World.new(SEED,true,"river_valley")
	base.build_starter("bright")
	var phrase := int(base.cfg["timing"]["phrase_frames"])
	for index in range(2): base.settle((base.phrase_index+1)*phrase)
	check(base.phrase_index == 2,"starter_matures_through_two_natural_settlements")
	var fixture := _fixture(base)
	check(not fixture.is_empty(),"real_empty_lot_yields_legal_partial_courtyard_in_mature_community")
	if fixture.is_empty():
		report["community_status"] = Rules.status(base,"west-1")
		_finish()
		return
	var city: World = fixture["city"]
	var site: Dictionary = fixture["site"]
	var cid := str(site["community_id"])
	var gain := float(JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"])
	var model := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var state: Dictionary = {}
	var cursor := city.phrase_index*phrase
	model.render_block(state,cursor,64,rate)
	cursor += 64
	# Focus is the existing player action for choosing which eligible community
	# occupies the one theme slot. It is shared by all three public alternatives.
	check(bool(model.submit({"kind":"focus","community":cid}).get("accepted",false)),"existing_focus_action_selects_mature_community")
	while cursor < model.next_boundary-128:
		var count := mini(1024,model.next_boundary-128-cursor)
		model.render_block(state,cursor,count,rate)
		cursor += count
	check(model.synth.focused_community == cid and bool(Rules.status(city,cid)["theme_eligible"]),"authored_focus_and_natural_theme_eligibility_are_live")
	var captured := model.capture_state()
	var phases := state.duplicate(true)
	var comparison := Preview.build(model.freeze(),site,state,cursor)
	check(model.capture_state() == captured and state == phases,"comparison_leaves_live_city_rng_and_phase_unchanged")
	check(comparison["seconds"] == 3 and comparison["gain"] == gain and comparison["source_frame"] == cursor and comparison["boundary_frame"] == model.next_boundary,"all_branches_share_length_gain_and_boundary")
	var variants: Dictionary = comparison["variants"]
	var summaries: Dictionary = {}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for kind: String in ["none","park","civic"]:
		var variant: Dictionary = variants[kind]
		check(bool(variant.get("accepted",false)),kind+"_branch_accepts_real_partial_target")
		if not bool(variant.get("accepted",false)): continue
		var pcm: PackedByteArray = variant["pcm"]
		check(pcm.size() == rate*3*4,kind+"_renders_three_seconds_of_real_stereo_pcm")
		var formal := Model.from_state(captured)
		formal.cancel_planning()
		if kind != "none": check(bool(formal.submit(_operation(site,kind)).get("accepted",false)),kind+"_formal_exact_submission_accepts")
		var formal_state := phases.duplicate(true)
		formal.render_block(formal_state,cursor,model.next_boundary-cursor,rate)
		var formal_pcm := Renderer.pcm16(formal.render_block(formal_state,model.next_boundary,rate*3,rate))
		check(pcm == formal_pcm and variant["score"] == formal.synth.score_snapshot(),kind+"_preview_pcm_and_schedule_equal_formal_continuation")
		check(int(variant["max_voices"]) <= int(model.synth.score["render_voice_limit"]) and float(variant["peak"]) < 0.70795,kind+"_keeps_calibrated_gain_and_existing_voice_budget")
		if kind == "none":
			check(formal.world.planning_reservations.any(func(item: Dictionary)->bool:return str(item.get("reservation_id","")) == str(site["source_reservation_id"])),"none_keeps_real_source_reservation")
		else:
			var anchor: Dictionary = variant["anchor"]
			check(anchor.get("target_polygons",[]) == site["target_polygons"] and anchor.get("hole_polygons",[]) == site["hole_polygons"] and anchor["polygon"] != site["polygon"],kind+"_audible_facility_uses_exact_partial_courtyard")
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.stereo = true
		wav.mix_rate = rate
		wav.data = pcm
		check(wav.save_to_wav(OUT+"mature_"+kind+".wav") == OK,kind+"_exports_real_three_second_wav")
		var summary: Dictionary = variant.duplicate(true)
		summary.erase("pcm")
		summary["pcm_bytes"] = pcm.size()
		var hasher := HashingContext.new()
		hasher.start(HashingContext.HASH_SHA256)
		hasher.update(pcm)
		summary["pcm_sha256"] = hasher.finish().hex_encode()
		summaries[kind] = Archive._json_value(summary)
	var differences := {
		"none_vs_park":_difference(variants["none"].get("pcm",PackedByteArray()),variants["park"].get("pcm",PackedByteArray())),
		"none_vs_civic":_difference(variants["none"].get("pcm",PackedByteArray()),variants["civic"].get("pcm",PackedByteArray())),
		"park_vs_civic":_difference(variants["park"].get("pcm",PackedByteArray()),variants["civic"].get("pcm",PackedByteArray())),
	}
	var changes := false
	for difference: Dictionary in differences.values():
		if is_finite(float(difference["max_abs"])) and float(difference["max_abs"]) > 0.000001: changes = true
	check(changes,"at_least_one_partial_public_choice_changes_real_pcm_in_mature_city")
	report = {"contract":"ROUND163_PARTIAL_AUDIBLE_RESULT/v1","seed":SEED,"lot_id":fixture["lot_id"],
		"steps":["bright starter","two natural settlements","reserve an empty west-1 lot","wait for reserve boundary","draw outer ring at 56% of source extent and centered courtyard at 32% of outer extent","focus the mature source community","compare the same target at next phrase boundary"],
		"source_phrase":city.phrase_index,"reserve_frame":fixture["reserve_frame"],"source_frame":cursor,"boundary_frame":model.next_boundary,
		"source_site":Archive._json_value(site),"source_community_status":Rules.status(city,cid),"sample_rate":rate,"seconds":3,"gain":gain,
		"variants":summaries,"pairwise_pcm_difference":differences,
		"claims":{"formal_exact_pcm":"verified by independent Model.from_state continuation","human_listening":"not claimed","wasapi_device_clock":"not run"}}
	_finish()

func _finish() -> void:
	report["checks"] = checks
	report["failures"] = failures
	report["passed"] = failures.is_empty()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var file := FileAccess.open(OUT+"mature_summary.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report,"  "))
		file.close()
	print("ROUND163_PARTIAL_AUDIBLE_RESULT checks=%d failures=%s differences=%s" % [checks.size(),JSON.stringify(failures),JSON.stringify(report.get("pairwise_pcm_difference",{}))])
	quit(0 if failures.is_empty() else 1)
