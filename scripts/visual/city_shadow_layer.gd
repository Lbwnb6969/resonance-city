class_name CityShadowLayer
extends Node2D
## Maximum coverage union in camera-independent ground coordinates.
const Values = preload("res://scripts/spec_values.gd")
const MaskShader = preload("res://资源/着色器/统一阴影遮罩.gdshader")
var cfg: Dictionary
var groups: Dictionary = {}
var images: Dictionary = {}
var patches: Dictionary = {}
var mask_images: Dictionary = {}
var static_cache: Dictionary = {}
var last_key := ""
var rebuild_usec := 0
var rebuild_count := 0
func _ready() -> void:
 cfg = Values.load_values()["lighting"]
 for kind in ["shadow","contact"]:
  var group := Node2D.new()
  group.name = "CastShadowGroup" if kind == "shadow" else "ContactShadowGroup"
  add_child(group)
  var sprite := Sprite2D.new()
  sprite.centered = false
  sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
  var material := ShaderMaterial.new()
  material.shader = MaskShader
  material.set_shader_parameter("shadow_color",Color(cfg["shadow_color"]))
  material.set_shader_parameter("layer_alpha",float(cfg[kind+"_alpha"]))
  sprite.material = material
  group.add_child(sprite)
  groups[kind] = group
  images[kind] = sprite

func _patch(record: Dictionary, kind: String) -> Dictionary:
 var entry: Dictionary = record["entry"]
 var base_scale: Vector2 = record["base_scale"].snapped(Vector2.ONE*0.00000001)
 var at: Vector2 = record["position"].snapped(Vector2.ONE/float(cfg["union_resolution"]))
 var key := str(entry[kind+"_texture"])+var_to_str(base_scale)+var_to_str(at)
 if patches.has(key): return patches[key]
 var path := "res://"+str(entry[kind+"_texture"])
 if not mask_images.has(path):
  var texture: Texture2D = load(path)
  assert(texture != null,"Missing ground mask: "+path)
  mask_images[path] = texture.get_image()
 var source: Image = mask_images[path].duplicate()
 source.clear_mipmaps()
 source.convert(Image.FORMAT_RGBA8)
 var scale_mask := base_scale*float(entry["pixels_per_world"])/float(entry[kind+"_pixels_per_world"])
 var resolution: float = cfg["union_resolution"]
 var offset: Array = entry[kind+"_origin"]
 var low := (at-Vector2(offset[0],offset[1])*scale_mask)*resolution
 var extent := Vector2(source.get_size())*scale_mask*resolution
 var begin := Vector2i(floori(low.x),floori(low.y))
 var end := Vector2i(ceili(low.x+extent.x),ceili(low.y+extent.y))
 var size_px := end-begin
 source.resize(maxi(1,size_px.x),maxi(1,size_px.y),Image.INTERPOLATE_BILINEAR)
 var rgba := source.get_data()
 var alpha := PackedByteArray()
 alpha.resize(size_px.x*size_px.y)
 for i: int in range(alpha.size()): alpha[i] = rgba[i*4+3]
 var patch := {"begin":begin,"size":size_px,"alpha":alpha,"key":key}
 patches[key] = patch
 return patch

func update_records(records: Array[Dictionary]) -> void:
 var started := Time.get_ticks_usec()
 var signature := ""
 for record in records:
  signature += str(record["entry"]["id"])+var_to_str(record["base_scale"].snapped(Vector2.ONE*0.00000001))+var_to_str(record["position"].snapped(Vector2.ONE/float(cfg["union_resolution"])))+str(record["visible"])+str(roundi(float(record["progress"])*int(cfg["progress_steps"])))
 if signature == last_key: return
 last_key = signature
 rebuild_count += 1
 for kind: String in ["shadow","contact"]:
  var active: Array[Dictionary] = []
  var low := Vector2i(2147483647,2147483647)
  var high := Vector2i(-2147483647,-2147483647)
  for record in records:
   if not record["visible"] or not record["entry"].has(kind+"_texture"): continue
   var patch := _patch(record,kind)
   active.append({"patch":patch,"progress":clampi(roundi(float(record["progress"])*int(cfg["progress_steps"])),0,int(cfg["progress_steps"]))})
   var begin: Vector2i = patch["begin"]
   var end: Vector2i = begin+patch["size"]
   low = Vector2i(mini(low.x,begin.x),mini(low.y,begin.y))
   high = Vector2i(maxi(high.x,end.x),maxi(high.y,end.y))
  var sprite: Sprite2D = images[kind]
  sprite.visible = not active.is_empty()
  if active.is_empty(): continue
  var size_px := high-low
  var static_key := var_to_str(low)+var_to_str(size_px)
  for item in active:
   if item["progress"] == int(cfg["progress_steps"]): static_key += str(item["patch"]["key"])
  if not static_cache.has(kind) or static_cache[kind]["key"] != static_key:
   var base := PackedByteArray()
   base.resize(size_px.x*size_px.y)
   base.fill(0)
   for item in active:
    if item["progress"] == int(cfg["progress_steps"]): _merge(base,size_px.x,low,item["patch"],int(cfg["progress_steps"]))
   static_cache[kind] = {"key":static_key,"data":base}
  var union: PackedByteArray = static_cache[kind]["data"].duplicate()
  for item in active:
   var progress: int = item["progress"]
   if progress > 0 and progress < int(cfg["progress_steps"]): _merge(union,size_px.x,low,item["patch"],progress)
  var image := Image.create_from_data(size_px.x,size_px.y,false,Image.FORMAT_R8,union)
  if sprite.texture != null and sprite.texture.get_size() == Vector2(size_px):
   (sprite.texture as ImageTexture).update(image)
  else: sprite.texture = ImageTexture.create_from_image(image)
  sprite.position = Vector2(low)/float(cfg["union_resolution"])
  sprite.scale = Vector2.ONE/float(cfg["union_resolution"])
 rebuild_usec = Time.get_ticks_usec()-started

func _merge(union: PackedByteArray, width: int, low: Vector2i, patch: Dictionary, progress: int) -> void:
 var data: PackedByteArray = patch["alpha"]
 var patch_size: Vector2i = patch["size"]
 var offset: Vector2i = patch["begin"]-low
 var steps: int = cfg["progress_steps"]
 for y: int in range(patch_size.y):
  var src: int = y*patch_size.x
  var dst: int = (offset.y+y)*width+offset.x
  for x: int in range(patch_size.x):
   var value: int = data[src+x] if progress == steps else roundi(float(data[src+x])*progress/steps)
   if value > union[dst+x]: union[dst+x] = value
