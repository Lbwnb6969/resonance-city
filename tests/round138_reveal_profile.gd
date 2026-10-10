extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/continuous_valley_demo.gd")
	var method := source.substr(source.find("func _sync_buildings()"),source.find("func _update_shadows()")-source.find("func _sync_buildings()"))
	method = method.replace("\t_prepare_ground()","\tvar phase_started := Time.get_ticks_usec()\n\t_prepare_ground()")
	method = method.replace("\t_refresh_overlay()","\tstages[\"ground_bind_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n\tphase_started = Time.get_ticks_usec()\n\t_refresh_overlay()")
	method = method.replace("\tvar frame := clock.renderer","\tstages[\"overlay_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n\tphase_started = Time.get_ticks_usec()\n\tvar frame := clock.renderer")
	method = method.replace("\tfor building in shown_world.buildings:","\tstages[\"display_bind_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n\tphase_started = Time.get_ticks_usec()\n\tfor building in shown_world.buildings:")
	method = method.replace("\tif shadows_dirty and (not append_only", "\tstages[\"sprite_loop_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n\tphase_started = Time.get_ticks_usec()\n\tif shadows_dirty and (not append_only")
	method += "\tstages[\"shadow_records_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n"
	var instrumented := GDScript.new()
	instrumented.source_code = "extends ContinuousValleyDemo\nvar stages: Dictionary = {}\n"+method
	assert(instrumented.reload() == OK)
	var demo: ContinuousValleyDemo = preload("res://scenes/continuous_valley.tscn").instantiate()
	demo.set_script(instrumented)
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.set_process(false)
	demo._start_world({},ContinuousWorld.regional_sample())
	# Let the sample's own newborns finish, matching the live next-phrase measurement.
	demo.clock.renderer.transport.audible_frame += 22050
	demo._sync_buildings()
	await RenderingServer.frame_post_draw
	var before := demo.shown_world.buildings.size()
	demo.model.world.settle(demo.model.next_boundary)
	demo.clock.renderer.transport.audible_frame = demo.model.next_boundary
	var begin := Time.get_ticks_usec()
	demo._sync_buildings()
	var elapsed := float(Time.get_ticks_usec()-begin)/1000.0
	var stages: Dictionary = demo.get("stages").duplicate()
	await RenderingServer.frame_post_draw
	var result := {"before":before,"after":demo.shown_world.buildings.size(),"total_sync_ms":elapsed,"stages":stages,"ground_draw_ms":demo.city_ground_layer.last_draw_ms,"shadow_update_ms":float(demo.shadow_layer.rebuild_usec)/1000.0,"tile_updates":demo.shadow_layer.updated_tile_count,"uploaded_pixels":demo.shadow_layer.uploaded_pixels,"scope":"Isolated GPU display binding after a real 1511->1525 settlement; output paused, no real-time FPS claim"}
	FileAccess.open("res://验证记录/连续河谷/第138轮_成长揭示分项.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("REVEAL_PROFILE ",JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit()
