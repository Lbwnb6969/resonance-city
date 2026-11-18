extends "res://tools/check_creation_lighting_comparison_live.gd"
## Modal opening profile, no mesh or GPU buffer readback during the timed load.
var sampling:=false
var last_tick:=0
var frame_samples:Array=[]
var long_frames:Array=[]
var last_context:Dictionary={}
var last_print:=0
func context()->Dictionary:
	var row:={"phase":demo.gallery.load_phase,"frame":Engine.get_process_frames()}
	var opening:Node3D=demo.get_node_or_null("OpeningTown")
	if opening!=null and opening.budget_rebuild!=null:
		var budget:RefCounted=opening.budget_rebuild
		row.merge({"worker":budget.worker!=null,"task":budget.task_index,"total":budget.tasks.size(),"last_step":budget.stats.get("last_step",{}).duplicate(),"last_poll":budget.stats.get("last_poll",{}).duplicate()})
	return row
func _process(_delta:float)->bool:
	if not sampling:return false
	var now:=Time.get_ticks_usec();var elapsed:=float(now-last_tick)/1000.;frame_samples.append(elapsed)
	var current:=context()
	if elapsed>120.:
		long_frames.append({"ms":elapsed,"before":last_context,"after":current});long_frames.sort_custom(func(a,b):return a.ms>b.ms)
		if long_frames.size()>20:long_frames.resize(20)
	last_tick=now;last_context=current
	if now-last_print>10000000:print("OPEN_STAGE ",JSON.stringify(current));last_print=now
	return false
func pipelines()->Dictionary:
	var result:Dictionary={}
	for key:String in ClassDB.class_get_integer_constant_list("Performance"):
		if key.begins_with("PIPELINE_COMPILATIONS_"):result[key]=Performance.get_monitor(ClassDB.class_get_integer_constant("Performance",key))
	return result
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--expected-renderer="):expected_renderer=arg.trim_prefix("--expected-renderer=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);var began:=Time.get_ticks_msec()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var empty_ms:=Time.get_ticks_msec()-began;var initial_pipelines:=pipelines()
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))
	var chosen:={"ok":true,"id":"startup300","title":"加载分段300","world":world,"view":{"focus":[-16.,.8,20.],"zoom":32.,"yaw":-.6,"pitch":.65,"evening":false,"light_phase":0}}
	last_tick=Time.get_ticks_usec();last_print=last_tick;last_context=context();sampling=true
	var start:=Time.get_ticks_usec();await demo.gallery._open_chosen(chosen);var open_ms:=float(Time.get_ticks_usec()-start)/1000.;sampling=false
	demo.life.set_process(false);await settle();quiet();demo.set_process(false);demo.town.set_process(false);demo.town.wildlife.set_process(false);demo.ui_layer.hide();demo.town.clear_preview();freeze_wind(0.)
	var houses:Array=[];var batch_ms:=0.;var color_ms:=0.
	for id:String in demo.town.house_roots:
		var house:Node3D=demo.town.house_roots[id];var batch:Dictionary=house.get_meta("material_batching",{});var color:Dictionary=house.get_meta("house_color_prepare",{})
		batch_ms+=float(batch.get("elapsed_ms",0.));color_ms+=float(color.get("prepare_ms",0.));houses.append({"id":id,"batch":batch,"color":color,"assembly":house.get_meta("house_assembly",{}).duplicate(true)})
	check(RenderingServer.get_current_rendering_method()==expected_renderer,"actual requested renderer")
	check(demo.state.houses.size()==300 and demo.town.house_roots.size()==300 and demo.life.last_revision==demo.state.revision,"complete 300-house work and matching Life published")
	check(FileAccess.get_file_as_bytes(State.DEFAULT_PATH)==personal,"personal save unchanged")
	await capture("complete_city")
	var shape:Dictionary={}
	if OS.get_cmdline_user_args().has("--shape-proof"):shape=shape_signature()
	var sources:Dictionary={}
	for path:String in ["tools/check_creation_renderer_startup_live.gd","scripts/visual/city_creation_renderer.gd","scripts/ui/city_creation_city_load.gd","scripts/visual/city_creation_hidden_house.gd","scripts/visual/city_creation_mesh_batcher.gd","scripts/visual/city_creation_house_colors.gd","scripts/visual/city_creation_box_source.gd"]:sources[path]=FileAccess.get_sha256("res://"+path)
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"empty_ms":empty_ms,"open_ms":open_ms,"loading":demo.gallery.load_stats.duplicate(true),"houses":houses,"batch_total_ms":batch_ms,"color_total_ms":color_ms,"frames":summary(frame_samples),"worst_frames":long_frames,"pipelines_before":initial_pipelines,"pipelines_after":pipelines(),"source_sha256":sources,"persistence":demo.persistence,"collection_directory":demo.collection_directory,"seconds":(Time.get_ticks_msec()-began)/1000.,"limit":"Wall timings include synchronous driver work; no buffer readback by profiler during timed opening."}
	report.shape=shape
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("RENDERER_STARTUP ",JSON.stringify({"ok":report.ok,"checks":checks,"open_ms":open_ms,"batch_ms":batch_ms,"color_ms":color_ms}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
