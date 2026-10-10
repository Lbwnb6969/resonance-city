extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var world := World.new("2026100900000062")
	var original := "--original" in OS.get_cmdline_user_args()
	if original: world.build_expanded_town()
	else: world.build_regional_town()
	var cache_prefix := "original_scale" if original else "scale"
	var phrase: int = world.cfg["timing"]["phrase_frames"]
	var history: Array = []
	var total := Time.get_ticks_usec()
	var max_ms := 0.0
	for i in range(1,301):
		var begin := Time.get_ticks_usec()
		world.settle(i*phrase)
		var elapsed := float(Time.get_ticks_usec()-begin)/1000.0
		max_ms = maxf(max_ms,elapsed)
		history.append({"phrase":i,"buildings":world.buildings.size(),"settle_ms":elapsed,"profile":world.settle_profile.duplicate()})
		if i%12 == 0 or world.buildings.size() >= 1500:
			print("SCALE_GROWTH phrase=",i," buildings=",world.buildings.size()," ms=",elapsed," profile=",JSON.stringify(world.settle_profile))
			FileAccess.open("res://.git/任务备份/round136/"+cache_prefix+"_checkpoint.bin",FileAccess.WRITE).store_var(world.snapshot())
		if world.buildings.size() >= 1500: break
	var legal := true
	var overlaps := 0
	var compact := 0
	var bounds := Rect2(WorldCoupling.position_of(world.buildings[0]),Vector2.ZERO)
	for building in world.buildings:
		var p := WorldCoupling.position_of(building)
		bounds = bounds.expand(p)
		legal = legal and world.SpatialPlanning.exclusion(world,world.building_polygon(p)).is_empty()
		var neighbors := 0
		for id in world.index.query_circle(p,1.8):
			if id == str(building["district_id"]): continue
			var other := WorldCoupling.position_of(world.by_id[id])
			if p.distance_to(other) < 0.78-0.000001: overlaps += 1
			if p.distance_to(other) <= 1.8: neighbors += 1
		if neighbors >= 2: compact += 1
	FileAccess.open("res://.git/任务备份/round136/"+cache_prefix+"_final.bin",FileAccess.WRITE).store_var(world.snapshot())
	var result := {"reached_1500":world.buildings.size() >= 1500,"all_legal":legal,"overlap_pairs":overlaps/2,"buildings":world.buildings.size(),"compact":compact,"communities":world.communities.size(),"active_communities":world.active_community_count(),"bounds":str(bounds),"phrase":world.phrase_index,"max_settle_ms":max_ms,"total_ms":float(Time.get_ticks_usec()-total)/1000.0,"history":history,"source_sha256":FileAccess.get_sha256("res://scripts/world/continuous_world.gd")}
	FileAccess.open("res://验证记录/连续河谷/第136轮_"+("合法成长规模_原版" if original else "三河段合法成长规模")+".json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("SCALE_GROWTH_RESULT ",JSON.stringify(result.duplicate().merged({"history":"see evidence"},true)))
	quit()
