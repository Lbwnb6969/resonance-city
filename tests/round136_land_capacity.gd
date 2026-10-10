extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var saved: Dictionary = FileAccess.open("res://.git/任务备份/round136/original_scale_final.bin",FileAccess.READ).get_var()
	var city := World.new(saved["seed_hex"],false)
	city.restore(saved)
	var reasons: Dictionary = {}
	var legal := 0
	var near_unfrozen := 0
	var probes: Array = []
	for y in range(-7,72):
		for x in range(-7,72):
			var p := Vector2(x*0.5,y*0.5)
			var check := city.placement(p)
			if not check["allowed"]:
				var reason: String = check["reason"]
				reasons[reason] = int(reasons.get(reason,0))+1
				continue
			legal += 1
			probes.append(p)
			for id in city.index.query_circle(p,2.4):
				if p.distance_to(WorldCoupling.position_of(city.by_id[id])) <= 2.4 and not city.frozen(id):
					near_unfrozen += 1
					break
	var result := {"buildings":city.buildings.size(),"legal_grid_candidates":legal,"near_unfrozen":near_unfrozen,"reasons":reasons,"radius":city.cfg["space"]["residential_radius"]}
	FileAccess.open("res://验证记录/连续河谷/第136轮_土地容量诊断.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("LAND_CAPACITY ",JSON.stringify(result))
	quit()
