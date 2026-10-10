class_name NeighborhoodPlan
extends RefCounted
## Stable street-front parcels and closed neighborhoods; public reservations precede plots.
static func box(p: Vector2,half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([p-half,p+Vector2(half.x,-half.y),p+half,p+Vector2(-half.x,half.y)])

static func populate(world: RefCounted) -> void:
	var cfg: Dictionary = world.cfg["city"]
	var t: Dictionary = world.cfg["terrain"]
	var depth := float(cfg["neighborhood_depth"])
	for bank: int in [-1,1]:
		var prefix := "west" if bank < 0 else "east"
		var names := ["松丘","石桥","芦湾"] if bank < 0 else ["晴岸","钟庭","白沙"]
		for i in range(3): world.communities["%s-%d" % [prefix,i+1]]["name"] = names[i]
		for i in range(1,4):
			var p: Array = world.nodes["%s-%d" % [prefix,i]]
			var q := Vector2(float(p[0])+bank*depth,float(p[1]))
			var node := "%s-outer-%d" % [prefix,i]
			world.nodes[node] = [q.x,q.y]
			world.roads.append({"id":"%s-cross-%d" % [prefix,i],"from":"%s-%d" % [prefix,i],"to":node,"path":PackedVector2Array([Vector2(p[0],p[1]),q]),"bridge":false,"kind":"branch"})
			if i == 1: continue
			var path := PackedVector2Array()
			var previous: Array = world.nodes["%s-outer-%d" % [prefix,i-1]]
			for sample in range(17):
				var y := lerpf(float(previous[1]),q.y,float(sample)/16.0)
				path.append(Vector2(world.terrain.river_x(y)+bank*(float(t["template_road_bank_offset"])+depth),y))
			world.roads.append({"id":"%s-outer-road-%d" % [prefix,i],"from":"%s-outer-%d" % [prefix,i-1],"to":node,"path":path,"bridge":false,"kind":"branch"})
			var polygon := PackedVector2Array()
			var low_y := float(previous[1])
			for sample in range(17):
				var y := lerpf(low_y,q.y,float(sample)/16.0)
				polygon.append(Vector2(world.terrain.river_x(y)+bank*float(t["template_road_bank_offset"]),y))
			for sample in range(16,-1,-1):
				var y := lerpf(low_y,q.y,float(sample)/16.0)
				polygon.append(Vector2(world.terrain.river_x(y)+bank*(float(t["template_road_bank_offset"])+depth),y))
			world.blocks.append({"id":"%s-block-%d" % [prefix,i-1],"polygon":polygon,"community_id":"%s-%d" % [prefix,i]})
		var park_y := 10.9 if bank < 0 else 17.1
		var park_center := Vector2(world.terrain.river_x(park_y)+bank*(float(t["template_road_bank_offset"])+depth*0.5),park_y)
		var park_names: Dictionary = {
			"river_valley":["松影公园","晴岸花园"],
			"lake_basin":["镜湖湿地园","月湾水庭"],
			"forest_ridge":["林下听风园","松岚花园"],
			"coastal_plain":["潮线绿湾","晴沙风园"],
			"highland_pass":["峡谷回声园","高地风口园"]}
		var park := {"id":prefix+"-park","kind":"park","name":park_names.get(world.terrain.family,["松影公园","晴岸花园"])[0 if bank < 0 else 1],"position":[park_center.x,park_center.y],
			"polygon":box(park_center,Vector2(cfg["park_half_width"],cfg["park_half_length"])),"entrance":[park_center.x-bank*float(cfg["park_half_width"]),park_y],
			"community_id":prefix+"-2","active":false,"frame":0}
		world.public_sites.append(park)
		var node: Array = world.nodes[prefix+"-outer-2"]
		var center := Vector2(float(node[0])+bank*1.8,float(node[1]))
		var civic_names: Dictionary = {
			"river_valley":["河谷图书馆","晴岸音乐亭"],
			"lake_basin":["湖心藏谱屋","月湾水声亭"],
			"forest_ridge":["林岭声部所","松岚木琴亭"],
			"coastal_plain":["潮汐资料馆","晴沙潮声站"],
			"highland_pass":["关隘回响所","峡口风琴亭"]}
		world.public_sites.append({"id":prefix+"-civic","kind":"civic","name":civic_names.get(world.terrain.family,["河谷图书馆","晴岸音乐亭"])[0 if bank < 0 else 1],"position":[center.x,center.y],
			"polygon":box(center,Vector2(cfg["civic_half_width"],cfg["civic_half_length"])),"entrance":node.duplicate(),
			"community_id":prefix+"-2","active":false,"frame":0})
		for row in range(7):
			var y := 8.8+row*1.6
			for side: int in [-1,1]:
				var x: float = world.terrain.river_x(y)+bank*(float(t["template_road_bank_offset"])+depth)
				var center_lot := Vector2(x+side*float(t["template_lot_road_offset"]),y)
				var region := mini(2,maxi(0,floori(y/10.0)))
				world.lots.append({"id":"%s-outer-lot-%d-%d" % [prefix,row,side],"center":[center_lot.x,center_lot.y],
					"polygon":box(center_lot,Vector2(t["template_lot_half_width"],t["template_lot_half_length"])),"entrance":[x,y],
					"use":"commercial" if row in [2,3] else "residential","community_id":"%s-%d" % [prefix,region+1],"bank":bank,"occupant":""})
	GardenNeighborhood.populate(world)
	var legal: Array[Dictionary] = []
	for lot in world.lots:
		var polygon: PackedVector2Array = lot["polygon"]
		if not world.terrain.valid_footprint(polygon): continue
		var clear := true
		for site in world.public_sites:
			var components: Array = site.get("footprint_components",[site.get("polygon",PackedVector2Array())])
			for component in components:
				if not Geometry2D.intersect_polygons(polygon,component).is_empty(): clear = false
		for road in world.roads:
			var width := float(cfg["branch_road_half_width"]) if road.get("kind","") == "branch" else float(t["template_road_half_width"])
			for strip in Geometry2D.offset_polyline(road["path"],width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
				if not Geometry2D.intersect_polygons(polygon,strip).is_empty(): clear = false
		if clear: legal.append(lot)
	world.lots = legal
