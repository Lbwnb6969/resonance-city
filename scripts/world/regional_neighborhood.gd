extends RefCounted
## Reuse a controlled district template along the same river, with fresh stable IDs.
## Only invoked for a new regional Demo; existing authored cities retain their plan.
static func _point(world: RefCounted,value: Variant,offset: float) -> Vector2:
	var p: Vector2 = value if value is Vector2 else Vector2(float(value[0]),float(value[1]))
	var bank_offset: float = p.x-world.terrain.river_x(p.y)
	var shore_change: float = world.terrain.river_width(p.y+offset)-world.terrain.river_width(p.y)
	return Vector2(world.terrain.river_x(p.y+offset)+bank_offset+signf(bank_offset)*shore_change,p.y+offset)

static func _polygon(world: RefCounted,value: PackedVector2Array,offset: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in value: result.append(_point(world,p,offset))
	return result

static func populate(world: RefCounted,count: int) -> void:
	if int(world.cfg["city"].get("regional_count",1)) >= count: return
	# WorldValues shares a read-only template; regional settings belong to this city.
	world.cfg = world.cfg.duplicate(true)
	var span: float = float(world.cfg["terrain"]["template_land_max"])-float(world.cfg["terrain"]["template_land_min"])
	world.cfg["city"]["regional_count"] = count
	world.cfg["terrain"]["template_land_max_y"] = float(world.cfg["terrain"]["template_land_max"])+span*(count-1)
	world.terrain.cfg = world.cfg["terrain"]
	world.terrain.configure(world.terrain.noise_seed,world.terrain.river_phase,world.terrain.family)
	var base_nodes: Dictionary = world.nodes.duplicate(true)
	var base_communities: Dictionary = world.communities.duplicate(true)
	var base_records: Dictionary = {}
	for field in ["roads","lots","blocks","green_corridors","centers","public_sites"]:
		base_records[field] = world.get(field).duplicate(true)
	for region in range(1,count):
		var prefix := "reach-%d-" % region
		var offset := span*region
		for id in base_nodes:
			var p := _point(world,base_nodes[id],offset)
			world.nodes[prefix+str(id)] = [p.x,p.y]
		for id in base_communities:
			var community: Dictionary = base_communities[id].duplicate(true)
			community["id"] = prefix+str(id)
			community["name"] = ["中游·","上游·"][posmod(region-1,2)]+str(community["name"])
			community["members"] = []
			for key in ["parent_id","center_id"]:
				if community.has(key): community[key] = prefix+str(community[key])
			world.communities[community["id"]] = community
		for field in base_records:
			for record in base_records[field]:
				var item: Dictionary = record.duplicate(true)
				for key in ["id","from","to","community_id","node_id"]:
					if item.has(key): item[key] = prefix+str(item[key])
				for key in ["position","center","entrance"]:
					if item.has(key):
						var p := _point(world,item[key],offset)
						item[key] = [p.x,p.y]
				for key in ["polygon","path"]:
					if item.has(key): item[key] = _polygon(world,item[key],offset)
				if item.has("occupant"): item["occupant"] = ""
				if item.has("covered"): item["covered"] = []
				if item.has("community_ids"):
					var ids: Array[String] = []
					for id in item["community_ids"]: ids.append(prefix+str(id))
					item["community_ids"] = ids
				if field == "public_sites":
					item["active"] = false
					item["frame"] = 0
					item["name"] = ["中游·","上游·"][posmod(region-1,2)]+str(item["name"])
				world.get(field).append(item)
		# Continuous bank roads connect each reach; never add a cross-water edge.
		for bank: int in [-1,1]:
			var side := "west" if bank < 0 else "east"
			var previous_prefix := "" if region == 1 else "reach-%d-" % (region-1)
			var from := previous_prefix+side+"-4"
			var to := prefix+side+"-1"
			var a: Array = world.nodes[from]
			var b: Array = world.nodes[to]
			var path := PackedVector2Array()
			for step in range(25):
				var y := lerpf(float(a[1]),float(b[1]),float(step)/24.0)
				var bank_distance := lerpf(absf(float(a[0])-world.terrain.river_x(float(a[1]))),absf(float(b[0])-world.terrain.river_x(float(b[1]))),float(step)/24.0)
				path.append(Vector2(world.terrain.river_x(y)+bank*bank_distance,y))
			path[0] = Vector2(float(a[0]),float(a[1]))
			path[-1] = Vector2(float(b[0]),float(b[1]))
			world.roads.append({"id":prefix+side+"-connection","from":from,"to":to,"path":path,"bridge":false,"kind":"branch"})
	world.network.rebuild(world.nodes,world.roads,world.terrain)
	world.rebuild_graph()
	world._refresh_public_network()
	world.refresh_fabric()
