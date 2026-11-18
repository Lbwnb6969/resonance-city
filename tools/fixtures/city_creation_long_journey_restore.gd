extends RefCounted
const Free=preload("res://tools/fixtures/city_creation_long_journey_free.gd")
const Targets=preload("res://scripts/ui/city_creation_sitting_targets.gd")
static func run(c:RefCounted)->void:
	var source_dir:String=c.out
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--source-journey-dir="):source_dir=arg.trim_prefix("--source-journey-dir=")
	var previous:Variant=JSON.parse_string(FileAccess.get_file_as_string(source_dir+"/v7_free.json"))
	c.check(previous is Dictionary and previous.get("ok",false),"v7_prior_process_saved_work")
	if not previous is Dictionary or not previous.get("ok",false):return
	var id:String=previous.details.saved_work_id;var base:String=c.demo.collection_directory.path_join(id)
	if source_dir!=c.out:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(c.demo.collection_directory))
		for suffix:String in [".json",".png"]:
			var original:String=source_dir.path_join("隔离作品").path_join(id+suffix)
			c.check(DirAccess.copy_absolute(ProjectSettings.globalize_path(original),ProjectSettings.globalize_path(base+suffix))==OK and FileAccess.get_sha256(original)==FileAccess.get_sha256(base+suffix),"v7_source_copy_exact_"+suffix)
	var original_json:String=FileAccess.get_sha256(base+".json");var original_png:String=FileAccess.get_sha256(base+".png")
	var saved:Dictionary=c.demo.gallery.library.read(id)
	c.check(saved.get("ok",false) and c.demo.state.houses.is_empty(),"v7_fresh_process_has_valid_prior_work")
	if not saved.get("ok",false):return
	c.stage("新进程重开上一旅程原作")
	await c.demo.gallery.open_work(id);await c.settle();c.demo.life.set_process(false)
	c.check(c.demo.gallery.last_opened_id==id and c.demo.state.houses==saved.world.houses,"v7_cross_process_work_restored")
	c.check(c.demo.state.houses[0].id==previous.details.author_id and int(c.demo.state.houses[0].seed)==int(previous.details.author_seed),"v7_restored_author_seed")
	for wanted:int in [1,2,0]:
		await c.click(c.demo.light_button)
		c.check(c.demo.light_phase==wanted,"v7_native_light_phase_"+str(wanted));await c.capture("昼夕夜_"+str(wanted))
	var muted:bool=c.demo.music.muted
	await c.click(c.demo.music_button);c.check(c.demo.music.muted!=muted,"v7_native_sound_mute")
	await c.click(c.demo.music_button);c.check(c.demo.music.muted==muted and Free.no_old_long(c),"v7_native_sound_restore_without_old_song")
	await Free.key(c,KEY_F1);var options:Node=c.demo.get_meta("creation_options")
	var guidance:bool=c.demo.state.creative_settings.guidance
	await c.click(options.guidance);c.check(c.demo.state.creative_settings.guidance!=guidance,"v7_native_guidance_preference")
	await Free.key(c,KEY_ESCAPE)
	while c.demo.light_phase!=2:await c.click(c.demo.light_button)
	var night:Dictionary=await c.save_work("星夜欣赏 · Play Test")
	await c.click(c.demo.light_button);await c.demo.gallery.open_work(night.id);await c.settle();c.demo.life.set_process(false)
	c.details.night_restore={"expected_id":night.id,"opened_id":c.demo.gallery.last_opened_id,"saved_phase":night.view.get("light_phase",-1),"actual_phase":c.demo.light_phase,"saved_guidance":night.world.creative_settings.guidance,"actual_guidance":c.demo.state.creative_settings.guidance,"old_guidance":guidance}
	c.check(c.demo.light_phase==2 and c.demo.town.light_phase==2 and c.demo.state.creative_settings.guidance!=guidance,"v7_saved_night_and_preference_restore")
	await c.click(c.demo.ui_layer.find_child("FourSeasons",true,false))
	var weather_index:int=c.demo.State.Microclimate.IDS.find(c.demo.state.microclimate)
	c.check(weather_index>=0 and c.demo.light_phase==c.demo.State.Microclimate.LIGHTS[weather_index],"v7_explicit_weather_still_applies_default_light")
	await c.demo.gallery.open_work(night.id);await c.settle();c.demo.life.set_process(false)
	var renderer_id:int=c.demo.town.get_instance_id()
	await c.demo.gallery.open_work(night.id);await c.settle();c.demo.life.set_process(false)
	c.check(c.demo.town.get_instance_id()!=renderer_id and c.demo.light_phase==2 and c.demo.town.light_phase==2 and c.demo.music.night and c.demo.town.wildlife._night and c.demo.town.water_material.get_shader_parameter("night")==1. and c.demo.ambience.report().night,"v7_same_night_reopen_updates_all_new_renderer_systems")
	c.stage("原生 B 静听与恢复镜头")
	await c.edit(c.demo.state.add_road([Vector2(-34,-15),Vector2(-20,-15)] as Array[Vector2],"gravel","none",1.25,"benches"),"road")
	c.demo.life.set_process(false);var seats:Dictionary=Targets.plans(c.demo);var chosen:=""
	for seat_id:String in seats:
		if not Targets.occupied(c.demo,seat_id):chosen=seat_id;break
	c.check(not chosen.is_empty(),"v7_actual_vacant_bench")
	if not chosen.is_empty():
		var seat:Dictionary=seats[chosen];c.look(seat.at,12.);c.demo.yaw=0.;c.demo.pitch=.85;c.demo._update_camera();await c.settle();await c.tree.physics_frame
		var camera:Array=[c.demo.focus,c.demo.yaw,c.demo.pitch,c.demo.zoom,c.demo.camera.projection]
		var motion:=InputEventMouseMotion.new();motion.device=92;motion.position=c.demo.camera.unproject_position(Vector3(seat.at.x,seat.y+.6,seat.at.y));motion.global_position=motion.position;c.tree.root.push_input(motion);await c.tree.process_frame
		await Free.key(c,KEY_B);c.check(c.demo.camera_rig.bench_view.seat_id==chosen,"v7_native_B_enters_actual_seat")
		await c.tree.create_timer(.5).timeout;await c.capture("B静听")
		await Free.key(c,KEY_ESCAPE)
		c.check(c.demo.camera_rig.bench_view.seat_id.is_empty() and camera==[c.demo.focus,c.demo.yaw,c.demo.pitch,c.demo.zoom,c.demo.camera.projection],"v7_B_escape_restores_exact_camera")
	c.stage("取消选择与真实坏档不污染当前城")
	var before:Dictionary=c.demo.state.snapshot();var city_id:int=c.demo.state.get_instance_id()
	await Free.key(c,KEY_O,true);await Free.key(c,KEY_ESCAPE)
	c.check(not c.demo.gallery.panel.visible and c.demo.state.get_instance_id()==city_id and c.demo.state.snapshot()==before,"v7_cancel_work_selection_preserves_city")
	var bad_id:String=id.left(-1)+("0" if id.right(1)!="0" else "1")
	FileAccess.open(c.demo.collection_directory.path_join(bad_id+".json"),FileAccess.WRITE).store_string("{broken")
	await c.demo.gallery.open_work(bad_id);await c.settle()
	c.check(c.demo.state.get_instance_id()==city_id and c.demo.state.snapshot()==before and not c.demo.gallery.busy,"v7_corrupt_work_rejects_without_city_change")
	c.check(FileAccess.get_sha256(base+".json")==original_json and FileAccess.get_sha256(base+".png")==original_png,"v7_original_work_and_cover_byte_identical")
	c.details.source_work_id=id;c.details.night_work_id=night.id;c.details.listening_approved=false
	c.details.cancel_scope="selection cancelled before choosing a work; not an in-flight loading cancellation claim"
	await c.capture("欣赏恢复_结束")
