extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new("2026101000000084",true,"highland_pass")
	world.build_expanded_town()
	var model := Model.new(world)
	var decision := model.submit({"kind":"retune","id":world.buildings[0]["district_id"],"midi":52})
	var traveler := Traveler.new("walker",0)
	traveler.position = Vector2(1.0,2.0)
	traveler.direction = Vector2.RIGHT
	traveler.path = PackedVector2Array([Vector2(1.0,2.0),Vector2(2.0,3.0)])
	traveler.lengths = PackedFloat32Array([1.4142])
	traveler.total = 1.4142
	traveler.distance = 0.4
	traveler.walk_target = Vector2(2.0,3.0)
	var dna_view := {"expression":"bright","starter":true,"town_starter":false,"zoom":0.88,"pan":Vector2.ZERO,"selected_id":"","travelers":{"walker-0":traveler.snapshot()}}
	var directory := "user://resonance_dna_contract"
	var result := Archive.export_dna({"model":model.capture_state(),"view":dna_view},directory)
	check(bool(result.get("ok",false)),"DNA export writes a complete file")
	if bool(result.get("ok",false)):
		var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(result["path"])))
		check(payload is Dictionary and payload.get("schema","") == "resonance_city_dna_v1","DNA has a stable schema")
		check(str(payload.get("seed_hex","")) == "2026101000000084","DNA preserves the world seed")
		check(str(payload.get("terrain",{}).get("family","")) == "highland_pass","DNA preserves terrain family")
		check(payload.get("buildings",[]).size() == world.buildings.size(),"DNA preserves building identities")
		check(payload.get("plan",{}).get("roads",[]).size() >= 120,"DNA preserves expanded roads")
		check(payload.get("plan",{}).get("public_sites",[]).size() >= 16,"DNA preserves public facilities")
		check(payload.get("music",{}).get("theme",{}).get("notes",[]).size() > 0,"DNA preserves authored theme notes")
		check(bool(decision.get("accepted",false)),"AudioPlan source decision is accepted")
		var audio_plan: Dictionary = payload.get("audio_plan",{})
		check(audio_plan.get("schema","") == "resonance_audio_plan_v1","DNA includes a replayable AudioPlan schema")
		check(int(audio_plan.get("phrase_frames",0)) > 0 and int(audio_plan.get("sample_rate",0)) > 0,"AudioPlan preserves timing basis")
		check(audio_plan.get("decisions",[]).size() >= 1 and audio_plan.get("sound_events",[]).size() >= 1,"AudioPlan preserves authored decisions and sound events")
		var imported := Archive.read_dna(str(result["path"]))
		check(bool(imported.get("ok",false)),"DNA exposes a recoverable runtime snapshot")
		var latest := Archive.latest_dna(directory)
		check(bool(latest.get("ok",false)) and str(latest.get("path","")).ends_with(".dna.json"),"DNA archive finds the latest readable export")
		if bool(imported.get("ok",false)):
			var restored := Model.from_state(imported["model"])
			check(restored.world.buildings.size() == world.buildings.size(),"DNA runtime restores building count")
			check(restored.world.rng.seed_hex == world.rng.seed_hex and restored.world.terrain.family == world.terrain.family,"DNA runtime restores seed and terrain")
			check(restored.sound_events.size() == model.sound_events.size() and restored.decisions.size() == model.decisions.size(),"DNA runtime restores audio decisions")
		var restored_traveler := Traveler.new("walker",0)
		restored_traveler.restore(imported["view"]["travelers"]["walker-0"])
		check(restored_traveler.position == Vector2(1.0,2.0) and restored_traveler.path is PackedVector2Array and restored_traveler.path.size() == 2,"DNA runtime restores traveler vector paths")
		DirAccess.remove_absolute(str(result["path"]))
	DirAccess.remove_absolute(directory)
	print("CITY_DNA ",JSON.stringify({"failures":failures,"bytes":result.get("bytes",0),"buildings":world.buildings.size(),"roads":world.roads.size()}))
	quit(0 if failures.is_empty() else 1)
