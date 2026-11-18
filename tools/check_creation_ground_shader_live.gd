extends SceneTree
## Isolate the ground shader on a flat metric grid, without city construction.
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func lattice(cell:Vector2i)->float:
	var value:=(((cell.x&0xffffffff)*0x8da6b343)^((cell.y&0xffffffff)*0xd8163841))&0xffffffff
	value=((value^(value>>16))*0x7feb352d)&0xffffffff
	value=((value^(value>>15))*0x846ca68b)&0xffffffff;value^=value>>16
	return float(value&0x00ffffff)/16777216.
func reference_noise(at:Vector2)->float:
	var cell:=Vector2i(floor(at.x),floor(at.y));var f:=at-Vector2(cell);f=f*f*(Vector2(3,3)-2.*f)
	return lerpf(lerpf(lattice(cell),lattice(cell+Vector2i(1,0)),f.x),lerpf(lattice(cell+Vector2i(0,1)),lattice(cell+Vector2i.ONE),f.x),f.y)
func run()->void:
	var out:="";var expected:="forward_plus"
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--expected-renderer="):expected=arg.trim_prefix("--expected-renderer=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));root.size=Vector2i(960,960);Engine.max_fps=0
	var began:=Time.get_ticks_msec();var scene:=Node3D.new();root.add_child(scene)
	var camera:=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=96.;camera.position=Vector3(0,100,0);camera.rotation_degrees=Vector3(-90,0,0)
	var environment:=WorldEnvironment.new();scene.add_child(environment);environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.1,.1,.1)
	var instance:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(96,96);plane.subdivide_width=191;plane.subdivide_depth=191;instance.mesh=plane;scene.add_child(instance)
	var source:=FileAccess.get_file_as_string("res://scripts/visual/shaders/creation_ground.gdshader");var rows:Array=[]
	var cases:={"albedo":source.replace("render_mode diffuse_burley, specular_disabled;","render_mode unshaded;"),"grass":source.replace("render_mode diffuse_burley, specular_disabled;","render_mode unshaded;").replace("ALBEDO = ground_surface;","ALBEDO = meadow_color(world_at.xz,PROJECTION_MATRIX);"),"broad":source.replace("render_mode diffuse_burley, specular_disabled;","render_mode unshaded;").replace("ALBEDO = ground_surface;","ALBEDO = vec3(meadow_noise(world_at.xz*.055));"),"world":source.replace("render_mode diffuse_burley, specular_disabled;","render_mode unshaded;").replace("ALBEDO = ground_surface;","ALBEDO = vec3((world_at.x+48.)/96.,0.,(world_at.z+48.)/96.);")}
	cases.encoded=cases.broad.replace("ALBEDO = vec3(meadow_noise(world_at.xz*.055));","vec3 value=vec3(meadow_noise(world_at.xz*.055));ALBEDO=OUTPUT_IS_SRGB ? value : meadow_srgb_to_linear(value);")
	# Both controls pass through the same native render/color path. This
	# separates noise correctness from differences between renderer resolves.
	var reference:=Image.create(128,128,false,Image.FORMAT_RF)
	for y in range(128):
		for x in range(128):reference.set_pixel(x,y,Color(reference_noise(((Vector2(x,y)+Vector2(.5,.5))/128.*96.-Vector2(48,48))*.055),0,0))
	var texture:=ImageTexture.create_from_image(reference)
	cases.reference_gpu=cases.encoded.replace("world_at.xz*.055","((floor(SCREEN_UV*128.)+vec2(.5))/128.*96.-vec2(48.))*.055")
	cases.reference_cpu=cases.encoded.replace("shader_type spatial;","shader_type spatial;\nuniform sampler2D scalar_reference : filter_nearest, repeat_disable;").replace("meadow_noise(world_at.xz*.055)","texture(scalar_reference,SCREEN_UV).r")
	var largest_step:=0.
	var gpu_reference:Image;var reference_error:=0.
	for key:String in cases:
		var shader:=Shader.new();shader.code=cases[key];var material:=ShaderMaterial.new();material.shader=shader;instance.material_override=material
		if key=="reference_cpu":material.set_shader_parameter("scalar_reference",texture)
		for i in range(8):await process_frame
		await RenderingServer.frame_post_draw;var picture:=root.get_texture().get_image();picture.save_png(out+"/"+key+".png");rows.append({"mode":key,"shader_sha256":shader.code.sha256_text()})
		if key=="reference_gpu":gpu_reference=picture
		if key=="reference_cpu":
			for y in range(picture.get_height()):
				for x in range(picture.get_width()):reference_error=maxf(reference_error,absf(picture.get_pixel(x,y).r-gpu_reference.get_pixel(x,y).r))
		if key=="encoded":
			for y in range(1,picture.get_height()-1):
				for x in range(1,picture.get_width()-1):
					var value:=picture.get_pixel(x,y).r
					largest_step=maxf(largest_step,maxf(absf(value-picture.get_pixel(x+1,y).r),absf(value-picture.get_pixel(x,y+1).r)))
	var report:={"ok":RenderingServer.get_current_rendering_method()==expected,"renderer":RenderingServer.get_current_rendering_method(),"seconds":(Time.get_ticks_msec()-began)/1000.,"cases":rows,"source_sha256":FileAccess.get_sha256("res://scripts/visual/shaders/creation_ground.gdshader"),"scope":"96m flat .5m grid, default shader parameters, unlit; no author state or personal persistence instantiated"}
	# Smooth value noise has maximum slope 1.5 per cell. At .1m pixels and
	# .055 cells/m, the bound is .00825 plus two 8-bit quantization steps.
	report.largest_adjacent_step=largest_step;report.continuity_limit=.00825+2./255.;report.continuity_ok=largest_step<=report.continuity_limit;report.ok=report.ok and report.continuity_ok
	report.native_cpu_reference_error=reference_error;report.reference_limit=2./255.;report.ok=report.ok and reference_error<=report.reference_limit
	report.palette_sha256=FileAccess.get_sha256("res://scripts/visual/shaders/creation_meadow_palette.gdshaderinc");report.tool_sha256=FileAccess.get_sha256("res://tools/check_creation_ground_shader_live.gd")
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("GROUND_SHADER ",JSON.stringify(report));scene.queue_free();await process_frame;quit(0 if report.ok else 1)
