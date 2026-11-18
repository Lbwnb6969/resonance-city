extends SceneTree
const Sequence=preload("res://scripts/audio/city_creation_game_music_sequence.gd")
const Fit=preload("res://scripts/audio/city_creation_music_sequence_fit.gd")
const State=preload("res://scripts/world/city_creation_state.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
class MusicHost extends Node:
	var _pluck_city:RefCounted
class Host extends Node:
	var music:Node
	var clock:=1.
	var prepared:Dictionary={"manifest":{"source_id":"not_in_catalog","schema":"city_sparse_music_v2"}}
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
	var pointer:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/active_game_music.json"))
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(pointer.sparse_trial.catalog))
	var city:=State.new();city.initialize_free();var snapshot:=var_to_bytes(city.snapshot())
	var music:=MusicHost.new();music._pluck_city=city;var host:=Host.new();host.music=music;var seq:=Sequence.new();seq.configure(host,catalog.packs)
	check(seq.rows.size()==catalog.packs.size(),"all active combined catalog rows signed and read")
	var vectors:Dictionary={}
	for row:Dictionary in seq.rows:vectors[row.name]=row.fit
	check(vectors.values().any(func(v):return v==[0.,0.,0.,1.]),"real highland response survives intake")
	for f:Dictionary in [{"era":"pastoral","values":[0.,0.,0.,0.],"code":"1-01"},{"era":"pastoral","values":[1.,0.,0.,0.],"code":"1-02"},{"era":"pastoral","values":[0.,1.,0.,0.],"code":"1-04"},{"era":"pastoral","values":[0.,0.,1.,0.],"code":"1-05"},{"era":"clockwork","values":[0.,0.,0.,1.],"code":"3-06"}]:
		Brush.select(city,f.era);host.spatial_facts.era=Brush.current(city).era;seq.history=[f.values];var selected:=seq.select_next()
		check(selected.name.begins_with(f.code) and selected.bundle_schema=="city_sparse_music_v2","actual catalog spatial selection "+f.code)
	seq.history=[];host.spatial_facts={"enclosure":.25,"flow":.5,"craft":.75,"highland":{"value":.9}};seq.observe()
	check(seq.average()==[.25,.5,.75,.9],"actual observe samples highland value alongside original facts")
	host.clock=2.;host.spatial_facts={};seq.observe();check(seq.average()==[.125,.25,.375,.45],"absent facts count as open space rather than stale affinity")
	for i in range(3,40):host.clock=float(i);seq.observe()
	check(seq.history.size()==30 and seq.average()==[0.,0.,0.,0.],"thirty-second history ages out old spatial context")
	host.spatial_facts.era=Brush.current(city).era
	seq.history=[[0.,0.,0.,1.]];var selected:=seq.select_next();host.prepared.manifest.source_id=selected.source_id
	check(seq.select_next().source_id!=selected.source_id,"actual current source excluded before spatial ranking")
	host.prepared.manifest.source_id="not_in_catalog";seq.recent=[selected.source_id];check(seq.select_next().source_id!=selected.source_id,"recent source excluded before ranking")
	city.creative_settings.music.mode="fixed";host.prepared.manifest.source_id=selected.source_id
	check(seq.select_next().source_id==selected.source_id and seq.select_next().bundle_schema=="city_sparse_music_v2","explicit fixed choice keeps source and protocol")
	city.creative_settings.music.mode="auto";seq.recent=[];seq.era_fit={};check(seq.select_next().is_empty(),"unknown editorial era does not acquire eligibility from response vector")
	var stale:Dictionary=catalog.packs[0].duplicate(true);stale.manifest_sha256="stale";seq.configure(host,[stale]);check(not seq.enabled,"changed manifest signature cannot produce a ranked candidate")
	var legacy:=Fit.vector({"schema":"city_adaptive_music_v1","descriptors":{"body":{"features":{"low_band_fraction":.2}},"motion":{"features":{"positive_envelope_change":1.2}},"detail":{"features":{"active_fraction":.7}}}})
	check(Vector3(legacy[0],legacy[1],legacy[2]).is_equal_approx(Vector3(.2,1.,.3)),"v1 statistical feature calculation preserved")
	check(Fit.vector({"schema":"city_sparse_music_v2","layers":[{"id":"background","role":"background","automatic_max":1.,"control":"flow"},{"id":"detail","role":"unassigned","automatic_max":0.,"control":"craft"} ]})==[0.,0.,0.,0.],"background and disabled residual never invent response affinity")
	Brush.select(city,"pastoral");check(var_to_bytes(city.snapshot())==snapshot,"read-only selection leaves author state intact")
	# Actual catalog: constant scenery must not starve the rest of an era.
	var coverage:Array=[]
	for era:String in ["pastoral","renaissance","clockwork","modern_eco"]:
		Brush.select(city,era);host.spatial_facts.era=Brush.current(city).era;seq.configure(host,catalog.packs);seq.recent=[];seq.history=[[0.,0.,0.,0.]]
		var eligible:Array=seq.rows.filter(func(row):return seq.era_fit.get(row.source_id,"")==era and row.get("automatic_candidate",true))
		host.prepared.manifest.source_id=eligible[0].source_id;var seen:Dictionary={}
		for turn in range(eligible.size()*2):
			var next:=seq.select_next();var counts:=seq.play_counts.duplicate()
			check(seq.select_next().source_id==next.source_id and seq.play_counts==counts,"preparation probes never consume a turn "+era+str(turn))
			seen[next.source_id]=true;seq.record_play(str(next.source_id));seq.recent.append(host.prepared.manifest.source_id)
			if seq.recent.size()>2:seq.recent.pop_front()
			host.prepared.manifest.source_id=next.source_id
		check(seen.size()==eligible.size(),"every eligible source gets a turn in stable "+era)
		coverage.append({"era":era,"eligible":eligible.size(),"reached":seen.size()})
	Brush.select(city,"pastoral")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"coverage":coverage,"real_vectors":vectors,"default_changed":false,"listening_approved":false}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SEQUENCE_FIT ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));host.free();music.free();quit(0 if report.ok else 1)
