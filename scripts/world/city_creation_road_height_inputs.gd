extends RefCounted
## Broad-phase dependencies preserve the original 0.82m projection test/order.
const Upper=preload("res://scripts/world/city_creation_upper_stoop.gd")
static func upper_anchor(house:Dictionary)->bool:
 return Upper.eligible(house) and house.cells.any(func(c):return int(c.level)==1 and c.kind=="room")
static func upper_signature(houses:Array)->Array:
 var result:Array=[]
 for house:Dictionary in houses:result.append([str(house.id),upper_anchor(house)])
 return result
static func for_road(road:Dictionary,doors:Array)->Array:
 var bounds:=Rect2(Vector2(road.points[0][0],road.points[0][1]),Vector2.ZERO)
 for point:Array in road.points:bounds=bounds.expand(Vector2(point[0],point[1]))
 bounds=bounds.grow(.85)
 var result:Array=[]
 for door:Dictionary in doors:
  if door.active and not str(door.road_id).is_empty() and str(door.road_id)!=str(road.id):continue
  if bounds.has_point(door.at):result.append(door)
 return result
