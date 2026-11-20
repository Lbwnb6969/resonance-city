extends SceneTree
const Fit=preload("res://scripts/audio/city_creation_music_era_fit.gd")
const Sequence=preload("res://scripts/audio/city_creation_game_music_sequence.gd")
const State=preload("res://scripts/world/city_creation_state.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
class MusicHost extends Node:
	var _pluck_city:RefCounted
class CandidateHost extends Node:
	var music:Node
	var prepared:Dictionary={"manifest":{"source_id":"past_a"}}
	var spatial_facts:Dictionary={}
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
	var city:=State.new();city.initialize_free();check(Fit.city_era(city,{})=="pastoral","empty default city era")
	Brush.select(city,"modern_eco");check(Fit.city_era(city,{})=="modern_eco","empty city follows explicit current brush")
	for era:String in Fit.ERAS:
		Brush.select(city,era);var result:Dictionary=city.add_house(Vector2(12+city.houses.size()*4,18));check(result.ok,"public era house "+era)
	for i in range(4):check(Fit.city_era(city,{city.houses[i].id:1.})==Fit.ERAS[i],"actual house era through spatial focus weights")
	var affinity:=preload("res://scripts/audio/city_creation_music_affinity.gd").new();affinity.refresh(city)
	for zoom:float in [8.,48.]:
		for focus:Vector2 in [Vector2(12,18),Vector2(24,18)]:
			var facts:=affinity.sample(focus,zoom)
			check(facts.era==Fit.city_era(city,facts.weights),"sampled era matches independent lookup at both zooms and focuses")
	var original:=var_to_bytes(city.snapshot());var music:=MusicHost.new();music._pluck_city=city;var host:=CandidateHost.new();host.music=music;host.spatial_facts=affinity.sample(Vector2(12,18),8.)
	var sequence:=Sequence.new();sequence.owner=host;sequence.enabled=true;sequence.era_fit={"past_a":"pastoral","past_b":"pastoral","modern_a":"modern_eco"}
	sequence.rows=[{"source_id":"past_a","fit":[0.,0.,0.]},{"source_id":"past_b","fit":[1.,1.,1.]},{"source_id":"modern_a","fit":[0.,0.,0.]},{"source_id":"unknown","fit":[0.,0.,0.]}]
	check(sequence.select_next().source_id=="past_b","wrong-era and unknown candidates excluded even when acoustic fit is better")
	sequence.recent=["past_b"];check(sequence.select_next().source_id=="past_b","history exclusion never falls into another era")
	host.spatial_facts=affinity.sample(Vector2(24,18),8.);check(sequence.select_next().source_id=="modern_a","actual modern focus selects modern candidate")
	host.spatial_facts=affinity.sample(Vector2(16,18),8.);check(sequence.select_next().is_empty(),"missing era returns no successor")
	sequence.prepare_next();check(sequence.worker==null and sequence.failed=="no_era_candidate","missing fit starts no full-mix fallback worker")
	city.creative_settings.music.mode="fixed";check(sequence.select_next().source_id=="past_a","explicit fixed manual choice can repeat its complete source")
	host.prepared.manifest.schema="city_sparse_music_v2"
	sequence.rows.append({"source_id":"past_a","fit":[0.,0.,0.],"bundle_schema":"city_sparse_music_v2"})
	check(sequence.select_next().get("bundle_schema","")=="city_sparse_music_v2","fixed same source cannot fall from sparse v2 to complete v1")
	host.prepared.signature="selected_render"
	sequence.rows.append({"source_id":"past_a","fit":[0.,0.,0.],"bundle_schema":"city_sparse_music_v2","manifest_sha256":"selected_render"})
	check(sequence.select_next().get("manifest_sha256","")=="selected_render","fixed mode keeps the exact current render when the same source was registered twice")
	city.creative_settings.music.mode="auto";check(var_to_bytes(city.snapshot())==original,"selection itself leaves city author state intact")
	var editorial:=Fit.read();check(not editorial.is_empty() and not editorial.values().has("modern") and not editorial.values().has("mixed_reserve"),"real editorial review normalizes modern and excludes unknown reserves")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"editorial_rows":editorial.size()}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("MUSIC_ERA_FIT ",JSON.stringify(report));host.free();music.free();quit(0 if report.ok else 1)
