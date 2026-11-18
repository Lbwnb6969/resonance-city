extends "res://tools/check_creation_neoclassical_window_glow_live.gd"
const Fixture=preload("res://tests/test_city_creation_clockwork_roof_pitch.gd")

func verify_house(id:String)->Array:
	var house:Node3D=demo.town.house_roots[id]
	var panes:Array=house.get_meta("roof_window_panes",[]).filter(func(row):return row.get("source","")=="clockwork_roof")
	var rig:Dictionary=demo.town.resonance.rigs[id]
	var windows:Array=rig.mesh.get_meta("windows",[]).filter(func(row):return row.get("kind","")=="clockwork_roof")
	var materials:Array=[];var actual:=PackedVector3Array();var inverse:=house.global_transform.affine_inverse()
	for mesh:MeshInstance3D in house.find_children("MansardDormerGlass*","MeshInstance3D",true,false):
		materials.append(mesh.material_override)
		for point:Vector3 in mesh.mesh.get_faces():actual.append(inverse*mesh.global_transform*point)
	var triangles:=0;var emitted:=0;var error:=0.;var geometry_matches:=true
	var vertices:PackedVector3Array=rig.mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for pane:Dictionary in panes:
		var faces:PackedVector3Array=pane.faces;triangles+=faces.size()/3
		for point:Vector3 in faces:
			var distance:=INF
			for source:Vector3 in actual:distance=minf(distance,point.distance_to(source))
			error=maxf(error,distance)
		for i in range(0,faces.size(),3):
			var normal:Vector3=(faces[i+2]-faces[i]).cross(faces[i+1]-faces[i]).normalized()
			for k in range(3):geometry_matches=geometry_matches and vertices.has(faces[i+k]+normal*.003)
	for window:Dictionary in windows:emitted+=int(window.triangles)
	check(materials.size()==2 and panes.size()==2 and triangles==8 and emitted==triangles,"both real mansard windows are recorded and emitted exactly once "+id)
	check(error<.00002,"recorded window vertices match actual published glazing "+id)
	check(geometry_matches,"night rig contains the actual recorded glass triangles "+id)
	facts[id]={"panes":panes.size(),"triangles":triangles,"emitted_triangles":emitted,"maximum_vertex_error_m":error}
	return materials

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=Fixture.fixture("");city.set_house_roof_pitch("h1",45.)
	city.add_house(Vector2(-20,-20));city.set_house_era("h2","clockwork");city.add_cell("h2",0,0,1);city.set_house_architecture("h2","recessed_townhouse");city.set_house_roof_pitch("h2",60.);city.rotate_house("h2",.6)
	await show(city,Vector2(-22.5,-20),"钟表自动屋顶窗昼夜");quiet();demo.life.set_process(false);demo.ui_layer.hide();demo.music.muted=true
	demo.focus=Vector3(-22.5,2.5,-20);demo.zoom=11.;demo.pitch=.58;demo.yaw=-.65;demo._update_camera();await settle()
	var author:Dictionary=demo.state.snapshot();var materials:=verify_house("h1");materials.append_array(verify_house("h2"))
	var energies:Array=[]
	for phase:int in [0,1,2]:
		demo._set_light_phase(phase);await settle()
		var energy:float=materials[0].emission_energy_multiplier;energies.append(energy)
		check(materials.all(func(material):return is_equal_approx(material.emission_energy_multiplier,energy)),"all automatic roof windows share light phase "+str(phase))
		await capture("clockwork_phase_"+str(phase))
	check(is_zero_approx(float(energies[0])) and energies[1]>0. and energies[2]>energies[1],"automatic clockwork glass is neutral by day with graduated dusk and night emission")
	for id:String in ["h1","h2"]:
		demo.town.resonance.update({"audible":true,"lead_id":id,"beat_pulse":1.,"clock_sec":.5})
		check(is_equal_approx(demo.town.resonance.rigs[id].pivot.scale.y,1.),"maximum lead beat keeps roof window glow on the stationary actual glass "+id)
	check(demo.state.snapshot()==author,"lighting leaves author city unchanged")
	check(personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"personal save remains byte-identical")
	facts.energies=energies;facts.seconds=(Time.get_ticks_msec()-began)/1000.
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"rendering":DisplayServer.get_name(),"persistence":demo.persistence}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("CLOCKWORK_WINDOW_GLOW_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
