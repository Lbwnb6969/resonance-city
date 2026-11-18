extends "res://tools/check_creation_neoclassical_window_glow_live.gd"

const EraFixture=preload("res://tests/test_city_creation_eras.gd")

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=EraFixture.fixture();var added:Dictionary=city.add_house(Vector2(18,18));var id:=str(added.house_id);city.add_cell(id,1,0,0);city.add_cell(id,0,1,0);city.add_cell(id,1,1,0);city.set_house_era(id,"renaissance");await show(city,Vector2(18.9,18.9),"穹顶灯窗阶段响应");quiet();demo.focus=Vector3(18.9,1.,18.9);demo.zoom=10.;demo.pitch=.58;demo.yaw=-.55;demo._update_camera();await settle()
	var before:Dictionary=demo.state.snapshot();var lamps:Array=[]
	for hid:String in demo.town.house_roots:
		var house:Node3D=demo.town.house_roots[hid]
		for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
			var mat:Material=mesh.material_override
			if mat!=null and int(mat.get_meta("creation_facade_glass",-1))==3:lamps.append(mesh)
	check(not lamps.is_empty(),"renaissance dome retains a phase-aware lantern glass material after batching")
	if lamps.is_empty():
		var report:={"ok":false,"checks":checks,"failures":failures,"facts":{"lanterns":0},"rendering":DisplayServer.get_name(),"persistence":demo.persistence};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("DOME_WINDOW_PHASE_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(1);return
	var material:StandardMaterial3D=lamps[0].material_override
	var energies:Array=[]
	for phase:int in range(3):
		demo._set_light_phase(phase);await settle();energies.append(float(material.emission_energy_multiplier));await capture("dome_phase_"+str(phase))
	facts={"lanterns":lamps.size(),"energies":energies,"albedo":material.albedo_color.to_html(false)}
	check(is_zero_approx(energies[0]) and energies[1]>energies[0] and energies[2]>energies[1],"lantern window emission is off in daylight and ramps through dusk to night")
	check(demo.state.snapshot()==before,"dome light phase changes leave authored city unchanged")
	check(personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"personal save remains byte-identical")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"rendering":DisplayServer.get_name(),"persistence":demo.persistence};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("DOME_WINDOW_PHASE_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
