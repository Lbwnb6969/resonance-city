extends "res://tools/check_creation_playtest_plants_live.gd"
func sequence()->void:
	demo.select_tool(5);demo.vegetation_single=true;demo.vegetation_kind="olive";demo.set_process(false)
	var original:Array=demo.state.plants.duplicate(true)
	await click_world(Vector2(-32,34));var pending:Node=demo.get_meta("pending_plants");var first:String=pending.rows.keys()[0];var pose:Transform3D=pending.rows[first].pose
	check(pending.rows.size()==1 and pending.root.is_visible_in_tree(),"first native single is visible while geometry publication is held")
	await click_world(Vector2(-28,34))
	check(pending.rows.size()==2 and pending.rows[first].pose==pose,"second native placement stays available and cannot move the first committed tree")
	await key(KEY_Z,true)
	check(pending.rows.size()==1 and pending.rows.has(first),"Undo before publication removes only the latest pending plant")
	var before:int=demo.state.plants.size();await motion(Vector2(-24,35.5));await button(Vector2(-24,35.5),true);await key(KEY_ESCAPE);await button(Vector2(-24,35.5),false)
	check(demo.state.plants.size()==before and pending.rows.size()==1,"cancelling a later brush cannot erase earlier committed plants")
	check(demo.tool==-1,"Escape returns to empty hand after cancelling the later brush")
	await capture("two_placements_undo_cancel")
	await key(KEY_Z,true);check(demo.state.plants==original and pending.rows.is_empty(),"second Undo clears pending surfaces and restores original authors")
	demo.select_tool(5);await click_world(Vector2(-32,34));check(pending.rows.size()==1,"new pending tree exists before actual gallery replacement")
	var city:=State.new();city.initialize_free()
	var chosen:={"ok":true,"id":"pending_new_city","title":"Pending new city","world":city.snapshot(),"view":{"focus":[-16.,.4,28.],"zoom":32.,"yaw":0.,"pitch":1.,"evening":false,"light_phase":0}}
	var previous:RefCounted=demo.state;await demo.gallery._open_chosen(chosen)
	check(demo.state==previous and pending.rows.size()==1,"existing gallery correctly blocks replacement during pending edits")
	demo.state.initialize_free();demo._after_edit({"ok":true,"message":"isolated API reset"},"history")
	await process_frame;await process_frame
	check(demo.state.houses.is_empty() and demo.state.plants.is_empty() and pending.rows.is_empty(),"same-State reset cancels old generation and clears its committed plants")
	demo.set_process(true);await settle();quiet();await demo.gallery._open_chosen(chosen);await settle();quiet()
	check(demo.state!=previous and demo.state.houses.is_empty() and not demo.town.has_node("PendingPlantSurfaces"),"actual permitted gallery replacement retains no old plant surfaces")
	check(demo.state._undo.is_empty(),"new city history belongs to the replacement source")
func plant_trace(single:bool)->void:
	if "--sequence-only" in OS.get_cmdline_user_args():
		if single:await sequence()
		return
	await super.plant_trace(single)
