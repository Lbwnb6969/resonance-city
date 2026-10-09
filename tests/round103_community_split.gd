extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)

func _connected(ids: Array) -> bool:
	if ids.is_empty(): return false
	var seen: Dictionary = {str(ids[0]):true}
	var queue: Array[String] = [str(ids[0])]
	while not queue.is_empty():
		var current: String = str(queue.pop_front())
		for raw_id in ids:
			var id := str(raw_id)
			if seen.has(id): continue
			if not Coupling.position_of(current_buildings[id]).distance_to(Coupling.position_of(current_buildings[current])) <= 3.25: continue
			seen[id] = true
			queue.append(id)
	return seen.size() == ids.size()

var current_buildings: Dictionary = {}

func _run() -> void:
	var world := World.new("2026101000000103",false,"river_valley")
	var parent_id := "west-1"
	world.communities[parent_id] = {"id":parent_id,"bank":-1,"name":"西岸一","members":[],"parent_id":""}
	var ids: Array = []
	for row in range(9):
		for column in range(9):
			var id := "building-%03d" % (row*9+column)
			var position := [20.0+float(column)*1.2,10.0+float(row)*1.2]
			var building := {"district_id":id,"position":position,"radius":0.45,"current_midi":48+(row+column)%5,"base_midi":48+(row+column)%5,"type":"residential","form":"群","community_id":parent_id,"family_id":"family-"+id,"expression":"bright","family_anchor":false,"voice_level":0.2,"vitality":100.0,"placement_tier":"L1","form_count":0,"birth_frame":0,"era":1}
			ids.append(id)
			current_buildings[id] = building
			world.buildings.append(building)
			world.by_id[id] = building
			world.communities[parent_id]["members"].append(id)
			world.index.put(id,Vector2(position[0],position[1]),0.45)
	world.landmarks.append({"id":"landmark-memory","position":[25.0,15.0],"radius":1.0,"frame":0,"era":1,"voice_level":0.34,"source_communities":[parent_id],"motif":[{"id":"historic","midi":61}]})
	var model := Model.new(world)
	var split_events: Array = world.split_oversized_communities(12345)
	var children: Array = world.communities[parent_id].get("split_children",[])
	_check(split_events.size() == 1,"one split event")
	_check(children.size() == 3,"81 buildings become three child communities")
	_check(not bool(world.communities[parent_id].get("active",true)),"parent is retained as inactive history")
	var seen: Dictionary = {}
	var max_child_size := 0
	for child_id in children:
		var members: Array = world.communities[child_id]["members"]
		max_child_size = maxi(max_child_size,members.size())
		_check(members.size() > 0 and members.size() <= 40,"child size bounded")
		_check(_connected(members),"child remains spatially connected")
		for id in members:
			seen[id] = int(seen.get(id,0))+1
			_check(str(world.by_id[id]["community_id"]) == str(child_id),"building points to child")
		var theme: Array = world.community_theme(str(child_id))
		_check(not theme.is_empty() and int(theme[0]) == 61,"parent landmark motif follows child lineage")
	_check(seen.size() == ids.size(),"all buildings assigned")
	_check(seen.values().all(func(value: int) -> bool: return value == 1),"members mutually exclusive")
	_check(world.active_community_count() == children.size(),"active community count excludes parent")
	var restored: World = world.fork()
	_check(restored.communities[parent_id].get("split_children",[]) == children,"split lineage survives snapshot")
	_check(restored.active_community_count() == children.size(),"restored active count excludes parent")
	var render_state: Dictionary = {}
	model.render_block(render_state,int(world.cfg["timing"]["phrase_frames"]),1,int(world.cfg["timing"]["sample_rate"]))
	_check(model.transition_total >= roundi(0.08*float(world.cfg["timing"]["sample_rate"])),"split event gets structural audio seam")
	print("COMMUNITY_SPLIT ",JSON.stringify({"passed":failures.is_empty(),"children":children,"counts":children.map(func(child_id: String) -> int: return world.communities[child_id]["members"].size()),"max_child_size":max_child_size,"active_communities":world.active_community_count(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
