extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
class ObservedTraveler extends CityTraveler:
	func advance(city: ContinuousWorld, _seconds: float, _traffic: Array = [], _physical_access: Dictionary = {}) -> Dictionary:
		city.record_transit_flow("west-2",4,2,1)
		return {}

var checks: Dictionary = {}
var cases: Array = []
var max_pcm_error := 0.0

func _initialize() -> void:
	call_deferred("_run")

func _wait_prepared(model: ContinuousAudioModel) -> void:
	while not model.settlement_job.completed(): await process_frame
	model.prepare_settlement(model.next_boundary-22050,22050)

func _compare(actual: ContinuousAudioModel, reference: ContinuousAudioModel, name: String) -> void:
	var boundary := actual.next_boundary
	var identity := actual.world
	var state: Dictionary = {}
	var expected_state: Dictionary = {}
	var block := actual.render_block(state,boundary-512,2048,22050)
	var expected := reference.render_block(expected_state,boundary-512,2048,22050)
	var error := 0.0
	for i in range(block.size()): error = maxf(error,block[i].distance_to(expected[i]))
	max_pcm_error = maxf(max_pcm_error,error)
	checks[name+"_pcm"] = error < 0.000001 and state == expected_state
	checks[name+"_world"] = actual.world.snapshot() == reference.world.snapshot()
	checks[name+"_fabric"] = actual.world.fabric_cache == reference.world.fabric_cache
	checks[name+"_identity"] = actual.world == identity
	checks[name+"_reveal"] = actual.presentation_world(boundary-1).phrase_index == actual.world.phrase_index-1 and actual.presentation_world(boundary).phrase_index == actual.world.phrase_index
	cases.append({"name":name,"buildings":actual.world.buildings.size(),"main_settle_ms":actual.max_settle_ms,
		"sync_settle_ms":reference.max_settle_ms,"background":actual.settlement_stats.duplicate(),"pcm_error":error})

func _run() -> void:
	for family in ValleyTerrain.family_ids():
		var a := World.new("2026100900000062",true,family)
		var b := World.new("2026100900000062",true,family)
		a.build_starter("bright")
		b.build_starter("bright")
		var actual := Model.new(a,1.3409036)
		var reference := Model.new(b,1.3409036)
		for model in [actual,reference]:
			model.world.record_transit_flow("west-2",2,1,0)
		actual.enable_background_settlement()
		actual.prepare_settlement(actual.next_boundary-22050,22050)
		await _wait_prepared(actual)
		_compare(actual,reference,family)
		checks[family+"_adopted"] = actual.settlement_stats["adopted"] == 1
		actual.close_background_settlement()
	# Explicit input still invalidates jobs; passenger observations merge after growth.
	for change in ["late_retune","late_flow","late_cancel"]:
		var a := World.new()
		var b := World.new()
		a.build_starter("bright")
		b.build_starter("bright")
		var actual := Model.new(a)
		var reference := Model.new(b)
		for model in [actual,reference]:
			model.rendered_until = model.next_boundary-100
			if change == "late_cancel": model.submit({"kind":"bridge"})
		actual.enable_background_settlement()
		actual.prepare_settlement(actual.next_boundary-22050,22050)
		await _wait_prepared(actual)
		for model in [actual,reference]:
			if change == "late_retune": model.submit({"kind":"retune","id":model.world.buildings[0]["district_id"],"midi":55})
			elif change == "late_flow": model.world.record_transit_flow("west-2",5,3,1)
			else: model.cancel_pending()
		_compare(actual,reference,change)
		checks[change+"_commit_path"] = actual.settlement_stats["adopted"] == (1 if change == "late_flow" else 0) and actual.settlement_stats["fallbacks"] == (0 if change == "late_flow" else 1)
		actual.prepare_settlement(actual.rendered_until,22050)
		checks[change+"_discard"] = actual.settlement_stats["discarded"] == (0 if change == "late_flow" else 1)
		actual.close_background_settlement()
	# Cancel a running task without leaking worker state into DNA; restoring stays idle.
	var closing_world := World.new()
	closing_world.build_town()
	var closing := Model.new(closing_world)
	closing.enable_background_settlement()
	closing.prepare_settlement(closing.next_boundary-22050,22050)
	closing.world.record_transit_flow("west-2",7,2,1)
	var saved := closing.capture_state()
	closing.close_background_settlement()
	var restored := Model.from_state(saved)
	checks["pending_flow_survives_dna"] = restored.world.transit_flow_pending == closing.world.transit_flow_pending and not restored.world.transit_flow_pending.is_empty()
	checks["close_running_task"] = closing.settlement_job == null and not closing.settlement_enabled
	checks["dna_no_task"] = not restored.settlement_enabled and restored.settlement_job == null and not saved.has("settlement_job")
	checks["retirement_joined"] = closing.retiring_settlements.is_empty()
	# During the queued-audio window travelers use the old view, but observations must reach the live city once.
	var demo: ContinuousValleyDemo = preload("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.set_process(false)
	var old_view: ContinuousWorld = demo.model.world.fork()
	old_view.record_transit_flow("west-1",1,0,0)
	demo.shown_world = old_view
	demo.scenery.rebuild(demo)
	for prop in demo.scenery.props.values():
		if prop.has_meta("traveler"): prop.set_meta("traveler",ObservedTraveler.new())
	var retained_pending := old_view.transit_flow_pending.duplicate(true)
	var live_pending := demo.model.world.transit_flow_pending.size()
	var travelers := 0
	for prop in demo.scenery.props.values():
		if prop.has_meta("traveler") and not prop.get_meta("modern_only",false): travelers += 1
	demo.scenery.sync(demo)
	checks["old_audible_view_retains_history"] = old_view.transit_flow_pending == retained_pending
	var forwarded := demo.model.world.transit_flow_pending.slice(live_pending)
	checks["old_audible_observations_forwarded_once"] = forwarded.size() == travelers and forwarded.all(func(event: Dictionary) -> bool: return event == {"stop_id":"west-2","boarded":4,"alighted":2,"transfers":1})
	demo.scenery.sync(demo)
	checks["old_audible_observations_no_replay"] = demo.model.world.transit_flow_pending.size() == live_pending+travelers*2 and old_view.transit_flow_pending == retained_pending
	demo.queue_free()
	await process_frame
	var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"cases":cases,"max_pcm_error":max_pcm_error}
	FileAccess.open("res://验证记录/连续河谷/第136轮_客流合并与PCM.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("BACKGROUND_SETTLEMENT ",JSON.stringify(result))
	quit(0 if result["passed"] else 1)
