extends "res://tools/check_creation_renaissance_roof_pitch_live.gd"
const PorticoFixture=preload("res://tests/test_city_creation_portico_roof_pitch.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
var pending_isolated:=true
var original_doors:Array=[]
static func fixture(width:int=2,depth:int=2,floors:int=1,kind:String="full")->RefCounted:return PorticoFixture.fixture(width,depth,floors,kind)
func preview_ready(angle:float)->bool:
 if control.pending!=null and control.pending.renderer!=null:
  for body:CollisionObject3D in control.pending.renderer.find_children("*","CollisionObject3D",true,false):pending_isolated=pending_isolated and body.collision_layer==0 and body.collision_mask==0
 return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-angle)<.2
func portico_focus()->void:
 var h:Dictionary=demo.state.houses[0];var center:=Vector2(h.origin[0],h.origin[1]);demo.focus=Vector3(center.x+1.,3.,center.y+1.);demo.zoom=20.;demo.pitch=.7;demo.yaw=.55;demo._update_camera()
func physical_faces(renderer)->Array:
 var faces:Array=[];var house:Node3D=renderer.house_roots.h1;var inverse:=house.global_transform.affine_inverse()
 for body:StaticBody3D in house.find_children("*","StaticBody3D",true,false):
  if not str(body.name).begins_with("PorticoRoofPick") and not str(body.name).begins_with("PorticoGablePick"):continue
  for shape:CollisionShape3D in body.get_children():
   for p:Vector3 in shape.shape.get_faces():faces.append(inverse*shape.global_transform*p)
 return faces
func verify_portico(label:String)->void:
 var h:Dictionary=demo.state.houses[0];var data:=PorticoFixture.Geo.for_house(demo.state,h);var points:Array=[]
 for patch:Dictionary in data.patches:points.append_array(patch.vertices)
 check(same_triangles(physical_faces(demo.town),points),"complete main and projecting porch roof collision equals CPU "+label)
 var space:PhysicsDirectSpaceState3D=demo.get_world_3d().direct_space_state;var world:=Pitch.Frame.world3(h,demo.town.house_roots.h1.get_meta("portico_roof_pitch").apex);var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.06,world-Vector3.UP*.06))
 check(not hit.is_empty() and hit.collider.get_meta("roof_surface",false) and absf(hit.position.y-world.y)<.001,"handle anchors actual pitched tile surface "+label)
 var doors:=door_rays();facts["doors_"+label]=doors;check(doors==original_doors,"roof preserves original actual entrance ray occupancy "+label)
func door_rays()->Array:
 var h:Dictionary=demo.state.houses[0];var space:PhysicsDirectSpaceState3D=demo.get_world_3d().direct_space_state;var result:Array=[]
 for entry:Dictionary in demo.state.house_entrances("h1"):
  var wall:=Vector3(entry.wall_at.x,float(h.get("base_y",0.))+.65,entry.wall_at.y);var normal:=Vector3(entry.outward.x,0,entry.outward.y);var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(wall+normal*.4,wall-normal*.2));result.append(not hit.is_empty())
 return result
func verify_original_anchor(label:String)->void:
 var h:Dictionary=demo.state.houses[0];var apex:Vector3=demo.town.house_roots.h1.get_meta("portico_original_anchor",Vector3.ZERO);var world:=Pitch.Frame.world3(h,apex);var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.06,world-Vector3.UP*.06));facts["original_anchor_"+label]={"house":h.duplicate(true),"root_meta":demo.town.house_roots.h1.get_meta_list(),"apex":apex,"direct":preload("res://scripts/visual/city_creation_portico_roof_pitch.gd").original_anchor(demo.town.house_roots.h1),"roof_names":demo.town.house_roots.h1.find_children("*Roof*","MeshInstance3D",true,false).map(func(n):return str(n.name)),"world":world,"hit":str(hit),"error":absf(hit.position.y-world.y) if not hit.is_empty() else -1.};check(apex!=Vector3.ZERO and not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1" and absf(hit.position.y-world.y)<.001,"original handle anchors actual old tile triangle "+label)
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));facts.source_sha256={}
 for source:String in ["res://scripts/visual/city_creation_portico_roof_pitch.gd","res://scripts/visual/city_creation_ancient_architecture.gd","res://scripts/ui/city_creation_roof_pitch_control.gd","res://scripts/world/city_creation_roof_pitch_geometry.gd","res://tools/check_creation_portico_roof_pitch_live.gd"]:facts.source_sha256[source]=FileAccess.get_file_as_string(source).sha256_text()
 root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec()
 var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control")
 if "--portico-bridge-only" in OS.get_cmdline_user_args():await portico_bridge();await modern_report(personal);return
 if "--extras-only" in OS.get_cmdline_user_args():await extras();await modern_report(personal);return
 await show(fixture(),Vector2(-26,-20),"柱廊门庭连续调坡");portico_focus();await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);var original:Dictionary=demo.state.snapshot();var old_gpu:=appearance(demo.town);original_doors=door_rays();facts.original_door_occupancy=original_doors;
 await open_editor();check(control.slider.editable and control.handle.visible,"native original portico controls remain reachable");verify_original_anchor("temple")
 if "--anchor-only" in OS.get_cmdline_user_args():
  for spec:Array in [[1,1,1,"full"],[2,2,2,"full"],[2,2,1,"half"],[1,1,1,"terrace"]]:
   var city:=fixture(spec[0],spec[1],spec[2],spec[3]);city.houses[0].base_y=1.;city.rotate_house("h1",.35);await show(city,Vector2(-27,-19),"原顶锚点五构型定位");portico_focus();await settle();quiet();await open_editor();verify_original_anchor(str(spec))
  await modern_report(personal);return

 for angle:float in [0.,45.,78.]:
  await open_editor();var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();await drag_slider(angle,false);check(await wait_for(func():return preview_ready(angle),18000),"full detached portico roof preview ready "+str(angle))
  if control.current==null:await modern_report(personal);return
  var expected:=appearance(control.current.renderer);check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"held roof preview keeps author and history pure "+str(angle));await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
  check(demo.state.snapshot().schema==45 and demo.state.houses[0].roof_pitch=={"version":10,"profile":"portico","degrees":angle} and demo.state._undo.size()==depth+1 and demo.state.houses[0].cells==original.houses[0].cells,"one native schema45 transaction retains all rooms "+str(angle));check(appearance(demo.town)==expected,"candidate and published GPU materials match and fixed colonnade stays "+str(angle));verify_portico(str(angle));await capture("portico_"+str(int(angle)))
  if angle==0.:
   var archived:Dictionary=demo.gallery.library.read(str(control.backup.get("id","")));var old:=State.new();check(archived.get("ok",false) and old.restore(archived.world).ok and old.houses==before.houses,"first schema45 edit archives exact original city")
  var cold:=State.new();var file:=OUT+"/cold_"+str(int(angle))+".json";check(demo.state.save_city(file).ok and cold.load_city(file).ok and cold.houses==demo.state.houses,"schema45 atomic disk cold read "+str(angle));var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
  while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
  check(preview.ready and appearance(preview.renderer)==appearance(demo.town),"independent cold GPU materials match "+str(angle));preview.clear();await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"native Undo restores exact prior portico roof "+str(angle));await key(KEY_Y,true);await settle();quiet()
 await roof_click();await open_editor();var before:Dictionary=demo.state.snapshot();await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);await key(KEY_ESCAPE);await release_slider();check(control.current==null and demo.state.snapshot()==before,"Esc cancels portico roof preview");await open_editor();await ui_click(control.reset);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);check(demo.state.houses==original.houses and appearance(demo.town)==old_gpu,"original button restores exact portico GPU materials and author data")
 await extras();root.size=Vector2i(1024,768);await settle();await open_editor();check(root.get_visible_rect().encloses(control.slider.get_global_rect()) and root.get_visible_rect().encloses(control.handle.get_global_rect()),"existing controls fit 1024 viewport");await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);var empty:=State.new();empty.initialize_free();await show(empty,Vector2(-28,-20),"长馆过期预演撤回");await settle();quiet();check(control.current==null and control.pending==null and demo.state.houses.is_empty(),"city change withdraws stale roof and picking");check(pending_isolated,"pending portico geometry never publishes collisions");facts.elapsed_seconds=(Time.get_ticks_msec()-began)/1000.;await modern_report(personal)
func roof_click()->void:
 demo.spatial_popover.close();demo.select_tool(0);portico_focus();await settle();quiet();var h:Dictionary=demo.state.houses[0];var at:=Vector2.ZERO;var hit:Dictionary={}
 for patch:Dictionary in PorticoFixture.Geo.for_house(demo.state,h).patches:
  if not patch.roof_skin:continue
  for i in range(0,patch.vertices.size(),3):
   var p:=Pitch.Frame.world3(h,(patch.vertices[i]+patch.vertices[i+1]+patch.vertices[i+2])/3.);var pixel:Vector2=demo.camera.unproject_position(p);var sample:Dictionary=demo._ray_hit(pixel)
   if root.get_visible_rect().has_point(pixel) and not sample.is_empty() and sample.collider.get_meta("roof_surface",false):at=pixel;hit=sample;break
  if not hit.is_empty():break
 var resolved:Dictionary=preload("res://scripts/ui/city_creation_unified_build.gd").resolve(demo.state,hit,Vector2(-26,-20));check(not hit.is_empty() and resolved.has("cell") and resolved.cell.level==1 and resolved.cell.kind=="room" and resolved.valid,"steep tile resolves original highest room upper floor");var before:Dictionary=demo.state.snapshot();await pointer(at);await send(at,true);await send(at,false);await settle();quiet();check(demo.state.houses[0].cells.size()==before.houses[0].cells.size()+1 and demo.state.houses[0].cells[-1].level==1 and demo.state.houses[0].roof_pitch==before.houses[0].roof_pitch,"native steep portico roof click adds real upper room and retains pitch");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and demo.town.house_roots.h1.has_meta("portico_roof_pitch"),"native Undo restores complete pitched portico")
func extras()->void:
 for spec:Array in [[1,1,1,"full"],[2,2,2,"full"],[2,2,1,"half"],[1,1,1,"terrace"]]:
  var city:=fixture(spec[0],spec[1],spec[2],spec[3]);city.houses[0].base_y=1.;city.rotate_house("h1",.35);await settle();quiet();await wait_for(func():return not demo.edit_pending() and not demo.gallery.busy,18000);await show(city,Vector2(-27,-19),"旋转抬基多层半院门庭"+str(spec));facts["load_"+str(spec)]={"expected":city.houses.duplicate(true),"actual":demo.state.houses.duplicate(true),"status":demo.gallery.panel._status,"busy":demo.gallery.busy,"edit":demo.edit_pending()};check(demo.state.houses==city.houses,"actual next fixture city loads exact requested rooms and original recipe "+str(spec));portico_focus();await settle();quiet();original_doors=door_rays();await open_editor();verify_original_anchor(str(spec))
  for angle:float in [0.,78.]:
   demo._after_edit(demo.state.set_house_roof_pitch("h1",angle),"pitch");await settle();quiet();verify_portico(str(spec)+str(angle));await capture("portico_case_"+str(spec[3])+str(spec[2])+"_"+str(int(angle)));await open_editor();check(control.slider.editable and control.handle.visible,"rotated raised stacked/half-court/terrace keeps controls "+str(spec))
   if spec[3]=="half" and angle==78.:demo.spatial_popover.close();demo.pitch=.3;demo.yaw=0.;demo._update_camera();await settle();await capture("portico_half_78_low_front")
 demo._after_edit(demo.state.set_house_colors("h1",Color("99b3c2"),Color("db946d")),"colors");await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);var hot:=appearance(demo.town);var cold:=State.new();cold.restore(demo.state.snapshot());var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
 while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
 check(preview.ready and appearance(preview.renderer)==hot,"hot custom tile colors equal independent cold GPU materials");preview.clear()
func portico_bridge()->void:
 var city:=fixture(1,1,1);city.set_house_roof_pitch("h1",0.)
 for at:Vector2 in [Vector2(-33,-20),Vector2(-24.5,-20)]:city.add_house(at)
 for id:String in ["h2","h3"]:city.houses[city._house_index(id)].base_y=.2;city.set_house_era(id,"modern_eco");city.set_house_architecture(id,"chalet");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
 city.set_house_skybridge_span("h3",true);await show(city,Vector2(-28,-20),"长馆与真实九米云廊");await settle();quiet();var before:Dictionary=demo.state.snapshot();check(not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"real cloud bridge clears flat portico roof");await open_editor();await drag_slider(78.,false);check(await wait_for(func():return preview_ready(78.),18000),"portico preview prepares affected bridge roots")
 if control.current==null:return
 check(control.current.ids.has("h2") and control.current.renderer.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.snapshot()==before,"pure portico preview retracts actual obstructed bridge");await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();check(demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.houses[2].skybridge_span==before.houses[2].skybridge_span,"published portico roof retracts bridge preserving span choice");await capture("portico_blocks_cloud_bridge");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"native Undo restores flat portico roof and actual bridge")

