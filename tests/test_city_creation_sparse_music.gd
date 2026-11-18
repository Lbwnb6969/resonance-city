extends SceneTree
const Bundle=preload("res://scripts/audio/city_creation_game_music_bundle.gd")
const Sparse=preload("res://scripts/audio/city_creation_sparse_music_bundle.gd")
const PATH="res://数据/音乐资产/游戏音乐包/20261106_sparse_v2/1_02/bundle.json"
var out:=""
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func invalid(data:Dictionary,label:String)->void:
	var path:=out+"/"+label+".json";FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data));check(not Bundle.read(path).ok,label)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec()
	var packet:=Bundle.read(PATH);check(packet.ok,"real v2 candidate loads")
	if packet.ok:
		check(packet.ids==["background","body","detail"] and packet.stream.stream_count==3 and not packet.fallback,"three synchronous source layers, no master fallback")
		check(Sparse.initial(packet,"background")==1. and Sparse.initial(packet,"body")==0. and Sparse.initial(packet,"detail")==0.,"independent background starts alone")
		check(packet.stream.get_sync_stream_volume(1)==-INF and packet.stream.get_sync_stream_volume(2)==-INF,"native optional streams initially exactly silent")
	var original:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PATH));var bad:Dictionary
	bad=original.duplicate(true);bad.layers[1].sha256="bad";invalid(bad,"broken_layer_cannot_restore_full_mix")
	bad=original.duplicate(true);bad.layers[0].source_id="other";invalid(bad,"cross_source_rejected")
	bad=original.duplicate(true);bad.layers[2].automatic_max=.1;invalid(bad,"unclassified_residual_cannot_enter")
	bad=original.duplicate(true)
	for i in [1,2]:bad.layers[i].role="lead";bad.layers[i].layer=3;bad.layers[i].automatic_max=.2
	invalid(bad,"multiple_layer3_leads_rejected")
	var pointer:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/active_game_music.json"));var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(pointer.catalog));var old:=Bundle.read(catalog.packs[0].manifest)
	check(old.ok and old.ids[0]=="core" and Sparse.initial(old,"body")==.35,"v1 complete core and .35 floor remain compatible")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SPARSE_BUNDLE ",JSON.stringify(report));quit(0 if report.ok else 1)
