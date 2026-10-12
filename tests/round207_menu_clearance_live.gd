extends SceneTree
## Narrow physical-window check after the full route/audio run: camera clearance.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
var checks: Dictionary = {}
var failures: Array[String] = []
var shots: Dictionary = {}
var demo: ContinuousValleyDemo
var output := "res://验证记录/round207_临街朝向/小窗避让/"

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func capture(cid: String) -> void:
	check(demo._begin_first_sound_choice(cid),cid+"_opens_actual_parcel")
	await create_timer(0.9).timeout
	var raw: Array = demo.context["position"]
	var centre := demo.point(Vector2(float(raw[0]),float(raw[1])))
	var parcel_and_facade := Rect2(centre-Vector2(90,100),Vector2(180,170))
	var panel := demo.menu.get_global_rect()
	check(not panel.intersects(parcel_and_facade),cid+"_whole_parcel_and_facade_clear_of_menu")
	check(Rect2(Vector2.ZERO,Vector2(800,600)).encloses(panel),cid+"_menu_fits_native_window")
	check(Rect2(Vector2.ZERO,Vector2(800,600)).encloses(parcel_and_facade),cid+"_target_stays_in_view")
	check(not demo.caption.visible and not demo.tooltip.visible,cid+"_choices_hide_redundant_map_instructions")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+cid+"_800x600_地块完整可见.png")
	shots[cid] = {"menu":panel,"target":centre,"target_bounds":parcel_and_facade,"community":demo.context["community_id"]}
	demo.menu.hide()

func _run() -> void:
	output += "run_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(800,600))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	var city := World.new("2026101100000184",true,"river_valley")
	city.build_first_composition_starter()
	demo._start_world({},city)
	demo.clock.start_output(demo.model._mix_frame,{},demo.clock.renderer.snapshot())
	await create_timer(2.5).timeout
	demo.clock.stop_output()
	check(demo.sprites.values().all(func(sprite: Node2D) -> bool: return sprite.progress >= 0.99),"opening_houses_are_revealed_before_screenshots")
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","physical_native_window")
	check(demo.size == Vector2(800,600),"native_ui_pixels_at_800x600")
	var before := demo.model.world.snapshot()
	await capture("west-2")
	await capture("east-2")
	DisplayServer.window_set_size(Vector2i(1440,900))
	await process_frame
	demo.menu.hide()
	demo.pointer_inside = false
	demo.zoom_target = 3.0
	var house: Dictionary = city.buildings[0]
	var at := demo.Coupling.position_of(house)
	demo.pan_target = -demo.Projection2D.to_screen(at-Vector2(16,16),Vector2.ZERO,demo.zoom_target,Vector2(28,14),city.terrain.height_at(at))
	await create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"第一时代_街面近景.png")
	check(demo.model.world.snapshot() == before,"camera_clearance_does_not_change_city")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"shots":shots,"scope":"Physical 800x600 camera/menu clearance only; audio route chain was already validated separately."}
	FileAccess.open(output+"clearance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND207_MENU_CLEARANCE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
