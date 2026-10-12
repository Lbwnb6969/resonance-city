extends SceneTree
## One production starter, actual birth, real archive/DNA and same-source PCM.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Neighborhoods = preload("res://scripts/world/player_neighborhoods.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const OUTPUT := "res://验证记录/round216_玩家街坊_存取/contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _finish() -> void:
	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,
		"scope":"City-level confirmed authorship; real 24-house starter, genuine seed birth, binary/JSON archive and same-source short PCM. Dummy only; no Demo/GPU/device/user works or exact-range audio."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("ROUND216_PLAYER_NEIGHBORHOODS ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func _city_fixture(path: String, city: Dictionary) -> void:
	var payload := var_to_bytes({"version":1,"saved_at":0,"reason":"contract fixture","city":city})
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(Archive.MAGIC.to_utf8_buffer())
	file.store_pascal_string(Archive._digest(payload))
	file.store_32(payload.size())
	file.store_buffer(payload)
	file.close()

func _json_fixture(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value,"\t")+"\n")
	file.close()

func _ids(city: ContinuousWorld, cid: String) -> Array[String]:
	var ids: Array[String] = []
	for building: Dictionary in city.buildings:
		if str(building["community_id"]) == cid: ids.append(str(building["district_id"]))
	ids.sort()
	return ids

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_only_no_device")
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var west := _ids(city,"west-1")
	var east := _ids(city,"east-2")
	check(city.buildings.size() == 24 and west.size() == 8 and east.size() == 8,"production_24_house_starter")
	if west.size() < 2 or east.is_empty(): _finish(); return
	var model := Model.new(city,1.34090362249795)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var renderer := Renderer.new(rate)
	renderer.source = model._mix_frame
	renderer.render(256)
	var before := model.capture_state()
	var renderer_before := renderer.snapshot()
	var authors := Neighborhoods.new()
	var requested: Array[String] = [east[0],west[1],west[0],west[1]]
	var expected: Array[String] = [east[0],west[1],west[0]]
	expected.sort()
	var created := authors.confirm(city,0,requested,"  石桥两岸  ")
	var id := str(created.get("record",{}).get("id",""))
	check(bool(created["ok"]) and authors.record(id).get("member_ids",[]) == expected and authors.record(id).get("name","") == "石桥两岸" and authors.records().size() == 1,"explicit_cross_cid_members_are_sorted_unique_and_not_whole_communities")
	if not bool(created["ok"]): _finish(); return
	var stable := authors.snapshot()
	check(not authors.confirm(city,0,expected,"  ")["ok"] and not authors.confirm(city,0,Array([],TYPE_STRING,"",null),"空")["ok"] and not authors.confirm(city,0,Array(["not-a-house"],TYPE_STRING,"",null),"无效")["ok"] and authors.snapshot() == stable,"invalid_new_confirmation_is_atomic")
	var returned := authors.records()
	returned[0]["member_ids"].clear()
	var one := authors.record(id)
	one["name"] = "外部写入"
	var member_records := authors.for_member(west[0])
	member_records[0]["member_ids"].clear()
	var external := authors.snapshot()
	external["neighborhoods"].clear()
	check(authors.snapshot() == stable,"all_public_queries_return_independent_deep_copies")
	var reference := model.freeze()
	var reference_state := renderer.state.duplicate(true)
	var reference_pcm := reference.render_block(reference_state,model.rendered_until,512,rate)
	var after := model.freeze()
	var after_state := renderer.state.duplicate(true)
	var after_pcm := after.render_block(after_state,model.rendered_until,512,rate)
	check(model.capture_state() == before and renderer.snapshot() == renderer_before and reference_pcm.to_byte_array() == after_pcm.to_byte_array(),"selection_name_queries_and_rejections_preserve_world_rng_pending_audio_state_and_pcm")

	var original_members: Array = authors.record(id)["member_ids"].duplicate()
	var original_building_ids: Array = city.by_id.keys()
	var candidate: Dictionary = First.opportunities(city)["seed_candidates"][0]
	var seed := model.submit(PlayerExpression.operation("deep",candidate["position"]))
	var boundary := model.next_boundary
	model.render_block(renderer.state,boundary-1,2,rate)
	renderer.transport.rendered_frames = model.rendered_until
	renderer.transport.audible_frame = float(boundary)
	var born := ""
	for building: Dictionary in city.buildings:
		if not original_building_ids.has(building["district_id"]): born = str(building["district_id"]); break
	check(bool(seed.get("accepted",false)) and not born.is_empty() and int(city.by_id[born]["birth_frame"]) == boundary and authors.record(id)["member_ids"] == original_members,"actual_new_birth_does_not_auto_expand_the_authored_neighborhood")
	if born.is_empty(): _finish(); return
	var actual_before := model.capture_state()
	var future: Array[String] = [west[0],born]
	check(not authors.confirm(city,boundary-1,future,"尚未来到")["ok"] and authors.snapshot() == stable,"render_ahead_house_cannot_become_a_new_member_before_heard_frame")
	var edit := authors.confirm(city,boundary,future,"桥边新名",id)
	var edited := authors.record(id)
	future.sort()
	check(bool(edit["ok"]) and edited["id"] == id and edited["revision"] == 2 and edited["created_audio_frame"] == 0 and edited["modified_audio_frame"] == boundary and edited["member_ids"] == future and authors.for_member(east[0]).is_empty(),"explicit_edit_keeps_identity_and_creation_but_adds_or_removes_only_chosen_valid_members")
	# A saved member may no longer exist in the restored city's live index.
	var historical := authors.snapshot()
	historical["neighborhoods"][0]["member_ids"].append("historical-removed-source")
	historical["neighborhoods"][0]["member_ids"].sort()
	var history_restored := authors.restore(historical)
	var rename := authors.confirm(city,boundary,future,"旧桥仍在",id)
	check(bool(history_restored["ok"]) and bool(rename["ok"]) and authors.record(id)["member_ids"].has("historical-removed-source") and authors.record(id)["revision"] == 3 and model.capture_state() == actual_before,"rename_retains_unavailable_historical_source_ids_without_world_writes")
	var second := authors.confirm(city,boundary,Array([east[0]],TYPE_STRING,"",null),"另一处街坊")
	check(bool(second["ok"]) and second["record"]["id"] != id and authors.records().size() == 2 and authors.for_member(east[0]).size() == 1,"neighborhood_identity_is_independent_of_names_cid_and_world_actions")
	var canonical := authors.snapshot()
	var unknown := canonical.duplicate(true)
	unknown["schema"] = 2
	var duplicates := canonical.duplicate(true)
	duplicates["neighborhoods"].append(duplicates["neighborhoods"][0].duplicate(true))
	var fractional := canonical.duplicate(true)
	fractional["next_neighborhood_id"] = 1.5
	check(not authors.restore(unknown)["ok"] and not authors.restore(duplicates)["ok"] and not authors.restore(fractional)["ok"] and authors.snapshot() == canonical,"unsupported_schema_duplicate_identity_and_fractional_counter_preserve_valid_memory")
	var collided := canonical.duplicate(true)
	collided["next_neighborhood_id"] = 1
	var collision_store := Neighborhoods.new()
	collision_store.restore(collided)
	var collision := collision_store.confirm(city,boundary,Array([east[1]],TYPE_STRING,"",null),"第三处")
	check(bool(collision["ok"]) and not canonical["neighborhoods"].any(func(item: Dictionary) -> bool: return item["id"] == collision["record"]["id"]),"restored_counter_cannot_reuse_an_existing_author_identity")

	var directory := ProjectSettings.globalize_path(OUTPUT.get_base_dir()+"/run_"+str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(directory)
	var captured := {"model":model.capture_state(),"renderer":renderer.snapshot(),"view":{"expression":"deep","zoom":1.0,"pan":Vector2(7,9)},"authorship":canonical}
	var saved := Archive.save(captured,"玩家街坊合同",directory)
	var loaded := Archive.read(str(saved.get("path",""))) if bool(saved.get("ok",false)) else saved
	var binary_store := Neighborhoods.new()
	var binary_ok := binary_store.restore(loaded.get("city",{}).get("authorship",{}))
	check(bool(saved["ok"]) and bool(loaded["ok"]) and bool(binary_ok["ok"]) and binary_store.snapshot() == canonical and loaded["city"]["model"] == captured["model"] and loaded["city"]["renderer"] == captured["renderer"],"actual_binary_city_roundtrip_preserves_authorship_and_complete_world_audio")
	var exported := Archive.export_dna(captured,directory+"/exports")
	var dna := Archive.read_dna(str(exported.get("path",""))) if bool(exported.get("ok",false)) else exported
	var dna_store := Neighborhoods.new()
	var dna_ok := dna_store.restore(dna.get("authorship",{}))
	check(bool(exported["ok"]) and bool(dna["ok"]) and bool(dna_ok["ok"]) and dna_store.snapshot() == canonical and dna["dna"]["runtime"]["authorship"] == dna["dna"]["authorship"],"actual_json_dna_roundtrip_uses_canonical_runtime_authorship")
	if not bool(dna.get("ok",false)): evidence["dna"] = dna; _finish(); return
	var restored_model := Model.from_state(dna["model"])
	var restored_renderer := Renderer.new(rate)
	restored_renderer.restore(dna["renderer"])
	restored_renderer.source = restored_model._mix_frame
	var original_copy := model.freeze()
	var original_renderer := Renderer.new(rate)
	original_renderer.restore(renderer.snapshot())
	original_renderer.source = original_copy._mix_frame
	var restored_pcm := restored_renderer.render(512)
	var saved_pcm := original_renderer.render(512)
	check(restored_pcm.to_byte_array() == saved_pcm.to_byte_array() and model.capture_state() == actual_before and authors.snapshot() == canonical,"json_resume_keeps_same_source_pcm_and_neighborhood_operations_never_change_live_audio")
	var legacy_city := captured.duplicate(true)
	legacy_city.erase("authorship")
	_city_fixture(directory+"/000000000000_0000000000000000.city",legacy_city)
	var legacy_binary := Archive.read(directory+"/000000000000_0000000000000000.city")
	var legacy_dna: Dictionary = dna["dna"].duplicate(true)
	legacy_dna.erase("authorship")
	legacy_dna["runtime"].erase("authorship")
	_json_fixture(directory+"/exports/000000000000_0000000000000000.dna.json",legacy_dna)
	var legacy_json := Archive.read_dna(directory+"/exports/000000000000_0000000000000000.dna.json")
	var empty := Neighborhoods.new().snapshot()
	check(bool(legacy_binary["ok"]) and bool(legacy_json["ok"]) and legacy_binary["city"]["authorship"] == empty and legacy_json["authorship"] == empty and legacy_binary["city"]["model"] == captured["model"],"legacy_binary_and_dna_without_author_field_restore_empty_without_claiming_cid_members")
	var invalid_city := captured.duplicate(true)
	invalid_city["authorship"] = unknown
	_city_fixture(directory+"/999999999999_0000000000000000.city",invalid_city)
	var invalid_dna: Dictionary = dna["dna"].duplicate(true)
	invalid_dna["authorship"] = unknown
	invalid_dna["runtime"]["authorship"] = unknown
	_json_fixture(directory+"/exports/999999999999_0000000000000000.dna.json",invalid_dna)
	var refused_binary := Archive.read(directory+"/999999999999_0000000000000000.city")
	var refused_json := Archive.read_dna(directory+"/exports/999999999999_0000000000000000.dna.json")
	check(not refused_binary["ok"] and not refused_json["ok"] and not Archive.save(invalid_city,"拒绝",directory)["ok"] and not Archive.export_dna(invalid_city,directory+"/exports")["ok"],"unknown_author_schema_is_rejected_at_binary_dna_read_and_write")
	var fallback := Archive.latest(directory)
	var dna_fallback := Archive.latest_dna(directory+"/exports")
	check(bool(fallback["ok"]) and bool(dna_fallback["ok"]) and fallback["skipped"] == 1 and dna_fallback["skipped"] == 1 and fallback["city"]["authorship"] == canonical and dna_fallback["authorship"] == canonical and FileAccess.file_exists(directory+"/999999999999_0000000000000000.city") and FileAccess.file_exists(directory+"/exports/999999999999_0000000000000000.dna.json"),"unsupported_latest_files_remain_and_prior_valid_authored_work_is_recovered")
	evidence = {"seed":"2026100900000062","selected_ids":expected,"new_real_house_id":born,"new_house_birth_frame":boundary,
		"authorship":canonical,"binary_path":saved.get("path",""),"dna_path":exported.get("path",""),"fixture_directory":directory,
		"selection_pcm_frames":reference_pcm.size(),"selection_pcm_sha256":Archive._digest(reference_pcm.to_byte_array()),
		"resumed_pcm_frames":restored_pcm.size(),"resumed_pcm_sha256":Archive._digest(restored_pcm.to_byte_array()),"driver":"Dummy"}
	model.close_background_settlement()
	_finish()
