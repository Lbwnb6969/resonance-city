extends RefCounted
const State=preload("res://scripts/world/city_creation_state.gd")
const Hinge=preload("res://scripts/world/city_creation_hinge_actions.gd")
static func build()->Dictionary:
	var city:=State.new();city.initialize_free()
	var first:Dictionary=city.add_house(Vector2(-32,-20));var cells:Array=[]
	for x:int in range(6):
		if x>0:cells.append({"x":x,"z":0,"level":0,"kind":"room"})
		cells.append({"x":x,"z":0,"level":1,"kind":"room"})
	var built:Dictionary=city.add_cells(first.house_id,cells)
	var folded:Dictionary=Hinge.set_angle(city,first.house_id,28.)
	var target:Dictionary=city.houses[0].cells.filter(func(c):return c.x==0 and c.level==1)[0]
	return {"city":city,"id":str(first.house_id),"target":str(target.id),"ok":first.ok and built.ok and folded.ok}
