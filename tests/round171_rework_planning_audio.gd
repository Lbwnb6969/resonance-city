extends SceneTree
## Round 171 audible rework starter evidence. All qualifications come from
## build_rework_starter's two real settlements. Candidate screening uses actual
## facilities/service and road access; only the selected candidate renders PCM.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Charter = preload("res://scripts/world/development_charter.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Archive = preload("res://scripts/world/city_archive.gd")

const SEED := "2026100900000062"
const OUT := "res://验证记录/round171_可听改编开局/"
const PUBLIC_KINDS := ["none","park","civic"]
const PEAK_LIMIT := 0.70795

var checks: Dictionary = {}
var failures: Array[String] = []
var report: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _candidate(city: World) -> Dictionary:
	var eligible: Dictionary = {}
	var community_ids: Array = city.communities.keys()
	community_ids.sort()
	for raw_id in community_ids:
		var cid := str(raw_id)
		var status := Rules.status(city,cid)
		if bool(status.get("theme_eligible",false)): eligible[cid] = status
	report["eligible_communities"] = eligible
	var best: Dictionary = {}
	var best_priority := -INF
	var examined := 0
	var seen: Dictionary = {}
	# Existing finite lot list bounds the search. No candidate causes audio
	# synthesis or a trial settlement; the chosen source remains the real city.
	for lot in city.lots:
		if not str(lot.get("occupant","" )).is_empty(): continue
		if not eligible.has(str(lot.get("community_id",""))): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var site: Dictionary = city.planning_candidate(p)
		if site.is_empty() or not bool(site.get("allowed",false)) or site.has("public_id"): continue
		var cid := str(site.get("community_id",""))
		if not eligible.has(cid): continue
		var source_id := str(site.get("source_site_id",""))
		if seen.has(source_id): continue
		seen[source_id] = true
		var access := Planning.public_access(city,site)
		if access.is_empty(): continue
		examined += 1
		var facility := Rules.facilities(city,cid)
		var preview := Charter.anchor_preview(city,site,"civic",access)
		var same_community_reachable := 0
		for raw_house in preview.get("covered",[]):
			var house_id := str(raw_house)
			if city.by_id.has(house_id) and str(city.by_id[house_id].get("community_id","")) == cid:
				same_community_reachable += 1
		var priority := 0.0
		# Missing real park flags change existing theme spacing; missing real
		# cultural service can change its existing level/pattern. Prefer those
		# direct same-community relationships without inventing a facility sound.
		if not bool(facility.get("park",false)): priority += 1000.0
		if not bool(facility.get("civic",false)) and same_community_reachable > 0: priority += 500.0
		priority += float(same_community_reachable)
		if priority <= best_priority: continue
		best_priority = priority
		site["planning_scope"] = [cid]
		best = site.duplicate(true)
		report["candidate_screen"] = {"eligible_community_id":cid,"facility_before":facility,
			"same_community_road_reachable_houses":same_community_reachable,"priority":priority,
			"method":"finite legal lots; theme eligibility + actual missing facilities + same-community walking coverage; one PCM comparison"}
	report["candidate_count"] = examined
	return best

func _difference(a: PackedByteArray,b: PackedByteArray) -> Dictionary:
	if a.is_empty() or a.size() != b.size(): return {"comparable":false,"max_abs":0.0,"rms":0.0,"bytes_equal":false}
	var maximum := 0.0
	var square := 0.0
	for offset in range(0,a.size(),2):
		var delta := float(a.decode_s16(offset)-b.decode_s16(offset))/32767.0
		maximum = maxf(maximum,absf(delta))
		square += delta*delta
	return {"comparable":true,"max_abs":maximum,"rms":sqrt(square/float(a.size()/2)),"bytes_equal":a == b}

func _arrangement(score: Dictionary) -> Dictionary:
	# Retain the actual audible scheduling facts; exclude implementation metrics
	# such as voice-count statistics that do not prove a musical arrangement.
	return {"theme":score.get("theme",{}).duplicate(true),
		"rhythms":score.get("rhythms",[]).duplicate(true),
		"response":score.get("response",{}).duplicate(true),
		"pads":score.get("pads",[]).duplicate(true)}

func _sha256(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(bytes)
	return hasher.finish().hex_encode()

func _community_record(variant: Dictionary,cid: String) -> Dictionary:
	for raw in variant.get("opportunity_preview",{}).get("communities",[]):
		if raw is Dictionary and str(raw.get("community_id","")) == cid: return raw
	return {}

func _run() -> void:
	var city := World.new(SEED,true,"river_valley")
	city.build_rework_starter("bright")
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	check(city.phrase_index == 2,"rework_starter_reaches_two_real_phrase_settlements")
	report = {"contract":"ROUND171_REWORK_PLANNING_AUDIO/v1","seed":SEED,"terrain":"river_valley",
		"steps":["bright rework starter through two real settlements","choose a naturally theme-eligible community with an existing legal road-access lot","submit the existing focus action","capture one source before its next boundary","compare none/park/civic for the same footprint","replay each formal continuation from the captured source"],
		"source_phrase":city.phrase_index,"source_houses":city.buildings.size()}
	var site := _candidate(city)
	check(not site.is_empty(),"natural_eligible_community_has_real_road_accessible_public_candidate")
	if site.is_empty():
		_finish()
		return
	var cid := str(site["community_id"])
	check(bool(Rules.status(city,cid).get("theme_eligible",false)),"selected_community_has_unmodified_natural_theme_eligibility")
	var gain := float(JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"])
	var model := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var state: Dictionary = {}
	var cursor := city.phrase_index*phrase
	model.render_block(state,cursor,64,rate)
	cursor += 64
	var focus := model.submit({"kind":"focus","community":cid})
	check(bool(focus.get("accepted",false)),"existing_focus_operation_queues_selected_community")
	while cursor < model.next_boundary-128:
		var count := mini(1024,model.next_boundary-128-cursor)
		model.render_block(state,cursor,count,rate)
		cursor += count
	check(model.synth.focused_community == cid,"focus_action_applies_before_shared_comparison_source")
	check(str(model.synth.theme.get("cid","")) == cid,"naturally_eligible_focused_community_uses_existing_theme_slot")
	var captured := model.capture_state()
	var phases := state.duplicate(true)
	var rng_before: Dictionary = city.rng.snapshot()
	var comparison := Preview.build(model.freeze(),site,state,cursor)
	check(model.capture_state() == captured,"comparison_does_not_mutate_live_city_or_audio_model")
	check(state == phases,"comparison_does_not_mutate_captured_phase_state")
	check(city.rng.snapshot() == rng_before,"comparison_does_not_consume_live_city_rng")
	check(comparison.get("source_version",[]) == Preview.identity(model,site),"all_real_branches_keep_one_source_identity")
	check(int(comparison.get("seconds",0)) == 3 and float(comparison.get("gain",0.0)) == gain and int(comparison.get("source_frame",-1)) == cursor and int(comparison.get("boundary_frame",-1)) == model.next_boundary,"all_real_branches_share_gain_length_source_and_boundary")
	var variants: Dictionary = comparison.get("variants",{})
	var summaries: Dictionary = {}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for kind: String in PUBLIC_KINDS:
		var variant: Dictionary = variants.get(kind,{})
		check(bool(variant.get("accepted",false)),kind+"_branch_accepts_real_public_candidate")
		if not bool(variant.get("accepted",false)):
			summaries[kind] = {"accepted":false,"reason":str(variant.get("reason","missing branch"))}
			continue
		var pcm: PackedByteArray = variant.get("pcm",PackedByteArray())
		check(pcm.size() == rate*3*4,kind+"_branch_contains_real_three_second_stereo_pcm")
		var formal := Model.from_state(captured)
		formal.cancel_planning()
		if kind != "none":
			check(bool(formal.submit({"kind":kind,"position":site["position"].duplicate()}).get("accepted",false)),kind+"_formal_public_submission_accepts_same_candidate")
		var formal_phases := phases.duplicate(true)
		formal.render_block(formal_phases,cursor,model.next_boundary-cursor,rate)
		var formal_pcm := Renderer.pcm16(formal.render_block(formal_phases,model.next_boundary,rate*3,rate))
		var continuation_diff := _difference(pcm,formal_pcm)
		check(pcm == formal_pcm,kind+"_preview_pcm_equals_formal_continuation_bytes")
		check(variant.get("score",{}) == formal.synth.score_snapshot(),kind+"_preview_schedule_equals_formal_continuation")
		check(int(variant.get("max_voices",0)) <= int(model.synth.score.get("render_voice_limit",70)),kind+"_stays_within_existing_render_voice_budget")
		check(float(variant.get("peak",1.0)) < PEAK_LIMIT,kind+"_stays_within_calibrated_peak")
		var anchor: Dictionary = variant.get("anchor",{})
		if kind != "none":
			check(not anchor.is_empty() and str(anchor.get("community_id","")) == cid and str(anchor.get("source_site_id","")) == str(site.get("source_site_id","")),kind+"_audible_public_anchor_is_same_real_candidate")
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.stereo = true
		wav.mix_rate = rate
		wav.data = pcm
		check(wav.save_to_wav(OUT+kind+".wav") == OK,kind+"_exports_real_three_second_wav")
		var record := _community_record(variant,cid)
		summaries[kind] = {"accepted":true,"pcm_bytes":pcm.size(),"pcm_sha256":_sha256(pcm),
			"formal_pcm_difference":continuation_diff,"peak":variant.get("peak",0.0),"max_voices":variant.get("max_voices",0),
			"houses":variant.get("houses",0),"theme_events_per_phrase":variant.get("theme_events",0),
			"arrangement":_arrangement(variant.get("score",{})),"facility":record.get("facility",{}),
			"community_status":record.get("status",{}),"served_houses":variant.get("service",{}).get("served",0),
			"newly_served_houses":variant.get("newly_served_ids",[]).size(),"lost_service_houses":variant.get("lost_service_ids",[]).size(),
			"anchor_id":str(anchor.get("id","")),"anchor_community_id":str(anchor.get("community_id","")),"wav":OUT+kind+".wav"}
	var differences: Dictionary = {}
	var real_public_change := false
	var baseline: Dictionary = variants.get("none",{})
	for kind: String in ["park","civic"]:
		var variant: Dictionary = variants.get(kind,{})
		var delta := _difference(baseline.get("pcm",PackedByteArray()),variant.get("pcm",PackedByteArray()))
		var arranged_differently := _arrangement(baseline.get("score",{})) != _arrangement(variant.get("score",{}))
		delta["arrangement_changed"] = arranged_differently
		differences["none_vs_"+kind] = delta
		if bool(variant.get("accepted",false)) and bool(delta.get("comparable",false)) and float(delta.get("max_abs",0.0)) > 0.000001 and arranged_differently:
			real_public_change = true
	differences["park_vs_civic"] = _difference(variants.get("park",{}).get("pcm",PackedByteArray()),variants.get("civic",{}).get("pcm",PackedByteArray()))
	check(real_public_change,"at_least_one_real_public_choice_changes_pcm_and_existing_arrangement")
	report.merge({"community_id":cid,"community_name":str(city.communities.get(cid,{}).get("name",cid)),
		"source_community_status":Rules.status(city,cid),"source_facility":Rules.facilities(city,cid),
		"candidate":site,"source_frame":cursor,"boundary_frame":model.next_boundary,"sample_rate":rate,"seconds":3,"gain":gain,
		"voice_limit":int(model.synth.score.get("render_voice_limit",70)),"peak_limit":PEAK_LIMIT,
		"variants":summaries,"pairwise_pcm_difference":differences,
		"claims":{"formal_exact_pcm":"verified from independent Model.from_state continuation","human_listening":"not claimed","device_playback":"not run","additional_facility_sound":"none; only existing score scheduling"}},true)
	_finish()

func _finish() -> void:
	report["passed"] = failures.is_empty()
	report["checks"] = checks
	report["failures"] = failures
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var file := FileAccess.open(OUT+"rework_planning_audio.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(Archive._json_value(report),"  ")+"\n")
		file.close()
	print("ROUND171_REWORK_PLANNING_AUDIO ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"candidate_count":report.get("candidate_count",0),"community_id":report.get("community_id",""),"pairwise_pcm_difference":report.get("pairwise_pcm_difference",{})}))
	quit(0 if failures.is_empty() else 1)
