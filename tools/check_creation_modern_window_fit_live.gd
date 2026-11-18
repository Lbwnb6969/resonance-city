extends "res://tools/check_creation_shape_palette_live.gd"
const Glass=preload("res://scripts/visual/shaders/creation_conservatory_glass.gdshader")
func actual_panes(id:String)->Array:
	var panes:Array=[];var house:Node3D=demo.town.house_roots[id]
	for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
		if mesh.material_override is ShaderMaterial and mesh.material_override.shader==Glass:
			panes.append({"inverse":mesh.global_transform.affine_inverse()*house.global_transform,"bounds":mesh.mesh.get_aabb()})
	return panes
func contains_light(pane:Dictionary,at:Vector3)->bool:
	var p:Vector3=pane.inverse*at;var b:AABB=pane.bounds
	var error:float=maxf(absf(p.z-b.end.z-.002),maxf(maxf(b.position.x-p.x,p.x-b.end.x),maxf(b.position.y-p.y,p.y-b.end.y)))
	return error<.00015
func fits(id:String)->bool:
	var panes:=actual_panes(id);var row:Dictionary=demo.town.resonance.rigs[id];var mesh:MeshInstance3D=row.mesh
	var pose:Transform3D=demo.town.house_roots[id].global_transform.affine_inverse()*mesh.global_transform
	var arrays:=mesh.mesh.surface_get_arrays(0);var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR];var count:=0
	for i in range(points.size()):
		if roundi(colors[i].r*8.)!=0:continue
		count+=1
		var nearest:=INF
		for pane:Dictionary in panes:
			var p:Vector3=pane.inverse*pose*points[i];var b:AABB=pane.bounds
			nearest=minf(nearest,maxf(absf(p.z-b.end.z-.002),maxf(maxf(b.position.x-p.x,p.x-b.end.x),maxf(b.position.y-p.y,p.y-b.end.y))))
		facts.max_pane_error=maxf(float(facts.get("max_pane_error",0.)),nearest)
		if nearest>=.00015:return false
	return count>0
func snapshot_meshes()->Array:
	var result:Array=[]
	for house:Node3D in demo.town.house_roots.values():
		for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
			if mesh.name in ["ResonanceVisualRig","ResonanceArc"]:continue
			for s in range(mesh.mesh.get_surface_count()):result.append(hash([mesh.mesh.surface_get_arrays(s),mesh.global_transform]))
	return result
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free()
	var kinds:Array=["chalet","pavilion","terrace","panorama","twin_gable","green_lodge"]
	for i in range(kinds.size()):
		var at:=Vector2(-30+(i%3)*7,-27+(i/3)*8);Brush.select(city,"modern_eco",kinds[i]);check(city.add_house(at).ok,"actual public modern type "+kinds[i])
	check(city.rotate_house("h4",.37).ok,"actual oblique panorama")
	await show(city,Vector2(-23,-23),"真实现代窗灯");await settle();quiet();demo.life.set_process(false)
	var author:Dictionary=demo.state.snapshot();var construction:=snapshot_meshes()
	for i in range(kinds.size()):
		var id:="h"+str(i+1);var panes:=actual_panes(id);var lights:Array=demo.town.resonance.rigs[id].mesh.get_meta("windows")
		check(not panes.is_empty() and not lights.is_empty(),"actual glass and glow exist "+kinds[i])
		check(lights.all(func(w):return panes.any(func(p):return contains_light(p,w.at))),"every light center lies on real published glass "+kinds[i])
		check(fits(id),"all actual GPU glow vertices fit published glass "+kinds[i])
		facts[kinds[i]]={"glass":panes.size(),"lights":lights.size()}
	demo.set_process(false);demo.town.set_process(false);demo.town.wildlife.hide();demo.ui_layer.hide();demo.weather_visual.hide();Engine.time_scale=0.
	for subject:String in ["chalet","panorama"]:
		demo.focus=Vector3(-30,1.,-27 if subject=="chalet" else -19);demo.zoom=8.;demo.pitch=.48;demo.yaw=-.65;demo._update_camera()
		for phase in [0,2]:
			demo._set_light_phase(phase)
			for row:Dictionary in demo.town.resonance.rigs.values():row.material.set_shader_parameter("night_glow",0. if phase==0 else .35);row.mesh.show()
			for n in range(48):await process_frame
			await capture(subject+"_"+str(phase))
	check(demo.state.snapshot()==author and snapshot_meshes()==construction,"phase and view preserve author world and construction buffers")
	Engine.time_scale=1.;demo.set_process(true)
	demo._after_edit(demo.state.rotate_house("h4",.63),"history");await settle();check(fits("h4"),"incremental rotated panorama keeps actual panes aligned")
	await key(KEY_Z,true);await settle();check(demo.state.houses==author.houses and fits("h4"),"native Undo restores author rotation and aligned panes")
	var cold:=State.new();check(cold.restore(demo.state.snapshot()).ok,"actual work restores independently")
	await show(cold,Vector2(-23,-23),"冷读现代窗灯");await settle();check(demo.town.resonance.rigs.keys().all(func(id):return fits(id)),"all six cold production light meshes fit actual panes")
	facts.seconds=(Time.get_ticks_msec()-began)/1000.;await complete_report(personal)
