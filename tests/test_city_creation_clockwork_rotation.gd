extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Roof=preload("res://scripts/visual/city_creation_clockwork.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
static func fixture()->RefCounted:
	var city:=State.new();city.initialize_free()
	city.add_house(Vector2(-25,-20));city.set_house_era("h1","clockwork");city.add_cell("h1",1,0,0)
	city.add_house(Vector2(-21.4,-20));city.set_house_era("h2","clockwork")
	return city
static func alone(city:RefCounted,id:String)->Array:
	var single:=State.new();single.restore(city.snapshot())
	for h:Dictionary in single.houses.duplicate():
		if str(h.id)!=id:single.remove_house(str(h.id))
	return Roof.prepare(single,single.houses[0])
func _initialize()->void:
	if not "--isolated-session" in OS.get_cmdline_user_args():quit(1);return
	var city:=fixture();check(city.houses.size()==2,"public two-house fixture")
	check(Roof.prepare(city,city.houses[1])!=alone(city,"h2"),"unrotated touching roof actually joins")
	check(city.rotate_house("h1",PI*.5).ok,"public rotation clears second house")
	var before:Dictionary=city.snapshot()
	for h:Dictionary in city.houses:check(Roof.prepare(city,h)==alone(city,str(h.id)),"detached roof equals isolated production arrays "+str(h.id))
	check(city.snapshot()==before,"roof query preserves author snapshot")
	var signature:=Roof.adjacency_signature(city,city.houses[0])
	check(city.add_house(Vector2(-25,-23.6)).ok and city.set_house_era("h3","clockwork").ok,"public new neighbour at rotated wing end")
	check(Roof.adjacency_signature(city,city.houses[0])!=signature,"new world neighbour invalidates old roof signature")
	for id:String in ["h1","h3"]:check(Roof.prepare(city,city.houses[city._house_index(id)])!=alone(city,id),"actual perpendicular square roofs join "+id)
	for angle:float in [.37,-.83,PI*.5]:
		var tilted:=State.new();tilted.initialize_free();tilted.add_house(Vector2(-25,-20));tilted.set_house_era("h1","clockwork")
		check(tilted.rotate_house("h1",angle).ok,"public oblique long house "+str(angle))
		var at:=Vector2(-25,-20)+Vector2(3.6,0).rotated(-angle)
		check(tilted.add_house(at).ok and tilted.set_house_era("h2","clockwork").ok and tilted.rotate_house("h2",angle).ok,"public aligned oblique neighbour "+str(angle))
		check(tilted.add_cell("h1",1,0,0).ok,"public extension closes actual oblique gap "+str(angle))
		for h:Dictionary in tilted.houses:check(Roof.prepare(tilted,h)!=alone(tilted,str(h.id)),"oblique touching roof joins "+str(angle)+str(h.id))
	var directional:=fixture();directional.set_house_architecture("h1","sawtooth_atrium");directional.set_house_architecture("h2","sawtooth_atrium");directional.rotate_house("h1",PI*.5)
	for h:Dictionary in directional.houses:check(Roof.prepare(directional,h)==alone(directional,str(h.id)),"detached directional roof keeps its end caps "+str(h.id))
	print("CLOCKWORK_ROTATION ",JSON.stringify({"ok":failures.is_empty(),"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
