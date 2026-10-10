extends RefCounted
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const ARCHIVE := "res://废弃/scripts/2026-10-10_第133轮声音准备优化前/"
static func synth_script() -> GDScript:
 var source := FileAccess.get_file_as_string(ARCHIVE+"continuous_synth.gd.txt").replace("\r","")
 var update := "func update_city"+source.get_slice("func update_city",1).get_slice("func configure_score",0)
 # Bypass the new ContinuousSynth wrapper so the archived grouping runs once.
 update = update.replace("super(city,state,marks,events.filter", "_update_city_data(city.duplicate(true),state,marks,events.filter")
 var configure := "func configure_score"+source.get_slice("func configure_score",1).get_slice("func _audibility",0)
 var script := GDScript.new()
 script.source_code = ("extends \"res://scripts/audio/continuous_synth.gd\"\n"+update+configure).replace("\t"," ")
 assert(script.reload() == OK)
 return script
static func model_script() -> GDScript:
 var source := FileAccess.get_file_as_string(ARCHIVE+"continuous_audio_model.gd.txt").replace("\r","")
 var script := GDScript.new()
 script.source_code = ("extends \"res://scripts/audio/continuous_audio_model.gd\"\nfunc render_block"+source.get_slice("func render_block",1).get_slice("func presentation_world",0)).replace("\t"," ")
 assert(script.reload() == OK)
 return script
static func make(city: ContinuousWorld, gain: float = 1.3409036) -> ContinuousAudioModel:
 var model: ContinuousAudioModel = model_script().new(city,gain)
 var old := model.synth
 model.synth = synth_script().new(city.buildings)
 for property in old.get_script().get_script_property_list():
  model.synth.set(str(property["name"]),old.get(str(property["name"])))
 return model
