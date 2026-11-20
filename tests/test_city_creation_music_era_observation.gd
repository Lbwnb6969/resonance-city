extends SceneTree
const Observation=preload("res://scripts/audio/city_creation_music_era_observation.gd")
const Fit=preload("res://scripts/audio/city_creation_music_era_fit.gd")
const Sequence=preload("res://scripts/audio/city_creation_game_music_sequence.gd")
const State=preload("res://scripts/world/city_creation_state.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
const Attention=preload("res://scripts/audio/city_creation_attention_mixer.gd")
class MusicHost extends Node:
	var _pluck_city:RefCounted
	var attention:=Attention.new()
class Host extends Node:
	var music:Node
	var paused:=false
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
	var city:=State.new();city.initialize_free()
	for era:String in Fit.ERAS:
		Brush.select(city,era);check(city.add_house(Vector2(12+city.houses.size()*4,18)).ok,"actual public era house "+era)
	var original:=var_to_bytes(city.snapshot());var observe:=Observation.new();var music:=MusicHost.new();music._pluck_city=city;var host:=Host.new();host.music=music
	var a:=Fit.city_era(city,{"h1":1.});var b:=Fit.city_era(city,{"h3":1.})
	observe.step(a,0.,0,false);check(observe.established=="pastoral" and observe.reason().is_empty(),"first actual context seeds an era without startup silence")
	observe.step(b,2.,0,false);check(observe.established==a and observe.reason()=="era_observation","two-second clockwork sweep does not replace established era")
	observe.step(a,.1,0,false);check(observe.established==a and observe.observed==0. and observe.reason().is_empty(),"return to established era cancels transient sweep")
	observe.step(b,10.,0,false);check(observe.established==a and observe.observed==0.,"slow frame arriving at a different era cannot credit the previous view")
	observe.step(b,5.9,0,false);check(observe.established==a,"sub-six-second candidate remains unadopted")
	observe.step(b,.11,0,false);check(observe.established==b and observe.reason().is_empty(),"six-second actual house-era candidate establishes")
	observe.step(a,2.,1,false);check(observe.reason()=="construction" and observe.observed==0.,"discrete public edit serial resets observation")
	observe.step(a,2.9,1,false);check(observe.reason()=="construction","three-second idle gate not bypassed")
	observe.step(a,.2,1,false);check(observe.observed<=.2 and observe.established==b,"idle expiry begins fresh observation without banking earlier edit time")
	observe.step(a,6.,1,false);check(observe.established==a,"post-edit stable interval establishes actual new era")
	for i in range(20):observe.step(b,1.,1,true)
	check(observe.established==a and observe.observed==0. and observe.reason()=="construction","continuous dragging cannot accrue observation")
	observe.step(b,12.,1,false)
	check(observe.established==a and observe.observed==0. and observe.reason()=="construction","cancelled drag starts idle from the first observed release")
	var seq:=Sequence.new();seq.owner=host;seq.enabled=true;host.spatial_facts={"era":a};seq.step(1_000_000)
	host.spatial_facts={"era":b};seq.step(1_350_000);seq.step(3_350_000)
	seq.pause_changed(false,3_350_000);host.paused=true
	var elapsed:float=seq.era_observation.elapsed;var seen:float=seq.era_observation.observed
	seq.step(23_350_000);check(elapsed==2.35 and seen==2. and seq.era_observation.elapsed==elapsed and seq.era_observation.observed==seen and seq.era_observation.established==a,"actual sequence uses wall time and pause freezes both observations")
	seq.pause_changed(true,43_350_000);host.paused=false
	seq.step(47_450_000);check(seq.era_observation.established==b and is_equal_approx(seq.era_observation.observed,6.1),"resume completes the remaining observation without crediting an unsampled paused interval")
	seq.finish(47_500_000);music.attention.dragging=true
	var end_usec:=seq.ended_usec
	seq.step(end_usec+1_200_000)
	check(is_equal_approx(seq.remaining,1.8),"short simulation delta still counts real active breath time")
	host.paused=true;seq.step(end_usec+6_200_000)
	check(is_equal_approx(seq.remaining,1.8) and is_equal_approx(seq.breath_clock,1.2),"paused wall time never counts toward breath")
	host.paused=false;seq.step(end_usec+8_200_000)
	check(seq.breathing and seq.worker==null and seq.remaining==0. and seq.wait_reason()=="construction","expired real timer still defers preparation while dragging")
	city.creative_settings.music.mode="fixed";seq.era_observation.last_edit=-INF;seq.era_observation.candidate=a
	check(seq.wait_reason().is_empty(),"explicit fixed repeat ignores camera-era observation")
	city.creative_settings.music.mode="auto";check(var_to_bytes(city.snapshot())==original,"scheduling does not change author data or brush")
	check(Fit.city_era(city,{"h1":.25,"h3":.75})==b,"indexed focus preserves weighted era winner")
	check(Fit.city_era(city,{"h3":.5,"h1":.5})==a,"mixed-era tie keeps existing era order rather than dictionary order")
	check(city.remove_house("h3").ok and Fit.city_era(city,{"h3":1.,"h1":.2})==a,"deleted cached focus source cannot vote for an era")
	check(city.undo().ok and Fit.city_era(city,{"h3":1.})==b,"Undo restores indexed source era")
	var delayed:=Observation.new();delayed.step(a,0.,0,false);delayed.step(b,0.,1,false);delayed.step(b,3.,1,false)
	check(delayed.observed==0. and delayed.established==a,"one long frame spanning idle gate cannot bank construction idle time")
	delayed.step(b,5.9,1,false);check(delayed.established==a,"post-idle long frame still requires full six-second observation")
	delayed.step(b,.11,1,false);check(delayed.established==b,"long-frame timing retains full idle plus observation interval")
	seq.close();host.free();music.free();var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ERA_OBSERVATION ",JSON.stringify(report));quit(0 if report.ok else 1)
