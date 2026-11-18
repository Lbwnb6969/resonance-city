extends RefCounted
## Immutable, ordered candidates for one local road-union boundary.
const CELL:=2.
var groups:Array=[]
var edges:Array=[]
var bins:Dictionary={}
var scanlines:Array=[]
func _init(source:Array)->void:
	groups=source
	for group:int in range(groups.size()):
		scanlines.append({})
		for contour:int in range(groups[group].size()):
			var polygon:PackedVector2Array=groups[group][contour]
			for i:int in range(polygon.size()):
				var a:=polygon[i];var b:=polygon[(i+1)%polygon.size()]
				var bounds:=Rect2(a,Vector2.ZERO).expand(b);var index:=edges.size()
				edges.append({"a":a,"b":b,"bounds":bounds,"group":group,"contour":contour})
				for z:int in range(floori(bounds.position.y/CELL),floori(bounds.end.y/CELL)+1):
					for x:int in range(floori(bounds.position.x/CELL),floori(bounds.end.x/CELL)+1):
						var key:=Vector2i(x,z)
						if not bins.has(key):bins[key]=[]
						bins[key].append(index)
					if a.y!=b.y:
						if not scanlines[group].has(z):scanlines[group][z]=[]
						scanlines[group][z].append(index)
func crossings(bounds:Rect2,own:int,contour:PackedVector2Array)->Array:
	var found:Dictionary={}
	for z:int in range(floori(bounds.position.y/CELL),floori(bounds.end.y/CELL)+1):
		for x:int in range(floori(bounds.position.x/CELL),floori(bounds.end.x/CELL)+1):
			for index:int in bins.get(Vector2i(x,z),[]):found[index]=true
	var indices:Array=found.keys();indices.sort();var result:Array=[]
	for index:int in indices:
		var edge:Dictionary=edges[index]
		if edge.group==own and groups[own][edge.contour]==contour:continue
		if bounds.intersects(edge.bounds,true):result.append(edge)
	return result
func inside(point:Vector2,group:int)->bool:
	var covered:=false
	for index:int in scanlines[group].get(floori(point.y/CELL),[]):
		var edge:Dictionary=edges[index];var a:Vector2=edge.a;var b:Vector2=edge.b
		if (a.y>point.y)==(b.y>point.y):continue
		var cross_x:float=float(a.x)+(float(point.y)-float(a.y))*(float(b.x)-float(a.x))/(float(b.y)-float(a.y))
		if float(point.x)<cross_x:covered=not covered
	return covered
