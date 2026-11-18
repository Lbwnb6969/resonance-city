extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
const Before=preload("res://tests/fixtures/city_creation_clockwork_before_query.gd")
const After=preload("res://scripts/visual/city_creation_clockwork.gd")
const Query=preload("res://scripts/visual/city_creation_clockwork_roof_query.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:
 if not "--isolated-session" in OS.get_cmdline_user_args():quit(1);return
 var edges:Array=[{"a":Vector2(-2,-2),"b":Vector2(2,-2),"base":1.7},{"a":Vector2(-2,-2),"b":Vector2(-2,2),"base":1.7},{"a":Vector2(-1,-1),"b":Vector2(2,2),"base":3.4}];var query:=Query.new(edges)
 for base:float in [1.7,3.4,1.7019,1.7021]:
  for point:Vector2 in [Vector2.ZERO,Vector2(-1,-1),Vector2(-2,-2),Vector2(-3,-2),Vector2(-3.0001,-2),Vector2(11,13),Vector2(-.999999,-2.1)]:
   var expected:=INF
   for edge:Dictionary in edges:
    if absf(float(edge.base)-base)>.002:continue
    expected=minf(expected,point.distance_to(Geometry2D.get_closest_point_to_segment(point,edge.a,edge.b)))
   check(After.roof_height(query.distance_at(point,base))==Before.roof_height(expected),"exact saturated height "+str([point,base]))
 for kind:String in ["","recessed_townhouse","sawtooth_atrium","clock_turret"]:
  var city:=State.new();city.initialize_free();Brush.select(city,"clockwork",kind)
  check(city.add_house(Vector2(-25,-20)).ok and city.add_house(Vector2(-23.2,-20)).ok,"real joined clockwork "+kind)
  check(city.add_cell("h1",0,0,1).ok,"real staggered upper room "+kind)
  var author:Dictionary=city.snapshot()
  for house:Dictionary in city.houses:check(After.prepare(city,house)==Before.prepare(city,house),"entire original roof arrays and metadata "+kind+str(house.id))
  check(city.snapshot()==author,"queries leave author world unchanged "+kind)
 print("CLOCKWORK_ROOF_QUERY ",JSON.stringify({"ok":failures.is_empty(),"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
