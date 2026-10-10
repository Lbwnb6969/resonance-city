class_name CityShadowLayer
extends Node2D
## R8 maximum coverage in fixed ground tiles. One texel halo keeps linear filtering continuous.
const Values = preload("res://scripts/spec_values.gd")
const MaskShader = preload("res://资源/着色器/统一阴影遮罩.gdshader")
const TILE_SIZE := 512
const PADDED_SIZE := TILE_SIZE+2
var cfg: Dictionary
var groups: Dictionary = {}
var tiles: Dictionary = {}
var members: Dictionary = {}
var patches: Dictionary = {}
# Resampling and alpha depend on texture and raster size, not ground position.
# Published byte arrays are immutable and shared by positioned patches.
var scaled_masks: Dictionary = {}
var mask_images: Dictionary = {}
var materials: Dictionary = {}
var rebuild_usec := 0
var rebuild_count := 0
var static_merge_count := 0
var retained_resize_count := 0
var updated_tile_count := 0
var uploaded_pixels := 0
var native_enabled := true
var native_batches := 0
var mask_merger: RefCounted = ClassDB.instantiate("CityMaskUnion") if ClassDB.class_exists("CityMaskUnion") else null

func _ready() -> void:
 cfg = Values.load_values()["lighting"]
 for kind in ["shadow","contact"]:
  var group := Node2D.new()
  group.name = "CastShadowGroup" if kind == "shadow" else "ContactShadowGroup"
  add_child(group)
  var material := ShaderMaterial.new()
  material.shader = MaskShader
  material.set_shader_parameter("shadow_color",Color(cfg["shadow_color"]))
  material.set_shader_parameter("layer_alpha",float(cfg[kind+"_alpha"]))
  groups[kind] = group
  materials[kind] = material
  tiles[kind] = {}
  members[kind] = {}

func _patch(record: Dictionary, kind: String) -> Dictionary:
 var entry: Dictionary = record["entry"]
 var base_scale: Vector2 = record["base_scale"].snapped(Vector2.ONE*0.00000001)
 var at: Vector2 = record["position"].snapped(Vector2.ONE/float(cfg["union_resolution"]))
 var key := [entry[kind+"_texture"],base_scale,at]
 if patches.has(key): return patches[key]
 var path := "res://"+str(entry[kind+"_texture"])
 if not mask_images.has(path):
  var texture: Texture2D = load(path)
  assert(texture != null,"Missing ground mask: "+path)
  mask_images[path] = texture.get_image()
 var original: Image = mask_images[path]
 var scale_mask := base_scale*float(entry["pixels_per_world"])/float(entry[kind+"_pixels_per_world"])
 var resolution: float = cfg["union_resolution"]
 var offset: Array = entry[kind+"_origin"]
 var low := (at-Vector2(offset[0],offset[1])*scale_mask)*resolution
 var extent := Vector2(original.get_size())*scale_mask*resolution
 var begin := Vector2i(floori(low.x),floori(low.y))
 var end := Vector2i(ceili(low.x+extent.x),ceili(low.y+extent.y))
 var size_px := end-begin
 var mask_key := [path,size_px]
 if not scaled_masks.has(mask_key):
  var source: Image = original.duplicate()
  source.clear_mipmaps()
  source.convert(Image.FORMAT_RGBA8)
  source.resize(maxi(1,size_px.x),maxi(1,size_px.y),Image.INTERPOLATE_BILINEAR)
  var rgba := source.get_data()
  var alpha := PackedByteArray()
  alpha.resize(size_px.x*size_px.y)
  for i: int in range(alpha.size()): alpha[i] = rgba[i*4+3]
  scaled_masks[mask_key] = alpha
 var patch := {"begin":begin,"size":size_px,"alpha":scaled_masks[mask_key],"key":key,"mask_key":mask_key}
 patches[key] = patch
 return patch


func update_records(records: Array[Dictionary]) -> void:
 var started := Time.get_ticks_usec()
 updated_tile_count = 0
 uploaded_pixels = 0
 for kind: String in ["shadow","contact"]:
  var current: Dictionary = {}
  var previous: Dictionary = members[kind]
  var dirty: Dictionary = {}
  for record in records:
   if not record["visible"] or not record["entry"].has(kind+"_texture"): continue
   var patch := _patch(record,kind)
   var key: Array = patch["key"]
   if not record.has("mask_keys"): record["mask_keys"] = {}
   record["mask_keys"][kind] = key
   var progress := clampi(roundi(float(record["progress"])*int(cfg["progress_steps"])),0,int(cfg["progress_steps"]))
   if not current.has(key) or current[key]["progress"] < progress:
    current[key] = {"patch":patch,"progress":progress}
  for key: Array in current:
   var patch: Dictionary = current[key]["patch"]
   var progress: int = current[key]["progress"]
   var before: Dictionary = previous.get(key,{})
   if not before.is_empty() and before["progress"] == progress:
    current[key] = before
    continue
   if not before.is_empty(): _remove_member(kind,key,before,dirty)
   var coords := _tile_coords(patch)
   current[key] = {"progress":progress,"coords":coords}
   for coord: Vector2i in coords:
    if not tiles[kind].has(coord): tiles[kind][coord] = _new_tile(kind,coord)
    var tile: Dictionary = tiles[kind][coord]
    # A changed reveal step reuses its already clipped, immutable patch.
    var clipped: Dictionary = tile["clips"].get(key,{})
    if clipped.is_empty():
     clipped = _clip_patch(patch,coord)
     tile["clips"][key] = clipped
    tile["items"][key] = {"patch":clipped,"progress":progress}
    dirty[coord] = true
  for key in previous:
   if not current.has(key): _remove_member(kind,key,previous[key],dirty,true)
  members[kind] = current
  for coord: Vector2i in dirty:
   var tile: Dictionary = tiles[kind][coord]
   if tile["items"].is_empty():
    tile["sprite"].queue_free()
    tiles[kind].erase(coord)
   else: _update_tile(tile,coord)
 var live_masks: Dictionary = {}
 for key in patches.keys():
  if not members["shadow"].has(key) and not members["contact"].has(key): patches.erase(key)
  else: live_masks[patches[key]["mask_key"]] = true
 for key in scaled_masks.keys():
  if not live_masks.has(key): scaled_masks.erase(key)
 if updated_tile_count > 0: rebuild_count += 1
 rebuild_usec = Time.get_ticks_usec()-started

func update_progress(records: Array[Dictionary]) -> void:
 var started := Time.get_ticks_usec()
 updated_tile_count = 0
 uploaded_pixels = 0
 for kind: String in ["shadow","contact"]:
  var dirty: Dictionary = {}
  for record in records:
   if not record["mask_keys"].has(kind): continue
   var key: Array = record["mask_keys"][kind]
   var member: Dictionary = members[kind][key]
   var progress := clampi(roundi(float(record["progress"])*int(cfg["progress_steps"])),0,int(cfg["progress_steps"]))
   if member["progress"] == progress: continue
   member["progress"] = progress
   for coord: Vector2i in member["coords"]:
    tiles[kind][coord]["items"][key]["progress"] = progress
    dirty[coord] = true
  for coord: Vector2i in dirty: _update_tile(tiles[kind][coord],coord)
 if updated_tile_count > 0: rebuild_count += 1
 rebuild_usec = Time.get_ticks_usec()-started

func _tile_coords(patch: Dictionary) -> Array[Vector2i]:
 var begin: Vector2i = patch["begin"]-Vector2i.ONE
 var end: Vector2i = patch["begin"]+patch["size"]
 var coords: Array[Vector2i] = []
 for y in range(floori(float(begin.y)/TILE_SIZE),floori(float(end.y)/TILE_SIZE)+1):
  for x in range(floori(float(begin.x)/TILE_SIZE),floori(float(end.x)/TILE_SIZE)+1):
   coords.append(Vector2i(x,y))
 return coords

func _new_tile(kind: String,coord: Vector2i) -> Dictionary:
 var sprite := Sprite2D.new()
 sprite.centered = false
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 sprite.material = materials[kind]
 # Draw only the core; sampling may use its neighboring texels in the halo.
 sprite.region_enabled = true
 sprite.region_rect = Rect2(1,1,TILE_SIZE,TILE_SIZE)
 sprite.region_filter_clip_enabled = false
 sprite.position = Vector2(coord*TILE_SIZE)/float(cfg["union_resolution"])
 sprite.scale = Vector2.ONE/float(cfg["union_resolution"])
 groups[kind].add_child(sprite)
 return {"sprite":sprite,"items":{},"clips":{},"mature":{},"base":PackedByteArray()}

func _clip_patch(patch: Dictionary,coord: Vector2i) -> Dictionary:
 var rect := Rect2i(coord*TILE_SIZE-Vector2i.ONE,Vector2i.ONE*PADDED_SIZE)
 var hit := rect.intersection(Rect2i(patch["begin"],patch["size"]))
 var size_px: Vector2i = patch["size"]
 var source := Image.create_from_data(size_px.x,size_px.y,false,Image.FORMAT_R8,patch["alpha"])
 var image := source.get_region(Rect2i(hit.position-patch["begin"],hit.size))
 return {"begin":hit.position,"size":hit.size,"alpha":image.get_data(),"key":patch["key"]}

func _remove_member(kind: String,key: Array,member: Dictionary,dirty: Dictionary,retire_clip := false) -> void:
 for coord: Vector2i in member["coords"]:
  tiles[kind][coord]["items"].erase(key)
  if retire_clip: tiles[kind][coord]["clips"].erase(key)
  dirty[coord] = true

func _update_tile(tile: Dictionary,coord: Vector2i) -> void:
 var completed: Dictionary = {}
 var reveal: Array[Dictionary] = []
 var steps: int = cfg["progress_steps"]
 for key in tile["items"]:
  var item: Dictionary = tile["items"][key]
  if item["progress"] == steps: completed[key] = item
  elif item["progress"] > 0: reveal.append(item)
 var previous: Dictionary = tile["mature"]
 var can_extend: bool = not tile["base"].is_empty()
 for key in previous:
  if not completed.has(key):
   can_extend = false
   break
 var base: PackedByteArray
 if can_extend: base = tile["base"]
 else:
  base = PackedByteArray()
  base.resize(PADDED_SIZE*PADDED_SIZE)
  base.fill(0)
 var mature: Array[Dictionary] = []
 for key in completed:
  if not can_extend or not previous.has(key):
   mature.append(completed[key])
   static_merge_count += 1
 var low := coord*TILE_SIZE-Vector2i.ONE
 base = _merge_batch(base,PADDED_SIZE,low,mature)
 tile["base"] = base
 tile["mature"] = completed
 var union := _merge_batch(base,PADDED_SIZE,low,reveal)
 var image := Image.create_from_data(PADDED_SIZE,PADDED_SIZE,false,Image.FORMAT_R8,union)
 var sprite: Sprite2D = tile["sprite"]
 if sprite.texture == null: sprite.texture = ImageTexture.create_from_image(image)
 else: (sprite.texture as ImageTexture).update(image)
 updated_tile_count += 1
 uploaded_pixels += PADDED_SIZE*PADDED_SIZE

func _merge_batch(union: PackedByteArray, width: int, low: Vector2i, items: Array[Dictionary]) -> PackedByteArray:
 if items.is_empty(): return union
 if native_enabled and mask_merger != null:
  native_batches += 1
  return mask_merger.merge_masks(union,width,low,items,int(cfg["progress_steps"]))
 union = union.duplicate()
 for item in items: _merge(union,width,low,item["patch"],item["progress"])
 return union

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
