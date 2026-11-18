extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Geo=Pitch.Modern
const KINDS:=["chalet","pavilion","terrace","panorama","twin_gable","green_lodge"]
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
static func fixture(kind:String)->RefCounted:
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.set_house_era("h1","modern_eco");city.set_house_architecture("h1",kind);city.add_cell("h1",0,0,1);return city
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var tops:Dictionary={}
	for kind:String in KINDS:
		var city:=fixture(kind);var original:Dictionary=city.snapshot();var h:Dictionary=city.houses[0];var depth:int=city._undo.size()
		check(Pitch.supported(city,h) and not Pitch.active(city,h),"actual modern family is eligible and original remains dormant "+kind)
		var heights:Array=[]
		for angle:float in [0.,15.,45.,78.]:
			var result:Dictionary=city.set_house_roof_pitch("h1",angle);h=city.houses[0];var patches:=Pitch.patches(city,h);var high:=-INF;var good:=true;var total:=0
			for patch:Dictionary in patches:
				for i in range(0,patch.vertices.size(),3):
					var a:Vector3=patch.vertices[i];var b:Vector3=patch.vertices[i+1];var c:Vector3=patch.vertices[i+2];good=good and a.is_finite() and b.is_finite() and c.is_finite() and (b-a).cross(c-a).length_squared()>.0000000001;total+=3
					if patch.part not in ["SedumPlant","EcoRoofGarden"]:high=maxf(high,maxf(a.y,maxf(b.y,c.y)))
			check(result.ok and Pitch.active(city,h) and h.roof_pitch.version==3 and city.snapshot().schema==38 and h.cells==original.houses[0].cells and h.architecture==kind,"explicit new recipe preserves family/body/author cells "+kind+str(angle))
			check(good and total>0 and is_finite(high),"complete finite nondegenerate modern geometry including zero slope "+kind+str(angle));heights.append(high)
			var cold:=State.new();check(cold.restore(city.snapshot()).ok and Pitch.patches(cold,cold.houses[0])==patches,"cold modern roof geometry exactly matches hot "+kind+str(angle))
		check(heights[-1]>heights[0]+1.3 and city._undo.size()==depth+4,"roof genuinely rises while four gestures create four Undo steps "+kind);tops[kind]=heights
		var file:=out+"/"+kind+".json";var cold:=State.new();check(city.save_city(file).ok and cold.load_city(file).ok and cold.houses==city.houses and Pitch.patches(cold,cold.houses[0])==Pitch.patches(city,city.houses[0]),"actual schema38 disk round trip "+kind)
		check(city.undo().ok and is_equal_approx(float(city.houses[0].roof_pitch.degrees),45.) and city.redo().ok and city.houses[0].roof_pitch.degrees==78.,"one Undo/Redo restores previous continuous slope "+kind)
		city.set_house_roof_pitch("h1",null);check(city.houses==original.houses and not Pitch.active(city,city.houses[0]),"original exact author recipe restores "+kind)
	var city:=fixture("pavilion");city.houses[0].roof_pitch={"version":1,"degrees":78.};var old:Dictionary=city.snapshot();check(not Pitch.active(city,city.houses[0]) and old.schema==35,"old dormant ordinary recipe on modern family stays dormant")
	check(city.set_house_roof_pitch("h1",45.).ok and city.snapshot().schema==38 and city.undo().ok and city.houses==old.houses,"only explicit modern edit upgrades and Undo restores dormant older data")
	city.redo();var invalid:Dictionary=city.snapshot();invalid.schema=37;check(not State.new().restore(invalid).ok,"schema37 rejects modern profile")
	invalid=city.snapshot();invalid.houses[0].roof_pitch.profile="round";check(not State.new().restore(invalid).ok,"modern version cannot masquerade as round profile")
	city.set_house_era("h1","pastoral");check(not Pitch.active(city,city.houses[0]),"modern profile stays dormant after changing era")
	var joined:=fixture("chalet");joined.add_cell("h1",0,1,0);joined.add_cell("h1",0,1,1);joined.set_house_roof_pitch("h1",45.);var plans:Array=[]
	for c:Dictionary in joined.houses[0].cells:
		if Geo.Plan.top(joined.houses[0],c):plans.append(Geo.cell_plan(joined,joined.houses[0],c))
	check(plans.size()==2 and plans.any(func(p):return p.joined_ends.has(true)),"same recipe joins the true neighbouring modern roof ends")
	var blocked:=fixture("pavilion");blocked.set_house_roof_pitch("h1",0.);var h:Dictionary=blocked.houses[0];var a:=Vector2(-27,-19.7);var b:=Vector2(-23,-19.7)
	check(not Pitch.blocks(blocked,h,a,b,6.,.04),"actual flat roof leaves high bridge corridor clear")
	blocked.set_house_roof_pitch("h1",78.);check(Pitch.blocks(blocked,blocked.houses[0],a,b,6.,.04),"actual tall mono-pitch roof blocks intersecting bridge corridor")
	var district:=fixture("pavilion");district.houses[0].erase("era_theme");var avenue:Array[Vector2]=[Vector2(-28,-20),Vector2(-22,-20)];district.add_district(avenue,6.);district.set_district_era("d1","modern_eco");district.houses[0].roof_pitch={"version":1,"degrees":78.};var prior:Dictionary=district.snapshot()
	check(State.new().restore(prior).ok and district.house_era(district.houses[0])=="modern_eco" and not Pitch.active(district,district.houses[0]),"real restorable district-derived modern era leaves old ordinary recipe dormant")
	check(district.set_house_roof_pitch("h1",45.).ok and Pitch.applies(district.houses[0],district) and district.houses[0].roof_pitch.version==3 and not district.houses[0].has("era_theme"),"explicit edit in district era stores modern recipe without pinning house era")
	var covered:=fixture("chalet");covered.add_cell("h1",0,0,2,"terrace");covered.set_house_roof_pitch("h1",45.);check(Pitch.patches(covered,covered.houses[0]).is_empty(),"terrace-covered room does not acquire invisible roof clearance geometry")
	var peer:=fixture("chalet");peer.add_house(Vector2(-25,-18.2));peer.set_house_era("h2","modern_eco");peer.set_house_architecture("h2","chalet");peer.add_cell("h2",0,0,1);peer.set_house_roof_pitch("h1",45.);peer.set_house_roof_pitch("h2",15.)
	check(not Geo.Plan.seams(peer,peer.houses[0],peer.houses[0].cells[-1],Vector2i.DOWN).has(true),"different authored neighbour slopes never remove a real roof end")
	for prototype:String in ["recessed_townhouse","cantilever_tea_deck"]:
		var variant:=fixture(prototype);var source:Dictionary=variant.snapshot();check(variant.set_house_roof_pitch("h1",60.).ok and variant.houses[0].architecture==prototype and variant.houses[0].cells==source.houses[0].cells,"modern street/deck adapter keeps original special facade and rooms "+prototype)
	for kind:String in KINDS:
		var bakery:=fixture(kind);bakery.set_house_role("h1","bakery");bakery.set_house_roof_pitch("h1",78.);var bakery_house:Dictionary=bakery.houses[0];var plan:=Geo.cell_plan(bakery,bakery_house,bakery_house.cells[-1]);var caps:Array=plan.parts.filter(func(p):return p.name=="ModernChimneyCap")
		check(caps.size()==1 and caps[0].at.is_finite(),"actual bakery stack remains finite on steep modern family "+kind)
		if not caps.is_empty():
			var point:Vector3=Transform3D(Basis(Vector3.UP,atan2(float(plan.front.x),float(plan.front.y))),Vector3(bakery_house.origin[0],bakery_house.get("base_y",0.),bakery_house.origin[1]))*caps[0].at
			check(Pitch.blocks(bakery,bakery_house,Vector2(point.x-.3,point.z),Vector2(point.x+.3,point.z),point.y,.02),"bakery crown participates in actual modern clearance "+kind)
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"tops":tops};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("MODERN_ROOF_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
