extends SceneTree
## Minimal world-level proof for the first charter + variation-card slice.
## This verifies deterministic draws, queued persistence, bounded influence and expiry.

const World = preload("res://scripts/world/continuous_world.gd")
const Charter = preload("res://scripts/world/development_charter.gd")
const Card = preload("res://scripts/world/planning_card.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")

var failures: Array[String] = []
var checks := 0

func check(condition: bool,label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var world := World.new("0000000000000146",true,"river_valley")
	world.build_starter("bright")
	var same_a := Card.choices(world,"compact")
	var same_b := Card.choices(world,"compact")
	var other_world := World.new("0000000000000147",true,"river_valley")
	var other := Card.choices(other_world,"compact")
	check(same_a == same_b and same_a.size() >= 2 and same_a.size() <= 3,"same world draws a stable two or three-card hand")
	check(same_a.all(func(id: String) -> bool: return Card.valid(id)) and same_a[0] != same_a[1],"draw contains unique valid cards")
	check(same_a != other,"different seed can change the drawn hand")

	var scope: Array = [str(world.communities.keys()[0])]
	var frame := int(world.cfg["timing"]["phrase_frames"])
	var before := world.snapshot()
	check(not world.request({"kind":"charter","plan_id":"compact","community_ids":scope,"card_refs":["missing-card"]},frame)["accepted"],"invalid card cannot queue a charter")
	check(world.snapshot() == before,"invalid card leaves world and RNG untouched")
	var queued := world.request({"kind":"charter","plan_id":"compact","community_ids":scope,"card_refs":[same_a[0]]},frame)
	check(bool(queued["accepted"]),"charter with drawn card queues at phrase boundary")
	world.settle(frame)
	check(world.development_charters.size() == 1 and world.development_charters[0]["card_refs"] == [same_a[0]],"settled charter stores card reference")
	check(world.events.any(func(event: Dictionary) -> bool: return event.get("kind","") == "charter" and event.get("card_refs",[]) == [same_a[0]]),"charter event carries card reference")

	var charter: Dictionary = world.development_charters[0]
	var building: Dictionary = world.buildings[0]
	var point := Coupling.position_of(building)
	var active_bonus := Card.priority_bonus(world,charter,str(building["community_id"]),point,2)
	check(active_bonus > 0.0,"active card changes an existing planning relation score")
	var expired := charter.duplicate(true)
	expired["committed_phrase"] = world.phrase_index-20
	check(Card.priority_bonus(world,expired,str(building["community_id"]),point,2) == 0.0,"expired card stops affecting candidate priority")
	var restored := world.fork()
	restored.restore(world.snapshot())
	check(restored.development_charters == world.development_charters and restored.development_charters[0]["card_refs"] == [same_a[0]],"snapshot restore preserves card reference")
	check(Charter.growth_delay(world,str(building["community_id"]),point,2,"L2") >= 1,"card timing stays within a valid growth delay")

	print("ROUND146_PLANNING_CARDS checks=",checks," failures=",JSON.stringify(failures)," hand=",JSON.stringify(same_a))
	quit(0 if failures.is_empty() else 1)
