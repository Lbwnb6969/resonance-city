extends SceneTree
var checks: Dictionary = {}
var current: CityShadowLayer
var reference: CityShadowLayer
var viewport: SubViewport
var gpu_samples: Array = []
func _initialize() -> void: call_deferred("_run")
static func reference_script() -> GDScript:
 var old := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第138轮成长揭示优化前/city_shadow_layer.gd.txt").replace("\r","")
 var begin := old.find("func update_records(")
 var end := old.find("func update_progress(")
 var script := GDScript.new()
 script.source_code = "extends CityShadowLayer\n"+old.substr(begin,end-begin)
 assert(script.reload() == OK)
 return script
func _run() -> void:
 viewport = SubViewport.new()
 viewport.size = Vector2i(1024,768)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var background := ColorRect.new()
 background.size = Vector2(viewport.size)
 background.color = Color(0.83,0.85,0.82)
 viewport.add_child(background)
 current = CityShadowLayer.new()
 reference = CityShadowLayer.new()
 reference.set_script(reference_script())
 viewport.add_child(current)
 viewport.add_child(reference)
 current.hide()
 reference.hide()
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/时代城市/manifest.json"))
 var entries: Array = manifest["entries"].filter(func(entry: Dictionary) -> bool: return int(entry["era"]) == 1)
 var records: Array[Dictionary] = []
 for i in range(20):
  records.append({"entry":entries[i%entries.size()],"base_scale":Vector2.ONE*0.075,"position":Vector2((i%5)*60-30,(i/5)*80-40),"progress":1.0,"visible":true})
 current.update_records(records)
 _compare(records,"initial")
 var added: Array[Dictionary] = []
 for at in [Vector2(250,250),Vector2(-260,-260),Vector2(510,10)]:
  added.append({"entry":entries[1],"base_scale":Vector2.ONE*0.11,"position":at,"progress":0.0,"visible":true})
 records.append_array(added)
 checks["zero_batch_registered"] = current.try_append_records(added)
 checks["zero_batch_no_upload"] = current.updated_tile_count == 0 and current.uploaded_pixels == 0
 _compare(records,"zero registration")
 await _gpu("zero registration")
 for progress in [0.01,0.125,0.5,1.0]:
  for record in added: record["progress"] = progress
  current.update_progress(added)
  _compare(records,"reveal "+str(progress))
  if progress in [0.125,0.5,1.0]: await _gpu("reveal "+str(progress))
 var late: Dictionary = added[0].duplicate(true)
 late.erase("mask_keys")
 late["position"] = Vector2(350,-220)
 late["progress"] = 0.125
 checks["late_visible_append"] = current.try_append_records([late])
 records.append(late)
 _compare(records,"late visible append")
 await _gpu("late visible append")
 var existing: int = current.members["shadow"].size()
 var fresh: Dictionary = added[0].duplicate(true)
 fresh.erase("mask_keys")
 fresh["position"] = Vector2(900,900)
 fresh["progress"] = 0.0
 var invalid: Array[Dictionary] = [fresh,added[0]]
 checks["visible_batch_rejected"] = not current.try_append_records(invalid)
 checks["rejection_atomic"] = current.members["shadow"].size() == existing and not fresh.has("mask_keys")
 invalid = [fresh,fresh.duplicate(true)]
 checks["duplicate_batch_rejected"] = not current.try_append_records(invalid) and current.members["shadow"].size() == existing
 invalid = [added[0].duplicate(true)]
 invalid[0]["progress"] = 0.0
 checks["existing_batch_rejected"] = not current.try_append_records(invalid)
 records[-1]["progress"] = 0.0
 current.update_progress([records[-1]])
 _compare(records,"visible regression to zero")
 records[0]["position"] = Vector2(20,30)
 records[0]["base_scale"] = Vector2.ONE*0.13
 records[1]["visible"] = false
 records.remove_at(2)
 records.reverse()
 current.update_records(records)
 _compare(records,"move resize hide remove reorder")
 current.native_enabled = false
 records[0]["progress"] = 0.375
 current.update_progress([records[0]])
 _compare(records,"script backend")
 await _gpu("script backend")
 current.update_records([])
 _compare([],"empty")
 viewport.queue_free()
 await process_frame
 await _real_city()
 var evidence := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"gpu_samples":gpu_samples,"source_sha256":FileAccess.get_sha256("res://scripts/visual/city_shadow_layer.gd"),"ui_sha256":FileAccess.get_sha256("res://scripts/ui/continuous_valley_demo.gd")}
 FileAccess.open("res://验证记录/连续河谷/第138轮_透明出生阴影合同.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
 print("TRANSPARENT_SHADOW ",JSON.stringify(evidence))
 quit(0 if evidence["passed"] else 1)
func _compare(records: Array[Dictionary],label: String) -> void:
 reference.update_records(records.duplicate(true))
 for kind: String in ["shadow","contact"]:
  var same: bool = current.tiles[kind].size() == reference.tiles[kind].size()
  for coord: Vector2i in reference.tiles[kind]:
   if not current.tiles[kind].has(coord):
    same = false
    continue
   var actual: Texture2D = current.tiles[kind][coord]["sprite"].texture
   var expected: Texture2D = reference.tiles[kind][coord]["sprite"].texture
   if actual == null:
    if expected != null:
     for byte in expected.get_image().get_data():
      if byte != 0: same = false
   elif expected == null: same = false
   elif actual.get_image().get_data() != expected.get_image().get_data(): same = false
  checks[label+" exact R8 "+kind] = same
func _gpu(label: String) -> void:
 current.position = Vector2(370.3,340.7)
 reference.position = current.position
 current.scale = Vector2.ONE*0.8
 reference.scale = current.scale
 reference.show()
 current.hide()
 await RenderingServer.frame_post_draw
 await RenderingServer.frame_post_draw
 var before := viewport.get_texture().get_image().get_data()
 reference.hide()
 current.show()
 await RenderingServer.frame_post_draw
 await RenderingServer.frame_post_draw
 var after := viewport.get_texture().get_image().get_data()
 var delta := 0
 for i in range(before.size()): delta = maxi(delta,absi(int(before[i])-int(after[i])))
 checks[label+" GPU"] = delta <= 1
 gpu_samples.append({"label":label,"max_byte_delta":delta})
 current.hide()
func _real_city() -> void:
 var demo: ContinuousValleyDemo = preload("res://scenes/continuous_valley.tscn").instantiate()
 demo.session_persistence = false
 root.add_child(demo)
 demo.clock.stop_output()
 demo.set_process(false)
 demo._start_world({},ContinuousWorld.regional_sample())
 demo.clock.renderer.transport.audible_frame += 22050
 demo._sync_buildings()
 await RenderingServer.frame_post_draw
 var before: Array[Dictionary] = []
 for record in demo.shadow_records.values(): before.append(record)
 demo.model.world.settle(demo.model.next_boundary)
 demo.clock.renderer.transport.audible_frame = demo.model.next_boundary
 # New arrivals first tests that unchanged records keep their registered keys.
 demo.model.world.buildings.reverse()
 demo._sync_buildings()
 checks["real_1511_to_1525"] = before.size() == 1511 and demo.shadow_records.size() == 1525
 checks["real_zero_upload"] = demo.shadow_layer.uploaded_pixels == 0
 var retained := true
 for record in before: retained = retained and record.has("mask_keys")
 for record in demo.shadow_records.values(): retained = retained and record.has("mask_keys")
 checks["reordered_records_keep_keys"] = retained
 # Compare every real-city tile against the previous full recomposition at several audible frames.
 current = demo.shadow_layer
 reference = CityShadowLayer.new()
 reference.set_script(reference_script())
 demo.add_child(reference)
 reference.hide()
 for offset in [0,2756,11025,22050]:
  demo.clock.renderer.transport.audible_frame = demo.model.next_boundary+offset
  demo._sync_buildings()
  var records: Array[Dictionary] = []
  for record in demo.shadow_records.values(): records.append(record)
  _compare(records,"real reveal "+str(offset))
 checks["real_native_backend"] = current.mask_merger != null and current.native_batches > 0
 demo.queue_free()
 await process_frame
