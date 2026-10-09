extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")

func _initialize() -> void:
	var world := World.new("2026101000000086",true,"river_valley")
	world.build_expanded_town()
	var phrase_frames := int(world.cfg["timing"]["phrase_frames"])
	var rows: Array = []
	for phrase in range(1,25):
		var started := Time.get_ticks_usec()
		world.settle(phrase_frames*(phrase+1))
		rows.append({"phrase":phrase,"ms":roundf(float(Time.get_ticks_usec()-started)/1000.0),"buildings":world.buildings.size(),"courtyards":world.fabric_cache.get("courtyards",[]).size()})
	print("SCALE_PROFILE ",JSON.stringify({"rows":rows,"final_buildings":world.buildings.size()}))
	quit(0)
