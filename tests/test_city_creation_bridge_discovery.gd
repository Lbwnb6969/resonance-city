extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Cloud=preload("res://tools/fixtures/city_creation_cloud_gallery_fixture.gd")
const Plan=preload("res://scripts/world/city_creation_skybridge_plan.gd")
const Discovery=preload("res://scripts/world/city_creation_bridge_discovery.gd")
const Preview=preload("res://scripts/world/city_creation_chemistry_preview.gd")
const Shape=preload("res://scripts/world/city_creation_chemistry_shapes.gd")
var checks:=0
var failures:Array=[]
var out:=""
func check(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 var city=Cloud.city(8.5,0.);var a:Dictionary=city.houses[0];var b:Dictionary=city.houses[1]
 var before=city.snapshot();var proof=Plan.assess(city,a,a.cells[2],b,b.cells[2],Vector2i.RIGHT)
 check(not proof.ok and "九米云廊" in proof.reason,"long span explains exact discoverable nine-metre choice")
 var hints=Discovery.building(city,a)
 check(hints.size()==1 and hints[0].valid==false and hints[0].kind=="bridge_hint","rejected span is diagnostic rather than a promised bridge")
 check(city.snapshot()==before,"diagnostic preserves all authorship and history")
 city.set_house_skybridge_span(b.id,true);var actual=Plan.for_house(city,a)
 proof=Plan.assess(city,a,a.cells[2],b,b.cells[2],Vector2i.RIGHT)
 check(proof.ok and actual.size()==1 and proof.plan==actual[0],"successful proof is the exact production geometry")
 check("九米云廊" in Shape.skybridge(actual[0]).label,"nine-metre ghost names the actual selected bridge")
 b.base_y+=.3;proof=Plan.assess(city,a,a.cells[2],b,b.cells[2],Vector2i.RIGHT)
 check(not proof.ok and "楼面高度" in proof.reason,"base height mismatch explained")
 b.base_y-=.3;b.yaw=.2;proof=Plan.assess(city,a,a.cells[2],b,b.cells[2],Vector2i.RIGHT)
 check(not proof.ok and "朝向" in proof.reason,"orientation mismatch explained")
 b.erase("yaw");b.origin[1]+=.2;proof=Plan.assess(city,a,a.cells[2],b,b.cells[2],Vector2i.RIGHT)
 check(not proof.ok and "正对齐" in proof.reason,"lateral alignment mismatch explained")
 b.origin[1]-=.2;b.cells[2].kind="terrace";proof=Plan.assess(city,a,a.cells[2],b,b.cells[2],Vector2i.RIGHT)
 check(not proof.ok and "房间端点" in proof.reason,"terrace cannot be mislabelled as a room endpoint")
 b.cells[2].kind="room"
 var blocker=city.add_house(Vector2(-25.75,-20));check(blocker.ok and city.add_cell(blocker.house_id,0,0,1).ok,"real blocking roof fixture")
 proof=Plan.assess(city,a,a.cells[2],b,b.cells[2],Vector2i.RIGHT)
 check(not proof.ok and "房屋或屋顶" in proof.reason and not Plan.for_house(city,a).any(func(p):return p.to_house==b.id),"diagnostic and production reject same actual blocking roof")
 var fresh=Cloud.city(6.,0.);check(fresh.remove_house("h2").ok,"new house bridge fixture retains issued ID high water")
 var cells:Array=[]
 for level in range(3):cells.append({"x":0,"z":0,"level":level,"kind":"room"})
 var where:=Vector2(-24,-20);var proposal=fresh.preview_house_stroke(where,cells);check(proposal.ok,"whole modern house proposal is legal")
 before=fresh.snapshot();var future=Preview.building(fresh,{"new_house":where,"base_y":0.,"cells":cells,"valid":true})
 check(fresh.snapshot()==before,"new-house bridge preview cannot issue real house or cell IDs")
 var built=fresh.add_house_stroke(where,cells);check(built.ok,"exact modern brush proposal commits")
 var expected_bridges:Array=[]
 for h:Dictionary in fresh.houses:
  for bridge:Dictionary in Plan.for_house(fresh,h):expected_bridges.append(Shape.skybridge(bridge))
 check(future.filter(func(r):return r.kind=="skybridge")==expected_bridges and not expected_bridges.is_empty(),"new-house brush era and predicted identities produce same bridge as commit")
 var roads:Array=[]
 for era:String in ["pastoral","renaissance","clockwork","modern_eco"]:
  var road_city=State.new();road_city.initialize_free();var pts:Array[Vector2]=[Vector2(-12,9),Vector2(15,9)]
  var district=road_city.add_district(pts,10.,"weave");check(district.ok and road_city.set_district_era(district.district_id,era).ok,"real bridge era "+era)
  var style="path" if era=="pastoral" else "promenade"
  var width:float=1.25 if era=="pastoral" else 1.6
  before=road_city.snapshot();var rows=Preview.road(road_city,pts,width,style,true)
  check(rows.any(func(r):return r.kind=="bridge"),"all road bridge families receive a ghost "+era)
  check(road_city.snapshot()==before,"road preview source remains unchanged "+era)
  var commit=road_city.add_road(pts,style,"none",width);check(commit.ok,"real bridge commit "+era+" "+str(commit))
  if not commit.ok:continue
  var profile=road_city.road_profile(road_city.roads[-1]);var expected:Array=[]
  for run:Dictionary in profile.bridge_runs:expected.append(Shape.bridge(run))
  expected.append_array(Shape.simple_bridge(profile,width))
  check(rows.filter(func(r):return r.kind=="bridge")==expected,"preview exactly matches published production profile "+era)
  roads.append({"era":era,"rows":rows})
 var steps=preload("res://tools/fixtures/city_creation_stepping_support_fixture.gd").build()
 var stepping_profile=steps.road_profile(steps.roads[0])
 check(not stepping_profile.stepping_runs.is_empty(),"real shallow-channel stepping fixture")
 check(Shape.simple_bridge(stepping_profile,float(steps.roads[0].width)).is_empty(),"stepping stones never promise a continuous simple bridge")
 var result={"ok":failures.is_empty(),"checks":checks,"failures":failures,"roads":roads}
 FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result))
 print("BRIDGE_DISCOVERY ",checks," checks; failures ",failures);quit(0 if failures.is_empty() else 1)
