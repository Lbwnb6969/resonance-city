extends SceneTree
## Round 151 P10: a stale reservation is rejected with an audible, actionable
## reason instead of leaving the player with a false "will land" message.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Demo = preload("res://scripts/ui/continuous_valley_demo.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
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
		if not site.has("reservation_id") and not site.has("public_id"): return site
	return {}

func _freeze_growth(world: ContinuousWorld) -> void:
	for family in world.families.values(): family["next_growth_phrase"] = 1000

func _cross_boundary(model: ContinuousAudioModel) -> int:
	var boundary: int = model.next_boundary
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	model.render_block({},boundary-1,2,rate)
	return boundary

func _run() -> void:
	var city := World.new()
	city.build_starter("bright")
	_freeze_growth(city)
	var site := _pick(city)
	_check(not site.is_empty(),"conflict_candidate_exists")
	if site.is_empty():
		quit(1)
		return
	var p := _position(site)
	var model := Model.new(city,1.3409036)
	var queued := model.submit({"kind":"reserve","position":[p.x,p.y]})
	_check(bool(queued.get("accepted",false)),"conflict_reserve_is_accepted_before_boundary")
	# Simulate a natural/other-authoritative occupation after preview but before
	# the phrase. The reservation must fail atomically and leave no false space.
	var family_id := "conflict-family"
	city.families[family_id] = {"root":"","created_phrase":city.phrase_index,"expression":"bright","next_growth_phrase":1000}
	var building_id := city._birth(p,48,family_id,true,city.phrase_index*int(city.cfg["timing"]["phrase_frames"]))
	city.families[family_id]["root"] = building_id
	_cross_boundary(model)
	_check(city.planning_reservations.is_empty(),"conflict_does_not_leave_reservation")
	var rejected: Dictionary = {}
	for event in city.events:
		if str(event.get("kind","")) == "planning_rejected": rejected = event
	_check(not rejected.is_empty(),"conflict_emits_rejection_event")
	_check(str(rejected.get("operation_kind","")) == "reserve","conflict_event_keeps_operation_kind")
	_check(str(rejected.get("source_site_id","")) == str(site.get("source_site_id","")),"conflict_event_keeps_source_identity")
	_check(rejected.get("position",[]).size() == 2,"conflict_event_keeps_position")
	_check(not str(rejected.get("reason","")).is_empty(),"conflict_event_explains_next_step")
	_check(str(rejected.get("reason","")).contains("占用"),"conflict_reason_names_geometry_change")
	var restored := Model.from_state(model.capture_state())
	var restored_rejection: Dictionary = {}
	for event in restored.world.events:
		if str(event.get("kind","")) == "planning_rejected": restored_rejection = event
	_check(restored_rejection.get("reason","") == rejected.get("reason",""),"conflict_reason_survives_state_roundtrip")
	var message := Demo.new()._planning_rejection_message(rejected)
	_check(message.contains("留地没有落定") and message.contains("介入槽"),"ui_message_exposes_rejection_and_next_step")
	var passed := checks.values().all(func(ok: bool) -> bool: return ok)
	print("ROUND151_P10_CONFLICT ",JSON.stringify({"passed":passed,"checks":checks}))
	quit(0 if passed else 1)

