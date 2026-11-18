extends RefCounted
## Current free-policy journey; legacy day-one economics remain a separate test.
static func key(c:RefCounted,code:int,ctrl:bool=false)->void:
	for down:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;event.ctrl_pressed=ctrl;c.tree.root.push_input(event);await c.tree.process_frame
	await c.settle()
static func no_old_long(c:RefCounted)->bool:
	return c.demo.music._players.values().all(func(p):return not p.playing)
static func run(c:RefCounted)->void:
	c.stage("现行自由城：真实空地落笔")
	c.check(c.demo.state.houses.is_empty() and c.demo.state.CreationPolicy.is_free(c.demo.state),"v7_free_empty")
	await c.postpone();c.demo.select_tool(0);await c.ground(Vector2(-30,-22));await c.settle()
	c.check(c.demo.state.houses.size()==1,"v7_native_first_house")
	if c.demo.state.houses.size()!=1:return
	var first:Dictionary=c.demo.state.houses[0];var identity:String=first.id;var seed_value:int=first.seed
	c.check(no_old_long(c),"v7_single_house_keeps_nature_and_no_rejected_long_song")
	c.stage("不按用途或区域顺序：先树与路，再扩房")
	await c.edit(c.demo.state.place_plant(Vector2(-34,-24),"olive"),"plant")
	await c.edit(c.demo.state.add_road([Vector2(-33,-20.45),Vector2(-27,-20.45)] as Array[Vector2],"path","none"),"road")
	var before:Array=c.demo.state.houses.duplicate(true)
	await c.edit(c.demo.state.add_cell(identity,0,0,1))
	var changed:Array=c.demo.state.houses.duplicate(true)
	await key(c,KEY_Z,true);c.check(c.demo.state.houses==before,"v7_native_undo_geometry")
	await key(c,KEY_Y,true);c.check(c.demo.state.houses==changed,"v7_native_redo_geometry")
	await c.edit(c.demo.state.add_house(Vector2(-24,-22)))
	c.check(c.demo.state.houses.all(func(h):return h.role=="residential") and c.demo.state.districts.is_empty() and no_old_long(c),"v7_no_roles_or_four_districts_required")
	c.check(c.demo.state.houses[0].id==identity and int(c.demo.state.houses[0].seed)==seed_value,"v7_author_identity_and_seed_preserved")
	c.stage("原导航查看与收藏")
	await key(c,KEY_L);c.check(c.demo.ledger.visible(),"v7_native_L_opens")
	c.check("自然底景" in c.demo.ledger.body.text,"v7_L_reports_real_nature_policy")
	await c.capture("自由营造_L");await key(c,KEY_ESCAPE)
	await key(c,KEY_J);c.check(c.demo.journal.panel.is_visible_in_tree(),"v7_native_J_opens")
	await c.capture("自由营造_J");await key(c,KEY_ESCAPE)
	var saved:Dictionary=await c.save_work("自由营造 · Play Test")
	c.check(saved.get("ok",false) and saved.world.houses==c.demo.state.houses,"v7_free_isolated_collection")
	c.details.saved_work_id=c.demo.gallery.last_saved_id;c.details.author_id=identity;c.details.author_seed=seed_value
	c.details.listening_approved=false;c.details.default_music="nature_only";c.details.works=c.demo.collection_directory
	await c.capture("自由营造_收藏后")
