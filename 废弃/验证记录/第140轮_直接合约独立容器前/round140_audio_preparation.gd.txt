extends SceneTree
const Preparation = preload("res://scripts/audio/community_audio_preparation.gd")
var checks: Dictionary = {}
var cases: Array = []
var max_error := 0.0
static func reference_script() -> GDScript:
	var synth := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第140轮边界更新优化前/continuous_synth.gd.txt").replace("\r","")
	var base := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第140轮边界更新优化前/district_synth.gd.txt").replace("\r","")
	var methods := "func update_audio_city"+synth.get_slice("func update_audio_city",1).get_slice("func _audibility",0)
	methods = methods.replace("events: Array = []) -> void:","events: Array = [], _preparation: Dictionary = {}) -> void:")
	methods += "func _update_city_data"+base.get_slice("func _update_city_data",1).get_slice("func set_solo",0)
	methods = methods.replace("events: Array) -> void:","events: Array, _preparation: Dictionary = {}) -> void:")
	var script := GDScript.new()
	script.source_code = "extends ContinuousSynth\n"+methods
	assert(script.reload() == OK)
	return script
static func copy_reference(old: ContinuousSynth) -> ContinuousSynth:
	var copy: ContinuousSynth = reference_script().new(old.districts)
	for property in old.get_script().get_script_property_list():
		copy.set(str(property["name"]),old.get(str(property["name"])))
	return copy
func _initialize() -> void: call_deferred("_run")
func _pcm(a: ContinuousAudioModel,b: ContinuousAudioModel,state: Dictionary,other: Dictionary,at: int,count: int,label: String) -> PackedVector2Array:
	var left := a.render_block(state,at,count,22050)
	var right := b.render_block(other,at,count,22050)
	var error := 0.0
	for index in range(count): error = maxf(error,left[index].distance_to(right[index]))
	max_error = maxf(max_error,error)
	checks[label+" PCM"] = error == 0.0
	checks[label+" sample state"] = state == other
	checks[label+" score and DNA"] = a.capture_state() == b.capture_state()
	checks[label+" routes and groups"] = a.synth.routing == b.synth.routing and a.synth.targets == b.synth.targets and a.synth.population == b.synth.population
	checks[label+" voice budget"] = a.synth.max_voice_count <= 70
	return left
func _prepare(model: ContinuousAudioModel) -> void:
	model.enable_background_settlement()
	model.prepare_settlement(model.next_boundary-22050,22050)
	while not model.settlement_job.completed(): await process_frame
	model.prepare_settlement(model.next_boundary-22050,22050)
func _case(city: ContinuousWorld,label: String,late_action: String = "") -> void:
	var twin := city.fork()
	twin.communities = city.communities.duplicate(true)
	var a := ContinuousAudioModel.new(city,1.3409036)
	var b := ContinuousAudioModel.new(twin,1.3409036)
	b.synth = copy_reference(b.synth)
	var state: Dictionary = {}
	var other: Dictionary = {}
	var start := city.phrase_index*a.phrase_frames
	for i in range(3): _pcm(a,b,state,other,start+i*1024,1024,label+" ramp "+str(i))
	# An already audible retune is included in the next structural settlement.
	for model in [a,b]: model.submit({"kind":"retune","id":city.buildings[0]["district_id"],"midi":55})
	var beat: int = a.sound_events[0]["sound_frame"]
	_pcm(a,b,state,other,beat-128,512,label+" earlier retune")
	await _prepare(a)
	await _prepare(b)
	var ready: Dictionary = a.settlement_job.audio_preparation
	var ready_hash := hash(ready)
	if late_action == "retune":
		for model in [a,b]: model.submit({"kind":"retune","id":city.buildings[-1]["district_id"],"midi":57})
	elif late_action == "cancel":
		for model in [a,b]:
			model.submit({"kind":"bridge","enabled":not model.world.bridge})
			model.cancel_pending()
	else:
		# Sound controls and passenger observations do not invalidate growth.
		for model in [a,b]:
			model.submit({"kind":"solo","community":city.buildings[0]["community_id"]})
			model.submit({"kind":"mute","community":city.buildings[-1]["community_id"],"enabled":true})
			model.world.record_transit_flow("west-2",9,7,2)
	var boundary := a.next_boundary
	_pcm(a,b,state,other,boundary-128,512,label+" growth")
	checks[label+" world and late flow"] = a.world.snapshot() == b.world.snapshot() and a.world.transit_flow_pending.is_empty()
	if late_action.is_empty():
		checks[label+" prepared path used"] = int(a.audio_preparation_stats["used"]) > 0 and int(a.settlement_stats["adopted"]) == 1
		checks[label+" immutable worker result"] = hash(ready) == ready_hash
		# Mutable synth membership never aliases the published worker projection.
		var key: String = ready["groups"].keys()[0]
		a.synth.pad_groups[key]["members"].append("private-mutation")
		checks[label+" members owned"] = hash(ready) == ready_hash
		a.synth.pad_groups[key]["members"].pop_back()
		var misses: int = a.audio_preparation_stats["fallback"]
		for model in [a,b]: model.submit({"kind":"retune","id":city.buildings[0]["district_id"],"midi":50})
		beat = a.sound_events[0]["sound_frame"]
		_pcm(a,b,state,other,beat-128,512,label+" late audible pitch")
		checks[label+" late pitch rebuild"] = a.audio_preparation_stats["fallback"] > misses
	else:
		checks[label+" stale task rejected"] = int(a.settlement_stats["adopted"]) == 0 and int(a.settlement_stats["fallbacks"]) == 1
	var saved := a.capture_state()
	var restored := ContinuousAudioModel.from_state(saved)
	checks[label+" preparation excluded from DNA"] = restored.prepared_audio_update.is_empty() and not saved.has("prepared_audio_update")
	var frozen := a.freeze()
	var old_frozen := b.freeze()
	old_frozen.synth = copy_reference(old_frozen.synth)
	checks[label+" preview excludes prepared cache"] = frozen.prepared_audio_update.is_empty()
	var after := a.rendered_until
	var resumed := state.duplicate(true)
	var pcm := _pcm(a,b,state,other,after,512,label+" continuation")
	var restored_pcm := restored.render_block(resumed,after,512,22050)
	checks[label+" exact restore PCM"] = pcm == restored_pcm and state == resumed
	_pcm(frozen,old_frozen,state.duplicate(true),other.duplicate(true),after+512,512,label+" preview")
	for model in [a,b,restored,frozen,old_frozen]: model.close_background_settlement()
	checks[label+" retirement preserves publication"] = hash(ready) == ready_hash
	cases.append({"label":label,"buildings":city.buildings.size(),"preparation":a.audio_preparation_stats,"settlement":a.settlement_stats})
func _direct() -> void:
	var world := ContinuousWorld.new()
	world.build_starter("bright")
	world.landmarks.append({"id":"test-motif","position":[2.0,3.0],"radius":1.2,"motif":[{"midi":48}],"era":1,"frame":0})
	var model := ContinuousAudioModel.new(world)
	var city := model.audio_city()
	var ready := Preparation.build(city,world.cfg)
	var a := ContinuousSynth.new(city)
	var b := copy_reference(a)
	var state: Dictionary = {}
	for district in city: state["_phase_"+district["district_id"]] = 0.123
	var other := state.duplicate(true)
	# Repeated route IDs and same-building stage events retain all matches/order.
	a.routing.append(a.routing[0].duplicate(true))
	b.routing.append(b.routing[0].duplicate(true))
	var events: Array = [{"kind":"upgrade","district_id":city[0]["district_id"],"frame":100,"form":"株"},{"kind":"upgrade","district_id":city[0]["district_id"],"frame":200,"form":"群"}]
	a.update_audio_city(city,state,{},events,ready)
	b.update_audio_city(city,other,{},events)
	checks["direct state and duplicate routes"] = state == other and a.routing == b.routing
	checks["direct groups targets landmark population"] = a.pad_groups == b.pad_groups and a.targets == b.targets and a.population == b.population
	# Priority lookup must preserve first occurrence and ignore active flags as before.
	world.centers.push_front({"community_id":"west-2","level":"secondary","active":false})
	world.centers.append({"community_id":"west-2","level":"primary","active":true})
	a.configure_score(world)
	b.configure_score(world)
	checks["center first occurrence and inactive record"] = a.score_snapshot() == b.score_snapshot() and a.rhythm_nodes == b.rhythm_nodes and a.musical_nodes == b.musical_nodes
	var hash_before := hash(ready)
	a.population["owned"] = 999
	a.targets["owned"] = 1.0
	checks["projection containers remain independent"] = hash(ready) == hash_before
func _run() -> void:
	_direct()
	for expression in ["bright","deep"]:
		var city := ContinuousWorld.new()
		city.build_starter(expression)
		await _case(city,expression+"18")
	for action in ["retune","cancel"]:
		var city := ContinuousWorld.new()
		city.build_starter("bright")
		await _case(city,"late "+action,action)
	await _case(ContinuousWorld.regional_sample(),"regional1511")
	var passed := checks.values().all(func(ok: bool) -> bool: return ok)
	var output := {"passed":passed,"checks":checks,"cases":cases,"pcm_max_error":max_error,
		"scope":"Exact old boundary methods versus worker projection: PCM, phases, DNA, late sound/flow, invalid jobs and independent data",
		"source_sha256":{"synth":FileAccess.get_sha256("res://scripts/audio/continuous_synth.gd"),"model":FileAccess.get_sha256("res://scripts/audio/continuous_audio_model.gd"),"job":FileAccess.get_sha256("res://scripts/world/world_settlement_job.gd"),"preparation":FileAccess.get_sha256("res://scripts/audio/community_audio_preparation.gd"),"routes":FileAccess.get_sha256("res://scripts/audio/district_synth.gd")}}
	FileAccess.open("res://验证记录/连续河谷/第140轮_音频准备合同.json",FileAccess.WRITE).store_string(JSON.stringify(output,"\t")+"\n")
	print("AUDIO_PREPARATION ",JSON.stringify(output))
	quit(0 if passed else 1)
