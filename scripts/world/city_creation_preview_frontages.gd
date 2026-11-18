extends RefCounted
## Road-only changes cannot alter distant entrances. House edits use original queries.
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
static func build(city:RefCounted,previous:Array,rows:Dictionary)->Dictionary:
 var dirty:Array[Rect2]=[]
 var reuse:bool=previous.size()==2 and previous[0]==city.houses
 if reuse:
  var old:Array=previous[1]
  # Position comparisons also invalidate reordered roads and their priority.
  for i:int in range(maxi(old.size(),city.roads.size())):
   var a:Dictionary=old[i] if i<old.size() else {}
   var b:Dictionary=city.roads[i] if i<city.roads.size() else {}
   if a==b:continue
   for road:Dictionary in [a,b]:
    if road.is_empty():continue
    # A long bent road's empty enclosing box is not a changed street.
    # Keep every old/new segment and width, including endpoint contacts.
    for j:int in range(1,road.points.size()):
     var start:=Vector2(road.points[j-1][0],road.points[j-1][1])
     var end:=Vector2(road.points[j][0],road.points[j][1])
     dirty.append(Rect2(start,Vector2.ZERO).expand(end).grow(float(road.width)*.5))
 var result:Dictionary={}
 for house:Dictionary in city.houses:
  var id:=str(house.id);var affected:bool=not reuse or not rows.has(id)
  if not affected:
   # Existing FrontageNeighborhoods uses this same conservative four-metre
   # reach for rotated doors, wide passages and projecting special entrances.
   var bounds:Rect2=Frame.house_bounds(house).grow(4.)
   for region:Rect2 in dirty:
    if bounds.intersects(region,true):affected=true;break
  result[id]=city.house_entrances(id) if affected else rows[id]
 return result
