class_name ValleyProp
extends Node2D
const ClassicalLampLight = preload("res://scripts/visual/classical_lamp_light.gd")
const ClassicalFacadeLight = preload("res://scripts/visual/classical_facade_light.gd")
var kind := "tree"
var era := 1:
	set(value):
		if era == value: return
		era = value
		if era != 1 and classical_lamp_light != null: classical_lamp_light.visible = false
		queue_redraw()
var tone := 0
var motion := 0.0
var direction := Vector2.RIGHT
var active := true
var reveal := 1.0
var passengers := 0
var stop_id := ""
var art_entry: Dictionary = {}
var art_texture: Texture2D
var art_shadow: Texture2D
var art_contact: Texture2D
var classical_lamp_light: Node2D
var classical_facade_light: Sprite2D

func sync_classical_lamp_light(night_strength: float,world_tint: Color) -> void:
	if kind != "lamp" or era != 1:
		if classical_lamp_light != null: classical_lamp_light.visible = false
		return
	if classical_lamp_light == null:
		classical_lamp_light = ClassicalLampLight.new()
		classical_lamp_light.name = "OilWickLight"
		add_child(classical_lamp_light)
	classical_lamp_light.sync(night_strength,world_tint)

func sync_classical_facade_light(mask: Texture2D,night_strength: float,world_tint: Color) -> void:
	if kind != "civic" or art_entry.is_empty() or mask == null:
		if classical_facade_light != null: classical_facade_light.visible = false
		return
	if classical_facade_light == null:
		classical_facade_light = ClassicalFacadeLight.new()
		add_child(classical_facade_light)
	classical_facade_light.set_entry(art_entry,mask)
	var bounds: Array = art_entry["model_bounds"]["size"]
	var world_scale := 28.0*sqrt(2.0)*float(art_entry["plot_span"])/maxf(float(bounds[0]),float(bounds[2]))
	classical_facade_light.scale = Vector2.ONE*world_scale/float(art_entry["pixels_per_world"])
	classical_facade_light.sync(reveal >= 1.0,night_strength,world_tint)

func _project(p: Vector2) -> Vector2:
	return Vector2((p.x-p.y)*28.0,(p.x+p.y)*14.0)

func _draw_art_candidate() -> void:
	var bounds: Array = art_entry["model_bounds"]["size"]
	var world_scale := 28.0*sqrt(2.0)*float(art_entry["plot_span"])/maxf(float(bounds[0]),float(bounds[2]))
	for mask: String in ["shadow","contact"]:
		var texture := art_shadow if mask == "shadow" else art_contact
		var factor := world_scale/float(art_entry[mask+"_pixels_per_world"])
		var origin: Array = art_entry[mask+"_origin"]
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE*factor)
		draw_texture(texture,-Vector2(origin[0],origin[1]),Color(1.0,1.0,1.0,0.16 if mask == "shadow" else 0.20))
	var factor := world_scale/float(art_entry["pixels_per_world"])
	var origin: Array = art_entry["origin"]
	var sway := sin(motion+tone)*0.014 if kind == "tree" else 0.0
	# A tiny lean rotates around the ground anchor, keeping the tree foot planted.
	draw_set_transform(Vector2.ZERO,sway,Vector2.ONE*factor)
	draw_texture(art_texture,-Vector2(origin[0],origin[1]))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	modulate.a = reveal
	if not art_entry.is_empty():
		_draw_art_candidate()
		return
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
	elif kind == "carriage":
		var forward := direction.normalized()*0.30
		var side := Vector2(-direction.y,direction.x)*0.12
		var body := PackedVector2Array([_project(-forward-side),_project(forward-side),_project(forward+side),_project(-forward+side)])
		var roof := PackedVector2Array()
		for p in body: roof.append(p-Vector2(0,5.8))
		draw_set_transform(Vector2(2,2),0,Vector2(1.0,0.5))
		draw_circle(Vector2.ZERO,8.0,Color(0.29,0.38,0.34,0.15))
		draw_set_transform(Vector2.ZERO)
		draw_colored_polygon(PackedVector2Array([body[0],body[1],roof[1],roof[0]]),Color("9b6d4d"))
		draw_colored_polygon(PackedVector2Array([body[1],body[2],roof[2],roof[1]]),Color("b98558"))
		draw_colored_polygon(PackedVector2Array([body[2],body[3],roof[3],roof[2]]),Color("7f5944"))
		draw_colored_polygon(roof,Color("d4b77d"))
		for wheel in [-0.62,0.62]:
			draw_circle(_project(forward*wheel+side*1.05)+Vector2(0,0.5),2.7,Color("594d43"))
			draw_circle(_project(forward*wheel+side*1.05)+Vector2(0,0.5),1.35,Color("c2a36f"))
		# A pair of small horses makes the early era readable at a glance.
		for side_sign in [-1.0,1.0]:
			var horse := _project(forward*1.45+side*side_sign*0.42)
			draw_line(_project(forward*0.35+side*side_sign*0.34)-Vector2(0,3),horse-Vector2(0,3),Color("89664e"),1.1,true)
			draw_line(horse+Vector2(-1.0,0),horse+Vector2(-1.2,4),Color("6d5949"),1.0,true)
			draw_line(horse+Vector2(1.0,0),horse+Vector2(1.2,4),Color("6d5949"),1.0,true)
			draw_circle(horse-Vector2(0,3.8),2.0,Color("ad8e6c"))
	elif kind == "tram":
		var forward := direction.normalized()*0.43
		var side := Vector2(-direction.y,direction.x)*0.11
		var floor := PackedVector2Array()
		for p in [-forward-side,forward-side,forward+side,-forward+side]: floor.append(_project(p))
		var roof := PackedVector2Array()
		for p in floor: roof.append(p-Vector2(0,7.5))
		draw_set_transform(Vector2(2,2),0,Vector2(1.0,0.5))
		draw_circle(Vector2.ZERO,11,Color(0.29,0.38,0.34,0.15))
		draw_set_transform(Vector2.ZERO)
		for i in range(4):
			var j := (i+1)%4
			draw_colored_polygon(PackedVector2Array([floor[i],floor[j],roof[j],roof[i]]),Color("718b87") if i%2 == 0 else Color("91a9a1"))
		draw_colored_polygon(roof,Color("d9c48a"))
		for t in [-0.55,-0.12,0.31]:
			var a := _project(forward*t+side*0.95)-Vector2(0,6.0)
			var b := _project(forward*(t+0.28)+side*0.95)-Vector2(0,6.0)
			draw_line(a,b,Color("dbe5d1"),1.8,true)
		for wheel in [-0.60,0.60]: draw_circle(_project(forward*wheel+side*0.85),1.7,Color("4e625f"))
	elif kind == "car":
		var forward := direction.normalized()*0.30
		var side := Vector2(-direction.y,direction.x)*0.09
		var floor := PackedVector2Array()
		for p in [-forward-side,forward-side,forward+side,-forward+side]: floor.append(_project(p))
		var roof := PackedVector2Array()
		for p in floor: roof.append(p-Vector2(0,5.4))
		draw_set_transform(Vector2(2,2),0,Vector2(1.0,0.5))
		draw_circle(Vector2.ZERO,7.5,Color(0.29,0.38,0.34,0.15))
		draw_set_transform(Vector2.ZERO)
		draw_colored_polygon(PackedVector2Array([floor[0],floor[1],roof[1],roof[0]]),Color("708d8b"))
		draw_colored_polygon(PackedVector2Array([floor[1],floor[2],roof[2],roof[1]]),Color("88aaa2"))
		draw_colored_polygon(PackedVector2Array([floor[2],floor[3],roof[3],roof[2]]),Color("526f73"))
		draw_colored_polygon(roof,Color("d9c58e"))
		for t in [-0.42,0.20]:
			var window := _project(forward*t+side*1.01)-Vector2(0,4.9)
			draw_colored_polygon(PackedVector2Array([window,window+Vector2(5,0),window+Vector2(5,2.0),window+Vector2(0,2.0)]),Color("547479"))
		for wheel in [-0.48,0.48]:
			draw_circle(_project(forward*wheel+side*0.88),1.6,Color("4f5b5a"))
		draw_circle(_project(forward+side*0.5)-Vector2(0,1.8),0.75,Color("f8e8b5"))
		draw_circle(_project(forward-side*0.5)-Vector2(0,1.8),0.75,Color("f8e8b5"))
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
		for i in range(mini(passengers,6)):
			var t: float = -0.58+float(i)*0.22
			var window := _project(forward*t+side*0.98)-Vector2(0,6.9)
			draw_circle(window,0.72,Color("f5e1a4") if active else Color("fff0bd"))
		if not active:
			draw_arc(Vector2(0,-5),13.0,0,TAU,20,Color(0.90,0.75,0.40,0.38),1.0,true)
	elif kind == "stop":
		var sign_colors: Array[Color] = [Color("d8b86e"),Color("86a9a0"),Color("c98e72"),Color("9c9bd0")]
		var sign_color: Color = sign_colors[posmod(tone,4)]
		draw_line(Vector2(0,2),Vector2(0,-14),Color("68766d"),1.4,true)
		draw_circle(Vector2(0,-15),4.0,Color(0.17,0.24,0.22,0.82))
		draw_circle(Vector2(0,-15),2.7,sign_color)
		draw_arc(Vector2(0,-15),5.8,-2.7,-0.45,10,Color(sign_color.r,sign_color.g,sign_color.b,0.45),1.0,true)
		if bool(get_meta("transfer_stop",false)):
			draw_arc(Vector2(0,-15),8.2,-2.9,-0.25,14,Color("f1d28a"),1.5,true)
			draw_line(Vector2(-3.4,-21),Vector2(0,-24),Color("f1d28a"),1.2,true)
			draw_line(Vector2(0,-24),Vector2(3.4,-21),Color("f1d28a"),1.2,true)
		if bool(get_meta("authored_stop",false)):
			draw_line(Vector2(-2.4,-15),Vector2(0,-17.4),Color("f8edcb"),1.0,true)
			draw_line(Vector2(0,-17.4),Vector2(2.4,-15),Color("f8edcb"),1.0,true)
		var exchange: Dictionary = get_meta("station_exchange",{})
		if not exchange.is_empty():
			draw_arc(Vector2(0,1),10.0,0.15,2.99,15,Color(0.89,0.76,0.45,0.65),1.3,true)
			for index in range(mini(5,int(exchange.get("boarded",0)))):
				var waiting := Vector2(-9+index*3,4)
				draw_circle(waiting-Vector2(0,2.6),0.9,Color("f4dc9d"))
				draw_line(waiting-Vector2(0,1.5),waiting+Vector2(0,0.5),Color("a79770"),1.2,true)
			for index in range(mini(4,int(exchange.get("alighted",0)))):
				draw_circle(Vector2(7+index*2.7,1+index*0.6),1.2,Color("9bb9ae"))
			if int(exchange.get("transfers",0)) > 0:
				draw_arc(Vector2(0,-15),10.8,-2.8,-0.35,16,Color("c8b1d2"),1.5,true)
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
		if era == 1: _draw_classical_lamp()
		else: _draw_retained_lamp()
	elif kind == "rock":
		draw_colored_polygon(PackedVector2Array([Vector2(-7,1),Vector2(-3,-5),Vector2(4,-6),Vector2(8,0),Vector2(3,4)]),Color("bdc4b5"))
		draw_line(Vector2(-3,-5),Vector2(3,-1),Color("dbe0ce"),1,true)

func _draw_classical_lamp() -> void:
	# A small stone pedestal holds an open terracotta oil bowl. Its fixed
	# surfaces share daylight tint; the separate oil wick supplies night emission.
	draw_colored_polygon(PackedVector2Array([Vector2(-2,1),Vector2(3,-1),Vector2(6,1),Vector2(1,3)]),Color("415445",0.13))
	draw_colored_polygon(PackedVector2Array([Vector2(-3.4,0),Vector2(0,-1.7),Vector2(3.4,0),Vector2(0,1.7)]),Color("c3b397"))
	draw_colored_polygon(PackedVector2Array([Vector2(-1.5,-1),Vector2(0,-0.3),Vector2(0,-8.8),Vector2(-1.2,-9.4)]),Color("d9c9aa"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-0.3),Vector2(1.5,-1),Vector2(1.2,-9.4),Vector2(0,-8.8)]),Color("aa9b7f"))
	draw_line(Vector2(-1.25,-4.9),Vector2(0,-4.3),Color("bdad8f"),0.6,true)
	draw_line(Vector2(0,-4.3),Vector2(1.3,-4.9),Color("92866e"),0.6,true)
	draw_colored_polygon(PackedVector2Array([Vector2(-2.7,-9.3),Vector2(0,-10.7),Vector2(2.7,-9.3),Vector2(0,-7.9)]),Color("e4d5b6"))
	draw_colored_polygon(PackedVector2Array([Vector2(-3.1,-11.2),Vector2(-2.0,-9.9),Vector2(1.6,-9.9),Vector2(3.0,-11.2)]),Color("ae7454"))
	draw_colored_polygon(PackedVector2Array([Vector2(-3.1,-11.2),Vector2(-1.3,-12.0),Vector2(1.4,-12.0),Vector2(3.0,-11.2),Vector2(1.3,-10.6),Vector2(-1.5,-10.6)]),Color("d0a078"))
	draw_colored_polygon(PackedVector2Array([Vector2(-2.0,-11.2),Vector2(-1.0,-11.7),Vector2(1.1,-11.7),Vector2(2.0,-11.2),Vector2(1.1,-10.9),Vector2(-1.1,-10.9)]),Color("6c5843"))
	draw_line(Vector2(1.7,-11.1),Vector2(3.5,-11.7),Color("bd8861"),1.2,true)
	draw_line(Vector2(3.2,-11.6),Vector2(3.8,-12.3),Color("514f3c"),0.7,true)

func _draw_retained_lamp() -> void:
	# Retained later-era lamp, unchanged from the original production prop.
	draw_line(Vector2.ZERO,Vector2(0,-13),Color("829585"),1.3,true)
	draw_circle(Vector2(0,-13),2.3,Color("e4d6a6"))
