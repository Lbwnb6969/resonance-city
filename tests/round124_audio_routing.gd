extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
var checks: Dictionary = {}
var max_pcm_error := 0.0
var cases: Array = []

func _initialize() -> void: call_deferred("_run")

func _old_update() -> String:
	var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第124轮声音路由前/district_synth.gd.txt")
	return "func update_city"+source.get_slice("func update_city",1).get_slice("func set_solo",0)

func _reference_script(continuous: bool) -> GDScript:
	var script := GDScript.new()
	if continuous:
		var source := FileAccess.get_file_as_string("res://scripts/audio/continuous_synth.gd")
		var update := "func update_city"+source.get_slice("func update_city",1).get_slice("func configure_score",0)
		update = update.replace("super(city,state,marks,events.filter","_reference_update_city(city,state,marks,events.filter")
		script.source_code = "extends \"res://scripts/audio/continuous_synth.gd\"\n"+_old_update().replace("func update_city","func _reference_update_city")+update
	else:
		script.source_code = "extends \"res://scripts/audio/district_synth.gd\"\n"+_old_update()
	assert(script.reload() == OK)
	return script

func _replace_synth(model: ContinuousAudioModel, script: GDScript) -> void:
	model.synth = script.new(model.world.buildings)
	model.synth.score = model.world.cfg["score"]
	model.synth.warm_score()
	model.synth.assist_enabled = false
	model.synth.gain = 1.3409036
	model.synth.update_city(model.audio_city(),{}, {},[])
	model.synth.configure_score(model.world)

func _compare(a: ContinuousAudioModel,b: ContinuousAudioModel,name: String) -> void:
	var boundary := a.next_boundary
	for model in [a,b]:
		model.rendered_until = boundary-1024
		var id: String = model.world.buildings[0]["district_id"]
		var cid: String = model.world.buildings[0]["community_id"]
		model.submit({"kind":"retune","id":id,"midi":55})
		model.submit({"kind":"solo","community":cid})
		model.submit({"kind":"mute","community":cid,"enabled":false})
		model.submit({"kind":"bridge"})
	var state: Dictionary = {}
	var expected_state: Dictionary = {}
	var actual := a.render_block(state,boundary-512,2048,22050)
	var expected := b.render_block(expected_state,boundary-512,2048,22050)
	var error := 0.0
	for i in range(actual.size()): error = maxf(error,actual[i].distance_to(expected[i]))
	max_pcm_error = maxf(max_pcm_error,error)
	checks[name+"_pcm"] = error == 0.0 and state == expected_state
	checks[name+"_routes"] = a.synth.routing == b.synth.routing
	checks[name+"_score"] = a.synth.score_snapshot() == b.synth.score_snapshot()
	checks[name+"_world"] = a.world.snapshot() == b.world.snapshot()
	var saved := a.capture_state()
	var restored := Model.from_state(saved)
	var copied_state: Dictionary = state.duplicate(true)
	var resumed := restored.render_block(copied_state,boundary+1536,256,22050)
	var continued := a.render_block(state,boundary+1536,256,22050)
	checks[name+"_restore"] = resumed == continued and copied_state == state
	cases.append({"name":name,"buildings":a.world.buildings.size(),"pcm_error":error,"new_render_ms":a.max_render_ms,"old_render_ms":b.max_render_ms})

func _run() -> void:
	var base_reference := _reference_script(false)
	var continuous_reference := _reference_script(true)
	var fixture: Array = ListeningFixtures.city(JSON.parse_string(FileAccess.get_file_as_string("res://数据/listening_fixtures.json"))["trials"][0])
	var a := DistrictSynth.new(fixture)
	var b: DistrictSynth = base_reference.new(fixture)
	var state: Dictionary = a.initial_state()
	var expected_state: Dictionary = b.initial_state()
	var modified: Array = fixture.duplicate(true)
	modified[0]["current_midi"] = 55
	var duplicate_route := a.routing[0].duplicate(true)
	a.routing.append(duplicate_route)
	b.routing.append(duplicate_route.duplicate(true))
	a.update_city(modified,state)
	b.update_city(modified,expected_state)
	checks["base_duplicate_routes"] = a.routing == b.routing and state == expected_state and a.districts == b.districts
	a.assist_enabled = false
	b.assist_enabled = false
	var pcm := a.render_block(state,0,256,22050)
	var expected := b.render_block(expected_state,0,256,22050)
	checks["base_pcm"] = pcm == expected and state == expected_state
	var child := DistrictSchema.create("round124-child","residential",Vector2i(3,3))
	child["anchor_id"] = fixture[0]["district_id"]
	child["form"] = "胚"
	modified.append(child)
	var events := [{"district_id":child["district_id"],"kind":"upgrade","form":"群","frame":100},{"district_id":child["district_id"],"kind":"upgrade","form":"央","frame":120}]
	a.update_city(modified,state,{},events)
	b.update_city(modified,expected_state,{},events)
	checks["ordered_stage_events"] = a.routing == b.routing and a.routing[-1]["stage"]["form"] == "央" and a.routing[-1]["stage"]["previous"] == "群"
	checks["appended_voice_pcm"] = a.render_block(state,128,256,22050) == b.render_block(expected_state,128,256,22050) and state == expected_state
	for family in ValleyTerrain.family_ids():
		var city := World.new("2026100900000062",true,family)
		city.build_starter("bright")
		var reference := city.fork()
		reference.communities = city.communities.duplicate(true)
		var actual := Model.new(city,1.3409036)
		var old := Model.new(reference,1.3409036)
		_replace_synth(old,continuous_reference)
		_compare(actual,old,family)
	var city := World.new("2026100900000062")
	city.build_expanded_town()
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	for index in range(1,72): city.settle(index*phrase)
	var reference := city.fork()
	reference.communities = city.communities.duplicate(true)
	var actual := Model.new(city,1.3409036)
	var old := Model.new(reference,1.3409036)
	_replace_synth(old,continuous_reference)
	_compare(actual,old,"large607")
	var city_input := actual.audio_city()
	var started := Time.get_ticks_usec()
	actual.synth.update_city(city_input,{})
	var route_new_ms := (Time.get_ticks_usec()-started)/1000.0
	started = Time.get_ticks_usec()
	old.synth.update_city(city_input,{})
	var route_old_ms := (Time.get_ticks_usec()-started)/1000.0
	cases.append({"name":"route_update_only","entities":city_input.size(),"new_ms":route_new_ms,"old_ms":route_old_ms})
	var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"cases":cases,"max_pcm_error":max_pcm_error}
	FileAccess.open("res://验证记录/连续河谷/第124轮_声音路由.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("AUDIO_ROUTING ",JSON.stringify(result))
	quit(0 if result["passed"] else 1)
