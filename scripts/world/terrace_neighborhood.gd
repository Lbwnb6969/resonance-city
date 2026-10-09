class_name TerraceNeighborhood
extends RefCounted
## A second-scale neighborhood layer: inner terraces add stable communities and real branch roads.
static func box(p: Vector2, half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([p-half,p+Vector2(half.x,-half.y),p+half,p+Vector2(-half.x,half.y)])

static func _clear_site(world: RefCounted, polygon: PackedVector2Array) -> bool:
	if not world.terrain.valid_footprint(polygon): return false
	# Extension reservations are added after authored lots; placement will honor them
	# and skip any overlapping lot, preserving the public site as the source of truth.
	for road in world.roads:
		var width := float(world.cfg["city"]["branch_road_half_width"]) if road.get("kind","") == "branch" else float(world.cfg["terrain"]["template_road_half_width"])
		for strip in Geometry2D.offset_polyline(road["path"],width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
			if not Geometry2D.intersect_polygons(polygon,strip).is_empty(): return false
	return true

static func _append_site(world: RefCounted, base: Vector2, half: Vector2, candidates: Array, site_id: String, kind: String, name: String, community_id: String) -> void:
	for delta in candidates:
		var center := base+Vector2(delta)
		var polygon := box(center,half)
		if not _clear_site(world,polygon): continue
		world.public_sites.append({"id":site_id,"kind":kind,"name":name,"position":[center.x,center.y],
			"polygon":polygon,"entrance":[base.x,base.y],"community_id":community_id,"active":false,"frame":0})
		return

static func populate(world: RefCounted) -> void:
	var cfg: Dictionary = world.cfg["city"]
	var t: Dictionary = world.cfg["terrain"]
	var offset: float = float(t["template_road_bank_offset"])+float(cfg["neighborhood_depth"])*0.72
	var ys: Array = [1.2,4.65,8.1,11.55,15.0,18.45,21.9,25.35]
	var bend := 0.0
	match world.terrain.family:
		"lake_basin":
			offset += 0.85
			ys = [1.2,4.5,7.8,11.1,14.4,17.7,21.0,24.3]
			bend = -0.32
		"forest_ridge":
			offset += 1.15
			ys = [0.9,4.35,7.8,11.25,14.7,18.15,21.6,25.05]
			bend = 0.42
		"coastal_plain":
			offset += 0.25
			ys = [1.4,4.8,8.2,11.6,15.0,18.4,21.8,25.2]
			bend = 0.18
	for bank: int in [-1,1]:
		var prefix := "west" if bank < 0 else "east"
		var names := ["苔阶","回声坡","石榴台","云栈","风铃坡","溪上台","白栎坡","月桂台"] if bank < 0 else ["晴岬","晚潮台","芦灯坡","映泉台","长风台","浅湾坡","金穗台","望星坡"]
		for index in range(ys.size()):
			var cid := "%s-terrace-%d" % [prefix,index+1]
			world.communities[cid] = {"id":cid,"bank":bank,"name":names[index],"members":[],"parent_id":prefix+"-2"}
			var y := float(ys[index])
			var x: float = world.terrain.river_x(y)+float(bank)*offset
			var node_id := "%s-terrace-node-%d" % [prefix,index+1]
			world.nodes[node_id] = [x,y]
			var main_x: float = world.terrain.river_x(y)+float(bank)*float(t["template_road_bank_offset"])
			var link_path := PackedVector2Array([Vector2(main_x,y)])
			if absf(bend) > 0.001:
				link_path.append(Vector2(lerpf(main_x,x,0.5),y+bend))
			link_path.append(Vector2(x,y))
			world.roads.append({"id":"%s-terrace-link-%d" % [prefix,index+1],
				"from":"%s-1" % prefix,"to":node_id,
				"path":link_path,"bridge":false,"kind":"branch"})
			if index > 0:
				var previous_y := float(ys[index-1])
				var previous_x: float = world.terrain.river_x(previous_y)+float(bank)*offset
				var terrace_path := PackedVector2Array([Vector2(previous_x,previous_y)])
				if absf(bend) > 0.001:
					terrace_path.append(Vector2(lerpf(previous_x,x,0.5),lerpf(previous_y,y,0.5)+bend))
				terrace_path.append(Vector2(x,y))
				world.roads.append({"id":"%s-terrace-road-%d" % [prefix,index+1],
					"from":"%s-terrace-node-%d" % [prefix,index],"to":node_id,
					"path":terrace_path,"bridge":false,"kind":"branch"})
			var lot_center := Vector2(x-float(bank)*float(t["template_lot_road_offset"]),y+0.9)
			var half := Vector2(float(t["template_lot_half_width"]),float(t["template_lot_half_length"]))
			var polygon := box(lot_center,half)
			if world.terrain.valid_footprint(polygon):
				world.lots.append({"id":"%s-terrace-lot-%d" % [prefix,index+1],
					"center":[lot_center.x,lot_center.y],"polygon":polygon,
					"entrance":[x,y],"use":"residential","community_id":cid,"bank":bank,"occupant":""})
			if index > 0:
				var previous := float(ys[index-1])
				var polygon_block := PackedVector2Array()
				polygon_block.append(Vector2(world.terrain.river_x(previous)+bank*float(t["template_road_bank_offset"]),previous))
				polygon_block.append(Vector2(world.terrain.river_x(y)+bank*float(t["template_road_bank_offset"]),y))
				polygon_block.append(Vector2(x,y))
				polygon_block.append(Vector2(world.terrain.river_x(previous)+bank*offset,previous))
				world.blocks.append({"id":"%s-terrace-block-%d" % [prefix,index],"polygon":polygon_block,"community_id":cid})
		var site_y := float(ys[3])
		var site_x: float = world.terrain.river_x(site_y)+float(bank)*offset
		var park_name := "湖光台地公园" if world.terrain.family == "lake_basin" else ("林脊听风园" if world.terrain.family == "forest_ridge" else ("潮汐绿湾" if world.terrain.family == "coastal_plain" else "回声台地公园"))
		_append_site(world,Vector2(site_x,site_y),Vector2(0.9,0.82),
			[Vector2(bank*2.1,0.0),Vector2(bank*2.8,0.4),Vector2(bank*1.9,1.5),Vector2(bank*3.2,-1.2)],
			prefix+"-terrace-park","park",park_name,prefix+"-terrace-4")
		var civic_name := "湖心共鸣屋" if world.terrain.family == "lake_basin" else ("林岭声部所" if world.terrain.family == "forest_ridge" else ("海湾潮声站" if world.terrain.family == "coastal_plain" else "台地音乐亭"))
		_append_site(world,Vector2(site_x,site_y+3.45),Vector2(0.58,0.62),
			[Vector2(bank*2.1,0.0),Vector2(bank*2.8,-0.3),Vector2(bank*1.9,1.25),Vector2(bank*3.2,1.8)],
			prefix+"-terrace-civic","civic",civic_name,prefix+"-terrace-5")
