extends SceneTree
## Real GPU transfer: raw mesh paint must resolve to its authored display color.
var out:=""
func _initialize()->void:run.call_deferred()
func shader(mode:String)->Shader:
	var value:=Shader.new();value.code='shader_type spatial;\nrender_mode unshaded,cull_disabled;\nuniform vec4 reference_paint : source_color;\n#include "res://scripts/visual/shaders/creation_paint_color.gdshaderinc"\n#include "res://scripts/visual/shaders/creation_meadow_palette.gdshaderinc"\nvoid fragment(){'
	if mode=="uniform":value.code+='ALBEDO=reference_paint.rgb;'
	elif mode=="paint":value.code+='ALBEDO=creation_paint_color(COLOR.rgb);'
	elif mode=="tip":value.code+='vec3 lift=meadow_srgb_to_linear(COLOR.rgb);ALBEDO=OUTPUT_IS_SRGB ? meadow_linear_to_srgb(lift) : lift;'
	else:value.code+='ALBEDO=COLOR.rgb;'
	value.code+='}';return value
func quad(color:Color,material:ShaderMaterial)->MeshInstance3D:
	var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(-1,-1,0),Vector3(1,-1,0),Vector3(1,1,0),Vector3(-1,1,0)])
	arrays[Mesh.ARRAY_COLOR]=PackedColorArray([color,color,color,color]);arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,3])
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=material;return node
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec()
	var viewport:=SubViewport.new();viewport.size=Vector2i(64,64);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color.BLACK;world.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR;viewport.add_child(world)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.5;camera.position=Vector3(0,0,3);viewport.add_child(camera);camera.look_at(Vector3.ZERO)
	var rows:Array=[];var failures:Array=[];var maximum:=0.;var raw_error:=0.;var reference:Dictionary={}
	for mode:String in ["uniform","paint","tip","raw"]:
		var material:=ShaderMaterial.new();material.shader=shader(mode)
		for color:Color in [Color(.25,.43,.27),Color(.24,.20,.135),Color(.085,.147,.072),Color(.05,.06,.01),Color(.8,.65,.4)]:
			material.set_shader_parameter("reference_paint",color)
			var node:=quad(color,material);viewport.add_child(node)
			for i in range(4):await process_frame
			await RenderingServer.frame_post_draw;var image:=viewport.get_texture().get_image();var pixel:=image.get_pixel(32,32)
			if mode=="uniform":reference[color]=pixel
			var expected:Color=reference[color];var error:=maxf(absf(pixel.r-expected.r),maxf(absf(pixel.g-expected.g),absf(pixel.b-expected.b)))
			rows.append({"mode":mode,"input":[color.r,color.g,color.b],"native_source_color":[expected.r,expected.g,expected.b],"output":[pixel.r,pixel.g,pixel.b],"error":error})
			if mode=="raw":raw_error=maxf(raw_error,error)
			elif mode!="uniform":
				maximum=maxf(maximum,error)
				if error>2./255.:failures.append(rows[-1])
			node.queue_free();await process_frame
	var renderer:=RenderingServer.get_current_rendering_method()
	if renderer=="forward_plus" and raw_error<.1:failures.append("raw control did not expose linear/display mismatch")
	var report:={"ok":failures.is_empty(),"failures":failures,"renderer":renderer,"samples":rows,"maximum_corrected_error":maximum,"maximum_raw_error":raw_error,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("PAINT_COLOR_GPU ",JSON.stringify({"ok":report.ok,"renderer":renderer,"maximum_corrected_error":maximum,"maximum_raw_error":raw_error,"seconds":report.seconds}));viewport.queue_free();await process_frame;quit(0 if report.ok else 1)
