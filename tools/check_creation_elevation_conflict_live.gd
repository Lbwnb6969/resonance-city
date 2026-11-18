extends "res://tools/check_creation_unified_build_live.gd"
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/city_creation_elevation_overlap.json"))
	var old:=State.new();check(old.restore(source.after).ok,"historical accepted overlap still opens")
	await show(old,Vector2(-24,-20),"旧高差问题作品");await settle();quiet();demo.zoom=13.;demo._update_camera();await capture("historical_overlap")
	var city:=State.new();check(city.restore(source.before).ok,"valid raised-ground and terrace fixture")
	await show(city,Vector2(-24,-20),"高差建造校验");await settle();quiet();demo.zoom=13.;demo._update_camera();demo.select_tool(0)
	check(DisplayServer.get_name()!="headless","actual native OpenGL building input")
	facts.hover=[]
	var target:=Vector2.INF
	for z:float in [-19.1,-18.9,-18.7,-18.5]:
		var at:=Vector2(-23.2,z);await motion(at)
		facts.hover.append({"at":str(at),"candidate":demo.candidate.duplicate(true)})
		if demo.candidate.has("new_house") and not demo.candidate.get("valid",true):target=at;break
	check(target.is_finite(),"visible hillside offers real invalid new-house preview under terrace")
	if not target.is_finite():await complete_report(personal);return
	var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size()
	check(demo.candidate.reason.contains("重叠"),"native preview reports physical overlap")
	await capture("blocked_hillside_preview");await button(target,true);await button(target,false);await settle();quiet()
	check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"native rejected stroke preserves full world and history")
	var terrace:Dictionary=demo.state.houses[0].cells.filter(func(c):return c.kind=="terrace")[0]
	demo._after_edit(demo.state.remove_cell("h1",str(terrace.id)),"erase");await settle();quiet();demo.select_tool(0);await motion(target)
	check(demo.candidate.has("new_house") and demo.candidate.valid,"same native hillside placement becomes legal after terrace removal")
	var cleared:Array=demo.state.houses.duplicate(true);depth=demo.state._undo.size()
	await button(target,true);await button(target,false);await settle();quiet()
	check(demo.state.houses.size()==2 and demo.state._undo.size()==depth+1 and float(demo.state.houses[-1].base_y)>0.,"native release creates elevated neighbour in one transaction")
	var built:Array=demo.state.houses.duplicate(true);await key(KEY_ESCAPE);await capture("legal_hillside_neighbour")
	await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==cleared,"native Undo removes complete elevated house")
	await key(KEY_Y,true);await settle();quiet();check(demo.state.houses==built,"native Redo restores exact elevated house")
	var cold:=State.new();check(cold.restore(demo.state.snapshot()).ok and cold.houses==built,"new legal elevated world cold restores")
	await complete_report(personal)
