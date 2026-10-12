extends SceneTree
## The visual family sentence uses only the heard birth and an older family house.
const Trail = preload("res://scripts/visual/authored_growth_trail.gd")
const OUTPUT := "res://验证记录/round200_作者生长轨迹/contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class WorldStub extends RefCounted:
	var by_id: Dictionary = {}
	var communities: Dictionary = {}
	var families: Dictionary = {}
	var buildings: Array = []
	var events: Array[Dictionary] = []

class TransportStub extends RefCounted:
	var audible_frame := 0.0
	var sample_rate := 100

class RendererStub extends RefCounted:
	var transport := TransportStub.new()

class ClockStub extends RefCounted:
	var renderer := RendererStub.new()

class PlanningStub extends RefCounted:
	var opened := false

class DemoStub extends Control:
	var model := RefCounted.new()
	var first_composition_mode := true
	var black := false
	var preview_started := false
	var clock := ClockStub.new()
	var planning_guide := PlanningStub.new()
	var menu := Control.new()
	var shown_world := WorldStub.new()
	func point(at: Vector2) -> Vector2: return at*10.0

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label); push_error(label)

func _house(id: String,family: String,at: Array,birth: int,authored := true) -> Dictionary:
	return {"district_id":id,"family_id":family,"position":at,"birth_frame":birth,
		"player_expression":authored,"expression":"warm" if authored else "bright","current_midi":48,"type":"residential"}

func _add(world: WorldStub,house: Dictionary) -> void:
	world.buildings.append(house)
	world.by_id[str(house["district_id"])] = house
	world.events.append({"kind":"birth","district_id":house["district_id"],"frame":house["birth_frame"]})

func _run() -> void:
	var demo := DemoStub.new()
	root.add_child(demo)
	demo.add_child(demo.menu)
	demo.menu.hide()
	var trail := Trail.new()
	demo.add_child(trail)
	var world := demo.shown_world
	world.families["author"] = {"root":"root","expression":"warm","player_expression":true}
	world.families["normal"] = {"root":"ordinary","expression":"bright"}
	_add(world,_house("root","author",[1.0,2.0],100))
	_add(world,_house("child","author",[2.0,2.0],500))
	_add(world,_house("ordinary","normal",[2.1,2.0],500,false))
	# A render-ahead model may already carry this building and event, but the
	# sound device has not reached its birth boundary.
	demo.clock.renderer.transport.audible_frame = 499
	trail.sync(demo)
	check(trail.trails.is_empty(),"future_birth_and_root_without_predecessor_have_no_trail")
	var before := {"buildings":world.buildings.duplicate(true),"families":world.families.duplicate(true),"events":world.events.duplicate(true)}
	demo.clock.renderer.transport.audible_frame = 500
	trail.sync(demo)
	check(trail.trails.size() == 1 and trail.trails[0]["id"] == "child" and trail.trails[0]["from_id"] == "root","actual_child_links_only_its_older_authored_family_house")
	check(trail.trails[0]["label"] == "你的暖庭 · 第2栋" and trail.trails[0]["from"] == Vector2(1,2) and trail.trails[0]["to"] == Vector2(2,2),"label_and_positions_come_from_real_family_birth")
	check(world.buildings == before["buildings"] and world.families == before["families"] and world.events == before["events"],"trail_does_not_mutate_world")
	trail.sync(demo)
	check(trail.trails.size() == 1,"the_same_event_is_not_added_twice")
	var restored_recent := Trail.new()
	demo.add_child(restored_recent)
	restored_recent.sync(demo)
	check(restored_recent.trails.is_empty(),"restoring_immediately_after_birth_does_not_replay_it")
	demo.menu.show()
	trail.sync(demo)
	check(not trail.visible,"root_menu_has_priority_over_growth_mark")
	demo.menu.hide()
	demo.planning_guide.opened = true
	trail.sync(demo)
	check(not trail.visible,"planning_panel_has_priority_over_growth_mark")
	demo.planning_guide.opened = false
	demo.preview_started = true
	trail.sync(demo)
	check(not trail.visible,"audition_has_priority_over_real_growth_mark")
	demo.preview_started = false
	demo.clock.renderer.transport.audible_frame = 800
	trail.sync(demo)
	check(trail.trails.is_empty(),"expired_mark_is_not_replayed_after_panel_or_audition")
	# Instantiating another layer for a restored city must not flash its history.
	var restored := Trail.new()
	demo.add_child(restored)
	restored.sync(demo)
	check(restored.trails.is_empty(),"restored_history_has_no_one_frame_growth_flash")
	_add(world,_house("later","author",[3.0,2.0],900))
	demo.clock.renderer.transport.audible_frame = 901
	trail.sync(demo)
	check(trail.trails.size() == 1 and trail.trails[0]["from_id"] == "child" and trail.trails[0]["label"].contains("第3栋"),"next_child_uses_nearest_previously_heard_member")
	demo.model = RefCounted.new()
	demo.shown_world = WorldStub.new()
	trail.sync(demo)
	check(trail.trails.is_empty(),"switching_city_clears_previous_visual_family")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Dummy read-only family growth trail over supplied heard World identities; no audio, screenshot, or human preference claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND200_AUTHORED_GROWTH_TRAIL ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
