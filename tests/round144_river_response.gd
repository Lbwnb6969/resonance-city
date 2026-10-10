extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const River = preload("res://scripts/world/river_call_response.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const OUT = "res://验证记录/连续河谷/第144轮_跨河对唱"
var checks: Dictionary = {}
var report: Dictionary = {}
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)
func _run() -> void:
	var world := World.new()
	world.build_starter("bright")
	for i in range(2): world.settle((world.phrase_index+1)*int(world.cfg["timing"]["phrase_frames"]))
	world.bridge = false
	world.rebuild_graph()
	var saved := world.snapshot()
	var relations := River.pairs(world)
	check(not relations.is_empty(),"natural grown river has compatible opposite-bank houses without bridge")
	check(relations.all(func(p:Dictionary)->bool:
		return p["distance"] < 8.0 and p["score"] >= 0.85 and not world.edges().any(func(e:Dictionary)->bool:return (e["a"] == p["a"] and e["b"] == p["b"]) or (e["b"] == p["a"] and e["a"] == p["b"]))),"all response pairs meet exact geometry and harmony while absent from R edges")
	check(world.snapshot() == saved,"relation discovery preserves world and RNG")
	var pair: Dictionary = relations[0]
	var aid := str(pair["a"])
	var bid := str(pair["b"])
	var probe := world.fork()
	# Isolate strict thresholds from authored template spacing.
	probe.buildings.assign([world.by_id[aid].duplicate(true),world.by_id[bid].duplicate(true)])
	probe.by_id = {aid:probe.buildings[0],bid:probe.buildings[1]}
	var y := 8.0
	var x: float = roundf(probe.terrain.river_x(y))
	probe.buildings[0]["position"] = [x-4.0,y]
	probe.buildings[1]["position"] = [x+4.0,y]
	probe.index = WorldSpatialIndex.new()
	for b in probe.buildings: probe.index.put(b["district_id"],WorldCoupling.position_of(b),float(b["radius"]))
	check(River.pairs(probe).is_empty(),"exactly eight units is excluded")
	probe.buildings[1]["position"][0] -= 0.01
	probe.index.put(bid,WorldCoupling.position_of(probe.by_id[bid]),float(probe.by_id[bid]["radius"]))
	probe.by_id[aid]["current_midi"] = 48
	probe.by_id[bid]["current_midi"] = 55
	check(River.pairs(probe).size() == 1,"under eight units and perfect fifth qualify")
	check(River.pairs(probe,{bid:49}).is_empty(),"audible semitone override cannot retain obsolete response")
	probe.terrain.family = "lake_basin"
	check(River.pairs(probe).is_empty(),"lake water does not acquire river bonuses")
	probe.terrain.family = "coastal_plain"
	check(River.pairs(probe).is_empty(),"sea water does not acquire river bonuses")
	var bonuses := River.bonuses(relations)
	var modifiers := world.musicality()
	var effective := world.musical_edges(modifiers)
	var base := world.coupling.vitality(world.buildings,effective,world.resonance,{},modifiers)
	var expected := world.coupling.vitality(world.buildings,effective,world.resonance,{},modifiers,bonuses)
	check(bonuses[aid] >= 2.0 and bonuses[bid] >= 2.0,"both ends receive two vitality per relation")
	var tiny: Array = [{"district_id":"a","current_midi":48,"vitality":40.0},{"district_id":"b","current_midi":55,"vitality":40.0}]
	var edge: Array = [{"a":"a","b":"b","coupling":0.01}]
	var scaled := world.coupling.vitality(tiny,edge,80.0,{},{"a":{"dv_scale":0.5},"b":{"dv_scale":0.5}})
	var unscaled_bonus := world.coupling.vitality(tiny,edge,80.0,{},{"a":{"dv_scale":0.5},"b":{"dv_scale":0.5}},{"a":2.0,"b":2.0})
	check(unscaled_bonus["a"]-scaled["a"] == 2.0,"river bonus is neither coupling weighted nor homogeneity halved")
	var cap := world.coupling.vitality(tiny,[],80.0,{"a":-100.0},{},{"a":200.0,"b":200.0})
	check(cap["a"] == 52.0 and cap["b"] == 52.0,"river sums and action costs share twelve-point net cap")
	var settle_world := world.fork()
	settle_world.families.clear()
	settle_world.settle((settle_world.phrase_index+1)*int(world.cfg["timing"]["phrase_frames"]))
	check(settle_world.buildings.all(func(b:Dictionary)->bool:return is_equal_approx(float(b["vitality"]),float(expected[b["district_id"]]))),"real phrase settlement uses exact river vitality result")
	var gain: float = JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"]
	var model := Model.new(world.fork(),gain)
	var synth := model.synth
	check(not synth.theme.is_empty() and not synth.response.is_empty(),"qualified natural theme obtains one real response without bridge")
	var source_cid := str(synth.theme.get("cid",""))
	var receiver_cid := str(synth.response.get("cid",""))
	var rate: int = world.cfg["timing"]["sample_rate"]
	var start: int = world.phrase_index*int(world.cfg["timing"]["phrase_frames"])
	var duration := rate*16
	var lead_node: Dictionary = {}
	var reply_node: Dictionary = {}
	for node in synth.musical_nodes.values():
		if node["answer"]: reply_node = node
		else: lead_node = node
	var lead_events := synth.musical_events(lead_node,start,duration,rate)
	var reply_events := synth.musical_events(reply_node,start,duration,rate)
	var source_events: Dictionary = {}
	for event in lead_events: source_events[event["event_id"]] = event
	check(not reply_events.is_empty() and reply_events.all(func(e:Dictionary)->bool:
		return e["generation"] == 1 and source_events.has(e["source_event_id"]) and int(e["onset"])-int(source_events[e["source_event_id"]]["onset"]) == rate),"every reply references one actual original event exactly two beats earlier")
	check(reply_events.all(func(e:Dictionary)->bool:return relations.any(func(p:Dictionary)->bool:return [p["a"],p["b"]].has(e["source_id"]) and [p["a"],p["b"]].has(e["receiver_id"]))),"each sounded reply has its actual qualifying house pair")
	var ids: Dictionary = {}
	for e in reply_events: ids[e["event_id"]] = true
	check(ids.size() == reply_events.size(),"reply identities are unique without recursive copies")
	var wave := synth._musical_block(reply_node,start,duration,rate)
	var pieced := PackedFloat32Array()
	for frame in range(start,start+duration,997): pieced.append_array(synth._musical_block(reply_node,frame,mini(997,start+duration-frame),rate))
	check(wave == pieced,"response event synthesis is invariant to audio block partition")
	var offset_node: Dictionary = reply_node.duplicate(true)
	offset_node["born_at"] = start+rate/2
	check(synth.musical_events(offset_node,start,rate*2,rate).all(func(e:Dictionary)->bool:return int(e["source_onset"]) >= int(offset_node["born_at"])),"newly selected reply never invents a source from before activation")
	var op := Rules.opportunity(world,receiver_cid,synth.score_snapshot())
	check(op["answering"] and op["river_pairs"] > 0 and op["next"].contains("不必建桥"),"community opportunity reveals real response and no-bridge rule")
	var phases: Dictionary = {}
	model.render_block(phases,start,256,rate)
	var compare_at := int(reply_events[0]["onset"])-256
	for frame in range(start+256,compare_at,1024): model.render_block(phases,frame,mini(1024,compare_at-frame),rate)
	var snapshot := model.capture_state()
	var resumed := Model.from_state(CityArchive._json_value(snapshot))
	var frozen := model.freeze()
	var a := model.render_block(phases.duplicate(true),compare_at,2048,rate)
	var b := resumed.render_block(phases.duplicate(true),compare_at,2048,rate)
	var c := frozen.render_block(phases.duplicate(true),compare_at,2048,rate)
	var json_delta := 0.0
	var freeze_delta := 0.0
	for i in range(a.size()):
		json_delta = maxf(json_delta,a[i].distance_to(b[i]))
		freeze_delta = maxf(freeze_delta,a[i].distance_to(c[i]))
	report["resume_deltas"] = {"json_compatible":json_delta,"freeze":freeze_delta}
	check(a == b and a == c,"DNA compatible state and preview freeze preserve response PCM")
	var muted_model := Model.new(world.fork(),gain)
	muted_model.synth.muted_communities[source_cid] = true
	var muted_phases: Dictionary = {}
	muted_model.synth.render_block(muted_phases,int(reply_events[0]["onset"]),1024,rate)
	var source_mute_ok := true
	for node in muted_model.synth.musical_nodes.values():
		if node["answer"]: source_mute_ok = source_mute_ok and float(muted_phases.get("_theme_level_"+str(node["key"]),0.0)) == 0.0
	check(source_mute_ok,"muted source cannot create an independently audible answer")
	var retired: Dictionary = reply_node.duplicate(true)
	retired["retired_at"] = start+rate*12
	var retired_events := synth.musical_events(retired,start,duration,rate)
	check(not retired_events.is_empty() and retired_events.all(func(e:Dictionary)->bool:return int(e["source_onset"]) < int(retired["retired_at"])),"retired node completes existing source replies and creates no new source events")
	check(retired_events.any(func(e:Dictionary)->bool:return int(e["onset"]) >= int(retired["retired_at"])),"pending reply survives source retirement for its exact delay")
	report["relations"] = relations
	report["bonuses"] = bonuses
	report["score"] = synth.score_snapshot()
	report["source_events"] = lead_events
	report["reply_events"] = reply_events
	report["base_vitality"] = base
	report["river_vitality"] = expected
	# Same whole score, same fixed gain, with and without the response route.
	var on := Model.new(world.fork(),gain)
	var off := Model.new(world.fork(),gain)
	for key in off.synth.musical_nodes.keys():
		if off.synth.musical_nodes[key]["answer"]: off.synth.musical_nodes.erase(key)
	off.synth.response.clear()
	render_audio(on,start,rate,"有应答")
	render_audio(off,start,rate,"无应答")
	check(FileAccess.get_file_as_bytes(OUT+"_有应答.wav") != FileAccess.get_file_as_bytes(OUT+"_无应答.wav"),"response changes actual rendered whole-score PCM")
	await gpu_flow(world,receiver_cid)
	checks["all"] = checks.values().all(func(v:bool)->bool:return v)
	report["checks"] = checks
	report["status"] = "PASS" if checks["all"] else "FAIL"
	FileAccess.open(OUT+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND144_RIVER_RESPONSE ",report["status"]," checks=",checks.size())
	quit(0 if checks["all"] else 1)

func render_audio(model: ContinuousAudioModel,start: int,rate: int,name: String) -> void:
	var state: Dictionary = {}
	var samples := PackedVector2Array()
	var peak := 0.0
	for frame in range(start,start+rate*16,1024):
		var block := model.render_block(state,frame,mini(1024,start+rate*16-frame),rate)
		for sample in block: peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		samples.append_array(block)
	var bytes := PackedByteArray()
	bytes.resize(samples.size()*4)
	for i in range(samples.size()):
		bytes.encode_s16(i*4,clampi(roundi(samples[i].x*32767.0),-32768,32767))
		bytes.encode_s16(i*4+2,clampi(roundi(samples[i].y*32767.0),-32768,32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = true
	wav.mix_rate = rate
	wav.data = bytes
	wav.save_to_wav(OUT+"_"+name+".wav")
	check(peak > 0.001 and peak < 0.70795 and model.synth.max_voice_count <= 70,name+" actual PCM preserves headroom and voice budget")
	report[name] = {"peak":peak,"max_voices":model.synth.max_voice_count}
	model.close_background_settlement()

func gpu_flow(world: ContinuousWorld,cid: String) -> void:
	var demo: ContinuousValleyDemo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await RenderingServer.frame_post_draw
	demo.clock.stop_output()
	demo.set_process(false)
	demo._start_world({},world.fork())
	demo.planning_guide.hide_tool()
	demo._sync_buildings()
	demo.selected_id = str(demo.shown_world.communities[cid]["members"][0])
	demo.context = {"kind":"retune","id":demo.selected_id}
	demo.pointer = demo.point(WorldCoupling.position_of(demo.shown_world.by_id[demo.selected_id]))
	demo._show_context_menu()
	await RenderingServer.frame_post_draw
	demo._show_context_menu()
	await RenderingServer.frame_post_draw
	check(demo.menu_info.text.contains("不必建桥") and demo.menu_info.text.contains("跨岸应答"),"actual GPU selection exposes river response feedback")
	check(demo.menu.get_rect().end.y <= demo.size.y and demo.menu.get_rect().end.x <= demo.size.x,"expanded community feedback fits viewport")
	root.get_texture().get_image().save_png(OUT+"_社区反馈.png")
	demo.menu.hide()
	var rate: int = world.cfg["timing"]["sample_rate"]
	var live_start := demo.model.next_boundary-rate*2
	demo.clock.renderer.transport.rendered_frames = live_start
	demo.clock.renderer.transport.audible_frame = live_start
	demo.clock.start_output(demo.model._mix_frame,{},demo.clock.renderer.snapshot())
	demo.set_process(true)
	await create_timer(4.5).timeout
	check(demo.clock.underruns == 0 and demo.shown_world.phrase_index > world.phrase_index and demo.model.synth.max_voice_count <= 70,"live WASAPI crosses real growth with response and zero skips")
	report["live"] = {"driver":AudioServer.get_driver_name(),"skips":demo.clock.underruns,"phrase":demo.shown_world.phrase_index,"max_voices":demo.model.synth.max_voice_count}
	demo.clock.stop_output()
	demo.free()
	await process_frame
