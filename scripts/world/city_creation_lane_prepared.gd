extends RefCounted
## Complete narrow-lane proofs. Plant decoration cannot change a street approach.
const Lane=preload("res://scripts/world/city_creation_lane_contract.gd")
static func capture(city:RefCounted)->Dictionary:
	return city.get_meta("prepared_lane_proofs",{}).duplicate(true)
static func history_seed(city:RefCounted)->Dictionary:
	var life=preload("res://scripts/world/city_creation_economy_pause.gd").owner(city)
	return capture(life._network.state) if life!=null and life._network!=null and life._network.state!=null else {}
static func derive(city:RefCounted,report:Dictionary,water_distance:Callable)->Array:
	if city.roads.is_empty():return []
	city.prepare_ground_height()
	# Protected terrain and road profiles carry all support geometry; full house,
	# street and membership records retain identity, ordering and entry changes.
	var signature:=hash([city.houses,city.roads,city.waters,city.placed_landmarks,city.districts,city.era_modifiers,city.era_unlocks,city.biome_seed,city.creative_settings,city.harmony_journey.get("traditions",[]),city.terrain_policy,city._ground_terrain._water_signature,city._road_heights.profiles,report])
	var cached:Dictionary=city.get_meta("prepared_lane_proofs",{})
	if cached.get("signature",null)==signature:
		city.set_meta("lane_contract_prepare_stats",{"reused":true});return cached.rows.duplicate(true)
	var rows:=Lane.derive(city,report,water_distance)
	city.set_meta("prepared_lane_proofs",{"signature":signature,"rows":rows.duplicate(true)})
	return rows
