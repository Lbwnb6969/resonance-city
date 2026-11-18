extends "res://tools/check_creation_three_road_modes_live.gd"
## Pointer-to-surface measurements on the same authored city, not API-only costs.
var sample_frames:Array=[]
var collecting:=false
var previous_frame:=0
func _process(_delta:float)->bool:
	var now:=Time.get_ticks_usec()
	if collecting and previous_frame>0:sample_frames.append((now-previous_frame)/1000.)
	previous_frame=now
	return false
func summary(values:Array)->Dictionary:
	if values.is_empty():return {}
	var sorted:=values.duplicate();sorted.sort()
	return {"count":sorted.size(),"median_ms":sorted[sorted.size()/2],"p95_ms":sorted[int(sorted.size()*.95)],"max_ms":sorted[-1]}
func trace(at:Vector2)->float:
	var e:=InputEventMouseMotion.new();e.device=92;e.position=screen(at);e.global_position=e.position
	var began:=Time.get_ticks_usec();root.push_input(e)
	return (Time.get_ticks_usec()-began)/1000.
func publication_settle()->Dictionary:
	var began:=Time.get_ticks_usec();var last_active:Dictionary={}
	while demo.edit_pending() or demo._edit_ui_pending or demo.gallery.busy or demo.music._loading:
		var elapsed:float=(Time.get_ticks_usec()-began)/1000.
		for flag:String in ["edit","ui","gallery","music"]:
			var active:bool=demo.edit_pending() if flag=="edit" else (demo._edit_ui_pending if flag=="ui" else (demo.gallery.busy if flag=="gallery" else demo.music._loading))
			if active:last_active[flag]=elapsed
		await process_frame
	var tail:=Time.get_ticks_usec()
	for i in range(12):await process_frame
	return {"last_active_ms":last_active,"tail_12_frames_ms":(Time.get_ticks_usec()-tail)/1000.}
func diagnostic()->Dictionary:
	var result:Dictionary={};var points:Array[Vector2]=demo.road_preview.duplicate();var width:float=demo._selected_road_width()
	var began:=Time.get_ticks_usec()
	preload("res://scripts/world/city_creation_road_endpoint_targets.gd").pick(demo.state,points[-1],1.8,true,points[-2])
	result.targets_ms=(Time.get_ticks_usec()-began)/1000.;began=Time.get_ticks_usec()
	demo.state.preview_road(points,demo.road_style,"none",width)
	result.validate_ms=(Time.get_ticks_usec()-began)/1000.;began=Time.get_ticks_usec()
	var encoded:Array=[]
	for p:Vector2 in points:encoded.append([p.x,p.y])
	preload("res://scripts/world/city_creation_wide_passage.gd").site(demo.state.houses,demo.state.roads,encoded,width,demo.state.Passage.for_house)
	result.wide_site_ms=(Time.get_ticks_usec()-began)/1000.;began=Time.get_ticks_usec()
	var planned:Dictionary=road_tool.Endpoints.plan(demo.state,points,points[-1],Vector2.INF,0,[],true,width,demo.road_style,"")
	result.plan_ms=(Time.get_ticks_usec()-began)/1000.;began=Time.get_ticks_usec()
	demo.town.preview_road(points,bool(planned.valid.ok),width,false,demo.road_style)
	result.paint_ms=(Time.get_ticks_usec()-began)/1000.;result.mask_ms=demo.town.road_draft_field.last_ms
	result.points=points.size();result.first=str(points[0]);result.last=str(points[-1]);result.valid=planned.valid.ok;result.message=planned.valid.message;return result
func draw_trace(label:String,commit:bool)->void:
	var before:Dictionary=demo.state.snapshot();var history:int=demo.state._undo.size()
	var points:Array[Vector2]=[]
	var count:=193 if "--burst" in OS.get_cmdline_user_args() else 25
	for i:int in range(count):
		var t:=float(i)/(count-1);points.append(Vector2(-25.+18.*t,32.+.5*sin(t*TAU*1.5)))
	demo.select_tool(2);road_tool.set_mode(0)
	await motion(points[0]);await button(points[0],true)
	var events:Array=[];sample_frames.clear();collecting=true;previous_frame=Time.get_ticks_usec()
	for i:int in range(points.size()):
		events.append(trace(points[i]))
		if not "--burst" in OS.get_cmdline_user_args() or i%8==0:await process_frame
	await process_frame
	collecting=false
	check(road_tool.active() and demo.road_drawing,"held freehand remains active "+label)
	check(demo.state.revision==before.revision and demo.state._undo.size()==history,"held road does not write city/history "+label)
	var preview:Array=demo.road_preview.duplicate();check(preview.size()>25 and road_tool.valid.ok,"pointer creates a valid curved surface "+label)
	await capture(label+"_held")
	var row:={"input":summary(events),"frames":summary(sample_frames),"diagnostic":diagnostic()}
	print("PLAYTEST_DRAG ",label," ",JSON.stringify(row))
	if commit:
		var began:=Time.get_ticks_usec();await button(points[-1],false)
		if not "--expect-old-publication" in OS.get_cmdline_user_args():
			check(road_tool.pending_roads.rows.size()==1,"released road keeps its committed visible surface "+label)
			check(demo.town.has_node("PendingRoadSurfaces") and demo.town.get_meta("pending_road_masks",[]).size()==1,"pending road owns separate geometry and grass mask "+label)
		row.release_ms=(Time.get_ticks_usec()-began)/1000.;await capture(label+"_released");began=Time.get_ticks_usec();row.wait_breakdown=await publication_settle()
		row.publish_ms=(Time.get_ticks_usec()-began)/1000.
		row.budget=demo.edit_budget_report();row.life=demo.life.budget_commit_stats.duplicate(true)
		check(demo.state.roads.size()==before.roads.size()+1 and exact(preview),"release commits exact displayed curve "+label)
		if not "--expect-old-publication" in OS.get_cmdline_user_args():check(road_tool.pending_roads.rows.is_empty(),"atomic publication retires committed road overlay "+label)
		var saved:Dictionary=demo.state.snapshot();var cold:=State.new();check(cold.restore(saved).ok and cold.roads==demo.state.roads,"committed road cold restores "+label)
		await capture(label+"_committed")
		await key(KEY_Z,true);await settle();check(demo.state.roads==before.roads,"one Undo removes entire curve "+label)
		await key(KEY_Y,true);await settle();check(demo.state.roads==saved.roads,"one Redo restores entire curve "+label)
	else:
		await key(KEY_ESCAPE);await button(points[-1],false)
		check(demo.state.roads==before.roads and demo.state._undo.size()==history,"Escape cancels with no edit "+label)
	facts[label]=row
func rapid_gestures()->void:
	demo.select_tool(2);road_tool.set_mode(0)
	var start:=Vector2(-23,32);await motion(start);await button(start,true)
	for i:int in range(1,25):trace(Vector2(-25,32)+Vector2(cos(i*TAU/24.),sin(i*TAU/24.))*2.)
	check(road_tool.dragged and road_tool.raw.size()>20,"same-frame loop retains samples and drag intent before any rebuild")
	await button(start,false);await settle()
	check(demo.state.roads.size()==1 and demo.state.roads[0].points.size()>40,"same-frame out-and-back loop commits curved road on release")
	await key(KEY_Z,true);await settle()
	road_tool.set_mode(1);await motion(start);await button(start,true);trace(Vector2(-19,32))
	await button(Vector2(-19,32),true,MOUSE_BUTTON_RIGHT)
	check(road_tool.active() and demo.road_locked_segments==1,"same-frame straight drag and right-click lock preserve the pen")
	await button(Vector2(-19,32),false,MOUSE_BUTTON_RIGHT);await key(KEY_ESCAPE);await button(start,false)
	check(demo.state.roads.is_empty(),"rapid-gesture Undo and Escape leave no authored road")
func keyboard_modes()->void:
	# The preceding Escape now leaves empty hand; re-enter the road key context.
	demo.select_tool(2)
	for mode:int in range(3):
		await key(KEY_1+mode)
		check(road_tool.mode==mode,"native number key selects road mode "+str(mode))
		var a:=Vector2(-25,32);var b:=Vector2(-17,34);var middle:=Vector2(-24,35)
		if mode==0:
			await motion(a);await button(a,true);await motion(middle);await motion(b)
		else:
			await click_world(a)
			if mode==2:await click_world(middle)
			await motion(b)
		await process_frame;await process_frame
		var preview:Array=demo.road_preview.duplicate()
		check(road_tool.valid.ok and preview.size()>2,"visible valid native road mode "+str(mode))
		if mode==0:await button(b,false)
		else:await click_world(b)
		await settle()
		check(demo.state.roads.size()==1 and exact(preview),"native mode commits exact preview "+str(mode))
		await key(KEY_Z,true);await settle()
func pending_sequence()->void:
	demo.select_tool(2);road_tool.set_mode(0);demo.set_process(false)
	await motion(Vector2(-25,32));await button(Vector2(-25,32),true);trace(Vector2(-15,32));await button(Vector2(-15,32),false)
	check(road_tool.pending_roads.rows.size()==1,"committed first stroke survives while publication is held")
	var frozen:ShaderMaterial=road_tool.pending_roads.rows[0].node.get_child(0).material_override
	var pixels:PackedByteArray=frozen.get_shader_parameter("draft_field").get_image().get_data()
	await motion(Vector2(-20,29));await button(Vector2(-20,29),true);trace(Vector2(-20,35));await button(Vector2(-20,35),false)
	check(road_tool.pending_roads.rows.size()==2,"a second crossing stroke keeps both committed surfaces")
	check(frozen.get_shader_parameter("draft_field").get_image().get_data()==pixels,"second stroke cannot mutate first frozen road texture")
	var field=demo.town.road_draft_field;var pixel:Vector2i=Vector2i((Vector2(-20,32)-field.rect.position)/field.PIXEL)
	check(field.image.get_pixelv(pixel).r>.9,"overlapping and repeated pending masks form a union without grass holes")
	await key(KEY_Z,true)
	check(road_tool.pending_roads.rows.size()==1,"Undo before publication removes only the latest committed overlay")
	await motion(Vector2(-23,34));await button(Vector2(-23,34),true);trace(Vector2(-16,35));await key(KEY_ESCAPE);await button(Vector2(-16,35),false)
	check(road_tool.pending_roads.rows.size()==1 and demo.state.roads.size()==1,"canceling another active pen preserves the earlier committed road")
	demo.set_process(true);await settle()
	check(road_tool.pending_roads.rows.is_empty(),"latest atomic publication retires all surviving road overlays")
	await key(KEY_Z,true);await settle()
	check(demo.state.roads.is_empty() and demo.town.get_meta("pending_road_masks",[]).is_empty(),"final Undo clears both authored road and pending grass masks")
func complete_report(personal:PackedByteArray)->void:
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"rendering":DisplayServer.get_name(),"persistence":demo.persistence}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t",true,true))
	print("PLAYTEST_EDIT ",JSON.stringify(result));demo.queue_free();await create_timer(.2).timeout;quit(0 if failures.is_empty() else 1)
func run()->void:
	var fixture:="res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();road_tool=demo.get_meta("road_tool")
	demo.focus=Vector3(-16.,.4,28.);demo.zoom=32.;demo.yaw=0.;demo.pitch=1.;demo._update_camera()
	if not "--publication-only" in OS.get_cmdline_user_args():
		await draw_trace("empty",false)
		await rapid_gestures()
	if "--small-only" in OS.get_cmdline_user_args():
		await keyboard_modes();await pending_sequence();await complete_report(personal);return
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(fixture))
	var chosen:={"ok":true,"id":"playtest300","title":"Play Test 300","world":world,"view":{"focus":[-16.,.4,28.],"zoom":32.,"yaw":0.,"pitch":1.,"evening":false,"light_phase":0}}
	await demo.gallery._open_chosen(chosen);await settle();quiet()
	check(demo.state.houses.size()==300 and demo.town.house_roots.size()==300,"all 300 houses genuinely published")
	await draw_trace("houses300",not "--diagnose-only" in OS.get_cmdline_user_args())
	await complete_report(personal)
