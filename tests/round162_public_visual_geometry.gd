extends SceneTree
## Audit the geometry consumed by retained ground commands and public props.
const VisualGeometry = preload("res://scripts/visual/public_space_visual_geometry.gd")
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const Ground = preload("res://scripts/visual/valley_ground_layer.gd")
const World = preload("res://scripts/world/continuous_world.gd")

var failures: Array[String] = []
var checks := 0

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _rect(x: float,y: float,width: float,height: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x,y),Vector2(x+width,y),Vector2(x+width,y+height),Vector2(x,y+height)])

func _run() -> void:
	var first := _rect(0,0,8,8)
	var second := _rect(10,0,4,4)
	var hole := _rect(2,2,4,4)
	var site := {"id":"visual-public","kind":"park","active":true,"frame":0,"position":[4.0,4.0],
		"polygon":first,"footprint_components":[first,second],"hole_polygons":[hole],"player_planned":true}
	var components := VisualGeometry.components(site)
	_check(components.size() == 2,"ground_data_contains_all_components")
	var area := 0.0
	var no_hole_fill := true
	var no_hole_details := true
	var anchors_solid := true
	for component in components:
		anchors_solid = anchors_solid and SpatialPlanning.point_in_footprint(site,component["position"])
		for piece in component["pieces"]:
			area += SpatialPlanning.polygon_area(piece)
			for intersection in Geometry2D.intersect_polygons(piece,hole):
				no_hole_fill = no_hole_fill and SpatialPlanning.polygon_area(intersection) <= 0.00001
		var details := VisualGeometry.park_details(component)
		for detail in details["paths"]+details["pools"]:
			for intersection in Geometry2D.intersect_polygons(detail,hole):
				no_hole_details = no_hole_details and SpatialPlanning.polygon_area(intersection) <= 0.00001
	_check(absf(area-64.0) < 0.0001,"ground_fill_area_excludes_hole_and_keeps_second_component")
	_check(no_hole_fill,"ground_fill_does_not_cover_hole")
	_check(no_hole_details,"park_paths_and_pools_do_not_cover_hole")
	_check(anchors_solid,"public_anchor_moves_out_of_hole")
	var alias := site.duplicate(true)
	alias.erase("footprint_components")
	alias.erase("hole_polygons")
	alias["target_polygons"] = [first,second]
	alias["target_holes"] = [hole]
	_check(VisualGeometry.identity(alias) == VisualGeometry.identity(site),"target_geometry_aliases_share_visual_identity")
	var legacy := {"polygon":second,"position":[12.0,2.0]}
	_check(VisualGeometry.components(legacy).size() == 1,"legacy_single_polygon_visual_stays_compatible")

	var city := World.new("2026101100000162",true,"river_valley")
	city.public_sites.clear()
	city.public_sites.append(site)
	var ground := Ground.new()
	ground.city = city
	var signature: Array = ground._urban_contents()["public"]
	site["footprint_components"] = [first,_rect(11,0,4,4)]
	_check(signature != ground._urban_contents()["public"],"retained_ground_invalidates_for_later_component")
	signature = ground._urban_contents()["public"]
	site["hole_polygons"] = [_rect(2,2,3,4)]
	_check(signature != ground._urban_contents()["public"],"retained_ground_invalidates_for_hole")
	site["footprint_components"] = [first,second]
	site["hole_polygons"] = [hole]

	var scene: PackedScene = load("res://scenes/continuous_valley.tscn")
	var demo = scene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	var scenery := ValleyScenery.new()
	scenery._sync_public_props(demo,city)
	var solid_props := true
	var both_components := [false,false]
	for key in scenery.public_prop_keys[site["id"]]:
		var prop = scenery.props[key]
		var p: Vector2 = prop.get_meta("world_position")
		solid_props = solid_props and SpatialPlanning.point_in_footprint(site,p)
		for index in range(2):
			if Geometry2D.is_point_in_polygon(p,[first,second][index]): both_components[index] = true
	_check(solid_props,"park_prop_anchors_avoid_hole")
	_check(both_components[0] and both_components[1],"park_props_populate_each_component")
	var prop_identity: Array = scenery.public_prop_layouts[site["id"]]
	site["hole_polygons"] = [_rect(1,1,6,6)]
	scenery._sync_public_props(demo,city)
	_check(prop_identity != scenery.public_prop_layouts[site["id"]],"prop_layout_invalidates_for_hole")
	prop_identity = scenery.public_prop_layouts[site["id"]]
	site["footprint_components"] = [first,_rect(11,0,4,4)]
	scenery._sync_public_props(demo,city)
	_check(prop_identity != scenery.public_prop_layouts[site["id"]],"prop_layout_invalidates_for_later_component")
	site["kind"] = "civic"
	site["footprint_components"] = [first,second]
	site["hole_polygons"] = [hole]
	scenery._sync_public_props(demo,city)
	_check(scenery.public_prop_keys[site["id"]].size() == 2,"civic_pavilion_populates_each_component")
	var civic_bases_solid := true
	for key in scenery.public_prop_keys[site["id"]]:
		var prop = scenery.props[key]
		var p: Vector2 = prop.get_meta("world_position")
		var radius := 0.7*float(prop.get_meta("public_scale"))
		for angle in range(32):
			civic_bases_solid = civic_bases_solid and SpatialPlanning.point_in_footprint(site,p+Vector2.from_angle(TAU*float(angle)/32.0)*radius*0.999)
	_check(civic_bases_solid,"scaled_civic_bases_avoid_hole_and_outer_edges")
	for prop in scenery.props.values(): prop.queue_free()
	ground.free()
	demo.queue_free()
	await process_frame
	print("ROUND162_PUBLIC_VISUAL_GEOMETRY checks=%d failures=%s" % [checks,JSON.stringify(failures)])
	quit(0 if failures.is_empty() else 1)
