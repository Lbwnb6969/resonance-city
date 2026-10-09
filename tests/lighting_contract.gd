class_name LightingContract
extends SceneTree
var out := "res://验证记录/Demo/UI-006_第55轮/"
var baseline := false
func _initialize() -> void:
 call_deferred("_run")
func _capture(label: String) -> void:
 await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(out+label+".png") == OK)
func _run() -> void:
 assert(DisplayServer.get_name() != "headless")
 baseline = "--baseline" in OS.get_cmdline_user_args()
 DirAccess.make_dir_recursive_absolute(out)
 var phase := "改前" if baseline else "改后"
 if "--asset-gray" in OS.get_cmdline_user_args():
  await _asset_gray()
  quit(0)
  return
 if "--style" in OS.get_cmdline_user_args():
  var scene: Control = load("res://scenes/style_frame.tscn").instantiate()
  root.add_child(scene)
  await process_frame
  var label := "古典小景" if "--classical-frame" in OS.get_cmdline_user_args() else "风格小景"
  await _capture(phase+"_"+label)
  scene.view_zoom = 1.8
  scene.zoom_target = 1.8
  scene.camera_age = 2.0
  await _capture(phase+"_"+label+"_推近")
  print("UI-006 CAPTURE ",label," ",phase)
  quit(0)
  return
 var main: Control = load("res://scenes/p0_main.tscn").instantiate()
 main.start_audio_on_ready = false
 root.add_child(main)
 await process_frame
 main.release_armed = true
 main.release_button.set_pressed_no_signal(false)
 var chosen := Vector2i(-1,-1)
 var empty: Array = main.model.session._empty_cells()
 empty.sort_custom(func(a: Array,b: Array) -> bool: return Vector2(a[0]-8,a[1]-8).length_squared() < Vector2(b[0]-8,b[1]-8).length_squared())
 for cell in empty:
  var safe := true
  for d in main.model.session.city:
   if d["type"] == "industrial":
    var at: Array = d["footprint"][0]
    safe = safe and absi(cell[0]-at[0])+absi(cell[1]-at[1]) > 5
  if safe:
   chosen = Vector2i(cell[0],cell[1])
   break
 assert(chosen.x >= 0)
 main._select_empty(chosen)
 main.release_armed = false
 main.city_view.release_mode = false
 var pcm := PackedVector2Array()
 for i in range(17):
  var at: int = main.model.next_boundary
  main.clock.renderer.transport.rendered_frames = at
  pcm.append_array(main.clock.renderer.render(17))
  main.clock.renderer.transport.audible_frame = at+22051
  await process_frame
 assert(main.model.session.city.size() == 27)
 main.city_view.selected_id = ""
 main.city_view.hover_cell = Vector2i(-1,-1)
 await _capture(phase+"_主城全景")
 main.city_view.view_zoom = 2.0
 main.city_view.zoom_target = 2.0
 main.city_view.camera_age = 2.0
 main.city_view.view_pan = Vector2(0,-220)
 await _capture(phase+"_主城推近")
 var proof := {"entities":main.model.session.city.size(),"city":main.model.session.city.duplicate(true),"rng":main.model.session.rng.snapshot(),"pcm_sha256":_sha(pcm.to_byte_array())}
 var file := FileAccess.open(out+phase+"_状态.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(proof,"\t")+"\n")
 if not baseline: await _checks(main,proof)
 print("UI-006 CAPTURE 主城 ",phase," entities=27")
 quit(0)

func _sha(bytes: PackedByteArray) -> String:
 var h := HashingContext.new()
 h.start(HashingContext.HASH_SHA256)
 h.update(bytes)
 return h.finish().hex_encode()

func _image(viewport: SubViewport) -> Image:
 await process_frame
 await RenderingServer.frame_post_draw
 return viewport.get_texture().get_image()

func _checks(main: Control, proof: Dictionary) -> void:
 var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out+"改前_状态.json"))
 assert(old == JSON.parse_string(JSON.stringify(proof)),"City, RNG or PCM changed")
 var saved: Dictionary = main.model.session.snapshot()
 var viewport := SubViewport.new()
 viewport.size = Vector2i(256,256)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var ground := ColorRect.new()
 ground.color = Color("e1e8ec")
 ground.size = Vector2(256,256)
 viewport.add_child(ground)
 var layer := CityShadowLayer.new()
 viewport.add_child(layer)
 var entry: Dictionary = main.city_view.entries["residential_building_type_a_01_base"]
 var record := {"entry":entry,"position":Vector2(100,150),"base_scale":Vector2.ONE*0.05,"progress":1.0,"visible":true}
 var records: Array[Dictionary] = [record]
 var evidence: Dictionary = {}
 for kind: String in ["shadow","contact"]:
  layer.update_records(records)
  layer.groups["shadow"].visible = kind == "shadow"
  layer.groups["contact"].visible = kind == "contact"
  var one := await _image(viewport)
  records.append(record.duplicate())
  layer.update_records(records)
  var two := await _image(viewport)
  assert(one.get_data() == two.get_data(),"Overlap deepens "+kind)
  assert(one.save_png(out+kind+"_重叠GPU.png") == OK)
  var darkest := Vector2i.ZERO
  var minimum := 4.0
  for y in range(256):
   for x in range(256):
    var color := one.get_pixel(x,y)
    var sum := color.r+color.g+color.b
    if sum < minimum:
     minimum = sum
     darkest = Vector2i(x,y)
  var full := one.get_pixelv(darkest)
  assert(ground.color.r-full.r > 0.03)
  for item in records: item["progress"] = 0.5
  layer.update_records(records)
  var half := await _image(viewport)
  var partial := half.get_pixelv(darkest)
  var difference := absf((ground.color.r-partial.r)/(ground.color.r-full.r)-0.5)
  assert(difference < 0.04,"Half progress alpha mismatch "+kind)
  records.resize(1)
  layer.update_records(records)
  assert((await _image(viewport)).get_data() == half.get_data(),"Partial overlap deepens "+kind)
  assert(half.save_png(out+kind+"_半拍GPU.png") == OK)
  evidence[kind] = {"overlap_exact":true,"half_overlap_exact":true,"half_alpha_error":difference,"sample":[darkest.x,darkest.y]}
  record["progress"] = 1.0
 viewport.queue_free()
 await process_frame
 var view: Control = main.city_view
 var target: AudioGrowthMask
 for sprite in view.sprites.values():
  if sprite.has_meta("asset_id") and sprite.visible:
   target = sprite
   break
 assert(target != null)
 var old_start: int = target.start_frame
 var old_progress: float = target.progress
 var audible: int = main.clock.renderer.transport.audible_frame
 target.begin_at(audible)
 view._sync_shadows(audible)
 assert(target.progress == 0.0)
 main.clock.renderer.transport.audible_frame = audible+target.STEP_FRAMES/2
 await process_frame
 view._sync_shadows(main.clock.renderer.transport.audible_frame)
 assert(absf(target.progress-0.5) < 0.0001)
 evidence["audible_growth_progress"] = target.progress
 var growth_rebuilds: Array[int] = []
 var growth_intervals: Array[int] = []
 var growth_last := Time.get_ticks_usec()
 for i in range(1,31):
  main.clock.renderer.transport.audible_frame = audible+target.STEP_FRAMES*i/32
  await process_frame
  var now := Time.get_ticks_usec()
  growth_intervals.append(now-growth_last)
  growth_last = now
  growth_rebuilds.append(view.shadow_layer.rebuild_usec)
 growth_rebuilds.sort()
 growth_intervals.sort()
 var growth_total := 0
 for usec in growth_rebuilds: growth_total += usec
 evidence["animated_growth"] = {"samples":30,"rebuild_mean_ms":float(growth_total)/30.0/1000.0,"rebuild_p95_ms":growth_rebuilds[28]/1000.0,"frame_p95_ms":growth_intervals[28]/1000.0,"note":"27-entity scene, one actual visible building in partial growth; audible frame stepped within beat"}
 target.start_frame = old_start
 target.progress = old_progress
 target.material.set_shader_parameter("growth_progress",old_progress)
 main.clock.renderer.transport.audible_frame = audible
 view._sync_shadows(audible)
 await process_frame
 var cached: int = view.shadow_layer.rebuild_count
 var intervals: Array[int] = []
 var last := Time.get_ticks_usec()
 for i in range(120):
  await process_frame
  var now := Time.get_ticks_usec()
  intervals.append(now-last)
  last = now
 assert(view.shadow_layer.rebuild_count == cached,"Static shadows rebuilt each frame")
 intervals.sort()
 var total := 0
 for interval in intervals: total += interval
 evidence["frame_times"] = {"samples":intervals.size(),"entities":27,"mean_ms":float(total)/intervals.size()/1000.0,"p95_ms":intervals[113]/1000.0,"maximum_ms":intervals[-1]/1000.0,"static_rebuilds":view.shadow_layer.rebuild_count-cached,"last_rebuild_ms":view.shadow_layer.rebuild_usec/1000.0,"driver":RenderingServer.get_current_rendering_method(),"audio":"Dummy; frozen audible clock; no live supply claim"}
 main.set_black_screen(true)
 await process_frame
 await RenderingServer.frame_post_draw
 var black := root.get_texture().get_image()
 black.convert(Image.FORMAT_RGB8)
 var bytes := black.get_data()
 var nonzero := 0
 for byte in bytes: nonzero += int(byte != 0)
 assert(nonzero == 0,"Black screen leaked shadows")
 assert(black.save_png(out+"改后_黑屏.png") == OK)
 main.set_black_screen(false)
 assert(saved == main.model.session.snapshot(),"Presentation altered city")
 evidence["black_screen"] = {"pixels":black.get_width()*black.get_height(),"nonzero_RGB_bytes":nonzero}
 evidence["state_PCM_RNG_exact"] = true
 var file := FileAccess.open(out+"UI-006_GPU.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(evidence,"\t")+"\n")
 print("UI-006 GPU PASS exact overlap + partial overlap + audible half beat + black RGB zero + state/PCM/RNG exact + 27 frame times + static cache")

func _asset_gray() -> void:
 var viewport := SubViewport.new()
 viewport.size = Vector2i(512,512)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var ground := ColorRect.new()
 ground.color = Color("e1e8ec")
 ground.size = Vector2(512,512)
 viewport.add_child(ground)
 var sprite := Sprite2D.new()
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 viewport.add_child(sprite)
 sprite.position = Vector2(256,256)
 var entries: Dictionary = {}
 for path in ["res://资源/Demo城市/manifest.json","res://资源/古典建筑候选/manifest.json"]:
  var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
  for entry in manifest["entries"]: entries[entry["id"]] = entry
 var metadata: Dictionary = {}
 DirAccess.make_dir_recursive_absolute(out+"灰度原图")
 for id: String in entries:
  var entry: Dictionary = entries[id]
  sprite.texture = load("res://"+str(entry["texture"]))
  sprite.scale = Vector2.ONE*420.0/maxf(sprite.texture.get_width(),sprite.texture.get_height())
  var image := await _image(viewport)
  assert(image.save_png(out+"灰度原图/"+id+".png") == OK)
  metadata[id] = {"texture":entry["texture"],"viewport":[512,512],"scale":sprite.scale.x,"texture_size":sprite.texture.get_size(),"ground":"#e1e8ec"}
 var file := FileAccess.open(out+"灰度素材GPU.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(metadata,"\t")+"\n")
 viewport.queue_free()
 print("UI-006 GRAY actual_GPU assets=",entries.size())
