extends SceneTree
## Round 174: a real park/civic choice is carried to the audible theme event
## that it changes.  The map projection can therefore point at the authored
## public site using the physical audible frame; no new voice or save field is
## introduced.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const SEED := "2026100900000062"
const EVIDENCE_PATH := "res://验证记录/round174_公共空间活动/public_space_activity_contract.json"

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _candidate(city: World,cid: String) -> Dictionary:
	for lot in city.lots:
		if not str(lot.get("occupant","" )).is_empty() or str(lot.get("community_id","")) != cid: continue
		var position := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var site := city.planning_candidate(position)
		if site.is_empty() or not bool(site.get("allowed",false)) or site.has("public_id"): continue
		if Planning.public_access(city,site).is_empty(): continue
		return site
	return {}

func _render_until(model: Model,state: Dictionary,finish: int,rate: int) -> void:
	while model.rendered_until < finish:
		var at := model.rendered_until
		model.render_block(state,at,mini(1024,finish-at),rate)

func _run() -> void:
	var city := World.new(SEED,true,"river_valley")
	city.build_rework_starter("bright")
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var rate := int(city.cfg["timing"]["sample_rate"])
	var cid := "west-1"
	check(bool(Rules.status(city,cid).get("theme_eligible",false)),"mature_theme_community_is_real")
	var site := _candidate(city,cid)
	check(not site.is_empty(),"real_empty_lot_has_legal_public_candidate")
	if site.is_empty():
		_finish()
		return
	var model := Model.new(city,1.0)
	model.enable_music_activity()
	var state: Dictionary = {}
	model.rendered_until = city.phrase_index*phrase
	model.render_block(state,model.rendered_until,64,rate)
	var cursor := model.rendered_until
	var focus := model.submit({"kind":"focus","community":cid})
	check(bool(focus.get("accepted",false)),"focus_keeps_selected_theme_source")
	_render_until(model,state,model.next_boundary-128,rate)
	cursor = model.rendered_until
	var submitted := model.submit({"kind":"park","position":site["position"].duplicate()})
	check(bool(submitted.get("accepted",false)),"real_park_submission_is_queued")
	var boundary := model.next_boundary
	_render_until(model,state,boundary+1,rate)
	var park: Dictionary = {}
	for item in model.world.public_sites:
		if bool(item.get("active",false)) and str(item.get("kind","")) == "park" and str(item.get("community_id","")) == cid:
			if str(item.get("id","")) != "west-park" or city.public_sites.filter(func(s: Dictionary)->bool:return str(s.get("id","")) == "west-park").is_empty():
				park = item
				break
	check(not park.is_empty(),"next_phrase_builds_the_authored_park")
	check(str(model.synth.theme.get("cid","")) == cid,"park_choice_keeps_real_theme_community")
	var first_event: Dictionary = {}
	for node: Dictionary in model.synth.musical_nodes.values():
		if not bool(node.get("active",false)) or bool(node.get("answer",false)): continue
		for event in model.synth.musical_events(node,boundary,phrase,rate):
			if int(event.get("onset",0)) >= boundary:
				first_event = event
				break
		if not first_event.is_empty(): break
	check(not first_event.is_empty(),"next_phrase_has_a_real_lead_event")
	var activity_ids: Array = []
	if not first_event.is_empty():
		var probe := int(first_event["onset"])+256
		_render_until(model,state,probe+1,rate)
		var rows := model.audible_music_activity(probe)
		var row: Dictionary = {}
		for item in rows:
			if str(item.get("event_id","")) == str(first_event.get("event_id","")):
				row = item
				break
		check(not row.is_empty(),"public_feedback_row_is_from_actual_rendered_pcm")
		check(row.get("public_site_ids",[]).has(str(park.get("id",""))),"actual_row_points_to_the_authored_park")
		check(row.get("public_site_kinds",[]).has("park"),"actual_row_reports_park_role")
		for raw_id in row.get("public_site_ids",[]): activity_ids.append(str(raw_id))
		check(activity_ids.has(str(park.get("id",""))),"actual_activity_carries_real_park_identity")
	check(model.synth.last_voice_count <= int(model.synth.score.get("render_voice_limit",70)),"public_feedback_keeps_existing_voice_budget")
	var snapshot := model.capture_state()
	check(not snapshot.get("world",{}).has("public_site_activity") and not snapshot.has("public_site_activity"),"public_feedback_is_runtime_only")
	# Repeat only the metadata handoff for a civic branch.  Round 171 already
	# proves its PCM/arrangement difference; this closes the site-to-row identity
	# for both public roles without duplicating the full three-second render.
	var civic_city := World.new(SEED,true,"river_valley")
	civic_city.build_rework_starter("bright")
	var civic_site := _candidate(civic_city,cid)
	var civic_model := Model.new(civic_city,1.0)
	civic_model.enable_music_activity()
	var civic_state: Dictionary = {}
	civic_model.rendered_until = civic_city.phrase_index*phrase
	civic_model.render_block(civic_state,civic_model.rendered_until,64,rate)
	check(bool(civic_model.submit({"kind":"focus","community":cid}).get("accepted",false)),"civic_focus_keeps_selected_theme_source")
	_render_until(civic_model,civic_state,civic_model.next_boundary-128,rate)
	check(bool(civic_model.submit({"kind":"civic","position":civic_site["position"].duplicate()}).get("accepted",false)),"real_civic_submission_is_queued")
	var civic_boundary := civic_model.next_boundary
	_render_until(civic_model,civic_state,civic_boundary+1,rate)
	var civic: Dictionary = {}
	for item in civic_model.world.public_sites:
		if bool(item.get("active",false)) and str(item.get("kind","")) == "civic" and str(item.get("community_id","")) == cid:
			if str(item.get("id","")) != "west-civic": civic = item; break
	check(not civic.is_empty(),"next_phrase_builds_the_authored_civic_site")
	var civic_event: Dictionary = {}
	for node: Dictionary in civic_model.synth.musical_nodes.values():
		if not bool(node.get("active",false)) or bool(node.get("answer",false)): continue
		for event in civic_model.synth.musical_events(node,civic_boundary,phrase,rate):
			if int(event.get("onset",0)) >= civic_boundary:
				civic_event = event
				break
		if not civic_event.is_empty(): break
	if not civic_event.is_empty(): _render_until(civic_model,civic_state,int(civic_event["onset"])+257,rate)
	var civic_ids: Array = []
	var civic_kinds: Array = []
	for item in civic_model.audible_music_activity(int(civic_event.get("onset",civic_boundary))+256):
		for raw_id in item.get("public_site_ids",[]): civic_ids.append(str(raw_id))
		for raw_kind in item.get("public_site_kinds",[]): civic_kinds.append(str(raw_kind))
	check(civic_ids.has(str(civic.get("id",""))),"actual_activity_carries_real_civic_identity")
	check(civic_kinds.has("civic"),"actual_activity_reports_civic_role")
	_finish_report({"passed":failures.is_empty(),"checks":checks,"failures":failures,"park_id":park.get("id",""),"activity_ids":activity_ids,"first_event":first_event.get("event_id","")})

func _finish() -> void:
	_finish_report({"passed":false,"checks":checks,"failures":failures})

func _finish_report(report: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE_PATH.get_base_dir()))
	var file := FileAccess.open(EVIDENCE_PATH,FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report,"  ")+"\n")
		file.close()
	print("ROUND174_PUBLIC_SPACE_ACTIVITY_CONTRACT ",JSON.stringify(report))
	quit(0 if bool(report.get("passed",false)) else 1)
