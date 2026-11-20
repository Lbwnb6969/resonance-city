extends RefCounted
## Shape-only colors, deduplicated within the existing one-house weight budget.
const Zones=preload("res://scripts/world/city_creation_functional_zones.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const Context=preload("res://scripts/audio/city_creation_expression_context.gd")
const Chamber=preload("res://scripts/audio/city_creation_chamber_context.gd")
const Civic=preload("res://scripts/audio/city_creation_civic_response.gd")
var signature:=0
var city_id:=0
var records:Dictionary={}
var civic:Array=[]
var rebuilds:=0
static func key(city:RefCounted)->int:
	return hash([city.houses,city.roads,city.waters,city.terrain_strokes,city.terrain_policy,city.districts,city.placed_landmarks])
static func ready(city:RefCounted)->bool:
	var life:Node3D=preload("res://scripts/world/city_creation_economy_pause.gd").owner(city)
	return life==null or (not life.budget_sync_pending() and not life._budget_hold and life.last_revision==city.revision)
static func needed(city:RefCounted)->bool:
	if not city.has_meta("game_expression_owner"):return false
	var owner:Node=city.get_meta("game_expression_owner").get_ref()
	return owner!=null and not owner.cancelled
static func prepare(city:RefCounted)->Dictionary:
	var model:RefCounted=load("res://scripts/audio/city_creation_expression_geometry.gd").new();model.refresh(city)
	return {"signature":model.signature,"records":model.records,"civic":model.civic}
static func capture(city:RefCounted)->Dictionary:
	if not ready(city):return {}
	var fields:Dictionary={}
	for field:String in ["houses","roads","waters","terrain_strokes","terrain_policy","districts","placed_landmarks","creative_settings","harmony_journey","cozy_progression","plants","era_modifiers","biome_seed","era_unlocks","revision","_region_network","_region_network_revision"]:
		var value:Variant=city.get(field);fields[field]=value.duplicate(true) if value is Array or value is Dictionary else value
	return {"fields":fields,"zones":city.functional_zones().duplicate(true),"courts":city.courtyard_plans().duplicate(true)}
static func prepare_snapshot(snapshot:Dictionary)->Dictionary:
	var city:RefCounted=load("res://scripts/world/city_creation_state.gd").new()
	for field:String in snapshot.fields:city.set(field,snapshot.fields[field])
	city._courtyard_plans_cache.assign(snapshot.courts);city._courtyard_revision=city.revision
	city.set_meta("functional_zones",{"key":[city.revision,city._region_network_revision],"value":snapshot.zones})
	preload("res://scripts/visual/city_creation_prepared_frontages.gd").prepare(city)
	return prepare(city)
static func adopt(city:RefCounted,prepared:Dictionary)->void:
	if prepared.get("signature",-1)==key(city):city.set_meta("expression_geometry_prepared",prepared)
func refresh(city:RefCounted)->void:
	if not ready(city):return
	var next_key:=key(city)
	if city_id==city.get_instance_id() and signature==next_key:return
	city_id=city.get_instance_id();signature=next_key;rebuilds+=1;records={}
	var prepared:Dictionary=city.get_meta("expression_geometry_prepared",{})
	if prepared.get("signature",-1)==signature and prepared.has("civic"):records=prepared.records;civic=prepared.civic;return
	var spaces:Dictionary=city.functional_zones()
	civic=Civic.collect(spaces)
	var curves:Array=[]
	for road:Dictionary in city.roads:curves.append({"id":road.id,"bins":Chamber.curves([road])})
	for house:Dictionary in city.houses:
		var water:=INF;var water_ids:Array=[];var sway_ids:Array=[];var craft_ids:Array=[]
		for cell:Dictionary in house.cells:
			if int(cell.level)!=0:continue
			var box:Variant=Frame.footprint(house,cell)
			water=minf(water,Zones._water_distance(city,box))
			if Zones._river_distance(city,box)<5.2 and not water_ids.has("river"):water_ids.append("river")
			for stroke:Dictionary in city.waters:
				var d:=INF
				for point:Array in stroke.points:d=minf(d,Frame.distance(box,Vector2(point[0],point[1])))
				for i in range(1,stroke.points.size()):
					var a:=Vector2(stroke.points[i-1][0],stroke.points[i-1][1]);var b:=Vector2(stroke.points[i][0],stroke.points[i][1])
					if Frame.segment(box,a,b):d=0.;break
					for corner:Vector2 in Frame.corners(box):d=minf(d,corner.distance_to(Geometry2D.get_closest_point_to_segment(corner,a,b)))
				if d-float(stroke.width)*.5<5.2 and not water_ids.has(stroke.id):water_ids.append(stroke.id)
		for curve:Dictionary in curves:
			if Chamber.house(city,house,curve.bins):sway_ids.append(curve.id)
		# An authored bend has shape even in a city with no roads.
		if Chamber.house(city,house,{}):sway_ids=[house.id]
		for space:Dictionary in spaces.get("spaces",[]):
			if space.kind=="artisan" and space.members.has(house.id) and not space.evidence.get("forecourts",[]).is_empty():
				for id:String in space.source_ids:
					if not craft_ids.has(id):craft_ids.append(id)
		if Context.architecture(city,house) and not craft_ids.has(house.id):craft_ids.append(house.id)
		var flow:=maxf(1.-smoothstep(0.,5.2,water),.7225 if not sway_ids.is_empty() else 0.)
		var sources:Array=water_ids if water<5.2 else []
		for id:String in sway_ids:
			if not sources.has(id):sources.append(id)
		if flow>0. and not sources.has(house.id):sources.append(house.id)
		sources.sort();craft_ids.sort()
		records[house.id]={"flow":flow,"craft":.65 if not craft_ids.is_empty() else 0.,"base_y":float(house.get("base_y",0.)),"flow_sources":sources,"craft_sources":craft_ids}
func sample(weights:Dictionary)->Dictionary:
	var result:={"flow":0.,"craft":0.,"flow_sources":[],"craft_sources":[],"flow_contributions":[],"craft_contributions":[]}
	for id:String in weights:
		var row:Dictionary=records.get(id,{})
		for kind:String in ["flow","craft"]:
			var contribution := float(weights[id]) * float(row.get(kind, 0.))
			if contribution <= 0.: continue
			result[kind] += contribution
			var sources: Array = row[kind+"_sources"]
			result[kind+"_contributions"].append({"source_ids":sources, "value":contribution})
			for source: String in sources:
				if not result[kind+"_sources"].has(source):result[kind+"_sources"].append(source)
	for kind:String in ["flow","craft"]:result[kind+"_sources"].sort()
	result.highland=Context.contour(records,weights)
	return result
