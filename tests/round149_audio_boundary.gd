extends SceneTree
## Round 149 audio-boundary contract: sound controls stay beat-quantized while
## public planning remains phrase-bound and preview branches preserve controls.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")

var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func public_candidates(world: RefCounted, cid: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lot in world.lots:
		if not str(lot.get("occupant","")).is_empty() or str(lot.get("community_id","")) != cid: continue
		var candidate: Dictionary = world.planning_candidate(Vector2(float(lot["center"][0]),float(lot["center"][1])))
		if candidate.is_empty() or not bool(candidate.get("allowed",false)) or candidate.has("public_id"): continue
		if not Planning.public_access(world,candidate).is_empty(): result.append(candidate)
	return result

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := World.new("2026101100000149",true,"river_valley")
	world.build_starter("bright")
	var phrase := int(world.cfg["timing"]["phrase_frames"])
	for i in range(2): world.settle((world.phrase_index+1)*phrase)
	var candidates := public_candidates(world,"west-1")
	check(candidates.size() >= 1,"real public planning candidate exists")
	if candidates.is_empty():
		print("ROUND149_AUDIO_BOUNDARY checks=",checks," failures=",JSON.stringify(failures))
		quit(1)
		return

	var model := Model.new(world)
	var rate := int(world.cfg["timing"]["sample_rate"])
	var at := world.phrase_index*phrase
	var state: Dictionary = {}
	model.render_block(state,at,64,rate)
	var baseline_world := model.world.snapshot()
	var expected_beat := (model.rendered_until/model.beat_frames+1)*model.beat_frames
	var focus := model.submit({"kind":"focus","community":"west-1"})
	var solo := model.submit({"kind":"solo","community":"west-1"})
	var mute := model.submit({"kind":"mute","community":"west-1","enabled":true})
	var response := model.submit({"kind":"response","enabled":false})
	check(focus["accepted"] and solo["accepted"] and mute["accepted"] and response["accepted"],"focus solo mute response controls are accepted")
	check(int(focus["sound_frame"]) == expected_beat and int(solo["sound_frame"]) == expected_beat and int(mute["sound_frame"]) == expected_beat and int(response["sound_frame"]) == expected_beat,"all sound controls share the next writable beat")
	check(model.synth.listener_community.is_empty() and model.synth.focused_community.is_empty() and not bool(model.synth.muted_communities.get("west-1",false)) and model.synth.response_enabled,"queued controls do not apply before their beat")
	check(model.world.snapshot() == baseline_world,"sound controls leave the structural world unchanged")

	var building_id := str(world.communities["west-1"]["members"][0])
	var retune := model.submit({"kind":"retune","id":building_id,"midi":52})
	check(retune["accepted"],"retune remains accepted alongside queued sound controls")
	check(int(retune["sound_frame"]) == expected_beat,"retune audio change shares the next writable beat")
	model.render_block(state,expected_beat-1,1,rate)
	check(model.synth.listener_community.is_empty() and model.synth.focused_community.is_empty() and not bool(model.synth.muted_communities.get("west-1",false)) and model.synth.response_enabled,"controls remain unchanged one sample before the beat")
	model.render_block(state,expected_beat,1,rate)
	check(model.synth.listener_community == "west-1" and model.synth.focused_community == "west-1" and bool(model.synth.muted_communities.get("west-1",false)) and not model.synth.response_enabled,"controls apply exactly at the queued beat")
	check(int(model.sound_overrides.get(building_id,-1)) == 52,"retune pitch applies at the same queued beat")
	check(model.world.snapshot() == baseline_world or model.world.snapshot()["pending_actions"].size() >= baseline_world["pending_actions"].size(),"retune changes only queued structural intent before its phrase boundary")

	var candidate: Dictionary = candidates[0]
	var source_state := state.duplicate(true)
	var live_before := model.capture_state()
	var comparison := Preview.build(model.freeze(),candidate,source_state,model.rendered_until)
	check(model.capture_state() == live_before,"public preview leaves live audio and world state unchanged")
	check(comparison.get("variants",{}).size() == 3,"public preview keeps three branch choices")
	var source_version: Array = comparison.get("source_version",[])
	check(source_version.size() >= 12 and str(source_version[7]) == "west-1" and str(source_version[8]) == "west-1" and not bool(source_version[9]),"preview source identity records focus solo and response state")
	for kind: String in ["none","park","civic"]:
		var variant: Dictionary = comparison["variants"][kind]
		check(bool(variant.get("accepted",false)) and (variant.get("pcm",PackedByteArray()) as PackedByteArray).size() > 0,kind+" branch keeps valid PCM")
		var branch_preview: Dictionary = variant.get("opportunity_preview",{})
		check(branch_preview.get("source_version",[]) == source_version,kind+" branch keeps the same captured control identity")
	var branch := model.freeze()
	branch.cancel_planning()
	var branch_request := branch.submit({"kind":"park","position":candidate["position"].duplicate()})
	check(branch_request["accepted"],"frozen preview branch accepts public park request")
	check(branch.synth.listener_community == "west-1" and branch.synth.focused_community == "west-1" and bool(branch.synth.muted_communities.get("west-1",false)) and not branch.synth.response_enabled,"frozen preview branch retains all live sound controls")
	check(int(branch_request["frame"]) == branch.next_boundary,"public park remains phrase-bound after sound controls")

	print("ROUND149_AUDIO_BOUNDARY checks=",checks," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
