extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Scene = preload("res://scenes/continuous_valley.tscn")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Reference = preload("res://tests/round135_traffic_reference.gd")
var checks: Dictionary = {}
var cases: Array = []
var total_samples := 0
func _initialize() -> void: call_deferred("_run")
func _pair(city: ContinuousWorld,label: String,steps: int) -> void:
 var demos: Array[ContinuousValleyDemo] = []
 for index in range(2):
  var demo: ContinuousValleyDemo = Scene.instantiate()
  demo.session_persistence = false
  root.add_child(demo)
  demo.clock.stop_output()
  demo.model.close_background_settlement()
  demo.set_process(false)
  var copy := city.fork()
  copy.communities = city.communities.duplicate(true)
  demo.model = Model.new(copy)
  demo.shown_world = copy
  for prop in demo.scenery.props.values(): prop.queue_free()
  demo.scenery = ValleyScenery.new() if index == 0 else Reference.scenery_script().new()
  demo.scenery.rebuild(demo)
  demos.append(demo)
 var exact := true
 var props_exact := true
 var times := [0,0]
 var topology_changed := false
 for i in range(steps):
  # Irregular/long frames exercise multiple legs and invalid within-frame subsets.
  var seconds := float(i)/60.0 + (1.7 if i >= steps/2 else 0.0)
  for index in range(2):
   var demo := demos[index]
   if i == steps/4:
    demo.model.world.terrain.river_phase += 0.1
    for prop in demo.scenery.props.values():
     if not prop.has_meta("traveler"):
      prop.set_meta("world_position",Vector2(prop.get_meta("world_position"))+Vector2(0.013,-0.017))
      break
   if i == steps/3:
    demo.model.world.bridge = true
    demo.model.world._refresh_public_network()
    topology_changed = true
   if i == steps*2/3:
    demo.model.world.era = 5
    demo.model.world._refresh_public_network()
   demo.clock.renderer.transport.audible_frame = seconds*22050
   var tick := Time.get_ticks_usec()
   demo.scenery.sync(demo)
   if i > 20: times[index] += Time.get_ticks_usec()-tick
  var a := demos[0].scenery
  var b := demos[1].scenery
  exact = exact and a.snapshot() == b.snapshot()
  for key in a.props:
   var ap: ValleyProp = a.props[key]
   var bp: ValleyProp = b.props[key]
   props_exact = props_exact and ap.position == bp.position and ap.direction == bp.direction and ap.visible == bp.visible and ap.modulate == bp.modulate and ap.active == bp.active and ap.get_meta("world_position") == bp.get_meta("world_position")
  total_samples += 1
 checks[label+"_trajectories"] = exact
 checks[label+"_visual_props"] = props_exact
 checks[label+"_flows"] = demos[0].model.world.snapshot() == demos[1].model.world.snapshot()
 checks[label+"_changes_exercised"] = topology_changed
 cases.append({"name":label,"steps":steps,"actual_us":times[0],"reference_us":times[1],"props":demos[0].scenery.props.size()})
 for demo in demos: demo.queue_free()
 await process_frame
func _direct() -> void:
 var city := World.new()
 city.build_expanded_town()
 city.era = 5
 city._refresh_public_network()
 var old: CityTraveler = Reference.traveler_script().new("car",8)
 var actual := CityTraveler.new("car",8)
 actual.position = Vector2(2.0,2.0)
 old.position = actual.position
 actual.direction = Vector2.RIGHT
 old.direction = actual.direction
 var access := city.network.access(actual.position,false)
 var fleet: Array = []
 for i in range(60):
  fleet.append({"kind":"car","ordinal":i,"position":actual.position+Vector2(float(i)*0.1,0),"direction":Vector2.RIGHT if i%2 == 0 else Vector2.LEFT,"road":access.get("road",""),"priority":i,"road_from":access.get("from",""),"road_to":access.get("to","")})
 var same := true
 for desired in [0.000001,0.016,0.25,2.5,20.0]:
  var exact := {"position":actual.position,"topology":city.network.topology,"access":access,"traffic":fleet}
  same = same and actual._traffic_distance(city,desired,fleet,exact) == old._traffic_distance(city,desired,fleet,exact)
  var stale := exact.duplicate()
  stale["position"] = Vector2(-100,-100)
  stale["traffic"] = []
  same = same and actual._traffic_distance(city,desired,fleet,stale) == old._traffic_distance(city,desired,fleet,stale)
  stale = exact.duplicate()
  stale["topology"] = "old topology"
  stale["traffic"] = []
  same = same and actual._traffic_distance(city,desired,fleet,stale) == old._traffic_distance(city,desired,fleet,stale)
 checks["full_order_ties_long_frames_stale_access"] = same
 var token := city.network.access_token
 city.network.rebuild(city.nodes,city.roads,city.terrain)
 checks["unchanged_topology_retains_token"] = token == city.network.access_token
 var physical := {"position":actual.position,"topology_token":token,"access":access,"traffic":fleet}
 checks["runtime_token_matches_authoritative_access"] = actual._traffic_distance(city,0.25,fleet,physical) == old._traffic_distance(city,0.25,fleet)
 var nodes := city.nodes.duplicate(true)
 nodes["unconnected-token-probe"] = [-99.0,-99.0]
 city.network.rebuild(nodes,city.roads,city.terrain)
 physical["traffic"] = []
 checks["changed_topology_rejects_old_token"] = token != city.network.access_token and actual._traffic_distance(city,0.25,fleet,physical) == old._traffic_distance(city,0.25,fleet)
 checks["runtime_token_excluded_from_dna"] = not city.snapshot().has("access_token")
func _index() -> void:
 var scenery := ValleyScenery.new()
 var traffic: Array = []
 var queries: Dictionary = {}
 for i in range(500):
  var p := Vector2(float((i*71)%231)-115.5,float((i*47)%197)-98.2)*0.13
  traffic.append({"road":str(i%13),"position":p})
  if i%7 == 0: queries[i] = {"position":p+Vector2(0.001,-0.001),"access":{"road":str(i%13)}}
 scenery._index_traffic(traffic,queries)
 var exact := true
 for query in queries.values():
  var expected: Array = []
  for agent in traffic:
   if agent["road"] == query["access"]["road"] or Vector2(query["position"]).distance_squared_to(agent["position"]) <= 1.800001*1.800001: expected.append(agent)
  exact = exact and expected == query["traffic"]
 checks["500_agent_sparse_index_exact_original_order"] = exact
func _disconnected_line() -> void:
 var city := World.new()
 city.build_expanded_town()
 var line: Dictionary = city.transit_lines[0]
 var from: String = line["legs"][0]["from"]
 var at := Vector2(-20,-20)
 city.network.nodes["isolated-test-stop"] = [at.x,at.y]
 city.network.adjacency["isolated-test-stop"] = []
 var traveler := CityTraveler.new("carriage",0)
 traveler.initialized = true
 traveler.line_index = 0
 traveler.line_key = "old line"
 traveler.destination = "isolated-test-stop"
 traveler.position = at
 traveler.path = PackedVector2Array([at-Vector2(1,0),at])
 traveler.lengths = PackedFloat32Array([1.0])
 traveler.total = 1.0
 traveler.distance = 1.0
 var path_before := traveler.path.duplicate()
 traveler._next_bus(city)
 checks["disconnected_waits_without_path_or_destination_jump"] = traveler.wait == 1.0 and traveler.position == at and traveler.destination == "isolated-test-stop" and traveler.path == path_before and traveler.line_key.is_empty()
 traveler._next_bus(city)
 checks["disconnected_retry_keeps_stop"] = traveler.position == at and traveler.destination == "isolated-test-stop" and traveler.path == path_before
 var destination_data: Array = city.network.nodes[from]
 var to := Vector2(destination_data[0],destination_data[1])
 city.network.route_cache["isolated-test-stop>"+from] = {"distance":at.distance_to(to),"edges":["reconnected"],"path":PackedVector2Array([at,to])}
 traveler._next_bus(city)
 checks["reconnected_joins_from_current_position"] = traveler.position == at and traveler.destination == from and traveler.path[0] == at and traveler.path[-1].distance_to(to) < 0.2 and not traveler.line_key.is_empty()
func _run() -> void:
 _disconnected_line()
 _index()
 for family in ValleyTerrain.family_ids():
  var city := World.new("2026100900000062",true,family)
  city.build_starter("bright")
  await _pair(city,family,600)
 var large := World.new()
 large.build_expanded_town()
 var phrase: int = large.cfg["timing"]["phrase_frames"]
 for i in range(1,72): large.settle(i*phrase)
 await _pair(large,"large676",1200)
 _direct()
 var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"cases":cases,"samples":total_samples}
 FileAccess.open("res://验证记录/连续河谷/第135轮_交通等价.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
 print("TRAFFIC_EQUIVALENCE ",JSON.stringify(result))
 quit(0 if result["passed"] else 1)
