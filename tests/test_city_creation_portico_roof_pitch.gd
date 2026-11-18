extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
const Geo=preload("res://scripts/world/city_creation_portico_roof_pitch.gd")
var checks:=0
var failures:Array=[]
var worst_error:=0.
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
static func fixture(width:int=2,depth:int=2,floors:int=1,kind:String="full")->RefCounted:
 var city:=State.new();city.initialize_free();Brush.select(city,"pastoral","portico");var cells:Array=[]
 for level in range(floors):
  for z in range(depth):
   for x in range(width):cells.append({"x":x,"z":z,"level":level,"kind":"room"})
 if kind=="half":
  for x in range(width):cells.append({"x":x,"z":0,"level":1,"kind":"room"});cells.append({"x":x,"z":1,"level":1,"kind":"terrace"})
 if kind=="terrace":cells.append({"x":0,"z":0,"level":floors,"kind":"terrace"})
 city.add_house_stroke(Vector2(-28,-20),cells);return city
func renderer(city)->Node3D:
 var r:=Renderer.new();root.add_child(r);r.state=city;r.buildings=Node3D.new();r.add_child(r.buildings)
 for node in [r.shore,r.lilypads,r.wildlife]:r.add_child(node)
 return r
func triangles_same(a:Array,b:Array)->bool:
 if a.size()!=b.size():return false
 var remaining:Array=b.duplicate()
 for i in range(0,a.size(),3):
  var found:=-1
  for j in range(0,remaining.size(),3):
   var ok:=true
   for k in range(3):
    var near:=false
    for q in range(3):near=near or Vector3(a[i+k]).distance_to(remaining[j+q])<.00015
    ok=ok and near
   if ok:found=j;break
  if found<0:return false
  for k in range(3):remaining.remove_at(found)
 return true
func fixed(node:Node3D)->Array:
 var rows:Array=[]
 for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
  if not str(mesh.name).begins_with("Doric") and not str(mesh.name) in ["GreekSharedEntablature","VillaContinuousEntablature"]:continue
  rows.append(var_to_bytes([mesh.mesh.surface_get_arrays(0),node.global_transform.affine_inverse()*mesh.global_transform]).hex_encode())
 rows.sort();return rows
func verify_render(city,label:String)->Array:
 var r:=renderer(city);var shell:Node3D=r._house(city.houses[0]);var data:=Geo.for_house(city,city.houses[0]);var expected:Array=[];var physics:Array=[];var gpu:Array=[];var families:Dictionary={};var valid:=true;var metric:=true;var cornices:=true
 for patch:Dictionary in data.patches:
  expected.append_array(patch.vertices);families[str(patch.get("part",""))]=true
  if patch.roof_skin and patch.has("uv") and (data.kind=="temple" or patch.category!="main"):
   for i in range(0,patch.vertices.size(),3):
    for pair:Vector2i in [Vector2i(0,1),Vector2i(1,2),Vector2i(2,0)]:
     var delta:Vector3=patch.vertices[i+pair.x]-patch.vertices[i+pair.y];var uv_delta:Vector2=patch.uv[i+pair.x]-patch.uv[i+pair.y]
     if absf(delta.z)<.00001 and absf(delta.x)>.0001:metric=metric and absf(absf(uv_delta.y)*.28-delta.length())<.0002
  if "Cornice" in str(patch.part):
   for i in range(0,patch.vertices.size(),3):
    for pair:Vector2i in [Vector2i(0,1),Vector2i(1,2),Vector2i(2,0)]:
     var delta:Vector3=patch.vertices[i+pair.x]-patch.vertices[i+pair.y]
     if delta.length()>.3 and absf(delta.z)<.001 and absf(delta.x)>.2:
      var midpoint:Vector3=(patch.vertices[i+pair.x]+patch.vertices[i+pair.y])*.5;var plan:Dictionary=Geo.ground(city.houses[0]);var slope:float=tan(deg_to_rad(float(city.houses[0].roof_pitch.degrees)));var expected_slope:float=-signf(midpoint.x-float(plan.center.x))*slope;cornices=cornices and absf(delta.y-expected_slope*delta.x)*cos(deg_to_rad(float(city.houses[0].roof_pitch.degrees)))<.066
  for p:Vector3 in patch.vertices:valid=valid and p.is_finite()
 for body:StaticBody3D in shell.find_children("*","StaticBody3D",true,false):
  if not str(body.name).begins_with("Portico"):continue
  for shape:CollisionShape3D in body.get_children():
   var pose:=shell.global_transform.affine_inverse()*shape.global_transform
   for p:Vector3 in shape.shape.get_faces():physics.append(pose*p)
 for mesh:MeshInstance3D in shell.find_children("*","MeshInstance3D",true,false):
  if not str(mesh.name).begins_with("Portico"):continue
  var pose:=shell.global_transform.affine_inverse()*mesh.global_transform
  for p:Vector3 in mesh.mesh.get_faces():gpu.append(pose*p)
 check(metric,"roof UV measures actual slope length "+label);check(cornices,"long raking cornice edges follow actual roof pitch "+label)
 var eave:=INF;var bottom:=INF;var base:float=city.houses[0].get("base_y",0.);var category:="main" if data.kind=="temple" else "porch" if data.kind=="villa" else "entry";var beam_top:=1.760 if data.kind=="temple" else 1.655 if data.kind=="villa" else 1.445
 for patch:Dictionary in data.patches:
  if patch.category!=category:continue
  if patch.roof_skin:
   for point:Vector3 in patch.vertices:eave=minf(eave,point.y-base)
  if "Closure" in str(patch.part) or "Pediment" in str(patch.part):
   for point:Vector3 in patch.vertices:bottom=minf(bottom,point.y-base)
 if data.kind!="villa":check(absf((eave-.045)-beam_top-.001)<.00001,"actual CPU thick roof underside has 1mm beam clearance "+label)
 else:check(absf(bottom-beam_top)<.00001 and absf(eave-.045-1.714-.001)<.00001,"actual porch closure bridges beam to 1mm thick roof gap "+label)
 check(not expected.is_empty() and valid,"finite complete authored roof model "+label)
 check(triangles_same(expected,physics),"actual collision triangles equal complete CPU roof and closures "+label)
 check(triangles_same(expected,gpu),"actual GPU triangles equal complete CPU roof and closures "+label)
 check(shell.has_meta("portico_roof_pitch"),"actual portico handle metadata exists "+label)
 check(Pitch.patches(city,city.houses[0])==data.patches,"clearance consumes complete read only roof model "+label)
 var lower:=fixed(shell);shell.free();r.free();return lower
func worker(saved:Dictionary)->Dictionary:
 var city:=State.new();var reply:Dictionary=city.restore(saved)
 return {"ok":reply.ok,"data":Geo.for_house(city,city.houses[0])} if reply.ok else reply
func run()->void:
 var out:=""
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
 if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 for spec:Array in [[1,1,1,"full"],[2,2,1,"full"],[2,2,2,"full"],[2,2,1,"half"],[1,1,1,"terrace"]]:
  var city:=fixture(spec[0],spec[1],spec[2],spec[3]);var source:Dictionary=city.snapshot();var history:int=city._undo.size();var lower:Array=[];check(Pitch.supported(city,city.houses[0]),"real complete/stacked/half-court/terrace supported "+str(spec))
  for angle:float in [0.,15.,45.,78.]:
   var reply:Dictionary=city.set_house_roof_pitch("h1",angle);var saved:Dictionary=city.snapshot();var label:=str(spec)+" "+str(angle)
   check(reply.ok and saved.schema==45 and city.houses[0].roof_pitch=={"version":10,"profile":"portico","degrees":angle} and city.houses[0].cells==source.houses[0].cells and city.houses[0].seed==source.houses[0].seed,"schema45 retains exact rooms terraces seed "+label)
   if not reply.ok:continue
   var current:=verify_render(city,label)
   if lower.is_empty():lower=current
   else:check(current==lower,"fixed real columns and entablature retain exact buffers and poses "+label)
   var thread:=Thread.new();var error:=thread.start(worker.bind(saved));var cold:Dictionary=thread.wait_to_finish() if error==OK else {};check(error==OK and cold.get("ok",false) and cold.data==Geo.for_house(city,city.houses[0]) and city.snapshot()==saved,"real Thread cold geometry exact and author snapshot pure "+label)
  var cold:=State.new();var filename:=out+"/city_"+str(checks)+".json";check(city.save_city(filename).ok and cold.load_city(filename).ok and cold.houses==city.houses,"atomic disk roundtrip "+str(spec));check(city._undo.size()==history+4 and city.undo().ok and city.houses[0].roof_pitch.degrees==45. and city.redo().ok and city.houses[0].roof_pitch.degrees==78.,"one transaction per angle Undo Redo "+str(spec));city.set_house_roof_pitch("h1",null);check(city.houses==source.houses,"original restores exact original author recipe "+str(spec))
 var city:=fixture();city.set_house_roof_pitch("h1",45.);var saved:Dictionary=city.snapshot();var cold:=State.new();cold.restore(saved);var invalid:Dictionary=saved.duplicate(true);invalid.schema=44;check(not cold.restore(invalid).ok and cold.snapshot()==saved,"schema44 rejects v10 atomically");invalid=saved.duplicate(true);invalid.houses[0].roof_pitch.profile="ionic_stoa";check(not cold.restore(invalid).ok and cold.snapshot()==saved,"wrong profile rejects atomically")
 for old:Dictionary in [{"version":1,"degrees":78.},{"version":8,"profile":"ionic_stoa","degrees":78.},{"version":9,"profile":"roman_basilica","degrees":78.}]:
  city=fixture();city.houses[0].roof_pitch=old;saved=city.snapshot();check(State.new().restore(saved).ok and not Pitch.active(city,city.houses[0]),"old recipe stays dormant "+str(old.version));check(city.set_house_roof_pitch("h1",15.).ok and city.undo().ok and city.houses==saved.houses,"explicit upgrade Undo restores old recipe "+str(old.version))
 city=fixture(2,2,2);city.houses[0].base_y=1.2;city.revision+=1;check(city.rotate_house("h1",.35).ok and city.set_house_roof_pitch("h1",78.).ok,"rotated raised multilevel remains editable");verify_render(city,"rotated raised")
 city=fixture(2,1,2);city.set_house_roof_pitch("h1",45.);saved=city.snapshot();city.houses[0].bend_angle_deg=15.;city.revision+=1
 var r:=renderer(city);var shell:Node3D=r._house(city.houses[0]);check(not Pitch.active(city,city.houses[0]) and not shell.has_meta("portico_roof_pitch") and (not shell.find_children("AncientLowTileRoof*","MeshInstance3D",true,false).is_empty() or not shell.find_children("GreekContinuousTileRoof*","MeshInstance3D",true,false).is_empty()),"folded dormancy retains actual old derived roofs");check(not Pitch.patches(city,city.houses[0]).is_empty(),"folded dormant roof still participates in clearance");shell.free();r.free();city.houses[0].erase("bend_angle_deg");city.revision+=1;check(Pitch.active(city,city.houses[0]),"return from fold restores v10 roof");verify_render(city,"fold return")
 city=fixture(2,1,2);city.add_district([Vector2(-31,-20),Vector2(-24,-20)] as Array[Vector2],6.);city.set_house_era("h1","district");city.set_house_roof_pitch("h1",78.);check(Pitch.active(city,city.houses[0]) and not city.houses[0].has("era_theme"),"inherited pastoral active without pinning era");city.set_district_era("d1","renaissance");check(not Pitch.active(city,city.houses[0]) and city.houses[0].roof_pitch.version==10,"inherited nonpastoral era retains dormant recipe")
 var ctx:=Geo.Context.new();ctx.prepare(city.houses,city.roads,city);var ordinary:=State.new();ordinary.restore(city.snapshot());ordinary.houses[0].erase("roof_pitch");var old_ctx:=Geo.Context.new();old_ctx.prepare(ordinary.houses,ordinary.roads,ordinary);check(ctx.roof_patches("h1")==old_ctx.roof_patches("h1"),"inherited nonpastoral Context roof equals actual original geometry");city.set_district_era("d1","pastoral");check(Pitch.active(city,city.houses[0]),"inherited pastoral return restores exact v10 recipe");verify_render(city,"era return")
 check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"isolated validation preserves personal save")
 var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("PORTICO_ROOF_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
