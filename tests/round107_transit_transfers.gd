extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _run() -> void:
	var world := World.new("2026101000000112",true,"river_valley")
	world.build_expanded_town()
	var transfer_links := 0
	var shared_stops: Dictionary = {}
	for line in world.transit_lines:
		for transfer in line.get("transfer_stops",[]):
			transfer_links += 1
			shared_stops[str(transfer.get("stop_id",""))] = true
	_check(transfer_links >= 2,"expanded lines expose shared transfer links")
	_check(shared_stops.size() >= 1,"at least one physical stop connects multiple lines")
	var buses: Array = []
	for index in range(6):
		buses.append(Traveler.new("bus",index))
	var max_transfers := 0
	var transfer_purpose := ""
	var transfer_stop := ""
	var transfer_line := -1
	var transfer_path_size := 0
	for step in range(1,2401):
		var seconds := float(step)*0.1
		for bus in buses:
			var result: Dictionary = bus.advance(world,seconds)
			if result.is_empty(): continue
			if bus.transfer_count > max_transfers:
				max_transfers = bus.transfer_count
				transfer_purpose = str(result.get("purpose",""))
				transfer_stop = str(result.get("transfer_stop",""))
				transfer_line = bus.line_index
				transfer_path_size = bus.path.size()
	_check(max_transfers >= 1,"a vehicle performs a deterministic line transfer")
	_check(transfer_purpose.begins_with("换乘至"),"transfer exposes a readable purpose")
	_check(shared_stops.has(transfer_stop),"transfer happens at a shared physical stop")
	_check(transfer_line >= 0 and transfer_line < world.transit_lines.size(),"transfer selects an active line")
	_check(transfer_path_size > 1,"transferred vehicle receives a physical route")
	var selected: Traveler = buses[0]
	for bus in buses:
		if bus.transfer_count > 0:
			selected = bus
			break
	var saved := selected.snapshot()
	var restored := Traveler.new("bus",selected.ordinal)
	restored.restore(saved)
	_check(restored.transfer_count == selected.transfer_count and restored.transfer_target == selected.transfer_target and restored.transfer_stop == selected.transfer_stop,"transfer state survives traveler snapshot")
	var forked: World = world.fork()
	_check(forked.transit_lines == world.transit_lines,"transfer topology survives world fork")
	_check(forked.transit_lines.any(func(line: Dictionary) -> bool: return not line.get("transfer_stops",[]).is_empty()),"fork retains transfer metadata")
	var classical := World.new("2026101000000113",true,"river_valley")
	classical.build_starter("bright")
	_check(classical.vehicle_kind() == "carriage","classical city uses carriages")
	classical.era = 4
	_check(classical.vehicle_kind() == "tram","industrial era uses trams")
	classical.era = 5
	_check(classical.vehicle_kind() == "bus","modern era uses buses")
	print("TRANSIT_TRANSFERS ",JSON.stringify({"passed":failures.is_empty(),"transfer_links":transfer_links,"shared_stops":shared_stops,"max_transfers":max_transfers,"purpose":transfer_purpose,"stop":transfer_stop,"line":transfer_line,"path_size":transfer_path_size,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
