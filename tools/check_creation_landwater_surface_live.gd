extends "res://tools/check_creation_lighting_comparison_live.gd"
const Bank=preload("res://tools/fixtures/city_creation_shore_road_fixture.gd")
func terrain_signature()->String:
	var rows:Array=[]
	for node:MeshInstance3D in demo.town.terrain_surface.find_children("*","MeshInstance3D",true,false):rows.append(var_to_bytes([str(node.name),node.transform,node.mesh.surface_get_arrays(0)]).hex_encode().sha256_text())
	rows.sort();return var_to_bytes(rows).hex_encode().sha256_text()
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input()
	var rows:Array=[];var worlds:Dictionary={};var shapes:Dictionary={}
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	for fixture:String in ["sculpted","bank_road"]:
		var city:RefCounted
		if fixture=="sculpted":city=State.new();check(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://数据/地貌河湾样例.json"))).ok,"existing authored ridge and pond fixture restores")
		else:
			var sample:Dictionary=Bank.build("slope",.35);city=sample.city;check(sample.ok,"real public rotated sloping bank road fixture")
		await show(city,Vector2(12,9) if fixture=="sculpted" else Vector2(-28,-20),"自然陆水对照");quiet();demo.life.set_process(false);demo.set_process(false);demo.town.set_process(false);demo.town.wildlife.hide();demo.weather_visual.hide();demo.ui_layer.hide();demo.town.clear_preview()
		var author:=var_to_bytes(demo.state.snapshot());var shape:=terrain_signature();worlds[fixture]=JSON.stringify(demo.state.snapshot(),"",true,true).sha256_text();shapes[fixture]=shape
		for subject:String in (["valley","ridge","pond","pond_overhead","river"] if fixture=="sculpted" else ["road","road_low"]):
			demo.focus=Vector3(12.4,.2,8.8);demo.zoom=13.;demo.pitch=.78;demo.yaw=.62
			if subject=="valley":demo.focus=Vector3(0,.3,0);demo.zoom=52.;demo.pitch=.8;demo.yaw=.2
			elif subject=="ridge":demo.focus=Vector3(17,1.2,11);demo.zoom=9.;demo.pitch=.30
			elif subject=="pond_overhead":demo.focus=Vector3(12.4,.2,8.8);demo.zoom=8.;demo.pitch=1.35;demo.yaw=.62
			elif subject=="river":demo.focus=Vector3(5,-.1,-16);demo.zoom=11.;demo.pitch=.35;demo.yaw=-.3
			elif fixture=="bank_road":demo.focus=Vector3(-28,.2,-21);demo.zoom=11.;demo.pitch=.10 if subject=="road_low" else .7;demo.yaw=.35
			demo._update_camera()
			for phase in range(3):
				demo._set_light_phase(phase);freeze_wind(0.)
				for i in range(18):await process_frame
				await capture(fixture+"_"+subject+"_"+str(phase));var row:={"fixture":fixture,"subject":subject,"phase":phase,"settings":settings()}
				if subject=="pond" and phase==0:row.static=await measure(false);freeze_wind(-1.);row.moving=await measure(true)
				rows.append(row)
		check(author==var_to_bytes(demo.state.snapshot()) and shape==terrain_signature(),"three-phase cameras preserve authored "+fixture+" terrain and native triangle buffers")
		demo.set_process(true);demo.town.set_process(true)
	check(not demo.persistence and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"isolated landwater test preserves personal save boundary")
	var hashes:Dictionary={}
	for n:String in ["scripts/visual/shaders/creation_ground.gdshader","scripts/visual/shaders/creation_lawn.gdshader","scripts/visual/shaders/creation_road_edge.gdshader","scripts/visual/shaders/creation_valley.gdshader","scripts/visual/shaders/creation_water.gdshader","scripts/visual/shaders/creation_shore_palette.gdshaderinc","scripts/visual/city_creation_shore_palette.gd","scripts/world/city_creation_terrain.gd","scripts/visual/city_creation_surface_height_field.gd","scripts/visual/shaders/creation_surface_height.gdshaderinc","scripts/visual/city_creation_renderer.gd","scripts/visual/city_creation_budget_rebuild.gd","tools/check_creation_landwater_surface_live.gd"]:hashes[n]=FileAccess.get_sha256("res://"+n)
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"views":rows,"world_sha256":worlds,"terrain_sha256":shapes,"source_sha256":hashes,"scope":"actual old sculpted fixture and public bank-road fixture; foliage wind frozen screenshots, water TIME live; pond/day72-frame camera+wind samples; no subjective art pass"}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("LANDWATER_SURFACE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
