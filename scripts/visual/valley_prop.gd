class_name ValleyProp
extends Node2D
var kind := "tree"
var tone := 0
var motion := 0.0
var direction := Vector2.RIGHT
var active := true
var reveal := 1.0

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
		var forward := direction.normalized()*9.0
		var side := Vector2(-direction.y,direction.x)*4.0
		var floor := PackedVector2Array([-forward-side,forward-side,forward+side,-forward+side])
		var roof := PackedVector2Array()
		for p in floor: roof.append(p-Vector2(0,7))
		draw_colored_polygon(floor,Color("7f9590"))
		for i in range(4):
			var j := (i+1)%4
			draw_colored_polygon(PackedVector2Array([floor[i],floor[j],roof[j],roof[i]]),Color("c3aa7f") if i%2 == 0 else Color("a59679"))
		draw_colored_polygon(roof,Color("ead9b7"))
		draw_line(-forward-side*0.92-Vector2(0,4),forward-side*0.92-Vector2(0,4),Color("5d797a"),2,true)
		draw_circle(-forward*0.6+side,1.8,Color("687a75"))
		draw_circle(forward*0.6+side,1.8,Color("687a75"))
	elif kind == "walker":
		draw_circle(Vector2(1,1),2,Color(0.35,0.40,0.35,0.15))
		draw_line(Vector2.ZERO,Vector2(0,-4),Color("9a8870") if tone%2 == 0 else Color("728b85"),1.7,true)
		draw_circle(Vector2(0,-5.0+0.3*sin(motion)),1.4,Color("d8c5a3"))
	elif kind == "lamp":
		draw_line(Vector2.ZERO,Vector2(0,-13),Color("829585"),1.3,true)
		draw_circle(Vector2(0,-13),2.3,Color("e4d6a6"))
	elif kind == "rock":
		draw_colored_polygon(PackedVector2Array([Vector2(-7,1),Vector2(-3,-5),Vector2(4,-6),Vector2(8,0),Vector2(3,4)]),Color("bdc4b5"))
		draw_line(Vector2(-3,-5),Vector2(3,-1),Color("dbe0ce"),1,true)
