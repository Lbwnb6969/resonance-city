extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Job = preload("res://scripts/world/world_settlement_job.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
 var city := World.new("2026100900000062")
 city.build_expanded_town()
 var phrase: int = city.cfg["timing"]["phrase_frames"]
 for index in range(1,72): city.settle(index*phrase)
 var samples: Array = []
 for repetition in range(2):
  var at := Time.get_ticks_usec()
  var snapshot := city.snapshot()
  var row := {"snapshot_ms":float(Time.get_ticks_usec()-at)/1000.0,"fields":{},"caches":{},"network":{}}
  for field in ["cfg","lots","roads","nodes","blocks","green_corridors","centers","communities","transit","transit_lines","transit_demand","functional_zones","public_sites","planning_reservations","landmarks","landmark_progress","pending_actions","buildings","pending","events","families","lifecycle"]:
   var value: Variant = city.get(field)
   at = Time.get_ticks_usec()
   var copy: Variant = value.duplicate(true)
   row["fields"][field] = {"ms":float(Time.get_ticks_usec()-at)/1000.0,"count":value.size()}
   assert(copy == value)
  for field in Job.WORLD_CACHE_FIELDS:
   var value: Variant = city.get(field)
   at = Time.get_ticks_usec()
   var copy: Variant = value.duplicate() if value is Dictionary else value
   row["caches"][field] = {"ms":float(Time.get_ticks_usec()-at)/1000.0,"count":value.size() if value is Dictionary else 0}
   assert(copy == value)
  for field in Job.NETWORK_CACHE_FIELDS:
   var value: Dictionary = city.network.get(field)
   at = Time.get_ticks_usec()
   var copy := value.duplicate()
   row["network"][field] = {"ms":float(Time.get_ticks_usec()-at)/1000.0,"count":value.size()}
   assert(copy == value)
  assert(snapshot["buildings"].size() == city.buildings.size())
  samples.append(row)
 var evidence := {"buildings":city.buildings.size(),"samples":samples}
 FileAccess.open("res://验证记录/连续河谷/第132轮_捕获分项.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
 print("CAPTURE_PROFILE ",JSON.stringify(evidence))
 quit()
