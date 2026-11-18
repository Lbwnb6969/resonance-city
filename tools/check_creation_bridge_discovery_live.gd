extends "res://tools/check_creation_playtest_edit_live.gd"
const Cloud=preload("res://tools/fixtures/city_creation_cloud_gallery_fixture.gd")
const Shape=preload("res://scripts/world/city_creation_chemistry_shapes.gd")
func point(at:Vector3)->void:
 var pos:Vector2=demo.camera.unproject_position(at);var e:=InputEventMouseMotion.new();e.device=92;e.position=pos;e.global_position=pos;root.push_input(e);await process_frame;await process_frame
func click_at(pos:Vector2,pressed:bool)->void:
 var e:=InputEventMouseButton.new();e.device=92;e.position=pos;e.global_position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;root.push_input(e);await process_frame
func click3(at:Vector3,pressed:bool)->void:await click_at(demo.camera.unproject_position(at),pressed)
func control(button:Control)->void:
 await click_at(button.get_global_rect().get_center(),true);await click_at(button.get_global_rect().get_center(),false)
func ghosts()->Array:
 return demo.town.preview.get_node("ChemistryGhost").get_meta("rows",[]) if demo.town.preview.has_node("ChemistryGhost") else []
func view(city:RefCounted,id:String,focus:Array,zoom:float)->void:
 var chosen:={"ok":true,"id":id,"title":id,"world":city.snapshot(),"view":{"focus":focus,"zoom":zoom,"yaw":0.,"pitch":.8,"evening":false,"light_phase":0}}
 await demo.gallery._open_chosen(chosen);await settle();quiet();demo.life.set_process(false)
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
 var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();road_tool=demo.get_meta("road_tool")
 var city:RefCounted
 var before:Dictionary
 var depth:int
 var promised:Array=[]
 var actual:Array=[]
 if not "--road-only" in OS.get_cmdline_user_args():
  city=Cloud.city(8.5,0.,2);city.add_cell("h1",0,0,2)
  await view(city,"Cloud endpoints",[-25.7,1.7,-20.],21.);demo.select_tool(0)
  var roof:=Vector3(-21.5,3.8,-20.)
  await point(roof);before=demo.state.snapshot();depth=demo.state._undo.size();var cue:int=demo.chemistry_brush.cue_count
  check(demo.candidate.has("cell") and demo.candidate.cell.level==2 and demo.candidate.valid,"native roof hover proposes legal third-floor room")
  check(await wait_for(func():return ghosts().any(func(r):return r.kind=="bridge_hint"),15000),"native roof hover discovers rejected long-span endpoints")
  var rejected:Array=ghosts();check(rejected.any(func(r):return r.kind=="bridge_hint" and not r.valid and "九米云廊" in r.label),"rejection displays exact nine-metre appearance entry instead of promising a bridge")
  check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"endpoint discovery does not write city or history")
  check(demo.chemistry_brush.cue_count==cue,"rejected connection does not issue a success chime")
  await capture("long_span_rejected_with_entry")
  demo.select_tool(4);await point(roof);await click3(roof,true);await click3(roof,false);await process_frame
  check(demo.spatial_popover.target_house_id=="h2","native smoke click opens the hinted endpoint house")
  await control(demo.spatial_popover.inspector.appearance_button);await process_frame
  var choice:Button=demo.find_child("SkybridgeChoice_nine",true,false)
  check(choice!=null and choice.is_visible_in_tree(),"nine-metre choice is visibly reachable through actual appearance sheet")
  if choice!=null:await control(choice);await settle();quiet();demo.life.set_process(false)
  check(demo.state.houses[1].has("skybridge_span"),"native span choice commits through original backed-up API")
  await key(KEY_ESCAPE);await key(KEY_ESCAPE);demo.select_tool(0);await point(roof)
  before=demo.state.snapshot();depth=demo.state._undo.size()
  check(await wait_for(func():return ghosts().any(func(r):return r.kind=="skybridge"),15000),"same native roof hover now previews real nine-metre bridge")
  promised=ghosts().filter(func(r):return r.kind=="skybridge").duplicate(true)
  check(promised.any(func(r):return "九米云廊" in r.label and "第3层" in r.label),"valid ghost names span and actual shared floor")
  await capture("nine_metre_valid_preview")
  await click3(roof,true);await click3(roof,false);await settle();quiet();demo.life.set_process(false)
  actual=[]
  for h:Dictionary in demo.state.houses:
   for plan:Dictionary in preload("res://scripts/world/city_creation_skybridge_plan.gd").for_house(demo.state,h):actual.append(Shape.skybridge(plan))
  check(promised==actual and demo.state._undo.size()==depth+1,"native room release produces exactly the promised bridge in one room transaction")
  await capture("nine_metre_committed")
  await key(KEY_Z,true);await settle();check(demo.state.houses==before.houses,"Undo restores old endpoint geometry and selected span")
 for era:String in ["clockwork","modern_eco"]:
  city=State.new();city.initialize_free();var pts:Array[Vector2]=[Vector2(-12,9),Vector2(15,9)];var district=city.add_district(pts,10.,"weave");city.set_district_era(district.district_id,era)
  await view(city,era+" bridge",[0.,.3,9.],38.);demo.select_tool(2);demo.road_style="promenade";demo.road_size=0;road_tool.set_mode(1)
  await motion(pts[0]);await button(pts[0],true);await button(pts[0],false);await motion(pts[1])
  check(await wait_for(func():return ghosts().any(func(r):return r.kind=="bridge"),15000),"native cross-water stroke previews "+era)
  facts[era]={"districts":demo.state.districts.duplicate(true),"valid":road_tool.valid.duplicate(true),"style":demo.road_style,"size":demo.road_size,"pending":demo._edit_pending,"worker":demo.chemistry_brush.planner.stats.duplicate(true),"rows":ghosts().duplicate(true)}
  promised=ghosts().filter(func(r):return r.kind=="bridge").duplicate(true)
  check(promised.any(func(r):return ("钢桁" if era=="clockwork" else "现代单拱") in r.label),"correct road bridge family is discoverable "+era)
  await capture(era+"_bridge_preview")
  await button(pts[1],true);await button(pts[1],false);await settle();quiet();demo.life.set_process(false)
  actual=[]
  if not demo.state.roads.is_empty():
   var profile:Dictionary=demo.state.road_profile(demo.state.roads[-1])
   for run:Dictionary in profile.bridge_runs:actual.append(Shape.bridge(run))
  check(not actual.is_empty() and actual==promised,"actual road publication matches all promised bridge edges "+era)
  await capture(era+"_bridge_committed")
 await complete_report(personal)
