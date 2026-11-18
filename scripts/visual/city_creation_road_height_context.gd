extends RefCounted
## One synchronous immutable height-query scope. Public queries stay unchanged.
const Boats=preload("res://scripts/world/city_creation_boathouse_plan.gd")
const Decks=preload("res://scripts/world/city_creation_tea_deck_plan.gd")
var city:RefCounted
var boats:Array
var decks:Array
func _init(source:RefCounted)->void:
	city=source;boats=Boats.all(city);decks=Decks.all(city)
	var key:Array=[city.revision,city._wish_epoch,city._road_heights.get_instance_id()]
	if city._ground_revision!=city.revision and city.get_meta("street_profiles_key",[])!=key:
		city._prepare_raw_height();city._road_heights.prepare(city);city.set_meta("street_profiles_key",key)
	if city._street_marker_revision!=city.revision:city._street_markers=city.Roundabouts.all(city.roads);city._street_marker_revision=city.revision
func height_at(at:Vector2,known_road_y:float=NAN)->float:
	for plan:Dictionary in boats:
		if Boats.contains(plan,at):return float(plan.top)
	for plan:Dictionary in decks:
		if Decks.contains(plan,at):return float(plan.top)
	for marker:Dictionary in city._street_markers:
		if at.distance_to(marker.center)<=marker.radius:return city._ground_terrain.raw_height_at(marker.center)+.075
	var road_y:float=known_road_y if not is_nan(known_road_y) else city._road_heights.height_at(at,NAN)
	return road_y if not is_nan(road_y) else float(city.street_height(at))
