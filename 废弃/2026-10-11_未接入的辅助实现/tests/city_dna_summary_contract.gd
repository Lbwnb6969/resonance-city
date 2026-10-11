extends SceneTree
## The full DNA remains the restore source; this contract checks the small
## player-facing index embedded beside it.
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const SEED := "2026101000000084"
var failures: Array[String] = []

func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new(SEED,true,"river_valley")
	world.build_first_composition_starter()
	var opening := First.opportunities(world)
	var sound_position: Array = opening["seed_candidates"][0]["position"]
	var boundary := int(world.cfg["timing"]["phrase_frames"])
	var queued := world.request({"kind":"seed","position":sound_position,"midi":36,"expression":"deep","player_expression":true},boundary)
	check(bool(queued.get("accepted",false)),"authored_seed_is_accepted_before_export")
	world.settle(boundary)
	var model := Model.new(world)
	var directory := ProjectSettings.globalize_path("res://验证记录/_tmp_city_dna_summary")
	var result := Archive.export_dna({"model":model.capture_state(),"view":{}},directory)
	check(bool(result.get("ok",false)),"DNA_export_writes_with_summary")
	if bool(result.get("ok",false)):
		var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(result["path"])))
		var summary: Dictionary = payload.get("summary",{}) if payload is Dictionary else {}
		check(str(summary.get("schema","")) == "resonance_city_summary_v1","summary_has_stable_schema")
		check(str(summary.get("seed_hex","")) == SEED,"summary_preserves_seed")
		check(str(summary.get("terrain",{}).get("label","")) == "河谷","summary_names_actual_terrain")
		var progress: Dictionary = summary.get("progress",{})
		check(int(progress.get("buildings",0)) == world.buildings.size() and int(progress.get("active_communities",0)) == 3,"summary_counts_actual_city")
		var routes: Array = summary.get("authored_routes",[])
		check(routes.size() == 1 and str(routes[0].get("expression_label","")) == "深流" and int(routes[0].get("building_count",0)) >= 1 and not bool(routes[0].get("theme_active",false)),"summary_names_actual_authored_route_without_inventing_theme")
		check(not summary.get("lines",[]).is_empty() and str(summary["lines"][0]).contains("河谷"),"summary_has_readable_lines")
		var imported := Archive.read_dna(str(result["path"]))
		check(bool(imported.get("ok",false)) and imported.get("summary",{}).get("schema","") == "resonance_city_summary_v1","summary_does_not_break_DNA_restore_and_is_exposed_on_read")
		DirAccess.remove_absolute(str(result["path"]))
	DirAccess.remove_absolute(directory)
	print("CITY_DNA_SUMMARY ",JSON.stringify({"failures":failures,"buildings":world.buildings.size()}))
	quit(0 if failures.is_empty() else 1)
