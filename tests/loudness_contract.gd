class_name LoudnessContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Generator = preload("res://scripts/city/city_generator.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Values = preload("res://scripts/spec_values.gd")

func _initialize() -> void:
	call_deferred("_run")

func _save(path: String, pcm: PackedVector2Array) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(pcm.to_byte_array())
	file.close()

func _run() -> void:
	var test := Contract.new("AUDIO-004","loudness")
	var values := Values.load_values()
	var rate := int(values["timing"]["sample_rate"])
	var city: Array = Generator.new().safe_fixture()
	var calibration := Calibration.for_city(city)
	var common_gain := float(calibration["gain"])
	var count := roundi(float(values["loudness"]["duration_seconds"])*rate)
	var directory := "res://验证记录/P0/响度校准"
	DirAccess.make_dir_recursive_absolute(directory)
	var fixtures := {"initial":city.duplicate(true)}
	for district in city:
		if district["type"] == "industrial":
			district["current_midi"] = 48
	fixtures["industrial_to_C"] = city.duplicate(true)
	for district in city:
		district["current_midi"] = 48
	fixtures["all_unison"] = city.duplicate(true)
	city[0]["footprint"] = [[8,6]]
	city[1]["footprint"] = [[8,7]]
	city[1]["current_midi"] = 49
	fixtures["narrowband_minor"] = city.duplicate(true)
	var gd_meters: Dictionary = {}
	for name in fixtures:
		var synth := Synth.new(fixtures[name])
		synth.gain = common_gain
		if name == "narrowband_minor":
			synth.device_mode = "narrowband"
			test.check(synth.assist_routes(synth.initial_state()).size() >= 2,"Peak fixture really includes narrowband companions")
		var pcm := synth.render_block(synth.initial_state(),0,count,rate)
		_save(directory.path_join(name+".f32"),pcm)
		gd_meters[name] = Calibration.integrated(pcm,rate)
		var drone := Synth.new(fixtures[name])
		drone.gain = common_gain
		drone.assist_enabled = false
		drone.active_layers.assign(["drone"])
		_save(directory.path_join(name+"__drone.f32"),drone.render_block(drone.initial_state(),0,count,rate))
	var output: Array = []
	var code := OS.execute("python",[ProjectSettings.globalize_path("res://tools/analyze_loudness.py"),"--directory","验证记录/P0/响度校准"],output,true)
	for line in output:
		print(line)
	test.check(code == 0,"Independent FFmpeg input meter completed")
	if code != 0:
		test.finish(self,"Meter unavailable; no loudness PASS")
		return
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("measurement.json")))
	var tolerance := float(values["loudness"]["tolerance_lu"])
	var target := float(values["mixing"]["target_lufs"])
	test.check(absf(float(report["initial"]["integrated_lufs"])-target) <= tolerance,"Calibrated initial input is -16 LUFS within declared 0.10 LU")
	for name in fixtures:
		test.check(absf(float(gd_meters[name]["lufs"])-float(report[name]["integrated_lufs"])) <= tolerance,"Game meter agrees with independent meter: "+name)
		test.check(float(report[name]["true_peak_dbtp"]) <= -float(values["mixing"]["peak_headroom_db"]),"True peak retains at least 3dB headroom: "+name)
		test.check(float(report[name]["drone_rms_ratio"]) >= float(values["mixing"]["drone_ratio"]),"Production drone RMS ratio meets 25%: "+name)
	var model := Model.new(Session.new(fixtures["initial"],"0000000000000001"))
	model.synth.gain = common_gain
	model.synth.set_mute(str(model.session.city[0]["district_id"]),true)
	model.synth.set_solo(str(model.session.city[1]["district_id"]))
	model.synth.device_mode = "narrowband"
	var copy := model.fork()
	test.check(model.synth.gain == common_gain and copy.synth.gain == common_gain,"Faders/mode/fork preserve one common calibration scalar")
	test.details = {"calibration":calibration,"game_meter":gd_meters,"independent":report,"compensation":"PENDING insufficient-input guard","human":"PENDING"}
	var file := FileAccess.open(directory.path_join("game_calibration.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(test.details,"\t")+"\n")
	file.close()
	test.finish(self,"Initial calibration and four measured peak/RMS states; excludes automatic insufficient-input compensation")
