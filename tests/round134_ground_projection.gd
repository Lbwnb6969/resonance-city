extends SceneTree
const Scene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Ground = preload("res://scripts/visual/valley_ground_layer.gd")
var checks: Dictionary = {}
var samples: Array = []
func _initialize() -> void: call_deferred("_run")
static func reference_script() -> GDScript:
 var script := GDScript.new()
 script.source_code = FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第134轮显示准备优化前/valley_ground_layer.gd.txt").replace("\r","")
 # Both sides close outlines on copies; old camera redraws mutated cached polygons.
 # Opening/growth were already pixel-identical to the unmodified old source.
 script.source_code = script.source_code.replace("var polygon := _project_polygon(reservation[\"polygon\"])", "var polygon := _project_polygon(reservation[\"polygon\"]).duplicate()")
 script.source_code = script.source_code.replace("\t\telse:\n\t\t\tprojected.append(projected[0])", "\t\telse:\n\t\t\tprojected = projected.duplicate()\n\t\t\tprojected.append(projected[0])")
 assert(script.reload() == OK)
 return script
func _compare(demo: ContinuousValleyDemo,actual: Node2D,old: Node2D,label: String) -> void:
 actual.sync(demo)
 old.sync(demo)
 actual.show()
 old.hide()
 await RenderingServer.frame_post_draw
 await RenderingServer.frame_post_draw
 var a := actual.get_viewport().get_texture().get_image().get_data()
 actual.hide()
 old.show()
 await RenderingServer.frame_post_draw
 await RenderingServer.frame_post_draw
 var b := actual.get_viewport().get_texture().get_image().get_data()
 checks[label+"_pixels"] = a == b
 var exact := true
 for height in actual.projected:
  for polygon in actual.projected[height]:
   exact = exact and actual.projected[height][polygon] == old._project_polygon(polygon,height).slice(0,polygon.size())
 checks[label+"_projection"] = exact
 samples.append({"name":label,"actual_ms":actual.last_draw_ms,"old_ms":old.last_draw_ms,"polygons":actual.projected.values().reduce(func(total: int,items: Dictionary) -> int: return total+items.size(),0),"points":actual.point_cache.size()})
 old.hide()
 actual.hide()
func _run() -> void:
 var demo: ContinuousValleyDemo = Scene.instantiate()
 demo.session_persistence = false
 root.add_child(demo)
 demo.clock.stop_output()
 demo.set_process(false)
 demo.model.close_background_settlement()
 var viewport := SubViewport.new()
 viewport.size = Vector2i(1024,768)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var background := ColorRect.new()
 background.color = Color(0.7,0.7,0.7)
 background.size = Vector2(viewport.size)
 viewport.add_child(background)
 var actual := Ground.new()
 var old: Node2D = reference_script().new()
 actual.role = "urban"
 old.role = "urban"
 viewport.add_child(actual)
 viewport.add_child(old)
 for family in ValleyTerrain.family_ids():
  var city := World.new("2026100900000062",true,family)
  city.build_starter("bright")
  demo.model = Model.new(city)
  demo.shown_world = city
  demo.size = Vector2(700,500)
  demo.view_zoom = 0.88
  demo.pan = Vector2.ZERO
  demo._prepare_ground()
  await _compare(demo,actual,old,family+"_opening")
  var opening_cache: Dictionary = actual.projected.duplicate(true)
  city.settle(int(city.cfg["timing"]["phrase_frames"]))
  demo._prepare_ground()
  actual.sync(demo)
  checks[family+"_retained_until_draw"] = actual.projected == opening_cache
  await _compare(demo,actual,old,family+"_growth")
  demo.view_zoom = 0.52
  demo.pan = Vector2(30,-50)
  await _compare(demo,actual,old,family+"_camera")
 var before := actual.projected.duplicate(true)
 demo.shown_world = World.new("2026100900000062",true,"river_valley")
 demo.shown_world.build_starter("bright")
 demo.shown_world.terrain.river_phase += 0.1
 demo._prepare_ground()
 await _compare(demo,actual,old,"same_seed_changed_phase")
 checks["terrain_change_invalidates"] = actual.projected != before
 var retained := actual.projected
 demo.shown_world.lots.clear()
 demo.shown_world.fabric_cache = {}
 demo.shown_world.phrase_index += 1
 await _compare(demo,actual,old,"removed_geometry")
 checks["prunes_old_polygons"] = actual.projected != retained and actual.projected.size() == old.projected.size()
 var result := {"reference_scope":"Archived projection path with the outline-copy fix on both sides; first draws already match unmodified archive", "passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"samples":samples}
 FileAccess.open("res://验证记录/连续河谷/第134轮_地面投影等价.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
 print("GROUND_PROJECTION ",JSON.stringify(result))
 viewport.queue_free()
 demo.queue_free()
 await process_frame
 quit(0 if result["passed"] else 1)
