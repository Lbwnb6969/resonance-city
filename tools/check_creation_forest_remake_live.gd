extends "res://tools/check_creation_lighting_comparison_live.gd"
const Old=preload("res://tests/fixtures/published_baselines/vegetation_remake_20261106/baseline/foliage_adapter.gd")
func install(bank:RefCounted)->void:
	for node:MultiMeshInstance3D in demo.town.vegetation_layer.find_children("*","MultiMeshInstance3D",true,false):
		if not node.has_meta("source_part"):
			for key:String in demo.town.tree_meshes:
				if demo.town.tree_meshes[key]==node.multimesh.mesh:node.set_meta("source_part",key);break
		var fields:=String(node.get_meta("source_part")).split(":");var parts:Dictionary=bank.parts(fields[0],int(fields[1]));var piece:String=fields[2]
		node.visible=parts.has(piece)
		if not node.visible:continue
		node.multimesh.mesh=parts[piece];node.material_override=bank.material(piece);node.multimesh.custom_aabb=AABB();node.multimesh.custom_aabb=node.multimesh.get_aabb().grow(.12)
	bank.material("canopy").set_shader_parameter("wind_time_override",0.)
func placements()->String:
	var rows:Array=[]
	for node:MultiMeshInstance3D in demo.town.vegetation_layer.find_children("*","MultiMeshInstance3D",true,false):rows.append(var_to_bytes([str(node.name),node.multimesh.buffer]).hex_encode().sha256_text())
	rows.sort();return var_to_bytes(rows).hex_encode().sha256_text()
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();var kinds:Array=["olive","cypress","golden_tree","weeping_willow","shrub"];var added:=0;var river_rejected:Array=[]
	for z in range(15):
		for x in range(19):
			var point:=Vector2(-28+x*2.6,-24+z*2.6);var kind:String=kinds[(z*19+x)%5]
			if city.place_plant(point,kind).ok:added+=1
			else:
				var clearance:float=State.GardenSpecies.clearance(kind,1.)
				river_rejected.append({"point":[point.x,point.y],"kind":kind,"water_distance":city.water_clearance(point),"required_clearance":clearance})
	check(added>200 and added==city.plants.size() and added+river_rejected.size()==285 and river_rejected.all(func(row):return row.water_distance<=row.required_clearance),"285 real author attempts produce a dense dry-land forest; only river clearance rejects positions")
	await show(city,Vector2(-8,-8.6),"真实混合树林");quiet();demo.life.set_process(false);demo.set_process(false);demo.town.set_process(false);demo.town.wildlife.set_process(false);demo.ui_layer.hide();demo.town.clear_preview()
	var author:=var_to_bytes(demo.state.snapshot());var transforms:=placements();var old:=Old.new();var rows:Array=[]
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	for stage:String in ["before","after"]:
		var bank:RefCounted=old if stage=="before" else demo.town.foliage;install(bank)
		for subject:String in ["grove","close","distant"]:
			demo.focus=Vector3(-8,.8,-8.6);demo.zoom=45.;demo.pitch=.55;demo.yaw=-.15
			if subject=="close":demo.focus=Vector3(-14,1.1,1.5);demo.zoom=12.;demo.pitch=.23;demo.yaw=-.35
			if subject=="distant":demo.zoom=64.;demo.pitch=.9
			demo._update_camera()
			for phase in range(3):
				demo._set_light_phase(phase);bank.material("canopy").set_shader_parameter("wind_time_override",0.)
				for i in range(24):await process_frame
				await capture(stage+"_"+subject+"_"+str(phase));var row:={"stage":stage,"subject":subject,"phase":phase,"settings":settings()}
				if subject=="grove" and phase==0:
					row.static=await measure(false);bank.material("canopy").set_shader_parameter("wind_time_override",-1.);row.moving=await measure(true)
				rows.append(row)
	check(placements()==transforms and var_to_bytes(demo.state.snapshot())==author,"all actual GPU instance transforms and authored forest records remain exact")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"plants":added,"river_rejected":river_rejected,"renderer":RenderingServer.get_current_rendering_method(),"views":rows,"seconds":(Time.get_ticks_msec()-began)/1000.,"persistence":demo.persistence,"collection_directory":demo.collection_directory,"scope":"real published author forest; only foreground vegetation bank is swapped, background grove stays current in both stages; paused simulation/hidden UI; moving combines camera and wind"}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("FOREST_REMAKE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
