extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Reference = preload("res://tests/round133_audio_reference.gd")
const Job = preload("res://scripts/world/world_settlement_job.gd")
var checks: Dictionary = {}
var cases: Array = []
var max_pcm_error := 0.0
func _initialize() -> void: call_deferred("_run")
func _prepare(model: ContinuousAudioModel) -> void:
 model.enable_background_settlement()
 model.prepare_settlement(model.next_boundary-22050,22050)
 while not model.settlement_job.completed(): await process_frame
 model.prepare_settlement(model.next_boundary-22050,22050)
func _pcm(a: ContinuousAudioModel,b: ContinuousAudioModel,state: Dictionary,other: Dictionary,at: int,count: int,label: String) -> void:
 var left := a.render_block(state,at,count,22050)
 var right := b.render_block(other,at,count,22050)
 var error := 0.0
 for i in range(count): error = maxf(error,left[i].distance_to(right[i]))
 max_pcm_error = maxf(max_pcm_error,error)
 checks[label+"_pcm"] = error == 0.0 and state == other
func _pair(city: ContinuousWorld,label: String,late: String = "") -> void:
 var copy := city.fork()
 copy.communities = city.communities.duplicate(true)
 var a := Model.new(city,1.3409036)
 var b := Reference.make(copy)
 var state: Dictionary = {}
 var other: Dictionary = {}
 var at := a.next_boundary
 for model in [a,b]:
  model.rendered_until = at-2*model.beat_frames
  model.submit({"kind":"retune","id":city.buildings[0]["district_id"],"midi":55})
 await _prepare(a)
 await _prepare(b)
 for model in [a,b]:
  if late == "retune": model.submit({"kind":"retune","id":city.buildings[0]["district_id"],"midi":43})
  elif late == "flow": model.world.record_transit_flow("west-2",5,3,1)
  elif late == "cancel": model.cancel_pending()
 _pcm(a,b,state,other,at-512,1024,label)
 checks[label+"_world"] = a.world.snapshot() == b.world.snapshot()
 checks[label+"_score_routes"] = a.synth.score_snapshot() == b.synth.score_snapshot() and a.synth.stage_snapshot() == b.synth.stage_snapshot() and a.synth.era_snapshot() == b.synth.era_snapshot()
 var saved := a.capture_state()
 checks[label+"_dna"] = saved == b.capture_state() and not saved.has("prepared_audio_buildings")
 checks[label+"_adoption"] = a.settlement_stats["adopted"] == (1 if late.is_empty() else 0) and (a.prepared_audio_phrase == a.world.phrase_index if late.is_empty() else a.prepared_audio_phrase == -1)
 checks[label+"_old_view"] = a.presentation_world(at-1).snapshot() == b.presentation_world(at-1).snapshot()
 var restored := Model.from_state(saved)
 var resumed_state := state.duplicate(true)
 _pcm(a,restored,state,resumed_state,at+512,512,label+"_resume")
 b.render_block(other,at+512,512,22050)
 for model in [a,b]:
  model.submit({"kind":"retune","id":city.buildings[0]["district_id"],"midi":50})
  model.submit({"kind":"solo","community":city.buildings[0]["community_id"]})
  model.submit({"kind":"mute","community":city.buildings[-1]["community_id"],"enabled":true})
 var beat := int(a.sound_events[0]["sound_frame"])
 _pcm(a,b,state,other,beat-256,512,label+"_later_input")
 checks[label+"_later_dna"] = a.capture_state() == b.capture_state()
 if late.is_empty():
  var base_hash := hash(a.prepared_audio_buildings)
  var projection := a.audio_city()
  projection[0]["position"][0] = -1234.0
  projection[0]["current_midi"] = -1234
  checks[label+"_public_copy"] = hash(a.prepared_audio_buildings) == base_hash and city.buildings[0]["current_midi"] != -1234 and city.buildings[0]["position"][0] != -1234.0
  var owned := a._owned_audio_city()
  checks[label+"_override_copy"] = hash(a.prepared_audio_buildings) == base_hash and owned[0]["current_midi"] == 50 and a.prepared_audio_buildings[0]["current_midi"] != 50
 var frozen := a.freeze()
 var old_frozen := b.freeze()
 _pcm(frozen,old_frozen,state.duplicate(true),other.duplicate(true),beat+256,512,label+"_preview")
 cases.append({"name":label,"buildings":city.buildings.size(),"voices":a.synth.max_voice_count,"adopted":a.settlement_stats["adopted"]})
 for model in [a,b,restored,frozen,old_frozen]: model.close_background_settlement()
func _ownership() -> void:
 var city := World.new()
 city.build_starter("bright")
 var job := Job.new()
 job.start(city,[],int(city.cfg["timing"]["phrase_frames"]))
 while not job.completed(): await process_frame
 job.join()
 var payload := job.audio_buildings
 var before := payload.duplicate(true)
 job.result.buildings[0]["position"][0] = -777.0
 checks["worker_projection_independent"] = payload == before
 job.retire()
 while not job.completed(): await process_frame
 job.join()
 checks["retirement_preserves_published_projection"] = payload == before and job.audio_buildings.is_empty()
 var synth := ContinuousSynth.new(city.buildings)
 var input: Array = city.buildings.duplicate(true)
 synth.update_city(input,{})
 input[0]["position"][0] = -555.0
 checks["public_update_retains_owned_copy"] = synth.districts[0]["position"][0] != -555.0
func _run() -> void:
 for family in ValleyTerrain.family_ids():
  var city := World.new("2026100900000062",true,family)
  city.build_starter("bright")
  await _pair(city,family)
 for late in ["retune","flow","cancel"]:
  var city := World.new()
  city.build_starter("bright")
  await _pair(city,"late_"+late,late)
 var large := World.new()
 large.build_expanded_town()
 var phrase: int = large.cfg["timing"]["phrase_frames"]
 for i in range(1,72): large.settle(i*phrase)
 await _pair(large,"large676")
 await _ownership()
 var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"cases":cases,"max_pcm_error":max_pcm_error}
 FileAccess.open("res://验证记录/连续河谷/第133轮_声音准备等价.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
 print("AUDIO_PREPARATION ",JSON.stringify(result))
 quit(0 if result["passed"] else 1)
