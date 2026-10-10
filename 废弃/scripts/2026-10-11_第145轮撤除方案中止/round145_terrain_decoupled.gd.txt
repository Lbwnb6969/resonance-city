extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const OUT = "res://验证记录/连续河谷/第145轮_地形音乐解耦"
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
	var rate: int = world.cfg["timing"]["sample_rate"]
	var start: int = world.phrase_index*int(world.cfg["timing"]["phrase_frames"])
	var gain: float = JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"]
	var reference := Model.new(world.fork(),gain)
	var pcm := reference.render_block({},start,4096,rate)
	var score := reference.synth.score_snapshot()
	var edges: Dictionary = {}
	for edge in world.edges(): edges[str(edge["a"])+":"+str(edge["b"])] = edge["coupling"]
	var resonance := world.coupling.resonance(world.buildings,world.musical_edges(world.musicality()))
	check(score["response"].is_empty() and not score["theme"].is_empty(),"natural mature community plays theme without automatic response")
	check(not score["theme"].has("terrain") and score["rhythms"].all(func(p:Dictionary)->bool:return not p.has("terrain")),"score has no terrain inputs")
	for family in world.terrain.family_ids():
		var clone := world.fork()
		clone.terrain.configure(73,1.17,family)
		clone.rebuild_graph()
		var model := Model.new(clone,gain)
		var clone_edges: Dictionary = {}
		for edge in clone.edges(): clone_edges[str(edge["a"])+":"+str(edge["b"])] = edge["coupling"]
		check(clone_edges == edges and is_equal_approx(clone.resonance,resonance),family+" preserves fixed-city coupling and resonance")
		check(model.render_block({},start,4096,rate) == pcm,family+" preserves actual fixed-city PCM")
		var env: Dictionary = clone.terrain.environment(Vector2(12,12),Vector2(24,12),false)
		check(env == {"occlusion":1.0,"terrain_factor":1.0,"sigma_a":1.0,"sigma_b":1.0},family+" provides no automatic terrain sound modifiers")
		model.close_background_settlement()
	var first: Dictionary = world.buildings[0]
	var second: Dictionary = world.buildings[1]
	check(world.coupling.coefficient(first,second) == world.coupling.coefficient(first,second,{"sigma_a":10.0,"sigma_b":5.0,"terrain_factor":0.1}),"obsolete terrain multiplier fields are ignored")
	var settled: ContinuousWorld = world.fork()
	settled.families.clear()
	var modifiers := settled.musicality()
	var effective := settled.musical_edges(modifiers)
	var expected := settled.coupling.vitality(settled.buildings,effective,settled.coupling.resonance(settled.buildings,effective),{},modifiers)
	settled.settle((settled.phrase_index+1)*int(settled.cfg["timing"]["phrase_frames"]))
	check(settled.buildings.all(func(b:Dictionary)->bool:return is_equal_approx(float(b["vitality"]),float(expected[b["district_id"]]))),"real growth settlement has no terrain vitality bonuses")
	var phases: Dictionary = {}
	reference = Model.new(world.fork(),gain)
	reference.render_block(phases,start,256,rate)
	var saved := reference.capture_state()
	var resumed := Model.from_state(CityArchive._json_value(saved))
	var frozen := reference.freeze()
	var future := reference.render_block(phases.duplicate(true),start+256,2048,rate)
	check(future == resumed.render_block(phases.duplicate(true),start+256,2048,rate) and future == frozen.render_block(phases.duplicate(true),start+256,2048,rate),"current DNA and preview retain exact PCM")
	var legacy: Dictionary = saved.duplicate(true)
	legacy.erase("music_layout_version")
	legacy["mix"]["theme"]["terrain"] = "lake_basin"
	legacy["mix"]["response"] = {"cid":"east-1","source":"west-1"}
	legacy["mix"]["musical_nodes"]["obsolete"] = {"answer":true,"active":true}
	legacy["mix"]["rhythm_nodes"]["obsolete"] = {"terrain":"forest_ridge","active":true}
	var imported := Model.from_state(CityArchive._json_value(legacy))
	check(imported.synth.response.is_empty() and imported.synth.musical_nodes.values().all(func(n:Dictionary)->bool:return not n["answer"]) and not imported.synth.rhythm_nodes.has("obsolete"),"old DNA discards retired terrain-driven routes")
	check(imported.world.snapshot() == world.snapshot() and imported.synth.pad_groups == Model.from_state(saved).synth.pad_groups,"old DNA preserves city RNG and pad phases")
	var opportunity := Rules.opportunity(world,"west-1",score)
	check(not opportunity["next"].contains("跨河") and not opportunity.has("river_pairs"),"community opportunity describes music rather than terrain rewards")
	var peak := 0.0
	var audio := Model.new(world.fork(),gain)
	var audio_state: Dictionary = {}
	for frame in range(start,start+rate*8,1024):
		for sample in audio.render_block(audio_state,frame,mini(1024,start+rate*8-frame),rate): peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
	check(peak > 0.001 and peak < 0.70795 and audio.synth.max_voice_count <= 70,"actual eight-second ensemble retains headroom and voice budget")
	report["audio"] = {"peak":peak,"max_voices":audio.synth.max_voice_count}
	await gpu_flow(world)
	var all_ok: bool = checks.values().all(func(v:bool)->bool:return v)
	report["checks"] = checks
	report["status"] = "PASS" if all_ok else "FAIL"
	FileAccess.open(OUT+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND145_TERRAIN_DECOUPLED ",report["status"]," checks=",checks.size())
	quit(0 if all_ok else 1)

func gpu_flow(world: ContinuousWorld) -> void:
	var demo: ContinuousValleyDemo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await RenderingServer.frame_post_draw
	demo.clock.stop_output()
	demo.set_process(false)
	demo._start_world({},world.fork())
	demo.planning_guide.hide_tool()
	demo._sync_buildings()
	demo.selected_id = str(demo.shown_world.communities["west-1"]["members"][0])
	demo.context = {"kind":"retune","id":demo.selected_id}
	demo.pointer = demo.point(WorldCoupling.position_of(demo.shown_world.by_id[demo.selected_id]))
	demo._show_context_menu()
	await RenderingServer.frame_post_draw
	check(demo.menu_info.text.contains("主题") and not demo.menu_info.text.contains("跨河"),"GPU selection retains musical choices without terrain instructions")
	root.get_texture().get_image().save_png(OUT+"_试玩.png")
	demo.menu.hide()
	var rate: int = world.cfg["timing"]["sample_rate"]
	var live_start := demo.model.next_boundary-rate*2
	demo.clock.renderer.transport.rendered_frames = live_start
	demo.clock.renderer.transport.audible_frame = live_start
	demo.clock.start_output(demo.model._mix_frame,{},demo.clock.renderer.snapshot())
	demo.set_process(true)
	await create_timer(4.5).timeout
	check(demo.clock.underruns == 0 and demo.shown_world.phrase_index > world.phrase_index and demo.model.synth.max_voice_count <= 70 and demo.model.synth.response.is_empty(),"live WASAPI crosses growth with zero skips and no terrain response")
	report["live"] = {"driver":AudioServer.get_driver_name(),"skips":demo.clock.underruns,"phrase":demo.shown_world.phrase_index,"max_voices":demo.model.synth.max_voice_count}
	demo.clock.stop_output()
	demo.free()
	await process_frame
