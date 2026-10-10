extends SceneTree
const Scene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
func _initialize() -> void: call_deferred("_run")
static func scenery_script() -> GDScript:
 var source := FileAccess.get_file_as_string("res://scripts/visual/valley_scenery.gd").replace("\r","")
 var body := "func sync"+source.get_slice("func sync",1)
 body = body.replace("\tvar city: ContinuousWorld", "\tprofile.clear()\n\tphase_at = Time.get_ticks_usec()\n\tvar city: ContinuousWorld")
 body = body.replace("\tvar traffic: Array", "\t_stamp(\"setup_ms\")\n\tvar traffic: Array")
 body = body.replace("\tfor key in props:", "\t_stamp(\"agents_access_ms\")\n\tfor key in props:")
 body = body.replace("\t\t\tvar movement := traveler.advance", "\t\t\tphase_at = Time.get_ticks_usec()\n\t\t\tvar movement := traveler.advance")
 body = body.replace("\t\t\tprop.visible = not movement.is_empty()", "\t\t\t_stamp(\"advance_ms\")\n\t\t\tprop.visible = not movement.is_empty()")
 body = body.replace("\t\tprop.position =", "\t\tphase_at = Time.get_ticks_usec()\n\t\tprop.position =")
 body += "\n\t\t_stamp(\"presentation_ms\")\n"
 var script := GDScript.new()
 script.source_code = ("extends \"res://scripts/visual/valley_scenery.gd\"\nvar profile: Dictionary = {}\nvar phase_at := 0\nfunc _stamp(label: String) -> void:\n var now := Time.get_ticks_usec()\n profile[label] = float(profile.get(label,0.0))+float(now-phase_at)/1000.0\n phase_at = now\n"+body).replace("\t"," ")
 assert(script.reload() == OK)
 return script
static func traveler_script() -> GDScript:
 var script := GDScript.new()
 script.source_code = "extends \"res://scripts/visual/city_traveler.gd\"\nvar profile: Dictionary = {}\nfunc _traffic_distance(city: ContinuousWorld,desired: float,traffic: Array,physical_access: Dictionary = {}) -> float:\n var tick := Time.get_ticks_usec()\n var value := super(city,desired,traffic,physical_access)\n profile[\"avoid_ms\"] = float(profile.get(\"avoid_ms\",0.0))+float(Time.get_ticks_usec()-tick)/1000.0\n return value\nfunc _sample(delta_seconds: float = 0.0) -> void:\n var tick := Time.get_ticks_usec()\n super(delta_seconds)\n profile[\"sample_ms\"] = float(profile.get(\"sample_ms\",0.0))+float(Time.get_ticks_usec()-tick)/1000.0\n"
 script.source_code += "func _junction_conflict(city: ContinuousWorld,current_access: Dictionary,other: Dictionary) -> bool:\n var tick := Time.get_ticks_usec()\n var value := super(city,current_access,other)\n profile[\"junction_ms\"] = float(profile.get(\"junction_ms\",0.0))+float(Time.get_ticks_usec()-tick)/1000.0\n return value\n"
 assert(script.reload() == OK)
 return script
func _run() -> void:
 var city := World.new()
 city.build_expanded_town()
 var phrase: int = city.cfg["timing"]["phrase_frames"]
 for i in range(1,72): city.settle(i*phrase)
 var demo: ContinuousValleyDemo = Scene.instantiate()
 demo.session_persistence = false
 root.add_child(demo)
 demo.clock.stop_output()
 demo.model.close_background_settlement()
 demo.set_process(false)
 demo.model = Model.new(city)
 demo.shown_world = city
 demo.clock.renderer.transport.audible_frame = 71*phrase
 demo._sync_buildings()
 demo.scenery = scenery_script().new()
 demo.scenery.rebuild(demo)
 var traveler_type := traveler_script()
 var travelers: Array = []
 for prop in demo.scenery.props.values():
  if not prop.has_meta("traveler"): continue
  var previous: CityTraveler = prop.get_meta("traveler")
  var traveler: CityTraveler = traveler_type.new(previous.kind,previous.ordinal)
  prop.set_meta("traveler",traveler)
  travelers.append(traveler)
 var samples: Array = []
 for i in range(1000):
  demo.clock.renderer.transport.audible_frame += 367.5
  var tick := Time.get_ticks_usec()
  demo.scenery.sync(demo)
  samples.append({"total_ms":float(Time.get_ticks_usec()-tick)/1000.0,"parts":demo.scenery.get("profile").duplicate()})
 var detail := {"avoid_ms":0.0,"sample_ms":0.0,"junction_ms":0.0}
 for traveler in travelers:
  for key in detail: detail[key] += float(traveler.get("profile").get(key,0.0))
 var result := {"topology_string_length":city.network.topology.length(),"traveler_detail":detail,"buildings":city.buildings.size(),"props":demo.scenery.props.size(),"travelers":demo.scenery.props.values().filter(func(prop: Node2D) -> bool: return prop.has_meta("traveler")).size(),"samples":samples}
 FileAccess.open("res://验证记录/连续河谷/第135轮_交通分项.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
 print("TRAFFIC_PROFILE ",JSON.stringify(result))
 demo.queue_free()
 await process_frame
 quit()
