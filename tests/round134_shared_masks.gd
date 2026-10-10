extends SceneTree
var checks: Dictionary = {}
var measurements: Array = []
func _initialize() -> void: call_deferred("_run")
static func reference_script() -> GDScript:
 var script := GDScript.new()
 script.source_code = FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第134轮显示准备优化前/city_shadow_layer.gd.txt").replace("\r","").replace("class_name CityShadowLayer\n","")
 assert(script.reload() == OK)
 return script
func _tiles_equal(a: CityShadowLayer,b: Node2D) -> bool:
 for kind in ["shadow","contact"]:
  if a.tiles[kind].keys() != b.tiles[kind].keys(): return false
  for coord in a.tiles[kind]:
   if a.tiles[kind][coord]["sprite"].texture.get_image().get_data() != b.tiles[kind][coord]["sprite"].texture.get_image().get_data(): return false
 return true
func _run() -> void:
 var current := CityShadowLayer.new()
 var old: Node2D = reference_script().new()
 root.add_child(current)
 root.add_child(old)
 current.hide()
 old.hide()
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/时代城市/manifest.json"))
 var patch_equal := true
 var patches_tested := 0
 for entry in manifest["entries"]:
  for scale_factor in [Vector2.ONE*0.075,Vector2.ONE*0.075000001,Vector2(0.11,0.09)]:
   for position in [Vector2(-512.01,-1.0),Vector2(0.3333,255.9999),Vector2(513.00001,512.125)]:
    var record := {"entry":entry,"base_scale":scale_factor,"position":position,"progress":1.0,"visible":true}
    for kind in ["shadow","contact"]:
     var a := current._patch(record,kind)
     var b: Dictionary = old._patch(record,kind)
     patch_equal = patch_equal and a["begin"] == b["begin"] and a["size"] == b["size"] and a["alpha"] == b["alpha"]
     patches_tested += 1
 checks["all_manifest_masks_exact"] = patch_equal
 var entries: Array = manifest["entries"]
 var records: Array[Dictionary] = []
 for i in range(60):
  records.append({"entry":entries[i%3],"base_scale":Vector2.ONE*0.075,"position":Vector2((i%10)*14-60,(i/10)*25-40),"progress":1.0,"visible":true})
 for backend in [true,false]:
  current.native_enabled = backend
  old.native_enabled = backend
  for stage in range(7):
   if stage == 1: records.append({"entry":entries[0],"base_scale":Vector2.ONE*0.075,"position":Vector2(62.125,128.2),"progress":0.0,"visible":true})
   if stage == 2: records[-1]["progress"] = 0.125
   if stage == 3: records[-1]["progress"] = 1.0
   if stage == 4:
    records[4]["position"] = Vector2(-1.9,63.99)
    records[5]["base_scale"] = Vector2.ONE*0.12
    records[6]["visible"] = false
    records[-1]["progress"] = 0.3
   if stage == 5: records.reverse()
   if stage == 6: records.clear()
   current.update_records(records)
   old.update_records(records)
   checks[str(backend)+"_stage_"+str(stage)] = _tiles_equal(current,old)
  for i in range(60):
   records.append({"entry":entries[i%3],"base_scale":Vector2.ONE*0.075,"position":Vector2((i%10)*14-60,(i/10)*25-40),"progress":1.0,"visible":true})
 checks["cache_pruned_when_empty"] = current.scaled_masks.is_empty()
 current.native_enabled = true
 old.native_enabled = true
 for node in [old,current]:
  var started := Time.get_ticks_usec()
  node.update_records(records)
  measurements.append({"reference":node == old,"ms":float(Time.get_ticks_usec()-started)/1000.0})
 checks["same_output_after_return"] = _tiles_equal(current,old)
 checks["resampling_shared"] = current.scaled_masks.size() < current.patches.size()/3
 var cache_before: Dictionary = current.scaled_masks.duplicate()
 var cache_hash := hash(cache_before)
 records[-1]["progress"] = 0.5
 current.update_records(records)
 checks["cached_alpha_immutable"] = hash(cache_before) == cache_hash
 current.update_records([])
 checks["final_cache_pruned"] = current.scaled_masks.is_empty()
 var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"patches_tested":patches_tested,"measurements":measurements}
 FileAccess.open("res://验证记录/连续河谷/第134轮_共享遮罩等价.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
 print("SHARED_MASKS ",JSON.stringify(result))
 current.queue_free()
 old.queue_free()
 await process_frame
 quit(0 if result["passed"] else 1)
