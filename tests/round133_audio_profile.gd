extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
var evidence: Dictionary = {}
func _initialize() -> void: call_deferred("_run")
static func synth_script(optimized: bool) -> GDScript:
 var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第133轮声音准备优化前/continuous_synth.gd.txt").replace("\r","")
 var body := "func render_block"+source.get_slice("func render_block",1).get_slice("func score_snapshot",0)
 body = body.replace("\tvar output := PackedVector2Array()","\tprofile.clear()\n\tphase_at = Time.get_ticks_usec()\n\tvar output := PackedVector2Array()")
 body = body.replace("\tfor key in pad_groups:\n\t\tvar group: Dictionary = pad_groups[key]\n\t\tvar target", "\t_stamp(\"selection_ms\")\n\tfor key in pad_groups:\n\t\tvar group: Dictionary = pad_groups[key]\n\t\tvar target")
 body = body.replace("\tif not native_keys.is_empty():","\t_stamp(\"packets_virtual_ms\")\n\tif not native_keys.is_empty():")
 body = body.replace("\t\tnative_controls = mixed[1]", "\t\tnative_controls = mixed[1]\n\t\t_stamp(\"native_pcm_ms\")")
 body = body.replace("\tfor key in retired: pad_groups.erase(key)", "\t_stamp(\"pad_state_ms\")\n\tfor key in retired: pad_groups.erase(key)")
 body = body.replace("\tif duck_release_at >= 0", "\t_stamp(\"rhythms_ms\")\n\tif duck_release_at >= 0")
 body = body.replace("\tlast_voice_count =", "\t_stamp(\"musical_ms\")\n\tlast_voice_count =")
 var script := GDScript.new()
 script.source_code = ("extends \"res://scripts/audio/continuous_synth.gd\"\n" if optimized else preload("res://tests/round133_audio_reference.gd").synth_script().source_code)+"\nvar profile: Dictionary = {}\nvar phase_at := 0\nfunc _stamp(label: String) -> void:\n var now := Time.get_ticks_usec()\n profile[label] = float(profile.get(label,0.0))+float(now-phase_at)/1000.0\n phase_at = now\n"+body
 script.source_code = script.source_code.replace("\t"," ")
 assert(script.reload() == OK)
 return script
static func model_script(optimized: bool) -> GDScript:
 var source := FileAccess.get_file_as_string("res://scripts/audio/continuous_audio_model.gd" if optimized else "res://废弃/scripts/2026-10-10_第133轮声音准备优化前/continuous_audio_model.gd.txt").replace("\r","")
 var body := "func render_block"+source.get_slice("func render_block",1).get_slice("func presentation_world",0)
 body = body.replace("\tvar started_us := Time.get_ticks_usec()", "\tvar started_us := Time.get_ticks_usec()\n\tprofile.clear()\n\tphase_at = started_us")
 body = body.replace("\t\tif changed:", "\t\t_stamp(\"commit_events_ms\")\n\t\tif changed:")
 if optimized: body = body.replace("synth.update_audio_city(_owned_audio_city(),state,{},recent)","synth.update_city(audio_city(),state,{},recent)")
 body = body.replace("\t\t\tsynth.update_city(audio_city(),state,{},recent)", "\t\t\tvar city := audio_city()\n\t\t\t_stamp(\"audio_city_ms\")\n\t\t\tsynth.update_city(city,state,{},recent)\n\t\t\t_stamp(\"city_update_ms\")")
 body = body.replace("\t\t\tsynth.configure_score(world,sound_overrides)", "\t\t\t_stamp(\"era_sync_ms\")\n\t\t\tsynth.configure_score(world,sound_overrides)\n\t\t\t_stamp(\"score_ms\")")
 body = body.replace("\t\tvar block := synth.render_block", "\t\t_stamp(\"control_ms\")\n\t\tvar block := synth.render_block")
 body = body.replace("\t\tvar bed_gain :=", "\t\t_stamp(\"synth_ms\")\n\t\tvar bed_gain :=")
 body = body.replace("\t\tat += amount", "\t\tat += amount\n\t\t_stamp(\"post_pcm_ms\")")
 if optimized: body = body.replace("var city := audio_city()","var city := _owned_audio_city()").replace("synth.update_city(city,state,{},recent)","synth.update_audio_city(city,state,{},recent)")
 var script := GDScript.new()
 script.source_code = "extends \"res://scripts/audio/continuous_audio_model.gd\"\nvar profile: Dictionary = {}\nvar phase_at := 0\nfunc _stamp(label: String) -> void:\n var now := Time.get_ticks_usec()\n profile[label] = float(profile.get(label,0.0))+float(now-phase_at)/1000.0\n phase_at = now\n"+body
 script.source_code = script.source_code.replace("\t"," ")
 assert(script.reload() == OK)
 return script
func _run() -> void:
 var samples: Array = []
 for optimized in [false,true]: samples.append(await _measure(optimized))
 evidence = {"samples":samples}
 FileAccess.open("res://验证记录/连续河谷/第133轮_声音分项_AB.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
 print("AUDIO_PROFILE ",JSON.stringify(evidence))
 quit()
func _measure(optimized: bool) -> Dictionary:
 var city := World.new()
 city.build_expanded_town()
 var phrase: int = city.cfg["timing"]["phrase_frames"]
 var rate: int = city.cfg["timing"]["sample_rate"]
 for i in range(1,72): city.settle(i*phrase)
 var model: ContinuousAudioModel = model_script(optimized).new(city,1.3409036)
 var original := model.synth
 model.synth = synth_script(optimized).new(city.buildings)
 for property in original.get_script().get_script_property_list():
  model.synth.set(str(property["name"]),original.get(str(property["name"])))
 var state: Dictionary = {}
 var samples: Array = []
 var at := 72*phrase-22050
 model.render_block(state,at,4096,rate)
 at += 4096
 for i in range(3):
  var tick := Time.get_ticks_usec()
  model.render_block(state,at,512,rate)
  samples.append({"kind":"steady","total_ms":float(Time.get_ticks_usec()-tick)/1000.0,"model":model.get("profile").duplicate(),"synth":model.synth.get("profile").duplicate()})
  at += 512
 model.enable_background_settlement()
 model.prepare_settlement(72*phrase-22050,rate)
 while not model.settlement_job.completed(): await process_frame
 model.prepare_settlement(72*phrase-22050,rate)
 var tick := Time.get_ticks_usec()
 model.render_block(state,72*phrase,512,rate)
 samples.append({"kind":"growth","total_ms":float(Time.get_ticks_usec()-tick)/1000.0,"model":model.get("profile").duplicate(),"synth":model.synth.get("profile").duplicate()})
 var result := {"optimized":optimized,"buildings":city.buildings.size(),"samples":samples,"max_voices":model.synth.max_voice_count}
 model.close_background_settlement()
 return result
