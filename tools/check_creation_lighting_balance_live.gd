extends "res://tools/check_creation_lighting_comparison_live.gd"
## Same town, colors and cameras; compare practical light balance and night fill.
const Candidate=preload("res://tests/fixtures/published_baselines/lighting_balance_20261105/light_candidate.gd")
const Wall=preload("res://scripts/visual/city_creation_wall_material.gd")
const Batch=preload("res://scripts/visual/city_creation_mesh_batcher.gd")
func effective_strength(material:ShaderMaterial)->Variant:
	var value:Variant=material.get_shader_parameter("window_bounce_strength")
	return RenderingServer.shader_get_parameter_default(material.shader.get_rid(),"window_bounce_strength") if value==null else value
func sample_board()->Node3D:
	var board:=Node3D.new();board.name="VerificationMaterialSamples";demo.town.add_child(board)
	for kind in range(7):
		var node:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.40;sphere.height=.8;node.mesh=sphere;board.add_child(node)
		var at:=Vector2(-20.5+kind*1.15,37.);node.position=Vector3(at.x,demo.state.ground_height(at)+.6,at.y)
		node.material_override=Wall.source(Color(["e5dfcd","a9aaa0","ba7754","657d78","e0dacf","648274","d6bb74"][kind]),null,"component",kind)
	Batch.new().merge(board);return board
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--expected-renderer="):expected_renderer=arg.trim_prefix("--expected-renderer=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var started:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))
	var chosen:={"ok":true,"id":"balance300","title":"光影层次300","world":world,"view":{"focus":[-16.,.8,20.],"zoom":32.,"yaw":-.6,"pitch":.65,"evening":false,"light_phase":0}}
	await demo.gallery._open_chosen(chosen);demo.life.set_process(false);await settle();quiet();demo.set_process(false);demo.town.set_process(false);demo.town.wildlife.set_process(false);demo.ui_layer.hide();demo.town.clear_preview();freeze_wind(0.)
	check(RenderingServer.get_current_rendering_method()==expected_renderer,"actual requested renderer")
	check(demo.state.houses.size()==300 and demo.town.house_roots.size()==300,"complete authored 300-house scene")
	var author:=var_to_bytes(demo.state.snapshot());var board:=sample_board();var rows:Array=[]
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var variants:Array=["baseline","natural","gentle"]
	if OS.get_cmdline_user_args().has("--production-only"):
		variants=["production"];check(root.msaa_3d==Viewport.MSAA_2X,"project default uses measured 2x MSAA")
	for variant_name:String in variants:
		for subject:String in ["town","facade","samples"]:
			board.visible=subject=="samples";demo.focus=Vector3(-16.,.8,20.);demo.zoom=32.;demo.pitch=.65;demo.yaw=-.6
			if subject=="facade":demo.focus=Vector3(-19.,.85,24.);demo.zoom=13.;demo.pitch=.26;demo.yaw=-.65
			if subject=="samples":demo.focus=Vector3(-17.,.65,37.);demo.zoom=8.;demo.pitch=.4;demo.yaw=.05
			demo._update_camera()
			for phase in range(3):
				if variant_name=="production":demo._set_light_phase(phase)
				else:Candidate.apply(demo,variant_name,phase)
				freeze_wind(0.)
				check(demo.light_phase==phase and demo.town.light_phase==phase,"environment and city phase agree: "+variant_name+"/"+subject+"/"+str(phase))
				for i in range(24):await process_frame
				var targets:Array=preload("res://scripts/visual/city_creation_window_bounce.gd").materials(demo.town)
				await capture(variant_name+"_"+subject+"_"+str(phase));var row:={"variant":variant_name,"subject":subject,"phase":phase,"settings":settings(),"city_phase":demo.town.light_phase,"window_bounce_strengths":targets.map(effective_strength),"window_bounce_overrides":targets.map(func(material):return material.get_shader_parameter("window_bounce_strength")),"window_material_count":targets.size()}
				if subject=="town" and phase==0:
					row.static=await measure(false);freeze_wind(-1.);row.moving=await measure(true)
				rows.append(row);print("BALANCE_VIEW ",variant_name," ",subject," ",phase)
	board.queue_free();demo._set_light_phase(0)
	var replay:Array=[]
	if variants==["production"]:
		var targets:Array=preload("res://scripts/visual/city_creation_window_bounce.gd").materials(demo.town)
		check(targets.all(func(material):return effective_strength(material)==0.),"all available ground/road/grass materials disable glow by effective shader default")
		var overrides:Array=targets.map(func(material):return material.get_shader_parameter("window_bounce_strength"));var msaa:Viewport.MSAA=root.msaa_3d
		var previous:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/PlayTest/lighting_balance_20261105/gl_variants_v2/report.json"))
		for row:Dictionary in previous.views:
			if row.subject!="town":continue
			Candidate.apply(demo,row.variant,int(row.phase));var actual:Dictionary=JSON.parse_string(JSON.stringify(settings(),"",true,true))
			replay.append({"variant":row.variant,"phase":row.phase,"same_environment_and_sun":actual.environment==row.settings.environment and actual.sun==row.settings.sun and actual.msaa_3d==row.settings.msaa_3d})
		check(replay.size()==9 and replay.all(func(row):return row.same_environment_and_sun),"saved control rig reproduces all nine recorded lighting settings")
		for i in range(targets.size()):targets[i].set_shader_parameter("window_bounce_strength",overrides[i])
		root.msaa_3d=msaa;demo._set_light_phase(0)
	check(var_to_bytes(demo.state.snapshot())==author,"all material/light comparisons preserve authored records")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"views":rows,"seconds":(Time.get_ticks_msec()-started)/1000.,"source_sha256":{"tool":FileAccess.get_sha256("res://tools/check_creation_lighting_balance_live.gd"),"candidate":FileAccess.get_sha256("res://tests/fixtures/published_baselines/lighting_balance_20261105/light_candidate.gd"),"environment":FileAccess.get_sha256("res://scripts/visual/city_creation_environment.gd"),"window_shader":FileAccess.get_sha256("res://scripts/visual/shaders/creation_window_bounce.gdshaderinc"),"project":FileAccess.get_sha256("res://project.godot")},"persistence":demo.persistence,"collection_directory":demo.collection_directory,"scope":"Diagnostic board only in samples views; frozen foliage/grass screenshots, other shader TIME remains live; movement benchmark includes camera and wind; technical checks do not accept visual quality"}
	report.control_replay=replay
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("LIGHT_BALANCE ",JSON.stringify({"ok":report.ok,"checks":checks,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
