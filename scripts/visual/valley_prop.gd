class_name ValleyProp
extends Node2D
var kind := "tree"
var tone := 0
var motion := 0.0
var direction := Vector2.RIGHT
var active := true
var reveal := 1.0

func _project(p: Vector2) -> Vector2:
	return Vector2((p.x-p.y)*28.0,(p.x+p.y)*14.0)

func _draw() -> void:
	modulate.a = reveal
	if kind == "tree":
		var lift := 15.0+tone%3*2.0
		var wind := sin(motion+tone)*0.7
		draw_set_transform(Vector2(5,3),0,Vector2(1.0,0.4))
		draw_circle(Vector2.ZERO,7,Color(0.29,0.38,0.34,0.14))
		draw_set_transform(Vector2.ZERO)
		draw_line(Vector2.ZERO,Vector2(wind,-lift),Color("89917b"),2.4,true)
		draw_set_transform(Vector2(wind,-lift),0,Vector2(1.0,0.84))
		var shade := Color("849d80") if tone%2 == 0 else Color("9bac88")
		draw_circle(Vector2(3,2),8,shade.darkened(0.10))
		draw_circle(Vector2(-4,-1),7,shade)
		draw_circle(Vector2(1,-6),8,shade.lightened(0.10))
		draw_circle(Vector2(-2,-7),4,Color(0.83,0.87,0.72,0.45))
		draw_set_transform(Vector2.ZERO)
	elif kind == "civic":
		var base := PackedVector2Array([Vector2(-27,0),Vector2(0,-13),Vector2(27,0),Vector2(0,13)])
		draw_colored_polygon(base,Color("cdcbb9"))
		draw_colored_polygon(PackedVector2Array([Vector2(-23,-4),Vector2(0,7),Vector2(0,-19),Vector2(-23,-30)]),Color("d5d4bf"))
		draw_colored_polygon(PackedVector2Array([Vector2(0,7),Vector2(23,-4),Vector2(23,-30),Vector2(0,-19)]),Color("b8c7c1"))
		draw_colored_polygon(PackedVector2Array([Vector2(-26,-30),Vector2(0,-43),Vector2(26,-30),Vector2(0,-17)]),Color("e9ddbf"))
		draw_colored_polygon(PackedVector2Array([Vector2(-26,-30),Vector2(0,-17),Vector2(0,-21),Vector2(-26,-34)]),Color("cfbc96"))
		for x in [-17,-9]:
			draw_line(Vector2(x,-26+x*0.48+8),Vector2(x,-4+x*0.48+8),Color("efebd8"),3.5,true)
		for x in [7,15]:
			draw_colored_polygon(PackedVector2Array([Vector2(x,-15-x*0.48),Vector2(x+4,-17-x*0.48),Vector2(x+4,-7-x*0.48),Vector2(x,-5-x*0.48)]),Color("829b9a"))
		draw_line(Vector2(-12,6),Vector2(4,14),Color("ede4cb"),2,true)
	elif kind == "bus":
		var forward := direction.normalized()*0.38
		var side := Vector2(-direction.y,direction.x)*0.105
		var floor := PackedVector2Array()
		for p in [-forward-side,forward-side,forward+side,-forward+side]: floor.append(_project(p))
		var roof := PackedVector2Array()
		for p in floor: roof.append(p-Vector2(0,8))
		draw_set_transform(Vector2(2,2),0,Vector2(1.0,0.5))
		draw_circle(Vector2.ZERO,11,Color(0.29,0.38,0.34,0.15))
		draw_set_transform(Vector2.ZERO)
		for i in range(4):
			var j := (i+1)%4
			var shade := Color("a9bfb3") if (floor[i]+floor[j]).y > 0 else Color("becfc0")
			draw_colored_polygon(PackedVector2Array([floor[i],floor[j],roof[j],roof[i]]),shade)
		for sign_side in [-1.0,1.0]:
			for t in [-0.65,-0.15,0.35]:
				var a := _project(forward*t+side*sign_side)-Vector2(0,6.6)
				var b := _project(forward*(t+0.35)+side*sign_side)-Vector2(0,6.6)
				draw_colored_polygon(PackedVector2Array([a,b,b+Vector2(0,2.6),a+Vector2(0,2.6)]),Color("698783"))
			for wheel in [-0.62,0.62]:
				draw_circle(_project(forward*wheel+side*sign_side)+Vector2(0,-0.3),1.6,Color("596f6a"))
		draw_colored_polygon(roof,Color("e9deba"))
		draw_line(_project(-forward*0.7)-Vector2(0,8),_project(forward*0.7)-Vector2(0,8),Color("f4eccf"),1.2,true)
		draw_line(_project(forward-side*0.6)-Vector2(0,5.5),_project(forward+side*0.6)-Vector2(0,5.5),Color("62817c"),2.2,true)
		for sign_side in [-1,1]:
			draw_circle(_project(forward+side*sign_side*0.7)-Vector2(0,2),0.85,Color("f8e8b5"))
	elif kind == "walker":
		var stride := sin(motion*2.7+tone)*0.8 if active else 0.0
		var facing := _project(direction*0.035)
		draw_circle(Vector2(1,1),2,Color(0.35,0.40,0.35,0.15))
		draw_line(Vector2(-0.5,-2.5),Vector2(-0.8-stride,0),Color("727c71"),1.0,true)
		draw_line(Vector2(0.5,-2.5),Vector2(0.8+stride,0),Color("727c71"),1.0,true)
		draw_line(Vector2(0,-2.5),Vector2(0,-5.0),Color("ab8d6e") if tone%2 == 0 else Color("73968c"),2.4,true)
		draw_line(Vector2(0,-4),facing+Vector2(stride,-3),Color("c6ad86"),1.0,true)
		draw_circle(facing*0.3+Vector2(0,-6.4),1.4,Color("dfcba4"))
	elif kind == "lamp":
		draw_line(Vector2.ZERO,Vector2(0,-13),Color("829585"),1.3,true)
		draw_circle(Vector2(0,-13),2.3,Color("e4d6a6"))
	elif kind == "rock":
		draw_colored_polygon(PackedVector2Array([Vector2(-7,1),Vector2(-3,-5),Vector2(4,-6),Vector2(8,0),Vector2(3,4)]),Color("bdc4b5"))
		draw_line(Vector2(-3,-5),Vector2(3,-1),Color("dbe0ce"),1,true)
