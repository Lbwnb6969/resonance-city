extends SceneTree
const Foliage=preload("res://scripts/visual/city_creation_foliage.gd")
const Baseline=preload("res://tests/fixtures/published_baselines/vegetation_remake_20261106/baseline/foliage_adapter.gd")
const Rig=preload("res://scripts/visual/city_creation_environment.gd")
var failures:Array=[]
var checks:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));root.size=Vector2i(1440,900);Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var began:=Time.get_ticks_msec();var scene:=Node3D.new();root.add_child(scene);var rig:=Rig.new();rig.setup(scene)
	var camera:=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.near=.1;camera.far=120.
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(36,28);ground.mesh=plane;var material:=StandardMaterial3D.new();material.albedo_color=Color("82976e");material.roughness=1.;ground.material_override=material;scene.add_child(ground)
	ground.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var banks:={"before":Baseline.new(),"after":Foliage.new()};var groups:Dictionary={};var geometry:Array=[];var kinds:Array=["olive","cypress","golden_tree","weeping_willow","shrub"]
	for stage:String in banks:
		var group:=Node3D.new();scene.add_child(group);groups[stage]=group;var bank:RefCounted=banks[stage]
		for kind_index in range(kinds.size()):
			var kind:String=kinds[kind_index]
			for variant in range(3):
				var start:=Time.get_ticks_usec();var parts:Dictionary=bank.parts(kind,variant);var generation_ms:=float(Time.get_ticks_usec()-start)/1000.;var bounds:AABB=parts.canopy.get_aabb();var vertices:=0;var triangles:=0
				for piece:String in parts:
					var node:=MeshInstance3D.new();node.mesh=parts[piece];node.material_override=bank.material(piece);node.position=Vector3(-7.2+kind_index*3.6,0,(variant-1)*3.5);node.rotation.y=variant*.71;group.add_child(node);bounds=bounds.merge(node.mesh.get_aabb())
					var arrays:Array=node.mesh.surface_get_arrays(0);vertices+=arrays[Mesh.ARRAY_VERTEX].size();triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
					if stage=="after":
						var valid:=true;var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
						for point:Vector3 in points:valid=valid and point.is_finite()
						for normal:Vector3 in normals:valid=valid and normal.is_finite() and absf(normal.length()-1.)<.001
						for i in range(0,indices.size(),3):
							var a:int=indices[i];var b:int=indices[i+1];var c:int=indices[i+2]
							valid=valid and mini(a,mini(b,c))>=0 and maxi(a,maxi(b,c))<points.size()
							if valid:valid=(points[b]-points[a]).cross(points[c]-points[a]).length_squared()>.000000000001
						check(valid,"finite unit normals and valid nondegenerate "+kind+str(variant)+piece)
						check(var_to_bytes(arrays)==var_to_bytes(Foliage.new().parts(kind,variant)[piece].surface_get_arrays(0)),"fresh bank deterministic "+kind+str(variant)+piece)
				geometry.append({"stage":stage,"kind":kind,"variant":variant,"top_y":bounds.end.y,"width":bounds.size.x,"vertices":vertices,"triangles":triangles,"generation_ms":generation_ms})
		bank.material("canopy").set_shader_parameter("wind_time_override",0.)
	for kind:String in ["pink_flower","white_flower","yellow_flower"]:
		for variant in range(3):
			var old:Dictionary=banks.before.parts(kind,variant);var fresh:Dictionary=banks.after.parts(kind,variant);var exact:=old.keys()==fresh.keys()
			for piece:String in old:exact=exact and var_to_bytes(old[piece].surface_get_arrays(0))==var_to_bytes(fresh[piece].surface_get_arrays(0))
			check(exact,"frozen original flower geometry bytes "+kind+str(variant))
	for stage:String in banks:
		for name:String in groups:groups[name].visible=name==stage
		for subject:String in ["lineup","olive","cypress","willow"]:
			var focus:=Vector3(0,1.5,0);var size:=23.;var pitch:=.55;var yaw:=.15
			if subject!="lineup":focus=Vector3(-7.2 if subject=="olive" else -3.6 if subject=="cypress" else 3.6,1.6,0);size=5.5;pitch=.18;yaw=.2
			camera.size=size;camera.position=focus+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*40.;camera.look_at(focus);rig.set_view(pitch)
			for phase in range(3):
				rig.apply(phase)
				for i in range(12):await process_frame
				await RenderingServer.frame_post_draw;check(root.get_texture().get_image().save_png(out+"/"+stage+"_"+subject+"_"+str(phase)+".png")==OK,"native "+stage+"/"+subject+"/"+str(phase))
	for old:Dictionary in geometry:
		if old.stage!="before":continue
		var matches:Array=geometry.filter(func(row):return row.stage=="after" and row.kind==old.kind and row.variant==old.variant)
		check(matches.size()==1 and absf(matches[0].top_y-old.top_y)<.00001,"preserve original authored-scale top "+old.kind+str(old.variant))
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"geometry":geometry,"seconds":(Time.get_ticks_msec()-began)/1000.,"renderer":RenderingServer.get_current_rendering_method(),"scope":"isolated model lineup on plain floor; no city State/personal storage instantiated; screenshots freeze wind, not a full-world performance test"}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("TREE_SILHOUETTES ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));scene.queue_free();await process_frame;quit(0 if report.ok else 1)
