class_name GardenNeighborhood
extends RefCounted
## A second landward street loop; its two communities remain stable during retuning.
static func populate(world: RefCounted) -> void:
	var cfg: Dictionary = world.cfg["city"]
	var t: Dictionary = world.cfg["terrain"]
	var offset := float(t["template_road_bank_offset"])+float(cfg["neighborhood_depth"])+float(cfg["garden_street_depth"])
	for bank: int in [-1,1]:
		var prefix := "west" if bank < 0 else "east"
		for region in range(1,3):
			var cid := "%s-garden-%d" % [prefix,region]
			var names := ["林前","松径"] if bank < 0 else ["花浦","长夏"]
			world.communities[cid] = {"id":cid,"bank":bank,"name":names[region-1],"members":[],"parent_id":prefix+"-2"}
		for index in range(1,4):
			var old: Array = world.nodes["%s-outer-%d" % [prefix,index]]
			var p := Vector2(world.terrain.river_x(float(old[1]))+bank*offset,float(old[1]))
			var id := "%s-garden-%d" % [prefix,index]
			world.nodes[id] = [p.x,p.y]
			# The middle connector would cut the existing civic reservation. Use the end junctions.
			if index in [1,3]:
				world.roads.append({"id":"%s-garden-cross-%d" % [prefix,index],"from":"%s-outer-%d" % [prefix,index],"to":id,
					"path":PackedVector2Array([Vector2(old[0],old[1]),p]),"bridge":false,"kind":"branch"})
			if index == 1: continue
			var previous: Array = world.nodes["%s-garden-%d" % [prefix,index-1]]
			var path := PackedVector2Array()
			for sample in range(17):
				var y := lerpf(float(previous[1]),p.y,float(sample)/16.0)
				path.append(Vector2(world.terrain.river_x(y)+bank*offset,y))
			world.roads.append({"id":"%s-garden-road-%d" % [prefix,index],"from":"%s-garden-%d" % [prefix,index-1],"to":id,
				"path":path,"bridge":false,"kind":"branch"})
		var polygon := PackedVector2Array()
		for sample in range(25):
			var y := lerpf(8.0,20.0,float(sample)/24.0)
			polygon.append(Vector2(world.terrain.river_x(y)+bank*(offset-float(cfg["garden_street_depth"])),y))
		for sample in range(24,-1,-1):
			var y := lerpf(8.0,20.0,float(sample)/24.0)
			polygon.append(Vector2(world.terrain.river_x(y)+bank*offset,y))
		world.blocks.append({"id":prefix+"-garden-block","polygon":polygon,"community_id":prefix+"-garden-1"})
		for row in range(int(cfg["garden_lot_rows"])):
			var y := 8.8+row*1.6
			var x: float = world.terrain.river_x(y)+bank*offset
			for side in [-1,1]:
				var center := Vector2(x+side*float(t["template_lot_road_offset"]),y)
				var half := Vector2(t["template_lot_half_width"],t["template_lot_half_length"])
				var region := 1 if y < 14.0 else 2
				world.lots.append({"id":"%s-garden-lot-%d-%d" % [prefix,row,side],"center":[center.x,center.y],
					"polygon":PackedVector2Array([center-half,center+Vector2(half.x,-half.y),center+half,center+Vector2(-half.x,half.y)]),"entrance":[x,y],"use":"residential",
					"community_id":"%s-garden-%d" % [prefix,region],"bank":bank,"occupant":""})
