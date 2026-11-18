extends "res://tools/check_creation_renaissance_roof_pitch_live.gd"
const GuildFixture=preload("res://tests/test_city_creation_guildhall_roof_pitch.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
var pending_isolated:=true
var original_doors:Array=[]
func appearance(renderer)->Array:
 var result:Array=[];var house:Node3D=renderer.house_roots.h1
 for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
  if mesh.name in ["ResonanceVisualRig","ResonanceArc"]:continue
  var at:Node=mesh.get_parent();var pose:Transform3D=mesh.transform
  while at!=house:
   var frame:Transform3D=at.transform
   if at.name=="ResonanceVisualPivot":frame.basis=Basis.IDENTITY
   pose=frame*pose;at=at.get_parent()
  # Cancelled pivot translations leave 2um float residue in a rotated hall.
  # Geometry, GPU attribute bytes and material values remain exact comparisons.
  pose.origin=pose.origin.snapped(Vector3.ONE*.0001)
  for i in range(mesh.mesh.get_surface_count()):result.append(hash([mesh.mesh.surface_get_arrays(i),RenderingServer.mesh_get_surface(mesh.mesh.get_rid(),i).get("attribute_data",PackedByteArray()),pose,material_key(mesh.material_override)]))
 result.sort();return result
static func fixture(length:int=3,axis:String="x",role:String="venue")->RefCounted:return GuildFixture.fixture(length,axis,role)
func preview_ready(angle:float)->bool:
 if control.pending!=null and control.pending.renderer!=null:
  for body:CollisionObject3D in control.pending.renderer.find_children("*","CollisionObject3D",true,false):pending_isolated=pending_isolated and body.collision_layer==0 and body.collision_mask==0
 return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-angle)<.2
func guildhall_focus()->void:
 var h:Dictionary=demo.state.houses[0];var center:=Vector2(h.origin[0],h.origin[1]);demo.focus=Vector3(center.x+1.,3.,center.y+1.);demo.zoom=20.;demo.pitch=.7;demo.yaw=.55;demo._update_camera()
func physical_faces(renderer)->Array:
 var faces:Array=[];var house:Node3D=renderer.house_roots.h1;var inverse:=house.global_transform.affine_inverse()
 for body:StaticBody3D in house.find_child("GuildPitchRoofs",true,false).find_children("*","StaticBody3D",true,false):
  for shape:CollisionShape3D in body.get_children():
   for p:Vector3 in shape.shape.get_faces():faces.append(inverse*shape.global_transform*p)
 return faces
func verify_guildhall(label:String)->void:
 var h:Dictionary=demo.state.houses[0];var data:=GuildFixture.Geo.for_house(demo.state,h);var points:Array=[]
 for patch:Dictionary in data.patches:points.append_array(patch.vertices)
 check(same_triangles(physical_faces(demo.town),points),"complete main and projecting porch roof collision equals CPU "+label)
 var space:PhysicsDirectSpaceState3D=demo.get_world_3d().direct_space_state;var world:=Pitch.Frame.world3(h,demo.town.house_roots.h1.get_meta("guildhall_roof_pitch").apex);var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.06,world-Vector3.UP*.06))
 check(not hit.is_empty() and hit.collider.get_meta("roof_surface",false) and absf(hit.position.y-world.y)<.001,"handle anchors actual pitched tile surface "+label)
 verify_seams(h,data,label);verify_end_cells(h,data,label)
 var doors:=door_rays();facts["doors_"+label]=doors;check(doors==original_doors,"roof preserves original actual entrance ray occupancy "+label)
func verify_seams(h:Dictionary,data:Dictionary,label:String)->void:
 var p:Dictionary=data.plan;var middle:=minf(1.65,float(p.span)*.55);var slope:=tan(deg_to_rad(float(h.roof_pitch.degrees)));var space:PhysicsDirectSpaceState3D=demo.get_world_3d().direct_space_state
 if slope>.01:
  for side:float in [-1.,1.]:
   var x:=side*middle*.5;var y:=.510+.11*slope*.5;var start:=Pitch.Frame.world3(h,data.pose*Vector3(x+side*.10,y,.23));var end:=Pitch.Frame.world3(h,data.pose*Vector3(x-side*.10,y,.23));var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(start,end));check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1","real transverse Jolt ray meets closed nave long side "+str(side)+label)
 for side:float in [-1.,1.]:
  var x:=side*float(p.span)*.5;var start:=Pitch.Frame.world3(h,data.pose*Vector3(x+side*.12,.03,.23));var end:=Pitch.Frame.world3(h,data.pose*Vector3(x-side*.12,.03,.23));var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(start,end));check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1","real transverse Jolt ray meets closed outer wing long side "+str(side)+label)
 for side:float in [-1.,1.]:
  var start:=Pitch.Frame.world3(h,data.pose*Vector3(.2,.53,side*1.06));var end:=Pitch.Frame.world3(h,data.pose*Vector3(.2,.53,side*.84));var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(start,end));check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1","real Jolt ray meets nave end closure "+str(side)+label)
func verify_end_cells(h:Dictionary,data:Dictionary,label:String)->void:
 if h.cells.size()<5:return
 for owner:Dictionary in [h.cells[0],h.cells[-1]]:
  var found:=false
  for patch:Dictionary in data.patches:
   if not patch.roof_skin or str(patch.cell_id)!=str(owner.id):continue
   for i in range(0,patch.vertices.size(),3):
    var local:Vector3=(patch.vertices[i]+patch.vertices[i+1]+patch.vertices[i+2])/3.;var at:Vector3=Pitch.Frame.world3(h,local);var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.03,at-Vector3.UP*.03))
    if hit.is_empty() or not hit.collider.get_meta("roof_surface",false):continue
    var resolved:Dictionary=preload("res://scripts/ui/city_creation_unified_build.gd").resolve(demo.state,hit,Vector2(at.x,at.z));found=hit.collider.get_meta("cell_id","")==str(owner.id) and resolved.has("cell") and resolved.cell.x==owner.x and resolved.cell.z==owner.z and resolved.cell.level==1 and resolved.valid
    if found:break
   if found:break
  check(found,"actual far end roof ray and unified upper-room resolve exact source cell "+str(owner.id)+label)
func door_rays()->Array:
 var h:Dictionary=demo.state.houses[0];var space:PhysicsDirectSpaceState3D=demo.get_world_3d().direct_space_state;var result:Array=[]
 for entry:Dictionary in demo.state.house_entrances("h1"):
  var wall:=Vector3(entry.wall_at.x,float(h.get("base_y",0.))+.65,entry.wall_at.y);var normal:=Vector3(entry.outward.x,0,entry.outward.y);var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(wall+normal*.4,wall-normal*.2));result.append(not hit.is_empty())
 return result
func verify_original_anchor(label:String)->void:
 var h:Dictionary=demo.state.houses[0];var apex:Vector3=demo.town.house_roots.h1.get_meta("guildhall_original_anchor",Vector3.ZERO);var world:=Pitch.Frame.world3(h,apex);var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.06,world-Vector3.UP*.06));facts["original_anchor_"+label]={"house":h.duplicate(true),"root_meta":demo.town.house_roots.h1.get_meta_list(),"apex":apex,"roof_names":demo.town.house_roots.h1.find_children("*Roof*","MeshInstance3D",true,false).map(func(n):return str(n.name)),"world":world,"hit":str(hit),"error":absf(hit.position.y-world.y) if not hit.is_empty() else -1.};check(apex!=Vector3.ZERO and not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1" and absf(hit.position.y-world.y)<.001,"original handle anchors actual old tile triangle "+label)
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));facts.source_sha256={}
 for source:String in ["res://scripts/visual/city_creation_guildhall_roof_pitch.gd","res://scripts/visual/city_creation_neoclassical_civic.gd","res://scripts/ui/city_creation_roof_pitch_control.gd","res://scripts/world/city_creation_roof_pitch_geometry.gd","res://tools/check_creation_guildhall_roof_pitch_live.gd"]:facts.source_sha256[source]=FileAccess.get_file_as_string(source).sha256_text()
 root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec()
 var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control")
 if "--guildhall-bridge-only" in OS.get_cmdline_user_args():await guildhall_bridge();await modern_report(personal);return
 if "--extras-only" in OS.get_cmdline_user_args():await extras();await modern_report(personal);return
 await show(fixture(),Vector2(-26,-20),"文艺公馆三盖与高门廊调坡");guildhall_focus();await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);var original:Dictionary=demo.state.snapshot();var old_gpu:=appearance(demo.town);original_doors=door_rays();facts.original_door_occupancy=original_doors;
 await open_editor();check(control.slider.editable and control.handle.visible,"native original guildhall controls remain reachable");verify_original_anchor("temple")
 for angle:float in [0.,45.,78.]:
  await open_editor();var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();await drag_slider(angle,false);check(await wait_for(func():return preview_ready(angle),18000),"full detached guildhall roof preview ready "+str(angle))
  if control.current==null:await modern_report(personal);return
  var expected:=appearance(control.current.renderer);check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"held roof preview keeps author and history pure "+str(angle));await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
  check(demo.state.snapshot().schema==46 and demo.state.houses[0].roof_pitch=={"version":11,"profile":"guildhall","degrees":angle} and demo.state._undo.size()==depth+1 and demo.state.houses[0].cells==original.houses[0].cells,"one native schema46 transaction retains all rooms "+str(angle));check(appearance(demo.town)==expected,"candidate and published GPU materials match and fixed colonnade stays "+str(angle));verify_guildhall(str(angle));await capture("guildhall_"+str(int(angle)))
  if angle==0.:
   var archived:Dictionary=demo.gallery.library.read(str(control.backup.get("id","")));var old:=State.new();check(archived.get("ok",false) and old.restore(archived.world).ok and old.houses==before.houses,"first schema46 edit archives exact original city")
  var cold:=State.new();var file:=OUT+"/cold_"+str(int(angle))+".json";check(demo.state.save_city(file).ok and cold.load_city(file).ok and cold.houses==demo.state.houses,"schema46 atomic disk cold read "+str(angle));var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
  while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
  check(preview.ready and appearance(preview.renderer)==appearance(demo.town),"independent cold GPU materials match "+str(angle));preview.clear();await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"native Undo restores exact prior guildhall roof "+str(angle));await key(KEY_Y,true);await settle();quiet()
 await roof_click();await open_editor();var before:Dictionary=demo.state.snapshot();await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);await key(KEY_ESCAPE);await release_slider();check(control.current==null and demo.state.snapshot()==before,"Esc cancels guildhall roof preview");await open_editor();await ui_click(control.reset);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);check(demo.state.houses==original.houses and appearance(demo.town)==old_gpu,"original button restores exact guildhall GPU materials and author data")
 await extras();root.size=Vector2i(1024,768);await settle();await open_editor();check(root.get_visible_rect().encloses(control.slider.get_global_rect()) and root.get_visible_rect().encloses(control.handle.get_global_rect()),"existing controls fit 1024 viewport");await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);var empty:=State.new();empty.initialize_free();await show(empty,Vector2(-28,-20),"长馆过期预演撤回");await settle();quiet();check(control.current==null and control.pending==null and demo.state.houses.is_empty(),"city change withdraws stale roof and picking");check(pending_isolated,"pending guildhall geometry never publishes collisions");facts.elapsed_seconds=(Time.get_ticks_msec()-began)/1000.;await modern_report(personal)
func roof_click()->void:
 demo.spatial_popover.close();demo.select_tool(0);guildhall_focus();await settle();quiet();var h:Dictionary=demo.state.houses[0];var at:=Vector2.ZERO;var hit:Dictionary={}
 for patch:Dictionary in GuildFixture.Geo.for_house(demo.state,h).patches:
  if not patch.roof_skin:continue
  for i in range(0,patch.vertices.size(),3):
   var p:=Pitch.Frame.world3(h,(patch.vertices[i]+patch.vertices[i+1]+patch.vertices[i+2])/3.);var pixel:Vector2=demo.camera.unproject_position(p);var sample:Dictionary=demo._ray_hit(pixel)
   if root.get_visible_rect().has_point(pixel) and not sample.is_empty() and sample.collider.get_meta("roof_surface",false):at=pixel;hit=sample;break
  if not hit.is_empty():break
 var resolved:Dictionary=preload("res://scripts/ui/city_creation_unified_build.gd").resolve(demo.state,hit,Vector2(-26,-20));check(not hit.is_empty() and resolved.has("cell") and resolved.cell.level==1 and resolved.cell.kind=="room" and resolved.valid,"steep tile resolves original highest room upper floor");var before:Dictionary=demo.state.snapshot();await pointer(at);await send(at,true);await send(at,false);await settle();quiet();check(demo.state.houses[0].cells.size()==before.houses[0].cells.size()+1 and demo.state.houses[0].cells[-1].level==1 and demo.state.houses[0].roof_pitch==before.houses[0].roof_pitch,"native steep guildhall roof click adds real upper room and retains pitch");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and demo.town.house_roots.h1.has_meta("guildhall_roof_pitch"),"native Undo restores complete pitched guildhall")
func extras()->void:
 for spec:Array in [[1,"x","venue"],[3,"z","garden_cafe"],[5,"x","bakery"]]:
  var city:=fixture(spec[0],spec[1],spec[2]);city.houses[0].base_y=1.;city.rotate_house("h1",.35);await settle();quiet();await wait_for(func():return not demo.edit_pending() and not demo.gallery.busy,18000);await show(city,Vector2(-27,-19),"文艺公馆原型"+str(spec));check(demo.state.houses==city.houses,"actual next fixture loads exact original rooms "+str(spec));guildhall_focus();await settle();quiet();original_doors=door_rays();await open_editor();verify_original_anchor(str(spec))
  for angle:float in [0.,78.]:
   demo._after_edit(demo.state.set_house_roof_pitch("h1",angle),"pitch");await settle();quiet();verify_guildhall(str(spec)+str(angle));await capture("guildhall_case_"+str(spec[0])+str(spec[1])+"_"+str(int(angle)));await open_editor();check(control.slider.editable and control.handle.visible,"rotated raised public linear hall keeps controls "+str(spec))
 demo._after_edit(demo.state.set_house_colors("h1",Color("99b3c2"),Color("db946d")),"colors");await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);var hot:=appearance(demo.town);var cold:=State.new();cold.restore(demo.state.snapshot());var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
 while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
 facts.hot_colors=color_rows(demo.town);facts.cold_colors=color_rows(preview.renderer)
 check(preview.ready and appearance(preview.renderer)==hot,"hot custom tile colors equal independent cold GPU materials");preview.clear()
func color_rows(renderer)->Array:
 var rows:Array=[]
 for mesh:MeshInstance3D in renderer.house_roots.h1.find_children("*","MeshInstance3D",true,false):
  var at:Node=mesh.get_parent();var pose:Transform3D=mesh.transform
  while at!=renderer.house_roots.h1:
   var frame:Transform3D=at.transform
   if at.name=="ResonanceVisualPivot":frame.basis=Basis.IDENTITY
   pose=frame*pose;at=at.get_parent()
  for i in range(mesh.mesh.get_surface_count()):rows.append({"name":str(mesh.name),"pose":str(pose),"pose_hash":hash(pose),"arrays":hash(mesh.mesh.surface_get_arrays(i)),"gpu":hash(RenderingServer.mesh_get_surface(mesh.mesh.get_rid(),i).get("attribute_data",PackedByteArray())),"material":str(material_key(mesh.material_override))})
 return rows
func guildhall_bridge()->void:
 var city:=fixture(1,"x","venue");city.set_house_roof_pitch("h1",0.)
 for at:Vector2 in [Vector2(-33,-20),Vector2(-24.5,-20)]:city.add_house(at)
 for id:String in ["h2","h3"]:city.houses[city._house_index(id)].base_y=.2;city.set_house_era(id,"modern_eco");city.set_house_architecture(id,"chalet");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
 city.set_house_skybridge_span("h3",true);await show(city,Vector2(-28,-20),"长馆与真实九米云廊");await settle();quiet();var before:Dictionary=demo.state.snapshot();check(not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"real cloud bridge clears flat guildhall roof");await open_editor();await drag_slider(78.,false);check(await wait_for(func():return preview_ready(78.),18000),"guildhall preview prepares affected bridge roots")
 if control.current==null:return
 check(control.current.ids.has("h2") and control.current.renderer.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.snapshot()==before,"pure guildhall preview retracts actual obstructed bridge");await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();check(demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.houses[2].skybridge_span==before.houses[2].skybridge_span,"published guildhall roof retracts bridge preserving span choice");await capture("guildhall_blocks_cloud_bridge");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"native Undo restores flat guildhall roof and actual bridge")

