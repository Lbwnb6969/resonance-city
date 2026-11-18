extends SceneTree
const Bundle=preload("res://scripts/audio/city_creation_game_music_bundle.gd")
const Sparse=preload("res://scripts/audio/city_creation_sparse_music_bundle.gd")
const Sequence=preload("res://scripts/audio/city_creation_game_music_sequence.gd")
const State=preload("res://scripts/world/city_creation_state.gd")
class MusicHost extends Node:
	var _pluck_city:RefCounted
class Host extends Node:
	var music:Node
	var prepared:Dictionary={"manifest":{"source_id":"","schema":"city_adaptive_music_v1","layers":[]}}
	var values:Dictionary={}
	var spatial_facts:Dictionary={}
	var envelope_state:Dictionary={"value":.8}
	var contour_state:Dictionary={"value":.7}
	var color_states:Dictionary={"flow":{"value":.6},"craft":{"value":.4}}
	var manual_expression:=false
	var expression:Dictionary={"flow":1.,"craft":1.}
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
	var pointer:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/active_game_music.json"));var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(pointer.sparse_trial.catalog));var results:Array=[];var manual:Dictionary={};var sparse_count:=0;var complete_count:=0
	for row:Dictionary in catalog.packs:
		var packet:=Bundle.read(row.manifest);check(packet.ok,"real audio container loads "+row.name)
		if not packet.ok:continue
		check(packet.signature==row.manifest_sha256 and packet.manifest.source_id==row.source_id and packet.ids.size()<=4,"catalog identity and voice budget "+row.name)
		if packet.manifest.schema==Sparse.SCHEMA:
			sparse_count+=1;check(Sparse.initial(packet,"background")==1. and packet.stream.get_sync_stream_volume(packet.ids.size()-1)==-INF,"actual sparse optional endpoint remains silent")
		else:
			complete_count+=1;check(not packet.manifest.automatic_candidate and not row.automatic_candidate and packet.ids==["core"],"complete master is explicitly manual-only")
			if packet.manifest.name.begins_with("1-10"):manual=row
		results.append({"source_id":row.source_id,"schema":packet.manifest.schema,"frames":packet.manifest.frames,"voices":packet.ids.size(),"signature":packet.signature})
	check(sparse_count==20 and complete_count==2,"twenty sparse candidates plus two manual full works")
	var host:=Host.new();host.prepared.manifest.layers=[{"id":"background","automatic_max":1.},{"id":"body","automatic_max":.25,"control":"flow"},{"id":"motion","automatic_max":.2,"control":"craft"},{"id":"detail","automatic_max":0.,"control":"none"}]
	Sparse.step(host,{});check(is_equal_approx(host.values.body,.15) and is_equal_approx(host.values.motion,.08) and host.values.detail==0.,"voice ids independently bind flow/craft instead of enclosure")
	host.prepared.manifest.layers[1].control="highland";Sparse.step(host,{});check(is_equal_approx(host.values.body,.175),"highland uses existing contour envelope")
	host.prepared.manifest.layers[1].control="enclosure";Sparse.step(host,{});check(is_equal_approx(host.values.body,.2),"enclosure remains a separate control")
	host.prepared.manifest.layers[1].control="flow";host.manual_expression=true;Sparse.step(host,{});check(host.values.body==.25 and host.values.motion==.2,"explicit manual expression uses named controls")
	host.manual_expression=false;host.color_states={"flow":{"value":0.},"craft":{"value":0.}};Sparse.step(host,{});check(host.values.body==0. and host.values.motion==0.,"expired observations produce exact zero optional gains")
	var music:=MusicHost.new();var city:=State.new();city.initialize_free();city.add_house(Vector2(12,18));music._pluck_city=city;host.music=music;host.spatial_facts={"era":city.house_era(city.houses[0])}
	var original_catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(pointer.catalog));var clean:Dictionary=original_catalog.packs[0];host.prepared.manifest={"source_id":clean.source_id,"schema":"city_adaptive_music_v1"}
	var sequence:=Sequence.new();var forced:Dictionary=manual.duplicate(true);forced.automatic_candidate=true;sequence.configure(host,[forced,clean]);check(not sequence.rows[0].automatic_candidate,"manifest manual-only flag cannot be overridden by catalog true")
	check(sequence.select_next().source_id==clean.source_id,"automatic succession never chooses voice-marked full master")
	city.creative_settings.music.mode="fixed";host.prepared.manifest.source_id=manual.source_id;check(sequence.select_next().source_id==manual.source_id,"explicit fixed manual choice may repeat")
	var bad:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(catalog.packs[0].manifest));bad.layers[0].control="invalid";var path:=out+"/invalid_control.json";FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(bad));check(not Bundle.read(path).ok,"unknown control is rejected")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"loaded":results};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("MUSIC_BATCH ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));host.free();music.free();quit(0 if report.ok else 1)
