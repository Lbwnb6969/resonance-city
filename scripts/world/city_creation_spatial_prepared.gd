extends RefCounted
## Pure spatial facts belong to the joined geometry worker, not the first UI draw.
static func needed(city:RefCounted)->bool:
	var geometry=preload("res://scripts/audio/city_creation_expression_geometry.gd")
	if geometry.needed(city) and city.get_meta("expression_geometry_prepared",{}).get("signature",-1)!=geometry.key(city):return true
	return city.CreationPolicy.is_free(city) and city.get_meta("functional_zones",{}).get("key",[])!=[city.revision,city.revision]
static func prepare(network:RefCounted)->void:
	var city:RefCounted=network.state
	if not city.CreationPolicy.is_free(city):return
	var began:=Time.get_ticks_usec()
	city.prepare_regional_echo(network)
	network.prepare_stats["regional_echo_ms"]=(Time.get_ticks_usec()-began)/1000.
	city.functional_zones()
	network.prepare_stats["lane_stages"]=city.get_meta("lane_contract_prepare_stats",{}).duplicate()
	network.prepare_stats["courtyard_stages"]=city.get_meta("courtyard_contract_prepare_stats",{}).duplicate()
	network.prepare_stats["spatial_stages"]=city.get_meta("functional_zone_prepare_stats",{}).duplicate()
	network.prepare_stats["spatial_ms"]=(Time.get_ticks_usec()-began)/1000.
	began=Time.get_ticks_usec()
	preload("res://scripts/world/city_creation_street_wonder_plan.gd").derive(city)
	network.prepare_stats["street_wonders_ms"]=(Time.get_ticks_usec()-began)/1000.
	began=Time.get_ticks_usec()
	preload("res://scripts/world/city_creation_water_lantern_plan.gd").prepare(city)
	network.prepare_stats["water_lanterns_ms"]=(Time.get_ticks_usec()-began)/1000.
	began=Time.get_ticks_usec()
	city.synergy_buffs()
	network.prepare_stats["planning_ms"]=(Time.get_ticks_usec()-began)/1000.
static func adopt(city:RefCounted,network:RefCounted)->void:
	preload("res://scripts/world/city_creation_paused_counter_history.gd").adopt(city,network)
	preload("res://scripts/audio/city_creation_expression_geometry.gd").adopt(city,network.state.get_meta("expression_geometry_prepared",{}))
	if not network.prepare_stats.has("planning_ms"):city._synergy_revision=-1
	if not network.prepare_stats.has("spatial_ms"):return
	var prepared:Dictionary=network.state.get_meta("functional_zones",{})
	if prepared.is_empty():return
	city.set_meta("functional_zones",{"key":[city.revision,city._region_network_revision],"value":prepared.value})
	# Regional publication invalidated the render worker's unconnected view.
	# This joined worker evaluated the actual street components and all links.
	if network.prepare_stats.has("planning_ms"):
		city._synergy_buffs=network.state._synergy_buffs;city._synergy_revision=city.revision
		city._natural_cluster_key=network.state._natural_cluster_key
		city._natural_cluster_rows=network.state._natural_cluster_rows
	var street:Dictionary=network.state.get_meta("street_wonder_plan",{}).duplicate()
	street.key=[city.revision,city._wish_epoch]
	city.set_meta("street_wonder_plan",street)
	city.set_meta("street_wonder_obstacles",network.state.get_meta("street_wonder_obstacles",{}))
	preload("res://scripts/world/city_creation_water_lantern_plan.gd").adopt(city,network.state)
