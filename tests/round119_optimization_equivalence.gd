extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const FabricReference = preload("res://废弃/第118轮_全扫描参考/fabric_relations.gd")
const NetworkReference = preload("res://废弃/第118轮_全扫描参考/city_road_network.gd")
const ReferenceModel = preload("res://废弃/第119轮_供音优化前/continuous_audio_model.gd")
var failures: Array[String] = []
var comparisons := 0
var max_pcm_error := 0.0
var max_phase_error := 0.0
var road_candidates := 0
var road_queries := 0
var current_audio_usec := 0
var reference_audio_usec := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for family in ValleyTerrain.family_ids():
		var city := World.new("2026101000000119",true,family)
		city.build_expanded_town()
		for bridge in [false,true]:
			if bridge:
				city.request({"kind":"bridge"},int(city.cfg["timing"]["phrase_frames"]))
				city.settle(int(city.cfg["timing"]["phrase_frames"]))
			var reference := NetworkReference.new()
			reference.rebuild(city.nodes,city.roads,city.terrain)
			for y in range(-5,39,3):
				for x in range(-5,39,3):
					var p := Vector2(x+0.001,y+0.31)
					_same(city.network.access(p,false),reference.access(p),family+" access "+str(p))
					road_candidates += city.network.access_candidates
					road_queries += 1
			for road in city.roads:
				for p in road["path"]:
					_same(city.network.access(p,false),reference.access(p),family+" road tie")
			var cache_size := city.network.access_cache.size()
			for i in range(100):
				city.network.access(Vector2(8.0+i*0.003,8.0+i*0.001),false)
			_same(city.network.access_cache.size(),cache_size,"moving queries do not retain positions")
		print("OPTIMIZATION_EQUIVALENCE roads ",family)
	var city := World.new("2026100900000062")
	city.build_expanded_town()
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	for index in range(1,48): city.settle(index*phrase)
	var scale := city.buildings.size()
	_same(FabricRelations.rebuild(city),FabricReference.rebuild(city),"469 building geometry")
	_same(FabricRelations.rebuild(city),FabricReference.rebuild(city),"warm anchor cache")
	city.settle(48*phrase)
	print("OPTIMIZATION_PROFILE ",JSON.stringify(city.settle_profile)," fabric=",JSON.stringify(city.fabric_profile))
	_same(city.fabric_cache,FabricReference.rebuild(city),"local growth invalidation")
	var saved := city.snapshot()
	city.public_sites[0]["polygon"] = PackedVector2Array([Vector2(4,4),Vector2(12,4),Vector2(12,12),Vector2(4,12)])
	_same(FabricRelations.rebuild(city),FabricReference.rebuild(city),"reserved geometry invalidation")
	city.restore(saved)
	_same(city.fabric_cache,FabricReference.rebuild(city),"snapshot clears geometry cache")
	var model := ContinuousAudioModel.new(city)
	var reference := ReferenceModel.new(city.fork())
	var state: Dictionary = {}
	var old_state: Dictionary = {}
	var rate := int(city.cfg["timing"]["sample_rate"])
	var at := 48*phrase+2048
	for block in range(120):
		if block == 30:
			var cid := str(city.buildings[0]["community_id"])
			model.synth.listener_community = cid
			reference.synth.listener_community = cid
		if block == 60:
			model.synth.listener_community = ""
			reference.synth.listener_community = ""
			model.synth.ducking = true
			reference.synth.ducking = true
		if block == 90:
			model.synth.ducking = false
			reference.synth.ducking = false
		var started := Time.get_ticks_usec()
		var pcm := model.render_block(state,at,512,rate)
		current_audio_usec += Time.get_ticks_usec()-started
		started = Time.get_ticks_usec()
		var old_pcm: PackedVector2Array = reference.render_block(old_state,at,512,rate)
		reference_audio_usec += Time.get_ticks_usec()-started
		for i in range(pcm.size()):
			max_pcm_error = maxf(max_pcm_error,maxf(absf(pcm[i].x-old_pcm[i].x),absf(pcm[i].y-old_pcm[i].y)))
		for key in state:
			if str(key).begins_with("_pad_phase_"):
				var error := absf(float(state[key])-float(old_state[key]))
				max_phase_error = maxf(max_phase_error,minf(error,1.0-error))
		at += 512
	_same(max_pcm_error <= 0.000002,true,"PCM equivalent including virtual voice rotation and ducking")
	_same(max_phase_error <= 0.0000001,true,"virtual phases retained")
	_same(model.synth.max_voice_count <= 70,true,"render voice budget")
	var evidence := {"passed":failures.is_empty(),"comparisons":comparisons,"buildings":scale,"road_queries":road_queries,"mean_road_candidates":float(road_candidates)/road_queries,"current_audio_ms":float(current_audio_usec)/1000.0,"reference_audio_ms":float(reference_audio_usec)/1000.0,"max_pcm_error":max_pcm_error,"max_phase_error":max_phase_error,"max_voices":model.synth.max_voice_count,"failures":failures}
	FileAccess.open("res://验证记录/连续河谷/第119轮_优化等价.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("OPTIMIZATION_EQUIVALENCE ",JSON.stringify(evidence))
	quit(0 if failures.is_empty() else 1)

func _same(actual: Variant,expected: Variant,label: String) -> void:
	comparisons += 1
	if actual != expected:
		failures.append(label)
		if failures.size() <= 8: print("DIFFERENCE ",label)
