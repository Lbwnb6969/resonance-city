class_name CityGenerator
extends RefCounted

const Values = preload("res://scripts/spec_values.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Harmony = preload("res://scripts/city/harmony.gd")
const RandomStreams = preload("res://scripts/city/named_random.gd")

var space: Dictionary
var harmony: CityHarmony

func _init() -> void:
	space = Values.load_values()["city"]
	harmony = Harmony.new()

func _free_cell(city: Array, rng: NamedRandom) -> Vector2i:
	var occupied: Array[Vector2i] = []
	for district in city:
		occupied.append(Schema.cell(district))
	while true:
		var cell := Vector2i(rng.bounded("terrain", int(space["width"])), rng.bounded("terrain", int(space["height"])))
		if not occupied.has(cell):
			return cell
	return Vector2i.ZERO

func _initial(rng: NamedRandom) -> Array:
	var city: Array = []
	var per_type := int(space["initial_count"]) / 3
	for type in ["residential", "commercial", "industrial"]:
		for index in range(per_type):
			city.append(Schema.create("%s_%d" % [type, index], type, _free_cell(city, rng)))
	return city

func _perturb(city: Array, rng: NamedRandom) -> Array:
	var next := city.duplicate(true)
	var index := rng.bounded("terrain", next.size())
	var moving: Dictionary = next.pop_at(index)
	var cell := _free_cell(next, rng)
	moving["footprint"] = [[cell.x, cell.y]]
	next.insert(index, moving)
	return next

func safe_fixture() -> Array:
	var city: Array = []
	for type in ["residential", "commercial", "industrial"]:
		var cells: Array = space["safe_cells"][type]
		for index in range(cells.size()):
			city.append(Schema.create("%s_%d" % [type, index], type, Vector2i(cells[index][0], cells[index][1])))
	return city

func generate(seed: String, daily: bool = false, initial_fixture: Array = [], perturb_fixture: Callable = Callable()) -> Dictionary:
	var current_seed := seed.to_lower()
	var records: Array[Dictionary] = []
	var generation_round := 0
	while true:
		var rng := RandomStreams.new(current_seed)
		var city := _initial(rng) if initial_fixture.is_empty() or generation_round > 0 else initial_fixture.duplicate(true)
		var resonance := harmony.resonance(city, harmony.adjacency(city))
		records.append({"seed":current_seed,"local_attempt":0,"resonance":resonance})
		var attempts := 0
		while resonance < float(space["minimum_initial_resonance"]) and attempts < int(space["resample_limit"]):
			city = perturb_fixture.call(city.duplicate(true)) if perturb_fixture.is_valid() else _perturb(city, rng)
			attempts += 1
			resonance = harmony.resonance(city, harmony.adjacency(city))
			records.append({"seed":current_seed,"local_attempt":attempts,"resonance":resonance})
		if resonance >= float(space["minimum_initial_resonance"]):
			return {"seed":current_seed,"requested_seed":seed,"daily":daily,"city":city,"resonance":resonance,
				"rng":rng.snapshot(),"generation_records":records,"fallback":false}
		if daily:
			city = safe_fixture()
			resonance = harmony.resonance(city, harmony.adjacency(city))
			records.append({"seed":current_seed,"local_attempt":attempts,"resonance":resonance,"fallback":true})
			assert(resonance >= float(space["minimum_initial_resonance"]))
			return {"seed":current_seed,"requested_seed":seed,"daily":true,"city":city,"resonance":resonance,
				"rng":rng.snapshot(),"generation_records":records,"fallback":true}
		generation_round += 1
		current_seed = ("retry:" + seed.to_lower() + ":" + str(generation_round)).sha256_text().substr(0,16)
	return {}
