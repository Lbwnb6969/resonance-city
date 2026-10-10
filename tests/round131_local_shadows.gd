extends SceneTree
var failures: Array[String] = []
var checks := 0
var gpu_samples: Array = []
var current: CityShadowLayer
var reference: Node2D
var viewport: SubViewport
func _initialize() -> void: call_deferred("_run")
static func reference_script() -> GDScript:
 var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第131轮阴影局部更新前/city_shadow_layer.gd.txt").replace("\r","")
 var script := GDScript.new()
 script.source_code = source.replace("class_name CityShadowLayer\n","")
 assert(script.reload() == OK)
 return script
func _run() -> void:
 viewport = SubViewport.new()
 viewport.size = Vector2i(1024,768)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var background := ColorRect.new()
 background.color = Color(0.83,0.85,0.82)
 background.size = Vector2(viewport.size)
 viewport.add_child(background)
 current = CityShadowLayer.new()
 reference = reference_script().new()
 viewport.add_child(current)
 viewport.add_child(reference)
 current.hide()
 reference.hide()
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/时代城市/manifest.json"))
 var entries: Array = manifest["entries"].filter(func(entry: Dictionary) -> bool: return int(entry["era"]) == 1)
 var records: Array[Dictionary] = []
 for i in range(20):
  records.append({"entry":entries[i%entries.size()],"base_scale":Vector2.ONE*0.075,"position":Vector2((i%5)*60-30,(i/5)*80-40),"progress":1.0,"visible":true})
 _compare(records,"initial")
 records.append({"entry":entries[1],"base_scale":Vector2.ONE*0.11,"position":Vector2(250,250),"progress":0.0,"visible":true})
 for progress in [0.0,0.01,0.125,0.5,0.999,1.0]:
  records[-1]["progress"] = progress
  _compare(records,"tile edge reveal "+str(progress),[] if progress == 0.0 else [records[-1]])
  if progress in [0.125,0.5,1.0]: await _gpu(records,"reveal "+str(progress),0.8,Vector2(220,200))
 records.append({"entry":entries[0],"base_scale":Vector2.ONE*0.1,"position":Vector2(-260,-260),"progress":1.0,"visible":true})
 _compare(records,"negative coordinates expansion")
 records.append(records[-1].duplicate())
 records[-1]["progress"] = 0.2
 _compare(records,"duplicate geometry max progress")
 records.remove_at(records.size()-1)
 records.remove_at(0)
 _compare(records,"mature retirement")
 records[2]["position"] = Vector2(20,30)
 records[2]["base_scale"] = Vector2.ONE*0.13
 _compare(records,"moved resized mature")
 records[3]["visible"] = false
 _compare(records,"hidden mature")
 records[4]["progress"] = 0.375
 _compare(records,"mature regression",[records[4]])
 for zoom in [0.45,1.0,1.33]:
  await _gpu(records,"camera "+str(zoom),zoom,Vector2(320.3,340.7))
 records.reverse()
 _compare(records,"reordering")
 var count := current.rebuild_count
 current.update_records(records)
 _check(current.rebuild_count == count and current.updated_tile_count == 0,"unchanged tiles retain textures")
 _compare([],"empty")
 _compare(records,"return from empty")
 _check(current.mask_merger != null and current.native_batches > 0,"native max-union")
 current.native_enabled = false
 records[4]["progress"] = 0.6
 _compare(records,"script fallback reveal",[records[4]])
 records[4]["progress"] = 0.2
 _compare(records,"script fallback retreat",[records[4]])
 records[4]["progress"] = 1.0
 _compare(records,"script fallback mature",[records[4]])
 var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"gpu_samples":gpu_samples,"tile_size":current.TILE_SIZE,"halo_texels":1}
 FileAccess.open("res://验证记录/连续河谷/第131轮_局部阴影等价.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
 print("LOCAL_SHADOW ",JSON.stringify(evidence))
 viewport.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
func _check(ok: bool,label: String) -> void:
 checks += 1
 if not ok: failures.append(label)
func _compare(records: Array[Dictionary],label: String,changes: Array = []) -> void:
 if changes.is_empty(): current.update_records(records)
 else:
  var typed: Array[Dictionary] = []
  typed.assign(changes)
  current.update_progress(typed)
 reference.update_records(records)
 for kind in ["shadow","contact"]:
  var expected: Sprite2D = reference.images[kind]
  _check(current.tiles[kind].is_empty() == not expected.visible,label+" visibility "+kind)
  if not expected.visible: continue
  var image := expected.texture.get_image()
  var low := Vector2i(expected.position*float(current.cfg["union_resolution"]))
  var actual := Image.create(image.get_width(),image.get_height(),false,Image.FORMAT_R8)
  actual.fill(Color(0,0,0))
  for coord: Vector2i in current.tiles[kind]:
   var sprite: Sprite2D = current.tiles[kind][coord]["sprite"]
   actual.blit_rect(sprite.texture.get_image(),Rect2i(1,1,current.TILE_SIZE,current.TILE_SIZE),coord*current.TILE_SIZE-low)
  _check(actual.get_data() == image.get_data(),label+" exact R8 "+kind)
func _gpu(_records: Array[Dictionary],label: String,zoom: float,at: Vector2) -> void:
 current.position = at
 reference.position = at
 current.scale = Vector2.ONE*zoom
 reference.scale = Vector2.ONE*zoom
 reference.show()
 current.hide()
 await RenderingServer.frame_post_draw
 await RenderingServer.frame_post_draw
 var before := viewport.get_texture().get_image()
 reference.hide()
 current.show()
 await RenderingServer.frame_post_draw
 await RenderingServer.frame_post_draw
 var after := viewport.get_texture().get_image()
 var a := before.get_data()
 var b := after.get_data()
 var max_delta := 0
 var changed := 0
 for i in range(a.size()):
  var delta := absi(int(a[i])-int(b[i]))
  max_delta = maxi(max_delta,delta)
  if delta > 0: changed += 1
 gpu_samples.append({"label":label,"max_byte_delta":max_delta,"changed_channels":changed})
 _check(max_delta <= 1,label+" GPU linear filtering within one byte")
 if label == "reveal 0.5": after.save_png("res://验证记录/连续河谷/第131轮_阴影跨块.png")
 current.hide()
