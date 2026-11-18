extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Network=preload("res://scripts/world/city_creation_network.gd")
const Life=preload("res://scripts/world/city_creation_life.gd")
const Ticket=preload("res://scripts/world/city_creation_preparation_ticket.gd")

class GateTicket extends Ticket:
	var entered:=Semaphore.new()
	var release:=Semaphore.new()
	var calls:=0
	func cancelled()->bool:
		calls+=1
		if calls==3:entered.post();release.wait()
		return super.cancelled()

class GatedLife extends Life:
	var gate:=GateTicket.new()
	var trap_next:=true
	func _start_budget_worker()->void:
		if trap_next:
			trap_next=false;_budget_ticket=gate;_budget_request.snapshot.preparation_ticket=gate
		super._start_budget_worker()

var checks:=0
var failures:Array=[]
func _initialize()->void:
	create_timer(25.).timeout.connect(func()->void:push_error("preparation cancellation probe timed out");quit(1))
	run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func city()->RefCounted:
	var value:=State.new();value.initialize_free()
	value.add_house(Vector2(-25,-20));value.add_house(Vector2(-21,-20))
	value.add_road([Vector2(-28,-17.5),Vector2(-10,-17.5)] as Array[Vector2],"path","none")
	return value
func captured(value:RefCounted)->Dictionary:
	return {"houses":value.houses.duplicate(true),"roads":value.roads.duplicate(true),"waters":value.waters.duplicate(true),"districts":value.districts.duplicate(true),"terrain_strokes":value.terrain_strokes.duplicate(true),"creative_settings":value.creative_settings.duplicate(true),"terrain_policy":value.terrain_policy}
func facts(network:RefCounted)->Dictionary:
	var result:Dictionary={}
	for key:String in ["graph","positions","road_edges","connected_houses","selected_entrances","component_of","prepared_positions","prepared_home_stops","prepared_exterior","prepared_street_heights","_service_routes","_service_lengths"]:result[key]=network.get(key)
	result.zones=network.state.functional_zones()
	return result
func entered(gate:GateTicket)->bool:
	var deadline:=Time.get_ticks_msec()+5000
	while Time.get_ticks_msec()<deadline:
		if gate.entered.try_wait():return true
		await process_frame
	return false
func run()->void:
	if not "--isolated-session" in OS.get_cmdline_user_args():quit(1);return
	var began:=Time.get_ticks_usec();var value:=city();var source:=captured(value);var before:Dictionary=value.snapshot();var actors:Array[Dictionary]=[]
	var baseline_path:="res://scripts/world/city_creation_network.gd";var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--baseline-network="):baseline_path=arg.trim_prefix("--baseline-network=")
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	var baseline=load(baseline_path).new()
	baseline.prepare(source.duplicate(true),{},actors)
	var current:=Network.new();var live_ticket:=Ticket.new();var active:=source.duplicate(true);active.preparation_ticket=live_ticket
	var worker:=Thread.new();worker.start(current.prepare.bind(active,{},actors));worker.wait_to_finish()
	check(facts(baseline)==facts(current),"uncancelled threaded and baseline preparation retain exact graph, routes, spatial facts and connection identity")
	check(value.snapshot()==before,"worker preparation leaves source city and author history untouched")
	var cancelled:=Ticket.new();cancelled.cancel();active=source.duplicate(true);active.preparation_ticket=cancelled
	var stopped:=Network.new();worker=Thread.new();worker.start(stopped.prepare.bind(active,{},actors));worker.wait_to_finish()
	check(stopped.prepare_stats.get("cancelled",false) and stopped.state==null,"cancelled queued snapshot stops before constructing a private State")
	var gate:=GateTicket.new();active=source.duplicate(true);active.preparation_ticket=gate
	stopped=Network.new();worker=Thread.new();worker.start(stopped.prepare.bind(active,{},actors))
	var reached:bool=await entered(gate);gate.cancel();gate.release.post();worker.wait_to_finish()
	check(reached and stopped.prepare_stats.has("graph_ms") and stopped.prepare_stats.get("cancelled",false) and not stopped.prepare_stats.has("cafe_seats_ms"),"in-flight real worker stops at next phase after graph preparation")
	var life:=GatedLife.new();root.add_child(life);life.set_process(false);life.setup(value);life.set_budget_hold(true)
	var published_id:=life._network.get_instance_id();value.add_house(Vector2(-17,-20));life.begin_budget_sync()
	reached=await entered(life.gate)
	value.add_house(Vector2(-13,-20));life.begin_budget_sync()
	check(reached and life._network.get_instance_id()==published_id,"replacement keeps the old published network while its private predecessor is held")
	life.gate.release.post();var deadline:=Time.get_ticks_msec()+10000
	while life.budget_sync_pending() and Time.get_ticks_msec()<deadline:life.poll_budget_sync();await process_frame
	check(not life.budget_sync_pending() and life.last_revision==value.revision and life._network.state.houses==value.houses and life.budget_cancelled_jobs==1,"only latest full request publishes after cancelling the superseded generation")
	check(not life._network.prepare_stats.get("cancelled",false) and life._network.prepare_stats.has("total_ms"),"cancelled partial network is never adopted as latest complete state")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cancelled_jobs":life.budget_cancelled_jobs,"seconds":(Time.get_ticks_usec()-began)/1000000.}
	if out.begins_with("res://验证记录/"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));FileAccess.open(out+"/cpu.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("PREPARATION_CANCEL_CPU ",JSON.stringify(report));life.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
