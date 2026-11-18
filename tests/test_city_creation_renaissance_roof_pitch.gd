extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Geo=Pitch.Renaissance
const Fixture=preload("res://tests/test_city_creation_stepped_guildhouse.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
static func fixture(kind:String,width:int=1,depth:int=1,floors:int=2)->RefCounted:return Fixture.fixture(width,depth,floors,kind)
func worker(source:Dictionary)->Dictionary:
	var city:=State.new();var result:Dictionary=city.restore(source)
	if not result.ok:return result
	return {"ok":true,"plan":Geo.for_house(city,city.houses[0]),"source":city.snapshot()}
func high(plan:Dictionary)->float:
	var value:=-INF
	for patch:Dictionary in plan.patches:
		for point:Vector3 in patch.vertices:value=maxf(value,point.y)
	return value
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec();var tops:Dictionary={}
	for kind:String in Geo.IDS:
		var city:=fixture(kind);var before:Dictionary=city.snapshot();var depth:int=city._undo.size();var heights:Array=[]
		check(Pitch.supported(city,city.houses[0]) and not Pitch.active(city,city.houses[0]),"original renaissance family stays original until explicit edit "+kind)
		for angle:float in [0.,15.,45.,78.]:
			var result:Dictionary=city.set_house_roof_pitch("h1",angle);var source:Dictionary=city.snapshot();var plan:=Geo.for_house(city,city.houses[0]);var good:bool=not plan.patches.is_empty()
			for patch:Dictionary in plan.patches:
				for i in range(0,patch.vertices.size(),3):
					var a:=Vector3(patch.vertices[i]);var b:=Vector3(patch.vertices[i+1]);var c:=Vector3(patch.vertices[i+2]);good=good and a.is_finite() and b.is_finite() and c.is_finite() and (b-a).cross(c-a).length_squared()>.0000000001
			check(result.ok and source.schema==40 and city.houses[0].roof_pitch=={"version":5,"profile":"renaissance","degrees":angle} and city.houses[0].cells==before.houses[0].cells and city.houses[0].architecture==kind,"explicit schema40 roof retains author rooms and family "+kind+str(angle));check(good and Pitch.active(city,city.houses[0]) and city.snapshot()==source,"finite complete read-only roof geometry "+kind+str(angle));heights.append(high(plan))
			var thread:=Thread.new();var error:=thread.start(worker.bind(source));var result2:Dictionary=thread.wait_to_finish() if error==OK else {};check(error==OK and result2.get("ok",false) and result2.plan==plan and result2.source==source,"actual CPU worker cold State exactly reproduces complete geometry "+kind+str(angle))
			if kind=="belvedere_villa":check(plan.records[0].parts.filter(func(p):return p.name=="OpenLoggiaColumn").size()==4,"four fixed-size lookout columns remain "+str(angle))
			if kind=="stepped_guildhouse":check(plan.records[0].parts.filter(func(p):return p.name=="GuildStepBody").size()==16 and plan.records[0].parts.filter(func(p):return p.name=="CarvedGuildRoundel").size()==2,"full stepped front/back parapets and two roundels remain "+str(angle))
			if kind=="corner_loggia_tower":check(plan.records[0].parts.filter(func(p):return p.name=="LoggiaPierAndArch").size()==4 and plan.records[0].parts.filter(func(p):return p.name=="LoggiaRearGlass").size()==2,"four real facade shells and two rear windows remain "+str(angle))
		var cold:=State.new();var file:=out+"/"+kind+".json";check(city.save_city(file).ok and cold.load_city(file).ok and cold.houses==city.houses and Geo.for_house(cold,cold.houses[0])==Geo.for_house(city,city.houses[0]),"disk schema40 cold read preserves exact production plan "+kind);check(heights[-1]>heights[0]+1. and city._undo.size()==depth+4 and city.undo().ok and city.houses[0].roof_pitch.degrees==45. and city.redo().ok and city.houses[0].roof_pitch.degrees==78.,"genuine flat-to-steep roof and one-step history "+kind);tops[kind]=heights;city.set_house_roof_pitch("h1",null);check(city.houses==before.houses,"original button data restores exact old recipe "+kind)
	var city:=fixture("venetian_loggia");city.set_house_roof_pitch("h1",45.);var invalid:Dictionary=city.snapshot();invalid.schema=39;check(not State.new().restore(invalid).ok,"schema39 rejects new renaissance recipe");invalid=city.snapshot();invalid.houses[0].roof_pitch.profile="clockwork";check(not State.new().restore(invalid).ok,"renaissance version cannot masquerade as clockwork")
	for recipe:Dictionary in [{"version":1,"degrees":78.},{"version":2,"profile":"round","degrees":78.},{"version":3,"profile":"modern","degrees":78.},{"version":4,"profile":"clockwork","degrees":78.}]:
		city=fixture("venetian_loggia");city.houses[0].roof_pitch=recipe;var source:Dictionary=city.snapshot();check(State.new().restore(source).ok and not Pitch.active(city,city.houses[0]),"older recipe stays dormant on renaissance special family "+str(recipe.version));check(city.set_house_roof_pitch("h1",15.).ok and city.undo().ok and city.houses==source.houses,"explicit upgrade and Undo preserve old dormant author data "+str(recipe.version))
	for kind:String in Geo.IDS:
		city=fixture(kind,2,2,3);city.houses[0].base_y=1.25;city.rotate_house("h1",.35);check(city.set_house_roof_pitch("h1",60.).ok,"rotated raised multi-cell prototype author edit "+kind);var plan:=Geo.for_house(city,city.houses[0]);check(plan.records.size()==(2 if kind=="stepped_guildhouse" else 4),"multi-cell prototype preserves complete original roof domain "+kind)
	city=fixture("stepped_guildhouse",2,1);city.set_house_role("h1","bakery");city.set_house_roof_pitch("h1",78.);var plan:=Geo.for_house(city,city.houses[0]);check(plan.outlets.size()==1 and plan.records.map(func(row):return row.parts.filter(func(p):return p.name=="GuildChimney").size()).reduce(func(a,b):return a+b,0)==1,"multi-bay bakery retains one real stack and smoke outlet")
	city=fixture("venetian_loggia");city.add_cell("h1",0,0,2,"terrace");city.set_house_roof_pitch("h1",45.);check(Geo.for_house(city,city.houses[0]).patches.is_empty(),"terrace-covered room never gets invisible special roof")
	city=fixture("venetian_loggia");city.set_house_roof_pitch("h1",78.);check(Pitch.blocks(city,city.houses[0],Vector2(-30,-20),Vector2(-26,-20),6.,.02),"actual tall hipped roof blocks bridge corridor");city.set_house_roof_pitch("h1",0.);check(not Pitch.blocks(city,city.houses[0],Vector2(-30,-20),Vector2(-26,-20),6.,.02),"actual flat hipped roof releases same corridor")
	city=fixture("corner_loggia_tower");city.set_house_roof_pitch("h1",45.)
	for offset:Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		var added:Dictionary=city.add_house(Vector2(-28,-20)+offset*1.8)
		if added.ok:city.set_house_era(added.house_id,"renaissance");city.add_cell(added.house_id,0,0,1)
	var before:Dictionary=city.snapshot();plan=Geo.for_house(city,city.houses[0]);check(plan.crown.is_empty() and not Pitch.supported(city,city.houses[0]) and Pitch.active(city,city.houses[0]),"blocked gallery uses actual fallback platform while editing is disabled")
	check(not city.set_house_roof_pitch("h1",60.).ok and city.snapshot()==before,"unsupported corner never commits a fake angle edit")
	city.initialize_free();check(city.restore(before).ok and Geo.for_house(city,city.houses[0])==plan,"same State reset and restore cannot reuse obsolete gallery plan")
	city=fixture("stepped_guildhouse",2,1);city.set_house_roof_pitch("h1",45.);before=city.snapshot();city.add_cell("h1",0,0,2);check(not Pitch.supported(city,city.houses[0]) and city.houses[0].roof_pitch==before.houses[0].roof_pitch and city.undo().ok and city.houses==before.houses,"irregular stepped house preserves dormant recipe and exact Undo")
	city=fixture("venetian_loggia");city.houses[0].erase("era_theme");city.add_district([Vector2(-31,-20),Vector2(-25,-20)] as Array[Vector2],6.);city.set_district_era("d1","renaissance");check(city.set_house_roof_pitch("h1",45.).ok and city.houses[0].roof_pitch.version==5 and not city.houses[0].has("era_theme"),"inherited renaissance edit does not pin the house era");city.set_district_era("d1","modern_eco");check(not Pitch.active(city,city.houses[0]) and city.houses[0].roof_pitch.version==5,"renaissance profile stays dormant after inherited era changes")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"tops":tops,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("RENAISSANCE_ROOF_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
