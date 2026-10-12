extends SceneTree
## One real road-side oil lamp; no Demo scene, physical output, or window.
const Prop = preload("res://scripts/visual/valley_prop.gd")
const Light = preload("res://scripts/visual/classical_lamp_light.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const Projection2D = preload("res://scripts/world/world_projection.gd")
const OUTPUT := "res://验证记录/round209_古典油灯夜光/lamp_light_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class LampProbe extends Prop:
	var classical_draws := 0
	var retained_draws := 0
	func _draw_classical_lamp() -> void: classical_draws += 1
	func _draw_retained_lamp() -> void: retained_draws += 1

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func inherited_color(node: CanvasItem) -> Color:
	var result := Color.WHITE
	var item := node
	while item != null:
		result *= item.modulate
		var ancestor := item.get_parent()
		item = ancestor as CanvasItem
	return result

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_audio_only")
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var baseline := city.snapshot()
	var at := Vector2.INF
	var road_id := ""
	for road: Dictionary in city.roads:
		if bool(road["bridge"]) or str(road.get("kind","")) == "branch": continue
		var path: PackedVector2Array = road["path"]
		var candidate := path[path.size()/2]+Vector2(0.38,0)
		if not city.terrain.land_at(candidate): continue
		at = candidate
		road_id = str(road["id"])
		break
	check(at != Vector2.INF and not road_id.is_empty(),"fixture_uses_the_actual_scenery_road_side_lamp_position_on_land")
	var buildings := Node2D.new()
	buildings.y_sort_enabled = true
	buildings.position = Vector2(640,370)
	buildings.scale = Vector2(1.7,1.7)
	var tint := Color(0.27,0.37,0.53)
	buildings.modulate = tint*Color(1.06,1,1)
	root.add_child(buildings)
	var lamp := Prop.new()
	lamp.kind = "lamp"
	lamp.era = city.era
	lamp.set_meta("world_position",at)
	lamp.position = Projection2D.to_screen(at-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),city.terrain.height_at(at))
	lamp.reveal = 1.0
	lamp.modulate = Color(tint.r/buildings.modulate.r,1,1,lamp.reveal)
	buildings.add_child(lamp)
	lamp.sync_classical_lamp_light(0.0,tint)
	var light: Node2D = lamp.classical_lamp_light
	check(light != null and not light.visible and light.modulate.a == 0.0,"actual_oil_bowl_has_no_emission_during_daylight")
	lamp.sync_classical_lamp_light(1.0,tint)
	check(light.visible and light.modulate.a == 1.0 and light.get_parent() == lamp,"night_emission_exists_only_as_a_child_of_the_actual_first_era_oil_lamp")
	check(light.position == Vector2.ZERO and light.scale == Vector2.ONE and not light.y_sort_enabled and light.show_behind_parent and light.z_index == 0,"light_keeps_the_real_foot_depth_sort_and_draws_behind_opaque_pedestal")
	var flame := Light.flame_polygon()
	var small_wick := flame.size() == 5 and Light.WICK_POSITION == Vector2(3.7,-12.3)
	for point in flame: small_wick = small_wick and point.distance_to(Light.WICK_POSITION) <= 1.56
	check(small_wick and Light.GROUND_RECT.size == Vector2(14,7) and Light.WICK_RECT.size == Vector2(6.2,6.2) and Light.GROUND_COLOR.a < 0.09,"production_draw_uses_one_small_wick_a_narrow_soft_glow_and_a_faint_two_to_one_foot_pool")
	check(light.material is CanvasItemMaterial and light.material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD and light.material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED,"emission_uses_cached_additive_unshaded_canvas_geometry_without_a_point_light")
	var global_wick := light.to_global(Light.WICK_POSITION)
	var expected := buildings.to_global(lamp.position+Light.WICK_POSITION)
	var single_transform := global_wick.distance_to(expected) < 0.00001
	buildings.position += Vector2(37,-21)
	buildings.scale = Vector2(0.72,0.72)
	expected = buildings.to_global(lamp.position+Light.WICK_POSITION)
	check(single_transform and light.to_global(Light.WICK_POSITION).distance_to(expected) < 0.00001,"wick_and_foot_pool_inherit_one_actual_terrain_pan_and_zoom_transform")
	var effective := inherited_color(light)
	check(is_equal_approx(effective.r,1.0) and is_equal_approx(effective.g,1.0) and is_equal_approx(effective.b,1.0),"emission_rgb_cancels_one_world_tint_after_scenery_removes_building_warmth")
	lamp.reveal = 0.35
	lamp.modulate.a = lamp.reveal
	lamp.sync_classical_lamp_light(0.5,tint)
	effective = inherited_color(light)
	check(is_equal_approx(effective.a,0.175) and is_equal_approx(light.modulate.a,0.5),"real_reveal_alpha_is_inherited_once_and_multiplied_only_by_night_strength")
	lamp.reveal = 0.0
	lamp.modulate.a = 0.0
	check(inherited_color(light).a == 0.0,"inaudible_zero_reveal_cannot_emit_light")
	lamp.reveal = 1.0
	lamp.modulate.a = 1.0
	buildings.visible = false
	check(not light.is_visible_in_tree(),"black_listening_mode_hides_the_light_through_the_real_parent")
	buildings.visible = true
	lamp.visible = false
	check(not light.is_visible_in_tree(),"actual_prop_visibility_hides_its_child_emission")
	lamp.visible = true
	lamp.era = 2
	var disabled_at_transition := not light.visible
	lamp.sync_classical_lamp_light(1.0,tint)
	check(disabled_at_transition and not light.visible and lamp.get_child_count() == 1,"era_transition_immediately_disables_classical_emission_without_replacing_the_retained_lamp")
	lamp.era = 1
	lamp.sync_classical_lamp_light(1.0,tint)
	check(light.visible and lamp.classical_lamp_light == light and lamp.get_child_count() == 1,"return_to_first_era_reuses_the_same_child_and_radial_texture")
	var probe := LampProbe.new()
	probe.kind = "lamp"
	probe._draw()
	probe.era = 3
	probe._draw()
	check(probe.classical_draws == 1 and probe.retained_draws == 1,"actual_first_and_later_era_draw_dispatch_still_selects_the_original_material_branches")
	probe.free()
	var tree := Prop.new()
	tree.sync_classical_lamp_light(1.0,tint)
	check(tree.classical_lamp_light == null and tree.get_child_count() == 0,"non_lamp_props_do_not_invent_light_sources")
	tree.free()
	var retained_position := lamp.position
	var retained_tone := lamp.tone
	for index in range(100):
		lamp.motion = float(index)
		lamp.sync_classical_lamp_light(0.75,tint)
	check(lamp.classical_lamp_light == light and lamp.position == retained_position and lamp.tone == retained_tone and light.modulate.a == 0.75 and city.snapshot() == baseline,"100_syncs_are_stable_without_random_flicker_or_world_save_rng_and_position_writes")
	lamp.sync_classical_lamp_light(0.0,tint)
	check(not light.visible and light.modulate.a == 0.0,"returning_to_daylight_fully_removes_flame_and_soft_light")
	# Geometry contract only: use the already imported actual civic texture as
	# an opaque stand-in mask. Root separately verifies all new night resources.
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/精制河湾/manifest.json"))
	var civic_entry: Dictionary = {}
	for entry: Dictionary in manifest["entries"]:
		if str(entry["id"]) == "refined_civic_loggia_o1": civic_entry = entry
	var geometry_mask: Texture2D = load("res://"+str(civic_entry["texture"]))
	var civic := Prop.new()
	civic.kind = "civic"
	civic.art_entry = civic_entry
	civic.art_texture = geometry_mask
	civic.art_shadow = load("res://"+str(civic_entry["shadow_texture"]))
	civic.art_contact = load("res://"+str(civic_entry["contact_texture"]))
	civic.position = lamp.position+Vector2(18,9)
	civic.reveal = 1.0
	civic.modulate = Color(tint.r/buildings.modulate.r,1,1,1)
	buildings.add_child(civic)
	civic.sync_classical_facade_light(geometry_mask,0.7,tint)
	var facade: Sprite2D = civic.classical_facade_light
	var bounds: Array = civic_entry["model_bounds"]["size"]
	var expected_scale := 28.0*sqrt(2.0)*float(civic_entry["plot_span"])/maxf(float(bounds[0]),float(bounds[2]))/float(civic_entry["pixels_per_world"])
	var civic_geometry := facade != null and facade.get_parent() == civic and facade.position == Vector2.ZERO and not facade.centered
	civic_geometry = civic_geometry and facade.offset == -Vector2(civic_entry["origin"][0],civic_entry["origin"][1]) and facade.scale.distance_to(Vector2.ONE*expected_scale) < 0.000001
	civic_geometry = civic_geometry and facade.visible and facade.to_global(Vector2.ZERO).distance_to(civic.to_global(Vector2.ZERO)) < 0.00001
	civic.reveal = 0.99
	civic.sync_classical_facade_light(geometry_mask,0.7,tint)
	civic_geometry = civic_geometry and not facade.visible
	civic.reveal = 1.0
	civic.sync_classical_facade_light(null,0.7,tint)
	civic_geometry = civic_geometry and not facade.visible
	check(civic_geometry and city.snapshot() == baseline,"actual_civic_facade_shares_oriented_production_origin_and_scale_and_hides_before_reveal_or_without_mask")
	await process_frame
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"actual_lamp":{"road":road_id,"world_position":at,"local_ground":lamp.position,"wick":Light.WICK_POSITION,"ground_rect":Light.GROUND_RECT,"wick_rect":Light.WICK_RECT},
		"scope":"Standalone headless Dummy; actual World road/terrain position and production ValleyProp/ClassicalLampLight. Numeric reveal/night inputs with native CanvasItem transforms, visibility and material. One civic origin/scale/reveal/null-mask contract uses the imported production civic base texture as a stand-in mask; Root separately verifies all authored night masks. No physical audio, window, World writes or aesthetic acceptance claim. Root integrates scenery and reviews a real-window night screenshot."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND209_CLASSICAL_LAMP_LIGHT ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	buildings.free()
	quit(0 if failures.is_empty() else 1)
