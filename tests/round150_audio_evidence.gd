extends SceneTree
## Round 150: local, repeatable PCM evidence for the public-planning snapshot.
##
## This script deliberately stays on the production offline renderer.  It
## proves that all three public branches use one captured source/next-boundary
## snapshot, that a queued focus + retune pair takes effect on the next beat,
## and that the branch PCM has a measurable relation.  It does not claim a
## WASAPI device-clock or human-listening result.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Preview = preload("res://scripts/world/public_planning_preview.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")

const SEED := "2026101100000150"
const EVIDENCE_PATH := "res://验证记录/round150_音频证据/规划分支与下一拍.json"

var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func public_candidates(world: RefCounted, cid: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lot in world.lots:
		if not str(lot.get("occupant","")).is_empty() or str(lot.get("community_id","")) != cid: continue
		var candidate: Dictionary = world.planning_candidate(Vector2(float(lot["center"][0]),float(lot["center"][1])))
		if candidate.is_empty() or not bool(candidate.get("allowed",false)) or candidate.has("public_id"): continue
		if not Planning.public_access(world,candidate).is_empty(): result.append(candidate)
	return result

func pcm_samples(bytes: PackedByteArray) -> int:
	return bytes.size()/4

func pcm_peak(bytes: PackedByteArray) -> float:
	var peak := 0.0
	for offset in range(0,bytes.size(),2):
		var value := absf(float(bytes.decode_s16(offset)))/32767.0
		peak = maxf(peak,value)
	return peak

func pcm_rms(bytes: PackedByteArray) -> float:
	if bytes.is_empty(): return 0.0
	var total := 0.0
	for offset in range(0,bytes.size(),2):
		var value := float(bytes.decode_s16(offset))/32767.0
		total += value*value
	return sqrt(total/float(bytes.size()/2))

func pcm_difference(a: PackedByteArray,b: PackedByteArray) -> Dictionary:
	if a.size() != b.size() or a.is_empty(): return {"max_abs":INF,"mean_abs":INF,"samples":0}
	var peak := 0.0
	var total := 0.0
	var count := a.size()/2
	for offset in range(0,a.size(),2):
		var difference := absf(float(a.decode_s16(offset)-b.decode_s16(offset)))/32767.0
		peak = maxf(peak,difference)
		total += difference
	return {"max_abs":peak,"mean_abs":total/float(count),"samples":count}

func safe_value(value: Variant) -> Variant:
	if value is Vector2: return [value.x,value.y]
	if value is PackedVector2Array:
		var points: Array = []
		for point in value: points.append([point.x,point.y])
		return points
	if value is PackedByteArray:
		return {"bytes":value.size()}
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[str(key)] = safe_value(value[key])
		return result
	if value is Array:
		var array_result: Array = []
		for item in value: array_result.append(safe_value(item))
		return array_result
	return value

func write_evidence(payload: Dictionary) -> void:
	var path := ProjectSettings.globalize_path(EVIDENCE_PATH)
	var parent := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(parent)
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		failures.append("write evidence file: "+str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(safe_value(payload),"  "))
	file.close()

func _run() -> void:
	var world := World.new(SEED,true,"river_valley")
	world.build_starter("bright")
	var phrase := int(world.cfg["timing"]["phrase_frames"])
	for i in range(2): world.settle((world.phrase_index+1)*phrase)
	var candidates := public_candidates(world,"west-1")
	check(not candidates.is_empty(),"real road-accessible public candidate exists")
	if candidates.is_empty():
		print("ROUND150_AUDIO_EVIDENCE checks=",checks," failures=",JSON.stringify(failures))
		quit(1)
		return

	var rate := int(world.cfg["timing"]["sample_rate"])
	var source_frame := world.phrase_index*phrase
	var phases: Dictionary = {}
	var model := Model.new(world)
	model.render_block(phases,source_frame,64,rate)
	source_frame += 64
	var control_model := model
	var control_state := phases.duplicate(true)
	var building_id := str(world.communities["west-1"]["members"][0])
	var expected_beat := (model.rendered_until/model.beat_frames+1)*model.beat_frames
	var focus := control_model.submit({"kind":"focus","community":"west-1"})
	var retune := control_model.submit({"kind":"retune","id":building_id,"midi":52})
	var structural_before := control_model.world.snapshot()
	check(focus["accepted"] and retune["accepted"],"focus and retune queue from one planning snapshot")
	check(int(focus["sound_frame"]) == expected_beat and int(retune["sound_frame"]) == expected_beat,"focus and retune share the next writable beat")
	check(control_model.world.snapshot() == structural_before,"queued focus and retune leave structure unchanged before phrase boundary")
	check(control_model.synth.focused_community.is_empty() and not control_model.sound_overrides.has(building_id),"queued controls do not apply before next beat")

	var comparison := Preview.build(control_model.freeze(),candidates[0],control_state,source_frame)
	check(comparison.get("variants",{}).size() == 3,"one public snapshot carries three branch choices")
	var source_version: Array = comparison.get("source_version",[])
	var variants: Dictionary = comparison.get("variants",{})
	var branch_summaries: Dictionary = {}
	for kind: String in ["none","park","civic"]:
		var variant: Dictionary = variants.get(kind,{})
		var pcm: PackedByteArray = variant.get("pcm",PackedByteArray())
		var preview: Dictionary = variant.get("opportunity_preview",{})
		check(bool(variant.get("accepted",false)),kind+" branch accepted")
		check(pcm_samples(pcm) == rate*3,kind+" branch renders exactly three seconds")
		check(preview.get("source_version",[]) == source_version,kind+" branch retains source identity")
		check(int(preview.get("source_frame",-1)) == source_frame and int(preview.get("boundary_frame",-1)) == comparison.get("boundary_frame",-2),kind+" branch retains source/boundary frame")
		branch_summaries[kind] = {
			"accepted":bool(variant.get("accepted",false)),
			"pcm_bytes":pcm.size(),
			"pcm_samples":pcm_samples(pcm),
			"peak":pcm_peak(pcm),
			"rms":pcm_rms(pcm),
			"source_frame":int(preview.get("source_frame",-1)),
			"boundary_frame":int(preview.get("boundary_frame",-1)),
			"affected_communities":preview.get("affected_communities",[]),
			"rules":preview.get("rules",[]),
		}
	var none_pcm: PackedByteArray = variants["none"]["pcm"]
	var park_pcm: PackedByteArray = variants["park"]["pcm"]
	var civic_pcm: PackedByteArray = variants["civic"]["pcm"]
	var none_park := pcm_difference(none_pcm,park_pcm)
	var none_civic := pcm_difference(none_pcm,civic_pcm)
	var park_civic := pcm_difference(park_pcm,civic_pcm)
	check(float(none_park["max_abs"]) > 0.000001 or float(none_civic["max_abs"]) > 0.000001,"at least one public branch changes the offline PCM")
	check(float(park_civic["max_abs"]) > 0.000001,"park and civic branches remain acoustically distinguishable in offline PCM")

	# Advance only the control model to the exact beat. The preview above used a
	# frozen copy, so this proves the actionable controls still land on the live
	# next beat after previewing.
	control_model.render_block(control_state,model.rendered_until,expected_beat-model.rendered_until,rate)
	check(control_model.synth.focused_community.is_empty() and not control_model.sound_overrides.has(building_id),"controls remain pending one sample before queued beat")
	control_model.render_block(control_state,expected_beat,1,rate)
	check(control_model.synth.focused_community == "west-1" and int(control_model.sound_overrides.get(building_id,-1)) == 52,"focus and retune apply together at next beat")

	var evidence := {
		"contract":"ROUND150_AUDIO_EVIDENCE/v1",
		"seed":SEED,
		"sample_rate":rate,
		"seconds":3,
		"source_frame":source_frame,
		"boundary_frame":int(comparison.get("boundary_frame",-1)),
		"source_version":source_version,
		"candidate":{"source_site_id":str(candidates[0].get("source_site_id","")),"community_id":str(candidates[0].get("community_id","")),"position":candidates[0].get("position",[])},
		"branches":branch_summaries,
		"pairwise_pcm_difference":{"none_vs_park":none_park,"none_vs_civic":none_civic,"park_vs_civic":park_civic},
		"next_beat_controls":{"requested_at":model.rendered_until,"expected_beat":expected_beat,"focus_sound_frame":int(focus.get("sound_frame",-1)),"retune_sound_frame":int(retune.get("sound_frame",-1)),"focus_community":"west-1","retune_id":building_id,"retune_midi":52},
		"claims":{"equivalent_offline_pcm":"verified by the production ContinuousAudioModel and public_planning_preview path","same_snapshot":"verified by shared source_version/source_frame/boundary_frame","wasapi_device_clock":"not run","human_listening":"not claimed"},
	}
	write_evidence(evidence)
	print("ROUND150_AUDIO_EVIDENCE checks=",checks," source_frame=",source_frame," boundary_frame=",comparison.get("boundary_frame")," none_park_max=",none_park["max_abs"]," park_civic_max=",park_civic["max_abs"]," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
