extends RefCounted
## Retain every off-period geometry until its exact counters have been merged.
## History snapshots stay cheap; public snapshots remain complete and read-only.
const Epoch=preload("res://scripts/world/city_creation_epoch_counters.gd")
static func merge(target:Dictionary,source:Dictionary)->void:
	for key:String in source:target[key]=maxi(int(target.get(key,0)),int(source[key]))
static func history_snapshot(city:RefCounted)->Dictionary:
	if not city.CreationPolicy.Save.Progression.paused(city) or preload("res://scripts/world/city_creation_economy_pause.gd").owner(city)==null:return city.snapshot()
	var data:Dictionary=city.Serializer.snapshot(city,false)
	if city.get_meta("functional_zones",{}).get("key",[])==[city.revision,city._region_network_revision]:
		var counts:Dictionary=city.get_meta("paused_counter_baseline",{}).duplicate();merge(counts,Epoch.baseline(city))
		city.set_meta("paused_counter_baseline",counts)
		return data
	var sources:Array=city.get_meta("paused_counter_sources",[])
	if sources.is_empty() or sources.back().world!=data or sources.back().region!=city._region_network or sources.back().region_revision!=city._region_network_revision:
		var serial:int=int(city.get_meta("paused_counter_serial",0))+1
		city.set_meta("paused_counter_serial",serial)
		sources.append({"id":serial,"world":data,"region":city._region_network.duplicate(true),"region_revision":city._region_network_revision,"height_seed":height_seed(city),"frontage_seed":preload("res://scripts/visual/city_creation_prepared_frontages.gd").history_seed(city),"lane_seed":preload("res://scripts/world/city_creation_lane_prepared.gd").history_seed(city)})
		city.set_meta("paused_counter_sources",sources)
	return data
static func height_seed(city:RefCounted)->Dictionary:
	# Retained inputs own immutable CPU seeds. Derivation copies them again before
	# preparing changed road beds; no worker can write the live or another seed.
	var result:Dictionary={}
	for field:String in ["_ground_terrain","_terrain_protection","_road_heights","_courtyards"]:
		var source:RefCounted=city.get(field);var copy:RefCounted=source.get_script().new()
		copy.copy_cache_from(source);result[field]=copy
	return result
static func derive(source:Dictionary)->Dictionary:
	var city:RefCounted=preload("res://scripts/world/city_creation_paused_counter_snapshot.gd").restore(source.world)
	for field:String in source.get("height_seed",{}):
		var seed:RefCounted=source.height_seed[field];var copy:RefCounted=seed.get_script().new()
		copy.copy_cache_from(seed);city.set(field,copy)
	city.cozy_progression=source.world.cozy_progression.duplicate(true)
	city._region_network=source.region.duplicate(true);city._region_network_revision=source.region_revision
	city.set_meta("prepared_lane_proofs",source.get("lane_seed",{}))
	preload("res://scripts/visual/city_creation_prepared_frontages.gd").prepare(city,source.get("frontage_seed",{}))
	return Epoch.baseline(city)
static func flush(city:RefCounted)->Dictionary:
	var counts:Dictionary=city.get_meta("paused_counter_baseline",{}).duplicate()
	for source:Dictionary in city.get_meta("paused_counter_sources",[]):merge(counts,derive(source))
	return counts
static func capture(city:RefCounted)->Array:
	return city.get_meta("paused_counter_sources",[]).duplicate(true)
static func before_restore(city:RefCounted,history:bool)->Dictionary:
	if not history or not city.CreationPolicy.Save.Progression.paused(city):return {}
	var policy:Dictionary=city.cozy_progression.duplicate(true)
	city.CreationPolicy.Save.Progression.skip_counts(city,policy)
	return policy
static func prepare(network:RefCounted,sources:Array)->void:
	if sources.is_empty():return
	var began:=Time.get_ticks_usec();var stages:Array=[]
	var counts:Dictionary={}
	for source:Dictionary in sources:
		var started:=Time.get_ticks_usec();merge(counts,derive(source));stages.append({"id":source.id,"revision":source.world.revision,"ms":(Time.get_ticks_usec()-started)/1000.})
	network.prepare_stats["paused_counters"]={"sources":stages,"total_ms":(Time.get_ticks_usec()-began)/1000.}
	network.state.set_meta("paused_counter_result",{"last_id":sources.back().id,"counts":counts})
static func adopt(city:RefCounted,network:RefCounted)->void:
	var result:Dictionary=network.state.get_meta("paused_counter_result",{})
	if result.is_empty():return
	var counts:Dictionary=city.get_meta("paused_counter_baseline",{}).duplicate();merge(counts,result.counts)
	city.set_meta("paused_counter_baseline",counts)
	var remaining:Array=[]
	for source:Dictionary in city.get_meta("paused_counter_sources",[]):
		if int(source.id)>int(result.last_id):remaining.append(source)
	city.set_meta("paused_counter_sources",remaining)
