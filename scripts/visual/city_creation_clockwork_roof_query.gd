extends RefCounted
## Roof height saturates at one metre. Far edges cannot change that endpoint.
const RADIUS:=1.0
var bins:Dictionary={}
var values:Dictionary={}
func _init(edges:Array)->void:
 for edge:Dictionary in edges:
  var bounds:=Rect2(edge.a,Vector2.ZERO).expand(edge.b).grow(RADIUS+.00001)
  for y:int in range(floori(bounds.position.y),floori(bounds.end.y)+1):
   for x:int in range(floori(bounds.position.x),floori(bounds.end.x)+1):
    var bin:=Vector2i(x,y)
    if not bins.has(bin):bins[bin]=[]
    bins[bin].append(edge)
func distance_at(at:Vector2,base:float)->float:
 var key:Array=[at,base]
 if values.has(key):return values[key]
 var distance:=INF
 for edge:Dictionary in bins.get(Vector2i(floori(at.x),floori(at.y)),[]):
  if absf(float(edge.base)-base)>.002:continue
  distance=minf(distance,at.distance_to(Geometry2D.get_closest_point_to_segment(at,edge.a,edge.b)))
 values[key]=distance;return distance
