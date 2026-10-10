extends SceneTree
var checks: Dictionary = {}
var cases: Array = []
var max_error := 0.0
static func reference_script() -> GDScript:
 var old := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第139轮声部分配优化前/continuous_synth.gd.txt").replace("\r","")
 var method := "func render_block"+old.get_slice("func render_block",1).get_slice("func score_snapshot",0)
 var script := GDScript.new()
 script.source_code = "extends ContinuousSynth\n"+method
 assert(script.reload() == OK)
 return script
static func reference_model(city: ContinuousWorld) -> ContinuousAudioModel:
 var model := ContinuousAudioModel.new(city,1.3409036)
 var old := model.synth
 model.synth = reference_script().new(city.buildings)
 for property in old.get_script().get_script_property_list():
  model.synth.set(str(property["name"]),old.get(str(property["name"])))
 return model
func _initialize() -> void: call_deferred("_run")
func _pcm(a: ContinuousAudioModel,b: ContinuousAudioModel,state: Dictionary,other: Dictionary,at: int,count: int,label: String) -> void:
 var left := a.render_block(state,at,count,22050)
 var right := b.render_block(other,at,count,22050)
 var delta := 0.0
 for i in range(count): delta = maxf(delta,left[i].distance_to(right[i]))
 max_error = maxf(max_error,delta)
 checks[label+" PCM"] = delta == 0.0
 checks[label+" state"] = state == other
 checks[label+" voices"] = a.synth.voice_group_stats == b.synth.voice_group_stats and a.synth.max_voice_count <= 70
func _prepare(model: ContinuousAudioModel) -> void:
 model.enable_background_settlement()
 model.prepare_settlement(model.next_boundary-22050,22050)
 while not model.settlement_job.completed(): await process_frame
 model.prepare_settlement(model.next_boundary-22050,22050)
func _case(city: ContinuousWorld,label: String) -> void:
 var copy := city.fork()
 copy.communities = city.communities.duplicate(true)
 var a := ContinuousAudioModel.new(city,1.3409036)
 var b := reference_model(copy)
 var state: Dictionary = {}
 var other: Dictionary = {}
 var start := city.phrase_index*a.phrase_frames
 for i in range(8): _pcm(a,b,state,other,start+i*1024,1024,label+" ramp "+str(i))
 for model in [a,b]:
  model.submit({"kind":"solo","community":city.buildings[0]["community_id"]})
  model.submit({"kind":"mute","community":city.buildings[-1]["community_id"],"enabled":true})
  model.submit({"kind":"retune","id":city.buildings[0]["district_id"],"midi":55})
 var beat: int = a.sound_events[0]["sound_frame"]
 _pcm(a,b,state,other,beat-256,1024,label+" input boundary")
 await _prepare(a)
 await _prepare(b)
 var boundary := a.next_boundary
 _pcm(a,b,state,other,boundary-256,1024,label+" real growth")
 checks[label+" world"] = a.world.snapshot() == b.world.snapshot()
 checks[label+" DNA"] = a.capture_state() == b.capture_state()
 var frozen := a.freeze()
 var original := b.freeze()
 original.synth = _copy_reference(original.synth)
 _pcm(frozen,original,state.duplicate(true),other.duplicate(true),boundary+768,512,label+" preview")
 var saved := a.capture_state()
 var restored := ContinuousAudioModel.from_state(saved)
 _pcm(a,restored,state,state.duplicate(true),boundary+768,512,label+" resume")
 b.render_block(other,boundary+768,512,22050)
 # Tight approximate ties, inactive tails and differing initial state/group levels.
 var index := 0
 for key in a.synth.pad_groups:
  for model in [a,b]:
   var group: Dictionary = model.synth.pad_groups[key]
   group["active"] = index%5 != 0
   group["level"] = float(index%7)*0.00001
   group["stereo"] = Vector2(0.92,0.12)
  var value := 0.02+float(index%3)*0.00000001
  state["_pad_level_"+key] = value
  other["_pad_level_"+key] = value
  index += 1
 # Resynchronize remaining state after the independent resume check.
 other = state.duplicate(true)
 for backend in [true,false]:
  a.synth.native_enabled = backend
  b.synth.native_enabled = backend
  for i in range(3): _pcm(a,b,state,other,boundary+1280+i*128,128,label+" ties "+str(backend)+" "+str(i))
 # Repeat identical priority inputs while oscillator phases continue.
 a.synth.native_enabled = true
 b.synth.native_enabled = true
 for key in a.synth.pad_groups:
  state["_pad_level_"+key] = 0.02
  other["_pad_level_"+key] = 0.02
 _pcm(a,b,state,other,boundary+2048,128,label+" cache warm")
 var sorts := a.synth.pad_priority_sorts
 for key in a.synth.pad_groups:
  state["_pad_level_"+key] = 0.02
  other["_pad_level_"+key] = 0.02
 _pcm(a,b,state,other,boundary+2176,128,label+" cache reuse")
 checks[label+" exact priorities reuse sort"] = a.synth.pad_priority_sorts == sorts
 var reordered: Dictionary = {}
 var keys: Array = a.synth.pad_groups.keys()
 keys.reverse()
 for key in keys: reordered[key] = a.synth.pad_groups[key]
 a.synth.pad_groups = reordered
 reordered = {}
 for key in keys: reordered[key] = b.synth.pad_groups[key]
 b.synth.pad_groups = reordered
 _pcm(a,b,state,other,boundary+2304,128,label+" insertion order")
 checks[label+" changed input order invalidates"] = a.synth.pad_priority_sorts > sorts
 checks[label+" cache excluded from DNA"] = a.capture_state() == b.capture_state()
 cases.append({"label":label,"before":index,"buildings":city.buildings.size(),"voices":a.synth.max_voice_count})
 for model in [a,b,frozen,original,restored]: model.close_background_settlement()
static func _copy_reference(old: ContinuousSynth) -> ContinuousSynth:
 var fresh: ContinuousSynth = reference_script().new(old.districts)
 for property in old.get_script().get_script_property_list():
  fresh.set(str(property["name"]),old.get(str(property["name"])))
 return fresh
func _run() -> void:
 var bright := ContinuousWorld.new()
 bright.build_starter("bright")
 await _case(bright,"bright18")
 var deep := ContinuousWorld.new()
 deep.build_starter("deep")
 await _case(deep,"deep18")
 await _case(ContinuousWorld.regional_sample(),"regional1511")
 var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"cases":cases,"max_pcm_error":max_error,"synth_sha256":FileAccess.get_sha256("res://scripts/audio/continuous_synth.gd")}
 FileAccess.open("res://验证记录/连续河谷/第139轮_声部优先级等价.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
 print("VOICE_PRIORITY ",JSON.stringify(result))
 quit(0 if result["passed"] else 1)
