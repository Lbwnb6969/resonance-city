class_name TerraceNeighborhood
extends RefCounted
## A second-scale neighborhood layer: inner terraces add stable communities and real branch roads.
static func box(p: Vector2, half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([p-half,p+Vector2(half.x,-half.y),p+half,p+Vector2(-half.x,half.y)])

static func populate(world: RefCounted) -> void:
	var cfg: Dictionary = world.cfg["city"]
	var t: Dictionary = world.cfg["terrain"]
	var offset := float(t["template_road_bank_offset"])+float(cfg["neighborhood_depth"])*0.72
	var ys := [1.2,4.65,8.1,11.55,15.0,18.45,21.9,25.35]
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
			world.roads.append({"id":"%s-terrace-link-%d" % [prefix,index+1],
				"from":"%s-1" % prefix,"to":node_id,
				"path":PackedVector2Array([Vector2(main_x,y),Vector2(x,y)]),"bridge":false,"kind":"branch"})
			if index > 0:
				var previous_y := float(ys[index-1])
				var previous_x: float = world.terrain.river_x(previous_y)+float(bank)*offset
				world.roads.append({"id":"%s-terrace-road-%d" % [prefix,index+1],
					"from":"%s-terrace-node-%d" % [prefix,index],"to":node_id,
					"path":PackedVector2Array([Vector2(previous_x,previous_y),Vector2(x,y)]),"bridge":false,"kind":"branch"})
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
