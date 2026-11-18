extends RefCounted
## Main-thread visual copy of the exact published terrain vertices. No authoring.
const Terrain=preload("res://scripts/world/city_creation_terrain.gd")
var texture:ImageTexture
var signature:Variant=null
var uploads:=0
var bytes:=0
func publish(renderer)->void:
	if renderer.record_only:return
	var values:PackedFloat32Array=renderer.state._ground_terrain.vertices
	var next:=hash(values)
	if signature!=next:
		var data:=values.to_byte_array();var image:=Image.create_from_data(Terrain.COLUMNS,Terrain.ROWS,false,Image.FORMAT_RF,data)
		if texture==null:texture=ImageTexture.create_from_image(image)
		else:texture.update(image)
		signature=next;uploads+=1;bytes=data.size()
	if renderer.water_material!=null:bind(renderer.water_material)
	if renderer.ground_material!=null:bind(renderer.ground_material)
func bind(material:ShaderMaterial)->void:
	# Staging renderers share the published water material. Their empty helper
	# must leave it alone until the guarded generation commit publishes data.
	if texture==null:return
	material.set_shader_parameter("terrain_height_field",texture)
	material.set_shader_parameter("terrain_height_rect",Vector4(Terrain.LAND_RECT.position.x,Terrain.LAND_RECT.position.y,Terrain.LAND_RECT.size.x,Terrain.LAND_RECT.size.y))
	material.set_shader_parameter("terrain_height_step",Terrain.STEP)
	material.set_shader_parameter("terrain_height_enabled",true)
