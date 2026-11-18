extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Geo=preload("res://scripts/world/city_creation_basilica_roof_pitch.gd")
const Plan=Geo.Plan
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Shell=preload("res://tests/test_city_creation_acoustic_shell.gd")
const Hits=preload("res://tests/test_city_creation_corner_loggia.gd")
const Bridge=preload("res://scripts/world/city_creation_skybridge_plan.gd")
var checks:=0
var failures:Array=[]
var worst_error:=0.
var worst_seam_gap:=0.
var worst_contact_error:=0.
var seam_facts:Array=[]
var baseline:Script
var baseline_facts:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
static func fixture(width:int=2,depth:int=3,floors:int=1)->RefCounted:
	var city:=Shell.fixture(width,depth,floors,"pavilion");city.set_house_era("h1","pastoral");city.set_house_architecture("h1","roman_basilica");return city
func renderer(city)->Node3D:
	var r:=Renderer.new();root.add_child(r);r.state=city;r.buildings=Node3D.new();r.add_child(r.buildings)
	for node in [r.shore,r.lilypads,r.wildlife]:r.add_child(node)
	return r
func worker(source:Dictionary)->Dictionary:
	var city:=State.new();var reply:Dictionary=city.restore(source)
	return {"ok":true,"data":Geo.for_house(city,city.houses[0]),"source":city.snapshot()} if reply.ok else reply
func materials(material:Material)->Dictionary:
	var result:Dictionary={}
	for property:Dictionary in material.get_property_list():
		if not int(property.usage)&PROPERTY_USAGE_STORAGE:continue
		var value:Variant=material.get(property.name);result[str(property.name)]=[value.get_class(),value.resource_path] if value is Resource else value
	for key:StringName in material.get_meta_list():result["meta/"+str(key)]=material.get_meta(key)
	return result
func surfaces(node:Node3D,fixed:bool=false)->Array:
	var rows:Array=[]
	for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		if fixed and (str(mesh.name).begins_with("BasilicaAisleRoofClosure") or str(mesh.name).begins_with("BasilicaAisleEndClosure") or str(mesh.name).begins_with("BasilicaApseRoofClosure") or str(mesh.name).begins_with("BasilicaClerestory") or str(mesh.name).begins_with("CivicClosedGable") or str(mesh.name).begins_with("BasilicaNaveTileRoof") or str(mesh.name).begins_with("BasilicaAisleTileRoof") or str(mesh.name).begins_with("BasilicaApseTileRoof")):continue
		var pose:Transform3D=node.global_transform.affine_inverse()*mesh.global_transform
		for i in range(mesh.mesh.get_surface_count()):rows.append(var_to_bytes([mesh.mesh.surface_get_arrays(i),pose,materials(mesh.material_override)]).hex_encode())
	rows.sort();return rows
func original_baseline(city,label:String)->void:
	if baseline==null:return
	var r:=renderer(city);var current:Node3D=r._house(city.houses[0]);var old_renderer:=renderer(city);var old:=Node3D.new();old_renderer.add_child(old);var palette:Array=old_renderer.HouseColors.era_palette(old_renderer,city.houses[0],old_renderer.HouseColors.base_palette(old_renderer,city.houses[0]),false)
	baseline.build(old_renderer,old,city.houses[0],palette,Plan.massing(city,city.houses[0]));baseline_debug(old.find_child("RomanBasilicaMassing",true,false),current.find_child("RomanBasilicaMassing",true,false),label);check(surfaces(old.find_child("RomanBasilicaMassing",true,false))==surfaces(current.find_child("RomanBasilicaMassing",true,false)),"real original complete builder arrays and all stored material fields "+label);old.free();old_renderer.free();current.free();r.free()
func area(points:Array)->float:
	var total:=0.
	for i in range(0,points.size(),3):
		var a:=Vector2(points[i].x,points[i].z);var b:=Vector2(points[i+1].x,points[i+1].z);var c:=Vector2(points[i+2].x,points[i+2].z);total+=absf((b-a).cross(c-a))*.5
	return total
func verify_render(city,label:String)->Array:
	var h:Dictionary=city.houses[0];var data:=Geo.for_house(city,h);var r:=renderer(city);var house:Node3D=r._house(h);var mass:Node3D=house.find_child("RomanBasilicaMassing",true,false);var nodes:Array=house.find_children("BasilicaPitchedCell_*","Node3D",true,false);var same:bool=nodes.size()==data.records.size();var valid:=true;var uv_good:=true;var owners:=true;var picked:=true;var patches:=0;var areas:Dictionary={};var seams:Dictionary={};var pane_good:=true;var panes:=0
	for k in range(mini(nodes.size(),data.records.size())):
		var row:Dictionary=data.records[k];var meshes:Array=nodes[k].get_children().filter(func(n):return n is MeshInstance3D);same=same and meshes.size()==row.parts.size();var roof_faces:=PackedVector3Array();var wall_faces:=PackedVector3Array();owners=owners and int(row.cell.level)==int(data.plan.floors)-1
		for j in range(mini(meshes.size(),row.parts.size())):
			var part:Dictionary=row.parts[j];var mesh:MeshInstance3D=meshes[j];var faces:=mesh.mesh.get_faces();var pose:Transform3D=house.global_transform.affine_inverse()*mesh.global_transform;same=same and faces.size()==part.vertices.size();patches+=1
			for i in range(mini(faces.size(),part.vertices.size())):
				var index:int=i-i%3+[0,2,1][i%3];var error:float=(pose*faces[i]).distance_to(data.pose*part.vertices[index]);same=same and error<.00015;worst_error=maxf(worst_error,error)
			if part.material=="glass":
				var pane:Dictionary=mesh.get_meta("basilica_civic_pane",{});pane_good=pane_good and not pane.is_empty()
				if pane.get("visible",false):
					panes+=1;var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF);var outside:=-INF if float(pane.normal.x)>0. else INF
					for point:Vector3 in faces:outside=maxf(outside,point.x) if float(pane.normal.x)>0. else minf(outside,point.x)
					for point:Vector3 in faces:
						if absf(point.x-outside)<.000001:low=low.min(Vector2(point.z,point.y));high=high.max(Vector2(point.z,point.y))
					var middle:Vector2=(low+high)*.5;var size_actual:=high-low-Vector2.ONE*.02;var actual_at:=Vector3(outside,middle.y,middle.x);var normal:Vector3=(pose.basis*Vector3(pane.normal)).normalized();var at:Vector3=pose*Vector3(pane.at)+normal*.006
					pane_good=pane_good and Vector3(pane.at).distance_to(actual_at)<.00015 and Vector2(pane.size).distance_to(size_actual)<.00015 and pane.size.x>0. and pane.size.y>0. and house.get_meta("civic_windows",[]).any(func(window):return Vector3(window.at).distance_to(at)<.00015 and Vector2(window.size).distance_to(pane.size)<.00015 and Vector3(window.normal).distance_to(normal)<.00015)
			for i in range(0,part.vertices.size(),3):valid=valid and part.vertices[i].is_finite() and (part.vertices[i+1]-part.vertices[i]).cross(part.vertices[i+2]-part.vertices[i]).length_squared()>.0000000001
			if part.roof_skin:
				roof_faces.append_array(PackedVector3Array(part.vertices));areas[part.name]=float(areas.get(part.name,0.))+area(part.vertices);var arrays:Array=mesh.mesh.surface_get_arrays(0);var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
				for i in range(faces.size()):
					var source_index:int=i-i%3+[0,2,1][i%3];uv_good=uv_good and uv[indices[i]].distance_to(part.uv[source_index])<.00015 and normals[indices[i]].y>0.
				for i in range(0,indices.size(),3):uv_good=uv_good and absf((uv[indices[i+1]]-uv[indices[i]]).cross(uv[indices[i+2]]-uv[indices[i]]))>.000001
				if part.name!="BasilicaApseTileRoof":
					for i in range(part.vertices.size()):
						var point:Vector3=part.vertices[i];var key:=str(part.name)+str(Vector3i(roundi(point.x*10000),roundi(point.y*10000),roundi(point.z*10000)));var previous:Vector2=seams.get(key,part.uv[i]);uv_good=uv_good and previous.distance_to(part.uv[i])<.001;seams[key]=part.uv[i]
			else:wall_faces.append_array(PackedVector3Array(part.vertices))
		for body:StaticBody3D in nodes[k].find_children("*","StaticBody3D",true,false):picked=picked and body.get_child(0).shape.get_faces()==(roof_faces if body.get_meta("roof_surface",false) else wall_faces) and body.get_meta("cell_id","")==str(row.cell.id)
	check(same and patches==data.patches.size(),"every actual clipped triangle equals CPU within0.15mm "+label);check(valid and uv_good,"finite nondegenerate upward metric tile UV and continuous clipped seams "+label);check(owners and picked,"skin and upper-wall picks carry actual highest room IDs "+label)
	check(pane_good and panes>0,"civic pane at size normal use actual outer glass face not taller AABB "+label)
	var p:Dictionary=data.plan;var half:float=p.width*.5;var depth:float=p.depth*.5;var nave:float=p.width*.23;var radius:float=data.apse_radius;var expected:Dictionary={"BasilicaNaveTileRoof":2.*(nave+.10)*(p.depth+.18),"BasilicaAisleTileRoof":2.*(half+.10-nave)*(p.depth-radius+.10),"BasilicaApseTileRoof":.5*32.*pow(radius+.07,2.)*sin(PI/32.)};var covered:=true
	for key:String in expected:covered=covered and absf(float(areas.get(key,0.))-float(expected[key]))<.0001
	check(covered,"highest-room roof slices preserve complete analytic three-roof footprint areas "+label);check(data.upper-data.aisle_top>=.329999 and house.get_meta("basilica_roof_pitch",{}).get("apex")==data.apex,"clerestory keeps positive original clearance and real skin anchor "+label)
	var blocked:=0
	for door_x:float in p.door_xs:
		for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
			if Hits.hits(mesh,mass,Vector3(door_x,.55,depth+.30),Vector3(door_x,.55,depth-.30)):blocked+=1;break
	check(blocked==0,"all original door arches remain actual open geometry "+label)
	var apse_z:float=-depth+radius;blocked=0
	for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
		if Hits.hits(mesh,mass,Vector3(-.12,.6,apse_z-radius*.3),Vector3(.12,.6,apse_z-radius*.3)):blocked+=1;break
	check(blocked==0,"semicircular apse retains true hollow lower interior "+label)
	if float(h.roof_pitch.degrees)==0.:
		var skin_hits:=0;var wall_hits:=0;var anchor:Vector3=data.apex
		for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
			if not Hits.hits(mesh,house,anchor+Vector3.UP*.03,anchor-Vector3.UP*.03):continue
			if str(mesh.name).begins_with("BasilicaNaveTileRoof"):skin_hits+=1
			else:wall_hits+=1
		check(skin_hits>0 and wall_hits==0 and absf(anchor.x-float(p.center.x))<nave-.065,"flat roof handle lies inside actual nave skin and outside every clerestory beam "+label)
	if float(h.roof_pitch.degrees)!=15.:verify_seams(house,label,data.plan)
	var fixed:=surfaces(mass,true);house.free();r.free();return fixed
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-builder="):baseline=load(arg.trim_prefix("--baseline-builder="))
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	for size:Vector3i in [Vector3i(1,1,1),Vector3i(2,3,1),Vector3i(3,2,2)]:
		var city:=fixture(size.x,size.y,size.z);var source:Dictionary=city.snapshot();var p:=Plan.massing(city,city.houses[0]);original_baseline(city,str(size));check(Pitch.supported(city,city.houses[0]) and not Pitch.active(city,city.houses[0]),"original basilica waits for explicit new recipe "+str(size));var history:int=city._undo.size();var previous:Array=[]
		for angle:float in [0.,15.,Geo.source_angle(city,city.houses[0]),45.,78.]:
			var reply:Dictionary=city.set_house_roof_pitch("h1",angle);var saved:Dictionary=city.snapshot();var data:=Geo.for_house(city,city.houses[0]);var label:=str(size)+str(angle);check(reply.ok and saved.schema==44 and city.houses[0].roof_pitch=={"version":9,"profile":"roman_basilica","degrees":angle} and city.houses[0].cells==source.houses[0].cells,"schema44 retains every original room "+label);check(Pitch.patches(city,city.houses[0])==data.patches and city.snapshot()==saved,"pure complete shared clearance plan "+label)
			check(absf(data.ridge-data.upper-.38*data.gain)<.000001 and absf(data.aisle_top-p.height-.06-.25*data.gain)<.000001,"main and aisle heights follow same actual authored gain "+label)
			var apse_high:=-INF;var apse_low:=INF
			for patch:Dictionary in data.patches:
				if patch.part!="BasilicaApseTileRoof":continue
				for point:Vector3 in patch.vertices:apse_high=maxf(apse_high,point.y);apse_low=minf(apse_low,point.y)
			check(absf(apse_high-apse_low-.26*data.gain)<.00001,"actual apse fan rise changes with same gain "+label);var thread:=Thread.new();var error:=thread.start(worker.bind(saved));var cold:Dictionary=thread.wait_to_finish() if error==OK else {};check(error==OK and cold.get("ok",false) and cold.data==data and cold.source==saved,"actual Thread restores exact three-roof CPU model "+label)
			var fixed:=verify_render(city,label)
			if previous.is_empty():previous=fixed
			else:check(previous==fixed,"all lower walls arches apse and original fixed material arrays stay identical "+label)
		var cold:=State.new();var file:=out+"/basilica_%dx%dx%d.json"%[size.x,size.y,size.z];check(city.save_city(file).ok and cold.load_city(file).ok and cold.snapshot()==city.snapshot() and Geo.for_house(cold,cold.houses[0])==Geo.for_house(city,city.houses[0]),"actual schema44 atomic disk cold read "+str(size));check(city._undo.size()==history+5 and city.undo().ok and city.houses[0].roof_pitch.degrees==45. and city.redo().ok and city.houses[0].roof_pitch.degrees==78.,"one-step pitch Undo Redo "+str(size));city.set_house_roof_pitch("h1",null);check(city.houses==source.houses,"original button data restores exact previous recipe "+str(size));cold.initialize_free();check(cold.restore(source).ok and Geo.for_house(cold,cold.houses[0]).patches.is_empty(),"same-State reset never reuses obsolete basilica plan")
	var city:=fixture();city.set_house_roof_pitch("h1",45.);var saved:Dictionary=city.snapshot();var cold:=State.new();cold.restore(saved);var invalid:Dictionary=saved.duplicate(true);invalid.schema=43;check(not cold.restore(invalid).ok and cold.snapshot()==saved,"schema43 rejects version9 atomically");invalid=saved.duplicate(true);invalid.houses[0].roof_pitch.profile="modern";check(not cold.restore(invalid).ok and cold.snapshot()==saved,"incorrect basilica profile rejected atomically")
	for recipe:Dictionary in [{"version":1,"degrees":78.},{"version":2,"profile":"round","degrees":78.},{"version":3,"profile":"modern","degrees":78.},{"version":4,"profile":"clockwork","degrees":78.},{"version":5,"profile":"renaissance","degrees":78.},{"version":6,"profile":"boathouse","degrees":78.},{"version":7,"profile":"acoustic_shell","degrees":78.},{"version":8,"profile":"ionic_stoa","degrees":78.}]:
		city=fixture();city.houses[0].roof_pitch=recipe;saved=city.snapshot();check(State.new().restore(saved).ok and not Pitch.active(city,city.houses[0]),"older profile stays dormant "+str(recipe.version));check(city.set_house_roof_pitch("h1",15.).ok and city.undo().ok and city.houses==saved.houses,"explicit upgrade Undo restores dormant profile "+str(recipe.version))
	for kind:String in ["partial","terrace","side_road","through_road"]:
		city=fixture();city.set_house_roof_pitch("h1",45.);saved=city.snapshot();var reply:Dictionary
		if kind=="partial":reply=city.add_cell("h1",0,0,1)
		elif kind=="terrace":reply=city.add_cell("h1",-1,0,0,"terrace")
		elif kind=="side_road":reply=city.add_road([Vector2(-32,-20),Vector2(-29.45,-20)] as Array[Vector2],"path","none")
		else:reply=city.add_road([Vector2(-32,-20),Vector2(-22,-20)] as Array[Vector2],"path","none")
		check(reply.ok and Plan.massing(city,city.houses[0]).is_empty() and not Pitch.active(city,city.houses[0]) and city.houses[0].roof_pitch==saved.houses[0].roof_pitch,"existing fallback preserves author roof "+kind);check(city.undo().ok and city.houses==saved.houses and Pitch.active(city,city.houses[0]),"fallback Undo restores original complete basilica "+kind)
	city=fixture(3,2,2);city.houses[0].base_y=1.2;city.revision+=1;check(city.rotate_house("h1",.35).ok and city.set_house_roof_pitch("h1",78.).ok,"rotated raised whole basilica remains editable");verify_render(city,"raised rotated")
	city=fixture(1,1);city.add_district([Vector2(-31,-20),Vector2(-24,-20)] as Array[Vector2],6.);city.set_house_era("h1","district");city.set_house_roof_pitch("h1",78.);check(Pitch.active(city,city.houses[0]) and not city.houses[0].has("era_theme"),"inherited pastoral author remains unpinned");city.set_district_era("d1","renaissance");check(not Pitch.active(city,city.houses[0]) and Geo.for_house(city,city.houses[0]).patches.is_empty() and city.houses[0].roof_pitch.version==9,"inherited era dormancy retains chosen recipe");city.set_district_era("d1","pastoral");check(Pitch.active(city,city.houses[0]),"return to pastoral restores basilican roof")
	city=fixture(1,1);city.set_house_roof_pitch("h1",0.)
	for at:Vector2 in [Vector2(-33,-20),Vector2(-24.5,-20)]:city.add_house(at)
	for id:String in ["h2","h3"]:city.houses[city._house_index(id)].base_y=.2;city.set_house_era(id,"modern_eco");city.set_house_architecture(id,"chalet");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
	city.set_house_skybridge_span("h3",true);check(not Bridge.for_house(city,city.houses[1]).is_empty(),"real nine-metre bridge clears flat raised-nave basilica");city.set_house_roof_pitch("h1",78.);check(Bridge.for_house(city,city.houses[1]).is_empty(),"tall three-roof and clerestory withdraw real cloud bridge");check(city.undo().ok and not Bridge.for_house(city,city.houses[1]).is_empty(),"basilica Undo restores actual nine-metre bridge")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"isolated CPU validation preserves personal save")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"max_seam_gap":worst_seam_gap,"contact_target":.001,"max_contact_target_error":worst_contact_error,"seam_facts":seam_facts,"baseline_facts":baseline_facts,"max_mesh_vertex_error":worst_error,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("BASILICA_ROOF_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)

func baseline_debug(old:Node3D,current:Node3D,label:String)->void:
	var a:Array=old.find_children("*","MeshInstance3D",true,false);var b:Array=current.find_children("*","MeshInstance3D",true,false);var differences:Array=[]
	for i in range(mini(a.size(),b.size())):
		var old_pose:Transform3D=old.global_transform.affine_inverse()*a[i].global_transform;var now_pose:Transform3D=current.global_transform.affine_inverse()*b[i].global_transform;var ma:=materials(a[i].material_override);var mb:=materials(b[i].material_override);var keys:Array=[]
		for key:String in ma:
			if ma[key]!=mb.get(key):keys.append({"key":key,"old":str(ma[key]),"current":str(mb.get(key))})
		if old_pose!=now_pose or a[i].mesh.surface_get_arrays(0)!=b[i].mesh.surface_get_arrays(0) or not keys.is_empty():differences.append({"old":str(a[i].name),"current":str(b[i].name),"mesh_equal":a[i].mesh.surface_get_arrays(0)==b[i].mesh.surface_get_arrays(0),"pose_old":old_pose,"pose_current":now_pose,"material":keys})
	baseline_facts.append({"label":label,"old_count":a.size(),"current_count":b.size(),"differences":differences})

func verify_seams(house:Node3D,label:String,plan:Dictionary)->void:
	var roofs:Dictionary={};var joins:Dictionary={};var join_faces:Dictionary={};var inverse:=house.global_transform.affine_inverse()
	var mapping:Dictionary={"BasilicaClerestoryLintel":"BasilicaNaveTileRoof","BasilicaClerestoryPier":"BasilicaNaveTileRoof","BasilicaClerestorySill":"BasilicaAisleTileRoof","CivicClosedGable":"BasilicaNaveTileRoof","BasilicaAisleRoofClosure":"BasilicaAisleTileRoof","BasilicaAisleEndClosure":"BasilicaAisleTileRoof","BasilicaApseRoofClosure":"BasilicaApseTileRoof"}
	for key:String in mapping:joins[key]={};join_faces[key]=PackedVector3Array()
	for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
		var pose:Transform3D=inverse*mesh.global_transform;var name:=str(mesh.name);var points:=PackedVector3Array()
		for point:Vector3 in mesh.mesh.get_faces():points.append(pose*point)
		for roof:String in ["BasilicaNaveTileRoof","BasilicaAisleTileRoof","BasilicaApseTileRoof"]:
			if name.begins_with(roof):
				if not roofs.has(roof):roofs[roof]=PackedVector3Array()
				roofs[roof].append_array(points)
		for key:String in mapping:
			if not name.begins_with(key):continue
			join_faces[key].append_array(points)
			for point:Vector3 in points:
				var token:=str(Vector2i(roundi(point.x*10000),roundi(point.z*10000)))
				if not joins[key].has(token) or point.y>joins[key][token].y:joins[key][token]=point
	for key:String in mapping:
		var valid:bool=not joins[key].is_empty();var samples:=0;var gap:=0.;var triangles:PackedVector3Array=roofs.get(mapping[key],PackedVector3Array())
		for point:Vector3 in joins[key].values():
			var sill:bool=key=="BasilicaClerestorySill"
			if sill and absf(point.x-float(plan.center.x))<float(plan.width)*.23-.00002:continue
			if sill and point.z<float(plan.center.y)-float(plan.depth)*.5+minf(float(plan.width)*.5*.72,float(plan.depth)*.5*.65)-.00002:continue
			samples+=1
			var at:=Vector2(point.x,point.z);var high:=actual_height(triangles,at);var join_top:=actual_height(join_faces[key],at,not sill);var contact:float=join_top-high if sill else high-join_top
			var error:=absf(contact-.001);valid=valid and is_finite(error) and error<=.0005;gap=maxf(gap,contact);worst_contact_error=maxf(worst_contact_error,error)
			if error>.0005 and seam_facts.size()<20:seam_facts.append({"label":label,"join":key,"point":point,"join_height":join_top,"roof_height":high,"contact":contact,"target_error":error})
		worst_seam_gap=maxf(worst_seam_gap,gap);check(valid and samples>0,"actual "+key+" has intended1mm roof contact clearance within0.5mm "+label)

func actual_height(triangles:PackedVector3Array,at:Vector2,highest:bool=true)->float:
	var high:=-INF if highest else INF
	for i in range(0,triangles.size(),3):
		var a:=Vector2(triangles[i].x,triangles[i].z);var b:=Vector2(triangles[i+1].x,triangles[i+1].z);var c:=Vector2(triangles[i+2].x,triangles[i+2].z);var determinant:float=(b-a).cross(c-a)
		if absf(determinant)<.000000001:continue
		var wb:float=(at-a).cross(c-a)/determinant;var wc:float=(b-a).cross(at-a)/determinant;var wa:=1.-wb-wc
		if minf(wa,minf(wb,wc))>=-.00002:
			var height:float=triangles[i].y*wa+triangles[i+1].y*wb+triangles[i+2].y*wc;high=maxf(high,height) if highest else minf(high,height)
	return high
