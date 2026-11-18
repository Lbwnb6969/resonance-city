extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Bridge=preload("res://scripts/world/city_creation_skybridge_plan.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
func roofs(city)->Array:
	var ctx:=Pitch.Context.new();ctx.prepare(city.houses,city.roads);return ctx.roof_patches("h1")
func roof_surfaces(patches: Array) -> Array:
	var surfaces: Array = []
	for patch: Dictionary in patches:
		var surface := patch.duplicate()
		surface.erase("ridge_guide")
		surfaces.append(surface)
	return surfaces

func run()->void:
	var out:="";var baseline_path:="";var legacy_path:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-context="):baseline_path=arg.trim_prefix("--baseline-context=")
		if arg.begins_with("--legacy-save="):legacy_path=arg.trim_prefix("--legacy-save=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.add_cell("h1",1,0,0);city.add_house(Vector2(-19,-20))
	var original:Dictionary=city.snapshot();var old_roofs:=roofs(city)
	if not baseline_path.is_empty():
		var baseline:RefCounted=load(baseline_path).new();baseline.prepare(city.houses,city.roads)
		check(roof_surfaces(old_roofs)==roof_surfaces(baseline.roof_patches("h1")),"base roof patches are bit-identical to pre-feature context")
	var previous:=-1.;var peaks:Array=[]
	for angle:float in [0.,15.,45.,78.]:
		var before:=city.snapshot();var result:=city.set_house_roof_pitch("h1",angle)
		check(result.ok and city.houses[1]==original.houses[1] and city.houses[0].cells==original.houses[0].cells and city.houses[0].seed==original.houses[0].seed,"slope transaction preserves other house, cells and seed "+str(angle))
		var patches:=roofs(city);var top:=-INF;var low:=INF;var valid:=true
		for patch:Dictionary in patches:
			if patch.surface!="roof":continue
			for p:Vector3 in patch.vertices:top=maxf(top,p.y);low=minf(low,p.y);valid=valid and is_finite(p.y)
			valid=valid and patch.coordinates.size()==patch.vertices.size()
		check(valid and top>previous and (angle!=0. or is_equal_approx(top,low)),"actual roof reaches finite increasing height with flat zero and complete UV "+str(angle));previous=top;peaks.append(top)
		var saved:Dictionary=city.snapshot();var cold:=State.new();check(saved.schema>=Pitch.SCHEMA and cold.restore(saved).ok and roofs(cold)==patches,"current city cold geometry equals actual authored roof "+str(angle))
		check(city.undo().ok and city.houses==before.houses,"one Undo restores exact previous houses "+str(angle));city.redo()
	check(peaks[-1]-1.73>4.,"78-degree roof has a genuinely tall pointed volume")
	var file:=out+"/city.json";var cold:=State.new();var written:Dictionary=city.save_city(file);var loaded:Dictionary=cold.load_city(file);check(written.ok and loaded.ok and cold.houses==city.houses and roofs(cold)==roofs(city),"atomic disk save and cold load preserve authored pitch and actual geometry")
	if not legacy_path.is_empty():
		var legacy := State.new()
		var legacy_loaded := legacy.load_city(legacy_path)
		check(legacy_loaded.ok and legacy.houses == city.houses and roofs(legacy) == roofs(city),
			"recorded schema35 city retains its authored angle and roof geometry")
	var saved:=city.snapshot();var hash_before:=hash(city.snapshot())
	for bad:Variant in [-1.,79.,INF,NAN,"45",true]:check(not city.set_house_roof_pitch("h1",bad).ok and hash(city.snapshot())==hash_before,"invalid angle leaves full city intact "+str(bad))
	for bad:Variant in [{"version":2,"degrees":30.},{"version":1,"degrees":80.},{"version":1,"degrees":"40"},{"version":1,"degrees":40.,"extra":true}]:
		var input:Dictionary=saved.duplicate(true);input.houses[0].roof_pitch=bad;check(not cold.restore(input).ok,"invalid disk roof recipe rejected "+str(bad))
	var too_old:Dictionary=saved.duplicate(true);too_old.schema=34;check(not cold.restore(too_old).ok,"older schema cannot silently accept roof field")
	Brush.sample(city,"h1");check(Brush.current(city).appearance.roof_pitch==city.houses[0].roof_pitch,"sampling existing house carries authored roof pitch")
	check(preload("res://scripts/world/city_creation_batch_appearance.gd").custom(city.houses[0]),"group editing protects hand-authored roof")
	city.set_house_style("h1","round_tower");check(not Pitch.active(city,city.houses[0]) and city.houses[0].has("roof_pitch"),"unsupported style retains dormant author choice without misdrawing roof")
	check(not city.set_house_roof_pitch("h1",40.).ok,"unsupported special roof is not falsely accepted as adapted")
	city.set_house_style("h1","classic");check(Pitch.active(city,city.houses[0]),"return to supported roof restores authored pitch")
	city.set_house_roof_pitch("h1",null);check(not city.houses[0].has("roof_pitch") and roofs(city)==old_roofs,"original roof reset restores exact legacy geometry")
	var obstruction:=State.new();obstruction.initialize_free();obstruction.add_house(Vector2(-25,-20));obstruction.set_house_roof_pitch("h1",0.)
	var a:=Vector2(-28,-20);var b:=Vector2(-22,-20)
	check(Bridge.obstruction(obstruction,a,b,3.55,"none","none").is_empty(),"flat roof leaves actual overhead bridge clearance")
	obstruction.set_house_roof_pitch("h1",78.)
	check(Bridge.obstruction(obstruction,a,b,3.55,"none","none").get("kind")=="building","pointed roof blocks bridge using actual triangles above old fixed envelope")
	check(not Pitch.blocks(obstruction,obstruction.houses[0],Vector2(-24.04,-23),Vector2(-24.04,-17),3.55,.01),"low eave corridor is not blocked by the distant peak")
	for prototype:String in ["townhouse","recessed_townhouse"]:
		var street:=State.new();street.initialize_free();street.add_house(Vector2(-25,-20));street.add_cell("h1",1,0,0);street.set_house_architecture("h1",prototype);var prior:Dictionary=street.houses[0].duplicate(true)
		check(street.set_house_roof_pitch("h1",55.).ok and street.houses[0].architecture==prototype and street.houses[0].cells==prior.cells,"street pitch preserves explicit prototype and rooms "+prototype)
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"peaks":peaks};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROOF_PITCH_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
