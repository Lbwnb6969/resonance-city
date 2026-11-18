extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Geo=Pitch.Stoa
const Plan=Geo.Plan
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Bridge=preload("res://scripts/world/city_creation_skybridge_plan.gd")
const ShellFixture=preload("res://tests/test_city_creation_acoustic_shell.gd")
var checks:=0
var failures:Array=[]
var baseline:Script
var worst_error:=0.
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
static func fixture(width:int=1,depth:int=1,floors:int=1)->RefCounted:
	var city:=ShellFixture.fixture(width,depth,floors,"pavilion");city.set_house_era("h1","pastoral");city.set_house_architecture("h1","ionic_stoa");return city
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
func surfaces(node:Node3D)->Array:
	var rows:Array=[]
	for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		var pose:Transform3D=node.global_transform.affine_inverse()*mesh.global_transform
		for i in range(mesh.mesh.get_surface_count()):rows.append(var_to_bytes([mesh.mesh.surface_get_arrays(i),pose,materials(mesh.material_override)]).hex_encode())
	rows.sort();return rows
func original_baseline(city,label:String)->void:
	if baseline==null:return
	var r:=renderer(city);var current:Node3D=r._house(city.houses[0]);var old:=Node3D.new();r.add_child(old);var p:=Plan.massing(city,city.houses[0]);var palette:Array=r.HouseColors.era_palette(r,city.houses[0],r.HouseColors.base_palette(r,city.houses[0]),false)
	baseline.roof(r,old,city.houses[0],palette,p);baseline.build(r,old,city.houses[0],palette,p)
	for name:String in ["IonicStoaRoof","IonicStoaColonnade"]:check(surfaces(old.find_child(name,true,false))==surfaces(current.find_child(name,true,false)),"actual original builder full mesh and stored material baseline "+name+label)
	old.free();current.free();r.free()
func verify_render(city,label:String)->Array:
	var r:=renderer(city);var shell:Node3D=r._house(city.houses[0]);var data:=Geo.for_house(city,city.houses[0]);var nodes:Array=shell.find_children("StoaPitchedRoof_*","Node3D",true,false);var same:bool=nodes.size()==data.records.size();var valid:=true;var uv_good:=true;var pick:=true;var roof_cells:Array=[];var patches:=0
	for k in range(mini(nodes.size(),data.records.size())):
		var row:Dictionary=data.records[k];var meshes:Array=nodes[k].get_children().filter(func(n):return n is MeshInstance3D);same=same and meshes.size()==row.parts.size();var roof_faces:=PackedVector3Array();var end_faces:=PackedVector3Array()
		for j in range(mini(meshes.size(),row.parts.size())):
			var part:Dictionary=row.parts[j];var mesh:MeshInstance3D=meshes[j];var faces:=mesh.mesh.get_faces();var transform:Transform3D=shell.global_transform.affine_inverse()*mesh.global_transform;same=same and faces.size()==part.vertices.size();patches+=1
			for i in range(mini(faces.size(),part.vertices.size())):
				var index:int=i-i%3+[0,2,1][i%3];var error:float=(transform*faces[i]).distance_to(data.pose*part.vertices[index]);same=same and error<.00015;worst_error=maxf(worst_error,error)
			for i in range(0,part.vertices.size(),3):valid=valid and part.vertices[i].is_finite() and (part.vertices[i+1]-part.vertices[i]).cross(part.vertices[i+2]-part.vertices[i]).length_squared()>.0000000001
			if part.roof_skin:
				roof_faces.append_array(PackedVector3Array(part.vertices));roof_cells.append(str(row.cell.id));var arrays:Array=mesh.mesh.surface_get_arrays(0);var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
				for i in range(vertices.size()):var v:=vertices[i];var expected:=Vector2(v.x/.22,signf(v.z)*Vector2(v.z,v.y-float(data.ridge)).length()/.28);uv_good=uv_good and uv[i].distance_to(expected)<.00015 and normals[i].y>0.
				for i in range(0,indices.size(),3):uv_good=uv_good and absf((uv[indices[i+1]]-uv[indices[i]]).cross(uv[indices[i+2]]-uv[indices[i]]))>.000001
			else:end_faces.append_array(PackedVector3Array(part.vertices))
		for body:StaticBody3D in nodes[k].find_children("*","StaticBody3D",true,false):pick=pick and body.get_child(0).shape.get_faces()==(roof_faces if body.get_meta("roof_surface",false) else end_faces) and body.get_meta("cell_id","")==str(row.cell.id) and int(body.get_meta("cell").level)==int(data.plan.floors)-1
	check(same and patches==data.patches.size(),"all actual roof and solid gable triangles equal CPU patches within0.15mm "+label);check(valid and uv_good,"nondegenerate actual metric UV and upward roof normals "+label);check(pick and data.records.all(func(row):return roof_cells.has(str(row.cell.id))),"true roof/gable pick and each highest room ownership "+label);check(shell.get_meta("stoa_roof_pitch",{}).get("apex")==data.apex,"handle anchor comes from actual roof triangle interior "+label)
	var columns:Array=surfaces(shell.find_child("IonicStoaColonnade",true,false));shell.free();r.free();return columns
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-builder="):baseline=load(arg.trim_prefix("--baseline-builder="))
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	for size:Vector3i in [Vector3i(1,1,1),Vector3i(3,1,2),Vector3i(2,3,2)]:
		var city:=fixture(size.x,size.y,size.z);var source:Dictionary=city.snapshot();var p:=Plan.massing(city,city.houses[0]);var angle_original:=Geo.source_angle(city,city.houses[0]);var columns:Array=[];var history:int=city._undo.size();original_baseline(city,str(size));check(Pitch.supported(city,city.houses[0]) and not Pitch.active(city,city.houses[0]),"original stoa waits for explicit recipe "+str(size))
		for angle:float in [0.,15.,angle_original,45.,78.]:
			var reply:Dictionary=city.set_house_roof_pitch("h1",angle);var saved:Dictionary=city.snapshot();var data:=Geo.for_house(city,city.houses[0]);var label:=str(size)+" "+str(angle)
			check(reply.ok and saved.schema==43 and city.houses[0].roof_pitch=={"version":8,"profile":"ionic_stoa","degrees":angle} and city.houses[0].cells==source.houses[0].cells and city.houses[0].seed==source.houses[0].seed,"schema43 retains all original rooms and seed "+label)
			check(Pitch.patches(city,city.houses[0])==data.patches and city.snapshot()==saved,"clearance uses read-only complete CPU model "+label)
			if angle==0.:check(data.records.all(func(row):return row.parts.all(func(part):return part.roof_skin)),"zero flat roof omits degenerate gables "+str(size))
			if angle==angle_original:check(absf(float(data.ridge)-(float(p.height)+.12+minf(.65,float(p.depth)*.25)))<.000001,"source angle exactly preserves original ridge "+str(size))
			var thread:=Thread.new();var error:=thread.start(worker.bind(saved));var cold:Dictionary=thread.wait_to_finish() if error==OK else {};check(error==OK and cold.get("ok",false) and cold.data==data and cold.source==saved,"actual Thread cold reader reproduces all surfaces "+label)
			var current:=verify_render(city,label)
			if columns.is_empty():columns=current
			else:check(columns==current,"all fixed columns volutes cornices walkway and materials unchanged "+label)
		var cold:=State.new();var filename:=out+"/stoa_%dx%dx%d.json"%[size.x,size.y,size.z];check(city.save_city(filename).ok and cold.load_city(filename).ok and cold.snapshot()==city.snapshot() and Geo.for_house(cold,cold.houses[0])==Geo.for_house(city,city.houses[0]),"actual schema43 file cold read "+str(size));check(city._undo.size()==history+5 and city.undo().ok and city.houses[0].roof_pitch.degrees==45. and city.redo().ok and city.houses[0].roof_pitch.degrees==78.,"one-step Undo Redo keeps exact pitch history "+str(size));city.set_house_roof_pitch("h1",null);check(city.houses==source.houses,"original restores exact author recipe "+str(size));cold.initialize_free();check(cold.restore(source).ok and Geo.for_house(cold,cold.houses[0]).patches.is_empty(),"reset does not reuse custom roof "+str(size))
	var city:=fixture();city.set_house_roof_pitch("h1",45.);var saved:Dictionary=city.snapshot();var cold:=State.new();cold.restore(saved)
	var invalid:Dictionary=saved.duplicate(true);invalid.schema=42;check(not cold.restore(invalid).ok and cold.snapshot()==saved,"schema42 rejects version8 atomically");invalid=saved.duplicate(true);invalid.houses[0].roof_pitch.profile="modern";check(not cold.restore(invalid).ok and cold.snapshot()==saved,"wrong profile rejects atomically")
	for old:Dictionary in [{"version":1,"degrees":78.},{"version":2,"profile":"round","degrees":78.},{"version":3,"profile":"modern","degrees":78.},{"version":4,"profile":"clockwork","degrees":78.},{"version":5,"profile":"renaissance","degrees":78.},{"version":6,"profile":"boathouse","degrees":78.},{"version":7,"profile":"acoustic_shell","degrees":78.}]:
		city=fixture();city.houses[0].roof_pitch=old;saved=city.snapshot();check(State.new().restore(saved).ok and not Pitch.active(city,city.houses[0]),"old recipe remains dormant on stoa "+str(old.version));check(city.set_house_roof_pitch("h1",15.).ok and city.undo().ok and city.houses==saved.houses,"explicit upgrade Undo restores old recipe "+str(old.version))
	for kind:String in ["partial","terrace","hinge"]:
		city=fixture(3,1);city.set_house_roof_pitch("h1",45.);saved=city.snapshot()
		if kind=="partial":city.add_cell("h1",0,0,1)
		elif kind=="terrace":city.add_cell("h1",-1,0,0,"terrace")
		else:city.houses[0].bend_angle_deg=15.;city.revision+=1
		check(not Pitch.supported(city,city.houses[0]) and not Pitch.active(city,city.houses[0]) and city.houses[0].roof_pitch==saved.houses[0].roof_pitch and Geo.for_house(city,city.houses[0]).patches.is_empty(),"unsupported shape keeps author recipe without fake roof "+kind)
	city=fixture(2,3,2);city.houses[0].base_y=1.2;city.revision+=1;check(city.rotate_house("h1",.35).ok and city.set_house_roof_pitch("h1",78.).ok,"rotated raised multilevel stoa remains editable");verify_render(city,"rotated raised")
	city=fixture();city.set_house_roof_pitch("h1",45.);var road:Dictionary=city.add_road([Vector2(-32,-20),Vector2(-24,-20)] as Array[Vector2],"path","none");check(road.ok and Pitch.supported(city,city.houses[0])==(not Plan.massing(city,city.houses[0]).is_empty()),"through-road follows existing stoa massing rule without new door gate")
	city=fixture();city.add_district([Vector2(-31,-20),Vector2(-24,-20)] as Array[Vector2],6.);city.set_house_era("h1","district");city.set_house_roof_pitch("h1",78.);check(Pitch.active(city,city.houses[0]) and not city.houses[0].has("era_theme"),"inherited pastoral stoa stays unpinned");city.set_district_era("d1","renaissance");check(not Pitch.active(city,city.houses[0]) and Geo.for_house(city,city.houses[0]).patches.is_empty() and city.houses[0].roof_pitch.version==8,"inherited era dormancy retains recipe");city.set_district_era("d1","pastoral");check(Pitch.active(city,city.houses[0]),"inherited pastoral return restores stoa")
	city=fixture();city.set_house_roof_pitch("h1",0.)
	for at:Vector2 in [Vector2(-33,-20),Vector2(-24.5,-20)]:city.add_house(at)
	for id:String in ["h2","h3"]:city.houses[city._house_index(id)].base_y=.2;city.set_house_era(id,"modern_eco");city.set_house_architecture(id,"chalet");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
	city.set_house_skybridge_span("h3",true);check(not Bridge.for_house(city,city.houses[1]).is_empty(),"real nine-metre bridge clears low stoa");city.set_house_roof_pitch("h1",78.);check(Bridge.for_house(city,city.houses[1]).is_empty(),"actual tall asymmetric roof withdraws real bridge");check(city.undo().ok and not Bridge.for_house(city,city.houses[1]).is_empty(),"Undo stoa roof restores real bridge")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"isolated validation preserves personal save")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"max_mesh_vertex_error":worst_error,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("STOA_ROOF_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
