extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Geo=Pitch.Acoustic
const Plan=Geo.Plan
const Base=preload("res://tests/test_city_creation_acoustic_shell.gd")
const Bridge=preload("res://scripts/world/city_creation_skybridge_plan.gd")
var checks:=0
var failures:Array=[]
var worst_mesh_error:=0.
var baseline_builder:Script
func _initialize()->void:run.call_deferred()
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label);push_error(label)
func renderer(city:RefCounted)->Node3D:
	var r:=Base.Renderer.new();root.add_child(r);r.state=city;r.buildings=Node3D.new();r.add_child(r.buildings)
	for node in [r.shore,r.lilypads,r.wildlife]:r.add_child(node)
	return r
func worker(source:Dictionary)->Dictionary:
	var city:=State.new();var reply:Dictionary=city.restore(source)
	return {"ok":reply.ok,"data":Geo.for_house(city,city.houses[0]),"source":city.snapshot()} if reply.ok else reply
func boards(root_node:Node3D)->Array:
	var result:Array=[]
	for mesh:MeshInstance3D in root_node.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).begins_with("AcousticStage"):result.append(var_to_bytes([str(mesh.name),mesh.mesh.get_faces(),mesh.transform]).hex_encode())
	result.sort();return result
func material_signature(material:Material)->Dictionary:
	var result:Dictionary={}
	for property:Dictionary in material.get_property_list():
		if not int(property.usage)&PROPERTY_USAGE_STORAGE:continue
		var value:Variant=material.get(property.name)
		result[str(property.name)]=[value.get_class(),value.resource_path] if value is Resource else value
	for key:StringName in material.get_meta_list():result["meta/"+str(key)]=material.get_meta(key)
	return result
func baseline_surfaces(stage:Node3D)->Array:
	var result:Array=[]
	for mesh:MeshInstance3D in stage.find_children("*","MeshInstance3D",true,false):
		var transform:Transform3D=stage.global_transform.affine_inverse()*mesh.global_transform
		for surface in range(mesh.mesh.get_surface_count()):result.append(var_to_bytes([mesh.mesh.surface_get_arrays(surface),transform,material_signature(mesh.material_override)]).hex_encode())
	result.sort();return result
func verify_original_baseline(city:RefCounted,label:String)->void:
	if baseline_builder==null:return
	var r:=renderer(city);var current:Node3D=r._house(city.houses[0]);var old:=Node3D.new();r.add_child(old);baseline_builder.build(r,old,city.houses[0])
	var old_stage:Node3D=old.find_child("TimberAcousticHall",true,false);var current_stage:Node3D=current.find_child("TimberAcousticHall",true,false)
	check(old_stage!=null and current_stage!=null and baseline_surfaces(old_stage)==baseline_surfaces(current_stage),"actual original builder mesh arrays and full stored material fields remain identical "+label)
	old.free();current.free();r.free()
func verify_render(city:RefCounted,label:String)->Array:
	var data:=Geo.for_house(city,city.houses[0]);var r:=renderer(city);var shell:Node3D=r._house(city.houses[0]);var stage:Node3D=shell.find_child("TimberAcousticHall",true,false)
	check(stage!=null,"actual published curved hall exists "+label)
	if stage==null:shell.free();r.free();return []
	var nodes:Array=stage.find_children("BentTimberPanel*","Node3D",true,false);var same:bool=nodes.size()==data.records.size();var finite:=true;var thick:=true;var sources:=true;var pick:=true;var count:=0
	for k in range(mini(nodes.size(),data.records.size())):
		var row:Dictionary=data.records[k];var meshes:Array=nodes[k].get_children().filter(func(n):return n is MeshInstance3D);same=same and meshes.size()==row.parts.size();sources=sources and int(row.cell.level)==int(data.plan.floors)-1
		var roof_faces:=PackedVector3Array();var wall_faces:=PackedVector3Array()
		for index in range(mini(meshes.size(),row.parts.size())):
			var part:Dictionary=row.parts[index];var faces:PackedVector3Array=meshes[index].mesh.get_faces();var pose:Transform3D=shell.global_transform.affine_inverse()*meshes[index].global_transform;same=same and faces.size()==part.vertices.size()
			for i in range(mini(faces.size(),part.vertices.size())):
				var source_index:int=i-i%3+[0,2,1][i%3]
				var error:float=(pose*faces[i]).distance_to(data.pose*part.vertices[source_index]);worst_mesh_error=maxf(worst_mesh_error,error);same=same and error<.00015
			for i in range(0,part.vertices.size(),3):
				var a:Vector3=part.vertices[i];var b:Vector3=part.vertices[i+1];var c:Vector3=part.vertices[i+2];finite=finite and a.is_finite() and b.is_finite() and c.is_finite() and (b-a).cross(c-a).length_squared()>.0000000001
			if part.roof_skin:thick=thick and absf(part.vertices[0].distance_to(part.vertices[6])-.07)<.00001;roof_faces.append_array(PackedVector3Array(part.vertices))
			else:wall_faces.append_array(PackedVector3Array(part.vertices))
			count+=1
		for body:StaticBody3D in nodes[k].find_children("*","StaticBody3D",true,false):
			var expected:=roof_faces if body.get_meta("roof_surface",false) else wall_faces;var collision:CollisionShape3D=body.get_child(0)
			pick=pick and collision.shape is ConcavePolygonShape3D and collision.shape.get_faces()==expected and body.get_meta("cell_id","")==str(row.cell.id)
	check(same and count==data.patches.size(),"all actual parts correspond to CPU patches within0.15mm "+label);check(finite and thick,"all parts nondegenerate and skin70mm along new normal "+label);check(sources and pick,"separate roof and side/rib true picks retain original top cells "+label)
	var blocked:=0
	for x:float in [-.25,0.,.25]:
		for y:float in [.55,1.1]:
			for mesh:MeshInstance3D in shell.find_children("*","MeshInstance3D",true,false):
				if Base.Hits.hits(mesh,stage,Vector3(x,y,float(data.plan.depth)*.5+.12),Vector3(x,y,float(data.plan.depth)*.5-.32)):blocked+=1;break
	check(blocked==0,"six actual mouth rays remain unblocked "+label)
	check(shell.has_meta("acoustic_roof_pitch") and shell.get_meta("acoustic_roof_pitch").apex==data.apex,"roof handle anchor is shared actual skin triangle interior "+label)
	var floor_data:=boards(shell);shell.free();r.free();return floor_data
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-builder="):baseline_builder=load(arg.trim_prefix("--baseline-builder="))
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	for size:Vector3i in [Vector3i(1,1,1),Vector3i(2,2,1),Vector3i(3,2,2)]:
		var city:RefCounted=Base.fixture(size.x,size.y,size.z);var original:Dictionary=city.snapshot();var source_plan:=Plan.for_house(city,city.houses[0]);var original_angle:=Geo.source_angle(city,city.houses[0]);var floor_data:Array=[];var heights:Array=[];var depth:int=city._undo.size()
		verify_original_baseline(city,str(size))
		check(Pitch.supported(city,city.houses[0]) and not Pitch.active(city,city.houses[0]),"original shell is unchanged until explicit choice "+str(size))
		for angle:float in [0.,15.,original_angle,45.,78.]:
			var reply:Dictionary=city.set_house_roof_pitch("h1",angle);var saved:Dictionary=city.snapshot();var h:Dictionary=city.houses[0];var data:=Geo.for_house(city,h);var label:=str(size)+" "+str(angle)
			check(reply.ok and saved.schema==42 and h.roof_pitch=={"version":7,"profile":"acoustic_shell","degrees":angle} and h.cells==original.houses[0].cells and h.seed==original.houses[0].seed,"explicit schema42 retains all authored rooms and seed "+label)
			check(Pitch.patches(city,h)==data.patches and city.snapshot()==saved and not data.patches.is_empty(),"CPU full geometry is read-only and used by bridge clearance "+label)
			var mouth:=Plan.point(data.plan,1.);check(mouth.x>=float(source_plan.height)+.18-.00001,"mouth height never falls below original usable opening "+label);heights.append(mouth.x)
			if angle==0.:check(absf(Plan.point(data.plan,0.).x-mouth.x)<.000001 and data.records.any(func(row):return row.parts.any(func(part):return part.name=="AcousticRearClosure")),"zero is genuine flat cover with real rear closure "+str(size))
			if angle==original_angle:
				var exact:=true
				for t:float in [0.,.1,.4,.65,1.]:exact=exact and Plan.point(data.plan,t).distance_to(Plan.point(source_plan,t))<.000001
				check(exact,"source angle exactly reproduces original curved profile "+str(size))
			var thread:=Thread.new();var error:=thread.start(worker.bind(saved));var from_thread:Dictionary=thread.wait_to_finish() if error==OK else {}
			check(error==OK and from_thread.get("ok",false) and from_thread.data==data and from_thread.source==saved,"real Thread cold reader reproduces exact full plan "+label)
			var current_floor:=verify_render(city,label)
			if floor_data.is_empty():floor_data=current_floor
			else:check(current_floor==floor_data,"actual stage base and floor boards remain fixed "+label)
		var cold:=State.new();var filename:=out+"/shell_%dx%dx%d.json"%[size.x,size.y,size.z];check(city.save_city(filename).ok and cold.load_city(filename).ok and cold.snapshot()==city.snapshot() and Geo.for_house(cold,cold.houses[0])==Geo.for_house(city,city.houses[0]),"real schema42 disk reader reproduces all parts "+str(size))
		check(city._undo.size()==depth+5 and city.undo().ok and city.houses[0].roof_pitch.degrees==45. and city.redo().ok and city.houses[0].roof_pitch.degrees==78. and heights[-1]>heights[0],"one choice per history step and genuine flat to tall change "+str(size))
		city.set_house_roof_pitch("h1",null);check(city.houses==original.houses and Plan.for_house(city,city.houses[0])==source_plan,"original restores exact pre-edit recipe and curve "+str(size));cold.initialize_free();check(cold.restore(original).ok and Plan.for_house(cold,cold.houses[0])==source_plan,"same State reset removes stale custom curve "+str(size))
	var city:RefCounted=Base.fixture();city.set_house_roof_pitch("h1",45.);var invalid:Dictionary=city.snapshot();invalid.schema=41;check(not State.new().restore(invalid).ok,"schema41 rejects acoustic version7");invalid=city.snapshot();invalid.houses[0].roof_pitch.profile="modern";check(not State.new().restore(invalid).ok,"version7 cannot masquerade as modern recipe")
	for old:Dictionary in [{"version":1,"degrees":78.},{"version":2,"profile":"round","degrees":78.},{"version":3,"profile":"modern","degrees":78.},{"version":4,"profile":"clockwork","degrees":78.},{"version":5,"profile":"renaissance","degrees":78.},{"version":6,"profile":"boathouse","degrees":78.}]:
		city=Base.fixture();city.houses[0].roof_pitch=old;var saved:Dictionary=city.snapshot();check(State.new().restore(saved).ok and not Pitch.active(city,city.houses[0]) and not Plan.for_house(city,city.houses[0]).has("degrees"),"old recipe stays dormant on acoustic shell "+str(old.version));check(city.set_house_roof_pitch("h1",15.).ok and city.undo().ok and city.houses==saved.houses,"upgrade Undo preserves old dormant recipe "+str(old.version))
	city=Base.fixture(3,1);var before_angle:=Geo.source_angle(city,city.houses[0]);city.set_house_roof_pitch("h1",45.);var road:Dictionary=city.add_road([Vector2(-32,-20),Vector2(-29.45,-20)] as Array[Vector2],"path","none");check(road.ok and Plan.for_house(city,city.houses[0]).front==Vector2i.LEFT and Geo.source_angle(city,city.houses[0])<before_angle,"side road turns real mouth and source-angle run together");verify_render(city,"side street")
	city=Base.fixture(3,1,2);city.houses[0].base_y=1.2;city.revision+=1;check(city.rotate_house("h1",.35).ok and city.set_house_roof_pitch("h1",78.).ok,"public rotated raised double-story shell");verify_render(city,"raised rotated")
	city=Base.fixture();city.set_house_roof_pitch("h1",45.);var saved:Dictionary=city.snapshot();check(city.add_cell("h1",0,0,1).ok and not Pitch.supported(city,city.houses[0]) and not Pitch.active(city,city.houses[0]) and Geo.for_house(city,city.houses[0]).patches.is_empty() and city.houses[0].roof_pitch==saved.houses[0].roof_pitch,"partial upper level uses existing fallback retaining authored choice");check(city.undo().ok and city.houses==saved.houses and Pitch.active(city,city.houses[0]),"Undo partial level restores exact shell")
	city=Base.fixture(2,1);city.set_house_roof_pitch("h1",45.);city.houses[0].bend_angle_deg=15.;city.revision+=1;check(not Pitch.supported(city,city.houses[0]) and not Pitch.active(city,city.houses[0]) and city.houses[0].roof_pitch.degrees==45.,"real hinge layout falls back preserving choice")
	city=Base.fixture();city.set_house_roof_pitch("h1",45.);road=city.add_road([Vector2(-32,-20),Vector2(-24,-20)] as Array[Vector2],"path","none");check(road.ok and not Pitch.active(city,city.houses[0]) and city.houses[0].roof_pitch.degrees==45.,"real through-road selects passage fallback preserving choice")
	city=Base.fixture();city.set_house_roof_pitch("h1",78.);var bridge_plan:=Plan.for_house(city,city.houses[0]);var p:=Plan.point(bridge_plan,.65);var a:Vector2=bridge_plan.center+Vector2(-3.,p.y).rotated(-float(bridge_plan.angle));var b:Vector2=bridge_plan.center+Vector2(3.,p.y).rotated(-float(bridge_plan.angle));var bridge_y:float=float(bridge_plan.base_y)+p.x-.05
	check(Pitch.blocks(city,city.houses[0],a,b,bridge_y,.03),"actual tall curved timber triangles block overhead corridor");city.set_house_roof_pitch("h1",0.);check(not Pitch.blocks(city,city.houses[0],a,b,bridge_y,.03),"same corridor clears after real skin becomes flat")
	city=Base.fixture(1,1);city.set_house_roof_pitch("h1",78.);bridge_plan=Plan.for_house(city,city.houses[0]);var mouth:=Plan.point(bridge_plan,1.);var jamb_x:float=float(bridge_plan.width)*.5-.04
	a=bridge_plan.center+Vector2(jamb_x,mouth.y-.3);b=bridge_plan.center+Vector2(jamb_x,mouth.y+.3);check(Pitch.blocks(city,city.houses[0],a,b,3.4,.01),"low corridor through tall real mouth column is blocked below the skin")
	city.set_house_roof_pitch("h1",0.);check(not Pitch.blocks(city,city.houses[0],a,b,3.4,.01),"low roof shortens actual mouth column and releases same corridor")
	for at:Vector2 in [Vector2(-33,-20),Vector2(-24.5,-20)]:city.add_house(at)
	for id:String in ["h2","h3"]:city.houses[city._house_index(id)].base_y=.2;city.set_house_era(id,"modern_eco");city.set_house_architecture(id,"chalet");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
	city.set_house_skybridge_span("h3",true);var span_before:Dictionary=city.snapshot();check(not Bridge.for_house(city,city.houses[1]).is_empty(),"real nine-metre bridge clears flat one-bay shell");city.set_house_roof_pitch("h1",78.);check(Bridge.for_house(city,city.houses[1]).is_empty() and city.houses[2].skybridge_span==span_before.houses[2].skybridge_span,"solid side reflector and high mouth withdraw actual obstructed bridge retaining span choice");check(city.undo().ok and not Bridge.for_house(city,city.houses[1]).is_empty(),"Undo curved roof restores real bridge")
	city=Base.fixture();city.add_district([Vector2(-31,-20),Vector2(-24,-20)] as Array[Vector2],6.);city.set_district_era("d1","modern_eco");city.set_house_era("h1","district");city.set_house_roof_pitch("h1",78.);check(Pitch.active(city,city.houses[0]) and not city.houses[0].has("era_theme"),"inherited modern shell is editable without pinning era");city.set_district_era("d1","pastoral");check(not Pitch.active(city,city.houses[0]) and Geo.for_house(city,city.houses[0]).patches.is_empty() and city.houses[0].roof_pitch.version==7,"inherited era change makes roof dormant without dropping recipe");city.set_district_era("d1","modern_eco");check(Pitch.active(city,city.houses[0]) and not city.houses[0].has("era_theme"),"inherited modern return restores prior exact choice")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"isolated CPU validation preserves personal save bytes")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"max_mesh_vertex_error":worst_mesh_error,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ACOUSTIC_ROOF_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
