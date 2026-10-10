extends SceneTree
## Round 145 equivalent 16-second PCM A/B evidence.
##
## This stays headless and uses the production ContinuousAudioModel/Synth path.
## It does not claim a WASAPI device clock or a human listening result.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Archive = preload("res://scripts/world/city_archive.gd")

var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func energy(pcm: PackedVector2Array) -> float:
	var total := 0.0
	for sample in pcm: total += sample.length_squared()
	return total

func max_difference(a: PackedVector2Array, b: PackedVector2Array) -> float:
	if a.size() != b.size(): return INF
	var result := 0.0
	for index in range(a.size()): result = maxf(result,a[index].distance_to(b[index]))
	return result

func render_window(model: ContinuousAudioModel, start: int, count: int) -> PackedVector2Array:
	var state: Dictionary = {}
	return model.render_block(state,start,count,22050)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var world := World.new("2026101100000145",true,"river_valley")
	world.build_starter("bright")
	var phrase := int(world.cfg["timing"]["phrase_frames"])
	for index in range(2): world.settle((world.phrase_index+1)*phrase)
	world.bridge = false
	world.rebuild_graph()
	var rate := int(world.cfg["timing"]["sample_rate"])
	var window := phrase # One configured 16-second phrase, without waiting on AudioClock.
	var start := world.phrase_index*phrase

	var on := Model.new(world.fork())
	var off := Model.new(world.fork())
	check(on.synth.response_enabled and off.synth.response_enabled,"A/B models start with response enabled")
	check(on.synth.response == off.synth.response,"A/B models share the same source/receiver relation")
	check(not on.synth.response.is_empty(),"A/B window has a concrete response relation")
	var relation_source_ids: Array = on.synth.response.get("source_ids",[])
	var relation_receiver_ids: Array = on.synth.response.get("receiver_ids",[])
	check(relation_source_ids == off.synth.response.get("source_ids",[]) and relation_receiver_ids == off.synth.response.get("receiver_ids",[]),"A/B keeps source and receiver identities fixed")

	var toggle := off.submit({"kind":"response","enabled":false})
	check(toggle["accepted"] and int(toggle["sound_frame"]) == off.beat_frames,"startup OFF queues at the next beat")
	var pre_state: Dictionary = {}
	off.render_block(pre_state,0,off.beat_frames-1,rate)
	check(off.synth.response_enabled,"OFF remains enabled before its queued beat")
	off.render_block(pre_state,off.beat_frames,1,rate)
	check(not off.synth.response_enabled and off.synth.response.is_empty(),"OFF takes effect exactly on the queued next beat")

	# Fresh models provide the same phase origin for the full configured phrase.
	on = Model.new(world.fork())
	off = Model.new(world.fork())
	on.rendered_until = start
	off.rendered_until = start
	off.submit({"kind":"response","enabled":false})
	var on_pcm := render_window(on,start,window)
	var off_pcm := render_window(off,start,window)
	check(on_pcm.size() == window and off_pcm.size() == window,"A/B renders one complete configured 16-second PCM window")
	var difference := max_difference(on_pcm,off_pcm)
	check(difference > 0.000001 and energy(on_pcm) > 0.0,"response ON PCM differs from response OFF PCM")
	check(on.synth.response_enabled and not on.synth.response.is_empty(),"response ON keeps the derived answer active")
	var on_leads := on.synth.musical_nodes.values().filter(func(node: Dictionary) -> bool: return not bool(node.get("answer",false)) and bool(node.get("active",false)))
	var off_leads := off.synth.musical_nodes.values().filter(func(node: Dictionary) -> bool: return not bool(node.get("answer",false)) and bool(node.get("active",false)))
	check(not on_leads.is_empty() and not off_leads.is_empty(),"response A/B both retain active source lead nodes")
	var lead_events: Array[Dictionary] = []
	if not on_leads.is_empty(): lead_events = on.synth.musical_events(on_leads[0],start,window,rate)
	check(not lead_events.is_empty() and lead_events.all(func(event: Dictionary) -> bool: return int(event.get("generation",-1)) == 0 and not str(event.get("source_id","" )).is_empty()),"enabled window still contains source generation-zero events")
	var answers: Array[Dictionary] = []
	for node in on.synth.musical_nodes.values():
		if bool(node.get("answer",false)): answers.append_array(on.synth.musical_events(node,start,window,rate))
	check(not answers.is_empty() and answers.all(func(event: Dictionary) -> bool: return int(event.get("generation",0)) == 1 and int(event["onset"])-int(event["source_onset"]) == on.beat_frames*2),"enabled PCM window schedules one-generation answers two beats after source")

	# Preview must render from a frozen model and leave the live state byte-for-byte intact.
	var live := Model.new(world.fork())
	var baseline := live.capture_state()
	var preview := live.forecast({"kind":"response","enabled":false},{},0,on.beat_frames*4)
	check(preview.size() == on.beat_frames*4 and live.capture_state() == baseline,"response preview produces PCM without mutating live state")
	var restored := Model.from_state(Archive._json_value(baseline))
	var live_pcm := render_window(live,start,window)
	var restored_pcm := render_window(restored,start,window)
	check(live_pcm == restored_pcm,"archive restore reproduces the same 16-second PCM window")
	check(restored.capture_state() == live.capture_state(),"archive restore preserves live response state after rendering")

	print("ROUND145_RIVER_PCM_AB checks=",checks," max_difference=",difference," samples=",window," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

