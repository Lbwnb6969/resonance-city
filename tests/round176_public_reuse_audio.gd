extends SceneTree
## Same-source public reuse branches versus their real formal continuation.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Reuse = preload("res://scripts/world/public_site_reuse.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const OUTPUT := "res://验证记录/round176_公共空间原位改用/public_reuse_audio.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var details: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _sha(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _difference(a: PackedByteArray,b: PackedByteArray) -> Dictionary:
	var maximum := 0.0
	var square := 0.0
	for offset in range(0,a.size(),2):
		var delta := float(a.decode_s16(offset)-b.decode_s16(offset))/32767.0
		maximum = maxf(maximum,absf(delta))
		square += delta*delta
	return {"max_abs":maximum,"rms":sqrt(square/float(a.size()/2)),"bytes_equal":a == b}

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	var gain := float(JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"])
	var model := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var phases: Dictionary = {}
	var cursor := city.phrase_index*phrase
	model.render_block(phases,cursor,64,rate)
	cursor += 64
	model.submit({"kind":"focus","community":"west-1"})
	while cursor < model.next_boundary-128:
		var count := mini(1024,model.next_boundary-128-cursor)
		model.render_block(phases,cursor,count,rate)
		cursor += count
	var site := Reuse.candidate(city,"west-civic")
	check(bool(site.get("allowed",false)),"existing_culture_site_is_a_real_reuse_candidate")
	if not bool(site.get("allowed",false)):
		_finish()
		return
	var pending_reuse := model.submit(Preview._operation(site,"park"))
	var transit := model.submit({"kind":"transit_line","stop_positions":[city.nodes["west-1"].duplicate(),city.nodes["west-2"].duplicate()],"source_topology":city.network.topology})
	check(bool(pending_reuse.get("accepted",false)) and bool(transit.get("accepted",false)),"same_site_reuse_and_independent_authored_transit_are_real_queued_intents")
	var source := model.capture_state()
	var before_phases := phases.duplicate(true)
	var rng := city.rng.snapshot()
	var comparison := Preview.build(model,site,phases,cursor)
	check(model.capture_state() == source and phases == before_phases and city.rng.snapshot() == rng,"three_branch_preview_keeps_live_model_phases_and_rng")
	check(comparison.get("source_version",[]) == Preview.identity(model,site),"reuse_branches_share_the_current_source_identity")
	var variants: Dictionary = comparison.get("variants",{})
	for kind: String in ["none","park","civic"]:
		var variant: Dictionary = variants.get(kind,{})
		check(bool(variant.get("accepted",false)),kind+"_reuse_branch_accepts_existing_footprint")
		if not bool(variant.get("accepted",false)): continue
		var pcm: PackedByteArray = variant["pcm"]
		check(pcm.size() == rate*3*4,kind+"_reuse_branch_has_three_seconds_stereo_pcm")
		var formal := Model.from_state(source)
		formal.enable_music_activity()
		formal.cancel_public_reuse(str(site["public_id"]))
		if kind != "none":
			check(bool(formal.submit(Preview._operation(site,kind)).get("accepted",false)),kind+"_formal_reuse_accepts_same_choice")
		var formal_phases := before_phases.duplicate(true)
		formal.render_block(formal_phases,cursor,model.next_boundary-cursor,rate)
		var formal_pcm := Renderer.pcm16(formal.render_block(formal_phases,model.next_boundary,rate*3,rate))
		check(pcm == formal_pcm and variant["score"] == formal.synth.score_snapshot(),kind+"_reuse_preview_equals_formal_pcm_and_schedule")
		check(formal.world.authored_transit_lines.size() == 1,kind+"_reuse_branch_preserves_independent_authored_transit")
		var anchor: Dictionary = variant.get("anchor",{})
		check(str(anchor.get("id","")) == "west-civic" and anchor.get("position",[]) == site["position"] and anchor.get("polygon",PackedVector2Array()) == site["polygon"],kind+"_reuse_keeps_real_site_identity_position_and_footprint")
		check(int(variant["max_voices"]) <= 70 and float(variant["peak"]) < 0.70795,kind+"_reuse_keeps_voice_budget_and_calibrated_peak")
		var theme_rows := formal.audible_music_activity(float(model.next_boundary)+rate*0.10)
		var public_ids: Array = []
		for row in theme_rows:
			for id in row.get("public_site_ids",[]):
				if not public_ids.has(id): public_ids.append(id)
		check(not theme_rows.is_empty() and public_ids.has("west-civic") == (kind != "park"),kind+"_theme_activity_tracks_actual_cultural_service_after_reuse")
		details[kind] = {"sha256":_sha(pcm),"peak":variant["peak"],"max_voices":variant["max_voices"],
			"served":variant["served_ids"].size(),"newly_served":variant["newly_served_ids"].size(),
			"lost_service":variant["lost_service_ids"].size(),"anchor_kind":anchor.get("kind",""),"theme_public_ids":public_ids}
	if variants.get("none",{}).get("accepted",false) and variants.get("park",{}).get("accepted",false) and variants.get("civic",{}).get("accepted",false):
		var unchanged: PackedByteArray = variants["none"]["pcm"]
		check(unchanged == variants["civic"]["pcm"],"retaining_cultural_use_does_not_expand_or_change_pcm")
		check(unchanged != variants["park"]["pcm"],"cultural_site_to_park_changes_actual_existing_arrangement_pcm")
		details["none_to_park"] = _difference(unchanged,variants["park"]["pcm"])
	_finish()

func _finish() -> void:
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"branches":details,
		"scope":"Production rework starter and actual west-civic footprint; same-source three-second branches and formal continuation. No physical-device or human-listening claim"}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(OUTPUT,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(evidence,"  ")+"\n")
	print("ROUND176_PUBLIC_REUSE_AUDIO "+JSON.stringify(evidence))
	quit(0 if failures.is_empty() else 1)
