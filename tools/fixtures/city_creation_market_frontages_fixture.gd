extends RefCounted
const State=preload("res://scripts/world/city_creation_state.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
const STREET_ROLES:=["bakery","atelier","workshop","garden_cafe"]

static func mixed_street()->Dictionary:
	var city:=State.new()
	city.initialize_free()
	var results:Array[bool]=[]
	for index in range(STREET_ROLES.size()):
		var x:= -28.+4.*index
		var built:Dictionary=city.add_house(Vector2(x,-20))
		results.append(built.ok and city.set_house_role(built.house_id,STREET_ROLES[index]).ok)
	results.append(city.add_road([Vector2(-30,-16),Vector2(-14,-16)] as Array[Vector2],"cobble","none").ok)
	for index in range(STREET_ROLES.size()):
		var x:= -28.+4.*index
		results.append(city.add_road([Vector2(x,-16),Vector2(x,-18.55)] as Array[Vector2],"cobble","none").ok)
	return {"city":city,"ok":not results.has(false)}

static func build()->Dictionary:
	var city:=State.new();city.initialize_free();var results:Array=[]
	results.append(Brush.select(city,"renaissance","venetian_loggia"))
	for x:float in [-18.,-14.,-10.,-6.]:results.append(city.add_house(Vector2(x,-20)).ok)
	results.append(city.add_road([Vector2(-20,-18.1),Vector2(-4,-18.1)] as Array[Vector2],"path","none").ok)
	results.append(city.add_water([Vector2(3,-24),Vector2(-20,-24)] as Array[Vector2],1.2,"channel").ok)
	Brush.select(city,"pastoral","townhouse");results.append(city.add_house(Vector2(-32,-16)).ok)
	results.append(city.add_road([Vector2(-34,-14.1),Vector2(-30,-14.1)] as Array[Vector2],"path","none").ok)
	return {"city":city,"ok":not results.has(false)}
