extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const MusicRules = preload("res://scripts/world/community_music_rules.gd")
const Street = preload("res://scripts/world/authored_street_growth.gd")
const Synth = preload("res://scripts/audio/continuous_synth.gd")
const LEGACY_SYNTH := "res://废弃/scripts/2026-10-11_作者主题及时出场前/continuous_synth.gd"
const OUTPUT := "res://验证记录/round190_作者主题及时出场/"
const SEED := "2026100900000062"
var checks: Dictionary = {}
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)
func _settle(city: World) -> void: city.settle((city.phrase_index+1)*int(city.cfg["timing"]["phrase_frames"]))
func _node(model: Model,answer: bool) -> Dictionary:
	for node: Dictionary in model.synth.musical_nodes.values():
		if bool(node.get("active",false)) and bool(node.get("answer",false)) == answer: return node
	return {}
func _actual_root(city: World) -> Dictionary:
	for family: Dictionary in city.families.values():
		if bool(family.get("player_expression",false)): return city.by_id[str(family["root"])]
	return {}
func _render(model: Model,phases: Dictionary,begin: int,end: int) -> Dictionary:
	var samples := PackedVector2Array()
	var root_rows: Array = []
	var source_id := str(_actual_root(model.world)["district_id"])
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	for at in range(begin,end,512):
		var amount := mini(512,end-at)
		samples.append_array(model.render_block(phases,at,amount,rate))
		for row: Dictionary in model.audible_music_activity(at+amount-1):
			if int(row["generation"]) == 0 and str(row["source_id"]) == source_id and not root_rows.any(func(old: Dictionary) -> bool: return str(old["event_id"]) == str(row["event_id"])): root_rows.append(row)
	return {"pcm":samples,"root_rows":root_rows}

func _ordinary_regression(city: World,rate: int) -> void:
	var script := GDScript.new()
	script.source_code = FileAccess.get_file_as_string(LEGACY_SYNTH).replace("class_name ContinuousSynth","")
	check(script.reload() == OK,"ordinary_legacy_synth_compiles")
	var old: RefCounted = script.new(city.buildings)
	var current := Synth.new(city.buildings)
	old.focused_community = "west-1"
	current.focused_community = "west-1"
	old.configure_score(city)
	current.configure_score(city)
	check(current.musical_nodes == old.musical_nodes,"ordinary_theme_lifetimes_unchanged")
	var unchanged := true
	for key in current.musical_nodes:
		if current.musical_events(current.musical_nodes[key],city.phrase_index*rate*16,rate*32,rate) != old.musical_events(old.musical_nodes[key],city.phrase_index*rate*16,rate*32,rate): unchanged = false
	check(unchanged,"ordinary_theme_source_schedule_unchanged")

func _reply_probe(phrase: int,rate: int) -> Dictionary:
	var city := World.new(SEED,true,"river_valley")
	city.build_first_composition_starter()
	city.request({"kind":"charter","plan_id":"compact","community_ids":["west-2"],"card_refs":["infill_pulse"]},phrase)
	for candidate: Dictionary in First.opportunities(city)["public_candidates"]:
		if str(candidate["community_id"]) == "west-2":
			city.request({"kind":"civic","position":candidate["position"]},phrase)
			break
	_settle(city)
	var frontier: Array[Vector2] = []
	for id: String in city.communities["west-2"]["members"]:
		var raw: Array = city.by_id[id]["position"]
		frontier.append(Vector2(float(raw[0]),float(raw[1])))
	var best := INF
	var position := Vector2.ZERO
	var receiver := ""
	for candidate: Dictionary in Street.candidates(city,frontier,"weave"):
		var p: Vector2 = candidate["position"]
		var placement: Dictionary = city.placement(p)
		if not bool(placement.get("allowed",false)) or str(placement.get("community_id","")) != "west-2": continue
		for id: String in city.communities["east-2"]["members"]:
			var raw: Array = city.by_id[id]["position"]
			var distance := p.distance_to(Vector2(float(raw[0]),float(raw[1])))
			if distance < best:
				best = distance
				position = p
				receiver = id
	check(best < 8.0,"reply_fixture_has_real_legal_cross_bank_land")
	check(bool(city.request(PlayerExpression.operation("weave",position),phrase*2).get("accepted",false)),"reply_fixture_real_author_root_accepted")
	while city.phrase_index < 5: _settle(city)
	check(bool(MusicRules.status(city,"west-2")["theme_eligible"]),"reply_fixture_natural_theme_qualification")
	var root_id := str(_actual_root(city)["district_id"])
	var model := Model.new(city)
	var begin := city.phrase_index*phrase+rate*9+1
	model.rendered_until = begin
	model.submit({"kind":"focus","community":"west-2"})
	# Actual E/G is an existing qualified major-sixth relation.
	model.submit({"kind":"retune","id":root_id,"midi":64})
	_render(model,{},begin,begin+rate*4)
	var lead := _node(model,false)
	var response := _node(model,true)
	check(not response.is_empty() and int(response.get("source_origin",-1)) == int(lead.get("source_origin",-2)),"actual_reply_shares_its_lead_origin")
	var events: Array = model.synth.musical_events(lead,int(lead["born_at"]),phrase*2,rate)
	var replies: Array = [] if response.is_empty() else model.synth.musical_events(response,int(lead["born_at"]),phrase*2,rate)
	var paired := not replies.is_empty()
	for reply: Dictionary in replies:
		if not events.any(func(event: Dictionary) -> bool: return event["event_id"] == reply["source_event_id"] and event["source_id"] == reply["source_id"] and int(reply["onset"])-int(event["onset"]) == rate): paired = false
	check(paired,"nonempty_actual_reply_follows_same_source_and_two_beats")
	# A receiver-only change rebuilds Reply while the Lead keeps its earlier origin.
	var origin := int(lead.get("source_origin",-1))
	var receiver_change: Dictionary = model.submit({"kind":"retune","id":receiver,"midi":43})
	check(bool(receiver_change.get("accepted",false)),"real_receiver_octave_change_accepted")
	_render(model,{},model.rendered_until,model.rendered_until+rate)
	var next_response := _node(model,true)
	check(bool(receiver_change.get("accepted",false)) and not next_response.is_empty() and int(next_response.get("source_origin",-1)) == origin and int(next_response["born_at"]) == int(receiver_change["sound_frame"]),"receiver_change_keeps_existing_lead_source_origin")
	return {"root":root_id,"receiver":receiver,"distance":best,"status":MusicRules.status(city,"west-2"),"lead_origin":origin,"reply_count":replies.size(),"first_reply":replies[0] if not replies.is_empty() else {}}
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var source := World.new(SEED,true,"river_valley")
	source.build_first_composition_starter()
	var phrase := int(source.cfg["timing"]["phrase_frames"])
	var rate := int(source.cfg["timing"]["sample_rate"])
	source.request({"kind":"charter","plan_id":"compact","community_ids":["west-1"],"card_refs":["infill_pulse"]},phrase)
	source.request({"kind":"civic","position":First.opportunities(source)["public_candidates"][0]["position"]},phrase)
	_settle(source)
	var snapshot := source.snapshot()
	var ordinary := source.fork()
	while ordinary.phrase_index < 5: _settle(ordinary)
	_ordinary_regression(ordinary,rate)
	var position: Array = First.opportunities(source)["seed_candidates"][0]["position"]
	var routes: Dictionary = {}
	for expression: String in PlayerExpression.IDS:
		var city := World.new(SEED,false,"river_valley")
		city.restore(snapshot)
		check(bool(city.request(PlayerExpression.operation(expression,position),phrase*2).get("accepted",false)),expression+"_actual_root_request")
		while city.phrase_index < 5: _settle(city)
		check(bool(MusicRules.status(city,"west-1")["theme_eligible"]),expression+"_ordinary_maturity_qualifies_theme")
		var house := _actual_root(city)
		var root_id := str(house["district_id"])
		var original_index := city.community_theme_sources("west-1").find(root_id)
		var old_model := Model.new(city.fork())
		var new_model := Model.new(city.fork())
		var begin := city.phrase_index*phrase+rate*9+1
		old_model.rendered_until = begin
		new_model.rendered_until = begin
		old_model.enable_music_activity()
		new_model.enable_music_activity()
		old_model.submit({"kind":"focus","community":"west-1"})
		new_model.submit({"kind":"focus","community":"west-1"})
		var retune: Dictionary = new_model.submit({"kind":"retune","id":root_id,"midi":int(house["current_midi"])+4})
		check(bool(retune.get("accepted",false)),expression+"_production_author_retune_accepted")
		var old_render := _render(old_model,{},begin,city.phrase_index*phrase+rate*13)
		var new_render := _render(new_model,{},begin,city.phrase_index*phrase+rate*13)
		var lead := _node(new_model,false)
		var old_rows: Array = old_render["root_rows"]
		var new_rows: Array = new_render["root_rows"]
		var old_row: Dictionary = old_rows[0] if not old_rows.is_empty() else {}
		var new_row: Dictionary = new_rows[0] if not new_rows.is_empty() else {}
		check(not new_row.is_empty() and int(new_row["onset"]) >= int(retune["sound_frame"]) and int(new_row["onset"])-int(retune["sound_frame"]) <= rate*4,expression+"_actual_generation_zero_author_root_heard_at_next_legal_pattern_beat")
		var requested_pitch := int(house["current_midi"])+4
		# The untouched control can still be on its old geometric turn; the production
		# contract is the chosen real root pitch on the first new authored event.
		check(not new_row.is_empty() and int(new_row["pitch"]) == requested_pitch,expression+"_same_real_root_uses_requested_pitch")
		var difference := 0.0
		var old_pcm: PackedVector2Array = old_render["pcm"]
		var new_pcm: PackedVector2Array = new_render["pcm"]
		for index in range(old_pcm.size()): difference = maxf(difference,maxf(absf(old_pcm[index].x-new_pcm[index].x),absf(old_pcm[index].y-new_pcm[index].y)))
		check(difference > 0.005,expression+"_real_full_score_pcm_changes")
		check(new_model.synth.theme["source_ids"][0] == root_id and new_model.synth.theme["source_ids"].size() == city.community_theme_sources("west-1").size(),expression+"_root_opens_without_discarding_actual_residents")
		var frozen := new_model.freeze()
		check(new_model.synth.musical_events(lead,begin,phrase*2,rate) == frozen.synth.musical_events(_node(frozen,false),begin,phrase*2,rate),expression+"_freeze_keeps_the_exact_authored_schedule_origin")
		var events: Array = new_model.synth.musical_events(lead,int(lead["born_at"]),phrase*20,rate)
		var performers: Array = []
		for event: Dictionary in events:
			if not performers.has(event["source_id"]): performers.append(event["source_id"])
		check(performers.size() == lead["pattern"]["source_ids"].size(),expression+"_later_notes_still_traverse_every_real_resident")
		var response := _node(new_model,true)
		var replies_same_source := true
		if not response.is_empty():
			for reply: Dictionary in new_model.synth.musical_events(response,int(lead["born_at"]),phrase*2,rate):
				if not events.any(func(event: Dictionary) -> bool: return event["event_id"] == reply["source_event_id"] and event["source_id"] == reply["source_id"] and int(reply["onset"])-int(event["onset"]) == rate): replies_same_source = false
		check(replies_same_source,expression+"_every_actual_reply_uses_the_exact_lead_schedule_and_two_beat_delay")
		routes[expression] = {"geometric_root_index":original_index,"source_count":city.community_theme_sources("west-1").size(),"retune":retune,"old_root_event":old_row,"new_root_event":new_row,"pcm_max_difference":difference,"lead_source_origin":lead.get("source_origin",-1),"reply_source_origin":response.get("source_origin",-1),"reply_available":not response.is_empty(),"resident_performers":performers}
	var reply := _reply_probe(phrase,rate)
	var result := {"checks":checks,"failures":failures,"routes":routes,"cross_bank_reply":reply}
	FileAccess.open(OUTPUT+"author_theme_entry.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("AUTHOR_THEME_ENTRY ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
