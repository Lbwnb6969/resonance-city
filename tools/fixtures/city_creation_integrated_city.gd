extends RefCounted
## Representative mixed city authored only through public construction APIs.
const State=preload("res://scripts/world/city_creation_state.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
static func build()->Dictionary:
	var city:=State.new();city.initialize_free();var operations:Array=[]
	var hill:Dictionary=city.plan_terrain_target([Vector2(-22,19)] as Array[Vector2],5.,1.4,true)
	operations.append({"label":"gentle modern terrace","result":city.apply_terrain_target(hill)})
	for group:Array in [["pastoral","portico",Vector2(-30,-24)],["renaissance","belvedere_villa",Vector2(16,-24)],["clockwork","sawtooth_atrium",Vector2(14,18)],["modern_eco","chalet",Vector2(-27,17)]]:
		operations.append({"label":"select "+str(group[0]),"result":{"ok":Brush.select(city,group[0],group[1])}})
		for house_index in range(3):
			var cells:Array=[]
			for x in range(3):
				for z in range(2):cells.append({"x":x,"z":z,"level":0,"kind":"room"})
			if house_index==1:
				for x in range(2):cells.append({"x":x,"z":0,"level":1,"kind":"room"})
			var at:Vector2=group[2]+Vector2(0,house_index*4.5)
			operations.append({"label":str(group[0])+" joined/staggered "+str(house_index),"result":city.add_house_stroke(at,cells)})
	operations.append({"label":"explicit modern courtyard brush","result":{"ok":Brush.select(city,"modern_eco","chalet")}})
	var court:Array=[]
	for x in range(5):
		for z in range(5):
			if x==0 or z==0 or x==4 or z==4:court.append({"x":x,"z":z,"level":0,"kind":"room"})
	operations.append({"label":"actual enclosed courtyard","result":city.add_house_stroke(Vector2(-16,-23),court)})
	for row:Array in [[Vector2(-34,-10),Vector2(-7,-10),"promenade"],[Vector2(11,-10),Vector2(30,-10),"avenue"],[Vector2(-32,30),Vector2(-12,30),"path"],[Vector2(10,32),Vector2(30,32),"promenade"],[Vector2(-14,4),Vector2(28,4),"promenade"],[Vector2(-14,-10),Vector2(-14,30),"path"],[Vector2(28,-10),Vector2(28,32),"path"]]:
		operations.append({"label":"real street "+str(row[0]),"result":city.add_road([row[0],row[1]] as Array[Vector2],row[2],"none")})
	for row:Array in [[Vector2(-33,-18),"olive"],[Vector2(-20,-29),"golden_tree"],[Vector2(12,-28),"cypress"],[Vector2(29,-16),"olive"],[Vector2(-32,13),"cypress"],[Vector2(-12,27),"golden_tree"],[Vector2(11,14),"olive"],[Vector2(32,25),"weeping_willow"],[Vector2(-5,12),"weeping_willow"],[Vector2(6,-5),"weeping_willow"]]:
		operations.append({"label":"plant "+str(row[0]),"result":city.place_plant(row[0],row[1],.9)})
	return {"city":city,"operations":operations,"ok":operations.all(func(r):return r.result.ok)}
