extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Scene=preload("res://scenes/city_creation.tscn")
const Fixture=preload("res://tools/fixtures/city_creation_amphitheater_fixture.gd")
const Span=preload("res://tools/fixtures/city_creation_recording_span.gd")
const StreamEvidence=preload("res://tools/fixtures/city_creation_stream_evidence.gd")
var OUT="res://验证记录/PlayTest/grand_festival_native"
var source:=""
var demo
var checks:Array=[]
var failures:Array[String]=[]
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	checks.append({"ok":ok,"label":label})
	if not ok:failures.append(label);push_error(label)
func _wait()->void:
	var end:=Time.get_ticks_msec()+90000
	while (demo.edit_pending() or demo._edit_ui_pending or demo.music.audio_report.is_empty()) and Time.get_ticks_msec()<end:await process_frame
	await physics_frame;await process_frame
func _capture(label:String)->void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+label+".png")
func _click(button:Control)->void:
	var parent:Node=button.get_parent()
	while parent!=null:
		if parent is ScrollContainer:parent.ensure_control_visible(button)
		parent=parent.get_parent()
	await process_frame
	var at:Vector2=button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=at;motion.global_position=at;root.push_input(motion);await process_frame
	for pressed:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event);await process_frame
	await _wait()
func _run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--source="):source=arg.trim_prefix("--source=")
	if DisplayServer.get_name()=="headless":push_error("Grand festival screenshot/PCM check requires a native rendering window");quit(1);return
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	root.size=Vector2i(1440,900);Engine.max_fps=60
	var fixture:Dictionary;var city:RefCounted;var placed:Dictionary
	if source.is_empty():
		fixture=Fixture.build(self);city=fixture.city
		var points:Array[Vector2]=[Vector2(-11,-9),Vector2(-11,9)];city.add_road(points,"tram")
		points=[Vector2(-11,9),Vector2(15,9)];city.add_road(points,"tram")
		placed=Fixture.place_connected(city);fixture.life.free()
		_check(placed.ok and placed.access.ok,"actual earned final signature is placed on shoreline with a real dry street connection")
		if not placed.ok or not placed.access.ok:quit(1);return
	else:
		var bytes:=FileAccess.get_file_as_bytes(source);city=State.new()
		var loaded:Dictionary=city.restore(JSON.parse_string(bytes.get_string_from_utf8()))
		for record:Dictionary in city.houses:
			if record.get("signature","")=="floating_amphitheater" and record.role=="symphony_hall":placed={"house_id":str(record.id),"at":Vector2(record.origin[0],record.origin[1])};break
		_check(loaded.ok and not placed.is_empty(),"shipped editable work restores its actual shoreline symphony hall")
		if not loaded.ok or placed.is_empty():quit(1);return
		fixture={"facts":{"source":source,"source_sha256":FileAccess.get_sha256(source),"houses":city.houses.size(),"legacy":not city.CreationPolicy.is_free(city)}}
	demo=Scene.instantiate();demo.persistence=false;demo.collection_directory=OUT+"/临时作品库";root.add_child(demo);demo.life.set_process(false)
	var restored:Dictionary=demo.state.restore(JSON.parse_string(JSON.stringify(city.snapshot(),"",true,true)))
	_check(restored.ok,"production final-signature town restores all actual chapter and service ledgers")
	demo._after_edit(restored,"history");await _wait()
	_check(not demo.edit_pending() and not demo._edit_ui_pending and not demo.music.audio_report.is_empty(),"full current work and original audio bank publish before inspection")
	if demo.edit_pending() or demo._edit_ui_pending or demo.music.audio_report.is_empty():quit(1);return
	demo.remove_child(demo.life);demo.life.queue_free();demo._setup_life();demo.life.set_process(false)
	_check(demo.life.connected_houses.has(placed.house_id),"actual rendered hall has a reachable dry street port")
	demo.ui_layer.visible=false;demo.focus=Vector3(placed.at.x-2.,1.2,placed.at.y+.8);demo.zoom=17;demo.yaw=.6;demo.pitch=.65;demo._update_camera();demo.town.clear_preview()
	var house:Node3D=demo.town.buildings.get_node(str(placed.house_id));var plan:Dictionary=house.get_meta("amphitheater",{})
	_check(not plan.is_empty() and demo.state.water_clearance(plan.stage)<-.65 and house.get_meta("signature_stage_triangles",0)>300,"actual renderer builds white sails wet stage piano jetty and three curved shoreline stands")
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(plan.stage.x,10,plan.stage.y),Vector3(plan.stage.x,-.4,plan.stage.y),1)
	var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(ray)
	_check(not hit.is_empty() and hit.collider.get_meta("water_stage",false) and hit.collider.get_meta("house_id")==placed.house_id,"physical overwater stage and sail picking retain the authored landmark and terrace identity")
	await _capture("03_water_amphitheater_shore_stands_and_sails")
	demo.ui_layer.visible=true;demo.selected_house=placed.house_id;demo.select_tool(4);demo.spatial_popover.open_for_house(placed.house_id);await process_frame
	var pop=demo.spatial_popover
	pop.inspector.roles.show_for(true);await process_frame
	var role_button:Button=pop.inspector.roles.buttons.symphony_hall
	_check(role_button.is_visible_in_tree() and not role_button.disabled,"eighth role remains available for the already placed modern hall")
	pop.inspector.roles.panel.hide();pop.inspector.show_page("music");await process_frame
	_check(pop.concert_button.is_visible_in_tree() and pop.concert_button.visible and "跨时代" in pop.concert_button.caption,"actual grand-festival action is enabled in production music inspector")
	await _capture("01_actual_music_action");root.grab_focus()
	await _click(pop.concert_button)
	_check(demo.life._concert.get("grand_festival",false) and demo.life.concert_status().phase=="gathering","actual UI button creates a four-era invitation while residents still need to arrive")
	demo.ui_layer.visible=false
	for i in range(7000):
		var status:Dictionary=demo.life.concert_status()
		if status.phase=="playing" or status.arrived==status.invited:break
		demo.life._process(.1)
		if i%50==0:await process_frame
	_check(demo.life.concert_status().arrived==demo.life.concert_status().invited,"every actual invited resident reaches the real shoreline entrance before music starts")
	fixture.facts.gathered=demo.life.concert_status()
	var recording:=Span.start();var theme_capture:=AudioEffectCapture.new();var theme_index:=AudioServer.get_bus_index(demo.music.spatial.report().bus_names[0]);AudioServer.add_bus_effect(theme_index,theme_capture);var phase_peaks:Dictionary={}
	var before:int=demo.state.life_progress.concerts;demo.life.set_process(true)
	var deadline:=Time.get_ticks_msec()+40000;var observed:Dictionary={};var frames:Array[float]=[];var last:=Time.get_ticks_usec();var waves:Dictionary={};var saved:=false;var save_attempted:=false;var save_result:Dictionary={};var sounding_started:=0
	while Time.get_ticks_msec()<deadline:
		await process_frame
		var now:=Time.get_ticks_usec();frames.append((now-last)/1000.);last=now
		var report:Dictionary=demo.music.grand_festival_report()
		if report.active and sounding_started==0:sounding_started=Time.get_ticks_usec()
		var buffer:=theme_capture.get_buffer(theme_capture.get_frames_available());var peak:=0.
		for sample:Vector2 in buffer:peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		if report.active and float(report.elapsed)>float(report.phrase)*3.+.25:phase_peaks[int(report.phrase)]=maxf(float(phase_peaks.get(int(report.phrase),0.)),peak)
		if report.active and float(report.elapsed)>float(report.phrase)*3.+1.8 and not observed.has(int(report.phrase)):
			var phase:int=report.phrase
			var volumes:Dictionary={}
			for key:String in demo.music.STEMS:volumes[key]=demo.music._players[key].volume_db
			var theme_bus:int=AudioServer.get_bus_index(demo.music.spatial.report().bus_names[0])
			observed[phase]={"era":report.era,"source":report.source_id,"gains":report.gains,"actual_volumes":volumes,"remote":report.remote,"theme_lowpass":AudioServer.is_bus_effect_enabled(theme_bus,1),"acoustic_weight":demo.music._long_acoustic_weight("wood"),"active_source":demo.music.active_source()}
			var roles:Dictionary=demo.music.get_meta("chamber_roles",{});var stem:String=roles.lead_track;var role:Dictionary=roles.roles[stem]
			var actual:AudioStream=demo.music._players[stem].stream;var expected:AudioStream=demo.music._variation_streams.get(role.id,demo.music._harmony_streams.get(role.id))
			observed[phase].melody={"stem":stem,"id":role.id,"layer":role.layer,"actual_id":demo.music._variation_active.get(stem,""),"stream_matches":actual==expected,"playing":demo.music._players[stem].playing,"position":demo.music._players[stem].get_playback_position()}
			observed[phase].melody.evidence=StreamEvidence.capture(demo.music,stem,str(role.id))
			if phase==2:
				waves=demo.town.grand_festival_visual.report.duplicate(true)
				await _capture("04_real_golden_water_and_rail_waves");last=Time.get_ticks_usec()
			if phase==7:
				demo.focus=Vector3(0,1,3);demo.zoom=72;demo._update_camera();await _capture("05_four_era_tutti_across_actual_city");last=Time.get_ticks_usec()
		if report.active and report.elapsed>10. and not save_attempted:
			save_attempted=true;save_result=demo.state.set_journey_checkpoint(demo.life.checkpoint())
			if save_result.ok:
				var check:=State.new();save_result=check.restore(JSON.parse_string(JSON.stringify(demo.state.snapshot(),"",true,true)))
			saved=save_result.ok
			if not saved:print("GRAND_SAVE_ERROR ",save_result)
		if int(demo.state.life_progress.concerts)>before:break
	demo.life.set_process(false)
	var sounding_wall_seconds:float=(Time.get_ticks_usec()-sounding_started)/1000000. if sounding_started>0 else -1.
	var pcm:=Span.finish(recording,OUT+"/grand_Master.wav");AudioServer.remove_bus_effect(theme_index,AudioServer.get_bus_effect_count(theme_index)-1)
	_check(pcm.ok and phase_peaks.size()==8 and phase_peaks.values().all(func(value:float)->bool:return value>.00001),"actual Master recording and each of eight theme-bus PCM phrases are non-silent and unclipped")
	_check(observed.size()==8 and observed[0].era=="pastoral" and observed[2].era=="renaissance" and observed[4].era=="clockwork" and observed[6].era=="modern_eco" and observed[7].era=="tutti","unaccelerated production transport audibly visits all four real era sources and final full tutti over eight phrases")
	_check(observed.size()==8 and observed.values().all(func(row:Dictionary)->bool:return row.melody.layer==3 and row.melody.evidence.qualified and row.melody.playing and row.melody.actual_id==row.melody.id and not "chamber_counter_" in str(row.melody.id)),"every era melody owns its bank stream or verified PCM transition from a current melody")
	_check(sounding_wall_seconds>=22. and sounding_wall_seconds<=26.,"the twenty-four-second performance follows audio time under actual slow frames")
	var audible:=true;var remote:=false;var filtered:=true
	for row:Dictionary in observed.values():
		audible=audible and row.active_source.audible
		if row.remote:remote=true;filtered=filtered and row.theme_lowpass and is_equal_approx(row.acoustic_weight,.25)
	_check(audible and remote and filtered,"actual dominant era PCM remains audible including quarter-gain distant special-event low-pass response")
	_check(waves.get("rail_edges",0)==demo.life.tram.plan.edges.size() and waves.get("rail_edges",0)>0 and waves.get("maximum_distance",0)>20. and waves.get("distance_source","")=="actual_street_graph","gold waves cover every actual connected rail edge using true road-network propagation distance")
	_check(saved and demo.state.life_progress.concerts==before+1 and demo.life.concert_status().phase=="idle","actual intermediate grand save validates and full twenty-four-second performance settles once")
	_check(not demo.life.finale_view().is_empty(),"completed water-theater performance retains its authored twelve-second finale")
	demo.life.set_process(false);var finale_ticks:=0
	while not demo.life.finale_view().is_empty() and finale_ticks<140:
		demo.life._process(.1);finale_ticks+=1;await process_frame
	await process_frame
	var strength:Variant=demo.town.water_material.get_shader_parameter("festival_strength")
	var finale_visual:Dictionary={"active":demo.town.grand_festival_visual.report.active,"strength":strength,"type":typeof(strength),"zero":is_zero_approx(float(strength))}
	_check(not finale_visual.active and finale_visual.zero,"after the real finale water and rail event glow retire without changing ordinary scenery")
	frames.sort();var p95:float=frames[int(frames.size()*.95)]
	_check(demo.music.STEMS.size()==12 and demo.music._effects.size()==4 and demo.music.spatial.report().bus_count==6,"grand performance preserves twelve long voices four short voices and six buses")
	_check(pcm.ok and pcm.peak<1. and (FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray())==personal,"actual recorded Master stays below full scale and personal save bytes remain valid")
	if not source.is_empty():_check(FileAccess.get_sha256(source)==fixture.facts.source_sha256,"shipped work bytes remain unchanged")
	var result:Dictionary={"ok":failures.is_empty(),"count":checks.size(),"checks":checks,"failures":failures,"observed":observed,"waves":waves,"pcm":pcm,"sounding_wall_seconds":sounding_wall_seconds,"phase_theme_peaks":phase_peaks,"finale_visual":finale_visual,"frame_p95_ms":p95,"frame_max_ms":frames[-1],"save_result":save_result,"end_status":demo.life.concert_status(),"mix_peaks":demo.music.audio_report.mix_peaks,"facts":fixture.facts}
	FileAccess.open(OUT+"/grand_live.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t",true,true));print("GRAND_LIVE ",JSON.stringify({"ok":result.ok,"count":checks.size(),"failures":failures,"frame_p95_ms":p95}))
	demo.queue_free();await process_frame;await create_timer(.1).timeout;quit(0 if failures.is_empty() else 1)
