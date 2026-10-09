class_name ContinuousValleyContract
extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Synth = preload("res://scripts/audio/continuous_synth.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")
const Config = preload("res://scripts/world/world_values.gd")
var failures: Array[String] = []
var checks := 0

func check(condition: bool, name: String) -> void:
	checks += 1
	if not condition: failures.append(name)

func _initialize() -> void:
	call_deferred("run_checks")

func entity(id: String, midi: int, x: float, type: String = "residential") -> Dictionary:
	return {"district_id":id,"current_midi":midi,"position":[x,0.0],"radius":0.45,"type":type,"vitality":50.0}

func run_checks() -> void:
	var coupling := Coupling.new()
	var a := entity("a",48,0.0)
	var b := entity("b",48,0.9)
	for fixture in [[48,100.0,59.0],[52,85.0,56.0],[54,0.0,42.5]]:
		b["current_midi"] = fixture[0]
		var edge := [{"a":"a","b":"b","coupling":coupling.coefficient(a,b)}]
		var r := coupling.resonance([a,b],edge)
		var v := coupling.vitality([a,b],edge,r)
		check(absf(r-float(fixture[1])) < 1e-6 and absf(float(v["a"])-float(fixture[2])) < 1e-6,"retained R/V fixture "+str(fixture[0]))
	check(coupling.distance_weight(4.0) > 0.0 and coupling.distance_weight(4.0001) == 0.0,"inclusive cutoff")
	check(absf(coupling.distance_weight(3.0)-0.1243530480442327) < 1e-12,"formula reference")
	b["type"] = "industrial"
	check(absf(coupling.coefficient(a,b,{"terrain_factor":1.15})-2.99) < 1e-6,"industrial water coefficient")
	check(coupling.coefficient(a,b,{"occlusion":0.0}) == 0.0,"occlusion zero")
	var e := entity("e",52,0.9)
	var f := entity("f",54,3.9)
	var star := [{"a":"a","b":"e","coupling":2.0},{"a":"a","b":"f","coupling":coupling.distance_weight(3.0)}]
	var star_r := coupling.resonance([a,e,f],star)
	var star_v := coupling.vitality([a,e,f],star,star_r)
	check(absf(star_r-80.02436325567872) < 1e-6 and star_v == {"a":48.0,"e":56.0,"f":43.0},"given-edge star and absolute vitality")
	check(coupling.coefficient(a,f,{"sigma_a":2.0,"sigma_b":1.0}) == coupling.coefficient(f,a,{"sigma_a":1.0,"sigma_b":2.0}),"symmetric height kernel")
	var world := World.new()
	check(world.terrain.buildable_ratio() >= 0.45,"buildable terrain fraction")
	check(world.communities.size() == 6 and world.lots.size() > 40,"six planned communities with frontage")
	var shared := true
	for road in world.roads:
		var from: Array = world.nodes[road["from"]]
		var to: Array = world.nodes[road["to"]]
		var path: PackedVector2Array = road["path"]
		shared = shared and path[0].distance_to(Vector2(from[0],from[1])) < 1e-5 and path[-1].distance_to(Vector2(to[0],to[1])) < 1e-5
	check(shared,"physical edges share endpoint nodes")
	var lot: Dictionary = world.lots[12]
	var p := Vector2(float(lot["center"][0])+0.043,float(lot["center"][1])-0.031)
	check(world.placement(p)["allowed"],"fractional placement inside true lot")
	var model := Model.new(world)
	var submission := model.submit({"kind":"seed","position":[p.x,p.y],"midi":48})
	check(submission["accepted"],"seed accepted for future phrase")
	print("SUBMISSION ",JSON.stringify(submission)," PLACEMENT ",JSON.stringify(world.placement(p)))
	var state: Dictionary = {}
	var frame := model.phrase_frames
	model.render_block(state,frame-2,4,int(Config.load_values()["timing"]["sample_rate"]))
	check(world.buildings.size() == 1 and world.buildings[0]["position"] == [p.x,p.y],"atomic birth retains exact float coordinates")
	if world.buildings.is_empty():
		print("EARLY FAIL ",JSON.stringify(failures)," pending=",JSON.stringify(world.pending))
		quit(1)
		return
	check(model.presentation_world(frame-1).buildings.is_empty() and model.presentation_world(frame).buildings.size() == 1,"visual commit follows audible frame")
	var id: String = world.buildings[0]["district_id"]
	var community: String = world.buildings[0]["community_id"]
	world.request({"kind":"retune","id":id,"midi":52},frame*2)
	world.settle(frame*2)
	check(world.by_id[id]["community_id"] == community and world.buildings.size() == 2,"stable planning community and legal automatic growth")
	check(world.by_id[id]["type"] == lot["use"],"land use survives retuning independently of pitch")
	var saved := world.snapshot()
	var copy: ContinuousWorld = world.fork()
	check(JSON.stringify(saved) == JSON.stringify(copy.snapshot()),"versioned snapshot and RNG round trip")
	world.settle(frame*3)
	copy.settle(frame*3)
	check(JSON.stringify(world.snapshot()) == JSON.stringify(copy.snapshot()),"deterministic growth after restored snapshot")
	check(not world.placement(Coupling.position_of(world.buildings[0]))["allowed"],"complete occupied footprint rejected")
	check(not world.placement(Vector2(world.terrain.river_x(14.0),14.0))["allowed"],"water placement rejected")
	var before := JSON.stringify(world.snapshot())
	var free: Dictionary = {}
	for candidate in world.lots:
		if candidate["occupant"] == "":
			free = candidate
			break
	var preview := Model.new(world).forecast({"kind":"seed","position":free["center"],"midi":55},{},frame*4,2205)
	check(not preview.is_empty() and JSON.stringify(world.snapshot()) == before,"future audio uses fork without mutating city or random streams")
	world.request({"kind":"bridge"},frame*4)
	world.settle(frame*4)
	check(world.bridge and world.roads[-1]["from"] == "west-2" and world.roads[-1]["to"] == "east-2","bridge joins actual shore nodes")
	var y := 14.0
	var left := Vector2(world.terrain.river_x(y)-2.4,y)
	var right := Vector2(world.terrain.river_x(y)+2.4,y)
	check(float(world.terrain.environment(left,right,false)["occlusion"]) == 0.0 and float(world.terrain.environment(left,right,true)["occlusion"]) == 1.0,"bridge changes river crossing mask")
	# Compare forecast against a separately advanced live renderer at its real boundary.
	var live_model := Model.new(world.fork())
	var preview_at := live_model.next_boundary-512
	var operation := {"kind":"retune","id":id,"midi":55}
	var forecast := live_model.forecast(operation,{},preview_at,256)
	var expected_model := Model.new(world.fork())
	expected_model.submit(operation)
	var expected_state: Dictionary = {}
	expected_model.render_block(expected_state,preview_at,512,22050)
	var expected := expected_model.render_block(expected_state,expected_model.next_boundary,256,22050)
	check(forecast == expected,"forecast PCM matches separately committed live path including environment bed")
	# A given-edge fixture checks N12 without claiming its abstract positions are legal lots.
	var graph := World.new()
	var center := entity("center",48,8.0)
	graph.by_id["center"] = center
	graph.index.put("center",Vector2(8,0),0.45)
	for i in range(13):
		var other := entity("n%02d" % i,54 if i == 12 else 48,8.0+0.1*(i+1))
		graph.by_id[other["district_id"]] = other
		graph.index.put(other["district_id"],Coupling.position_of(other),0.45)
		graph.edge_cache["center:"+other["district_id"]] = {"a":"center","b":other["district_id"],"coupling":2.0-0.1*i}
	check(graph.near_edges("center").size() == 12 and not graph.frozen("center"),"far dissonance outside N12 does not freeze")
	var homogeneous := graph.musicality()
	check(absf(float(homogeneous["center"]["M"])-0.7) < 1e-6 and float(homogeneous["center"]["dv_scale"]) == 0.5,"homogeneity computed from pre-M neighbors without feedback")
	var music_edges := graph.musical_edges(homogeneous)
	check(absf(float(music_edges[0]["coupling"])-float(graph.edges()[0]["coupling"])*0.7) < 1e-6,"symmetric single M multiplier")
	var unison_edges := [{"a":"a","b":"b","coupling":1.4}]
	b["current_midi"] = 48
	var reduced := coupling.vitality([a,b],unison_edges,100.0,{}, {"a":{"dv_scale":0.5},"b":{"dv_scale":0.5}})
	check(reduced == {"a":55.0,"b":55.0},"active homogeneity has separate vitality fixture 55, not legacy 59")
	graph.by_id["n00"]["current_midi"] = 54
	check(graph.frozen("center"),"near dissonance inside N12 freezes")
	# Calibrate once, before live output, using a deliberately coherent full-budget
	# reference; this is a signal fixture, not a claimed naturally grown city.
	var reference: Array[Dictionary] = []
	for i in range(24):
		var building: Dictionary = world.buildings[0].duplicate(true)
		building["district_id"] = "reference-%d" % i
		building["position"] = world.lots[i]["center"].duplicate()
		building["footprint"] = [building["position"].duplicate()]
		building["current_midi"] = 48
		building["form"] = "腔"
		building["birth_frame"] = -22050
		reference.append(building)
	var source := Synth.new(reference)
	var calibration := Calibration.for_synth(source)
	check(is_finite(float(calibration["gain"])) and float(calibration["gain"]) > 0.0,"finite fixed reference calibration")
	calibration["reference"] = "24 coherent C3 sources at planned lot centers, chamber layers; not a playable-city completion claim"
	calibration["contract_sha256"] = FileAccess.get_file_as_string("res://数据/spec_values.json").sha256_text()
	var calibration_file := FileAccess.open("res://数据/valley_audio_calibration.json",FileAccess.WRITE)
	calibration_file.store_string(JSON.stringify(calibration,"\t")+"\n")
	calibration_file.close()
	DirAccess.make_dir_recursive_absolute("res://验证记录/连续河谷")
	var evidence := {"checks":checks,"failures":failures,"lots":world.lots.size(),"communities":world.communities.size(),
		"buildable_ratio":world.terrain.buildable_ratio(),"calibration":calibration,"scope":"first controlled valley; not full P0, five terrain families or city-scale performance"}
	var file := FileAccess.open("res://验证记录/连续河谷/基础.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"\t")+"\n")
	file.close()
	print("CONTINUOUS VALLEY ",checks," checks; failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
