extends SceneTree
var evidence: Array = []
func _initialize() -> void: call_deferred("_run")
static func instrumented_synth() -> GDScript:
 var source := FileAccess.get_file_as_string("res://scripts/audio/continuous_synth.gd").replace("\r","")
 var method := "func render_block"+source.get_slice("func render_block",1).get_slice("func score_snapshot",0)
 method = method.replace("\tvar output := PackedVector2Array()","\tvar phase_started := Time.get_ticks_usec()\n\tvar output := PackedVector2Array()")
 var sort_begin := "\tif pad_candidates ==" if source.contains("pad_priority_input") else "\tpad_candidates.sort_custom"
 method = method.replace(sort_begin,"\tstages[\"candidate_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n\tphase_started = Time.get_ticks_usec()\n"+sort_begin)
 method = method.replace("\tfor key in pad_groups:\n\t\tvar group: Dictionary = pad_groups[key]\n\t\tvar target", "\tstages[\"sort_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n\tphase_started = Time.get_ticks_usec()\n\tfor key in pad_groups:\n\t\tvar group: Dictionary = pad_groups[key]\n\t\tvar target")
 method = method.replace("\tif not native_keys.is_empty():", "\tstages[\"control_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n\tphase_started = Time.get_ticks_usec()\n\tif not native_keys.is_empty():")
 method = method.replace("\tfor key in retired:", "\tstages[\"native_state_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n\tfor key in retired:")
 method = method.replace("\tvar retiring_rhythms:", "\tstages[\"pads_ms\"] = float(stages[\"candidate_ms\"])+float(stages[\"sort_ms\"])+float(stages[\"control_ms\"])+float(stages[\"native_state_ms\"])\n\tphase_started = Time.get_ticks_usec()\n\tvar retiring_rhythms:")
 method = method.replace("\tif duck_release_at", "\tstages[\"rhythms_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n\tphase_started = Time.get_ticks_usec()\n\tif duck_release_at")
 method = method.replace("\tlast_voice_count =", "\tstages[\"musical_ms\"] = float(Time.get_ticks_usec()-phase_started)/1000.0\n\tlast_voice_count =")
 var script := GDScript.new()
 var updates := ""
 for name in ["update_audio_city","_update_pad_groups","_apply_prepared_pad_groups","configure_score","_sync_rhythm_nodes","_sync_musical_nodes","_rebuild_assist_neighbors"]:
  var header: String = source.get_slice("func "+name,1).get_slice("\n",0)
  var args := "city,state,marks,events,preparation" if name == "update_audio_city" else ("preparation,state" if name == "_apply_prepared_pad_groups" else ("city,state" if name == "_update_pad_groups" else ("world,overrides" if name == "configure_score" else ("city" if name == "_rebuild_assist_neighbors" else ""))))
  updates += "func "+name+header+"\n\tvar began := Time.get_ticks_usec()\n\tsuper."+name+"("+args+")\n\tstages[\""+name+"_ms\"] = float(Time.get_ticks_usec()-began)/1000.0\n"
 script.source_code = "extends ContinuousSynth\nvar stages: Dictionary = {}\n"+method+updates
 assert(script.reload() == OK)
 return script
static func instrumented_model() -> GDScript:
 var source := FileAccess.get_file_as_string("res://scripts/audio/continuous_audio_model.gd").replace("\r","")
 var method := "func render_block"+source.get_slice("func render_block",1).get_slice("func presentation_world",0)
 method = method.replace("\tvar started_us := Time.get_ticks_usec()","\tstages = {}\n\tvar started_us := Time.get_ticks_usec()")
 method = method.replace("\t\tif changed:\n","\t\tif changed:\n\t\t\tvar change_started := Time.get_ticks_usec()\n")
 method = method.replace("\t\t\tsynth.set_gray(bool(world.lifecycle[\"gray\"]),at)","\t\t\tsynth.set_gray(bool(world.lifecycle[\"gray\"]),at)\n\t\t\tstages[\"city_score_update_ms\"] = float(Time.get_ticks_usec()-change_started)/1000.0")
 method = method.replace("\t\tvar block := synth.render_block", "\t\tvar synth_started := Time.get_ticks_usec()\n\t\tvar block := synth.render_block")
 method = method.replace("\t\tvar bed_gain :=", "\t\tstages[\"synth_ms\"] = float(stages.get(\"synth_ms\",0.0))+float(Time.get_ticks_usec()-synth_started)/1000.0\n\t\tvar bus_started := Time.get_ticks_usec()\n\t\tvar bed_gain :=")
 method = method.replace("\t\toutput.append_array(block)","\t\tstages[\"bed_seam_duck_ms\"] = float(stages.get(\"bed_seam_duck_ms\",0.0))+float(Time.get_ticks_usec()-bus_started)/1000.0\n\t\toutput.append_array(block)")
 var script := GDScript.new()
 script.source_code = "extends ContinuousAudioModel\nvar stages: Dictionary = {}\n"+method
 assert(script.reload() == OK)
 return script
func _case(city: ContinuousWorld,label: String) -> void:
 var model: ContinuousAudioModel = instrumented_model().new(city,1.3409036)
 var old := model.synth
 model.synth = instrumented_synth().new(city.buildings)
 for property in old.get_script().get_script_property_list():
  model.synth.set(str(property["name"]),old.get(str(property["name"])))
 var state: Dictionary = {}
 var start := city.phrase_index*model.phrase_frames
 for i in range(64): model.render_block(state,start+i*1024,1024,22050)
 var samples: Array = []
 for i in range(12):
  var begin := Time.get_ticks_usec()
  model.render_block(state,start+(64+i)*1024,1024,22050)
  samples.append({"total_ms":float(Time.get_ticks_usec()-begin)/1000.0,"model":model.get("stages").duplicate(),"synth":model.synth.get("stages").duplicate()})
 model.enable_background_settlement()
 model.prepare_settlement(model.next_boundary-22050,22050)
 while not model.settlement_job.completed(): await process_frame
 model.prepare_settlement(model.next_boundary-22050,22050)
 var begin := Time.get_ticks_usec()
 model.render_block(state,model.next_boundary-512,1024,22050)
 evidence.append({"label":label,"buildings":city.buildings.size(),"steady_samples":samples,"boundary_ms":float(Time.get_ticks_usec()-begin)/1000.0,"boundary_model":model.get("stages").duplicate(),"boundary_synth":model.synth.get("stages").duplicate(),"voice_budget":model.synth.max_voice_count,"scope":"Isolated 1024-frame kernel costs; cursor jumps before prepared real settlement; not real-time FPS"})
 model.close_background_settlement()
func _run() -> void:
 var small := ContinuousWorld.new()
 small.build_starter("bright")
 await _case(small,"starter18")
 await _case(ContinuousWorld.regional_sample(),"regional1511")
 FileAccess.open("res://验证记录/连续河谷/第140轮_供音分项.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
 print("AUDIO_PROFILE ",JSON.stringify(evidence))
 quit()
