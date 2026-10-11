extends SceneTree
## Playable expanded-town entry: public rhythm activity follows actual PCM and its
## returned metadata cannot mutate the runtime cache or saved musical state.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const OUT := "res://验证记录/round175_公共经营接续/public_activity_identity.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _run() -> void:
	var world := World.new("2026101000000071",true,"river_valley")
	world.build_expanded_town()
	var base := Model.new(world,1.0)
	var at := world.phrase_index*base.phrase_frames
	var state: Dictionary = {}
	base.render_block(state,at,64,22050)
	var saved := base.capture_state()
	var captured := Model.from_state(saved)
	var silent := Model.from_state(saved)
	captured.enable_music_activity()
	check(captured.synth.rhythms.any(func(part: Dictionary) -> bool:return bool(part.get("facility",false))),"playable_expanded_town_has_real_public_rhythm_slot")
	var captured_state := state.duplicate(true)
	var silent_state := state.duplicate(true)
	var probe := -1
	var pulse: Dictionary = {}
	var exact_pcm := true
	var finish := captured.rendered_until+22050*3
	while captured.rendered_until < finish:
		at = captured.rendered_until
		var count := mini(777,finish-at)
		var a := captured.render_block(captured_state,at,count,22050)
		var b := silent.render_block(silent_state,at,count,22050)
		exact_pcm = exact_pcm and a.to_byte_array() == b.to_byte_array()
		if pulse.is_empty():
			for row in captured.audible_public_activity(at+count-1):
				if float(row["strength"]) > 0.0001:
					probe = at+count-1
					pulse = row.duplicate(true)
					break
	check(exact_pcm and captured_state == silent_state,"public_activity_collection_keeps_pcm_and_phase_exact")
	check(captured.capture_state() == silent.capture_state(),"public_activity_collection_adds_no_saved_state")
	check(not pulse.is_empty(),"public_rhythm_has_actual_rendered_audible_contribution")
	if not pulse.is_empty():
		var identities_are_real := true
		for index in range(pulse["public_site_ids"].size()):
			var sites: Array = world.public_sites.filter(func(site: Dictionary) -> bool:return str(site["id"]) == str(pulse["public_site_ids"][index]) and bool(site["active"]))
			identities_are_real = identities_are_real and not sites.is_empty() and str(sites[0]["kind"]) == str(pulse["public_site_kinds"][index])
		check(identities_are_real,"public_pulse_ids_and_kinds_match_active_real_facilities")
		var rows := captured.audible_public_activity(probe)
		var before := rows.duplicate(true)
		rows[0]["public_site_ids"].clear()
		rows[0]["public_site_kinds"].clear()
		check(captured.audible_public_activity(probe) == before,"public_pulse_query_returns_independent_facility_arrays")
	check(captured.audible_public_activity(captured.rendered_until).is_empty(),"public_pulse_never_reports_unrendered_device_frame")
	var restored := Model.from_state(captured.capture_state())
	restored.enable_music_activity()
	check(restored.audible_public_activity(probe).is_empty() and restored.public_activity.segments.is_empty(),"restored_work_has_no_old_public_activity")
	check(captured.public_activity.segments.size() <= 512 and captured.synth.last_voice_count <= 70,"public_activity_keeps_bounded_cache_and_voice_budget")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"pulse":pulse,"scope":"Production playable expanded-town entry with 777-frame chunks; exact same-chunk PCM/phases/save state and read-only actual public activity. No device or human listening claim"}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	FileAccess.open(OUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND175_PUBLIC_ACTIVITY_IDENTITY ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
