extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Life=preload("res://scripts/world/city_creation_life.gd")
const Network=preload("res://scripts/world/city_creation_network.gd")
const Spatial=preload("res://scripts/world/city_creation_spatial_prepared.gd")
const Geometry=preload("res://scripts/audio/city_creation_expression_geometry.gd")
const Lantern=preload("res://scripts/world/city_creation_water_lantern_plan.gd")
class CandidateOwner extends Node:
	var cancelled:=false
var checks:=0
var failures:Array=[]
var out:=""
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func direct(world:Dictionary)->Dictionary:
	var city:=State.new();check(city.restore(world).ok,"independent full source validates")
	var network:=Network.new();network.state=city;network._build_graph();city.prepare_regional_echo(network)
	return {"zones":city.functional_zones(),"streets":preload("res://scripts/world/city_creation_street_wonder_plan.gd").derive(city),"geometry":Geometry.prepare(city),"frozen_geometry":Geometry.prepare_snapshot(Geometry.capture(city)),"planning":city.synergy_buffs(),"clusters":city.natural_clusters(),"lamps":Lantern.derive(city)}
func worker_ready(life:Node3D)->bool:
	var until:=Time.get_ticks_msec()+120000
	while not life.poll_budget_sync(false) and Time.get_ticks_msec()<until:await process_frame
	return life._budget_ready_network!=null
func run()->void:
	var source:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--fixture="):source=arg.trim_prefix("--fixture=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec();var city:=State.new()
	if source.is_empty():
		city.initialize_free();city.add_house(Vector2(-25,-20));city.add_house(Vector2(-25,-16));city.add_road([Vector2(-29,-18),Vector2(-21,-18)] as Array[Vector2],"path","none")
	else:check(city.restore(JSON.parse_string(FileAccess.get_file_as_string(source))).ok,"provided actual authored city restores")
	var candidate:=CandidateOwner.new();root.add_child(candidate);city.set_meta("game_expression_owner",weakref(candidate))
	var source_houses:Array=city.houses.duplicate(true);var source_roads:Array=city.roads.duplicate(true);var source_cozy:Dictionary=city.cozy_progression.duplicate(true)
	var life:=Life.new();root.add_child(life);life.set_process(false);life.setup(city,true);life.set_budget_hold(true)
	check(life.begin_budget_sync() and life._budget_thread!=null,"real existing network worker starts")
	check(await worker_ready(life),"worker joins with ready spatial consumer data")
	var prepared:Dictionary=life._budget_ready_network.state.functional_zones();var expected:=direct(city.snapshot())
	check(var_to_bytes(prepared)==var_to_bytes(expected.zones),"isolated partial routing snapshot produces exact full-city spatial facts")
	check(var_to_bytes(life._budget_ready_network.state.synergy_buffs())==var_to_bytes(expected.planning),"worker planning bonuses equal independent full-city evaluation")
	check(var_to_bytes(life._budget_ready_network.state.get_meta("prepared_water_lanterns",{}).get("rows",[]))==var_to_bytes(expected.lamps),"worker lamps equal independently derived full-city volumes")
	check(var_to_bytes(expected.geometry)==var_to_bytes(expected.frozen_geometry),"initial bundle-worker frozen input gives exact full-city expression records")
	check(var_to_bytes(life._budget_ready_network.state.get_meta("expression_geometry_prepared",{}))==var_to_bytes(expected.geometry),"active expression consumer prepares exact records on routing worker")
	check(life.commit_budget_sync(),"already validated generation actually publishes")
	check(city.get_meta("functional_zones",{}).get("key",[])==[city.revision,city.revision],"current actual network revision owns adopted facts")
	check(var_to_bytes(city.functional_zones())==var_to_bytes(expected.zones),"main view reads identical worker facts")
	check(city._synergy_revision==city.revision and var_to_bytes(city.synergy_buffs())==var_to_bytes(expected.planning),"publication adopts exact ready planning before first cafe read")
	check(var_to_bytes(city.natural_clusters())==var_to_bytes(expected.clusters),"adopted natural membership equals independent full derivation")
	check(city.has_meta("prepared_water_lanterns") and is_same(Lantern.derive(city),city.get_meta("prepared_water_lanterns").rows) and var_to_bytes(Lantern.derive(city))==var_to_bytes(expected.lamps),"published city reads exact worker lamp array without main-thread derivation")
	check(var_to_bytes(city.get_meta("street_wonder_plan"))==var_to_bytes(expected.streets),"adopted complete street scenery and source key equal independent full city")
	check(city.houses==source_houses and city.roads==source_roads and city.cozy_progression==source_cozy,"spatial preparation alters no author records or account")
	check(not Spatial.needed(city),"published geometry has no missing spatial consumer")
	var model=Geometry.new();model.refresh(city);check(model.records.is_empty(),"held unpublished geometry cannot update the audible model")
	life.set_budget_hold(false);model.refresh(city);check(var_to_bytes(model.records)==var_to_bytes(expected.geometry.records),"published player reads prepared model without rebuilding")
	var h:Dictionary=city.houses[-1];var top:=0
	for cell:Dictionary in h.cells:top=maxi(top,int(cell.level))
	check(city.add_cell(str(h.id),0,0,top+1).ok,"actual same-footprint upper room edit")
	check(life._signature()==life._network_signature,"this real edit reuses walking graph identity")
	life.set_budget_hold(true)
	check(Spatial.needed(city) and life.begin_budget_sync(),"changed spatial consumer still schedules worker for equal walk graph")
	check(await worker_ready(life),"second actual geometry worker finishes")
	var changed:=direct(city.snapshot());check(life.commit_budget_sync() and var_to_bytes(city.functional_zones())==var_to_bytes(changed.zones),"new room publishes exact changed spatial facts without first-view derivation")
	check(var_to_bytes(city.get_meta("street_wonder_plan"))==var_to_bytes(changed.streets),"changed-room scenery cache also equals independently derived source geometry")
	check(var_to_bytes(city.get_meta("expression_geometry_prepared",{}))==var_to_bytes(changed.geometry),"changed-room music records exactly match independent geometry")
	check(city._synergy_revision==city.revision and var_to_bytes(city.synergy_buffs())==var_to_bytes(changed.planning),"same-footprint edit publishes current planning bonuses")
	var published:Dictionary=city.get_meta("functional_zones");var synchronous:=Network.new();synchronous.state=city;synchronous._build_graph();Spatial.adopt(city,synchronous)
	check(is_same(published,city.get_meta("functional_zones")),"ordinary synchronous graph cannot relabel a stale or unprepared cache")
	check(city.add_road([Vector2(-38,34),Vector2(-30,34)] as Array[Vector2],"path","none").ok and life.begin_budget_sync(),"real new street starts a third existing worker")
	var other:=State.new();other.initialize_free();life.setup(other);life.set_budget_hold(false)
	while life._budget_thread!=null and life._budget_thread.is_alive():await process_frame
	life.poll_budget_sync(false);var other_facts:Dictionary=other.functional_zones();var other_streets:Dictionary=preload("res://scripts/world/city_creation_street_wonder_plan.gd").derive(other)
	check(life.state==other and other.houses.is_empty() and other_facts.houses.is_empty() and other_facts.spaces.is_empty() and other_streets.piers.is_empty() and other_streets.pockets.is_empty(),"cancelled old worker cannot publish either old-city cache into the initialized new city")
	life.free()
	var old:=State.new();old.initialize_empty();var old_life:=Life.new();root.add_child(old_life);old_life.set_process(false);old_life.setup(old)
	check(not old_life.begin_budget_sync() and not Spatial.needed(old),"unchanged legacy graph retains original fast path");old_life.free();candidate.queue_free()
	await linked_planning()
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"houses":city.houses.size(),"spaces":expected.zones.spaces.size(),"seconds":(Time.get_ticks_usec()-began)/1000000.,"source":source}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SPATIAL_PREPARED ",JSON.stringify(report));quit(0 if report.ok else 1)

func linked_planning()->void:
	var city:=State.new();city.initialize_free()
	check(city.add_house(Vector2(-25,-20)).ok and city.add_house(Vector2(-25,-6)).ok,"linked planning uses two actual houses")
	var a:Dictionary=city.add_district([Vector2(-25,-20)] as Array[Vector2],4.,"warm")
	var b:Dictionary=city.add_district([Vector2(-25,-6)] as Array[Vector2],4.,"deep")
	check(a.ok and b.ok and city.link_districts(a.district_id,b.district_id).ok,"actual distinct painted districts are linked")
	var life:=Life.new();root.add_child(life);life.set_process(false);life.setup(city,true);life.set_budget_hold(true)
	check(life.begin_budget_sync() and await worker_ready(life),"linked planning worker finishes")
	var expected:=direct(city.snapshot())
	check(expected.planning.connected_identities==2 and var_to_bytes(life._budget_ready_network.state.synergy_buffs())==var_to_bytes(expected.planning),"worker retains real musical links and two distinct identities")
	check(life.commit_budget_sync() and city._synergy_buffs==expected.planning,"linked planning publishes intact")
	check(city.add_cell(str(city.houses[0].id),0,0,1).ok and life.begin_budget_sync() and await worker_ready(life),"prepare a new linked generation before changing its source")
	city.musical_links.clear()
	check(not life.commit_budget_sync() and life.budget_sync_pending(),"same-revision link change rejects completed obsolete generation and schedules replacement")
	expected=direct(city.snapshot())
	check(await worker_ready(life) and life.commit_budget_sync() and city._synergy_buffs==expected.planning and expected.planning.connected_identities==1,"replacement publishes exact unlinked planning")
	check(city.add_cell(str(city.houses[0].id),0,0,2).ok and life.begin_budget_sync() and await worker_ready(life),"prepare free planning before a same-revision policy change")
	city.synergy_buffs();check(city._synergy_revision==city.revision,"old free planning is current before changing policy")
	city.creative_settings.creation_policy="legacy"
	check(not life.commit_budget_sync() and life.budget_sync_pending(),"changed policy rejects ready free planning and actually schedules replacement")
	check(await worker_ready(life) and life.commit_budget_sync() and not life._network.state.CreationPolicy.is_free(life._network.state) and city._synergy_revision!=city.revision,"legacy replacement cannot adopt old free planning as current")
	life.free()
