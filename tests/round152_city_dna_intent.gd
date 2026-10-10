extends SceneTree
## Round 152: a readable City DNA export keeps the player's planning intent.
##
## This follows one real route through the current model: a development
## charter with variation cards, a reserved site converted to a civic facility,
## and a queued river-response switch.  The exported JSON must preserve these
## authored choices and the runtime model must remain playable after import.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Archive = preload("res://scripts/world/city_archive.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func _position(site: Dictionary) -> Vector2:
	var raw: Array = site.get("position",[])
	return Vector2(float(raw[0]),float(raw[1]))

func _pick(world: ContinuousWorld) -> Dictionary:
	for lot in world.lots:
		if not str(lot.get("occupant","")).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var site := world.planning_candidate(p)
		if site.is_empty() or not bool(site.get("allowed",false)): continue
		if site.has("reservation_id") or site.has("public_id"): continue
		if not Planning.public_access(world,site).is_empty(): return site
	return {}

func _freeze_growth(world: ContinuousWorld) -> void:
	for family in world.families.values(): family["next_growth_phrase"] = 1000

func _cross_boundary(model: ContinuousAudioModel) -> int:
	var boundary: int = model.next_boundary
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	model.render_block({},boundary-1,2,rate)
	return boundary

func _run() -> void:
	var city := World.new("2026101100000152",true)
	city.build_starter("bright")
	_freeze_growth(city)
	var site := _pick(city)
	_check(not site.is_empty(),"intent_candidate_has_real_access")
	if site.is_empty():
		quit(1)
		return
	var p := _position(site)
	var community_id := str(site.get("community_id",""))
	var model := Model.new(city,1.3409036)
	var charter := model.submit({"kind":"charter","plan_id":"corridor","community_ids":[community_id],"card_refs":["road_echo","infill_pulse"]})
	_check(bool(charter.get("accepted",false)),"intent_charter_accepts_cards")
	var reserve := model.submit({"kind":"reserve","position":[p.x,p.y]})
	_check(bool(reserve.get("accepted",false)),"intent_reservation_accepts_after_charter")
	_cross_boundary(model)
	_check(city.development_charters.size() == 1,"intent_charter_commits")
	_check(city.development_charters[0].get("card_refs",[]) == ["road_echo","infill_pulse"],"intent_card_refs_commit")
	_check(city.planning_reservations.size() == 1,"intent_reservation_commits")
	var civic := model.submit({"kind":"civic","position":[p.x,p.y]})
	_check(bool(civic.get("accepted",false)),"intent_civic_conversion_accepts")
	_cross_boundary(model)
	var facility := city.public_at(p)
	_check(not facility.is_empty() and str(facility.get("kind","")) == "civic","intent_civic_conversion_commits")
	_check(city.planning_reservations.is_empty(),"intent_conversion_consumes_reservation")
	var response := model.submit({"kind":"response","enabled":false})
	_check(bool(response.get("accepted",false)),"intent_response_switch_queues")
	var response_frame := int(response.get("sound_frame",-1))
	var rate := int(city.cfg["timing"]["sample_rate"])
	if response_frame > 0: model.render_block({},response_frame-1,2,rate)
	_check(not bool(model.synth.response_enabled),"intent_response_switch_applies")

	var directory := "user://round152_city_dna_intent_%d" % Time.get_ticks_usec()
	var exported := Archive.export_dna({"model":model.capture_state(),"renderer":{},"view":{}},directory)
	_check(bool(exported.get("ok",false)),"intent_dna_export_writes")
	if bool(exported.get("ok",false)):
		var path := str(exported["path"])
		var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var plan: Dictionary = payload.get("plan",{}) if payload is Dictionary else {}
		var music: Dictionary = payload.get("music",{}) if payload is Dictionary else {}
		var runtime: Dictionary = payload.get("runtime",{}) if payload is Dictionary else {}
		var runtime_model: Dictionary = runtime.get("model",{})
		var runtime_world: Dictionary = runtime_model.get("world",{})
		_check(plan.get("development_charters",[]).size() == 1,"intent_dna_keeps_charter")
		_check(plan.get("development_charters",[])[0].get("card_refs",[]) == ["road_echo","infill_pulse"],"intent_dna_keeps_cards")
		_check(plan.get("planning_reservations",[]).is_empty(),"intent_dna_keeps_converted_reservation_state")
		_check(plan.get("public_sites",[]).any(func(item: Dictionary) -> bool: return str(item.get("kind","")) == "civic" and bool(item.get("active",false))),"intent_dna_keeps_civic_facility")
		_check(int(music.get("gain",0)) > 0,"intent_dna_keeps_music_mix")
		_check(not bool(runtime_model.get("mix",{}).get("response_enabled",true)),"intent_dna_keeps_response_state")
		_check(runtime.get("model",{}).get("decisions",[]).any(func(item: Dictionary) -> bool: return str(item.get("operation",{}).get("kind","")) == "response"),"intent_dna_keeps_response_decision")
		_check(runtime_world.get("events",[]).any(func(item: Dictionary) -> bool: return str(item.get("kind","")) == "civic"),"intent_dna_keeps_facility_event")
		var imported := Archive.read_dna(path)
		_check(bool(imported.get("ok",false)),"intent_dna_is_readable")
		if bool(imported.get("ok",false)):
			var restored := Model.from_state(imported["model"])
			var restored_facility := restored.world.public_at(p)
			_check(restored.world.development_charters.size() == 1 and restored.world.development_charters[0].get("card_refs",[]) == ["road_echo","infill_pulse"],"intent_import_restores_charter_cards")
			_check(not restored_facility.is_empty() and str(restored_facility.get("kind","")) == "civic" and bool(restored_facility.get("active",false)),"intent_import_restores_civic_facility")
			_check(not bool(restored.synth.response_enabled),"intent_import_restores_response_state")
		DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	var passed := checks.values().all(func(ok: bool) -> bool: return ok)
	print("ROUND152_CITY_DNA_INTENT ",JSON.stringify({"passed":passed,"checks":checks,"buildings":city.buildings.size(),"facility":facility.get("id","")}))
	quit(0 if passed else 1)
