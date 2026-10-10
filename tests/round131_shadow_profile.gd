extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
func _initialize() -> void: call_deferred("_run")

static func profiled_script() -> GDScript:
	var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第131轮阴影局部更新前/city_shadow_layer.gd.txt").replace("\r","")
	source = source.replace("class_name CityShadowLayer\n","")
	source = source.replace("var rebuild_usec := 0","var profile: Dictionary = {}\nvar phase_at := 0\nfunc _stamp(label: String) -> void:\n var now := Time.get_ticks_usec()\n profile[label] = float(profile.get(label,0.0))+float(now-phase_at)/1000.0\n phase_at = now\n\nvar rebuild_usec := 0")
	source = source.replace("var started := Time.get_ticks_usec()\n var signature", "var started := Time.get_ticks_usec()\n phase_at = started\n profile.clear()\n var signature")
	source = source.replace("last_key = signature","_stamp(\"signature_ms\")\n last_key = signature")
	source = source.replace("var completed: Dictionary = {}","_stamp(\"patches_ms\")\n  var completed: Dictionary = {}")
	source = source.replace('var union: PackedByteArray = static_cache[kind]["data"].duplicate()', '_stamp("mature_ms")\n  var union: PackedByteArray = static_cache[kind]["data"].duplicate()\n  _stamp("copy_ms")')
	source = source.replace("var image := Image.create_from_data", '_stamp("reveal_ms")\n  var image := Image.create_from_data')
	source = source.replace("if sprite.texture != null", '_stamp("image_ms")\n  if sprite.texture != null')
	source = source.replace("sprite.scale = Vector2.ONE/float(cfg[\"union_resolution\"])", 'sprite.scale = Vector2.ONE/float(cfg["union_resolution"])\n  _stamp("upload_ms")\n  profile[kind+"_pixels"] = size_px.x*size_px.y')
	var script := GDScript.new()
	script.source_code = source
	assert(script.reload() == OK)
	return script

func _run() -> void:
	var world := World.new()
	world.build_expanded_town()
	var phrase: int = world.cfg["timing"]["phrase_frames"]
	for index in range(1,72): world.settle(index*phrase)
	var demo: Control = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.set_process(false)
	var layer: Node2D = profiled_script().new()
	demo.buildings_layer.add_child(layer)
	layer.hide()
	var local := CityShadowLayer.new()
	demo.buildings_layer.add_child(local)
	local.hide()
	demo.shown_world = world
	demo.model.world = world
	demo.clock.renderer.transport.audible_frame = phrase*71
	demo._sync_buildings()
	var records: Array[Dictionary] = []
	for building in world.buildings: records.append(demo.shadow_records[building["district_id"]])
	layer.update_records(records)
	local.update_records(records)
	await RenderingServer.frame_post_draw
	world.settle(phrase*72)
	var samples: Array = []
	var changes: Array[Dictionary] = []
	for step in range(1,6):
		demo.clock.renderer.transport.audible_frame = phrase*72+step*2205
		demo._sync_buildings()
		records.clear()
		for building in world.buildings: records.append(demo.shadow_records[building["district_id"]])
		layer.update_records(records)
		if step == 1:
			local.update_records(records)
			for record in records:
				if record["progress"] < 1.0: changes.append(record)
		else: local.update_progress(changes)
		samples.append({"progress_step":step,"old_ms":float(layer.rebuild_usec)/1000.0,"local_ms":float(local.rebuild_usec)/1000.0,"updated_tiles":local.updated_tile_count,"uploaded_pixels":local.uploaded_pixels,"profile":layer.profile.duplicate()})
		await RenderingServer.frame_post_draw
	var result := {"buildings":world.buildings.size(),"samples":samples,"source_sha256":FileAccess.get_sha256("res://废弃/scripts/2026-10-10_第131轮阴影局部更新前/city_shadow_layer.gd.txt")}
	FileAccess.open("res://验证记录/连续河谷/第131轮_阴影分项.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("SHADOW_PROFILE ",JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit()
