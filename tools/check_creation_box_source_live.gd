extends SceneTree
const Source=preload("res://scripts/visual/city_creation_box_source.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var out:="";var expected:="forward_plus"
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--expected-renderer="):expected=arg.trim_prefix("--expected-renderer=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec()
	var native:=BoxMesh.new();native.size=Vector3.ONE;var cached:=Source.new();var original:=var_to_bytes(cached.surface_get_arrays(0));var rows:Array=[];var outputs:Array=[]
	for source:Mesh in [native,cached]:
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);var started:=Time.get_ticks_usec()
		for i in range(600):
			var scale:=Vector3(.04+float(i%11)*.08,.08+float(i%7)*.16,.03+float(i%5)*.1)
			if i%3==0:scale.x=-scale.x
			var basis:=Basis.from_euler(Vector3(.13*(i%4),.27*(i%9),-.19*(i%3)))*Basis.from_scale(scale)
			surface.append_from(source,0,Transform3D(basis,Vector3(i%13-6,float(i%5)*.1,i%17-8)))
		var elapsed:=float(Time.get_ticks_usec()-started)/1000.;var arrays:=surface.commit_to_arrays();outputs.append(var_to_bytes(arrays));rows.append({"source":"native" if source==native else "cpu","ms":elapsed,"vertices":arrays[Mesh.ARRAY_VERTEX].size(),"indices":arrays[Mesh.ARRAY_INDEX].size(),"arrays_sha256":outputs[-1].hex_encode().sha256_text()})
	var same:bool=outputs[0]==outputs[1];var unchanged:bool=original==var_to_bytes(cached.surface_get_arrays(0))
	var report:={"ok":same and unchanged and RenderingServer.get_current_rendering_method()==expected,"same_all_attributes":same,"immutable_source":unchanged,"cases":rows,"seconds":(Time.get_ticks_msec()-began)/1000.,"renderer":RenderingServer.get_current_rendering_method(),"source_sha256":FileAccess.get_sha256("res://scripts/visual/city_creation_box_source.gd"),"tool_sha256":FileAccess.get_sha256("res://tools/check_creation_box_source_live.gd"),"scope":"600 identical native C++ appends including rotation, nonuniform/negative scales; CPU array comparison, no personal state instantiated"}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("BOX_SOURCE ",JSON.stringify(report));quit(0 if report.ok else 1)
