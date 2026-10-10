extends SceneTree

const World = preload("res://scripts/world/continuous_world.gd")

var failures: Array[String] = []
var checks := 0

func check(condition: bool, name: String) -> void:
	checks += 1
	if not condition: failures.append(name)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := World.new()
	var preview: Dictionary = world.bridge_preview()
	check(bool(preview.get("available",false)),"bridge preview is available before construction")
	check(preview.get("from_node","") == "west-2" and preview.get("to_node","") == "east-2","preview uses paired road nodes")
	check(preview.get("road_ids",[]).has("west-road-2") and preview.get("road_ids",[]).has("east-road-2"),"preview cites real shore road ids")
	check(preview.get("community_ids",[]) == ["west-2","east-2"],"preview carries affected planning communities")
	check(preview.get("source_topology","") == world.network.topology,"preview pins current road topology")
	check(is_inf(float(preview.get("route_before",0.0))),"unbridged shore route is disconnected")
	check(float(preview.get("crossing_length",0.0)) > 0.0 and float(preview.get("route_after",0.0)) > 0.0,"preview exposes a physical crossing length")
	var bad := world.request({"kind":"bridge","source_topology":"stale-topology"},int(world.cfg["timing"]["phrase_frames"]))
	check(not bool(bad.get("accepted",false)) and str(bad.get("reason","")).contains("变化"),"stale bridge preview is rejected")
	var frame := int(world.cfg["timing"]["phrase_frames"])
	var queued := world.request({"kind":"bridge","source_topology":str(preview["source_topology"])},frame)
	check(bool(queued.get("accepted",false)),"current bridge preview can be queued")
	check(not world.bridge and not world.roads.any(func(road: Dictionary) -> bool: return bool(road.get("bridge",false))),"bridge stays pending before phrase boundary")
	world.settle(frame)
	check(world.bridge and world.roads.any(func(road: Dictionary) -> bool: return bool(road.get("bridge",false))),"bridge commits at phrase boundary")
	var event: Dictionary = world.events.back()
	check(event.get("kind","") == "bridge" and event.get("community_ids",[]) == ["west-2","east-2"],"bridge event records planning scope")
	check(str(event.get("traffic","")) == "两岸联奏线","bridge event records traffic consequence")
	var after := world.bridge_preview()
	check(not bool(after.get("available",true)) and bool(after.get("built",false)),"built bridge no longer offers a preview")
	var from_raw: Array = preview["from_position"]
	var to_raw: Array = preview["to_position"]
	var from := Vector2(float(from_raw[0]),float(from_raw[1]))
	var to := Vector2(float(to_raw[0]),float(to_raw[1]))
	check(is_finite(world.network.walking_distance(from,to)),"bridge invalidates route cache and connects walking graph")
	check(float(world.terrain.environment(from,to,true)["occlusion"]) == 1.0,"bridge crossing is represented in terrain acoustic mask")
	print("ROUND153 BRIDGE PREVIEW checks=",checks," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
