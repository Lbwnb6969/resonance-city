extends "res://tools/check_creation_neoclassical_window_glow_live.gd"

const SAMPLE="res://数据/柱廊河湾样例.json"

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();var source:=FileAccess.get_file_as_bytes(SAMPLE);var restored:Dictionary=city.restore(JSON.parse_string(source.get_string_from_utf8()));check(restored.ok,"arcade sample restores")
	await show(city,Vector2(-7.,-4.),"三阶段柱廊灯");quiet();demo.focus=Vector3(-7.,1.,-4.);demo.zoom=10.;demo.pitch=.55;demo.yaw=0.;demo._update_camera();await settle()
	var lamps:Array=[]
	for mesh:MeshInstance3D in demo.town.find_children("*","MeshInstance3D",true,false):
		var mat:Material=mesh.material_override
		if mat!=null and bool(mat.get_meta("creation_phase_lamp",false)) and not lamps.has(mat):lamps.append(mat)
	check(not lamps.is_empty(),"production arcade/door lamps use the shared phase material")
	var energies:Array=[]
	var before:Dictionary=demo.state.snapshot()
	for phase:int in range(3):
		demo._set_light_phase(phase);await settle();energies.append(float(lamps[0].emission_energy_multiplier));await capture("phase_lamp_"+str(phase))
	facts={"lamp_materials":lamps.size(),"energies":energies}
	check(is_zero_approx(energies[0]) and energies[1]>energies[0] and energies[2]>energies[1],"architectural lamps are dark in day and ramp through dusk to night")
	check(demo.state.snapshot()==before,"lamp phase changes leave authored city unchanged")
	check(personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"personal save remains byte-identical")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"rendering":DisplayServer.get_name(),"persistence":demo.persistence};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("PHASE_LAMP_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
