extends RefCounted
## Only temporary surfaces may sample the last published protected ground.
## Current road profiles and platform priorities remain authoritative.
const Query=preload("res://scripts/world/city_creation_street_height_query.gd")
static func height(renderer:Node3D,at:Vector2)->float:
 var budget=renderer.budget_rebuild
 var city:RefCounted=renderer.state
 var ground:RefCounted=null
 if budget!=null and budget.published_ground_owner==[city.get_instance_id(),city._wish_epoch]:ground=budget.published_ground
 var frontages:Dictionary={}
 var key:Array=[city.revision,city._wish_epoch,city._road_heights.get_instance_id()]
 if city._ground_revision!=city.revision and city.get_meta("street_profiles_key",[])!=key:
  renderer.preview_junctions.copy_cache_from(city._junctions)
  frontages=renderer.preview_junctions.preview_frontages(city)
 return Query.height(city,at,NAN,ground,frontages)
static func key(renderer:Node3D)->Array:
 var budget=renderer.budget_rebuild
 return [renderer.state.get_instance_id(),renderer.state.revision,renderer.state._wish_epoch,budget.published_ground.get_instance_id() if budget!=null and budget.published_ground!=null else 0]
