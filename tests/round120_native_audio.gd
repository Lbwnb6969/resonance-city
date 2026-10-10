extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ClassDB.class_exists("CityPadMixer"):
		push_error("CityPadMixer extension missing")
		quit(1)
		return
	var world := World.new()
	world.build_expanded_town()
	var phrase := int(world.cfg["timing"]["phrase_frames"])
	for index in range(1,48): world.settle(index*phrase)
	var native := Model.new(world,1.3409036)
	var reference := Model.new(world.fork(),1.3409036)
	reference.synth.native_enabled = false
	var state: Dictionary = {}
	var old_state: Dictionary = {}
	var native_usec := 0
	var script_usec := 0
	var max_pcm_error := 0.0
	var max_state_error := 0.0
	var count := 512
	var start := 47*phrase+1024
	for index in range(120):
		if index in [15,30,45,60]:
			for model in [native,reference]:
				model.rendered_until = start+index*count
				if index == 15: model.submit({"kind":"solo","community":world.buildings[0]["community_id"]})
				elif index == 30: model.submit({"kind":"solo","community":""})
				elif index == 45: model.submit({"kind":"mute","community":world.buildings[1]["community_id"],"enabled":true})
				else: model.submit({"kind":"retune","id":world.buildings[0]["district_id"],"midi":55})
		if index == 75:
			for model in [native,reference]:
				for group in model.synth.pad_groups.values(): group["stereo"] = Vector2(0.92,0.12)
		if index == 90:
			for model in [native,reference]: model.synth.ducking = true
		if index == 105:
			# A live DNA restore must continue with the same packed phase/envelopes.
			native = Model.from_state(native.capture_state())
		var timer := Time.get_ticks_usec()
		var actual := native.render_block(state,start+index*count,count,22050)
		native_usec += Time.get_ticks_usec()-timer
		timer = Time.get_ticks_usec()
		var expected := reference.render_block(old_state,start+index*count,count,22050)
		script_usec += Time.get_ticks_usec()-timer
		for sample in range(count): max_pcm_error = maxf(max_pcm_error,actual[sample].distance_to(expected[sample]))
		for key in state:
			if state[key] is float: max_state_error = maxf(max_state_error,absf(state[key]-old_state[key]))
			elif state[key] is Vector2: max_state_error = maxf(max_state_error,state[key].distance_to(old_state[key]))
	if max_pcm_error > 0.000001: failures.append("PCM native/reference divergence")
	if max_state_error > 0.000001: failures.append("phase/envelope/stereo divergence")
	if native.synth.max_voice_count > 70: failures.append("voice budget")
	var evidence := {"passed":failures.is_empty(),"buildings":world.buildings.size(),"samples":120*count,"max_pcm_error":max_pcm_error,"max_state_error":max_state_error,"native_ms":native_usec/1000.0,"script_ms":script_usec/1000.0,"max_voices":native.synth.max_voice_count,"failures":failures}
	FileAccess.open("res://验证记录/连续河谷/第120轮_原生合成.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("NATIVE_AUDIO ",JSON.stringify(evidence))
	quit(0 if failures.is_empty() else 1)
