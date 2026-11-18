extends RefCounted
## A prepared road surface needs no protected terrain grid. Off-road queries
## still prepare that complete grid and use the original terrain policy.
static func height(city:RefCounted,position:Vector2,known_road_y:float=NAN,visible_ground:RefCounted=null,frontages:Dictionary={})->float:
 var boat_y:float=preload("res://scripts/world/city_creation_boathouse_plan.gd").height(city,position)
 if not is_nan(boat_y):return boat_y
 var deck_y:float=city.TeaDeck.height(city,position)
 if not is_nan(deck_y):return deck_y
 var key:Array=[city.revision,city._wish_epoch,city._road_heights.get_instance_id()]
 if city._ground_revision!=city.revision and city.get_meta("street_profiles_key",[])!=key:
  city._prepare_raw_height();city._road_heights.prepare(city,frontages);city.set_meta("street_profiles_key",key)
 if city._street_marker_revision!=city.revision:city._street_markers=city.Roundabouts.all(city.roads);city._street_marker_revision=city.revision
 for marker:Dictionary in city._street_markers:
  if position.distance_to(marker.center)<=marker.radius:return city._ground_terrain.raw_height_at(marker.center)+.075
 var road_y:float=known_road_y if not is_nan(known_road_y) else city._road_heights.height_at(position,NAN)
 if not is_nan(road_y):return road_y
 if visible_ground==null and city._ground_revision!=city.revision:city.prepare_ground_height()
 var legacy:=.055+.185*(1.-smoothstep(-.05,.65,city.water_clearance(position)))
 var ground:RefCounted=city._ground_terrain if visible_ground==null else visible_ground
 if city.TerrainPolicy.enabled(city):return ground.height_at(position)+.075
 return maxf(ground.height_at(position)+.075,legacy)
