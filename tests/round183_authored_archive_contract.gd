extends SceneTree
## Round 183: the first authored choice is a real save/export boundary.
##
## This deliberately exercises the same compact first-composition chain for
## deep, weave and warm.  Ctrl+S is represented by CityArchive.save/latest,
## F9 by restoring the latest binary checkpoint, and City DNA by
## export_dna/read_dna.  The test checks identity and causal fields; it does
## not make a human listening or route-balance claim.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const PlanningCard = preload("res://scripts/world/planning_card.gd")

const SEED := "2026100900000062"
const OUTPUT := "res://验证记录/round183_作品保存导出/"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {"routes":{}}
var temp_dirs: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _renderer(model: Model,snapshot: Dictionary = {}) -> Renderer:
	var renderer := Renderer.new(int(model.world.cfg["timing"]["sample_rate"]))
	renderer.source = model.render_block
	if not snapshot.is_empty(): renderer.restore(snapshot)
	return renderer

func _advance(renderer: Renderer,end_frame: int) -> void:
	while renderer.transport.rendered_frames < end_frame:
		renderer.render(mini(1024,end_frame-renderer.transport.rendered_frames))

func _root(model: Model,choice: String) -> Dictionary:
	for family: Dictionary in model.world.families.values():
		if not bool(family.get("player_expression",false)) or str(family.get("expression","")) != choice: continue
		return model.world.by_id.get(str(family.get("root","")),{})
	return {}

func _event(model: Model,kind: String,id: String) -> Dictionary:
	for event: Dictionary in model.world.events:
		if str(event.get("kind","")) == kind and (id.is_empty() or str(event.get("district_id",event.get("id",""))) == id): return event
	return {}

func _family(model: Model,root_id: String) -> Dictionary:
	var root: Dictionary = model.world.by_id.get(root_id,{})
	return model.world.families.get(str(root.get("family_id","")),{})

func _latest_root(model: Model,choice: String) -> Dictionary:
	var root := _root(model,choice)
	if root.is_empty(): return {}
	var family := _family(model,str(root.get("district_id","")))
	return {"root":root,"family":family}

func _cleanup() -> void:
	for directory in temp_dirs:
		if DirAccess.dir_exists_absolute(directory+"/exports"):
			for filename in DirAccess.get_files_at(directory+"/exports"):
				DirAccess.remove_absolute(directory+"/exports/"+filename)
			DirAccess.remove_absolute(directory+"/exports")
		for filename in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory+"/"+filename)
		DirAccess.remove_absolute(directory)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var city := World.new(SEED,true,"river_valley")
	city.build_first_composition_starter()
	var gain := 1.34090362249795
	var source := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var renderer := _renderer(source)
	var cards := PlanningCard.choices(city,"compact")
	var card := "infill_pulse" if cards.has("infill_pulse") else str(cards[0])
	var public_position: Array = []
	for candidate: Dictionary in First.opportunities(city)["public_candidates"]:
		if str(candidate.get("community_id","")) == "west-1": public_position = candidate["position"].duplicate()
	var charter := source.submit({"kind":"charter","plan_id":"compact","community_ids":["west-1"],"card_refs":[card]})
	var civic := source.submit({"kind":"civic","position":public_position})
	_check(bool(charter.get("accepted",false)) and bool(civic.get("accepted",false)),"common_first_composition_planning_intents_are_accepted")
	var phrase := int(source.phrase_frames)
	_advance(renderer,phrase*2-128)
	var candidates: Array = First.opportunities(city).get("seed_candidates",[])
	var position: Array = []
	for candidate: Dictionary in candidates:
		if str(candidate.get("community_id","")) == "west-1": position = candidate["position"].duplicate(); break
	_check(position.size() == 2,"common_authored_sound_position_is_real_and_continuous")
	if position.size() != 2:
		_finish(); return
	var shared_model := source.capture_state()
	var shared_renderer := renderer.snapshot()
	for choice: String in PlayerExpression.IDS:
		var model := Model.from_state(shared_model)
		var branch_renderer := _renderer(model,shared_renderer)
		var seed_request := model.submit(PlayerExpression.operation(choice,Vector2(float(position[0]),float(position[1]))))
		_check(bool(seed_request.get("accepted",false)),choice+"_expression_seed_is_accepted")
		_advance(branch_renderer,model.next_boundary+1)
		var state := _latest_root(model,choice)
		var root: Dictionary = state.get("root",{})
		var family: Dictionary = state.get("family",{})
		var root_id := str(root.get("district_id",""))
		_check(not root.is_empty() and bool(root.get("player_expression",false)) and str(root.get("expression","")) == choice,choice+"_saved_route_has_real_authored_root")
		if root.is_empty(): continue
		var before_theme := model.world.community_theme("west-1",model.sound_overrides).duplicate(true)
		var new_midi := int(root.get("current_midi",0))+4
		var retune := model.submit({"kind":"retune","id":root_id,"midi":new_midi})
		_check(bool(retune.get("accepted",false)),choice+"_author_root_retune_is_accepted")
		_advance(branch_renderer,model.next_boundary+1)
		root = model.world.by_id.get(root_id,{})
		family = _family(model,root_id)
		var after_theme := model.world.community_theme("west-1",model.sound_overrides)
		_check(int(root.get("current_midi",-1)) == new_midi and int(model.sound_overrides.get(root_id,-1)) == new_midi,choice+"_retuned_pitch_is_current_and_override_is_durable")
		_check(before_theme != after_theme and model.world.community_theme_sources("west-1").has(root_id),choice+"_retune_changes_the_actual_theme_source_at_its_map_house")
		_check(not _event(model,"birth",root_id).is_empty() and not _event(model,"retune",root_id).is_empty(),choice+"_birth_and_retune_map_events_are_recorded")
		var reservation_id := str(family.get("expression_reservation_id",""))
		var reservations: Array = model.world.planning_reservations.filter(func(item: Dictionary) -> bool: return str(item.get("id","")) == reservation_id)
		_check((choice == "warm" and not reservation_id.is_empty() and reservations.size() == 1) or (choice != "warm" and reservation_id.is_empty() and reservations.is_empty()),choice+"_keep_land_state_is_preserved_only_for_warm")
		var city_state := {"model":model.capture_state(),"renderer":branch_renderer.snapshot(),"view":{"first_composition_mode":true,"selected_id":root_id}}
		var directory := "user://round183_authored_archive_%s_%d" % [choice,Time.get_ticks_usec()]
		temp_dirs.append(directory)
		var written := Archive.save(city_state,"Round183 Ctrl+S authored route",directory)
		_check(bool(written.get("ok",false)),choice+"_ctrl_s_checkpoint_writes")
		var latest := Archive.latest(directory)
		_check(bool(latest.get("ok",false)),choice+"_f9_finds_latest_checkpoint")
		if not bool(latest.get("ok",false)): continue
		var restored: Model = Model.from_state(latest["city"]["model"])
		var restored_root := _root(restored,choice)
		var restored_family := _family(restored,str(restored_root.get("district_id","")))
		_check(str(restored_root.get("district_id","")) == root_id and int(restored_root.get("current_midi",-1)) == new_midi and bool(restored_root.get("player_expression",false)),choice+"_f9_restores_authored_identity_and_retune")
		_check(restored_family.get("expression_reservation_id","") == family.get("expression_reservation_id","") and restored.world.planning_reservations == model.world.planning_reservations,choice+"_f9_restores_keep_land_family_and_reservation")
		_check(not _event(restored,"birth",root_id).is_empty() and not _event(restored,"retune",root_id).is_empty() and restored.world.community_theme_sources("west-1").has(root_id),choice+"_f9_restores_map_events_and_theme_source")
		var export_dir := directory+"/exports"
		var exported := Archive.export_dna(city_state,export_dir)
		_check(bool(exported.get("ok",false)),choice+"_city_dna_export_writes")
		if bool(exported.get("ok",false)):
			var dna_path := str(exported["path"])
			var imported := Archive.read_dna(dna_path)
			_check(bool(imported.get("ok",false)),choice+"_city_dna_is_readable")
			var payload: Dictionary = imported.get("dna",{})
			var runtime_model: Dictionary = payload.get("runtime",{}).get("model",{})
			var runtime_world: Dictionary = runtime_model.get("world",{})
			var plan: Dictionary = payload.get("plan",{})
			_check(payload.get("families",{}).has(str(root.get("family_id",""))) and runtime_world.get("families",{}).has(str(root.get("family_id",""))),choice+"_city_dna_exports_authored_family_and_expression")
			_check(runtime_model.get("sound_overrides",{}).get(root_id,-1) == new_midi and runtime_world.get("events",[]).any(func(item: Dictionary) -> bool: return str(item.get("kind","")) == "retune" and str(item.get("district_id","")) == root_id),choice+"_city_dna_exports_retune_override_and_event")
			var dna_restored: Model = Model.from_state(imported["model"])
			var dna_root := _root(dna_restored,choice)
			var dna_family := _family(dna_restored,str(dna_root.get("district_id","")))
			_check(str(dna_root.get("district_id","")) == root_id and int(dna_root.get("current_midi",-1)) == new_midi and bool(dna_root.get("player_expression",false)),choice+"_city_dna_restores_authored_root_and_pitch")
			_check(dna_family.get("expression_reservation_id","") == family.get("expression_reservation_id","") and dna_restored.world.community_theme_sources("west-1").has(root_id),choice+"_city_dna_restores_keep_land_and_theme_source")
			var archive_check := Archive.validate_audio_plan(dna_path)
			_check(bool(archive_check.get("ok",false)),choice+"_city_dna_audio_plan_remains_replayable")
			evidence["routes"][choice] = {"root_id":root_id,"expression":choice,"base_midi":int(root.get("base_midi",-1)),"current_midi":new_midi,"family_id":str(root.get("family_id","")),"reservation_id":reservation_id,"theme_sources":model.world.community_theme_sources("west-1"),"birth_event":_event(model,"birth",root_id),"retune_event":_event(model,"retune",root_id),"checkpoint":written.get("path",""),"dna":dna_path,"audio_plan":{"ok":bool(archive_check.get("ok",false)),"phrase_frames":int(archive_check.get("phrase_frames",0)),"sample_rate":int(archive_check.get("sample_rate",0)),"sound_event_count":int(archive_check.get("sound_event_count",0)),"decision_count":int(archive_check.get("decision_count",0))}}
	_finish()

func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Ctrl+S/F9 binary and City DNA preserve real authored expression, root retune, keep-land reservation, theme source and map events. No human listening claim."}
	FileAccess.open(OUTPUT+"authored_archive_contract.json",FileAccess.WRITE).store_string(JSON.stringify(Archive._json_value(report),"  ")+"\n")
	_cleanup()
	print("ROUND183_AUTHORED_ARCHIVE_CONTRACT "+JSON.stringify({"passed":failures.is_empty(),"checks":checks.size(),"failures":failures,"routes":evidence["routes"].keys()}))
	quit(0 if failures.is_empty() else 1)
