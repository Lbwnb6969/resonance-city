extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Links = preload("res://scripts/visual/heard_reply_links.gd")
const Layer = preload("res://scripts/visual/city_music_activity_layer.gd")
const OUTPUT := "res://验证记录/core_slice_作者应答可视/"
var checks: Dictionary = {}
var failures: Array[String] = []

class MapView extends Control:
	var model: RefCounted
	var shown_world: RefCounted
	var black := false
	var preview_started := false
	var view_zoom := 1.0
	var daylight_state := {"night_strength":0.0}
	var clock := {"active":true,"renderer":{"transport":{"audible_frame":0.0,"sample_rate":22050}}}
	func point(p: Vector2) -> Vector2:
		return Vector2((p.x-p.y)*28,(p.x+p.y-32)*14)+Vector2(640,400)
	func note_name(note: int) -> String:
		return str({0:"C",2:"D",4:"E",7:"G",9:"A"}.get(posmod(note,12),"·"))

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _render(model: RefCounted,state: Dictionary,finish: int) -> void:
	while model.rendered_until < finish:
		var start: int = model.rendered_until
		model.render_block(state,start,mini(1024,finish-start),22050)

func _row(rows: Array[Dictionary],id: String) -> Dictionary:
	for row in rows:
		if str(row["event_id"]) == id: return row
	return {}

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	var start := city.phrase_index*int(city.cfg["timing"]["phrase_frames"])
	var model := Model.new(city.fork())
	model.rendered_until = start
	model.enable_music_activity()
	var reply: Dictionary = {}
	for node: Dictionary in model.synth.musical_nodes.values():
		if not bool(node.get("active",false)) or not bool(node.get("answer",false)): continue
		for event: Dictionary in model.synth.musical_events(node,start,model.phrase_frames,22050):
			if int(event["source_onset"]) < start or str(event["receiver_id"]).is_empty(): continue
			if reply.is_empty() or int(event["onset"]) < int(reply["onset"]): reply = event
	if reply.is_empty():
		check(false,"natural_world_has_actual_reply")
		_finish({})
		return
	var lead_probe := int(reply["source_onset"])+256
	var reply_probe := int(reply["onset"])+256
	var state := model.capture_state()
	_render(model,state,reply_probe+22050)
	var lead_rows: Array[Dictionary] = model.audible_music_activity(lead_probe)
	var reply_rows: Array[Dictionary] = model.audible_music_activity(reply_probe)
	var lead := _row(lead_rows,str(reply["source_event_id"]))
	var heard_reply := _row(reply_rows,str(reply["event_id"]))
	check(not lead.is_empty() and not heard_reply.is_empty() and int(heard_reply["onset"])-int(lead["onset"]) == 22050,"production_pcm_contains_exact_lead_and_two_beat_reply")
	var links := Links.new()
	check(links.observe(lead_rows,city,lead_probe,22050).is_empty() and links.observe(model.audible_music_activity(int(reply["onset"])-1),city,int(reply["onset"])-1,22050).is_empty(),"lead_and_prefetched_reply_do_not_draw_future_links")
	var current := links.observe(reply_rows,city,reply_probe,22050)
	check(current.size() == 1 and str(current[0]["source_event_id"]) == str(lead["event_id"]) and str(current[0]["receiver_id"]) == str(reply["receiver_id"]),"currently_heard_reply_links_only_to_its_exact_observed_lead")
	var unobserved := Links.new()
	check(unobserved.observe(reply_rows,city,reply_probe,22050).is_empty(),"reply_without_a_heard_source_does_not_invent_a_connection")
	var broken_rows: Array[Dictionary] = [heard_reply.duplicate()]
	broken_rows[0]["source_event_id"] = ""
	check(links.observe(broken_rows,city,reply_probe,22050).is_empty(),"missing_source_event_identity_draws_nothing")
	var expired := int(reply["onset"])+ceili(Links.SHOW_SECONDS*22050)
	check(links.observe(model.audible_music_activity(expired),city,expired,22050).is_empty(),"heard_links_expire_after_short_reply_gesture")
	var view := MapView.new()
	view.model = model
	view.shown_world = city
	view.size = Vector2(1280,800)
	root.add_child(view)
	var layer := Layer.new()
	view.add_child(layer)
	var before := model.capture_state()
	var snapshot := city.snapshot()
	view.clock.renderer.transport.audible_frame = lead_probe
	layer.sync(view)
	view.clock.renderer.transport.audible_frame = reply_probe
	layer.sync(view)
	var day_alpha: float = layer.trails[0]["alpha"] if not layer.trails.is_empty() else 0.0
	var day_ink: Color = layer.trails[0]["to_ink"] if not layer.trails.is_empty() else Color.BLACK
	check(layer.trails.size() == 1 and layer.trail_ground.z_index == -26 and not layer.trail_ground.z_as_relative and layer.marks.any(func(mark: Dictionary) -> bool: return mark["role"] == "reply" and int(mark["pitch"]) == int(heard_reply["pitch"])),"thin_ground_arc_preserves_existing_reply_pitch_and_double_ring")
	var ordinary_alpha := clampf(float(heard_reply["strength"])/0.022,0.0,1.0)*0.88*(1.0-float(reply_probe-int(heard_reply["onset"]))/22050.0/Layer.MARK_SECONDS)
	check(is_equal_approx(day_alpha,ordinary_alpha) and not bool(layer.trails[0].get("authored",false)),"ordinary_reply_keeps_original_strength_based_visibility")
	view.daylight_state["night_strength"] = 1.0
	layer.sync(view)
	check(layer.trails.size() == 1 and float(layer.trails[0]["alpha"]) == day_alpha and layer.trails[0]["to_ink"] != day_ink,"night_brightens_ink_without_claiming_more_audible_strength")
	view.preview_started = true
	layer.sync(view)
	check(not layer.visible and layer.trails.is_empty() and layer.marks.is_empty() and layer.heard_reply_links.heard_leads.is_empty(),"preview_clears_marks_links_and_source_history")
	view.preview_started = false
	view.clock.renderer.transport.audible_frame = lead_probe
	layer.sync(view)
	view.black = true
	layer.sync(view)
	check(not layer.visible and layer.trails.is_empty() and layer.heard_reply_links.heard_leads.is_empty(),"black_screen_clears_heard_connections")
	view.black = false
	view.clock.active = false
	layer.sync(view)
	check(not layer.visible and layer.marks.is_empty() and layer.trails.is_empty(),"stopped_output_keeps_no_performance_marks")
	check(model.capture_state() == before and city.snapshot() == snapshot,"visual_projection_leaves_audio_state_world_archive_and_rng_unchanged")
	# Reuse exact heard production events on a read-only authored-house fixture;
	# the new visibility floor must still pass the observed-source gate.
	var authored_city := city.fork()
	authored_city.by_id[str(heard_reply["source_id"])]["player_expression"] = true
	authored_city.by_id[str(heard_reply["receiver_id"])]["player_expression"] = true
	var authored_snapshot: Dictionary = authored_city.snapshot()
	view.shown_world = authored_city
	view.clock.active = true
	layer.heard_reply_links.clear()
	view.clock.renderer.transport.audible_frame = reply_probe
	layer.sync(view)
	check(layer.trails.is_empty(),"authored_visibility_does_not_invent_an_unheard_source")
	view.clock.renderer.transport.audible_frame = lead_probe
	layer.sync(view)
	view.clock.renderer.transport.audible_frame = int(reply["onset"])-1
	layer.sync(view)
	check(layer.trails.is_empty(),"authored_visibility_does_not_draw_prefetched_reply")
	view.clock.renderer.transport.audible_frame = reply_probe
	layer.sync(view)
	var authored_alpha: float = layer.trails[0]["alpha"] if not layer.trails.is_empty() else 0.0
	check(layer.trails.size() == 1 and bool(layer.trails[0].get("authored",false)) and authored_alpha > 0.70 and layer.marks.any(func(mark: Dictionary) -> bool: return str(mark["event_id"]) == str(heard_reply["event_id"]) and is_equal_approx(float(mark["alpha"]),authored_alpha)),"heard_authored_reply_has_readable_arc_and_matching_receiver_rings")
	check(authored_city.snapshot() == authored_snapshot and model.capture_state() == before,"authored_visibility_floor_leaves_city_and_audio_unchanged")
	_finish({"lead":lead,"reply":heard_reply,"day_alpha":day_alpha,"authored_alpha":authored_alpha,"ground_z":layer.trail_ground.z_index})

func _finish(details: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	FileAccess.open(OUTPUT+"heard_reply_links.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"details":details,"scope":"Real production-model PCM activity plus read-only screen projection. Dummy only; no device or human listening conclusion."},"\t"))
	print("HEARD_REPLY_LINKS ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
