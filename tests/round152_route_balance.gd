extends SceneTree
## Round 152 P12 route-balance evidence.
##
## This is a technical matrix, not a listening claim.  Each fixed seed compares
## the three development charters, all cards that can be selected from the
## current draw, and the three public landing branches from one source snapshot.
## The matrix records growth/role differences and proves every branch reaches
## the same four-role opportunity + P11 next-action contract.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Charter = preload("res://scripts/world/development_charter.gd")
const Card = preload("res://scripts/world/planning_card.gd")
const NextAction = preload("res://scripts/world/planning_next_action.gd")

const SEED := "2026101100000152"
const PLANS := ["compact","corridor","bluegreen"]
const CARD_IDS := ["infill_pulse","road_echo","anchor_bloom"]
const PUBLIC_KINDS := ["none","park","civic"]
const OUT := "res://验证记录/round152_规划路线平衡/矩阵.json"

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func public_candidates(world: RefCounted,cid: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lot in world.lots:
		if not str(lot.get("occupant","")).is_empty() or str(lot.get("community_id","") ) != cid: continue
		var candidate: Dictionary = world.planning_candidate(Vector2(float(lot["center"][0]),float(lot["center"][1])))
		if candidate.is_empty() or not bool(candidate.get("allowed",false)) or candidate.has("public_id"): continue
		if not Planning.public_access(world,candidate).is_empty(): result.append(candidate)
	return result

func base_world() -> RefCounted:
	var world := World.new(SEED,true,"river_valley")
	world.build_starter("bright")
	var phrase := int(world.cfg["timing"]["phrase_frames"])
	for _i in range(2): world.settle((world.phrase_index+1)*phrase)
	return world

func round_value(value: float) -> float:
	return snappedf(value,0.001)

func route_matrix(base: RefCounted,scope: Array[String],candidate: Dictionary,phrase: int) -> Dictionary:
	var matrix: Dictionary = {}
	for plan in PLANS:
		for card_id in CARD_IDS:
			for public_kind in PUBLIC_KINDS:
				var world: RefCounted = base.fork()
				var event: Dictionary = world.request({"kind":"charter","plan_id":plan,"community_ids":scope,"card_refs":[card_id]},(world.phrase_index+1)*phrase)
				check(bool(event.get("accepted",false)),"route charter queues: %s/%s/%s" % [plan,card_id,public_kind])
				var public_event: Dictionary = {"accepted":true,"frame":int(event.get("frame",(world.phrase_index+1)*phrase))}
				if public_kind != "none":
					public_event = world.request({"kind":public_kind,"position":candidate["position"].duplicate()},int(event.get("frame",(world.phrase_index+1)*phrase)))
				check(bool(public_event.get("accepted",false)),"route public queues: %s/%s/%s" % [plan,card_id,public_kind])
				var before_events: int = world.events.size()
				world.settle(int(event.get("frame",(world.phrase_index+1)*phrase)))
				# Capture the card/charter ranking while the first post-commit
				# frontier is still open.  Later phrases may fill every lot and would
				# hide a valid conditional relation behind an empty sample set.
				var first_growth_bonus := 0.0
				var first_bonus_samples := 0
				for lot in world.lots:
					if not str(lot.get("occupant","")).is_empty(): continue
					var first_p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
					var first_check: Dictionary = world.placement(first_p)
					if not bool(first_check.get("allowed",false)): continue
					var first_cid := str(first_check.get("community_id",scope[0]))
					if not Charter.in_scope(world,first_cid,scope): continue
					first_growth_bonus = maxf(first_growth_bonus,Charter.growth_bonus(world,first_cid,first_p,1))
					first_bonus_samples += 1
				for _step in range(3): world.settle((world.phrase_index+1)*phrase)
				var charter: Dictionary = Charter.for_community(world,scope[0])
				var born: Array = []
				for raw in world.events.slice(before_events):
					if str(raw.get("kind","")) == "birth": born.append(raw)
				var positions: Array = []
				var road_distance := 0.0
				var center_distance := 0.0
				var compact_neighbors := 0
				for raw in born:
					var id := str(raw.get("district_id",""))
					if not world.by_id.has(id): continue
					var building: Dictionary = world.by_id[id]
					var p := Vector2(float(building["position"][0]),float(building["position"][1]))
					positions.append([round_value(p.x),round_value(p.y)])
					var nearest_road := INF
					for segment in world.near_road_segments(p,8.0):
						nearest_road = minf(nearest_road,p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment["a"],segment["b"])))
					if nearest_road < INF: road_distance += nearest_road
					for other in world.buildings:
						if str(other.get("community_id","")) != scope[0] or other["district_id"] == id: continue
						var q := Vector2(float(other["position"][0]),float(other["position"][1]))
						center_distance += p.distance_to(q)
						if p.distance_to(q) <= 1.8: compact_neighbors += 1
				var max_bonus := 0.0
				var sample_count := 0
				for lot in world.lots:
					if not str(lot.get("occupant","")).is_empty(): continue
					var lp := Vector2(float(lot["center"][0]),float(lot["center"][1]))
					var check_result: Dictionary = world.placement(lp)
					if not bool(check_result.get("allowed",false)): continue
					var cid := str(check_result.get("community_id",scope[0]))
					if not Charter.in_scope(world,cid,scope): continue
					max_bonus = maxf(max_bonus,Charter.growth_bonus(world,cid,lp,compact_neighbors))
					sample_count += 1
				var birth_frames: Array = []
				for raw in born: birth_frames.append(int(raw.get("frame",-1)))
				birth_frames.sort()
				var active_site: Dictionary = world.public_at(Vector2(float(candidate["position"][0]),float(candidate["position"][1])))
				var route_key: String = plan+"/"+card_id+"/"+public_kind
				matrix[route_key] = {
					"plan":plan,"card_id":card_id,"houses":born.size(),
					"public_kind":public_kind,
					"birth_frames":birth_frames,"positions":positions,
					"road_distance_mean":round_value(road_distance/float(maxi(1,born.size()))),
					"center_distance_sum":round_value(center_distance),
					"compact_neighbors":compact_neighbors,"max_growth_bonus":round_value(first_growth_bonus),
					"bonus_samples":first_bonus_samples,
					"charter_card_refs":charter.get("card_refs",[]),
					"charter_plan":str(charter.get("plan_id","")),
					"public_active":not active_site.is_empty() and bool(active_site.get("active",false)),
					"public_served":active_site.get("served",[]),
				}
	return matrix

func role_signature(preview: Dictionary) -> Dictionary:
	var records: Array = preview.get("communities",[])
	if records.is_empty(): return {}
	var record: Dictionary = records[0]
	var roles: Dictionary = record.get("roles",{})
	var result := {}
	for alias in ["theme","bass","commercial","response"]:
		var role: Dictionary = roles.get(alias,{})
		result[alias] = {
			"qualified":bool(role.get("qualified",false)),
			"current":str(role.get("current","")),
			"next":str(role.get("next","")),
			"scheduled":bool(record.get("schedule",{}).get(alias,false)),
		}
	return result

func public_matrix(base: RefCounted,scope: Array[String],candidate: Dictionary,phrase: int) -> Dictionary:
	var result: Dictionary = {}
	var rate := int(base.cfg["timing"]["sample_rate"])
	for plan in PLANS:
		for card_id in CARD_IDS:
			var model := Model.new(base.fork())
			var at := model.world.phrase_index*phrase
			var phases: Dictionary = {}
			model.render_block(phases,at,64,rate)
			at += 64
			var queued: Dictionary = model.submit({"kind":"charter","plan_id":plan,"community_ids":scope,"card_refs":[card_id]})
			check(bool(queued.get("accepted",false)),"preview charter queues: %s/%s" % [plan,card_id])
			var comparison := Preview.build(model.freeze(),candidate,phases,at)
			var route_key: String = plan+"/"+card_id
			var branch_record := {"plan":plan,"card_id":card_id,"branches":{}}
			for kind in PUBLIC_KINDS:
				var variant: Dictionary = comparison.get("variants",{}).get(kind,{})
				var preview: Dictionary = variant.get("opportunity_preview",{})
				check(bool(variant.get("accepted",false)),route_key+"/"+kind+" accepted")
				check(preview.get("source_version",[]) == comparison.get("source_version",[]),route_key+"/"+kind+" source identity")
				var roles := role_signature(preview)
				check(roles.size() == 4,route_key+"/"+kind+" exposes four opportunity roles")
				var action := NextAction.from_preview(preview,kind)
				check(str(action.get("contract","")) == NextAction.CONTRACT,route_key+"/"+kind+" next action contract")
				check(action.get("community_targets",{}).has(scope[0]),route_key+"/"+kind+" next action targets source community")
				branch_record["branches"][kind] = {
					"houses":int(variant.get("houses",0)),
					"birth_count":variant.get("birth_ids",[]).size(),
					"peak":round_value(float(variant.get("peak",0.0))),
					"theme_events":int(variant.get("theme_events",0)),
					"max_voices":int(variant.get("max_voices",0)),
					"affected_communities":preview.get("affected_communities",[]),
					"roles":roles,
					"next_action":{"status":str(action.get("status","")),"role":str(action.get("target",{}).get("role","")),"community_targets":action.get("community_targets",{}).keys()},
				}
			result[route_key] = branch_record
	return result

func _run() -> void:
	var base := base_world()
	var scope: Array[String] = ["west-1"]
	var phrase := int(base.cfg["timing"]["phrase_frames"])
	var candidates := public_candidates(base,scope[0])
	check(candidates.size() >= 1,"real public landing candidate exists")
	if candidates.is_empty():
		print("ROUND152_ROUTE_BALANCE checks=%d failures=%s" % [checks,failures])
		quit(1)
		return
	var candidate: Dictionary = candidates[0]
	var routes := route_matrix(base,scope,candidate,phrase)
	var public := public_matrix(base,scope,candidate,phrase)
	# Technical non-dominance: every charter has a route-specific signal and no
	# plan/card pair may be identical across all measured growth dimensions.
	var plan_signatures: Dictionary = {}
	for plan in PLANS:
		var values: Array = []
		for card_id in CARD_IDS:
			var row: Dictionary = routes[plan+"/"+card_id+"/park"]
			values.append([row["houses"],row["birth_frames"],row["positions"],row["road_distance_mean"],row["center_distance_sum"]])
		plan_signatures[plan] = values
	for i in range(PLANS.size()):
		for j in range(i+1,PLANS.size()):
			check(plan_signatures[PLANS[i]] != plan_signatures[PLANS[j]],"charters %s and %s produce distinct growth signatures" % [PLANS[i],PLANS[j]])
	for plan in PLANS:
		var card_signatures: Array = []
		for card_id in CARD_IDS:
			var row: Dictionary = routes[plan+"/"+card_id+"/park"]
			card_signatures.append([row["birth_frames"],row["positions"],row["road_distance_mean"],row["center_distance_sum"]])
		check(card_signatures[0] != card_signatures[1] or card_signatures[1] != card_signatures[2],"cards vary at least one growth signal under %s" % plan)
	# Public landing must actually remain a three-way comparison and produce
	# distinct scheduling/PCM metadata; route/card changes may legitimately leave
	# one role unchanged, so we require structural coverage rather than a taste
	# judgment about which branch sounds best.
	for key in public:
		var branches: Dictionary = public[key]["branches"]
		check(branches.size() == 3,key+" has all three public branches")
		var role_sigs: Array = []
		for kind in PUBLIC_KINDS: role_sigs.append(branches[kind]["roles"])
		check(role_sigs[0] != role_sigs[1] or role_sigs[1] != role_sigs[2],key+" public branches expose a role scheduling difference")

	var evidence := {"contract":"ROUND152-ROUTE-BALANCE/v1","seed":SEED,"scope":scope,
		"candidate":{"source_site_id":str(candidate.get("source_site_id","")),"position":candidate.get("position",[]),"community_id":str(candidate.get("community_id",""))},
		"route_matrix":routes,"public_matrix":public,
		"claims":{"technical_route_difference":"verified from production growth and public preview metadata","non_dominance":"structural signals only; no subjective winner declared","pcm_or_wasapi":"not run in this offline matrix","human_listening":"not claimed"}}
	var path := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(evidence,"\t")+"\n"); file.close()
	print("ROUND152_ROUTE_BALANCE checks=%d failures=%s" % [checks,JSON.stringify(failures)])
	quit(0 if failures.is_empty() else 1)
