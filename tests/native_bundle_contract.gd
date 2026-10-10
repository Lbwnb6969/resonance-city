extends SceneTree
## External probe: current continuous Demo and native DLL from an isolated pack.
var checks: Array[Dictionary] = []
var failed := false
var output := ""

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks.append({"passed":ok,"description":label})
	if not ok:
		failed = true
		push_error("NATIVE_BUNDLE_FAIL "+label)

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--result="): output = argument.trim_prefix("--result=")
	assert(not output.is_empty())
	_check(not root.has_node("MCPRuntimeServer"),"development server stripped")
	_check(ClassDB.class_exists("CityPadMixer"),"native DLL loaded outside source checkout")
	_check(not FileAccess.file_exists("res://tests/round120_native_audio.gd"),"test sources excluded")
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	var packed: PackedScene = load(main_scene)
	var demo: ContinuousValleyDemo = packed.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await RenderingServer.frame_post_draw
	demo.clock.stop_output()
	demo.set_process(false)
	_check(demo.model.world.buildings.size() == 18 and demo.sprites.size() == 18,"current continuous main scene builds opening city")
	_check(demo.planning_guide.visible and demo.planning_guide.cards.get_child_count() == 3,"portable opening offers three development charters")
	demo.planning_guide.hide_tool()
	var charter_city: ContinuousWorld = demo.model.world.fork()
	var scope: Array = [charter_city.communities.keys()[0]]
	var charter_request := charter_city.request({"kind":"charter","plan_id":"compact","community_ids":scope},int(charter_city.cfg["timing"]["phrase_frames"]))
	charter_city.Charter.commit(charter_city,charter_city.pending_actions.back(),int(charter_city.cfg["timing"]["phrase_frames"]))
	var resumed: ContinuousWorld = charter_city.fork()
	_check(charter_request["accepted"] and resumed.development_charters == charter_city.development_charters and resumed.Charter.for_community(resumed,str(scope[0]))["plan_id"] == "compact","portable charter operation and snapshot persistence")
	_check(demo.model.synth.theme.is_empty() and not demo.MusicRules.opportunity(demo.shown_world,"west-1",demo.model.audible_score())["qualified"],"portable opening respects real community theme eligibility")
	var focused_copy := ContinuousAudioModel.from_state(demo.model.capture_state())
	focused_copy.synth.focused_community = "west-1"
	_check(ContinuousAudioModel.from_state(focused_copy.capture_state()).synth.focused_community == "west-1","portable runtime preserves focused community")
	var river_world: ContinuousWorld = demo.model.world.fork()
	for i in range(2): river_world.settle((river_world.phrase_index+1)*int(river_world.cfg["timing"]["phrase_frames"]))
	river_world.bridge = false
	river_world.rebuild_graph()
	var river_model := ContinuousAudioModel.new(river_world)
	var river_relations: Array = preload("res://scripts/world/river_call_response.gd").pairs(river_world)
	_check(not river_relations.is_empty() and not river_model.synth.response.is_empty() and river_model.synth.response.get("generation",0) == 1,"packed river community answers without a bridge using actual spatial pairs")
	var river_start: int = river_world.phrase_index*int(river_world.cfg["timing"]["phrase_frames"])
	var river_events_ok := false
	for node in river_model.synth.musical_nodes.values():
		if not node["answer"]: continue
		var river_events: Array = river_model.synth.musical_events(node,river_start,22050*16,22050)
		river_events_ok = not river_events.is_empty() and river_events.all(func(e:Dictionary)->bool:return e["generation"] == 1 and e["onset"]-e["source_onset"] == 22050)
	_check(river_events_ok,"packed response events retain their source and exact two-beat delay")
	_check(demo.model.synth.native_mixer != null and demo.model.synth.native_enabled,"opening score uses native mixer")
	_check(ClassDB.class_exists("CityMaskUnion") and demo.shadow_layer.mask_merger != null and demo.shadow_layer.native_batches > 0,"opening shadows use native batch merger")
	var native_audio := ContinuousAudioModel.from_state(demo.model.capture_state())
	var script_audio := ContinuousAudioModel.from_state(demo.model.capture_state())
	script_audio.synth.native_enabled = false
	var audio_frame: int = demo.clock.renderer.transport.rendered_frames
	var audio_rate: int = demo.model.world.cfg["timing"]["sample_rate"]
	_check(native_audio.render_block(demo.clock.renderer.state.duplicate(true),audio_frame,256,audio_rate) == script_audio.render_block(demo.clock.renderer.state.duplicate(true),audio_frame,256,audio_rate),"rebuilt native mixer preserves opening PCM against script")
	native_audio.close_background_settlement()
	script_audio.close_background_settlement()
	var textures_ok := true
	for texture in demo.textures.values(): textures_ok = textures_ok and texture.get_image().has_mipmaps()
	_check(textures_ok,"packed era textures have mipmaps")
	var point := Vector2.ZERO
	var found := false
	for lot in demo.model.world.lots:
		point = Vector2(lot["center"][0],lot["center"][1])
		if demo.model.world.placement(point)["allowed"]:
			found = true
			break
	_check(found,"playable seed location")
	if found:
		var private_city: ContinuousWorld = demo.model.world.fork()
		var planning_site := private_city.planning_candidate(point)
		var public_model := ContinuousAudioModel.new(private_city,demo.fixed_gain)
		var comparison := demo.PublicPreview.build(public_model.freeze(),planning_site,{},audio_frame)
		_check(comparison["variants"].size() == 3 and comparison["variants"]["none"]["pcm"].size() == audio_rate*3*4 and comparison["variants"]["park"]["accepted"] and comparison["variants"]["civic"]["accepted"] and public_model.world.buildings.size() == 18,"portable public comparison renders three real choices without changing city")
		var planned := false
		if not planning_site.is_empty() and bool(planning_site["allowed"]):
			var action := private_city.request({"kind":"reserve","position":[point.x,point.y]},int(private_city.cfg["timing"]["phrase_frames"]))
			if bool(action["accepted"]):
				private_city.settle(int(private_city.cfg["timing"]["phrase_frames"]))
				var json_snapshot: Dictionary = CityArchive._json_value(private_city.snapshot())
				var restored_city := ContinuousWorld.new(private_city.rng.seed_hex,false)
				restored_city.restore(json_snapshot)
				planned = restored_city.planning_reservations.size() == 1 and not bool(restored_city.placement(point)["allowed"])
		_check(planned,"packed player reservation survives JSON DNA geometry and blocks growth")
	if found:
		_check(demo._hover_placement(point) == demo.model.world.placement(point),"hover matches placement before change")
		var accepted := demo.model.submit({"kind":"seed","position":[point.x,point.y],"midi":48})
		_check(accepted["accepted"],"packed player operation accepted")
		var boundary := demo.model.next_boundary
		demo.model.enable_background_settlement()
		demo.model.prepare_settlement(boundary-22050,22050)
		var base_environment := demo.model.world.environment_cache
		var base_count := base_environment.size()
		demo.model.world.road_environment(Vector2(3.123,4.567),Vector2(7.891,10.123))
		_check(base_environment.is_read_only() and demo.model.world.edge_cache.is_read_only() and base_environment.size() == base_count and not demo.model.world.environment_pending.is_empty(),"packed worker freezes roots while new queries use private delta")
		while not demo.model.settlement_job.completed(): await process_frame
		demo.model.prepare_settlement(boundary-22050,22050)
		demo._sync_buildings()
		await RenderingServer.frame_post_draw
		var old_ground_updates: int = demo.city_ground_layer.update_count
		var old_building_syncs: int = demo.building_sync_count
		demo.clock.renderer.transport.rendered_frames = boundary
		demo.clock.renderer.render(512)
		_check(demo.model.settlement_stats["adopted"] == 1 and demo.model.settlement_stats["fallbacks"] == 0,"packed worker result adopted at original phrase frame")
		_check(demo.model.prepared_audio_phrase == demo.model.world.phrase_index and demo.model.prepared_audio_buildings == demo.model.world.buildings and not demo.model.capture_state().has("prepared_audio_buildings"),"packed worker audio projection adopted without entering DNA")
		var old_shown := demo.model.presentation_world(boundary-1)
		_check(demo.model.presentation_stats["prepared"] == 1 and demo.model.presentation_stats["reconstructed"] == 0 and old_shown.phrase_index == 0,"packed prepared old city used before audible boundary")
		demo.clock.renderer.transport.audible_frame = boundary-1
		demo.shown_world = old_shown
		demo._sync_buildings()
		await RenderingServer.frame_post_draw
		_check(demo.city_ground_layer.update_count == old_ground_updates and demo.building_sync_count == old_building_syncs and demo.city_ground_layer.city == old_shown,"packed old-world view retains geometry while rebinding data")
		var history: Array = demo.model.capture_state()["presentation_history"]
		_check(not history.is_empty() and history.all(func(entry: Dictionary) -> bool: return not entry.has("view") and not entry.has("derived")),"packed runtime view excluded from DNA")
		demo.clock.renderer.transport.audible_frame = boundary
		demo.shown_world = demo.model.presentation_world(boundary)
		demo._sync_buildings()
		var registered := true
		for record in demo.shadow_records.values(): registered = registered and record.has("mask_keys")
		_check(registered and demo.shadow_layer.uploaded_pixels == 0,"packed transparent newborn shadows register without uploading unchanged masks")
		demo.clock.renderer.transport.audible_frame = boundary+2205
		demo.shown_world = demo.model.presentation_world(boundary+2205)
		demo._sync_buildings()
		var partial := not demo.revealing_buildings.is_empty()
		demo.clock.renderer.transport.audible_frame = boundary+4410
		demo._sync_buildings()
		_check(partial and demo.shadow_layer.updated_tile_count > 0 and demo.shadow_layer.uploaded_pixels > 0,"packed audible growth updates local shadow tiles")
		demo.clock.renderer.transport.audible_frame = boundary+33075
		demo.shown_world = demo.model.presentation_world(boundary+33075)
		demo._sync_buildings()
		_check(not demo._hover_placement(point)["allowed"] and demo._hover_placement(point) == demo.model.world.placement(point),"growth invalidates hover placement")
		_check(demo.shown_world.phrase_index == 1 and demo.sprites.size() == demo.shown_world.buildings.size(),"committed city revealed at audible frame")
	var mature_materials: Dictionary = {}
	for sprite in demo.sprites.values():
		if sprite.progress >= 1.0: mature_materials[sprite.material] = true
	_check(mature_materials.size() == 1,"packed mature buildings share one growth material")
	await RenderingServer.frame_post_draw
	var retained_projection: Dictionary = demo.city_ground_layer.urban_parts["public"].projected.duplicate(true)
	_check(not demo.shadow_layer.scaled_masks.is_empty() and demo.shadow_layer.scaled_masks.size() < demo.shadow_layer.patches.size(),"packed shadow patches share resampled alpha")
	var screen_error := 0.0
	demo.view_zoom = 0.54
	demo.pan = Vector2(100,-150)
	demo._sync_buildings()
	for id in demo.sprites:
		screen_error = maxf(screen_error,demo.sprites[id].global_position.distance_to(demo.point(WorldCoupling.position_of(demo.shown_world.by_id[id]))))
	_check(screen_error < 0.001,"packed camera projection")
	await RenderingServer.frame_post_draw
	_check(not retained_projection.is_empty() and demo.city_ground_layer.urban_parts["public"].projected == retained_projection,"packed camera redraw retains exact ground projections")
	var terrain_draws: int = demo.terrain_layer.rebuild_count
	var ground_draws: int = demo.city_ground_layer.rebuild_count
	var shadow_updates: int = demo.shadow_layer.rebuild_count
	demo.pan += Vector2(12,-6)
	demo._sync_buildings()
	await RenderingServer.frame_post_draw
	_check(demo.terrain_layer.rebuild_count == terrain_draws and demo.city_ground_layer.rebuild_count == ground_draws and demo.shadow_layer.rebuild_count == shadow_updates,"packed camera pan reuses retained ground and shadow tiles")
	# Sorting is reused, while alpha and reveal progress are checked per hit.
	var sprite: Sprite2D = demo.sprites.values()[0]
	var id: String = demo.sprites.keys()[0]
	var image: Image = demo.asset_images[demo.shown_world.by_id[id]["type"]]
	var hit := ""
	for y in range(image.get_height()/2,image.get_height(),7):
		for x in range(0,image.get_width(),7):
			if image.get_pixel(x,y).a <= 0.9: continue
			hit = demo._hit(sprite.to_global(sprite.offset+Vector2(x,y)))
			if not hit.is_empty(): break
		if not hit.is_empty(): break
	_check(not hit.is_empty(),"cached depth order preserves alpha hit after camera move")
	demo.scenery.sync(demo)
	var scenery_positions := true
	for prop in demo.scenery.props.values():
		var p: Vector2 = prop.get_meta("world_position")
		if prop.visible: scenery_positions = scenery_positions and prop.global_position.distance_to(demo.point(p)) < 0.001
	_check(not demo.scenery.prop_projections.is_empty() and scenery_positions,"packed static scenery projection cache matches moving props and camera")
	var sample_traffic: Array = [{"road":"a","position":Vector2.ZERO},{"road":"a","position":Vector2(10,10)},{"road":"b","position":Vector2(0.5,0)},{"road":"b","position":Vector2(10,10)}]
	var sample_access := {"agent":{"position":Vector2.ZERO,"access":{"road":"a"}}}
	demo.scenery._index_traffic(sample_traffic,sample_access)
	_check(sample_access["agent"]["traffic"] == sample_traffic.slice(0,3),"packed traffic index retains ordered same-road and nearby junction agents")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.get_base_dir()+"/运行包Demo.png")
	var regional_key := InputEventKey.new()
	regional_key.keycode = KEY_E
	regional_key.pressed = true
	regional_key.shift_pressed = true
	demo._input(regional_key)
	demo.clock.stop_output()
	demo._sync_buildings()
	var regional_frame := demo.shown_world.phrase_index*int(demo.shown_world.cfg["timing"]["phrase_frames"])
	_check(demo.shown_world.buildings.size() == 1511 and demo.shown_world.transit_lines.size() == 8 and demo.sprites.size() == 1511,"packed Shift+E opens naturally grown regional sample")
	_check(demo.clock.renderer.transport.rendered_frames >= regional_frame and demo.clock.renderer.transport.rendered_frames < demo.model.next_boundary,"packed regional audio resumes sample phrase instead of zero")
	_check(demo.shown_world.terrain.land_at(Vector2(0,110)) and not demo.shown_world.terrain.land_at(Vector2(0,120)) and demo.view_zoom < 0.55,"packed regional terrain and home camera cover all three reaches")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.get_base_dir()+"/三河段大城.png")
	var names: Node2D = demo.community_label_layer
	var name_draws: int = names.draw_count
	var name_layouts: int = names.layout_updates
	var name_geometry: int = names.geometry_updates
	demo._sync_buildings()
	demo.queue_redraw()
	await RenderingServer.frame_post_draw
	_check(names.draw_count == name_draws and names.layout_updates == name_layouts,"packed live HUD retains stationary community names")
	var name_bounds: Array[Rect2] = []
	var readable: bool = not names.labels.is_empty() and names.labels.size() < names.anchors.size()
	for label in names.labels:
		for bounds in name_bounds: readable = readable and not bounds.intersects(label["bounds"])
		name_bounds.append(label["bounds"])
	_check(readable,"packed regional labels remove screen overlaps")
	demo.pan += Vector2(60,-30)
	demo._sync_buildings()
	_check(names.geometry_updates == name_geometry and names.layout_updates == name_layouts+1,"packed camera reuses label ground anchors")
	demo.black = true
	demo._sync_buildings()
	_check(not names.visible,"packed black listening hides retained map names")
	var phase_state: Dictionary = demo.clock.renderer.state.duplicate(true)
	var audio_at: int = demo.clock.renderer.transport.rendered_frames
	demo.model.synth.render_block(phase_state,audio_at,22050,22050)
	demo.model.synth.render_block(phase_state,audio_at+22050,512,22050)
	var priority_sorts: int = demo.model.synth.pad_priority_sorts
	demo.model.synth.render_block(phase_state,audio_at+22562,512,22050)
	_check(demo.model.synth.pad_priority_sorts == priority_sorts and demo.model.synth.last_voice_count <= 70,"packed settled voice priorities reuse sort within the voice budget")
	demo.black = false
	demo._sync_buildings()
	await RenderingServer.frame_post_draw
	var regional_ground_draws: Dictionary = {}
	var regional_ground_keys: Dictionary = {}
	for part_name in demo.city_ground_layer.urban_parts:
		regional_ground_draws[part_name] = demo.city_ground_layer.urban_parts[part_name].rebuild_count
		regional_ground_keys[part_name] = demo.city_ground_layer.urban_parts[part_name].key.duplicate(true)
	demo.model.enable_background_settlement()
	demo.model.prepare_settlement(demo.model.next_boundary-22050,22050)
	while not demo.model.settlement_job.completed(): await process_frame
	demo.model.prepare_settlement(demo.model.next_boundary-22050,22050)
	var growth_at: int = demo.model.next_boundary
	demo.model.render_block(phase_state,growth_at-64,128,22050)
	_check(int(demo.model.audio_preparation_stats["used"]) > 0 and demo.model.prepared_audio_update["stereo"].size() == demo.model.audio_city().size() and demo.model.synth.last_voice_count <= 70,"packed worker sound groups commit on the regional growth boundary within the voice budget")
	demo.clock.renderer.transport.rendered_frames = growth_at+64
	demo.clock.renderer.transport.audible_frame = growth_at+64
	demo.shown_world = demo.model.presentation_world(growth_at+64)
	demo._sync_buildings()
	await RenderingServer.frame_post_draw
	_check(demo.city_ground_layer.urban_parts.size() == 6 and regional_ground_draws.keys().all(func(part_name: String) -> bool:
		var part: Node2D = demo.city_ground_layer.urban_parts[part_name]
		var changed: bool = part.key != regional_ground_keys[part_name]
		return part.rebuild_count == regional_ground_draws[part_name]+(1 if changed else 0)), "packed regional growth redraws only changed urban drawing parts")
	demo.queue_free()
	await process_frame
	FileAccess.open(output.get_base_dir()+"/Godot及第三方许可.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info(),"engine_license":Engine.get_license_text(),"third_party_licenses":Engine.get_license_info(),"third_party_copyright":Engine.get_copyright_info()},"\t")+"\n")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"status":"FAIL" if failed else "PASS","engine":Engine.get_version_info()["string"],"checks":checks,"scope":"Current continuous Demo, native pad mixer and simulated audible boundary in isolated GPU pack; Dummy output, no physical listening or long stress"},"\t")+"\n")
	print("NATIVE_BUNDLE_ISOLATED ","FAIL" if failed else "PASS"," checks=",checks.size())
	quit(1 if failed else 0)
