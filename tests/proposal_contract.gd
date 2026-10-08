class_name ProposalContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")

func _initialize() -> void:
	call_deferred("_run")

func fixture() -> Array:
	return [Schema.create("home","residential",Vector2i(2,6)),
		Schema.create("factory","industrial",Vector2i(3,6)),
		Schema.create("shop","commercial",Vector2i(4,6))]

func _run() -> void:
	var selected := Contract.selected_case("verbs")
	var test := Contract.new("PROPOSAL-001", selected)
	test.check(selected == "verbs", "Supported case: verbs")
	var city := Session.new(fixture(),"2026100800000001")
	var period := city.transport.phrase_frame(1)
	var retune := {"proposal_id":"p0:0:factory:retune","target":55}
	var before := city.snapshot()
	var queued := city.request(retune,period-1,period-2000.0)
	test.check(queued["accepted"] and queued["frame"] == period, "Industrial G3 option is legal and future-quantized")
	test.check(city.city == before["city"], "Confirmation cannot mutate city before the boundary")
	test.check(not city.request({"proposal_id":"p0:0:factory:retune","target":54},period-1,0.0)["accepted"], "No free pitch input or unchanged pitch")
	test.check(city.pending["target"] == 55, "Rejected selection preserves the valid pending choice")
	var retuned := city.settle(period)
	test.check(city.city[1]["type"] == "industrial" and city.city[1]["current_midi"] == 55, "Retune preserves industrial identity")
	test.check(retuned["intervention_deltas"]["factory"] == -10.0 and city.city[1]["vitality"] == 46.0, "Retune cost and new-neighbor deltas settle once")
	test.check(city.city[0]["vitality"] == 56.0 and city.city[2]["vitality"] == 51.0, "New fifth and neutral minor third drive actual vitality")
	test.check(city.pending.is_empty(), "Consumed intervention cannot replay")
	var moved := Session.new(fixture(),"2026100800000001")
	var move := {"proposal_id":"p0:0:factory:relocate","target":[12,12]}
	test.check(not moved.request({"proposal_id":"p0:0:factory:relocate","target":[2,6]},0,0.0)["accepted"], "Occupied target rejected")
	test.check(not moved.request({"proposal_id":"p0:0:factory:relocate","target":[16,6]},0,0.0)["accepted"], "Out-of-map target rejected")
	moved.request(retune,period-10,period-2000.0)
	moved.request(move,period-10,period-2000.0)
	var relocated := moved.settle(period)
	test.check(relocated["choice"]["verb"] == "relocate" and moved.city[1]["current_midi"] == 54, "Latest confirmation replaces previous action without a second cost")
	test.check(moved.city[0]["vitality"] == 51.0 and relocated["after_r"] == 100.0, "Original neighbor loses relationship; R uses new graph")
	test.check(moved.silent_until["factory"] == period*2, "Relocate silent exactly one phrase")
	moved.settle(period*2)
	test.check(moved.silent_until.is_empty(), "Restore due migration before next phrase settles")
	test.check(moved.request({"proposal_id":"p0:0:factory:relocate","target":[13,12]},period*2+1,period*2-2000.0).get("frame",-1) == period*3, "Rendered boundary cannot be rewritten")
	var canceled := Session.new(fixture(),"2026100800000001")
	canceled.request(retune,period-1,0.0)
	canceled.cancel_pending()
	var canceled_result := canceled.settle(period)
	test.check(canceled_result["choice"].is_empty() and canceled.city[1]["current_midi"] == 54, "Canceled confirmation has no intervention cost")
	var refresh := Session.new(fixture(),"2026100800000001")
	# Keep the graph healthy, so catalog timing is measured independently of collapse.
	refresh.request(retune,period-1,0.0)
	for index in range(1,5):
		refresh.settle(period*index)
	test.check(refresh.refresh_cycle == 1 and refresh.proposal("p0:0:factory:retune").is_empty(), "Catalog refreshes at 64 audio seconds")
	test.check(refresh.is_on_grid(period-1764.0) and refresh.is_on_grid(period+1764.0), "Optional landing includes both 80ms limits")
	test.check(not refresh.is_on_grid(period+1765.0), "Quantization does not turn a late input into a landing")
	var live := Model.new(Session.new(fixture(),"2026100800000001"))
	var output := Renderer.new()
	output.source = live._mix_frame
	output.state = live.synth.initial_state()
	output.transport.rendered_frames = period-1
	live.session.request(move,period-1,period-2000.0)
	output.render(1)
	test.check(live.session.city[1]["footprint"] == [[3,6]], "PCM immediately before boundary keeps old location")
	output.render(1)
	test.check(live.session.city[1]["footprint"] == [[12,12]], "First boundary sample submits new graph")
	var silent_tracks := live.synth.render_tracks(output.state,period+1,output.transport.sample_rate)
	test.check(silent_tracks["District_factory_Drone"] == Vector2.ZERO and silent_tracks["District_factory_Rhythm"] == Vector2.ZERO, "Actual relocated output is silent")
	test.check(silent_tracks["District_home_Drone"] != Vector2.ZERO, "Migration does not suppress unrelated district")
	var old_phase: float = output.state["_phase_factory"]
	output.transport.rendered_frames = period*2
	output.render(1)
	test.check(live.synth.silent_until.is_empty() and float(output.state["_phase_factory"]) != 0.0 and float(output.state["_phase_factory"]) != old_phase, "Next boundary restores continuously advanced oscillator")
	var restored_tracks := live.synth.render_tracks(output.state,period*2+1,output.transport.sample_rate)
	test.check(restored_tracks["District_factory_Drone"] != Vector2.ZERO and live.synth.routing[1]["stereo"].y > live.synth.routing[1]["stereo"].x, "Restored migration follows new right-hand pan")
	var saved := refresh.snapshot()
	var copy := refresh.fork()
	copy.rng.bounded("events",100)
	copy.city[0]["vitality"] = 0
	test.check(refresh.snapshot() == saved, "Fork owns city and all five RNG counters")
	test.details = {"retune_v":retuned["after"][1]["vitality"],"relocation_end_frame":period*2,
		"full_error_gameplay":"PENDING P1 U06","boundary_order":"restore, commit, R, V+cost, cap, clamp"}
	test.finish(self, "P0 approved exact choices and optional landing only; no P1 pitch-error mechanics")
