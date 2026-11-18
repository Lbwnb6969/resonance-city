extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Geo=Pitch.Clockwork
const Clock=preload("res://scripts/visual/city_creation_clockwork.gd")
const KINDS:=["","recessed_townhouse","sawtooth_atrium","clock_turret","iron_conservatory","guild_arcade"]
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
static func fixture(kind:String)->RefCounted:
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.set_house_era("h1","clockwork");city.add_cell("h1",0,0,1)
	if not kind.is_empty():city.set_house_architecture("h1",kind)
	return city
func cold_worker(source:Dictionary)->Dictionary:
	var city:=State.new();var loaded:Dictionary=city.restore(source)
	if not loaded.ok:return loaded
	return {"ok":loaded.ok,"plan":Geo.for_house(city,city.houses[0]),"source":city.snapshot()}
func high(patches:Array)->float:
	var top:=-INF
	for patch:Dictionary in patches:
		for point:Vector3 in patch.vertices:top=maxf(top,point.y)
	return top
func run()->void:
	var out:="";var baseline:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-clockwork="):baseline=arg.trim_prefix("--baseline-clockwork=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec();var tops:Dictionary={}
	for kind:String in KINDS:
		var city:=fixture(kind);var original:Dictionary=city.snapshot();var depth:int=city._undo.size();var heights:Array=[]
		check(Pitch.supported(city,city.houses[0]) and not Pitch.active(city,city.houses[0]),"original clockwork family remains original until explicit edit "+kind)
		if not baseline.is_empty():check(var_to_bytes(load(baseline).prepare(city,city.houses[0]))==var_to_bytes(Clock.prepare(city,city.houses[0])),"unedited preparation matches previous actual builder "+kind)
		for angle:float in [0.,15.,45.,78.]:
			var chosen:Dictionary=city.set_house_roof_pitch("h1",angle);var source:Dictionary=city.snapshot();var plan:=Geo.for_house(city,city.houses[0]);var good:bool=not plan.patches.is_empty();var count:=0
			for patch:Dictionary in plan.patches:
				for i in range(0,patch.vertices.size(),3):
					var a:=Vector3(patch.vertices[i]);var b:=Vector3(patch.vertices[i+1]);var c:=Vector3(patch.vertices[i+2]);good=good and a.is_finite() and b.is_finite() and c.is_finite() and (b-a).cross(c-a).length_squared()>.0000000001;count+=1
			check(chosen.ok and source.schema>=Pitch.CLOCKWORK_SCHEMA and source.schema==preload("res://scripts/world/city_creation_creative_save.gd").LATEST_SCHEMA and city.houses[0].roof_pitch=={"version":4,"profile":"clockwork","degrees":angle} and city.houses[0].cells==original.houses[0].cells and city.houses[0].get("architecture")==original.houses[0].get("architecture"),"current save schema retains exact roof recipe, body and family "+kind+str(angle))
			check(good and count>0 and Pitch.active(city,city.houses[0]) and city.snapshot()==source,"complete finite nondegenerate read-only CPU geometry "+kind+str(angle));heights.append(high(plan.patches))
			var thread:=Thread.new();var error:=thread.start(cold_worker.bind(source));var result:Dictionary=thread.wait_to_finish() if error==OK else {};check(error==OK and result.get("ok",false) and result.plan==plan and result.source==source,"real worker cold State reproduces exact complete roof plan "+kind+str(angle))
			if kind=="clock_turret":
				var parts:Array=plan.records[0].parts;check(parts.filter(func(p):return p.name=="RomanClockDisc").size()==4 and parts.filter(func(p):return p.name=="OctagonalClockDrum").size()==1,"four actual fixed-size clock faces and drum remain "+str(angle))
			if kind=="iron_conservatory":check(plan.records[0].parts.filter(func(p):return p.name=="ConservatoryPlant").size()==4 and plan.records[0].parts.filter(func(p):return p.name=="ConservatoryPot").size()==4,"all four real plants and pots retained "+str(angle))
		var file:=out+"/"+(kind if not kind.is_empty() else "mansard")+".json";var cold:=State.new();check(city.save_city(file).ok and cold.load_city(file).ok and cold.houses==city.houses and Geo.for_house(cold,cold.houses[0])==Geo.for_house(city,city.houses[0]),"disk round trip reproduces full clockwork plan "+kind)
		check(heights[-1]>heights[0]+1. and city._undo.size()==depth+4 and city.undo().ok and city.houses[0].roof_pitch.degrees==45. and city.redo().ok and city.houses[0].roof_pitch.degrees==78.,"real flat-to-tall shape and complete one-step history "+kind);tops[kind]=heights
		city.set_house_roof_pitch("h1",null);check(city.houses==original.houses,"original restores exact older author recipe "+kind)
	var city:=fixture("");city.set_house_roof_pitch("h1",45.);var invalid:Dictionary=city.snapshot();invalid.schema=38;check(not State.new().restore(invalid).ok,"old schema38 rejects new clockwork recipe");invalid=city.snapshot();invalid.houses[0].roof_pitch.profile="modern";check(not State.new().restore(invalid).ok,"clockwork version cannot masquerade as modern")
	for recipe:Dictionary in [{"version":1,"degrees":78.},{"version":2,"profile":"round","degrees":78.},{"version":3,"profile":"modern","degrees":78.}]:
		city=fixture("");city.houses[0].roof_pitch=recipe;var original:Dictionary=city.snapshot();check(State.new().restore(original).ok and not Pitch.active(city,city.houses[0]),"older dormant recipe never silently activates on clockwork "+str(recipe.version));check(city.set_house_roof_pitch("h1",15.).ok and city.undo().ok and city.houses==original.houses,"explicit upgrade and Undo preserve older dormant clockwork author data "+str(recipe.version))
	city=fixture("recessed_townhouse");city.add_cell("h1",1,0,0);city.add_cell("h1",1,0,1);city.set_house_dormer("h1","gable_light");city.set_house_chimney("h1","copper_cowl");city.set_house_architecture_variant("h1","timber_verge","gable_trim");var detail:Dictionary=city.houses[0].architecture_variant.duplicate(true)
	for angle:float in [0.,15.,78.,0.]:
		city.set_house_roof_pitch("h1",angle);var plan:=Geo.for_house(city,city.houses[0]);check(plan.details.details.size()==3 and city.houses[0].architecture_variant==detail,"clockwork deep-window retains shared three-slot detail plan "+str(angle))
	var slope:=tan(deg_to_rad(45.));check(Geo.roof_height(.28,slope)-Geo.roof_height(0.,slope)>3.*(Geo.roof_height(1.,slope)-Geo.roof_height(.28,slope)),"mansard retains real steep lower and shallow upper fold")
	city=fixture("guild_arcade");city.set_house_roof_pitch("h1",78.);var h:Dictionary=city.houses[0];check(Pitch.blocks(city,h,Vector2(-27,-20),Vector2(-23,-20),6.,.05),"actual tall clockwork roof participates in bridge obstruction");city.set_house_roof_pitch("h1",0.);check(not Pitch.blocks(city,city.houses[0],Vector2(-27,-20),Vector2(-23,-20),6.,.05),"actual flat clockwork roof releases the same high corridor")
	for kind:String in KINDS:
		city=fixture(kind);city.set_house_roof_pitch("h1",45.);var okay:=true
		for row:Dictionary in Geo.for_house(city,city.houses[0]).records:
			for part:Dictionary in row.parts:
				if part.name not in ["SawtoothEndCheek","ClockShoulderEnd","ConservatoryEndGlass","GuildStonePediment"]:continue
				for i in range(0,part.vertices.size(),3):
					var a:=Vector3(part.vertices[i]);var b:=Vector3(part.vertices[i+1]);var c:=Vector3(part.vertices[i+2]);var center:Vector3=(a+b+c)/3.-Vector3(row.center.x,row.base,row.center.y);okay=okay and (b-a).cross(c-a).dot(Vector3(center.x,0,center.z))>0.
		check(okay,"all actual exposed end triangles face outward "+kind)
	city=fixture("");city.add_house(Vector2(-23.2,-20));city.set_house_era("h2","clockwork");city.add_cell("h2",0,0,1);city.set_house_roof_pitch("h1",45.);city.set_house_roof_pitch("h2",45.);var first:Array=Geo.for_house(city,city.houses[0]).records[0].parts[0].vertices;var second:Array=Geo.for_house(city,city.houses[1]).records[0].parts[0].vertices
	check(first.any(func(p):return absf(p.x+24.1)<.0001) and second.any(func(p):return absf(p.x+24.1)<.0001),"equal neighbouring recipes meet at the actual shared roof boundary")
	var signature:=Clock.adjacency_signature(city,city.houses[1]);city.set_house_roof_pitch("h1",15.);check(Clock.adjacency_signature(city,city.houses[1])!=signature and Geo.sides(Geo.tops(city,city.houses[1]).filter(func(row):return row.house=="h2")[0],Geo.tops(city,city.houses[1])).has(Vector2.LEFT),"changing neighbour slope refreshes signature and restores exposed end")
	city=fixture("sawtooth_atrium");city.add_cell("h1",0,0,2,"terrace");city.set_house_roof_pitch("h1",45.);check(Geo.for_house(city,city.houses[0]).patches.is_empty(),"terrace-covered room never generates invisible clockwork roof")
	city=fixture("");city.set_house_style("h1","round_tower");var before:Dictionary=city.snapshot();check(not Pitch.supported(city,city.houses[0]) and not city.set_house_roof_pitch("h1",45.).ok and city.snapshot()==before,"unadapted old round-body clockwork recipe stays explicit and unchanged")
	city=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.add_district([Vector2(-28,-20),Vector2(-22,-20)] as Array[Vector2],6.);city.set_district_era("d1","clockwork")
	check(city.set_house_roof_pitch("h1",45.).ok and city.houses[0].roof_pitch.version==4 and not city.houses[0].has("era_theme"),"district-derived clockwork edit does not pin the house era")
	var source:Dictionary=city.snapshot();var old_plan:=Geo.for_house(city,city.houses[0]);city.initialize_free();check(city.restore(source).ok and Geo.for_house(city,city.houses[0])==old_plan,"same State reset and cold restore do not reuse an obsolete roof plan")
	city.set_district_era("d1","modern_eco");check(not Pitch.active(city,city.houses[0]) and city.houses[0].roof_pitch.version==4,"clockwork profile becomes dormant after changing inherited era")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"tops":tops,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("CLOCKWORK_ROOF_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
