extends SceneTree
const Fixture=preload("res://tools/fixtures/city_creation_space_contract_fixture.gd")
const State=Fixture.State
const Life=preload("res://scripts/world/city_creation_life.gd")
const History=preload("res://scripts/world/city_creation_paused_counter_history.gd")
const Result=preload("res://scripts/world/city_creation_paused_counter_result.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
class Builder extends RefCounted:
	var entered:=Semaphore.new()
	var release:=Semaphore.new()
	var calls:=0
	func compute()->Dictionary:
		calls+=1;entered.post();release.wait();return {"cell_peak":3,"space_cluster/courtyard_1_1":1}
func run()->void:
	var out:="";var baseline_path:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-history="):baseline_path=arg.trim_prefix("--baseline-history=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec()
	var city:=State.new();city.initialize_free()
	check(city.begin_progression_epoch(out+"/epoch.json").ok and city.CreationPolicy.set_progression_enabled(city,false,out+"/paused.json").ok,"create and actually pause backed-up account")
	var life:=Life.new();root.add_child(life);life.set_process(false);life.setup(city,true)
	var shape:Dictionary=Fixture.courtyard("U","none")
	var cells:Array=shape.city.houses[0].cells.map(func(c):return {"x":c.x,"z":c.z,"level":c.level,"kind":c.kind})
	check(city.add_house_stroke(Fixture.ORIGIN,cells).ok,"create real off-period courtyard history")
	var sources:=History.capture(city);var captured:=History.capture(city);var source:Dictionary=sources.back()
	check(is_same(source.result,captured.back().result) and not is_same(source.world,captured.back().world),"captures detach source data but share the immutable source result")
	var world:Dictionary=source.world.duplicate(true);var region:Dictionary=source.region.duplicate(true)
	var old=load(baseline_path) if not baseline_path.is_empty() else History
	var first:=Time.get_ticks_usec();var expected:Dictionary=old.derive(source);var baseline_ms:=(Time.get_ticks_usec()-first)/1000.;first=Time.get_ticks_usec()
	var actual:=History.derive(source);var cold_ms:=(Time.get_ticks_usec()-first)/1000.;first=Time.get_ticks_usec()
	var again:=History.derive(captured.back());var reused_ms:=(Time.get_ticks_usec()-first)/1000.
	check(actual==expected and again==expected,"all paused counters exactly match uncached history derivation across captures")
	again.cell_peak=999
	check(History.derive(source)==expected and source.world==world and source.region==region,"caller edits cannot corrupt cached counts or retained source")
	check(source.result.stats().computations==1,"one immutable source computes exactly once")
	var before_policy:Dictionary=city.cozy_progression.duplicate(true);var saved:Dictionary=city.snapshot();var second:Dictionary=city.snapshot()
	check(saved==second and city.cozy_progression==before_policy,"public paused snapshots stay complete and do not mutate the account")
	check(source.result.stats().computations==1 and source.result.stats().reuses>=3,"public save snapshots reuse completed exact history counts")
	check(city.add_cell("h1",0,0,1).ok,"new geometry adds an independent history source")
	var new_sources:=History.capture(city)
	check(not is_same(new_sources.back().result,source.result),"different geometry never shares a result by source number or revision")
	var expected_union:Dictionary={}
	for row:Dictionary in new_sources:History.merge(expected_union,old.derive(row))
	var network=load("res://scripts/world/city_creation_network.gd").new();network.state=State.new()
	History.prepare(network,new_sources);History.adopt(city,network)
	check(city.get_meta("paused_counter_sources",[]).is_empty() and city.get_meta("paused_counter_baseline",{})==expected_union,"worker result adoption preserves the entire historical counter union")
	var legacy_source:Dictionary=source.duplicate(true);legacy_source.erase("result")
	check(History.derive(legacy_source)==expected,"retained sources without a memo still derive exact counters")
	var builder:=Builder.new();var shared:=Result.new();var a:=Thread.new();var b:=Thread.new()
	a.start(shared.resolve.bind(builder.compute));var deadline:=Time.get_ticks_msec()+3000
	while not builder.entered.try_wait() and Time.get_ticks_msec()<deadline:await process_frame
	b.start(shared.resolve.bind(builder.compute));builder.release.post()
	var av:Dictionary=a.wait_to_finish();var bv:Dictionary=b.wait_to_finish()
	check(av==bv and builder.calls==1 and shared.stats()=={"computations":1,"reuses":1},"two real workers share one completed computation under the mutex")
	var other:=State.new();other.initialize_free();city.restore(other.snapshot())
	check(not city.has_meta("paused_counter_sources") and not city.has_meta("paused_counter_baseline"),"different-city restore releases the live history and result ownership")
	life.free()
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"baseline_ms":baseline_ms,"cold_ms":cold_ms,"reuse_ms":reused_ms,"seconds":(Time.get_ticks_usec()-began)/1000000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("PAUSED_COUNTER_RESULT ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
