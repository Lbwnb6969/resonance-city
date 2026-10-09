extends SceneTree
const Era = preload("res://scripts/city/city_era.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
var checks: Array[String] = []
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, name: String) -> void:
	if not value:
		push_error(name)
		failures.append(name)
		quit(1)
	assert(value,name)
	checks.append(name)
func make_session() -> CityInterventions:
	var city: Array = []
	for index in range(4):
		var d := Schema.create("edge_%d" % index,"residential",Vector2i(7+index%2,7+index/2))
		d["current_midi"] = 48
		city.append(d)
	var session := Session.new(city,"2026100800000001")
	Era.enable(session)
	session.growth_enabled = true
	return session
func _last_boundary() -> void:
	var session := make_session()
	Era.enable(session,true)
	session.request_release(48,Vector2i(1,8),session.next_city_boundary()-1,0)
	var model := Model.new(session)
	model.synth.voice_grouping = true
	var state := model.synth.initial_state()
	model.render_block(state,model.next_boundary,1,session.transport.sample_rate)
	check(model.synth.routing.size() > 4 and model.synth.routing.all(func(route: Dictionary) -> bool: return route.has("era_change")),"boundary newborn joins the sound conversion")
	model.render_block(state,model.next_boundary,1,session.transport.sample_rate)
	check(model.synth.map_width == 20,"new map updates the sound field width")
	check(model.synth._pan_for(Schema.create("center","residential",Vector2i(10,5))) == 0.0 and model.synth._pan_for(Schema.create("right","residential",Vector2i(11,5))) > 0.0,"20 tile projection uses scaled center/right split")
	var file := FileAccess.open("res://验证记录/Demo/时代Demo_第61轮/最终边界.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("ERA_FINAL_BOUNDARY_%s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit()

func run() -> void:
	if "--era-final-boundary" in OS.get_cmdline_user_args():
		_last_boundary()
		return
	# One focused contract for progression, boundary hold and restored intervention.
	var session := make_session()
	for index in range(35): session.settle(session.next_city_boundary())
	check(session.run["era"] == 1 and session.run["chapter"] == 3 and session.run["phrase"] == 11,"no early automatic cross")
	var last: int = session.next_city_boundary()
	var request := session.request_release(48,Vector2i(1,8),last-1,last-100)
	check(request["accepted"],"preceding boundary accepts intervention")
	session.settle(last)
	check(session.last_result["choice"]["verb"] == "release" and session.run["phase"] == "transition","pending settles then fallback cross")
	var frozen := session.phrase_index
	var vitality: Dictionary = {}
	for d in session.city: vitality[d["district_id"]] = d["vitality"]
	check(not session.request_release(48,Vector2i(2,8),last,last)["accepted"],"hold rejects interventions")
	session.settle(session.next_city_boundary())
	check(session.phrase_index == frozen and session.city.filter(func(d: Dictionary) -> bool: return d.get("visitor",false)).size() == 2,"land and two visitors without city tick")
	var copy := session.fork()
	check(copy.snapshot() == session.snapshot(),"expanded map snapshot restores")
	copy.settle(copy.next_city_boundary())
	check(copy.phrase_index == frozen and copy.run["offset"] == copy.transport.phrase_frame(1) and copy.run["chapter"] == 4,"release moves city anchor exactly one phrase")
	check(copy.settings["allowed_pitches"].has(53) and copy.settings["allowed_pitches"].has(59),"expanded F B proposals")
	for d in copy.city:
		if vitality.has(d["district_id"]): check(d["vitality"] == vitality[d["district_id"]],"old vitality unchanged during hold: "+d["district_id"])
	var visitor: Dictionary = copy._district("era2_visitor_0")
	var proposal: Dictionary = copy.catalog.filter(func(p: Dictionary) -> bool: return p["district_id"] == visitor["district_id"] and p["verb"] == "retune")[0]
	var visitor_pitch: int = proposal["allowed_pitches"][0]
	request = copy.request({"proposal_id":proposal["proposal_id"],"target":visitor_pitch},copy.next_city_boundary()-1,copy.next_city_boundary()-100)
	check(request["accepted"],"visitor retune after restored anchor")
	copy.settle(int(request["frame"]))
	check(copy._district(visitor["district_id"])["current_midi"] == visitor_pitch and copy.phrase_index == frozen+1,"first medieval intervention lands")
	# Real distinct-edge solution accounting: alternate the same three edges twice.
	var solved := make_session()
	for index in range(3):
		var id := "edge_%d" % index
		solved._district(id)["current_midi"] = 50
		solved._refresh_catalog()
		var p: Dictionary = solved.catalog.filter(func(p: Dictionary) -> bool: return p["district_id"] == id and p["verb"] == "retune")[0]
		solved.request({"proposal_id":p["proposal_id"],"target":48},solved.next_city_boundary()-1,0)
		solved.settle(solved.next_city_boundary())
	var unique: int = solved.run["resolved"].size()
	solved._district("edge_0")["current_midi"] = 50
	solved._refresh_catalog()
	var p: Dictionary = solved.catalog.filter(func(p: Dictionary) -> bool: return p["district_id"] == "edge_0" and p["verb"] == "retune")[0]
	solved.request({"proposal_id":p["proposal_id"],"target":48},solved.next_city_boundary()-1,0)
	solved.settle(solved.next_city_boundary())
	check(unique >= 3 and solved.run["resolved"].size() == unique,"same unordered edge does not count twice")
	solved.run["chapter"] = 2
	solved.run["era_chapters"] = 1
	solved.run["phrase"] = 11
	solved.settle(solved.next_city_boundary())
	check(solved.run["transition"]["perfect"],"earned crossing after minimum two chapters")
	var saved := Model.new(solved)
	saved.synth.begin_era_transition(solved.run["transition"],solved.transport)
	check(saved.fork().snapshot() == saved.snapshot(),"transition sound snapshot restores")
	# Actual scene/audio/presentation together, one short GPU playthrough.
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var last_picture := ""
	while main.clock.renderer.transport.audible_frame < main.clock.renderer.transport.sample_rate*34:
		await process_frame
		var at: float = main.clock.renderer.transport.audible_frame/main.clock.renderer.transport.sample_rate
		var picture := "古典" if at < 16 else ("时代卡" if at < 22 else ("变换波" if at < 26 else "中世纪"))
		if "--capture-era" in OS.get_cmdline_user_args() and picture != last_picture and (at > 3 if picture == "古典" else at > (19 if picture == "时代卡" else (24 if picture == "变换波" else 33))):
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png("res://验证记录/Demo/时代Demo_第61轮/"+picture+".png")
			last_picture = picture
	check(main.model.session.run["era"] == 2 and main.model.session.run["phase"] == "playing","actual scene reaches playable medieval era")
	check(main.city_view.map_size == Vector2i(20,20) and main.release_pitch.item_count == 7,"actual new land and scale visible")
	check(main.clock.underruns == 0,"actual WASAPI no skips in the slice")
	main.clock.stop_output()
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://验证记录/Demo/时代Demo_第61轮/中世纪最终.png")
	var file := FileAccess.open("res://验证记录/Demo/时代Demo_第61轮/可玩流程.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"skips":main.clock.underruns,"run":main.model.session.run,"districts":main.model.session.city.size()},"  "))
	print("ERA_DEMO_%s checks=%d skips=%d" % ["PASS" if failures.is_empty() else "FAIL",checks.size(),main.clock.underruns])
	main.queue_free()
	await process_frame
	quit()
