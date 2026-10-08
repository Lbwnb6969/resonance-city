class_name AudioContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Transport = preload("res://scripts/audio/sample_transport.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var test := Contract.new("AUDIO-002", Contract.selected_case("all"))
	test.check(test.case_name == "all", "Supported case: all")
	for rate in [22050, 44100, 47999]:
		var clock := Transport.new(rate)
		test.check(clock.bar_frame(1) == rate * 2, "2-second bar at rate " + str(rate))
		test.check(clock.phrase_frame(1) == rate * 16, "16-second phrase at rate " + str(rate))
		test.check(clock.beat_frame(10001) == roundi(10001.0 * rate / 2.0), "No accumulated rounded-step drift")
		clock.rendered_frames = rate * 16
		test.check(clock.next_phrase_frame() == rate * 16, "Unwritten boundary is legal")
		clock.rendered_frames += 1
		test.check(clock.next_phrase_frame() == rate * 32, "Rendered boundary is never overwritten")
	var clock := Transport.new()
	clock.rendered_frames = 10000
	var estimate := clock.update_audible(2000, 0.01, 0.03)
	test.check(is_equal_approx(estimate, 8000.0 - clock.sample_rate * 0.02), "Queued PCM and hardware output latency both compensated")
	test.check(clock.update_audible(9000, 0.0, 0.03) == estimate, "Audible estimate never moves backwards")
	test.check(clock.allows_pitch({"type": "industrial", "kind": "initial", "midi": 54}), "Industrial F-sharp remains valid")
	test.check(clock.allows_pitch({"type": "residential", "kind": "rebellion_fixture", "midi": 49}), "Explicit C-sharp rebellion fixture remains valid")
	test.check(not clock.allows_pitch({"type": "residential", "kind": "initial", "midi": 49}), "Normal initial pitch is protected")
	clock.approve_proposal("p1", "industry", "industrial", [55])
	test.check(clock.allows_pitch({"type": "industrial", "kind": "retune", "district_id": "industry", "proposal_id": "p1", "midi": 55}), "Approved industrial retune is accepted")
	test.check(not clock.allows_pitch({"type": "industrial", "kind": "retune", "district_id": "other", "proposal_id": "p1", "midi": 55}), "Another district cannot borrow proposal permission")
	test.check(not clock.allows_pitch({"type": "industrial", "kind": "retune", "district_id": "industry", "proposal_id": "p1", "midi": 56}), "Pitch outside approved proposal is rejected")
	var live := Renderer.new()
	live.source = _fixture_source
	var response := live.transport.queue_pitch({"type": "industrial", "kind": "initial", "district_id": "industry", "midi": 54})
	test.check(response["accepted"] and response["frame"] == 0, "Initial authorized event starts on first writable phrase")
	live.transport.approve_proposal("p1", "industry", "industrial", [55])
	var first := live.render(1)
	response = live.transport.queue_pitch({"type": "industrial", "kind": "retune", "district_id": "industry", "proposal_id": "p1", "midi": 55})
	var boundary := live.transport.phrase_frame(1)
	test.check(response["frame"] == boundary, "Input after frame zero waits for phrase boundary")
	var saved := live.snapshot()
	var remaining := live.render(boundary - 1)
	test.check(live.state["industry"] == 54, "State cannot change before phrase boundary")
	var committed := live.render(1)
	test.check(live.state["industry"] == 55, "State commits before mixing the boundary sample")
	var offline := Renderer.new()
	offline.source = _fixture_source
	offline.restore(saved)
	var offline_pcm := offline.render(boundary)
	remaining.append_array(committed)
	test.check(remaining == offline_pcm, "Live chunked PCM equals offline contiguous PCM sample for sample")
	var bytes := Renderer.pcm16(remaining)
	test.check(bytes == Renderer.pcm16(offline_pcm), "PCM16 export uses identical renderer output")
	test.check(first[0] != Vector2.ZERO and bytes.size() == boundary * 4, "Fixture is non-silent stereo with expected length")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = live.transport.sample_rate
	wav.stereo = true
	wav.data = bytes
	var path := "res://验证记录/P0/时钟fixture.wav"
	test.check(wav.save_to_wav(path) == OK, "WAV evidence written")
	var loaded := AudioStreamWAV.load_from_file(path)
	test.check(loaded != null and loaded.data == bytes, "Saved WAV PCM exactly matches live PCM")
	test.details = {"rates_tested": [22050, 44100, 47999], "pcm_frames": boundary,
		"pcm_bytes": bytes.size(), "wav": path, "fixture": "Transport-only synthetic deterministic source; not production timbre"}
	test.finish(self, "Clock, future quantization, pitch authorization and shared PCM renderer; hardware audible accuracy pending live probe")

func _fixture_source(state: Dictionary, at: int, _rate: int) -> Vector2:
	# A deliberately simple non-musical transport probe; it is not a drone timbre.
	var midi := int(state.get("industry", 0))
	return Vector2(float((at + midi) % 127) / 127.0, float((at + midi) % 113) / 113.0) * 0.1
