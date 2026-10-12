extends SceneTree
## Actual World footprints under a tiny UI/transport shell; no Demo or GPU.
const Focus = preload("res://scripts/visual/community_member_focus.gd")
const IsoProjection = preload("res://scripts/world/world_projection.gd")
const OUTPUT := "res://验证记录/round214_社区成员焦点/focus_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class CountingWorld extends "res://scripts/world/continuous_world.gd":
	var footprint_queries := 0
	func building_polygon(p: Vector2) -> PackedVector2Array:
		footprint_queries += 1
		return super.building_polygon(p)

class DummyWorkbench extends RefCounted:
	var opened := true
	var state: Dictionary = {}

class DummyTransport extends RefCounted:
	var audible_frame := 0.0

class DummyRenderer extends RefCounted:
	var transport := DummyTransport.new()

class DummyClock extends RefCounted:
	var renderer := DummyRenderer.new()

class DummyModel extends RefCounted:
	var world: RefCounted

class DummyDemo extends Control:
	var shown_world: RefCounted
	var model := DummyModel.new()
	var community_workbench := DummyWorkbench.new()
	var clock := DummyClock.new()
	var black := false
	var pan := Vector2.ZERO
	var view_zoom := 1.0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _ids(focus: Node2D) -> Array[String]:
	var ids: Array[String] = []
	for member: Dictionary in focus.member_polygons: ids.append(str(member["id"]))
	return ids

func _same_projection(focus: Node2D,demo: Control,city: RefCounted) -> bool:
	var origin: Vector2 = Vector2(demo.size.x*0.5,demo.size.y*0.52)+demo.pan
	for member: Dictionary in focus.member_polygons:
		var raw: Array = city.by_id[member["id"]]["position"]
		var position := Vector2(float(raw[0]),float(raw[1]))
		var expected: PackedVector2Array = city.building_polygon(position)
		if member["world_position"] != position or member["footprint"] != expected: return false
		var projected: PackedVector2Array = member["polygon"]
		if projected.size() != expected.size()+1 or projected[0] != projected[-1]: return false
		for i in range(expected.size()):
			var vertex := expected[i]
			var screen := IsoProjection.to_screen(vertex-Vector2(16,16),origin,demo.view_zoom,Vector2(28,14),city.terrain.height_at(vertex))
			if not focus.to_global(projected[i]).is_equal_approx(screen): return false
	return true

func _run() -> void:
	check(DisplayServer.get_name() == "headless" and AudioServer.get_driver_name() == "Dummy","headless_dummy_without_demo_gpu_or_audio_device")
	root.size = Vector2i(800,900)
	var city := CountingWorld.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var cid := "west-1"
	var actual: Array = city.communities[cid]["members"].duplicate()
	actual.sort()
	var future := str(actual[0])
	city.by_id[future]["birth_frame"] = 512
	var heard := actual.duplicate()
	heard.erase(future)
	var requested := actual.duplicate()
	requested.append(actual[-1])
	requested.append(city.communities["east-2"]["members"][0])
	requested.append("not-a-building")
	var writable := CountingWorld.new("2026100900000062",false,"river_valley")
	writable.restore(city.snapshot())
	writable.terrain.configure(city.terrain.noise_seed+17,city.terrain.river_phase,"forest_ridge")
	var demo := DummyDemo.new()
	demo.size = Vector2(800,900)
	demo.shown_world = city
	demo.model.world = writable
	demo.community_workbench.state = {"id":cid,"member_ids":requested}
	root.add_child(demo)
	var focus := Focus.new()
	focus.setup(demo)
	demo.add_child(focus)
	var before: Dictionary = city.snapshot()
	var writable_before: Dictionary = writable.snapshot()
	focus.sync()
	check(focus.visible and _ids(focus) == heard,"only_unique_actual_heard_members_of_selected_community")
	check(_same_projection(focus,demo,city),"each_outline_is_real_world_footprint_at_actual_terrain_height")
	check(not _ids(focus).has(future),"render_ahead_birth_is_hidden_until_audible_frame")
	var rebuilds: int = focus.geometry_updates
	var queries: int = city.footprint_queries
	var retained: Array = focus.member_polygons.duplicate(true)
	focus.sync()
	check(focus.geometry_updates == rebuilds and city.footprint_queries == queries and focus.member_polygons == retained,"unchanged_members_reuse_retained_geometry")
	demo.pan = Vector2(63,-25)
	demo.view_zoom = 0.73
	focus.sync()
	check(focus.geometry_updates == rebuilds and city.footprint_queries == queries and focus.member_polygons == retained,"camera_moves_do_not_rebuild_or_query_world_footprints")
	check(_same_projection(focus,demo,city),"pan_zoom_transform_retained_polygons_to_correct_screen_positions")
	check(city.snapshot() == before and writable.snapshot() == writable_before,"visual_sync_preserves_shown_and_writable_world_rng_and_pending")
	demo.clock.renderer.transport.audible_frame = 512
	focus.sync()
	check(_ids(focus) == actual and focus.geometry_updates == rebuilds+1,"new_member_appears_exactly_when_its_birth_is_heard")
	var fork := CountingWorld.new("2026100900000062",false,"river_valley")
	fork.restore(city.snapshot())
	var same_fork_before: Dictionary = fork.snapshot()
	var fork_queries: int = fork.footprint_queries
	rebuilds = focus.geometry_updates
	demo.shown_world = fork
	focus.sync()
	check(focus.geometry_updates == rebuilds and fork.footprint_queries == fork_queries and fork.snapshot() == same_fork_before,"equivalent_fork_reuses_value_cache_without_world_reference")
	fork.terrain.configure(city.terrain.noise_seed+9,city.terrain.river_phase,"forest_ridge")
	var fork_before: Dictionary = fork.snapshot()
	focus.sync()
	check(focus.geometry_updates == rebuilds+1 and _same_projection(focus,demo,fork),"divergent_fork_rebuilds_from_actual_terrain_fields")
	check(fork.snapshot() == fork_before and city.snapshot() == before and writable.snapshot() == writable_before,"fork_focus_does_not_mutate_any_world_or_copy_geometry_back")
	demo.community_workbench.state = {"id":"east-2","member_ids":fork.communities["east-2"]["members"].duplicate()}
	focus.sync()
	var east: Array = fork.communities["east-2"]["members"].duplicate()
	east.sort()
	check(_ids(focus) == east and _same_projection(focus,demo,fork),"community_switch_replaces_members_instead_of_keeping_old_outlines")
	demo.black = true
	focus.sync()
	check(not focus.visible and focus.member_polygons.is_empty() and focus.geometry_key.is_empty(),"black_clears_cached_member_outlines")
	demo.black = false
	focus.sync()
	demo.community_workbench.opened = false
	focus.sync()
	check(not focus.visible and focus.member_polygons.is_empty(),"closing_workbench_removes_focus")
	demo.community_workbench.opened = true
	demo.community_workbench.state = {"id":"east-2","member_ids":[]}
	focus.sync()
	check(not focus.visible and focus.member_polygons.is_empty(),"empty_community_does_not_create_a_fake_boundary")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT).get_base_dir())
	var report := {"checks":checks,"failures":failures,"passed":checks.size()-failures.size(),"total":checks.size(),
		"renderer":DisplayServer.get_name(),"audio":AudioServer.get_driver_name(),
		"scope":"Member footprints only; no public/reservation boundary, Demo, GPU, PCM or human quality claim."}
	var file := FileAccess.open(OUTPUT,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND214 COMMUNITY FOCUS %d/%d" % [checks.size()-failures.size(),checks.size()])
	demo.free()
	quit(0 if failures.is_empty() else 1)
