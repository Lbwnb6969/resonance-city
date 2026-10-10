extends SceneTree
func _init():
 var a=PackedVector2Array([Vector2(0,0),Vector2(10,0),Vector2(10,10),Vector2(0,10)])
 var b=PackedVector2Array([Vector2(3,3),Vector2(7,3),Vector2(7,7),Vector2(3,7)])
 print('exclude=',Geometry2D.exclude_polygons(a,b))
 print('clip=',Geometry2D.clip_polygons(a,b))
 print('intersect=',Geometry2D.intersect_polygons(a,b))
 quit()
