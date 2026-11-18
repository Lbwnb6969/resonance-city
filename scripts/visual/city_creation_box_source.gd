extends Mesh
## CPU-only input to SurfaceTool.append_from. Never installed on a scene node.
## Preserve the native unit BoxMesh arrays once, instead of reading its GPU
## buffers again for every trim, shutter, style course and road detail box.
var _arrays:Array
var _format:=0
func _init()->void:
	var source:=BoxMesh.new();source.size=Vector3.ONE
	_arrays=source.surface_get_arrays(0)
	for index in range(Mesh.ARRAY_MAX):
		if _arrays[index]!=null:_format|=1<<index
func _get_aabb()->AABB:return AABB(Vector3(-.5,-.5,-.5),Vector3.ONE)
func _get_blend_shape_count()->int:return 0
func _get_blend_shape_name(_index:int)->StringName:return &""
func _set_blend_shape_name(_index:int,_name:StringName)->void:pass
func _get_surface_count()->int:return 1
func _surface_get_array_index_len(_index:int)->int:return _arrays[Mesh.ARRAY_INDEX].size()
func _surface_get_array_len(_index:int)->int:return _arrays[Mesh.ARRAY_VERTEX].size()
func _surface_get_arrays(_index:int)->Array:return _arrays
func _surface_get_blend_shape_arrays(_index:int)->Array[Array]:return []
func _surface_get_format(_index:int)->int:return _format
func _surface_get_lods(_index:int)->Dictionary:return {}
func _surface_get_material(_index:int)->Material:return null
func _surface_get_primitive_type(_index:int)->int:return Mesh.PRIMITIVE_TRIANGLES
func _surface_set_material(_index:int,_material:Material)->void:pass
