extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Job = preload("res://scripts/world/world_settlement_job.gd")
const OUT = "res://验证记录/连续河谷/第143轮_公共规划对照"
var checks: Dictionary = {}
var report: Dictionary = {}
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)
func sites(world: ContinuousWorld,cid: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lot in world.lots:
		if not str(lot["occupant"]).is_empty() or (not cid.is_empty() and str(lot["community_id"]) != cid): continue
		var candidate := world.planning_candidate(Vector2(float(lot["center"][0]),float(lot["center"][1])))
		if candidate.is_empty() or not candidate["allowed"] or candidate.has("public_id"): continue
		if not Planning.public_access(world,candidate).is_empty(): result.append(candidate)
	return result
func _run() -> void:
	var world := World.new()
	world.build_starter("bright")
	for i in range(2): world.settle((world.phrase_index+1)*int(world.cfg["timing"]["phrase_frames"]))
	var available := sites(world,"west-1")
	check(available.size() >= 2,"real community has alternative public locations")
	var site: Dictionary = available[0]
	var gain := float(JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"])
	var model := Model.new(world,gain)
	var rate: int = world.cfg["timing"]["sample_rate"]
	var at: int = world.phrase_index*int(world.cfg["timing"]["phrase_frames"])
	var phases: Dictionary = {}
	model.render_block(phases,at,64,rate)
	at += 64
	model.submit({"kind":"charter","plan_id":"bluegreen","community_ids":["west-1"]})
	model.submit({"kind":"retune","id":world.communities["west-1"]["members"][0],"midi":52})
	model.submit({"kind":"reserve","position":available[1]["position"]})
	var original := model.capture_state()
	var comparison := Preview.build(model.freeze(),site,phases,at)
	check(model.capture_state() == original,"all comparisons preserve live city RNG controls and queue")
	check(comparison["boundary_frame"] == model.next_boundary and comparison["gain"] == gain and comparison["source_frame"] == at and comparison["seconds"] == 3,"three choices share snapshot cursor gain and duration")
	var summaries: Dictionary = {}
	for kind: String in ["none","park","civic"]:
		var variant: Dictionary = comparison["variants"][kind]
		check(variant["accepted"] and variant["pcm"].size() == rate*3*4 and variant["peak"] < 0.70795 and variant["max_voices"] <= 70,kind+" actual three second PCM respects budget")
		var actual := model.freeze()
		actual.cancel_planning()
		if kind != "none": actual.submit({"kind":kind,"position":site["position"]})
		var worker := Job.new()
		worker.start(actual.world,[kind],actual.next_boundary)
		worker.join()
		worker.adopt(actual.world)
		check(actual.world.buildings.size() == variant["houses"] and actual.world.public_service_summary() == variant["service"],kind+" predicted growth and capacity match real worker settlement")
		if kind == "none":
			check(actual.world.planning_reservations.is_empty() and actual.world.development_charters.size() == 1 and actual.world.by_id[world.communities["west-1"]["members"][0]]["current_midi"] == 52,"not building clears only replaceable planning and preserves charter and retune")
		else:
			var anchor := actual.world.public_at(Vector2(float(site["position"][0]),float(site["position"][1])))
			check(anchor == variant["anchor"],kind+" predicted anchor identity and actual service agree")
			var intrusion := false
			for building in actual.world.buildings:
				if Planning.disc_hits(anchor["polygon"],WorldCoupling.position_of(building),float(building["radius"])): intrusion = true
			check(not intrusion,kind+" real ordinary growth avoids chosen public footprint")
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.stereo = true
		wav.mix_rate = rate
		wav.data = variant["pcm"]
		wav.save_to_wav(OUT+"_"+kind+".wav")
		var summary: Dictionary = variant.duplicate(true)
		summary.erase("pcm")
		summaries[kind] = CityArchive._json_value(summary)
	check(comparison["variants"]["park"]["theme_events"] < comparison["variants"]["none"]["theme_events"],"park changes actual compiled theme density")
	check(comparison["variants"]["park"]["pcm"] != comparison["variants"]["none"]["pcm"] and comparison["variants"]["civic"]["pcm"] != comparison["variants"]["none"]["pcm"],"public choices change real forecast audio")
	var civic: Dictionary = comparison["variants"]["civic"]
	check(civic["anchor"]["served"].size() <= 18 and civic["newly_served_ids"].all(func(id:Variant)->bool:return not comparison["variants"]["none"]["served_ids"].has(id)),"additional culture users exclude existing overlapping service")
	check(civic["opportunities"][0].has("world_version") and civic["opportunities"][0].has("missing_conditions") and civic["opportunities"][0].has("anchor_ids"),"future opportunities retain canonical conditions anchors and versions")
	var restore := Model.from_state(CityArchive._json_value(original))
	check(not restore.capture_state().has("comparison") and not restore.world.snapshot().has("comparison") and restore.world.pending_actions.size() == model.world.pending_actions.size(),"preview remains ephemeral across real JSON runtime restoration")
	report["variants"] = summaries
	report["source"] = {"at":at,"boundary":comparison["boundary_frame"],"gain":gain,"rate":rate,"site":CityArchive._json_value(site)}
	await gpu_flow(world,available)
	var ok := not checks.values().has(false)
	report["checks"] = checks
	report["status"] = "PASS" if ok else "FAIL"
	report["scope"] = "P11 public choice comparison from one captured model: real 3s branches, worker commitment, stale-result rejection and actual WASAPI UI. Complete Bass/commercial/response prediction, cards and human listening remain pending."
	FileAccess.open(OUT+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("PUBLIC_COMPARISON ",report["status"]," checks=",checks.size())
	quit(0 if ok else 1)
func wait_preview(demo: ContinuousValleyDemo) -> void:
	var end := Time.get_ticks_msec()+12000
	var last := ""; while demo.preview_thread != null and Time.get_ticks_msec() < end: var state := "%s|%s|%s|%s" % [str(demo.pointer),str(demo.world_at(demo.pointer)),str(demo.planning_guide.candidate),str(demo.planning_guide.opened)]; if state != last: print("DBG_TICK ",state); last = state; await process_frame
	check(demo.preview_thread == null,"preview worker finishes")
func gpu_flow(world: ContinuousWorld,available: Array[Dictionary]) -> void:
	var demo: ContinuousValleyDemo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await RenderingServer.frame_post_draw
	demo.clock.stop_output()
	demo._start_world({},world.fork())
	demo._sync_buildings()
	var guide: PanelContainer = demo.planning_guide
	var p := Vector2(float(available[0]["position"][0]),float(available[0]["position"][1]))
	guide.choose_plan("bluegreen")
	guide.map_click(p,false)
	guide.commit_scope()
	demo.pointer = demo.point(p)
	guide.sync()
	print("DBG_BEFORE_REQUEST opened=",guide.opened," stage=",guide.stage," ptr=",demo.pointer," p=",p," world_at=",demo.world_at(demo.pointer)," candidate=",JSON.stringify(guide.candidate)," ident=",JSON.stringify(guide.comparison_identity())); var held_rng := demo.model.world.rng.snapshot()
	demo._request_preview()
	demo.model.submit({"kind":"charter","plan_id":"compact","community_ids":["west-1"]})
	demo._request_preview()
	await wait_preview(demo)
	check(guide.comparison.is_empty() and not demo.preview_started,"late worker keeps captured identity after newer request and is rejected")
	demo._request_preview()
	await wait_preview(demo)
	print("DBG_AFTER_PREVIEW comparison=",JSON.stringify(guide.comparison)," key=",JSON.stringify(guide.comparison_key)," identity=",JSON.stringify(guide.comparison_identity())," context=",JSON.stringify(demo.preview_context_key)," requested=",demo.preview_requested," started=",demo.preview_started," thread=",demo.preview_thread," opened=",guide.opened," stage=",guide.stage," scope=",JSON.stringify(guide.scope)," candidate=",JSON.stringify(guide.candidate)," serial=",demo.model.world.action_serial," phrase=",demo.model.world.phrase_index," shown=",demo.shown_world.phrase_index); check(guide.comparison.has("variants") and guide.comparison["variants"].size() == 3 and demo.preview_started,"actual Space worker returns three public choices and plays chosen PCM")
	print("DBG_DETAIL ",guide.detail.text); check(guide.detail.text.contains("暂不建") and guide.detail.text.contains("全城净增") and guide.detail.text.contains("下一步"),"planning guide exposes actual service tradeoffs and next opportunity")
	for kind: String in ["none","park","civic"]:
		guide.choose_anchor(kind)
		check(demo.preview_player.stream.data == guide.comparison["variants"][kind]["pcm"] and demo.preview_thread == null,kind+" switches same captured PCM without resimulation")
	check(demo.model.world.rng.snapshot() == held_rng and demo.model.world.buildings.size() == world.buildings.size(),"preview and instant comparison never grow live city")
	var release := InputEventKey.new()
	release.keycode = KEY_SPACE
	release.pressed = false
	demo._input(release)
	check(not demo.preview_player.playing and not demo.preview_duck_owned and not demo.model.synth.ducking,"Space release restores live mix immediately through existing fade")
	await RenderingServer.frame_post_draw
	guide.reset_size()
	await RenderingServer.frame_post_draw
	check(guide.get_rect().end.x <= demo.size.x and guide.get_rect().end.y <= demo.size.y,"public comparison panel fits actual viewport")
	root.get_texture().get_image().save_png(OUT+"_三种选择.png")
	var old_key: Array = guide.comparison_key.duplicate(true)
	var old_result: Dictionary = guide.comparison
	demo.pointer = demo.point(Vector2(float(available[1]["position"][0]),float(available[1]["position"][1])))
	guide.sync()
	check(guide.comparison.is_empty() and not guide.accept_comparison(old_result,old_key),"moving to another actual site invalidates derived comparison")
	demo.pointer = demo.point(p)
	guide.sync()
	guide.choose_anchor("none")
	var before := demo.model.world.snapshot()
	guide.map_click(p,false)
	check(demo.model.world.public_sites == before["public_sites"] and demo.model.world.development_charters == before["development_charters"] and demo.model.world.pending_actions.any(func(op:Dictionary)->bool:return op["kind"] == "charter"),"confirm not building preserves existing objects and queued charter")
	demo.context = {"kind":"retune","id":world.communities["west-1"]["members"][0]}
	demo._request_preview()
	guide.open_tool()
	await wait_preview(demo)
	check(not demo.preview_player.playing and not demo.preview_duck_owned,"generic preview finishing after planning opens is discarded")
	guide.choose_plan("bluegreen")
	guide.map_click(p,false)
	guide.commit_scope()
	demo.pointer = demo.point(p)
	guide.sync()
	guide.choose_anchor("civic")
	var rate: int = world.cfg["timing"]["sample_rate"]
	var live_at: int = demo.model.next_boundary-rate*2
	demo.clock.renderer.transport.rendered_frames = live_at
	demo.clock.renderer.transport.audible_frame = live_at
	demo.clock.start_output(demo.model._mix_frame,{},demo.clock.renderer.snapshot())
	demo._request_preview()
	await wait_preview(demo)
	check(demo.preview_started,"public comparison plays alongside real output")
	await create_timer(3.5).timeout
	check(demo.clock.underruns == 0 and demo.shown_world.phrase_index > world.phrase_index,"actual WASAPI public preview crosses normal growth without skips")
	check(guide.comparison.is_empty() and not demo.preview_player.playing and not demo.preview_duck_owned,"growth invalidates public preview and restores ensemble")
	report["live"] = {"driver":AudioServer.get_driver_name(),"skips":demo.clock.underruns,"max_voices":demo.model.synth.max_voice_count,"phrase":demo.shown_world.phrase_index}
	demo.clock.stop_output()
	demo.free()
	await process_frame
