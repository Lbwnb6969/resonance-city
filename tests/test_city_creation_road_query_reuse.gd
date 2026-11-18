extends SceneTree
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Heights=preload("res://scripts/visual/city_creation_road_surface_heights.gd")
const OldHeights=preload("res://tests/fixtures/published_baselines/road_publish_hotspots_20261106/reference/road_surface_heights.gd")
const OldBed=preload("res://tests/fixtures/published_baselines/road_publish_hotspots_20261106/reference/shore_road_bed.gd")
const ParentBed=preload("res://tests/fixtures/published_baselines/road_publish_hotspots_20261106/reference/shore_road_bed_parent.gd")
const Shore=preload("res://tools/fixtures/city_creation_shore_road_fixture.gd")
const Banks=preload("res://tools/fixtures/city_creation_bridge_banks_fixture.gd")
var checks:=0
var failures:Array=[]
var rows:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func compare(city:RefCounted,id:String,label:String)->void:
	var original:Dictionary=city.snapshot();city.prepare_ground_height();city.road_junctions()
	var town:=Renderer.new();town.state=city;town.record_only=true;town._prepare_road_layout()
	var road:Dictionary=city.roads.filter(func(row):return row.id==id)[0];var data:Dictionary=town._prepare_road_data(road);var profile:Dictionary=city.road_profile(road)
	var a:Array[Vector3]=[];a.assign(data.arrays[Mesh.ARRAY_VERTEX]);var b:Array[Vector3]=a.duplicate()
	for i in range(a.size()):a[i].y=0.;b[i].y=0.
	var samples:Array[Vector2]=town._road_geometry(road).samples;var spans:Array[Vector2]=Renderer.Bridges.paving_spans(profile);var stone:Array[Vector2]=Renderer.Bridges.paving_spans(profile,true)
	var began:=Time.get_ticks_usec();var old:Dictionary=OldHeights.prepare(town,samples,a,road.width,spans,stone);var old_ms:=(Time.get_ticks_usec()-began)/1000.
	town.rebuild_stats={};began=Time.get_ticks_usec();var current:=Heights.prepare(town,samples,b,road.width,spans,stone);var new_ms:=(Time.get_ticks_usec()-began)/1000.
	check(a==b and old==current,"exact original vertex heights, paving weights and UVs: "+label)
	began=Time.get_ticks_usec();var bed:Dictionary=OldBed.prepare(town,road,data.arrays);var bed_old:=(Time.get_ticks_usec()-began)/1000.
	check(bed==data.earthworks.shore_bed,"exact original shore bed faces and pieces: "+label)
	check(ParentBed.prepare(town,road,data.arrays)==data.earthworks.shore_bed,"existing bounds cull also matches accepted-parent bed: "+label)
	check(city.snapshot()==original,"read-only preparation: "+label)
	rows.append({"label":label,"vertices":a.size(),"queries":town.rebuild_stats.road_height_queries,"height_old_ms":old_ms,"height_new_ms":new_ms,"bed_old_ms":bed_old,"shore_faces":bed.faces.size()})
	Renderer.BudgetRebuild.new()._dispose_context(town)
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec()
	for kind:String in ["straight","bend","junction","middle_pond","slope","cross"]:
		var fixture:=Shore.build(kind,.4);check(fixture.ok,"actual rotated shore fixture: "+kind)
		if fixture.ok:compare(fixture.city,fixture.road_id,kind)
	for kind:String in ["slope","bank_bend"]:
		var city:RefCounted=Banks.build(kind);compare(city,str(city.roads[0].id),"bridge_"+kind)
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"rows":rows,"boundary":"Frozen original algorithm and exact Variant comparisons, not image similarity. Timings are one warm comparison per fixture."};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_QUERY_REUSE ",JSON.stringify(report));quit(0 if report.ok else 1)
