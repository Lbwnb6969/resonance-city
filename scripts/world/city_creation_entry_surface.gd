extends RefCounted
## One actual approach owns its unchanging frame/steps and typed road points.
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const Street=preload("res://scripts/visual/city_creation_road_height_context.gd")
const EPS:=.002
var city:RefCounted
var entry:Dictionary
var normal:Vector2
var width:float
var points:Array[Vector2]=[]
var steps:Array=[]
var street:RefCounted
static func create(owner:RefCounted,house:Dictionary,door:Dictionary,road:Dictionary,plan:Dictionary)->RefCounted:
 var sampler=load("res://scripts/world/city_creation_entry_surface.gd").new();sampler.city=owner;sampler.entry=door;sampler.normal=Frame.normal(door);sampler.width=float(road.width)
 sampler.street=Street.new(owner)
 for p:Array in road.points:sampler.points.append(Vector2(p[0],p[1]))
 var base:float=house.get("base_y",0.)
 if door.active:
  var count:int=plan.count;var rise:float=.15-float(plan.bottom)
  for i in range(count):sampler.steps.append([.18+i*.23,.145,.47+i*.045,base+.15-i*rise/count,"porch_step"])
 elif owner.house_era(house)!="modern_eco":
  for row:Array in [[.3,.27,.48,.105],[.55,.34,.52,.0445]]:sampler.steps.append([row[0],row[1],row[2],base+float(row[3]),"door_step"])
 return sampler
func distance(at:Vector2)->float:
 var result:=at.distance_to(points[0])
 for i in range(1,points.size()):result=minf(result,city._distance_to_segment(at,points[i-1],points[i]))
 return result
func sample(at:Vector2)->Dictionary:
 var result:={"y":city.ground_height(at),"kind":"ground"}
 if distance(at)<=width*.5+EPS:
  var surface:Dictionary=city._road_heights.surface_at(at)
  var y:float=surface.top_y if surface.has("top_y") else street.height_at(at,float(surface.get("y",NAN)))
  if not surface.is_empty() and not surface.get("supported",true):
   if city.water_clearance(at)<.05:result={"y":y,"kind":"road_gap"}
  elif not surface.is_empty() and y>=float(result.y):result={"y":y,"kind":surface.kind}
 var relative:=at-Vector2(entry.wall_at);var along:=relative.dot(normal);var lateral:=absf(relative.cross(normal))
 for step:Array in steps:
  if absf(along-float(step[0]))<=float(step[1])+EPS and lateral<=float(step[2])+EPS and float(step[3])>=float(result.y):result={"y":float(step[3]),"kind":str(step[4])}
 return result
