extends SceneTree
const Reference = preload("res://tests/round134_display_reference.gd")
var checks: Dictionary = {}
var samples: Array = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
 var viewport := SubViewport.new()
 viewport.size = Vector2i(1024,768)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var groups: Array[Node2D] = []
 var all_sprites: Array = []
 var entry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/时代城市/manifest.json"))["entries"][0]
 var texture: Texture2D = load("res://"+str(entry["texture"]))
 for script in [Reference.growth_script(),preload("res://scripts/visual/audio_growth_mask.gd")]:
  var group := Node2D.new()
  viewport.add_child(group)
  group.hide()
  groups.append(group)
  var sprites: Array[AudioGrowthMask] = []
  for i in range(400):
   var sprite: AudioGrowthMask = script.new()
   sprite.use_master_clock = false
   sprite.texture = texture
   sprite.scale = Vector2.ONE*0.08
   sprite.position = Vector2((i%20)*44+20,(i/20)*30+20)
   sprite.modulate = Color(1.0,1.0,0.92 if i%3 == 0 else 0.97)
   group.add_child(sprite)
   sprite.begin_at(0)
   sprite.sample_frame(sprite.STEP_FRAMES)
   sprites.append(sprite)
  all_sprites.append(sprites)
 for stage in range(4):
  if stage > 0:
   for sprites in all_sprites:
    for i in [0,12,24]:
     var sprite: AudioGrowthMask = sprites[i]
     sprite.sample_frame(float(sprite.STEP_FRAMES)*[1.0,0.25,0.75,1.0][stage])
  var images: Array[PackedByteArray] = []
  for index in range(2):
   groups[1-index].hide()
   groups[index].show()
   await RenderingServer.frame_post_draw
   await RenderingServer.frame_post_draw
   images.append(viewport.get_texture().get_image().get_data())
   samples.append({"stage":stage,"reference":index == 0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
  checks["stage_"+str(stage)+"_pixels"] = images[0] == images[1]
  var actual: Array = all_sprites[1]
  checks["stage_"+str(stage)+"_mature_shared"] = actual[1].material == actual[2].material and actual[1].material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED
  checks["stage_"+str(stage)+"_growing_private"] = actual[0].material != actual[1].material if stage in [1,2] else actual[0].material == actual[1].material
 var before: Array = all_sprites[0]
 var after: Array = all_sprites[1]
 var unique_old: Dictionary = {}
 var unique_new: Dictionary = {}
 for sprite in before: unique_old[sprite.material] = true
 for sprite in after: unique_new[sprite.material] = true
 checks["mature_materials_400_to_1"] = unique_old.size() == 400 and unique_new.size() == 1
 var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"samples":samples,"sprites":400}
 FileAccess.open("res://验证记录/连续河谷/第134轮_成熟材质合批.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
 print("GROWTH_BATCHING ",JSON.stringify(result))
 viewport.queue_free()
 await process_frame
 quit(0 if result["passed"] else 1)
