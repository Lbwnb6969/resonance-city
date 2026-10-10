extends SceneTree
## UI smoke for the player path: charter -> drawn card -> community scope.

const Coupling = preload("res://scripts/world/world_coupling.gd")
var failures: Array[String] = []
var checks := 0

func check(condition: bool,label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene: PackedScene = load("res://scenes/continuous_valley.tscn")
	var demo: ContinuousValleyDemo = scene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var guide = demo.planning_guide
	check(guide.cards.get_child_count() == 3,"planning tool still presents three fixed charter plans")
	guide.open_tool()
	guide.choose_plan("compact")
	check(guide.stage == "card" and guide.drawn_card_ids.size() >= 2,"choosing a plan opens a two-or-three-card draw")
	check(guide.card_choices.get_child_count() == guide.drawn_card_ids.size(),"drawn card buttons match the current hand")
	guide.choose_card(guide.drawn_card_ids[0])
	check(guide.stage == "scope" and guide.card_id == guide.drawn_card_ids[0],"card selection advances to community scope")
	var point := Coupling.position_of(demo.model.world.buildings[0])
	guide.map_click(point,false)
	check(guide.scope.size() == 1,"map click selects a real community after card selection")
	guide.commit_scope()
	var queued: Dictionary = demo.model.world.pending_actions.back() if not demo.model.world.pending_actions.is_empty() else {}
	check(guide.stage == "anchor" and queued.get("kind","") == "charter" and queued.get("card_refs",[]) == [guide.card_id],"committed planning carries the selected card")
	print("ROUND146_PLANNING_CARDS_UI checks=",checks," failures=",JSON.stringify(failures))
	demo.queue_free()
	quit(0 if failures.is_empty() else 1)
