extends "res://tools/check_creation_lighting_comparison_live.gd"
const Old=preload("res://tests/fixtures/published_baselines/grass_remake_20261106/baseline/meadow_adapter.gd")
const Garden=preload("res://tools/fixtures/city_creation_space_contract_fixture.gd")
const Mask=preload("res://scripts/visual/city_creation_grass_mask.gd")
func buffers()->String:
	var rows:Array=[]
	for node:MultiMeshInstance3D in demo.town.meadow.find_children("*","MultiMeshInstance3D",true,false):rows.append([str(demo.town.meadow.get_path_to(node)),node.multimesh.buffer])
	return var_to_bytes(rows).hex_encode().sha256_text()
func install(bank)->void:
	for node:MultiMeshInstance3D in demo.town.meadow.find_children("*","MultiMeshInstance3D",true,false):
		var part:String=String(node.name).trim_prefix("Meadow_")
		if part not in ["lawn","grass"]:continue
		var source:String="lawn_lod" if part=="lawn" and demo.town.meadow.detail<=.84375 else part
		node.multimesh.mesh=bank._mesh(source);node.material_override=bank._material(part)
		if not node.has_meta("production_aabb"):node.set_meta("production_aabb",node.multimesh.custom_aabb)
		# Same culling envelope in both stages; includes full current and old shape.
		var bounds:AABB=node.get_meta("production_aabb");var mesh_bounds:AABB=node.multimesh.mesh.get_aabb()
		for i in range(node.multimesh.visible_instance_count):bounds=bounds.merge((node.multimesh.get_instance_transform(i)*mesh_bounds).grow(.12))
		node.multimesh.custom_aabb=bounds
	for part:String in ["lawn","grass"]:
		bank._material(part).set_shader_parameter("detail",demo.town.meadow.detail if part=="lawn" else 1.);bank._material(part).set_shader_parameter("meadow_time_override",0.)
func bounds_and_edges()->void:
	var totals:={"lawn":0,"grass":0};var sampled:={"lawn":0,"grass":0};var vertices:=0;var contained:=true;var clear:=true;var root_failures:Array=[];var vertex_failures:Array=[]
	for block:Vector2i in demo.town.meadow.blocks:
		var parent:Node3D=demo.town.meadow.blocks[block];var mask:=Mask.new();mask.setup(demo.state,block)
		for part:String in ["lawn","grass"]:
			var node:=parent.get_node_or_null("Meadow_"+part) as MultiMeshInstance3D
			if node==null:continue
			var arrays:Array=demo.town.meadow._mesh(part).surface_get_arrays(0);var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var uvs:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			var production:AABB=node.get_meta("production_aabb") if node.has_meta("production_aabb") else node.multimesh.custom_aabb
			var envelope:AABB=demo.town.meadow._mesh(part).get_aabb();envelope=envelope.expand(Vector3(envelope.end.x,envelope.end.y*1.284,envelope.end.z));envelope=envelope.expand(Vector3(envelope.position.x,envelope.position.y-.020,envelope.position.z))
			for i in range(node.multimesh.visible_instance_count):
				var transform:=node.multimesh.get_instance_transform(i);var custom:=node.multimesh.get_instance_custom_data(i);var origin:=parent.global_transform*transform.origin;totals[part]+=1
				contained=contained and production.grow(.00001).encloses((transform*envelope).grow(.06))
				# Tall accents use .18 base roots; tree skirts reserve .25. Both must
				# satisfy the common smaller root margin and full displaced vertex test.
				var root_clear:=mask.visible(Vector2(origin.x,origin.z),.18)
				clear=clear and root_clear
				if not root_clear and root_failures.size()<8:root_failures.append({"part":part,"origin":str(origin)})
				if sampled[part]>=32 or custom.b>=.95:continue
				sampled[part]+=1
				for index in range(points.size()):
					for gust:float in [-1.,1.]:
						var v:Vector3=points[index];var tip:=uvs[index].y;var h:=clampf(custom.b,0.,1.);var species:=clampf(custom.a,0.,1.)
						v.y*=1.07*h*lerpf(1.,1.2,species);v.y-=(1.-smoothstep(0.,.30,tip))*.020
						v.z*=lerpf(1.,.78 if part=="grass" else .46,species);v.x*=lerpf(.20,1.,h);v.z*=lerpf(.20,1.,h)
						var push_tip:=clampf(tip*255.*.011764707043766975,0.,1.)
						v+=transform.basis.inverse()*Vector3(custom.r,0.,custom.g)*4.*(1.-h)*h*push_tip*push_tip*.045
						v+=transform.basis.inverse()*Vector3(.82,0.,.57)*(-gust*.09*tip*tip*.25*1.1144999265670776)*h
						var local:=transform*v;contained=contained and production.grow(.00001).has_point(local)
						var world:=parent.global_transform*local;var distance:float=mask.continuous_edge(Vector2(world.x,world.z)).clearance;clear=clear and distance>=-.00001;vertices+=1
						if distance<-.00001 and vertex_failures.size()<8:vertex_failures.append({"part":part,"origin":str(origin),"vertex":str(world),"clearance":distance})
	check(contained and sampled.lawn>0 and sampled.grass>0,"actual production short/tall AABBs contain sampled full-blade species and wind extremes")
	check(clear,"all actual roots and sampled short/tall blade extremes stay outside buildings roads and water")
	facts.edges={"roots":totals,"sampled_clumps":sampled,"vertex_extremes":vertices,"root_failures":root_failures,"vertex_failures":vertex_failures}
func wind_probe()->void:
	var viewport:=SubViewport.new();viewport.size=Vector2i(256,256);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.7;viewport.add_child(environment)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-35,0);viewport.add_child(light)
	var camera:=Camera3D.new();viewport.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.8;camera.position=Vector3(2,1.5,3);camera.look_at(Vector3(0,.25,0))
	var node:=MultiMeshInstance3D.new();var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_custom_data=true;multi.mesh=demo.town.meadow._mesh("grass");multi.instance_count=9
	for i in range(9):multi.set_instance_transform(i,Transform3D(Basis(Vector3.UP,float(i)*.7),Vector3((i%3-1)*.36,0,(i/3-1)*.36)));multi.set_instance_custom_data(i,Color(0,0,1,.65))
	var material:ShaderMaterial=demo.town.meadow._material("grass").duplicate();material.set_shader_parameter("bank_sand_enabled",false);material.set_shader_parameter("ground_contact_enabled",false);material.set_shader_parameter("road_draft_enabled",false)
	node.multimesh=multi;node.material_override=material;viewport.add_child(node);var cpu:=var_to_bytes(multi.mesh.surface_get_arrays(0));var buffer:=multi.buffer;var images:Array[Image]=[]
	for time:float in [.2,2.3]:
		material.set_shader_parameter("meadow_time_override",time);await process_frame;await process_frame;await RenderingServer.frame_post_draw;var image:Image=viewport.get_texture().get_image();images.append(image);image.save_png(OUT+"/isolated_wind_"+str(images.size())+".png")
	var changed:=0
	for y in range(256):
		for x in range(256):
			if images[0].get_pixel(x,y)!=images[1].get_pixel(x,y):changed+=1
	check(changed>100 and multi.buffer==buffer and var_to_bytes(multi.mesh.surface_get_arrays(0))==cpu,"actual GPU grass wind changes pixels while CPU shared mesh and instance bytes remain exact")
	facts.wind={"changed_pixels":changed,"size":[256,256],"scope":"nine isolated production tall exemplars; contact and shore fields disabled; only wind override changes"};viewport.queue_free();await process_frame
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:RefCounted=Garden.courtyard("ring","none").city
	check(city.add_road([Vector2(-33,-10),Vector2(-26,-9),Vector2(-17,-10)] as Array[Vector2],"path","none").ok,"actual curved path fixture")
	check(city.add_water([Vector2(-33,-17)] as Array[Vector2],2.,"pond").ok,"actual pond fixture")
	for at:Vector2 in [Vector2(-20,-8),Vector2(-17,-14),Vector2(-32,-12)]:check(city.place_plant(at,"shrub").ok,"real shrub creates tall fringe "+str(at))
	await show(city,Vector2(-24,-13),"高草与草坪重制");quiet();demo.life.set_process(false);demo.set_process(false);demo.town.set_process(false);demo.town.wildlife.set_process(false);demo.ui_layer.hide();demo.town.clear_preview()
	demo.town.wildlife.hide()
	demo.weather_visual.hide()
	for node:GPUParticles3D in demo.find_children("*","GPUParticles3D",true,false):node.hide()
	var author:=var_to_bytes(demo.state.snapshot());var signature:=buffers();var old:=Old.new();old.state=demo.state;old.water_field=demo.town.meadow.water_field
	for part:String in ["lawn","grass"]:
		var source:ShaderMaterial=demo.town.meadow._material(part);var target:ShaderMaterial=old._material(part)
		for uniform:Dictionary in target.shader.get_shader_uniform_list():
			var value=source.get_shader_parameter(uniform.name)
			if value!=null:target.set_shader_parameter(uniform.name,value)
	var same:=true
	for block:Vector2i in demo.town.meadow.base_candidates:same=same and old._build_base_candidates(block)==demo.town.meadow.base_candidates[block]
	for plant:Dictionary in demo.state.plants:same=same and old._build_plant_candidates(plant)==demo.town.meadow._build_plant_candidates(plant)
	check(same,"frozen original builder reproduces every actual candidate field and tree-skirt seed tuple")
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true);facts.views=[]
	for subject:String in ["court","close","side","far"]:
		demo.focus=Vector3(-24,.3,-10);demo.yaw=.25;demo.pitch=.8;demo.zoom=18.
		if subject=="close":demo.focus=Vector3(-20,.20,-8);demo.zoom=5.;demo.pitch=.38
		elif subject=="side":demo.focus=Vector3(-20,.20,-8);demo.zoom=6.;demo.pitch=.10;demo.yaw=2.5
		elif subject=="far":demo.zoom=36.
		demo._update_camera()
		if subject=="close":bounds_and_edges()
		for phase in range(3):
			demo._set_light_phase(phase)
			for stage:String in ["before","after"]:
				var bank=old if stage=="before" else demo.town.meadow;install(bank)
				for i in range(12):await process_frame
				await capture(stage+"_"+subject+"_"+str(phase));var row:={"subject":subject,"stage":stage,"phase":phase,"detail":demo.town.meadow.detail}
				if subject=="court" and phase==0:
					row.static=await measure(false)
					for part:String in ["lawn","grass"]:bank._material(part).set_shader_parameter("meadow_time_override",-1.)
					row.moving=await measure(true)
				facts.views.append(row)
	check(buffers()==signature and var_to_bytes(demo.state.snapshot())==author,"all actual candidate GPU buffers and authored records remain exact")
	await wind_probe()
	check(not demo.persistence and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"isolated test keeps personal save bytes and collection boundary")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-began)/1000.,"scope":"foreground meadow bank A/B, frozen actors/UI; wind frozen screenshots, moving sample combines camera/wind; only court/day performance; original roots and masks"}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("GRASS_REMAKE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));old.free();demo.queue_free();await process_frame;quit(0 if report.ok else 1)
