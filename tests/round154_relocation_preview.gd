extends SceneTree
## P10 relocation preview contract.  This is a read-only planning proof: the
## future relocate_public transaction can reuse these fields without mutating
## the live city before a phrase boundary.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Relocation = preload("res://scripts/world/public_site_relocation.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _find_preview(city: World,site_id: String) -> Dictionary:
	# Public footprints are wider than one starter lot.  Scan a stable half-unit
	# lattice so the test searches real continuous space rather than inventing a
	# second placement rule.
	for y in range(1,71):
		for x in range(-30,31):
			var target := Vector2(float(x)*0.5,float(y)*0.5)
			var preview: Dictionary = city.public_site_relocation_preview(site_id,target)
			if bool(preview.get("accepted",false)): return preview
	return {}

func _run() -> void:
	var city := World.new()
	city.build_starter("bright")
	var source: Dictionary = {}
	for site in city.public_sites:
		if bool(site.get("active",false)) and str(site.get("kind", "")) == "civic":
			source = site
			break
	_check(not source.is_empty(),"finds_active_civic_site")
	if source.is_empty():
		_finish()
		return
	var source_id := str(source["id"])
	var source_position := Vector2(float(source["position"][0]),float(source["position"][1]))
	var same: Dictionary = city.public_site_relocation_preview(source_id,source_position)
	_check(not bool(same.get("accepted",false)),"same_position_is_not_a_relocation")
	var preview := _find_preview(city,source_id)
	_check(not preview.is_empty(),"finds_legal_target_with_real_entrance")
	if preview.is_empty():
		_finish()
		return
	_check(str(preview.get("source_site_id","")) == source_id,"preview_keeps_stable_source_id")
	_check(str(preview.get("source_revision","")) != "","preview_exposes_stale_guard_revision")
	_check(preview.get("source_position",[]) == source.get("position",[]),"preview_reports_source_position")
	_check(preview.get("source_entrance",[]) == source.get("entrance",[]),"preview_reports_source_entrance")
	_check(preview.get("target_polygon",PackedVector2Array()).size() == source.get("polygon",PackedVector2Array()).size(),"preview_preserves_footprint_shape")
	_check(preview.get("target_access_path",PackedVector2Array()).size() >= 2,"preview_reports_target_access_path")
	_check(not str(preview.get("road_id","" )).is_empty(),"preview_reports_target_road")
	_check(preview.get("covered_before",[]).size() == source.get("covered",[]).size(),"preview_reads_current_coverage")
	_check(preview.has("covered_after") and preview.has("served_before") and preview.has("served_after"),"preview_reports_service_impact")
	_check(preview.has("affected_communities") and preview.has("service_delta"),"preview_reports_community_service_delta")
	_check(city.public_sites.any(func(site: Dictionary)->bool:return str(site.get("id","")) == source_id and Vector2(float(site["position"][0]),float(site["position"][1])) == source_position),"preview_does_not_mutate_live_site")
	var direct: Dictionary = Relocation.preview(city,source_id,Vector2(float(preview["target_position"][0]),float(preview["target_position"][1])))
	_check(direct.get("source_revision","") == preview.get("source_revision",""),"world_wrapper_matches_read_only_module")
	var saved := city.snapshot()
	var restored := World.new()
	restored.restore(saved)
	var restored_preview: Dictionary = restored.public_site_relocation_preview(source_id,Vector2(float(preview["target_position"][0]),float(preview["target_position"][1])))
	_check(restored_preview.get("source_revision","") == preview.get("source_revision",""),"preview_revision_survives_city_snapshot")
	_check(restored_preview.get("target_polygon",PackedVector2Array()) == preview.get("target_polygon",PackedVector2Array()),"preview_geometry_survives_city_snapshot")
	var moving := World.new()
	moving.build_starter("bright")
	var moving_site: Dictionary = moving.public_sites.filter(func(item: Dictionary)->bool:return str(item.get("id","")) == source_id)[0]
	var move_model := Model.new(moving)
	var move_target := _find_preview(moving,source_id)
	_check(not move_target.is_empty(),"move_fixture_reuses_legal_target")
	if not move_target.is_empty():
		var operation := {"kind":"relocate_public","id":source_id,"target_position":move_target["target_position"],"source_revision":move_target["source_revision"]}
		var queued: Dictionary = move_model.submit(operation)
		_check(bool(queued.get("accepted",false)),"relocation_request_accepts_stable_preview")
		var boundary := move_model.next_boundary
		var rate := int(moving.cfg["timing"]["sample_rate"])
		move_model.render_block({},boundary-1,2,rate)
		var moved: Dictionary = moving.public_sites.filter(func(item: Dictionary)->bool:return str(item.get("id","")) == source_id)[0]
		_check(Vector2(float(moved["position"][0]),float(moved["position"][1])) == Vector2(float(move_target["target_position"][0]),float(move_target["target_position"][1])),"relocation_moves_same_stable_site_id")
		_check(str(moved.get("kind","")) == str(moving_site.get("kind","")) and int(moved.get("service_level",1)) == int(moving_site.get("service_level",1)),"relocation_preserves_facility_kind_and_level")
		_check(moving.events.any(func(event: Dictionary)->bool:return str(event.get("kind","")) == "relocate_public" and str(event.get("id","")) == source_id and event.has("covered_before") and event.has("covered_after") and event.has("served_before") and event.has("served_after")),"relocation_event_records_service_before_after")
	_finish()

func _finish() -> void:
	print("ROUND154_RELOCATION_PREVIEW ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
