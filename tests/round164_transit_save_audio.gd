extends SceneTree
## One authored route continues through both player save formats and real
## vehicle observations. Musical qualification is observed, never fabricated.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var paths: Array[String] = []
var directory := ""

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _renderer(model: Model, snapshot: Dictionary = {}) -> Renderer:
	var result := Renderer.new(int(model.world.cfg["timing"]["sample_rate"]))
	result.source = model._mix_frame
	if not snapshot.is_empty(): result.restore(snapshot)
	return result

func _advance(renderer: Renderer, frame: int) -> void:
	while renderer.transport.rendered_frames < frame:
		renderer.render(mini(4096,frame-renderer.transport.rendered_frames))

func _pcm_difference(a: PackedVector2Array, b: PackedVector2Array) -> float:
	if a.size() != b.size(): return INF
	var difference := 0.0
	for index in range(a.size()): difference = maxf(difference,a[index].distance_to(b[index]))
	return difference

func _points(raw: Variant) -> PackedVector2Array:
	if raw is PackedVector2Array: return raw
	var result := PackedVector2Array()
	for point in raw:
		result.append(point if point is Vector2 else Vector2(float(point[0]),float(point[1])))
	return result

func _same_points(a: Variant, b: Variant) -> bool:
	var left := _points(a)
	var right := _points(b)
	if left.size() != right.size(): return false
	for index in range(left.size()):
		if left[index].distance_to(right[index]) > 0.000001: return false
	return true

func _line(city: World, line_id: String) -> Dictionary:
	for line in city.transit_lines:
		if str(line.get("id","")) == line_id: return line
	return {}

func _event(city: World, event_id: Variant) -> Dictionary:
	for event in city.events:
		if str(event.get("kind","")) == "transit_line" and str(event.get("event_id","")) == str(event_id): return event
	return {}

func _same_route(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty(): return false
	for field in ["id","stops","edges","frame","community_ids","covered_building_ids","intent_stop_ids","route_stops","route_mode"]:
		if a.get(field) != b.get(field): return false
	if not _same_points(a.get("path",[]),b.get("path",[])): return false
	var left: Array = a.get("legs",[])
	var right: Array = b.get("legs",[])
	if left.size() != right.size(): return false
	for index in range(left.size()):
		if str(left[index].get("from","")) != str(right[index].get("from","")) or str(left[index].get("to","")) != str(right[index].get("to","")): return false
		if not _same_points(left[index].get("path",[]),right[index].get("path",[])): return false
	return true

func _roundtrip(model: Model, renderer: Renderer, stage: String) -> Array:
	var city := {"model":model.capture_state(),"renderer":renderer.snapshot(),"view":{}}
	var binary := Archive.save(city,"round164 "+stage,directory)
	var exported := Archive.export_dna(city,directory+"/exports")
	_check(bool(binary.get("ok",false)) and bool(exported.get("ok",false)),stage+"_binary_and_dna_write")
	if not bool(binary.get("ok",false)) or not bool(exported.get("ok",false)): return []
	paths.append(str(binary["path"]))
	paths.append(str(exported["path"]))
	var saved := Archive.read(str(binary["path"]))
	var dna := Archive.read_dna(str(exported["path"]))
	_check(bool(saved.get("ok",false)) and bool(dna.get("ok",false)),stage+"_binary_and_dna_read")
	if not bool(saved.get("ok",false)) or not bool(dna.get("ok",false)): return []
	var binary_model := Model.from_state(saved["city"]["model"])
	var dna_model := Model.from_state(dna["model"])
	return [[binary_model,_renderer(binary_model,saved["city"]["renderer"])],
		[dna_model,_renderer(dna_model,dna["renderer"])],dna["dna"]]

func _pending_matches(city: World, projected: Variant, topology: Variant, event_id: Variant) -> bool:
	if city.pending_actions.size() != 1: return false
	var pending: Dictionary = city.pending_actions[0]
	return str(pending.get("kind","")) == "transit_line" and _same_points(pending.get("stop_positions",[]),projected) and pending.get("source_topology") == topology and str(pending.get("event_id","")) == str(event_id)

func _stop_truth_matches(a: World, b: World, line: Dictionary) -> bool:
	for stop_id in line.get("stops",[]):
		if a.transit_stop_record(str(stop_id)).is_empty() or b.transit_stop_record(str(stop_id)).is_empty(): return false
		if a.transit_stop_position(str(stop_id)).distance_to(b.transit_stop_position(str(stop_id))) > 0.000001: return false
	return true

func _transit_zone(city: World) -> Dictionary:
	for zone in city.functional_zones:
		if str(zone.get("role","")) == "transit": return zone
	return {}

func _fixture(city: World) -> Dictionary:
	var positions: Array = []
	for road_id: String in ["west-road-1","west-road-2","west-road-3"]:
		for road in city.roads:
			if str(road.get("id","")) != road_id: continue
			var path: PackedVector2Array = road["path"]
			var point := path[path.size()/2]
			positions.append([point.x,point.y])
	return city.transit_plan_preview(positions)

func _run() -> void:
	directory = "user://round164_transit_save_audio_%d" % Time.get_ticks_usec()
	var city := World.new("2026101100000164",true,"river_valley")
	city.build_starter("bright")
	var model := Model.new(city,1.3409036)
	var renderer := _renderer(model)
	var before := model.capture_state()
	var road_truth := {"nodes":city.nodes.duplicate(true),"roads":city.roads.duplicate(true)}
	var old_line_ids := city.transit_lines.map(func(line: Dictionary) -> String: return str(line["id"]))
	var preview := _fixture(city)
	_check(bool(preview.get("accepted",false)),"three_player_road_stops_form_a_real_connected_route")
	_check(model.capture_state() == before,"route_preview_keeps_live_rng_world_and_sound_state")
	if not bool(preview.get("accepted",false)):
		_finish()
		return
	var positions: Array = []
	for stop in preview.get("stops",[]): positions.append(stop["position"])
	var queued := model.submit({"kind":"transit_line","stop_positions":positions,"source_topology":preview["source_topology"]})
	_check(bool(queued.get("accepted",false)),"player_route_queues_for_the_real_phrase_boundary")
	if not bool(queued.get("accepted",false)):
		_finish()
		return
	var event_id: Variant = queued["event_id"]
	var line_id := "player-line-"+str(event_id)
	var boundary := model.next_boundary
	_check(_line(city,line_id).is_empty() and _pending_matches(city,positions,preview["source_topology"],event_id),"queued_stations_have_precise_geometry_without_early_activation")
	_advance(renderer,boundary-128)
	var pending_saves := _roundtrip(model,renderer,"pending")
	if pending_saves.is_empty():
		_finish()
		return
	var binary_model: Model = pending_saves[0][0]
	var binary_renderer: Renderer = pending_saves[0][1]
	var dna_model: Model = pending_saves[1][0]
	var dna_renderer: Renderer = pending_saves[1][1]
	_check(_pending_matches(binary_model.world,positions,preview["source_topology"],event_id) and _pending_matches(dna_model.world,positions,preview["source_topology"],event_id),"both_pending_formats_restore_geometry_topology_and_event_identity")
	_check(_line(binary_model.world,line_id).is_empty() and _line(dna_model.world,line_id).is_empty(),"pending_restore_does_not_reveal_the_route_early")
	# Continue every copy to the exact boundary. The saved copies still hold the
	# pending operation; rendering through the boundary is what reveals it.
	_advance(renderer,boundary+1)
	_advance(binary_renderer,boundary+1)
	_advance(dna_renderer,boundary+1)
	var reference_pcm := renderer.render(4096)
	var binary_pcm := binary_renderer.render(4096)
	var dna_pcm := dna_renderer.render(4096)
	evidence["pending_binary_pcm_error"] = _pcm_difference(reference_pcm,binary_pcm)
	evidence["pending_dna_pcm_error"] = _pcm_difference(reference_pcm,dna_pcm)
	_check(float(evidence["pending_binary_pcm_error"]) < 0.000001 and float(evidence["pending_dna_pcm_error"]) < 0.000001,"both_formats_continue_pcm_through_the_same_commit_boundary")
	var authored := _line(city,line_id)
	var event := _event(city,event_id)
	_check(not authored.is_empty() and bool(authored.get("authored",false)) and not event.is_empty() and int(event.get("frame",-1)) == boundary,"restored_pending_intent_becomes_one_authored_line_at_its_boundary")
	_check(_same_route(authored,_line(binary_model.world,line_id)) and _same_route(authored,_line(dna_model.world,line_id)),"binary_and_dna_commit_the_same_stations_legs_route_and_coverage")
	_check(_stop_truth_matches(city,binary_model.world,authored) and _stop_truth_matches(city,dna_model.world,authored),"binary_and_dna_hydrate_the_actual_projected_station_records")
	_check(event.get("stop_ids",[]) == authored.get("intent_stop_ids",[]) and _event(binary_model.world,event_id).get("stop_ids",[]) == event.get("stop_ids",[]) and _event(dna_model.world,event_id).get("stop_ids",[]) == event.get("stop_ids",[]),"one_event_preserves_the_committed_station_order")
	_check(old_line_ids.all(func(id: String) -> bool: return not _line(city,id).is_empty()),"the_authored_route_preserves_existing_lines")
	_check(city.nodes == road_truth["nodes"] and city.roads == road_truth["roads"],"projected_stations_do_not_rewrite_physical_roads_or_nodes")
	_check(not authored.get("covered_building_ids",[]).is_empty() and authored.get("community_ids",[]).size() >= 2,"author_route_coverage_refers_to_existing_houses_and_communities")
	var stop_id := str(authored.get("stops",[""])[0])
	_check(not city.network.nodes.has(stop_id),"evidence_exercises_a_projected_station_instead_of_a_legacy_node")
	var station_position := city.transit_stop_position(stop_id)
	_check(city._transit_growth_bonus(station_position,"commercial") > city._transit_growth_bonus(station_position+Vector2(80.0,80.0),"commercial"),"projected_stations_enter_the_existing_local_growth_priority")
	# A real traveler owns its occupancy and records arrivals through advance().
	# No direct demand score, role, MIDI, age or voice-budget edits are made.
	var baseline := model.freeze()
	var baseline_renderer := _renderer(baseline,renderer.snapshot())
	var rng_before := city.rng.snapshot()
	var line_index := city.transit_lines.find(authored)
	var traveler := Traveler.new("carriage",line_index)
	for tick in range(1201): traveler.advance(city,float(tick)*0.25)
	var observed := city.transit_flow_pending.duplicate(true)
	var passenger_activity := 0
	for observation in observed:
		if authored.get("stops",[]).has(str(observation.get("stop_id",""))):
			passenger_activity += int(observation.get("boarded",0))+int(observation.get("alighted",0))+int(observation.get("transfers",0))
	_check(passenger_activity > 0 and not observed.is_empty(),"a_vehicle_actually_visits_authored_stations_and_records_passengers")
	_check(city.rng.snapshot() == rng_before and city.transit_demand_score(stop_id) == 0.0,"vehicle_observations_wait_for_phrase_commit_without_consuming_city_rng")
	var settled_saves := _roundtrip(model,renderer,"settled_with_passengers")
	if settled_saves.is_empty():
		_finish()
		return
	for restored in [settled_saves[0][0],settled_saves[1][0]]:
		_check(_same_route(authored,_line(restored.world,line_id)) and _stop_truth_matches(city,restored.world,authored),"settled_"+("binary" if restored == settled_saves[0][0] else "dna")+"_retains_author_route_station_truth")
		_check(restored.world.transit_flow_pending == observed,"settled_"+("binary" if restored == settled_saves[0][0] else "dna")+"_retains_uncommitted_real_passengers")
	var continued: Model = settled_saves[1][0]
	var continued_renderer: Renderer = settled_saves[1][1]
	var flow_boundary := continued.next_boundary
	_advance(continued_renderer,flow_boundary+1)
	_advance(baseline_renderer,flow_boundary+1)
	var demand_peak := 0.0
	for id in authored.get("stops",[]): demand_peak = maxf(demand_peak,continued.world.transit_demand_score(str(id)))
	_check(continued.world.transit_flow_pending.is_empty() and demand_peak > 0.0,"json_continuation_commits_real_passenger_memory_once")
	var demand_before := continued.world.transit_demand.duplicate(true)
	# Existing settlement consumes observations after growth/network derivation;
	# the following phrase must consume the committed demand, not the arrival UI.
	var music_boundary := continued.next_boundary
	_advance(continued_renderer,music_boundary+1)
	_advance(baseline_renderer,music_boundary+1)
	var zone := _transit_zone(continued.world)
	_check(float(zone.get("peak_demand",0.0)) > 0.0 and not zone.get("community_ids",[]).is_empty(),"committed_author_station_demand_reaches_real_functional_zone_qualification")
	_check(str(zone.get("music_role","")) in ["pulse","pulse_dense"],"transit_qualification_uses_the_existing_pulse_role")
	var rhythm_qualified := false
	for cid in zone.get("community_ids",[]):
		if continued.world.functional_zone_roles(str(cid)).has(str(zone.get("music_role",""))): rhythm_qualified = true
	_check(rhythm_qualified,"transit_demand_reaches_existing_community_rhythm_conditions")
	_check(_same_route(_line(continued.world,line_id),_line(baseline.world,line_id)),"future_phrases_keep_the_same_authored_route_without_recreating_stops")
	_check(continued.world.transit_demand != demand_before and continued.world.transit_flow_pending.is_empty(),"later_phrases_decay_memory_without_replaying_saved_arrivals")
	var source_before := continued.capture_state()
	var renderer_before := continued_renderer.snapshot()
	var sound_copy := continued.freeze()
	var sound_renderer := _renderer(sound_copy,renderer_before)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var heard := sound_renderer.render(rate*3)
	var without_arrivals := baseline_renderer.render(rate*3)
	evidence["passenger_observations"] = observed.size()
	evidence["passenger_activity"] = passenger_activity
	evidence["committed_demand_peak"] = demand_peak
	evidence["zone"] = zone
	evidence["rhythms"] = sound_copy.synth.rhythms.duplicate(true)
	evidence["theme_zone_roles"] = sound_copy.synth.theme.get("zone_roles",[])
	evidence["three_second_pcm_difference"] = _pcm_difference(heard,without_arrivals)
	evidence["voice_budget"] = int(sound_copy.synth.score["render_voice_limit"])
	evidence["max_voices"] = sound_copy.synth.max_voice_count
	evidence["audibility_condition"] = "Arrival memory enters existing pulse/pulse_dense qualification; facility, market, garden and workshop priority and available score slots still determine the audible pattern. PCM equality is allowed."
	_check(continued.capture_state() == source_before and continued_renderer.snapshot() == renderer_before,"offline_causal_listening_preserves_live_rng_phase_cursor_and_world")
	_check(sound_copy.synth.gain == continued.synth.gain and sound_copy.synth.score["render_voice_limit"] == continued.synth.score["render_voice_limit"] and sound_copy.synth.max_voice_count <= int(sound_copy.synth.score["render_voice_limit"]),"real_route_listening_keeps_the_existing_gain_and_voice_budget")
	_check(not _event(continued.world,event_id).is_empty() and _line(continued.world,line_id).get("frame",-1) == boundary,"continued_city_preserves_original_authorship_and_event_frame")
	_finish()

func _finish() -> void:
	# Only disposable files written by this invocation are removed.
	for path in paths:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	if not directory.is_empty():
		if DirAccess.dir_exists_absolute(directory+"/exports"): DirAccess.remove_absolute(directory+"/exports")
		if DirAccess.dir_exists_absolute(directory): DirAccess.remove_absolute(directory)
	print("ROUND164_TRANSIT_SAVE_AUDIO ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"evidence":evidence,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
