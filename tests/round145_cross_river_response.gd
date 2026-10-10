extends SceneTree
## Round 145 contract: river response routing, next-beat A/B control, and archive isolation.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const RiverResponse = preload("res://scripts/world/river_call_response.gd")
const Archive = preload("res://scripts/world/city_archive.gd")

var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var world := World.new("2026101100000145",true,"river_valley")
	world.build_starter("bright")
	var phrase := int(world.cfg["timing"]["phrase_frames"])
	for index in range(2): world.settle((world.phrase_index+1)*phrase)
	world.bridge = false
	world.rebuild_graph()
	var model := Model.new(world)
	var relations: Array = RiverResponse.pairs(world)
	check(not relations.is_empty(),"river geometry supplies cross-bank response pairs")
	check(not model.synth.response.is_empty(),"lead theme selects a receiving community")
	if model.synth.response.is_empty():
		print("ROUND145_RIVER_RESPONSE FAIL checks=",checks," failures=",JSON.stringify(failures))
		quit(1)
		return
	var response: Dictionary = model.synth.response
	var source_ids: Array = response.get("source_ids",[])
	var receiver_ids: Array = response.get("receiver_ids",[])
	check(int(response.get("generation",0)) == 1,"response is one derived generation")
	check(source_ids.size() == receiver_ids.size() and source_ids.any(func(id:Variant)->bool:return not str(id).is_empty()) and receiver_ids.any(func(id:Variant)->bool:return not str(id).is_empty()),"response keeps source and receiver building identities")
	check(response.get("stereo",null) is Vector2,"response routes to receiving stereo")
	var receiver_id := ""
	for value in receiver_ids:
		if not str(value).is_empty():
			receiver_id = str(value)
			break
	check(not receiver_id.is_empty() and world.by_id.has(receiver_id),"receiver identity resolves in world")
	var answer_node: Dictionary = {}
	for node in model.synth.musical_nodes.values():
		if bool(node.get("answer",false)):
			answer_node = node
			break
	var rate := int(world.cfg["timing"]["sample_rate"])
	var events: Array = model.synth.musical_events(answer_node,world.phrase_index*phrase,phrase,rate) if not answer_node.is_empty() else []
	check(not events.is_empty(),"response produces scheduled events")
	check(events.all(func(event:Dictionary)->bool:
		return int(event.get("generation",0)) == 1 and not str(event.get("source_id","")).is_empty() and not str(event.get("receiver_id","")).is_empty() and int(event["onset"])-int(event["source_onset"]) == model.beat_frames*2
	),"response events preserve source receiver and exact two-beat delay")
	var startup_model := Model.new(world.fork())
	var startup_toggle := startup_model.submit({"kind":"response","enabled":false})
	check(int(startup_toggle["sound_frame"]) == startup_model.beat_frames,"startup response toggle also uses the next beat")
	var state: Dictionary = {}
	model.render_block(state,0,1,rate)
	var before_world := model.world.snapshot()
	var off := model.submit({"kind":"response","enabled":false})
	check(off["accepted"] and int(off["sound_frame"]) == model.beat_frames,"response toggle queues at the next beat")
	check(model.synth.response_enabled and model.world.snapshot() == before_world,"queued response toggle leaves live audio and city unchanged")
	model.render_block(state,int(off["sound_frame"])-1,1,rate)
	check(model.synth.response_enabled,"response remains enabled before queued beat")
	model.render_block(state,int(off["sound_frame"]),1,rate)
	check(not model.synth.response_enabled and model.synth.response.is_empty(),"response disables at queued beat")
	var on := model.submit({"kind":"response","enabled":true})
	model.render_block(state,int(on["sound_frame"]),1,rate)
	check(model.synth.response_enabled and not model.synth.response.is_empty(),"response re-enables at a later beat")
	var baseline := model.capture_state()
	var preview := model.forecast({"kind":"response","enabled":false},{},model.rendered_until,2205)
	check(preview.size() == 2205 and model.capture_state() == baseline,"response preview is isolated from live state")
	var restored := Model.from_state(Archive._json_value(baseline))
	check(restored.synth.response_enabled == model.synth.response_enabled and restored.synth.response.get("source_ids",[]) == model.synth.response.get("source_ids",[]) and restored.synth.response.get("receiver_ids",[]) == model.synth.response.get("receiver_ids",[]),"archive restores response state and identities")
	check(restored.synth.response.get("stereo",null) is Vector2,"archive hydrates response stereo")
	print("ROUND145_RIVER_RESPONSE checks=",checks," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
