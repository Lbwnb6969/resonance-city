class_name ValleyScenery
extends RefCounted
## Props share the building depth sort and the same audio frame as the river and city.
var props: Dictionary = {}
var sites: Dictionary = {}

func rebuild(demo: Control) -> void:
	for node in props.values(): node.queue_free()
	props.clear()
	for site in demo.shown_world.public_sites:
		sites[site["id"]] = site
	var city: ContinuousWorld = demo.shown_world
	# Deterministic natural groves, independent of the city's growth RNG.
	for i in range(110):
		var x := 1.2+float((i*47+13)%301)/10.0
		var y := -1.4+float((i*73+29)%327)/10.0
		var p := Vector2(x,y)
		if not city.terrain.land_at(p): continue
		var clear := true
		for lot in city.lots:
			if p.distance_to(Vector2(lot["center"][0],lot["center"][1])) < 1.25: clear = false
		for site in city.public_sites:
			if Geometry2D.is_point_in_polygon(p,site["polygon"]): clear = false
		var access := city.network.access(p)
		if not access.is_empty() and float(access["gap"]) < 0.6: clear = false
		if clear: _add(demo,"grove-%d" % i,p,"rock" if i%13 == 0 else "tree",i)
	for road in city.roads:
		if road["bridge"]: continue
		var path: PackedVector2Array = road["path"]
		if road.get("kind","") == "branch": continue
		var p := path[path.size()/2]+Vector2(0.38,0)
		if city.terrain.land_at(p): _add(demo,"lamp-"+road["id"],p,"lamp",0)
	for site in city.public_sites:
		var p := Vector2(site["position"][0],site["position"][1])
		if site["kind"] == "civic": _add(demo,site["id"],p,"civic",0,site["id"])
		else:
			for i in range(8):
				var offset := Vector2(-1.1+(i%2)*2.2,-1.4+(i/2)*0.9)
				_add(demo,"%s-tree-%d" % [site["id"],i],p+offset,"tree",i,site["id"])
	for i in range(2): _add(demo,"bus-%d" % i,Vector2.ZERO,"bus",i)
	for i in range(10): _add(demo,"walker-%d" % i,Vector2.ZERO,"walker",i)

func _add(demo: Control,key: String,p: Vector2,kind: String,tone: int,site: String = "") -> void:
	var prop := ValleyProp.new()
	prop.kind = kind
	prop.tone = tone
	prop.set_meta("world_position",p)
	prop.set_meta("site",site)
	if kind in ["bus","walker"]: prop.set_meta("traveler",CityTraveler.new(kind,tone))
	demo.buildings_layer.add_child(prop)
	props[key] = prop

func sync(demo: Control) -> void:
	var city: ContinuousWorld = demo.shown_world
	var frame: float = demo.clock.renderer.transport.audible_frame
	var rate: int = demo.clock.renderer.transport.sample_rate
	var seconds := frame/rate
	for key in props:
		var prop: ValleyProp = props[key]
		var p: Vector2 = prop.get_meta("world_position")
		var site_id := str(prop.get_meta("site"))
		prop.visible = true
		if not site_id.is_empty():
			var site: Dictionary = city.public_sites.filter(func(s: Dictionary) -> bool: return s["id"] == site_id)[0]
			prop.visible = site["active"]
			prop.reveal = clampf((frame-int(site["frame"]))/(0.5*rate),0.0,1.0)
		if prop.kind in ["bus","walker"]:
			var traveler: CityTraveler = prop.get_meta("traveler")
			var movement := traveler.advance(city,seconds)
			prop.visible = not movement.is_empty()
			if prop.visible:
				p = movement["position"]
				prop.direction = movement["direction"]
				prop.active = not movement["stopped"]
				prop.set_meta("world_position",p)
		prop.position = demo.point(p)
		prop.scale = Vector2.ONE*demo.view_zoom
		prop.motion = seconds*TAU/4.0
		prop.queue_redraw()
