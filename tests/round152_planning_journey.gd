extends SceneTree
## Round 152 end-to-end planning journey. This keeps the playable contract
## together: charter + card -> community scope -> public anchor -> growth and
## audio difference -> save/restore. It does not claim human listening quality.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const PlanningCard = preload("res://scripts/world/planning_card.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func public_candidate(world: World, cid: String) -> Dictionary:
	for lot in world.lots:
		if not str(lot.get("occupant", "")).is_empty(): continue
		if str(lot.get("community_id", "")) != cid: continue
		var p := Vector2(float(lot["center"][0]), float(lot["center"][1]))
		var candidate := world.planning_candidate(p)
		if candidate.is_empty() or not bool(candidate.get("allowed", false)): continue
		if candidate.has("public_id"): continue
		if not Planning.public_access(world, candidate).is_empty(): return candidate
	return {}

func render(model: Model, seconds: int = 3) -> PackedVector2Array:
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	var state: Dictionary = {}
	var output := PackedVector2Array()
	var total := rate*seconds
	for offset in range(0, total, 1024):
		var block := model.render_block(state, offset, mini(1024, total-offset), rate)
		output.append_array(block)
	return output

func max_difference(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var difference := 0.0
	for i in range(mini(a.size(), b.size())):
		difference = maxf(difference, maxf(absf(a[i].x-b[i].x), absf(a[i].y-b[i].y)))
	return difference

func _run() -> void:
	var base := World.new()
	base.build_starter("bright")
	var cid := str(base.buildings[0]["community_id"])
	var candidate := public_candidate(base, cid)
	check(not candidate.is_empty(), "journey finds a real road-accessible parcel")
	if candidate.is_empty():
		quit(1)
		return
	var card_ids := PlanningCard.choices(base, "compact")
	check(card_ids.size() >= 2, "charter draws a reproducible hand")
	var card_id := str(card_ids[0])
	var boundary := int(base.cfg["timing"]["phrase_frames"])
	var city := base.fork()
	var model := Model.new(city)
	check(model.submit({"kind":"charter", "plan_id":"compact", "community_ids":[cid], "card_refs":[card_id]})["accepted"], "charter and chosen card queue together")
	check(model.submit({"kind":"park", "position":candidate["position"]})["accepted"], "public anchor queues at selected position")
	check(city.development_charters.is_empty() and city.public_sites.all(func(site: Dictionary) -> bool: return not bool(site.get("active", false)) or str(site.get("id", "")) != "planning"), "queued planning does not mutate city early")
	city.settle(boundary)
	var anchor: Dictionary = city.public_at(Vector2(float(candidate["position"][0]), float(candidate["position"][1])))
	check(city.development_charters.size() == 1, "charter commits at the phrase boundary")
	check(not anchor.is_empty() and str(anchor.get("kind", "")) == "park" and bool(anchor.get("active", false)), "selected park becomes a real active anchor")
	check(anchor.get("polygon", PackedVector2Array()) == candidate["polygon"], "anchor preserves the selected footprint")
	check(city.buildings.size() > base.buildings.size(), "ordinary growth continues after player planning")
	check(city.buildings.all(func(building: Dictionary) -> bool: return not Planning.disc_hits(candidate["polygon"], Vector2(float(building["position"][0]), float(building["position"][1])), float(building["radius"]))), "growth respects the public footprint")
	var saved: Dictionary = city.snapshot()
	var restored := World.new()
	restored.restore(saved)
	check(restored.development_charters == city.development_charters, "save and restore keeps charter and card identity")
	var restored_anchor := restored.public_at(Vector2(float(candidate["position"][0]), float(candidate["position"][1])))
	check(restored_anchor.get("polygon", PackedVector2Array()) == anchor["polygon"] and restored_anchor.get("kind", "") == "park", "save and restore keeps anchor geometry and use")
	var bare := base.fork()
	bare.settle(boundary)
	var planned_audio := render(model)
	var bare_audio := render(Model.new(bare))
	check(planned_audio.size() == bare_audio.size() and planned_audio.size() > 0, "journey renders a comparable short score")
	check(max_difference(planned_audio, bare_audio) > 0.0001, "public planning changes the rendered score")
	var scene: PackedScene = load("res://scenes/continuous_valley.tscn")
	var demo = scene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	check(str(demo._planning_status_hint()).begins_with("P规划"), "fresh Demo keeps the planning entry visible")
	var ui_cid := str(demo.model.world.buildings[0]["community_id"])
	var ui_cards := PlanningCard.choices(demo.model.world, "compact")
	check(demo.model.submit({"kind":"charter", "plan_id":"compact", "community_ids":[ui_cid], "card_refs":[str(ui_cards[0])]})["accepted"], "UI status fixture queues a charter")
	check(str(demo._planning_status_hint()).begins_with("待播规划"), "queued planning is visible after the panel closes")
	demo.queue_free()
	await process_frame
	await process_frame
	var failures: Array[String] = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print("ROUND152_PLANNING_JOURNEY checks=%d failures=%s" % [checks.size(), failures])
	quit(0 if failures.is_empty() else 1)
