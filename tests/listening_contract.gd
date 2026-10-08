class_name ListeningContractTest
extends SceneTree
const Contract = preload("res://tests/contract_support.gd")
const Fixtures = preload("res://scripts/audio/listening_fixtures.gd")
const Values = preload("res://scripts/spec_values.gd")
const Harmony = preload("res://scripts/city/harmony.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var test := Contract.new("AUDIO-001","listening_tool")
	var protocol := Fixtures.protocol()
	var values := Values.load_values()
	var spec: Dictionary = values["listening"]
	var practice := 0
	var formal := 0
	var counts := {"left":0,"center":0,"right":0,"minor":0,"tritone":0}
	var legal := true
	for trial in protocol["trials"]:
		var city := Fixtures.city(trial)
		var ids: Dictionary = {}
		for district in city:
			ids[district["district_id"]] = district
		var wrong := 0
		var target := ""
		for district in city:
			if int(district["current_midi"]) != int(spec["base_midi"]):
				wrong += 1
				target = district["district_id"]
		var edges := Harmony.new().adjacency(city)
		var target_edges := edges.filter(func(edge: Dictionary) -> bool: return edge["a"] == target or edge["b"] == target)
		legal = legal and city.size() == int(values["city"]["initial_count"]) and wrong == 1 and target_edges.size() == 1
		var cell_x := int(ids[target]["footprint"][0][0])
		var direction := "left" if cell_x <= 4 else "center" if cell_x <= 10 else "right"
		legal = legal and direction == trial["truth_direction"]
		if trial["stage"] == "practice":
			practice += 1
		else:
			formal += 1
			counts[trial["truth_direction"]] += 1
			counts[trial["truth_type"]] += 1
	test.check(practice == int(spec["practice_count"]) and formal == int(spec["formal_count"]),"Exactly six practice and ten formal trials")
	test.check(counts["minor"] == 5 and counts["tritone"] == 5,"Formal types balanced five each")
	test.check(counts["left"] == 4 and counts["center"] == 3 and counts["right"] == 3,"Formal directions balanced four/three/three")
	test.check(legal,"All actual nine-voice fixtures have one target with exactly one same-direction neighbor")
	var standard := Fixtures.render(protocol["trials"][0],"headphones_standard")
	var repeat := Fixtures.render(protocol["trials"][0],"speaker_standard")
	test.check(standard["pcm"] == repeat["pcm"] and standard["pcm_sha256"] == repeat["pcm_sha256"],"Headphone/speaker standard conditions render identical deterministic source")
	test.check(not standard["assist_state"] and standard["device_mode"] == "standard","Formal standard path has helper OFF")
	var pcm: PackedVector2Array = standard["pcm"]
	test.check(pcm.size() == roundi(float(spec["duration_seconds"])*int(standard["sample_rate"])),"Actual trial is exactly eight seconds")
	test.check(pcm[0] == Vector2.ZERO and pcm[pcm.size()-1] == Vector2.ZERO,"Whole-trial equal-power fade has zero endpoints")
	var scene := load("res://scenes/listening_session.tscn") as PackedScene
	var node = scene.instantiate()
	root.add_child(node)
	var protocol_before := protocol.duplicate(true)
	node.diagnostic_mode = true
	var valid: bool = node.begin_session("AUTOMATION_CONTRACT","headphones_standard","tool validation, not a human")
	test.check(valid and node.playing and not node.panel.visible,"Actual listening UI hides every control before playback")
	node.player.stop_output()
	node.playing = false
	node.audio = standard
	node.answer_direction = "left"
	node.answer_type = "minor"
	node._submit()
	var text := FileAccess.get_file_as_string(node.result_path)
	test.check(text.contains("automation") and node.saved_formal == 0,"Automatic UI exercise is clearly marked and cannot count as human formal answers")
	test.check(protocol == protocol_before,"UI answer recording cannot change locked truth/fixture")
	var result := FileAccess.open("res://验证记录/P0/听测工具_自动检查.csv",FileAccess.WRITE)
	result.store_string(text)
	result.close()
	node.queue_free()
	test.details = {"protocol":protocol["version"],"counts":counts,"sample_count":pcm.size(),"human":"PENDING","automation_csv":"听测工具_自动检查.csv"}
	await process_frame
	test.finish(self,"Deterministic real PCM and actual hidden UI; no human score claimed")
