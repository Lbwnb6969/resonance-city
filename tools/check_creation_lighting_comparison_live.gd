extends "res://tools/check_creation_three_road_modes_live.gd"
## One authored town, identical cameras and real viewport timings per renderer.
var candidate_path:=""
var variant:="baseline"
var expected_renderer:="gl_compatibility"
func summary(values:Array)->Dictionary:
	var sorted:=values.duplicate();sorted.sort();var total:=0.
	for value:float in sorted:total+=value
	return {"count":sorted.size(),"mean":total/sorted.size(),"median":sorted[sorted.size()/2],"p95":sorted[mini(sorted.size()-1,ceili(sorted.size()*.95)-1)],"max":sorted[-1]}
func freeze_wind(time:float)->void:
	for material:Material in demo.town.foliage._materials.values():
		if material is ShaderMaterial:material.set_shader_parameter("wind_time_override",time)
	for key:String in ["lawn","grass"]:demo.town.meadow.materials[key].set_shader_parameter("meadow_time_override",time)
func geometry_signature()->String:
	var rows:Array=[]
	for node:Node in demo.town.find_children("*","GeometryInstance3D",true,false):
		if node is MeshInstance3D and node.mesh!=null:
			for surface in range(node.mesh.get_surface_count()):rows.append(var_to_bytes([node.global_transform,node.mesh.surface_get_arrays(surface)]).hex_encode().sha256_text())
		elif node is MultiMeshInstance3D and node.multimesh!=null:rows.append(var_to_bytes([node.global_transform,node.multimesh.buffer]).hex_encode().sha256_text())
	rows.sort();return var_to_bytes(rows).hex_encode().sha256_text()
func shape_signature()->Dictionary:
	var rows:Array=[];var meshes:=0;var instances:=0;var groups:Dictionary={}
	for node:Node in demo.town.find_children("*","GeometryInstance3D",true,false):
		var branch:Node=node
		while branch.get_parent()!=demo.town:branch=branch.get_parent()
		var group:=str(branch.name);var signature:=""
		if node is MeshInstance3D and node.mesh!=null:
			meshes+=1;signature=var_to_bytes([node.global_transform,node.mesh.get_faces()]).hex_encode().sha256_text()
		elif node is MultiMeshInstance3D and node.multimesh!=null and node.multimesh.mesh!=null:
			var transforms:Array=[]
			for i in range(node.multimesh.instance_count):transforms.append(node.multimesh.get_instance_transform(i))
			instances+=transforms.size();signature=var_to_bytes([node.global_transform,node.multimesh.mesh.get_faces(),transforms]).hex_encode().sha256_text()
		if signature.is_empty():continue
		rows.append(signature)
		if not groups.has(group):groups[group]=[]
		groups[group].append({"path":str(demo.town.get_path_to(node)),"sha256":signature})
	FileAccess.open(OUT+"/shape_inventory.json",FileAccess.WRITE).store_string(JSON.stringify(groups,"\t",true,true))
	var hashes:Dictionary={}
	for group:String in groups:
		var values:Array=groups[group].map(func(row):return row.sha256);values.sort();hashes[group]=var_to_bytes(values).hex_encode().sha256_text()
	rows.sort();return {"sha256":var_to_bytes(rows).hex_encode().sha256_text(),"meshes":meshes,"instances":instances,"groups":hashes}
func configure(phase:int)->void:
	demo._set_light_phase(phase)
	if not candidate_path.is_empty():load(candidate_path).apply(demo.environment_rig,variant,phase)
func settings()->Dictionary:
	var env:Environment=demo.environment_rig.environment;var result:={"environment":{},"sun":{}}
	for key:String in ["ambient_light_energy","ambient_light_sky_contribution","ambient_light_color","tonemap_mode","tonemap_exposure","tonemap_white","tonemap_agx_white","tonemap_agx_contrast","ssao_enabled","ssao_radius","ssao_intensity","ssil_enabled","ssil_radius","ssil_intensity","glow_enabled"]:result.environment[key]=env.get(key)
	for key:String in ["light_energy","light_color","rotation_degrees","light_angular_distance","shadow_bias","shadow_normal_bias","shadow_opacity","shadow_blur"]:result.sun[key]=demo.sun.get(key)
	result.msaa_3d=root.msaa_3d;result.camera={"transform":demo.camera.global_transform,"projection":demo.camera.projection,"size":demo.camera.size,"near":demo.camera.near,"far":demo.camera.far,"focus":demo.focus,"pitch":demo.pitch,"yaw":demo.yaw,"zoom":demo.zoom}
	return result
func diagnostics()->Array:
	demo.focus=Vector3(-16.,.8,20.);demo.zoom=32.;demo.pitch=.65;demo.yaw=-.6;demo._update_camera()
	var ground:ShaderMaterial=demo.town.ground_material;var original:Shader=ground.shader;var contact:bool=ground.get_shader_parameter("ground_contact_enabled");var rows:Array=[]
	for mode:String in ["reference","no_ssao","no_shadow","no_contact","up_normal"]:
		configure(0);demo.environment_rig.environment.ssao_enabled=mode!="no_ssao";demo.sun.shadow_enabled=mode!="no_shadow";ground.set_shader_parameter("ground_contact_enabled",contact and mode!="no_contact")
		if mode=="up_normal":
			var shader:=Shader.new();shader.code=original.code.replace("NORMAL = safe_normalize((VIEW_MATRIX*vec4(relief_normal,0.0)).xyz);","NORMAL = safe_normalize((VIEW_MATRIX*vec4(vec3(0.,1.,0.),0.)).xyz);");ground.shader=shader
		for i in range(36):await process_frame
		await capture("diagnostic_"+mode);rows.append({"mode":mode,"settings":settings()})
	ground.shader=original;ground.set_shader_parameter("ground_contact_enabled",contact);demo.sun.shadow_enabled=true;demo.environment_rig.environment.ssao_enabled=true
	return rows
func measure(moving:bool)->Dictionary:
	var frame:Array=[];var gpu:Array=[];var cpu:Array=[];var setup:Array=[];var draws:Array=[]
	var base_yaw:float=demo.yaw;var base_focus:Vector3=demo.focus;var previous:=Time.get_ticks_usec()
	for i in range(72):
		if moving:
			demo.yaw=base_yaw+.13*sin(float(i)*TAU/72.);demo.focus=base_focus+Vector3(sin(float(i)*TAU/72.)*.8,0,cos(float(i)*TAU/72.)*.5);demo._update_camera()
		await process_frame;await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec();frame.append((now-previous)/1000.);previous=now
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()));cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()));setup.append(RenderingServer.get_frame_setup_time_cpu());draws.append(float(root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)))
	demo.yaw=base_yaw;demo.focus=base_focus;demo._update_camera()
	return {"frame_ms":summary(frame),"gpu_ms":summary(gpu),"render_cpu_ms":summary(cpu),"setup_cpu_ms":summary(setup),"draw_calls":summary(draws),"video_memory_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)}
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--candidate="):candidate_path=arg.trim_prefix("--candidate=")
		if arg.begins_with("--variant="):variant=arg.trim_prefix("--variant=")
		if arg.begins_with("--expected-renderer="):expected_renderer=arg.trim_prefix("--expected-renderer=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var started:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	check(RenderingServer.get_current_rendering_method()==expected_renderer,"actual renderer equals requested comparison")
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	print("LIGHTING_STAGE empty_scene_ready")
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))
	var chosen:={"ok":true,"id":"lighting300","title":"光照比较300","world":world,"view":{"focus":[-16.,.8,20.],"zoom":32.,"yaw":-.6,"pitch":.65,"evening":false,"light_phase":0}}
	await demo.gallery._open_chosen(chosen);await settle();quiet()
	print("LIGHTING_STAGE all_houses_ready")
	check(demo.state.houses.size()==300 and demo.town.house_roots.size()==300,"all authored 300 houses published")
	demo.set_process(false);demo.life.set_process(false);demo.town.set_process(false);demo.town.wildlife.set_process(false);demo.ui_layer.hide();demo.town.clear_preview();freeze_wind(0.)
	var author:=var_to_bytes(demo.state.snapshot());var geometry:=geometry_signature();var shape:=shape_signature();var rows:Array=[]
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var subjects:Array=["town","facade"]
	if OS.get_cmdline_user_args().has("--diagnostics"):rows=await diagnostics();subjects=[]
	for subject:String in subjects:
		demo.focus=Vector3(-16.,.8,20.);demo.zoom=32.;demo.pitch=.65;demo.yaw=-.6
		if subject=="facade":demo.focus=Vector3(-19.,.85,24.);demo.zoom=13.;demo.pitch=.26;demo.yaw=-.65
		demo._update_camera()
		for phase in range(3):
			print("LIGHTING_STAGE ",subject," ",phase)
			configure(phase);freeze_wind(0.)
			for i in range(48):await process_frame
			await capture(subject+"_"+str(phase));var row:={"subject":subject,"phase":phase,"settings":settings(),"static":await measure(false)}
			freeze_wind(-1.);row.moving=await measure(true);rows.append(row)
	check(geometry_signature()==geometry and var_to_bytes(demo.state.snapshot())==author,"camera and light keep exact geometry and author data")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save bytes unchanged")
	var sources:={"tool":FileAccess.get_sha256("res://tools/check_creation_lighting_comparison_live.gd"),"environment":FileAccess.get_sha256("res://scripts/visual/city_creation_environment.gd"),"candidate":FileAccess.get_sha256(candidate_path) if not candidate_path.is_empty() else ""}
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"variant":variant,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"geometry_sha256":geometry,"shape":shape,"author_sha256":author.hex_encode().sha256_text(),"seconds":(Time.get_ticks_msec()-started)/1000.,"views":rows,"persistence":demo.persistence,"sources_sha256":sources,"animation_scope":"screenshots freeze foliage/meadow wind; water and other shader TIME remain live; moving combines camera and wind"}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("LIGHTING_COMPARISON ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds,"renderer":report.renderer}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
