extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var world := World.new("2026100900000062",true,"river_valley")
	world.build_first_composition_starter()
	var opportunity := First.opportunities(world)
	print("FIRST "+JSON.stringify({"count":world.buildings.size(),"phrase":world.phrase_index,"opportunities":opportunity}))
	var p: Dictionary = opportunity["public_candidates"][0]
	print("CIVIC_REQUEST "+JSON.stringify(world.request({"kind":"civic","position":p["position"]},int(world.cfg["timing"]["phrase_frames"]))))
	for i in range(4):
		world.settle((world.phrase_index+1)*int(world.cfg["timing"]["phrase_frames"]))
		var states: Array = []
		for cid in opportunity["community_ids"]: states.append({"state":Rules.status(world,cid),"facility":Rules.facilities(world,cid)})
		print("GROW "+JSON.stringify({"phrase":world.phrase_index,"count":world.buildings.size(),"status":states}))
		var choices := First.opportunities(world)
		if world.phrase_index == 1:
			for court in world.fabric_cache.get("courtyards",[]):
				if str(court.get("community_id","")) == "west-1": print("COURT "+JSON.stringify({"court":court,"candidate":world.planning_candidate(Vector2(float(court["center"][0]),float(court["center"][1])))}))
		for choice in choices["seed_candidates"]:
			if str(choice["community_id"]) == "west-1": print("WEST_SOUND "+JSON.stringify({"phrase":world.phrase_index,"seed":choice,"reservation":First.warm_reservation(world,Vector2(float(choice["position"][0]),float(choice["position"][1])))}))
	quit()
