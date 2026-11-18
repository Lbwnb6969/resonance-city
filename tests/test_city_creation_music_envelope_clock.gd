extends SceneTree
const Clock=preload("res://scripts/audio/city_creation_music_envelope_clock.gd")
class City extends RefCounted:
	var _wish_epoch:=0
class Voice extends Node:
	var concert_active:=true
	var _concert_venue:="h1"
	var _concert_clock_origin:=0.
	var _pluck_city:RefCounted=City.new()
	var at:=0.
	func _playback_clock()->float:return at
var checks:=0
var failures:Array[String]=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func fade(voice:Voice,steps:int,elapsed:float)->float:
	Clock.step(voice,0.);var db:=-80.
	for i in range(1,steps+1):
		voice.at=elapsed*float(i)/steps
		db=lerpf(db,-18.,1.-exp(-Clock.step(voice,minf(elapsed/steps,.1))*2.8))
	return db
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(out)
	var fast:=Voice.new();var slow:=Voice.new()
	var a:=fade(fast,16,1.6);var b:=fade(slow,4,1.6)
	var analytic:=-18.+(-80.+18.)*exp(-2.8*1.6)
	check(is_equal_approx(a,analytic) and is_equal_approx(b,analytic),"fast and clamped slow frames reach the analytic audio-time exponential")
	var legacy:=-18.+(-80.+18.)*exp(-2.8*.4)
	check(b>-20. and legacy< -38.,"audio-time fade clears the real missed phrase while clamped simulation remains behind")
	check(is_zero_approx(Clock.step(slow,.1)),"stopped audio holds the envelope despite simulation ticks")
	slow.at=1.2;check(is_zero_approx(Clock.step(slow,.1)),"backwards seek cannot produce a negative fade interval")
	slow.at=1.4;check(is_equal_approx(Clock.step(slow,.1),.2),"the first forward sample after seek resumes from the new position")
	slow._concert_clock_origin=1.;slow.at=80.;check(is_equal_approx(Clock.step(slow,.1),.1),"resumed performance origin starts from its own envelope interval")
	slow.at=80.3;check(is_equal_approx(Clock.step(slow,.1),.3),"audio timing resumes after an origin reset")
	slow._concert_venue="h2";slow.at=90.;check(is_equal_approx(Clock.step(slow,.1),.1),"another venue does not inherit previous elapsed time")
	slow._pluck_city=City.new();slow.at=120.;check(is_equal_approx(Clock.step(slow,.1),.1),"different city with identical venue and origin starts independently")
	slow._pluck_city._wish_epoch+=1;slow.at=150.;check(is_equal_approx(Clock.step(slow,.1),.1),"restoring another work into the same State discards the previous timing sample")
	slow.concert_active=false;slow.at=200.;check(is_equal_approx(Clock.step(slow,.07),.07) and not slow.has_meta("concert_envelope_clock"),"ordinary creation retains delta timing and retires the concert sample")
	slow.concert_active=true;slow.at=240.;check(is_equal_approx(Clock.step(slow,.1),.1),"a later concert cannot consume the idle interval")
	var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"fast_db":a,"slow_db":b,"analytic_db":analytic,"old_clamped_db":legacy}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("ENVELOPE_CLOCK ",JSON.stringify(result))
	fast.free();slow.free();quit(0 if failures.is_empty() else 1)
