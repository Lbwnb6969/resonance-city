extends SceneTree
const Fixture=preload("res://tools/fixtures/city_creation_space_contract_fixture.gd")
const State=Fixture.State
const Ledger=preload("res://scripts/world/city_creation_progression_ledger.gd")
const Epoch=preload("res://scripts/world/city_creation_epoch_counters.gd")
var out:=""
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func network(city:RefCounted)->void:
	var n=load("res://scripts/world/city_creation_network.gd").new();n.state=city;n._build_graph();city.prepare_regional_echo(n)
func opened(label:String)->RefCounted:
	var city:=State.new();city.initialize_free();check(city.begin_progression_epoch(out+"/"+label+".json").ok,"backed-up empty epoch "+label);return city
func cells(shape:String)->Array:
	var f:=Fixture.courtyard(shape,"none");return f.city.houses[0].cells.map(func(c):return {"x":c.x,"z":c.z,"level":c.level,"kind":c.kind})
func paused_space_history()->void:
	var city:=opened("paused_space")
	check(city.CreationPolicy.set_progression_enabled(city,false,out+"/paused_space.json").ok,"disable actual account before courtyard construction")
	var life:=preload("res://scripts/world/city_creation_life.gd").new();root.add_child(life);life.set_process(false);life.setup(city,true)
	check(city.add_house_stroke(Fixture.ORIGIN,cells("U")).ok,"create real off-period half court")
	check(not city.get_meta("paused_counter_sources",[]).is_empty(),"live paused history retains immutable geometry before background preparation")
	check(life.begin_budget_sync(),"actual network worker accepts retained off-period inputs")
	var first_cell:Dictionary=city.houses[0].cells[0]
	check(city.add_cell(city.houses[0].id,int(first_cell.x),int(first_cell.z),1).ok and city.add_cell(city.houses[0].id,int(first_cell.x),int(first_cell.z),2).ok,"two rapid real edits supersede an in-flight paused worker")
	var expected:Dictionary=preload("res://scripts/world/city_creation_paused_counter_history.gd").flush(city)
	var deadline:=Time.get_ticks_msec()+30000
	while not life.poll_budget_sync(false) and Time.get_ticks_msec()<deadline:await process_frame
	check(life.commit_budget_sync() and city.get_meta("paused_counter_sources",[]).is_empty(),"validated publication merges exact counter union and retires only processed inputs")
	check(city.get_meta("paused_counter_baseline",{})==expected,"superseded worker retains the full independent union including intermediate cell peaks")
	var ready:Dictionary=Epoch.baseline(city)
	preload("res://scripts/world/city_creation_paused_counter_history.gd").history_snapshot(city)
	check(city.get_meta("paused_counter_sources",[]).is_empty() and ready.keys().all(func(k):return city.get_meta("paused_counter_baseline",{}).get(k,0)>=ready[k]),"exact published facts merge immediately without queuing another identical city")
	network(city)
	var keys:Array=Epoch.spaces(city).keys()
	check(not keys.is_empty(),"off-period courtyard has real geometric receipt keys")
	var policy:Dictionary=city.cozy_progression.duplicate(true);var frozen:Dictionary=city.snapshot()
	check(city.cozy_progression==policy and keys.all(func(k):return frozen.cozy_progression.baseline.get(k,0)==1),"read-only paused snapshot records all space high water without mutating account")
	check(city.remove_house(city.houses[0].id).ok and city.save_city(out+"/removed_paused_space.json").ok,"save after off-period courtyard has been removed")
	var reader:=State.new();check(reader.load_city(out+"/removed_paused_space.json").ok,"cold restore removed off-period geometry")
	check(keys.all(func(k):return reader.cozy_progression.baseline.get(k,0)==1),"cold paused baseline remembers removed off-period space keys")
	check(reader.CreationPolicy.set_progression_enabled(reader,true,out+"/resumed_removed_space.json").ok,"resume after cold read of removed courtyard")
	check(reader.add_house_stroke(Fixture.ORIGIN,cells("U")).ok,"recreate off-period court with fresh identities after resume")
	network(reader)
	check(Ledger.collect(reader).earned==0,"cold save and off-period deletion cannot repay the same house cell peaks or space discovery")
	var other:=State.new();other.initialize_free()
	check(city.restore(other.snapshot()).ok and not city.has_meta("paused_counter_baseline") and not city.has_meta("paused_counter_sources"),"explicit different-city restore clears retained accounting inputs and completed union")
	life.free()
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();await paused_space_history();var city:=opened("houses");var old:Dictionary=city.harmony_journey.duplicate(true)
	for i in range(5):check(city.add_house(Vector2(-35+i*5,-25)).ok,"actual peak house")
	check(Ledger.collect(city).earned==10,"five net houses pay original two point valuation")
	var xp:int=city.cozy_progression.xp
	for i in range(20):
		check(city.remove_house(city.houses[-1].id).ok and Ledger.collect(city).earned==0,"actual deletion never pays")
		check(city.add_house(Vector2(-15,-25)).ok and Ledger.collect(city).earned==0,"twenty fresh IDs at same net peak cannot farm")
	check(city.cozy_progression.xp==xp and city.cozy_progression.receipts.house_peak==5,"net peak high-water persists across twenty replacements")
	check(city.add_house(Vector2(-10,-25)).ok and Ledger.collect(city).earned==2,"sixth net house pays once")
	check(city.add_cell(city.houses[0].id,1,0,0).ok and Ledger.collect(city).earned==1,"additional authored module raises expansion peak")
	check(city.undo().ok and city.redo().ok and Ledger.collect(city).earned==0,"module Undo Redo cannot farm")
	check(city.harmony_journey==old,"epoch valuation never edits old cutoff or rights")
	var court:=opened("spaces");check(court.add_house_stroke(Fixture.ORIGIN,cells("U")).ok,"pure geometric half court")
	network(court);var earned:Dictionary=Ledger.collect(court)
	check(earned.events.get("space_cluster",0)>0 and not earned.events.has("space_district"),"half enclosure discovered without shops or residents")
	for x in range(1,4):check(court.add_cell("h1",x,4,0).ok,"close real courtyard edge")
	check(court.add_road([Fixture.ORIGIN+Vector2(-2,3.6),Fixture.ORIGIN+Vector2(10,3.6)] as Array[Vector2],"path","none").ok,"real public court portal")
	network(court);earned=Ledger.collect(court);check(earned.events.get("space_district",0)>0,"closed court geometry and portal publish district discovery")
	var paid:Dictionary=court.cozy_progression.duplicate(true);var space_keys:Array=Epoch.spaces(court).keys()
	check(court.remove_house("h1").ok,"remove actual court");Ledger.collect(court)
	check(court.add_house_stroke(Fixture.ORIGIN,cells("ring")).ok,"recreate court with fresh owner and cell IDs");network(court);earned=Ledger.collect(court)
	check(earned.earned==0 and court.cozy_progression==paid and Epoch.spaces(court).keys()==space_keys,"same-place geometric rediscovery does not repay on fresh IDs")
	check(court.save_city(out+"/paid.json").ok,"new counter keys serialize with existing schema")
	var cold:=State.new();check(cold.load_city(out+"/paid.json").ok and cold.cozy_progression==paid and Ledger.collect(cold).earned==0,"disk cold state retains paid peaks and discoveries")
	# A real existing account with pre-extension counters is a compatibility fixture.
	var raw:Dictionary=court.snapshot();raw.cozy_progression.baseline.erase("house_peak");raw.cozy_progression.baseline.erase("cell_peak")
	for field:String in ["baseline","receipts"]:
		for key:String in raw.cozy_progression[field].keys():
			if key in ["house_peak","cell_peak"] or key.begins_with("space_"):raw.cozy_progression[field].erase(key)
	var before_raw:Dictionary=raw.duplicate(true);var legacy_epoch:=State.new();check(legacy_epoch.restore(raw).ok,"old schema account restores")
	check(raw==before_raw and legacy_epoch.cozy_progression.baseline.has("house_peak") and Ledger.collect(legacy_epoch).earned==0,"old geometric content is baseline with no historical replay or input mutation")
	check(legacy_epoch.cozy_progression.xp==raw.cozy_progression.xp and legacy_epoch.cozy_progression.level==raw.cozy_progression.level,"old earned balance preserved")
	var old_path:=out+"/pre_extension_account.json";FileAccess.open(old_path,FileAccess.WRITE).store_string(JSON.stringify(raw,"\t"));var original_bytes:=FileAccess.get_file_as_bytes(old_path)
	var file_reader:=State.new();check(file_reader.load_city(old_path).ok and Ledger.collect(file_reader).earned==0,"normal old-account opening baselines existing geometry before new edits")
	check(FileAccess.get_file_as_bytes(old_path)==original_bytes and file_reader.harmony_journey==raw.harmony_journey,"old original bytes and cutoff rights remain intact during baseline opening")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("EPOCH_GEOMETRY ",JSON.stringify(report));quit(0 if report.ok else 1)
