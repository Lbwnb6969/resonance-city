extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Geo=Pitch.Boathouse
const Base=preload("res://tests/test_city_creation_boathouse.gd")
const Plan=Base.Plan
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label);push_error(label)
func worker(source:Dictionary)->Dictionary:
	var city:=State.new();var restored:Dictionary=city.restore(source)
	return {"ok":restored.ok,"patches":Pitch.patches(city,city.houses[0]),"dock":Plan.find(city,"h1"),"source":city.snapshot()} if restored.ok else restored
func triangles(vertices:Variant)->Array:
	var result:Array=[]
	for i in range(0,vertices.size(),3):
		var points:Array=[]
		for j in range(3):
			var p:Vector3=vertices[i+j];points.append("%d,%d,%d"%[roundi(p.x*10000.),roundi(p.y*10000.),roundi(p.z*10000.)])
		points.sort();result.append("|".join(points))
	result.sort();return result
func surface_faces(root_node:Node3D)->Dictionary:
	var result:={"main":[],"canopy":[]}
	var inverse:Transform3D=root_node.global_transform.affine_inverse()
	for mesh:MeshInstance3D in root_node.find_children("*","MeshInstance3D",true,false):
		var label:=str(mesh.name);var key:="canopy" if label=="BoathouseSlipRoof" else "main"
		if key=="main" and label!="GreekContinuousTileRoof" and label!="JoinedRoofSurface" and not label.begins_with("AncientLowTileRoof"):continue
		for p:Vector3 in mesh.mesh.get_faces():result[key].append(inverse*mesh.global_transform*p)
	return result
func renderer(city:RefCounted)->Node3D:
	var r:=Base.Renderer.new();root.add_child(r);r.state=city;r.buildings=Node3D.new();r.add_child(r.buildings)
	for node in [r.shore,r.lilypads,r.wildlife]:r.add_child(node)
	return r
func verify_render(city:RefCounted,label:String)->void:
	var r:Node3D=renderer(city);var root_node:Node3D=r._house(city.houses[0]);var actual:=surface_faces(root_node);var expected:={"main":[],"canopy":[]};var good:=true
	for patch:Dictionary in Pitch.patches(city,city.houses[0]):
		if patch.surface!="roof":continue
		var key:="canopy" if patch.get("part","")=="BoathouseSlipRoof" else "main"
		expected[key].append_array(patch.vertices)
		for i in range(0,patch.vertices.size(),3):
			var a:Vector3=patch.vertices[i];var b:Vector3=patch.vertices[i+1];var c:Vector3=patch.vertices[i+2]
			good=good and a.is_finite() and b.is_finite() and c.is_finite() and (b-a).cross(c-a).length_squared()>.0000000001
	check(good and not expected.main.is_empty(),"finite nondegenerate complete CPU roof "+label)
	check(triangles(actual.main)==triangles(expected.main),"actual main roof triangles equal CPU roof "+label)
	check(triangles(actual.canopy)==triangles(expected.canopy) and not actual.canopy.is_empty(),"actual separate canopy triangles equal CPU roof "+label)
	var dock:Node3D=root_node.find_child("CreekBoathouseDock",true,false)
	if dock!=null:
		var boat:Node3D=dock.find_child("MooredWoodenSkiff",true,false)
		check(boat!=null and absf(boat.global_position.y-float(city.Terrain.WATER_LEVEL))<.00001,"actual boat stays at water datum "+label)
		check(dock.find_child("BoathouseDockSurface",true,false).shape is ConcavePolygonShape3D,"dock retains real triangle collision "+label)
		var canopy:Node3D=dock.find_child("BoathouseCanopyPick",true,false)
		check(canopy!=null and canopy.get_meta("roof_surface",false) and canopy.get_meta("house_id","")=="h1","separate canopy pick is actual roof of original room "+label)
	root_node.free();r.free()
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	var city:RefCounted=Base.fixture();var original:Dictionary=city.snapshot();var original_plan:=Plan.find(city,"h1");var heights:Array=[]
	check(Pitch.supported(city,city.houses[0]) and not Pitch.active(city,city.houses[0]),"original boat house remains unmodified until explicit choice")
	for angle:float in [0.,15.,45.,78.]:
		var edited:Dictionary=city.set_house_roof_pitch("h1",angle);var source:Dictionary=city.snapshot();var h:Dictionary=city.houses[0];var plan:=Plan.find(city,"h1")
		check(edited.ok and source.schema==41 and h.roof_pitch=={"version":6,"profile":"boathouse","degrees":angle} and h.cells==original.houses[0].cells and h.seed==original.houses[0].seed,"explicit schema41 preserves rooms and seed "+str(angle))
		check(not plan.is_empty() and plan.floors==original_plan.floors and plan.boat==original_plan.boat and plan.top==original_plan.top,"roof edit retains true narrow piers mooring and shore level "+str(angle))
		check(absf(Geo.ridge(h)-(1.64+1.08*tan(deg_to_rad(angle))))<.00001 and city.snapshot()==source,"canopy ridge changes at authored angle without state writes "+str(angle))
		check(is_nan(Plan.height(city,plan.boat)) and Plan.floor_support(city,plan.boat,.1).is_empty(),"central wet slot never becomes a floor "+str(angle))
		for x:float in [-.8,.8]:check(Plan.supported(plan,Plan.at(plan,Vector2(x,1.)),.12),"whole foot remains supported by real pier "+str(angle)+" "+str(x))
		var thread:=Thread.new();var error:=thread.start(worker.bind(source));var cold:Dictionary=thread.wait_to_finish() if error==OK else {}
		check(error==OK and cold.get("ok",false) and cold.patches==Pitch.patches(city,h) and cold.dock==plan and cold.source==source,"actual Thread cold read reproduces complete geometry "+str(angle))
		verify_render(city,str(angle));heights.append(Geo.ridge(h))
	check(heights[0]<heights[1] and heights[1]<heights[2] and heights[2]<heights[3] and city.undo().ok and city.houses[0].roof_pitch.degrees==45. and city.redo().ok and city.houses[0].roof_pitch.degrees==78.,"continuous canopy height and one-step exact Undo Redo")
	var saved:Dictionary=city.snapshot();var cold:=State.new();check(city.save_city(out+"/boat.json").ok and cold.load_city(out+"/boat.json").ok and cold.snapshot()==saved and Pitch.patches(cold,cold.houses[0])==Pitch.patches(city,city.houses[0]),"actual schema41 disk reader preserves source and CPU surfaces")
	var invalid:Dictionary=saved.duplicate(true);invalid.schema=40;check(not State.new().restore(invalid).ok,"schema40 rejects new recipe");invalid=saved.duplicate(true);invalid.houses[0].roof_pitch.profile="renaissance";check(not State.new().restore(invalid).ok,"version6 cannot masquerade as another profile")
	var a:=Plan.at(original_plan,Vector2(-2.,1.6));var b:=Plan.at(original_plan,Vector2(2.,1.6));check(Pitch.blocks(city,city.houses[0],a,b,4.,.03),"steep actual canopy blocks overhead corridor");city.set_house_roof_pitch("h1",0.);check(not Pitch.blocks(city,city.houses[0],a,b,4.,.03),"flat canopy releases same overhead corridor")
	city.set_house_roof_pitch("h1",null);check(city.houses==original.houses and Plan.find(city,"h1")==original_plan,"original roof restores exact original author and dock")
	for old:Dictionary in [{"version":1,"degrees":78.},{"version":2,"profile":"round","degrees":78.},{"version":3,"profile":"modern","degrees":78.},{"version":4,"profile":"clockwork","degrees":78.},{"version":5,"profile":"renaissance","degrees":78.}]:
		city=Base.fixture();city.houses[0].roof_pitch=old;var source:Dictionary=city.snapshot()
		check(State.new().restore(source).ok and not Pitch.active(city,city.houses[0]) and Geo.ridge(city.houses[0])==2.18 and Pitch.Geometry.degrees(city.houses[0])<0.,"older recipe stays dormant "+str(old.version))
		check(city.set_house_roof_pitch("h1",15.).ok and city.undo().ok and city.houses==source.houses,"explicit upgrade Undo keeps old recipe "+str(old.version))
	city=Base.fixture();city.rotate_house("h1",.35);var rotated_line:Array[Vector2]=[]
	for p:Vector2 in [Vector2(-32,-17.7),Vector2(-24,-17.7)]:rotated_line.append(Plan.Frame.point(city.houses[0],p))
	city.add_water(rotated_line,2.4,"pond");city.houses[0].base_y=.2;city.revision+=1;check(city.set_house_roof_pitch("h1",45.).ok and not Plan.find(city,"h1").is_empty(),"rotated raised shore still supports both roofs");verify_render(city,"rotated raised")
	city=Base.fixture();city.add_cell("h1",0,0,1);city.set_house_roof_pitch("h1",45.);verify_render(city,"multilevel context main")
	city=Base.fixture();city.set_house_roof_pitch("h1",0.);var plan:=Plan.find(city,"h1");var neighbor:Dictionary=city.houses[0].duplicate(true);neighbor.id="high_neighbor";neighbor.erase("architecture");neighbor.erase("roof_pitch");var at:=Plan.at(plan,Vector2(0,1.));neighbor.origin=[at.x,at.y];neighbor.base_y=3.4;city.houses.append(neighbor);city.revision+=1
	check(not Plan.find(city,"h1").is_empty(),"high neighbor clears low canopy")
	city.set_house_roof_pitch("h1",78.);check(Plan.find(city,"h1").is_empty() and city.houses[0].roof_pitch.degrees==78.,"neighbor above old2.3 boundary withdraws steep dock retaining choice")
	check(city.undo().ok and not Plan.find(city,"h1").is_empty(),"Undo roof restores valid low dock despite high neighbor")
	city=Base.fixture();city.set_house_roof_pitch("h1",45.);var before_water:Dictionary=city.snapshot();check(city.remove_water_at(Vector2(-28,-17.7)).ok and Plan.find(city,"h1").is_empty() and city.houses==before_water.houses,"no water withdraws only derived dock retaining chosen pitch");check(city.undo().ok and not Plan.find(city,"h1").is_empty(),"Undo water restores dock with authored pitch")
	cold.initialize_free();check(cold.restore(before_water).ok and Pitch.patches(cold,cold.houses[0])==Pitch.patches(city,city.houses[0]),"same State reset cannot reuse stale roof or dock context")
	city=Base.fixture();city.add_cell("h1",1,0,0);city.add_district([Vector2(-31,-20),Vector2(-24,-20)] as Array[Vector2],6.);city.set_house_era("h1","district");city.set_house_roof_pitch("h1",78.)
	var inherited:Dictionary=city.snapshot();check(not city.houses[0].has("era_theme") and Pitch.active(city,city.houses[0]),"inherited pastoral boat accepts explicit pitch without pinning era")
	for era:String in ["renaissance","clockwork","modern_eco"]:
		city.set_district_era("d1",era);var reference:=State.new();reference.restore(city.snapshot());reference.houses[0].erase("roof_pitch");reference.revision+=1
		check(not Pitch.active(city,city.houses[0]) and city.houses[0].roof_pitch.degrees==78. and Plan.find(city,"h1").is_empty(),"inherited other era keeps dormant author choice without dock "+era)
		check(Pitch.context(city).roof_patches("h1")==Pitch.context(reference).roof_patches("h1"),"dormant inherited boat recipe cannot leak high Context roof "+era)
		var r:=renderer(city);var current_root:Node3D=r._house(city.houses[0]);var current_mesh:=surface_faces(current_root);current_root.free();r.free();r=renderer(reference);var reference_root:Node3D=r._house(reference.houses[0]);check(triangles(current_mesh.main)==triangles(surface_faces(reference_root).main),"actual inherited other-era main matches unpitched reference "+era);reference_root.free();r.free()
	city.set_district_era("d1","pastoral");check(Pitch.active(city,city.houses[0]) and not city.houses[0].has("era_theme") and city.houses==inherited.houses and not Plan.find(city,"h1").is_empty(),"return to inherited pastoral restores exact authored roof and dock")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"CPU isolated checks leave personal save bytes unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"heights":heights,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("BOATHOUSE_ROOF_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
