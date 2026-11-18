extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Edge=preload("res://scripts/visual/city_creation_path_edge.gd")
const Before=preload("res://tests/fixtures/regression_baselines/path_edge_before_joined_attributes.gd")
const Shore=preload("res://tools/fixtures/city_creation_shore_road_fixture.gd")
const Banks=preload("res://tools/fixtures/city_creation_bridge_banks_fixture.gd")
var checks:=0
var failures:Array=[]
var cases:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func same_surface(actual:Array,expected:Array)->bool:
	if actual.is_empty() or expected.is_empty():return actual.is_empty() and expected.is_empty()
	var actual_indices:PackedInt32Array=actual[Mesh.ARRAY_INDEX];var expected_indices:PackedInt32Array=expected[Mesh.ARRAY_INDEX]
	if actual_indices.size()!=expected_indices.size():return false
	for corner in actual_indices.size():
		var left:=actual_indices[corner];var right:=expected_indices[corner]
		for attr in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2]:
			if actual[attr][left]!=expected[attr][right]:return false
		for attr in [Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1]:
			for component in 4:
				if actual[attr][4*left+component]!=expected[attr][4*right+component]:return false
	return true
func compare(city:RefCounted,id:String,label:String)->void:
	var author:Dictionary=city.snapshot();city.prepare_ground_height();city.road_junctions()
	var town:=Renderer.new();town.state=city;town.record_only=true;town._prepare_road_layout()
	var road:Dictionary=city.roads.filter(func(r):return r.id==id)[0];var cuts:Array=city.road_profile(road).stepping_cuts
	var started:=Time.get_ticks_usec();var expected:Dictionary=Before.new().prepare(town,road,cuts);var before_ms:=(Time.get_ticks_usec()-started)/1000.;started=Time.get_ticks_usec()
	var actual:Dictionary=Edge.new().prepare(town,road,cuts);var after_ms:=(Time.get_ticks_usec()-started)/1000.
	if not actual.arrays.is_empty() and not expected.arrays.is_empty():
		var colors:PackedColorArray=actual.arrays[Mesh.ARRAY_COLOR]
		check(colors.size()==actual.arrays[Mesh.ARRAY_VERTEX].size() and Array(colors).all(func(color):return color.r>=0 and color.r<=1),"edge vertices carry a valid deck blend "+label)
	check(actual.stats==expected.stats and same_surface(actual.arrays,expected.arrays),"same indexed triangles, normals and original edge segments "+label)
	check(city.snapshot()==author,"read-only author data and receipts "+label)
	cases.append({"label":label,"stats":actual.stats,"before_ms":before_ms,"after_ms":after_ms})
	Renderer.BudgetRebuild.new()._dispose_context(town)
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	if "--frontage" in OS.get_cmdline_user_args():
		var city:RefCounted=preload("res://tools/fixtures/city_creation_integrated_city.gd").build().city
		var road:Dictionary=city.roads.filter(func(row):return Vector2(row.points[0][0],row.points[0][1])==Vector2(-32,30))[0]
		city.prepare_ground_height();city.road_junctions()
		var town:=Renderer.new();town.state=city;town.record_only=true;town._prepare_road_layout()
		var prepared:=Edge.new().prepare(town,road)
		print("FRONTAGE_RING ",prepared.stats," width ",road.width)
		for side:float in [-1.,1.]:
			var at:=Vector2(-25,30+side*(float(road.width)*.5-.04));var nearest:=INF
			if not prepared.arrays.is_empty():
				var arrays:=prepared.arrays as Array;var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX];var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
				for start in range(0,indices.size(),3):
					var corners:=PackedVector2Array()
					for offset in range(3):
						var point:=vertices[indices[start+offset]];corners.append(Vector2(point.x,point.z))
					if not Geometry2D.is_point_in_polygon(at,corners):continue
					var index:=indices[start];var pairs:Array=[[arrays[Mesh.ARRAY_TEX_UV][index],arrays[Mesh.ARRAY_TEX_UV2][index]]]
					for slot in [Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1,Mesh.ARRAY_CUSTOM2]:
						var coords:PackedFloat32Array=arrays[slot];var base:=index*4;pairs.append([Vector2(coords[base],coords[base+1]),Vector2(coords[base+2],coords[base+3])])
					for pair:Array in pairs:nearest=minf(nearest,at.distance_to(Geometry2D.get_closest_point_to_segment(at,pair[0],pair[1])))
			print("FRONTAGE_DISTANCE ",at," ",nearest)
			check(absf(nearest-.04)<.004,"actual straight frontage shoulder samples four centimetres inside both banks")
		Renderer.BudgetRebuild.new()._dispose_context(town);quit(0 if failures.is_empty() else 1);return
	for kind:String in ["straight","bend","junction","middle_pond","slope","cross"]:
		var f:=Shore.build(kind,.4);check(f.ok,"actual rotated shoreline "+kind)
		if f.ok:compare(f.city,f.road_id,kind)
	for kind:String in ["slope","bank_bend"]:
		var city:RefCounted=Banks.build(kind);compare(city,str(city.roads[0].id),"bridge_"+kind)
	var loop:=State.new();loop.initialize();loop.houses.clear();loop.roads.clear();loop.plants.clear()
	for points:Array in [[Vector2(-15,-10),Vector2(-8,-10)],[Vector2(-11,-13),Vector2(-11,-7)],[Vector2(-17,3),Vector2(-13,3),Vector2(-13,8),Vector2(-17,8),Vector2(-17,3)],[Vector2(-15,0),Vector2(-15,5)],[Vector2(-12,5),Vector2(-16,5)]]:
		var typed:Array[Vector2]=[];typed.assign(points)
		check(loop.add_road(typed).ok,"public overlapping loop fixture")
	for road:Dictionary in loop.roads:compare(loop,str(road.id),"loop_"+str(road.id))
	var large:=State.new();check(large.restore(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/regression_baselines/quiet_street_300.json"))).ok,"original300 restore")
	compare(large,"r7","original300_r7");compare(large,"r20","original300_r20")
	var low:=INF
	for road:Dictionary in large.roads:
		for point:Array in road.points:
			if is_equal_approx(float(point[0]),-38.):low=minf(low,float(point[1]))
	check(large.add_road([Vector2(-38,low),Vector2(-38,-38.5),Vector2(16,-38.5)] as Array[Vector2],"promenade","none").ok,"actual300 remote bridge")
	compare(large,"r7","changed300_r7");compare(large,"r20","changed300_r20")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cases":cases,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("PATH_EDGE_ATTRIBUTES ",JSON.stringify(result));quit(0 if result.ok else 1)
