extends SceneTree
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Fixture=preload("res://tools/fixtures/city_creation_shore_road_fixture.gd")
const OldBed=preload("res://tests/fixtures/published_baselines/road_install_stages_20261106/reference/shore_road_bed.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(Fixture.State.DEFAULT_PATH)
	var fixture:=Fixture.build("bend",.4,false);var city:RefCounted=fixture.city;var before:Dictionary=city.snapshot();var history:int=city._undo.size()
	var town:=Renderer.new();root.add_child(town);town.setup(city);var valid:Dictionary=city.preview_road(fixture.points,"promenade","none");check(fixture.ok and valid.ok,"real shore candidate remains valid")
	town.preview_road(valid.points,true,valid.width,valid.bridge,valid.style)
	for i:int in range(600):
		if town.has_meta("shore_road_preview"):break
		await process_frame
	var ready:Dictionary=town.get_meta("shore_road_preview",{});check(ready.has("mesh") and not ready.mesh.arrays.is_empty(),"preview cache retains prepared mesh")
	var mesh:MeshInstance3D=town.preview.find_child("ShoreRoadBed",true,false);var arrays:Array=mesh.mesh.surface_get_arrays(0)
	var original_root:=Node3D.new();town.add_child(original_root);OldBed.install(town,original_root,ready.bed,ready.road,true)
	check(arrays==original_root.get_node("ShoreRoadBed").mesh.surface_get_arrays(0),"preview matches original actual mesh arrays including encoded normals")
	check(town.preview.find_children("*","StaticBody3D",true,false).is_empty(),"preview does not create pickable physics bodies")
	town.clear_preview();town.preview_road(valid.points,true,valid.width,valid.bridge,valid.style)
	check(is_same(ready.mesh,town.get_meta("shore_road_preview").mesh),"same preview reuses identical prepared data dictionary")
	mesh=town.preview.find_child("ShoreRoadBed",true,false);check(mesh.mesh.surface_get_arrays(0)==arrays,"repeat preview matches original exact surface arrays")
	# Start another valid candidate, then cancel before its result can install.
	var moved:Array[Vector2]=valid.points.duplicate();moved[-1]+=Vector2(.25,.1)
	town.clear_preview();preload("res://scripts/visual/city_creation_shore_road_preview.gd").show(town,moved,valid.width,valid.style)
	var worker:Node=town.get_node("ShorePreviewWorker");town.clear_preview()
	for i:int in range(600):
		if worker.thread==null:break
		await process_frame
	check(town.preview.find_child("ShoreRoadBed",true,false)==null,"cancelled late result never reinstalls shore bed")
	check(worker.stats.discarded>0,"cancelled job actually finished and was discarded")
	# A same-revision replacement city must not accept the old candidate.
	preload("res://scripts/visual/city_creation_shore_road_preview.gd").show(town,moved,valid.width,valid.style)
	var other:=Fixture.State.new();other.initialize_free();town.state=other
	for i:int in range(600):
		if worker.thread==null:break
		await process_frame
	check(town.preview.find_child("ShoreRoadBed",true,false)==null,"different city rejects old result")
	town.state=city;town.clear_preview()
	# Replace a running candidate with a newer point set.
	preload("res://scripts/visual/city_creation_shore_road_preview.gd").show(town,moved,valid.width,valid.style)
	var latest:Array[Vector2]=valid.points.duplicate();latest[-1]+=Vector2(.4,.15)
	town.clear_preview();preload("res://scripts/visual/city_creation_shore_road_preview.gd").show(town,latest,valid.width,valid.style)
	for i:int in range(600):
		if worker.thread==null and worker.pending.is_empty():break
		await process_frame
	check(town.get_meta("shore_road_preview").key[3]==latest and town.preview.find_child("ShoreRoadBed",true,false)!=null,"latest pending candidate wins after stale worker finishes")
	check(city.snapshot()==before and city._undo.size()==history,"preview leaves author and Undo history unchanged")
	check(personal==FileAccess.get_file_as_bytes(Fixture.State.DEFAULT_PATH),"personal save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SHORE_PREVIEW_REUSE ",JSON.stringify(report));town.queue_free();await process_frame;quit(0 if report.ok else 1)
