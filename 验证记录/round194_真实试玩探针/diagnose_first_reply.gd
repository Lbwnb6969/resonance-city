extends SceneTree
## Read-only diagnostic for the old one-author natural Reply observation.
## It mirrors the first-composition route and prints the actual river pairs
## available after the first authored root is retuned.
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const River = preload("res://scripts/world/river_call_response.gd")
const SEED := "2026100900000062"

func _initialize() -> void: call_deferred("_run")

func _settle(city: RefCounted) -> void:
	city.settle((city.phrase_index+1)*int(city.cfg["timing"]["phrase_frames"]))

func _run() -> void:
	var city := World.new(SEED,true,"river_valley")
	city.build_first_composition_starter()
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var choices: Dictionary = First.opportunities(city)
	var public: Dictionary = {}
	for candidate: Dictionary in choices.get("public_candidates",[]):
		if str(candidate.get("community_id","")) == "west-1": public = candidate; break
	var charter := city.request({"kind":"charter","plan_id":"compact","community_ids":["west-1"],"card_refs":["infill_pulse"]},phrase)
	var civic := city.request({"kind":"civic","position":public.get("position",[])},phrase)
	_settle(city)
	var seed_choices: Array = First.opportunities(city).get("seed_candidates",[])
	var seed: Dictionary = {}
	for candidate: Dictionary in seed_choices:
		if str(candidate.get("community_id","")) == "west-1": seed = candidate; break
	var operation := PlayerExpression.operation("weave",Vector2(float(seed["position"][0]),float(seed["position"][1])))
	var root_request := city.request(operation,phrase*2)
	while city.phrase_index < 5: _settle(city)
	var root_id := ""
	for family: Dictionary in city.families.values():
		if bool(family.get("player_expression",false)):
			root_id = str(family.get("root","")); break
	var root: Dictionary = city.by_id.get(root_id,{})
	var overrides := {root_id:64}
	var pairs := River.pairs(city,overrides)
	var theme := {"cid":"west-1","source_ids":city.community_theme_sources("west-1"),"player_expression":true}
	var response := River.reply(city,theme,pairs,overrides)
	var rows: Array = []
	for pair: Dictionary in pairs:
		rows.append({"a":pair["a"],"b":pair["b"],"distance":pair["distance"],"score":pair["score"],"a_pitch":int(overrides.get(str(pair["a"]),city.by_id[pair["a"]]["current_midi"])),"b_pitch":int(overrides.get(str(pair["b"]),city.by_id[pair["b"]]["current_midi"]))})
	var nearest: Array = []
	var root_pos := Vector2(float(root.get("position",[0.0,0.0])[0]),float(root.get("position",[0.0,0.0])[1]))
	for house: Dictionary in city.buildings:
		var p := Vector2(float(house["position"][0]),float(house["position"][1]))
		if signf(p.x-city.terrain.river_x(p.y)) == signf(root_pos.x-city.terrain.river_x(root_pos.y)): continue
		nearest.append({"id":house["district_id"],"community":house["community_id"],"distance":root_pos.distance_to(p),"position":house["position"],"pitch":int(house["current_midi"])})
	nearest.sort_custom(func(a: Dictionary,b: Dictionary)->bool: return float(a["distance"]) < float(b["distance"]))
	var out := {"starter":24,"phrase":city.phrase_index,"charter":charter,"civic":civic,"seed":seed,"root_request":root_request,"root_id":root_id,"root_position":root.get("position",[]),"root_pitch":root.get("current_midi",-1),"pairs":rows,"nearest_opposite":nearest.slice(0,8),"response":response}
	var path := ProjectSettings.globalize_path("res://验证记录/round194_真实试玩探针/diagnose_first_reply.json")
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(out,"\t")+"\n")
	print("DIAG_FIRST_REPLY ",JSON.stringify(out))
	quit()
