extends RefCounted
## A playable comparison city built through the same public and sound choices.
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")

static func _candidate(city: World,key: String,cid: String) -> Dictionary:
	for candidate: Dictionary in First.opportunities(city)[key]:
		if str(candidate["community_id"]) == cid: return candidate
	return {}

static func _settle(city: World) -> void:
	city.settle((city.phrase_index+1)*int(city.cfg["timing"]["phrase_frames"]))

static func build() -> World:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var charter := city.request({"kind":"charter","plan_id":"compact","community_ids":["west-2"],"card_refs":["infill_pulse"]},phrase)
	assert(bool(charter["accepted"]),"Comparison city's compact charter must use a legal player choice")
	# There is one replaceable public intent, so each public space commits
	# before querying the next legal site. No scenery-only buildings are added.
	for choice: Dictionary in [{"kind":"civic","cid":"west-2"},{"kind":"park","cid":"east-2"}]:
		var site := _candidate(city,"public_candidates",str(choice["cid"]))
		assert(not site.is_empty(),"Comparison city's public choice must have a legal site")
		var result := city.request({"kind":choice["kind"],"position":site["position"]},(city.phrase_index+1)*phrase)
		assert(bool(result["accepted"]),"Comparison city's public request must be accepted")
		_settle(city)
	for choice: Dictionary in [{"expression":"deep","cid":"west-2"},{"expression":"weave","cid":"east-2"}]:
		var site := _candidate(city,"seed_candidates",str(choice["cid"]))
		assert(not site.is_empty(),"Comparison city's author must have a legal sound site")
		var result := city.request(PlayerExpression.operation(str(choice["expression"]),site["position"]),(city.phrase_index+1)*phrase)
		assert(bool(result["accepted"]),"Comparison city's sound request must be accepted")
		_settle(city)
	return city
