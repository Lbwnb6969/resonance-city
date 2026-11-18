extends "res://tools/check_creation_shape_palette_live.gd"
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.set_house_architecture("h1","portico")
	await show(city,Vector2(-25,-20),"屋面开口定位");await settle();quiet();demo._set_light_phase(1)
	await key(KEY_V);demo.set_process(false);demo.life.set_process(false);demo.ui_layer.hide()
	var sun:Vector3=demo.sun.global_basis.z;var angle:=atan2(-sun.x,-sun.z)
	demo.yaw=angle;demo.pitch=.1;demo.focus=Vector3(-25+sin(angle)*6.,1.3,-20+cos(angle)*6.);demo._update_camera()
	for i in range(60):await process_frame
	demo.get_meta("waterfront_light").set_process(false);demo.get_meta("waterfront_light").material.set_shader_parameter("strength",0.);Engine.time_scale=0.
	var author:Dictionary=demo.state.snapshot();var arrays:Array=[]
	for mesh:MeshInstance3D in demo.town.house_roots.h1.find_children("*","MeshInstance3D",true,false):
		for s in range(mesh.mesh.get_surface_count()):arrays.append(hash(mesh.mesh.surface_get_arrays(s)))
	await capture("baseline")
	var from:Vector3=demo.camera.project_ray_origin(Vector2(590,224));var direction:Vector3=demo.camera.project_ray_normal(Vector2(590,224));var hits:Array=[]
	for mesh:MeshInstance3D in demo.town.house_roots.h1.find_children("*","MeshInstance3D",true,false):
		var faces:=mesh.mesh.get_faces();var pose:=mesh.global_transform
		for i in range(0,faces.size(),3):
			var a:Vector3=pose*faces[i];var b:Vector3=pose*faces[i+1];var c:Vector3=pose*faces[i+2];var hit=Geometry3D.ray_intersects_triangle(from,direction,a,b,c)
			if hit!=null:hits.append({"node":str(mesh.get_path()),"point":str(hit),"normal":str((b-a).cross(c-a).normalized()),"distance":from.distance_to(hit)})
		for surface in range(mesh.mesh.get_surface_count()):
			var material:=mesh.get_active_material(surface)
			if material is ShaderMaterial and (material.shader.code.contains("roof_normal") or material.shader.resource_path.ends_with("creation_ancient_tiles.gdshader")):
				var replacement:=material.duplicate();var shader:=Shader.new();shader.code=material.shader.code.replace("render_mode diffuse_burley, specular_schlick_ggx;","render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;");replacement.shader=shader
				if mesh.material_override!=null:mesh.material_override=replacement
				else:mesh.set_surface_override_material(surface,replacement)
	facts.hole_ray=hits
	for i in range(4):await process_frame
	await capture("two_sided")
	var current:Array=[]
	for mesh:MeshInstance3D in demo.town.house_roots.h1.find_children("*","MeshInstance3D",true,false):
		for s in range(mesh.mesh.get_surface_count()):current.append(hash(mesh.mesh.surface_get_arrays(s)))
	check(current==arrays and demo.state.snapshot()==author,"material diagnostic preserves actual GPU geometry and author world")
	Engine.time_scale=1.;demo.set_process(true);await complete_report(personal)
