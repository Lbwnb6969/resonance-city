extends "res://tools/check_creation_playtest_edit_live.gd"
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
const Stamp=preload("res://scripts/ui/city_creation_prototype_stamp.gd")
func palette()->Control:return demo.tactile_dock.bubble_rows.find_child("NewHousePalette",true,false)
func open_palette()->void:
	demo.select_tool(0);demo.tactile_dock.house_options=true;demo.tactile_dock.refresh();await settle();quiet()
func card(key:String)->void:
	var p=palette();var button:Control=p.cards[key];p.scroll.ensure_control_visible(button);await process_frame;await process_frame;await ui_click(button);await process_frame
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20))
	await show(city,Vector2(-25,-20),"直接选择建筑形状");await settle();quiet();demo.zoom=26.;demo._update_camera();await open_palette()
	check(DisplayServer.get_name()!="headless","actual native OpenGL shape controls")
	var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size()
	for size:Vector2i in [Vector2i(1440,900),Vector2i(1024,768)]:
		root.size=size;await settle()
		check(palette().is_visible_in_tree() and root.get_visible_rect().encloses(demo.tactile_dock.popup.get_global_rect()),"shape palette fits viewport "+str(size.x))
		for era:String in city.Eras.IDS:
			await ui_click(palette().eras[era]);await process_frame
			check(palette().cards.size()==4+Brush.prototypes(era).size() and palette().eras[era].active,"native era exposes all actual permitted silhouettes "+era+str(size.x))
			for id:String in Brush.prototypes(era):check(Stamp.PROFILES.has(id),"prototype has specific silhouette "+id)
		await capture("palette_"+str(size.x))
	check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"all shape and era browsing leaves author world and history unchanged")
	root.size=Vector2i(1440,900);await settle()
	var choices:Array=[{"era":"pastoral","key":"style/timber"},{"era":"pastoral","key":"style/stone"},{"era":"pastoral","key":"style/round_tower"},{"era":"pastoral","key":"style/classic"},{"era":"pastoral","key":"prototype/creek_boathouse"},{"era":"renaissance","key":"prototype/corner_loggia_tower"},{"era":"modern_eco","key":"prototype/timber_acoustic_shell"}]
	for row:Dictionary in choices:
		await open_palette();await ui_click(palette().eras[row.era]);await process_frame;await card(row.key)
		var brush:=Brush.current(demo.state).duplicate(true)
		check(palette().cards[row.key].active and demo.state.snapshot()==before and demo.state._undo.size()==depth,"native shape selection changes only brush "+row.key)
		var at:=Vector2(-29,-26);await motion(at)
		check(demo.candidate.has("new_house") and demo.candidate.get("valid",false),"real empty-ground placement available "+row.key)
		await button(at,true);await button(at,false);await settle();quiet();demo.life.set_process(false)
		var h:Dictionary=demo.state.houses[-1]
		check(demo.state.houses.size()==2 and demo.state.houses[0]==before.houses[0] and demo.state.house_era(h)==row.era,"native shape builds one new house and preserves existing house "+row.key)
		check(h.get("architecture","")==brush.prototype if row.key.begins_with("prototype/") else h.get("style","classic")==row.key.trim_prefix("style/"),"actual published house carries selected geometry "+row.key)
		check(demo.town.house_roots.has(h.id) and not demo.town.house_roots[h.id].find_children("*","MeshInstance3D",true,false).is_empty(),"actual selected building has published geometry "+row.key)
		await capture(row.key.replace("/","_"));await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"one Undo removes entire new shape "+row.key)
		await key(KEY_Y,true);await settle();quiet();check(demo.state.houses[-1]==h,"one Redo restores selected complete shape "+row.key)
		await key(KEY_Z,true);await settle();quiet();before=demo.state.snapshot();depth=demo.state._undo.size()
	await open_palette();await ui_click(palette().find_child("NewHouseLandmarks",true,false));await settle();quiet()
	check(demo.signatures.panel.is_visible_in_tree(),"shape strip reaches existing landmark page")
	for id:String in demo.signatures.buttons:
		var b:Button=demo.signatures.buttons[id];check(b.shape_key=="landmark/"+id and not b.disabled,"landmark has its own available silhouette "+id)
	await capture("landmark_shapes")
	var b:Control=demo.signatures.buttons.bell_keep
	# Scroll pages own the same original placement callback.
	while not b.get_parent() is ScrollContainer and b.get_parent()!=null:b=b.get_parent()
	if b.get_parent() is ScrollContainer:b.get_parent().ensure_control_visible(demo.signatures.buttons.bell_keep)
	await ui_click(demo.signatures.buttons.bell_keep);await process_frame
	check(demo.signatures.placing=="bell_keep" and demo.state.snapshot()==before,"native landmark silhouette enters original placement without writing")
	await key(KEY_ESCAPE);await settle();check(demo.signatures.placing.is_empty() and demo.state.snapshot()==before,"Escape cancels shape-selected landmark without writing")
	demo.select_tool(4);demo.tactile_dock.house_options=false;demo.tactile_dock.refresh();demo.spatial_popover.open_for_house("h1");await settle();quiet()
	await ui_click(demo.spatial_popover.style_button);await settle();var picker=demo.get_meta("house_style_picker")
	check(picker.panel.visible and picker.buttons.values().all(func(button):return button.shape_key.begins_with("style/") and root.get_visible_rect().encloses(button.get_global_rect())),"existing-house editor displays four distinct reachable shape cards")
	await ui_click(picker.buttons.timber);await settle();quiet();check(demo.state.houses[0].get("style")=="timber","native existing-house shape uses real style transaction")
	await key(KEY_Z,true);await settle();check(demo.state.houses==before.houses,"one Undo restores original existing house after shape choice")
	await complete_report(personal)
