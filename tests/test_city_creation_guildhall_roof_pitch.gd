extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
const Plan=preload("res://scripts/world/city_creation_neoclassical_civic_plan.gd")
const Geo=preload("res://scripts/world/city_creation_guildhall_roof_pitch.gd")
var checks:=0
var failures:Array=[]
var worst_error:=0.
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
static func fixture(length:int=3,axis:String="x",role:String="venue")->RefCounted:
 var city:=State.new();city.initialize_free();Brush.select(city,"renaissance","guildhall");var cells:Array=[]
 for i in range(length):cells.append({"x":i if axis=="x" else 0,"z":i if axis=="z" else 0,"level":0,"kind":"room"})
 city.add_house_stroke(Vector2(-28,-20),cells);city.set_house_role("h1",role);city.set_house_era("h1","renaissance");city.set_house_architecture("h1","guildhall");return city
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
  if str(mesh.name).begins_with("GuildPitch"):continue
  rows.append(var_to_bytes([mesh.mesh.surface_get_arrays(0),node.global_transform.affine_inverse()*mesh.global_transform]).hex_encode())
 rows.sort();return rows
func verify_render(city,label:String)->Array:
 var r:=renderer(city);var shell:Node3D=r._house(city.houses[0]);var data:=Geo.for_house(city,city.houses[0]);var expected:Array=[];var physics:Array=[];var gpu:Array=[];var families:Dictionary={};var valid:=true;var metric:=true;var nave:=false;var wing:=false;var porch:=false
 for patch:Dictionary in data.patches:
  expected.append_array(patch.vertices);families[str(patch.get("part",""))]=true
  nave=nave or str(patch.part)=="GuildPitchNaveTileRoof";wing=wing or str(patch.part)=="GuildPitchWingTileRoof";porch=porch or str(patch.part)=="GuildPitchPorchTileRoof"
  if patch.roof_skin:
   for i in range(0,patch.vertices.size(),3):
    for pair:Vector2i in [Vector2i(0,1),Vector2i(1,2),Vector2i(2,0)]:
     var delta:Vector3=data.pose.basis.inverse()*(patch.vertices[i+pair.x]-patch.vertices[i+pair.y]);var uv_delta:Vector2=patch.uv[i+pair.x]-patch.uv[i+pair.y]
     if absf(delta.z)<.00001 and absf(delta.x)>.0001:metric=metric and absf(absf(uv_delta.y)*.28-delta.length())<.0002
  for p:Vector3 in patch.vertices:valid=valid and p.is_finite()
 for body:StaticBody3D in shell.find_child("GuildPitchRoofs",true,false).find_children("*","StaticBody3D",true,false):
  for shape:CollisionShape3D in body.get_children():
   var pose:=shell.global_transform.affine_inverse()*shape.global_transform
   for p:Vector3 in shape.shape.get_faces():physics.append(pose*p)
 for mesh:MeshInstance3D in shell.find_children("*","MeshInstance3D",true,false):
  if not str(mesh.name).begins_with("GuildPitch"):continue
  var pose:=shell.global_transform.affine_inverse()*mesh.global_transform
  for p:Vector3 in mesh.mesh.get_faces():gpu.append(pose*p)
 var span:float=data.plan.span;var middle:=minf(1.65,span*.55);var slope:=tan(deg_to_rad(float(city.houses[0].roof_pitch.degrees)));var wall_closed:=true;var wing_closed:=true
 for side:float in [-1.,1.]:
  var samples:Array=[[Vector3(side*span*.5+side*.12,.03,.23),Vector3(side*span*.5-side*.12,.03,.23),"wing"]]
  if slope>.01:samples.append([Vector3(side*middle*.5+side*.1,.510+.11*slope*.5,.23),Vector3(side*middle*.5-side*.1,.510+.11*slope*.5,.23),"nave"])
  for sample:Array in samples:
   var a:Vector3=data.pose*sample[0];var b:Vector3=data.pose*sample[1];var found:=false
   for patch:Dictionary in data.patches:
    for i in range(0,patch.vertices.size(),3):found=found or Geometry3D.segment_intersects_triangle(a,b,patch.vertices[i],patch.vertices[i+1],patch.vertices[i+2])!=null
   if sample[2]=="wing":wing_closed=wing_closed and found
   else:wall_closed=wall_closed and found
 check(wing_closed,"CPU real transverse segment meets outer wing closure above wall "+label);check(wall_closed,"CPU real transverse segment meets raised nave long side closure "+label)
 check(nave and wing and porch,"all nave twin wing and high porch roof families published "+label);check(metric,"actual roof metric UV measures slope length "+label)
 check(not expected.is_empty() and valid,"finite complete authored three roofs and high porch "+label)
 check(triangles_same(expected,physics),"actual collision triangles equal complete CPU roofs and closures "+label)
 check(triangles_same(expected,gpu),"actual GPU triangles equal complete CPU roofs and closures "+label)
 check(shell.has_meta("guildhall_roof_pitch"),"actual guildhall handle metadata exists "+label)
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
 for spec:Array in [[1,"x","venue"],[3,"x","bakery"],[3,"z","garden_cafe"],[5,"x","venue"]]:
  var city:=fixture(spec[0],spec[1],spec[2]);var source:Dictionary=city.snapshot();var history:int=city._undo.size();var lower:Array=[];check(Pitch.supported(city,city.houses[0]),"real isolated linear public guildhall qualifies "+str(spec))
  for angle:float in [0.,15.,45.,78.]:
   var reply:Dictionary=city.set_house_roof_pitch("h1",angle);var saved:Dictionary=city.snapshot();var label:=str(spec)+" "+str(angle)
   check(reply.ok and saved.schema==46 and city.houses[0].roof_pitch=={"version":11,"profile":"guildhall","degrees":angle} and city.houses[0].cells==source.houses[0].cells and city.houses[0].seed==source.houses[0].seed,"schema46 retains exact rooms and seed "+label)
   if not reply.ok:continue
   var current:=verify_render(city,label)
   if lower.is_empty():lower=current
   else:check(current==lower,"fixed original lower hall and columns retain exact buffers and poses "+label)
   var thread:=Thread.new();var error:=thread.start(worker.bind(saved));var cold:Dictionary=thread.wait_to_finish() if error==OK else {};check(error==OK and cold.get("ok",false) and cold.data==Geo.for_house(city,city.houses[0]) and city.snapshot()==saved,"real Thread cold geometry exact and author snapshot pure "+label)
  var cold:=State.new();var filename:=out+"/city_"+str(checks)+".json";check(city.save_city(filename).ok and cold.load_city(filename).ok and cold.houses==city.houses,"atomic disk roundtrip "+str(spec));check(city._undo.size()==history+4 and city.undo().ok and city.houses[0].roof_pitch.degrees==45. and city.redo().ok and city.houses[0].roof_pitch.degrees==78.,"one transaction per angle Undo Redo "+str(spec));city.set_house_roof_pitch("h1",null);check(city.houses==source.houses,"original restores exact original author recipe "+str(spec))
 var city:=fixture();city.set_house_roof_pitch("h1",45.);var saved:Dictionary=city.snapshot();var cold:=State.new();cold.restore(saved);var invalid:Dictionary=saved.duplicate(true);invalid.schema=45;check(not cold.restore(invalid).ok and cold.snapshot()==saved,"schema45 rejects v11 atomically");invalid=saved.duplicate(true);invalid.houses[0].roof_pitch.profile="portico";check(not cold.restore(invalid).ok and cold.snapshot()==saved,"wrong profile rejects atomically")
 for kind:String in ["upper","terrace","square","role","era","neighbor"]:
  city=fixture();city.set_house_roof_pitch("h1",45.);saved=city.snapshot()
  if kind=="upper":city.add_cell("h1",0,0,1)
  elif kind=="terrace":city.add_cell("h1",0,0,1,"terrace")
  elif kind=="square":city.add_cell("h1",0,1,0)
  elif kind=="role":city.set_house_role("h1","residential")
  elif kind=="era":city.set_house_era("h1","pastoral")
  else:city.add_house(Vector2(-28,-18.2))
  check(not Pitch.active(city,city.houses[0]) and city.houses[0].roof_pitch==saved.houses[0].roof_pitch,"real invalid shape role or era leaves recipe dormant "+kind)
  var r:=renderer(city);var node:Node3D=r._house(city.houses[0]);check(not node.has_meta("guildhall_roof_pitch"),"unsupported case does not publish fake guildhall roof "+kind);node.free();r.free()
 city=fixture(3,"z");city.houses[0].base_y=1.2;city.revision+=1;check(city.rotate_house("h1",.35).ok and city.set_house_roof_pitch("h1",78.).ok,"rotated raised longitudinal hall remains editable");verify_render(city,"rotated raised")
 city=fixture();city.add_district([Vector2(-31,-20),Vector2(-24,-20)] as Array[Vector2],6.);city.set_district_era("d1","renaissance");city.set_house_era("h1","district");city.set_house_roof_pitch("h1",78.);check(Pitch.active(city,city.houses[0]) and not city.houses[0].has("era_theme"),"inherited renaissance hall stays unpinned");city.set_district_era("d1","pastoral");check(not Pitch.active(city,city.houses[0]) and city.houses[0].roof_pitch.version==11,"pastoral era preserves dormant v11 without fake guildhall shell");city.set_district_era("d1","renaissance");check(Pitch.active(city,city.houses[0]),"return of inherited era restores authored hall");verify_render(city,"inherited era return")
 check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"isolated validation preserves personal save")
 var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("GUILDHALL_ROOF_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
