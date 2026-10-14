extends SceneTree

const State := preload("res://scripts/world/city_creation_state.gd")
var failures: Array[String] = []


func _initialize() -> void:
	var city := State.new()
	city.initialize()
	var initial := city.snapshot()
	_check(city.houses.size() == 6, "six initial houses")
	_check(city.houses[0].cells[0].source == "seed" and city.roads[0].source == "seed", "initial content carries seed origin")
	var initial_load := State.new()
	_check(initial_load.restore(initial).ok and initial_load.roads.size() == 6, "initial six houses and five branches satisfy geometry rules")
	_check(city.validate_add_cell("h1", 2, 0, 0, "room").ok and city.validate_add_cell("h3", 2, 0, 0, "room").ok, "initial shared houses leave expansion space")
	for ignored in range(100):
		city.snapshot()
	_check(city.snapshot() == initial, "no autonomous growth or random consumption")
	_check(city.validate_add_cell("h1", 0, 0, 1, "room").ok, "valid cell preview")
	_check(city.validate_add_house(Vector2(-15.0, 6.0)).ok and city.snapshot() == initial, "previews consume no IDs or state")
	_check(not city.validate_add_house(Vector2(3.0, 0.0)).ok, "water placement rejected")
	var result := city.add_cell("h1", 0, 0, 1, "room")
	_check(result.ok and city.dirty and city.revision == 1, "edit commits immediately")
	var expanded := city.snapshot()
	_check(city.houses[0].cells[-1].source == "player", "expanded cells carry player origin")
	_check(not city.add_cell("h1", 0, 0, 3, "room").ok, "unsupported upper floor rejected")
	_check(city.snapshot() == expanded, "failed edit is atomic")
	_check(city.undo().ok and city.dirty, "undo marks save dirty")
	_check(_geometry(city.snapshot()) == _geometry(initial), "undo restores geometry and stable identity")
	_check(city.redo().ok, "redo available")
	_check(_geometry(city.snapshot()) == _geometry(expanded), "redo restores seeds and identity")
	var roof_id: String = result.cell_id
	_check(city.add_cell("h1", 0, 0, 2, "room").ok, "supported second floor")
	var tower := city.snapshot()
	result = city.remove_cell("h1", roof_id)
	_check(result.ok and result.removed_count == 2, "support removal cascades in one transaction")
	city.undo()
	_check(_geometry(city.snapshot()) == _geometry(tower), "one undo restores entire cascade")
	_check(not city.remove_cell("h6", city.houses[5].cells[0].id).ok, "last module retained")
	_check(not city.add_cell("h6", 3, 0, 0, "room").ok, "disconnected foundation rejected")
	_check(city.add_house(Vector2(-15.0, 6.0)).ok, "independent new house")
	var new_id: String = city.houses[-1].id
	_check(new_id != "h6", "new house receives new identity")
	_check(city.houses[-1].cells[0].source == "new_house", "new-house origin remains distinct")
	var before_role := city.snapshot()
	_check(city.set_house_role(new_id, "bakery").ok and city.houses[-1].role == "bakery", "function change immediate")
	city.undo()
	_check(_geometry(city.snapshot()) == _geometry(before_role), "role change unified undo")
	city.redo()
	_check(city.set_house_name(new_id, "河岸面包房").ok, "name change immediate")
	_check(not city.set_house_role(new_id, "unknown").ok, "unknown function rejected")
	_check(city.add_road([Vector2(-15.0, 4.0), Vector2(-12.1, 4.5), Vector2(-11.0, 5.0)]).ok, "continuous road transaction")
	_check(city.roads[-1].source == "player", "roads carry player origin")
	_check(not city.add_road([Vector2(-8.0, -10.0), Vector2(-8.0, -4.0)]).ok, "road through walls rejected")
	_check(not city.add_road([Vector2(3.0, -10.0), Vector2(3.0, -8.0)]).ok, "road along river rejected")
	_check(not city.add_road([Vector2(-1.0, -10.0), Vector2(3.0, -10.0)]).ok, "partial bridge rejected")
	_check(city.add_road([Vector2(-1.0, -10.0), Vector2(8.0, -10.0)]).ok and city.roads[-1].bridge, "complete crossing becomes bridge")
	_check(city.add_road([Vector2(-8.0, -10.0), Vector2(-8.0, -6.9)]).ok, "road terminal may reach exterior doorway")
	var path := "user://city_creation_contract_%d.json" % Time.get_ticks_usec()
	var saved := city.snapshot()
	_check(city.save_city(path).ok and not city.dirty, "atomic save verified")
	var loaded := State.new()
	_check(loaded.load_city(path).ok, "save can load")
	_check(_geometry(loaded.snapshot()) == _geometry(saved), "save restores geometry IDs seeds and counters")
	_check(city.save_city(path).ok, "repeat save retains previous valid save in abandoned directory")
	var legacy := saved.duplicate(true)
	legacy.erase("high_watermark")
	for house in legacy.houses:
		house.erase("name")
		house.erase("role")
		for cell in house.cells:
			cell.erase("source")
	for road in legacy.roads:
		road.erase("source")
	var legacy_city := State.new()
	_check(legacy_city.restore(legacy).ok and legacy_city.houses[0].role == "residential" and not legacy_city.houses[0].name.is_empty(), "early schema defaults names and roles")
	_check(legacy_city.houses[-1].cells[0].source == "seed" and legacy_city.roads[-1].source == "seed", "early schema defaults missing origins to seed")
	_check(loaded.add_house(Vector2(-15.0, -6.0)).ok and loaded.houses[-1].id != new_id, "load preserves identity counter")
	var before_bad := loaded.snapshot()
	var corrupted := before_bad.duplicate(true)
	corrupted.schema = 999
	_check(not loaded.restore(corrupted).ok and loaded.snapshot() == before_bad, "unknown schema rejects without mutation")
	corrupted = before_bad.duplicate(true)
	corrupted.houses[0].cells[0].id = corrupted.houses[1].cells[0].id
	_check(not loaded.restore(corrupted).ok and loaded.snapshot() == before_bad, "duplicate identity rejects without mutation")
	corrupted = before_bad.duplicate(true)
	corrupted.houses[0].cells[0].source = "invented"
	_check(not loaded.restore(corrupted).ok and loaded.snapshot() == before_bad, "unknown origin rejects without mutation")
	for illegal_position in [[100.0, 0.0], [3.0, 0.0]]:
		corrupted = before_bad.duplicate(true)
		corrupted.houses[-1].origin = illegal_position
		_check(not loaded.restore(corrupted).ok and loaded.snapshot() == before_bad, "restored house rejects out-of-bounds or water atomically")
	corrupted = before_bad.duplicate(true)
	corrupted.roads[0].points = [[-8.0, -10.0], [-8.0, -4.0]]
	_check(not loaded.restore(corrupted).ok and loaded.snapshot() == before_bad, "restored road may not cross house walls")
	corrupted = before_bad.duplicate(true)
	for road in corrupted.roads:
		if road.bridge:
			road.bridge = false
	_check(not loaded.restore(corrupted).ok and loaded.snapshot() == before_bad, "restored bridge metadata must match geometry")
	var bad_file := FileAccess.open(path + ".bad", FileAccess.WRITE)
	bad_file.store_string("{broken")
	bad_file.close()
	_check(not loaded.load_city(path + ".bad").ok and loaded.snapshot() == before_bad, "corrupt file retains current city")
	# One history-fork regression: published identity survives undo/save, while
	# redo restores the same intent and a new branch receives fresh identity.
	var branch := State.new()
	branch.initialize()
	var first_house := branch.add_house(Vector2(-15.0, 6.0))
	branch.undo()
	var after_undo := branch.snapshot()
	_check(branch.save_city(path + ".branch").ok, "persist high watermark with undone identity")
	var restored_branch := State.new()
	_check(restored_branch.load_city(path + ".branch").ok and restored_branch.snapshot().high_watermark == after_undo.high_watermark, "load allocator high watermark after undo")
	var second_house := restored_branch.add_house(Vector2(-15.0, -6.0))
	_check(first_house.ok and second_house.ok and first_house.house_id != second_house.house_id, "new history branch cannot reuse published house ID")
	var first_cell := branch.add_cell("h1", 0, 0, 1, "room")
	branch.undo()
	branch.redo()
	_check(first_cell.ok and branch.houses[0].cells[-1].id == first_cell.cell_id, "redo retains original published cell ID")
	_check(restored_branch.save_city(path + ".branch").ok, "persist allocator watermark")
	var persisted_branch := State.new()
	_check(persisted_branch.load_city(path + ".branch").ok and persisted_branch.snapshot().high_watermark == restored_branch.snapshot().high_watermark, "save load preserves issued identity high watermark")
	if failures.is_empty():
		print("CITY_CREATION_STATE PASS: immediate edits, support cascade, no idle growth, identity, undo/redo, atomic save, bad-save rejection")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _geometry(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	result.erase("revision")
	result.erase("high_watermark")
	return result


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
