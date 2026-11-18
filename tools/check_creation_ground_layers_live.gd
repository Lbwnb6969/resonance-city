extends "res://tools/check_creation_lighting_comparison_live.gd"
## Temporary layer isolation only; no performance claims from hidden layers.
var layers:Dictionary={}
var originals:Dictionary={}
var layer_visibility:Dictionary={}
func restore_layers()->void:
	for key:String in layers:layers[key].visible=layer_visibility[key]
	for node:GeometryInstance3D in originals:node.material_override=originals[node]
func only(key:String)->void:
	for name:String in layers:layers[name].visible=name==key
func plain_shader(world_coordinates:bool=false)->Shader:
	var shader:=Shader.new();shader.code='shader_type spatial;\nrender_mode unshaded,cull_disabled;\nvarying vec3 at;\nvoid vertex(){at=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}\nvoid fragment(){ALBEDO='+('vec3(fract((at.x+48.)/16.),.2,fract((at.z+48.)/16.))' if world_coordinates else 'vec3(.16,.42,.12)')+';}'
	return shader
func override_layer(key:String,shader:Shader,preserve_inputs:bool=false)->int:
	var material:=ShaderMaterial.new();material.shader=shader
	var copied:=0
	if preserve_inputs:
		for uniform:Dictionary in demo.town.ground_material.shader.get_shader_uniform_list():
			material.set_shader_parameter(uniform.name,demo.town.ground_material.get_shader_parameter(uniform.name));copied+=1
	for node:GeometryInstance3D in originals:
		if layers[key].is_ancestor_of(node):node.material_override=material
	return copied
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--expected-renderer="):expected_renderer=arg.trim_prefix("--expected-renderer=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);var stages:Dictionary={}
	check(RenderingServer.get_current_rendering_method()==expected_renderer,"actual isolated renderer")
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();stages.empty_ms=Time.get_ticks_msec()-began
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))
	var chosen:={"ok":true,"id":"layer300","title":"地表分层300","world":world,"view":{"focus":[-16.,.8,20.],"zoom":32.,"yaw":-.6,"pitch":.65,"evening":false,"light_phase":0}}
	var started:=Time.get_ticks_msec();await demo.gallery._open_chosen(chosen);await settle();quiet();stages.open_city_ms=Time.get_ticks_msec()-started
	check(demo.state.houses.size()==300 and demo.town.house_roots.size()==300,"complete 300-house authored scene")
	demo.set_process(false);demo.life.set_process(false);demo.town.set_process(false);demo.town.wildlife.set_process(false);demo.ui_layer.hide();demo.town.clear_preview();freeze_wind(0.)
	layers={"terrain":demo.town.terrain_surface,"meadow":demo.town.meadow,"outer":demo.town.valley}
	for key:String in layers:
		layer_visibility[key]=layers[key].visible
		for node:GeometryInstance3D in layers[key].find_children("*","GeometryInstance3D",true,false):originals[node]=node.material_override
	var before:=var_to_bytes(demo.state.snapshot());var rows:Array=[]
	var modes:Array=["reference","terrain","meadow","outer","terrain_plain","terrain_world","terrain_albedo","meadow_plain","outer_plain"]
	if OS.get_cmdline_user_args().has("--verification"):modes=["reference","terrain","terrain_albedo_bound","dusk","night","facade"]
	for mode:String in modes:
		restore_layers();demo._set_light_phase(0)
		demo.focus=Vector3(-16.,.8,20.);demo.zoom=32.;demo.pitch=.65;demo.yaw=-.6
		if mode=="facade":demo.focus=Vector3(-19.,.85,24.);demo.zoom=13.;demo.pitch=.26;demo.yaw=-.65
		demo._update_camera()
		if mode in ["dusk","night"]:demo._set_light_phase(1 if mode=="dusk" else 2)
		var copied:=0
		if mode in ["terrain","meadow","outer"]:only(mode)
		elif mode.begins_with("terrain_"):
			only("terrain")
			if mode in ["terrain_albedo","terrain_albedo_bound"]:
				var shader:=Shader.new();shader.code=demo.town.ground_material.shader.code.replace("render_mode diffuse_burley, specular_disabled;","render_mode unshaded;");copied=override_layer("terrain",shader,mode=="terrain_albedo_bound")
			else:override_layer("terrain",plain_shader(mode=="terrain_world"))
		elif mode=="meadow_plain":
			only("meadow")
			var shader:=Shader.new();shader.code=demo.town.meadow.materials.lawn.shader.code.replace("render_mode ","render_mode unshaded, ").replace("ALBEDO=OUTPUT_IS_SRGB ? meadow_linear_to_srgb(albedo) : albedo;","ALBEDO=vec3(.16,.42,.12);")
			override_layer("meadow",shader)
		elif mode=="outer_plain":only("outer");override_layer("outer",plain_shader())
		for i in range(36):await process_frame
		await capture(mode);rows.append({"mode":mode,"elapsed_ms":Time.get_ticks_msec()-began,"visible":layers.keys().filter(func(key):return layers[key].visible),"copied_production_uniforms":copied,"settings":settings()})
		print("GROUND_LAYER ",mode," ",Time.get_ticks_msec()-began)
	restore_layers()
	check(originals.keys().all(func(node):return node.material_override==originals[node]) and layers.keys().all(func(key):return layers[key].visible==layer_visibility[key]),"all original materials and visibility restored")
	check(var_to_bytes(demo.state.snapshot())==before,"layer diagnostics preserve author state")
	check(FileAccess.get_file_as_bytes(State.DEFAULT_PATH)==personal,"personal save unchanged")
	var sources:Dictionary={}
	for path:String in ["tools/check_creation_ground_layers_live.gd","scripts/visual/shaders/creation_ground.gdshader","scripts/visual/shaders/creation_lawn.gdshader","scripts/visual/shaders/creation_valley.gdshader","scripts/visual/shaders/creation_meadow_palette.gdshaderinc"]:sources[path]=FileAccess.get_sha256("res://"+path)
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"renderer":RenderingServer.get_current_rendering_method(),"author_sha256":before.hex_encode().sha256_text(),"stages":stages,"cases":rows,"sources_sha256":sources,"persistence":demo.persistence,"collection_directory":demo.collection_directory,"limit":"Visibility isolation is diagnostic only; no performance comparison. Only terrain_albedo_bound copies production uniform/texture bindings; other diagnostic overrides use defaults."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("GROUND_LAYERS ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
