extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Context=preload("res://scripts/visual/city_creation_road_height_context.gd")
const BoatFixture=preload("res://tests/test_city_creation_boathouse.gd")
const DeckFixture=preload("res://tests/test_city_creation_tea_deck.gd")
const Ring=preload("res://scripts/world/city_creation_roundabout_width.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func compare(city:RefCounted,points:Array[Vector2],label:String)->void:
	var before:Dictionary=city.snapshot();var cold:=State.new();check(cold.restore(before).ok,"independent current-schema restore "+label)
	var context:=Context.new(cold);var same:=true
	for at:Vector2 in points:same=same and city.street_height(at)==context.height_at(at)
	check(same,"exact public scalar/batch heights "+label)
	check(city.snapshot()==before and cold.snapshot()==before,"read-only original and cold city "+label)
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	var open:=State.new();open.initialize_free();compare(open,[Vector2(-28,-20),Vector2(3,0),Vector2(12,10),Vector2.ZERO],"offroad and water fallback")
	var boat:RefCounted=BoatFixture.fixture();var boats:=Context.Boats.all(boat);check(not boats.is_empty(),"real boathouse plan exists")
	if not boats.is_empty():
		var points:Array[Vector2]=[Vector2(-28,-20),Vector2(-35,-24)]
		for floor:Rect2 in boats[0].floors:points.append(Context.Boats.at(boats[0],floor.get_center()))
		compare(boat,points,"boathouse precedence")
	var deck:RefCounted=DeckFixture.fixture();var decks:=Context.Decks.all(deck);check(not decks.is_empty(),"real tea deck plan exists")
	if not decks.is_empty():
		var points:Array[Vector2]=[Vector2(-28,-20),Vector2(-34,-23)]
		for floor:Rect2 in decks[0].floors:points.append(Context.Decks.at(decks[0],floor.get_center()))
		compare(deck,points,"tea deck precedence")
	var ring:=State.new();ring.initialize_free();var center:=Vector2(-20,12)
	check(ring.add_road([center-Vector2(8,0),center+Vector2(8,0)] as Array[Vector2],"path","none").ok and ring.add_road([center-Vector2(0,8),center+Vector2(0,8)] as Array[Vector2],"path","none").ok and Ring.add(ring,center,3.8).ok,"real wide roundabout fixture")
	compare(ring,[center,center+Vector2(3.7,0),center+Vector2(4,0),center+Vector2(7,0),center+Vector2(10,10)],"roundabout road and offroad boundary")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_HEIGHT_CONTEXT ",JSON.stringify(report));quit(0 if report.ok else 1)
