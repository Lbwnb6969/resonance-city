extends "res://tools/check_music_build_journey_live.gd"
const Integrated=preload("res://tools/fixtures/city_creation_integrated_city.gd")
const STREET_VIEWS := [["court",Vector2(-12,-19),19.,.55],["staggered",Vector2(-24,23),20.,.5],["clockwork",Vector2(17,23),20.,.5],["river",Vector2(0,4),23.,.65],["town",Vector2(0,3),76.,.8]]

func capture_street(view: Array) -> void:
	focus(view[1],view[2],view[3])
	for phase: int in [0,2]:
		demo._set_light_phase(phase)
		for frame_index in range(12): await process_frame
		await capture(view[0]+"_"+str(phase))
func focus(at:Vector2,zoom:float=24.,pitch:float=.7)->void:
	demo.focus=Vector3(at.x,.8,at.y);demo.zoom=zoom;demo.pitch=pitch;demo._update_camera()
func shape()->Dictionary:
	var rows:Dictionary={}
	for id:String in demo.town.house_roots:
		var entries:Array=[];var house:Node3D=demo.town.house_roots[id]
		for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh==null:continue
			for surface in range(mesh.mesh.get_surface_count()):
				var data:Array=mesh.mesh.surface_get_arrays(surface);entries.append(var_to_bytes([data,house.global_transform.affine_inverse()*mesh.global_transform]).hex_encode().sha256_text())
		entries.sort();rows[id]=entries
	return rows
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	var built:=Integrated.build();check(built.ok,"all public mixed-city construction operations succeed")
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();await show(built.city,Vector2(-25,21),"整城组合 · 四时代河湾");quiet();demo.life.set_process(true);focus(Vector2(-25,21),24.);await settle();var voices:=pool()
	check(demo.state.houses.size()==13 and demo.town.house_roots.size()==13 and demo.state.roads.size()==7 and demo.state.plants.size()==10,"all13 authored joined/staggered buildings, seven connected roads and ten plants publish")
	if "--visual-only" in OS.get_cmdline_user_args():
		var authored := var_to_bytes(demo.state.snapshot())
		demo.ui_layer.hide();demo.weather_visual.hide();demo.town.clear_preview()
		for view: Array in STREET_VIEWS: await capture_street(view)
		await capture_street(["door_path",Vector2(-25,29.6),8.,.82])
		check(authored==var_to_bytes(demo.state.snapshot()),"street views preserve authored city")
		var report := {"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"persistence":demo.persistence,"mode":"visual-only"}
		FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		print("INTEGRATED_CITY_VISUAL ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1);return
	trial=Trial.new();demo.add_child(trial);check(trial.install(demo),"current real candidate L is installed")
	for i in range(trial.packs.size()):
		if trial.packs[i].name.begins_with("4-06") and "20261108_modern_v2" in trial.packs[i].manifest:trial.picker.select(i);break
	demo.ledger.open_panel();await create_timer(.3).timeout;var recording:=Span.start();await ui_click(trial.play_button);check(await wait_for(active,30000),"actual L button starts modern candidate in mixed city")
	if not active():quit(1);return
	var node:Node=trial.conductor;var first:String=node.prepared.manifest.source_id;var duration:float=float(node.prepared.manifest.frames)/44100.;check(node.player.get_playback_position()<1. and node.values.background==1.,"complete source starts from zero with independent background")
	await key(KEY_ESCAPE);input_ground=demo.state._ground_terrain.get_script().new();input_ground.copy_cache_from(demo.state._ground_terrain)
	var plant_count:int=demo.state.plants.size();demo.select_tool(5);demo.vegetation_kind="olive";demo.vegetation_single=true;var plant_at:=Vector2(-32,26);await move(plant_at);await mouse(plant_at,true);await mouse(plant_at,false);await settle()
	check(demo.state.plants.size()==plant_count+1,"native pointer plants into real mixed city")
	await key(KEY_ESCAPE);await key(KEY_Z,true);await settle();check(demo.state.plants.size()==plant_count,"native Undo removes the actual plant");await key(KEY_Y,true);await settle();check(demo.state.plants.size()==plant_count+1,"native Redo restores it")
	var edit:Dictionary=demo.state.set_house_roof_pitch("h11",45.);demo._after_edit(edit,"room",true);await settle();check(edit.ok and demo.town.house_roots.h11.has_meta("modern_roof_pitch"),"real stepped modern house roof edit publishes during full song")
	await key(KEY_Z,true);await settle();check(not demo.state.houses[demo.state._house_index("h11")].has("roof_pitch"),"native Undo restores the original roof recipe");await key(KEY_Y,true);await settle()
	check(node.prepared.manifest.source_id==first and node.player.playing,"mixed construction/history do not cut current source")
	var saved:Dictionary=demo.state.snapshot();var continuous:=true;var previous:float=node.player.get_playback_position();var trace:Array=[]
	demo.ui_layer.hide();demo.weather_visual.hide();demo.town.clear_preview()
	for view:Array in STREET_VIEWS:
		await capture_street(view)
		continuous=continuous and node.prepared.manifest.source_id==first and node.player.get_playback_position()>=previous;previous=node.player.get_playback_position()
	# Stable local clockwork focus can only affect the successor, not this song.
	demo._set_light_phase(0);focus(Vector2(17,23),17.);var deadline:=Time.get_ticks_msec()+int((duration+20.)*1000.)
	while node.sequence.transitions.is_empty() and Time.get_ticks_msec()<deadline:
		await create_timer(.5).timeout
		if node.prepared.manifest.source_id==first and node.player.playing:
			var at:float=node.player.get_playback_position();continuous=continuous and at>=previous-.06;previous=at
		trace.append({"source":node.prepared.manifest.source_id,"position":node.player.get_playback_position(),"values":node.values.duplicate(),"era":node.sequence.era_observation.established})
		if trace.size()%40==0:print("INTEGRATED_PROGRESS ",previous," / ",duration)
	check(continuous and previous>duration-1. and node.sequence.transitions.size()==1,"whole modern song naturally completes without seek or edit restart")
	check(node.prepared.manifest.era=="clockwork" and node.prepared.manifest.schema=="city_sparse_music_v2","stable clockwork neighborhood supplies the actual next song only at natural ending")
	await create_timer(3.).timeout;facts.pcm=Span.finish(recording,OUT+"/whole_modern_mixed_city_Master.wav");check(facts.pcm.ok,"actual complete mixed-city performance and successor PCM non-silent/unclipped")
	facts.first_duration=duration;facts.last_first_cursor=previous;facts.transitions=node.sequence.transitions.duplicate(true);facts.trace=trace;facts.no_seek=true
	check(demo.state.snapshot()==saved,"day/night/camera/music leave authored city intact")
	await wait_for(func():return demo.town.touch.active.is_empty(),3000);var hot:=shape();var path:=OUT+"/city.json";check(demo.state.save_city(path).ok,"actual mixed work saves in isolated directory");var cold:=State.new();check(cold.load_city(path).ok,"independent State cold loads complete city")
	var prior:int=node.get_instance_id();await show(cold,Vector2(0,4),"组合城市冷读");quiet();await settle();check(shape()==hot,"all thirteen buildings retain exact construction arrays and rest transforms after cold read");check(not is_instance_id_valid(prior) and not demo.music.has_meta("game_music"),"city replacement withdraws candidate ownership")
	check(pool()==voices and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"original audio pool and personal save bytes remain intact")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts,"persistence":demo.persistence,"default_changed":false,"listening_approved":false};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("INTEGRATED_CITY ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
