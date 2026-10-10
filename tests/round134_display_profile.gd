extends SceneTree
const Scene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
func _initialize() -> void: call_deferred("_run")
static func demo_script() -> GDScript:
 var source := FileAccess.get_file_as_string("res://scripts/ui/continuous_valley_demo.gd").replace("\r","")
 var body := "func _sync_buildings"+source.get_slice("func _sync_buildings",1).get_slice("func _draw()",0)
 body = body.replace("\t_prepare_ground()", "\tphase_at = Time.get_ticks_usec()\n\tprofile.clear()\n\t_prepare_ground()\n\t_stamp(\"prepare_ground_ms\")")
 body = body.replace("\t_refresh_overlay()", "\t_stamp(\"layer_sync_ms\")\n\t_refresh_overlay()\n\t_stamp(\"overlay_ms\")")
 body = body.replace("\tfor building in shown_world.buildings:\n\t\tvar id:", "\t_stamp(\"full_setup_ms\")\n\tfor building in shown_world.buildings:\n\t\tvar id:")
 body = body.replace("\tif shadows_dirty: _update_shadows()", "\t_stamp(\"sprites_ms\")\n\tif shadows_dirty: _update_shadows()\n\t_stamp(\"shadows_ms\")")
 var script := GDScript.new()
 script.source_code = ("extends \"res://scripts/ui/continuous_valley_demo.gd\"\nvar profile: Dictionary = {}\nvar phase_at := 0\nfunc _stamp(label: String) -> void:\n var now := Time.get_ticks_usec()\n profile[label] = float(now-phase_at)/1000.0\n phase_at = now\n"+body).replace("\t"," ")
 assert(script.reload() == OK)
 return script
func _run() -> void:
 var city := World.new()
 city.build_expanded_town()
 var phrase: int = city.cfg["timing"]["phrase_frames"]
 for i in range(1,72): city.settle(i*phrase)
 var demo: ContinuousValleyDemo = Scene.instantiate()
 demo.set_script(demo_script())
 demo.session_persistence = false
 root.add_child(demo)
 demo.clock.stop_output()
 demo.set_process(false)
 demo.model.close_background_settlement()
 demo.model = Model.new(city,1.3409036)
 demo.shown_world = city
 demo.clock.renderer.transport.audible_frame = 71*phrase
 demo._sync_buildings()
 await RenderingServer.frame_post_draw
 var before: Dictionary = demo.get("profile").duplicate()
 city.settle(72*phrase)
 demo.clock.renderer.transport.audible_frame = 72*phrase
 demo._sync_buildings()
 await RenderingServer.frame_post_draw
 var result := {"buildings":city.buildings.size(),"opening":before,"growth":demo.get("profile").duplicate(),"urban_draw_ms":demo.city_ground_layer.last_draw_ms}
 FileAccess.open("res://验证记录/连续河谷/第134轮_显示分项.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
 print("DISPLAY_PROFILE ",JSON.stringify(result))
 demo.queue_free()
 await process_frame
 quit()
