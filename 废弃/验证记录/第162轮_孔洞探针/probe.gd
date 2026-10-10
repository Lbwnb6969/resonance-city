extends SceneTree
func area(p: PackedVector2Array) -> float:
	var s:=0.0
	for i in range(p.size()): s += p[i].x*p[(i+1)%p.size()].y-p[(i+1)%p.size()].x*p[i].y
	return absf(s)*0.5
func show(label:String,arr:Array[PackedVector2Array]):
	print(label,' count=',arr.size())
	for p in arr: print(' area=',area(p),' points=',p)
func _init():
	var outer := PackedVector2Array([Vector2(0,0),Vector2(10,0),Vector2(10,10),Vector2(0,10)])
	var hole := PackedVector2Array([Vector2(3,3),Vector2(7,3),Vector2(7,7),Vector2(3,7)])
	show('clip outer,hole',Geometry2D.clip_polygons(outer,hole))
	show('clip hole,outer',Geometry2D.clip_polygons(hole,outer))
	show('exclude outer,hole',Geometry2D.exclude_polygons(outer,hole))
	show('exclude hole,outer',Geometry2D.exclude_polygons(hole,outer))
	show('intersect',Geometry2D.intersect_polygons(outer,hole))
	show('merge',Geometry2D.merge_polygons(outer,hole))
	quit()
