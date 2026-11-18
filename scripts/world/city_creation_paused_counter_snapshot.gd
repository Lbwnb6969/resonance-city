extends RefCounted
## Only history_snapshot's serializer-owned runtime values enter this path.
## Public State.restore/file loading still validates every external snapshot.
static func restore(source:Dictionary)->RefCounted:
 var city:RefCounted=load("res://scripts/world/city_creation_state.gd").new()
 var data:Dictionary=source.duplicate(true)
 # Same application/migration and non-recursive accounting flag as before;
 # avoid validating a second time the State that produced this exact snapshot.
 data.cozy_progression.enabled=true
 city._apply_snapshot(data)
 city.revision=int(data.revision);city.dirty=false;city.life_progress_dirty=false
 return city
