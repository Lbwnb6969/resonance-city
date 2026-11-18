extends "res://tools/check_game_music_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
const Fit=preload("res://scripts/audio/city_creation_music_era_fit.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	var trial:=Trial.new();demo.add_child(trial);check(trial.install(demo),"original isolated L loads expanded sparse catalog")
	var pointer:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/active_game_music.json"));var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(pointer.sparse_trial.catalog));var rows:Array=[]
	for row:Dictionary in catalog.packs:rows.append(row.merged({"era":JSON.parse_string(FileAccess.get_file_as_string(row.manifest)).era}))
	check(rows.size()==4 and rows.map(func(row):return row.era).has("modern_eco"),"four-era sparse candidates are present")
	facts.candidates=[]
	for row:Dictionary in rows:
		var city:=State.new();city.initialize_free();Brush.select(city,row.era);check(city.add_house(Vector2(16,18)).ok,"public isolated "+row.era+" house")
		if row.era=="modern_eco":
			var prefs:Dictionary=city.creative_settings.music.duplicate();prefs.mode="fixed";prefs.style="warm";check(city.CreationPolicy.set_preferences(city,{"music":prefs}).ok,"public fixed preference for real dual-schema source")
		await show(city,Vector2(16,18),row.name);quiet();demo.life.set_process(false)
		for i in range(trial.packs.size()):
			if trial.packs[i].manifest==row.manifest:trial.picker.select(i)
		trial.start_selected();var node:Node=trial.conductor
		check(await wait_for(func():return is_instance_valid(node) and node.active,30000),"actual L action loads "+row.era)
		if not is_instance_valid(node) or not node.active:continue
		await create_timer(1.).timeout
		check(node.prepared.manifest.source_id==row.source_id and node.prepared.manifest.schema=="city_sparse_music_v2" and node.prepared.signature==row.manifest_sha256,"real selected source, schema and signed bytes for "+row.era)
		check(node.values.background==1. and node.values.body==0. and node.values.detail==0.,row.era+" lone house starts with independent background only")
		check(Fit.city_era(demo.state,node.spatial_facts.weights)==row.era,"actual house and acoustic weights retain requested era")
		var next:Dictionary=node.sequence.select_next();check(not next.is_empty() and next.source_id==row.source_id and next.bundle_schema=="city_sparse_music_v2","same-era same-schema successor for "+row.era)
		check(node.seek(10.),"synchronized cursor "+row.era);var record:=Span.start();await create_timer(3.).timeout
		var pcm:=Span.finish(record,OUT+"/"+row.era+"_Master.wav");check(pcm.ok,"actual "+row.era+" background PCM is non-silent and unclipped")
		facts.candidates.append({"source_id":node.prepared.manifest.source_id,"era":row.era,"signature":node.prepared.signature,"values":node.values.duplicate(),"pcm":pcm})
		if row.era=="modern_eco":
			check(node.sequence.rows.any(func(candidate):return candidate.source_id==row.source_id and candidate.bundle_schema=="city_adaptive_music_v1"),"real modern source has both v1 and v2 in L")
			check(node.seek(float(node.prepared.manifest.frames)/44100.-.4),"seek all modern streams to real natural ending")
			check(await wait_for(func():return node.sequence.transitions.size()==1,10000),"fixed modern v2 actually continues after song end")
			check(node.prepared.manifest.schema=="city_sparse_music_v2" and node.prepared.manifest.source_id==row.source_id,"actual dual-schema fixed replay keeps v2")
		await capture(row.era)
	var empty:=State.new();empty.initialize_free();await show(empty,Vector2(16,18),"结束四时代候选检验");quiet()
	check(pool()==voices,"12 long/4 short/6 bus player identities retained")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save bytes preserved")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SPARSE_ERAS ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
