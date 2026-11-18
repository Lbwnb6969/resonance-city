extends SceneTree
const Record=preload("res://scripts/audio/city_creation_candidate_record.gd")
const Phono=preload("res://scripts/audio/city_creation_phonograph.gd")
const Library=preload("res://scripts/world/city_creation_collection.gd")
const State=preload("res://scripts/world/city_creation_state.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec()
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/游戏音乐包/20261106_remaining_v2/catalog.json"))
	var path:String=catalog.packs.filter(func(row):return row.name.begins_with("1-04"))[0].manifest;var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path));var gains:Dictionary={}
	for layer:Dictionary in data.layers:gains[layer.id]=1. if layer.id=="background" else float(layer.automatic_max)*.5
	var value:={"version":2,"source_id":data.source_id,"bundle_schema":data.schema,"manifest":path,"manifest_sha256":FileAccess.get_sha256(path),"frames":data.frames,"position":37.25,"values":gains,"master_gain":.8,"ended":false,"fallback":false,"name":data.name}
	check(Phono.valid(value),"real sparse candidate frozen snapshot structure")
	var packet:=Record.prepare(value);check(packet.get("ok",false) and packet.ids.size()==gains.size(),"actual signed same-source synchronized audio prepares")
	for field:String in ["source_id","manifest_sha256"]:
		var bad:=value.duplicate(true);bad[field]="x";check(not Record.valid(bad),"malformed identity refused "+field)
	for candidate:String in ["C:/Windows/bundle.json","res://数据/音乐资产/游戏音乐包/../bundle.json","res://数据/音乐资产/游戏音乐包/a\\bundle.json","https://example.com/bundle.json","res://数据/音乐资产/游戏音乐包/a://bundle.json"]:
		var bad:=value.duplicate(true);bad.manifest=candidate;check(not Record.valid(bad),"external/traversal path refused "+candidate)
	for field:String in ["position","frames","master_gain"]:
		var bad:=value.duplicate(true);bad[field]=NAN;check(not Record.valid(bad),"non-finite number refused "+field)
	var bad:=value.duplicate(true);bad.values.body=INF;check(not Record.valid(bad),"non-finite layer gain refused")
	bad=value.duplicate(true);bad.values.erase("body");check(not Record.prepare(bad).get("ok",false),"missing saved layer cannot become a different mix")
	bad=value.duplicate(true);bad.source_id="0".repeat(64);check(not Record.prepare(bad).get("ok",false),"manifest source identity mismatch refused")
	bad=value.duplicate(true);bad.bundle_schema="city_adaptive_music_v1";check(not Record.prepare(bad).get("ok",false),"same source cannot change bundle protocol")
	bad=value.duplicate(true);bad.frames+=1;check(not Record.prepare(bad).get("ok",false),"saved frame identity mismatch refused")
	bad=value.duplicate(true);bad.fallback=true;check(not Record.prepare(bad).get("ok",false),"degraded full mix cannot replace recorded sparse layers")
	bad=value.duplicate(true);bad.values.detail=.1;check(not Record.prepare(bad).get("ok",false),"silent residual cannot be enabled by a changed record")
	bad=value.duplicate(true);bad.values.body=.8;check(not Record.prepare(bad).get("ok",false),"recorded layer cannot exceed source automatic cap")
	var missing:=value.duplicate(true);missing.manifest="res://数据/音乐资产/游戏音乐包/missing/bundle.json";check(Record.valid(missing) and not Record.prepare(missing).get("ok",false),"missing local audio preserves structural readability while refusing replay")
	var city:=State.new();city.initialize_free();var original:=var_to_bytes(city.snapshot());var lib:=Library.new();lib.directory=out+"/works"
	var cover:=Image.create(8,8,false,Image.FORMAT_RGBA8);cover.fill(Color.BEIGE);var view:={"focus":[-3.,.8,0.],"zoom":25.,"yaw":.25,"pitch":.8,"evening":false,"light_phase":0}
	var saved:=lib.save("本地稀疏混音",city.snapshot(),view,cover,"manual",value);check(saved.ok,"real immutable collection accepts version2 mix")
	var read:Dictionary=lib.read(saved.id) if saved.ok else {};check(read.get("ok",false) and JSON.stringify(read.phonograph_mix,"",true,true)==JSON.stringify(JSON.parse_string(JSON.stringify(value)),"",true,true),"disk collection roundtrip retains all frozen mix fields")
	var absent:=lib.save("缺包仍可保留",city.snapshot(),view,cover,"manual",missing);check(absent.ok and lib.read(absent.id).ok,"collection remains readable when local audio is absent")
	check(var_to_bytes(city.snapshot())==original,"collection and audio prepare leave author snapshot intact")
	var legacy:={"version":1,"position":0.,"mode":-1,"theme_pan":0.,"concert_pan":0.,"tracks":{}}
	for stem:String in Phono.STEMS:legacy.tracks[stem]={"bank":"original","key":stem,"db":-20.}
	check(Phono.valid(legacy),"legacy twelve-bank version1 structure preserved")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"source_id":data.source_id,"manifest_sha256":value.manifest_sha256,"default_changed":false,"listening_approved":false}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("CANDIDATE_RECORD_CPU ",JSON.stringify(report));quit(0 if report.ok else 1)
