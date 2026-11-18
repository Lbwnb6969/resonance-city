extends SceneTree
const Select=preload("res://scripts/audio/city_creation_background_candidate.gd")
const Fit=preload("res://scripts/audio/city_creation_music_era_fit.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec()
	var pointer:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/active_game_music.json"));var old:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(pointer.catalog));var extra:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(pointer.sparse_trial.catalog));var packs:Array=old.packs+extra.packs;var fit:=Fit.read();var choices:Array=[]
	for era:String in Fit.ERAS:
		var choice:=Select.select(packs,fit,era);check(not choice.is_empty(),"era candidate exists "+era)
		if choice.is_empty():continue
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(choice.manifest));check(data.schema=="city_sparse_music_v2" and data.name.begins_with(Select.START_CODES[era]) and fit[choice.source_id]==era,"preferred initial sparse source and editorial era "+era);choices.append(choice)
	check(Select.select(old.packs,fit,"pastoral").is_empty(),"full v1 library is never automatic entry fallback")
	check(Select.select(extra.packs.filter(func(row):return not row.get("automatic_candidate",true)),fit,"pastoral").is_empty(),"manual-only complete works excluded")
	check(Select.select(packs,{},"pastoral").is_empty() and Select.select(packs,fit,"").is_empty(),"unknown fit and unknown era fail closed")
	var changed:Array=extra.packs.duplicate(true)
	for row:Dictionary in changed:
		if row.source_id==choices[0].source_id:row.manifest_sha256="invalid"
	var alternative:=Select.select(changed,fit,"pastoral");check(not alternative.is_empty() and alternative.source_id!=choices[0].source_id,"broken preferred signature uses another sparse candidate")
	var source:Dictionary=extra.packs[0];var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source.manifest));data.automatic_candidate=false;var path:=out+"/manual_sparse.json";FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data));var row:Dictionary=source.duplicate();row.manifest=path;row.manifest_sha256=FileAccess.get_sha256(path);row.automatic_candidate=true
	check(Select.select([row],fit,"pastoral").is_empty(),"manifest exclusion cannot be overridden at the new entry")
	data.automatic_candidate=true;data.era="clockwork";FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data));row.manifest_sha256=FileAccess.get_sha256(path);check(Select.select([row],fit,"pastoral").is_empty(),"manifest era must agree with editorial source fit")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"choices":choices};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("BACKGROUND_ENTRY ",JSON.stringify(report));quit(0 if report.ok else 1)
