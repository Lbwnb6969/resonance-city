extends RefCounted
## Detached preparation computes broad bounds once, retaining source order.
## Live/external queries without this immutable context keep the full inputs.
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
static func build(city:RefCounted)->void:
 var houses:Array=[];var roads:Array=[];var result:Dictionary={}
 for h:Dictionary in city.houses:houses.append({"house":h,"bounds":Frame.house_bounds(h)})
 for r:Dictionary in city.roads:
  var bounds:=Rect2(Vector2(r.points[0][0],r.points[0][1]),Vector2.ZERO)
  for p:Array in r.points:bounds=bounds.expand(Vector2(p[0],p[1]))
  roads.append({"road":r,"bounds":bounds.grow(float(r.width)*.5)})
 for target:Dictionary in houses:
  # Includes default/rotated door corridors, the existing 2m blocker key,
  # wide passages and the 2.25m projecting boathouse/acoustic entrances.
  var bounds:Rect2=target.bounds.grow(4.);var near_houses:Array=[];var near_roads:Array=[]
  for other:Dictionary in houses:
   if bounds.intersects(other.bounds,true):near_houses.append(other.house)
  for other:Dictionary in roads:
   if bounds.intersects(other.bounds,true):near_roads.append(other.road)
  result[str(target.house.id)]={"houses":near_houses,"roads":near_roads}
 city.set_meta("frontage_neighborhoods",result)
static func for_house(city:RefCounted,id:String)->Dictionary:
 return city.get_meta("frontage_neighborhoods",{}).get(id,{})
