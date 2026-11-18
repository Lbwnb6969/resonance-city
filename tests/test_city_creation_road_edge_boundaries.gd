extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Edge=preload("res://scripts/visual/city_creation_path_edge.gd")
const Before=preload("res://tests/fixtures/regression_baselines/path_edge_before_empty_boundary_filter.gd")
var checks:=0
var failures:Array=[]
var cases:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func filled(point:Vector2,groups:Array)->bool:
	for group:Array in groups:
		var inside:=false
		for polygon:PackedVector2Array in group:
			if Geometry2D.is_point_in_polygon(point,polygon):inside=not inside
		if inside:return true
	return false
func rectangle(rect:Rect2)->PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
func boundary(groups:Array,label:String,raster:bool=false)->Dictionary:
	var edge:=Edge.new();var segments:Array=edge._exposed_segments(groups);var raw:Array=segments.duplicate(true);var contours:Array=edge._boundary_contours(segments)
	check(not segments.is_empty() and not contours.is_empty(),"closed exposed union "+label)
	var displacement:=0.;var uncovered:=0.;var total_length:=0.
	for i in range(segments.size()):
		for end in range(2):displacement=maxf(displacement,Vector2(segments[i][end]).distance_to(raw[i][end]))
		total_length+=Vector2(segments[i][0]).distance_to(segments[i][1])
		for point:Vector2 in [segments[i][0],Vector2(segments[i][0]).lerp(segments[i][1],.5),segments[i][1]]:
			var nearest:=INF
			for contour:PackedVector2Array in contours:
				for j in range(contour.size()):nearest=minf(nearest,point.distance_to(Geometry2D.get_closest_point_to_segment(point,contour[j],contour[(j+1)%contour.size()])))
			uncovered=maxf(uncovered,nearest)
	check(displacement<Edge.WELD+.000001,"weld remains below0.2mm "+label)
	check(uncovered<=.0021,"every exposed edge consumed by returned closed contours "+label)
	if raster:
		var same:=true;var samples:=0
		for x in range(-10,60):
			for z in range(-10,40):
				var point:=Vector2(x*.2+.073,z*.2+.117);same=same and filled(point,groups)==filled(point,[contours]);samples+=1
		check(same,"independent polygon parity preserves union and holes "+label)
		cases.append({"label":label,"parity_samples":samples})
	return {"segments":segments.size(),"contours":contours.size(),"length":total_length,"max_weld_m":displacement,"max_uncovered_m":uncovered}
func town_for(city:RefCounted)->Node3D:
	city.prepare_ground_height();city.road_junctions();var town:=Renderer.new();town.state=city;town.record_only=true;town._prepare_road_layout();return town
func large(city:RefCounted,label:String)->void:
	var original:Dictionary=city.snapshot();var town:=town_for(city);var cold:=State.new();check(cold.restore(original).ok,"independent current-schema restore "+label);var other:=town_for(cold)
	for id:String in ["r7","r20"]:
		var road:Dictionary=city.roads.filter(func(r):return r.id==id)[0];var groups:Array=[town.road_outlines[id]]
		for neighbor:Dictionary in city.roads:
			if neighbor.id!=id and town._roads_touch(road,neighbor):groups.append(town.road_outlines[neighbor.id])
		var geometry:=boundary(groups,label+id);var expected:Array=Before.new()._boundary_contours(Before.new()._exposed_segments(groups))
		check(expected.is_empty(),"frozen old300 reproduces missing contour "+label+id)
		var began:=Time.get_ticks_usec();var current:Dictionary=Edge.new().prepare(town,road,city.road_profile(road).stepping_cuts);var elapsed:=(Time.get_ticks_usec()-began)/1000.
		check(not current.arrays.is_empty() and current.stats.triangles>0,"actual restored soft edge triangles "+label+id)
		var restored_road:Dictionary=cold.roads.filter(func(r):return r.id==id)[0]
		check(current==Edge.new().prepare(other,restored_road,cold.road_profile(restored_road).stepping_cuts),"entire restored edge arrays equal independent cold build "+label+id)
		cases.append({"label":label+id,"boundary":geometry,"stats":current.stats,"prepare_ms":elapsed})
	check(city.snapshot()==original and cold.snapshot()==original,"read-only original and cold author data "+label)
	Renderer.BudgetRebuild.new()._dispose_context(town);Renderer.BudgetRebuild.new()._dispose_context(other)
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	boundary([[rectangle(Rect2(0,0,8,2)),rectangle(Rect2(3,1,2,4))]],"same-road overlapping contours",true)
	boundary([[rectangle(Rect2(0,0,8,2))],[rectangle(Rect2(2,0,3,2))]],"collinear overlapping boundary",true)
	boundary([[rectangle(Rect2(0,0,8,6)),rectangle(Rect2(2,2,4,2))],[rectangle(Rect2(7,2,3,2))]],"road ring hole and T junction",true)
	var edge:=Edge.new()
	for gap:float in [.001,.5]:
		var segments:Array=[[Vector2(0,0),Vector2(4,0)],[Vector2(4,0),Vector2(4,4)],[Vector2(4,4),Vector2(0,4)],[Vector2(0,4),Vector2(0,gap)]]
		check(edge._boundary_contours(segments).is_empty(),"actual open gap is never invented closed "+str(gap))
	var city:=State.new();check(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/regression_baselines/quiet_street_300.json"))).ok,"original300 restore");large(city,"original300")
	var low:=INF
	for road:Dictionary in city.roads:
		for point:Array in road.points:
			if is_equal_approx(float(point[0]),-38.):low=minf(low,float(point[1]))
	check(city.add_road([Vector2(-38,low),Vector2(-38,-38.5),Vector2(16,-38.5)] as Array[Vector2],"promenade","none").ok,"actual remote bridge command");large(city,"changed300")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cases":cases,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("ROAD_EDGE_BOUNDARIES ",JSON.stringify(result));quit(0 if result.ok else 1)
