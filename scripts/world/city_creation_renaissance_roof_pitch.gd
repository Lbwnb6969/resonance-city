extends RefCounted
## Shared plans for the four authored renaissance roof families.
const Parts=preload("res://scripts/world/city_creation_renaissance_roof_parts.gd")
const P=Parts.P
const Roofs=preload("res://scripts/world/city_creation_renaissance_prototype_plan.gd")
const Step=preload("res://scripts/world/city_creation_stepped_guildhouse.gd")
const Corner=preload("res://scripts/world/city_creation_corner_loggia.gd")
const Context=preload("res://scripts/visual/city_creation_building_context.gd")
const IDS:=["venetian_loggia","belvedere_villa","stepped_guildhouse","corner_loggia_tower"]
static func eligible(h:Dictionary)->bool:
	if h.has("signature") or h.get("architecture","") not in IDS or h.get("style","") in ["timber","round_tower"] or not is_zero_approx(Corner.Frame.Hinge.angle(h)):return false
	return Step.authored(h) if h.architecture==Step.ID else Corner.supported(h)
static func authored(h:Dictionary)->bool:return eligible(h) and h.get("roof_pitch",{}).get("version")==5 and h.roof_pitch.get("profile")=="renaissance"
static func context(city)->RefCounted:
	var key:Array=[city.revision,city._wish_epoch];var saved:Dictionary=city.get_meta("renaissance_pitched_context",{})
	if saved.get("key")!=key:
		var value:=Context.new();value.prepare(city.houses,city.roads,city);saved={"key":key,"value":value};city.set_meta("renaissance_pitched_context",saved)
	return saved.value
static func supported(city,h:Dictionary)->bool:
	if not eligible(h):return false
	return h.architecture!=Corner.ID or not Corner.crown(context(city),h,Roofs.roofs(h)).is_empty()
static func source_angle(h:Dictionary)->float:return rad_to_deg(atan({"venetian_loggia":.45/.9,"belvedere_villa":.50/.74,"stepped_guildhouse":.78/.9,"corner_loggia_tower":.55/.87}[h.architecture]))
static func source_anchor(city,h:Dictionary)->Vector3:
	if h.architecture==Step.ID:
		var bays:=Step.bays(city,h);return bays[0].center+Vector3.UP*.88 if not bays.is_empty() else Vector3.ZERO
	var rows:=Roofs.roofs(h)
	if rows.is_empty():return Vector3.ZERO
	var row:Dictionary=Corner.crown(context(city),h,rows) if h.architecture==Corner.ID else rows[0]
	if row.is_empty():return Vector3.ZERO
	return Vector3(row.center.x,row.base+{"venetian_loggia":.55,"belvedere_villa":1.77,"corner_loggia_tower":2.16}[h.architecture],row.center.y)
static func for_house(city,h:Dictionary)->Dictionary:
	var token:=hash([city.revision,city._wish_epoch,h]);var cache:Dictionary=city.get_meta("renaissance_pitched_plans",{});var id:=str(h.id)
	if cache.get(id,{}).get("token")==token:return cache[id].plan
	var result:={"records":[],"patches":[],"outlets":[],"crown":{}};var rows:Array=Step.bays(city,h) if h.architecture==Step.ID else Roofs.roofs(h);var slope:=tan(deg_to_rad(float(h.roof_pitch.degrees)));var ctx:=context(city)
	if h.architecture==Corner.ID:result.crown=Corner.crown(ctx,h,rows)
	for row:Dictionary in rows:
		var parts:Array=[];var origin:Vector3=row.center if h.architecture==Step.ID else Vector3(row.center.x,row.base,row.center.y);var angle:float=float(row.get("angle",0.));var crowned:bool=not result.crown.is_empty() and result.crown.cell.id==row.cell.id
		var metadata:={"cell_id":str(row.cell.id),"prototype":str(h.architecture),"base":origin.y,"crown":crowned,"degrees":float(h.roof_pitch.degrees)}
		if h.architecture==Step.ID:
			var data:=preload("res://scripts/world/city_creation_stepped_roof_pitch.gd").build(row,slope,str(h.get("role",""))=="bakery" and result.outlets.is_empty());parts=data.parts;metadata.height=data.height;metadata.steps=4;metadata.depth=row.depth;metadata.angle=angle
			for point:Vector3 in data.outlets:result.outlets.append(Transform3D(Basis(Vector3.UP,angle),origin)*point)
		else:
			P.box(parts,"LoggiaRoofPlatform",Vector3(1.8,.14 if h.architecture==Corner.ID else .12,1.8),Vector3(0,.025 if h.architecture==Corner.ID else .015,0),"stone")
			if h.architecture=="venetian_loggia":Parts.hip(parts,1.8,1.8,.10,.9*slope)
			elif h.architecture==Corner.ID and crowned:
				parts.append_array(Parts.transform(preload("res://scripts/world/city_creation_loggia_roof_pitch.gd").build(slope),Transform3D(Basis(Vector3.UP,float(result.crown.angle)),Vector3.ZERO)))
			else:
				for side:Vector2i in Corner.SIDES:
					if not ctx.neighbor(h,row.cell,side,0,true).is_empty() or h.architecture==Corner.ID and not ctx.neighbor(h,row.cell,side,1,true).is_empty():continue
					var rail:Array=[];Parts.rail(rail,1.64 if h.architecture==Corner.ID else 1.65,.80,h.architecture==Corner.ID);parts.append_array(Parts.transform(rail,Transform3D(Basis(Vector3.UP,atan2(float(side.x),float(side.y))),Vector3.ZERO)))
				if h.architecture=="belvedere_villa" and row==rows[0]:Parts.lookout(parts,slope);metadata.lookout=true
		Parts.transform(parts,Transform3D(Basis(Vector3.UP,angle),origin));result.records.append({"parts":parts,"cell":row.cell,"metadata":metadata})
		for part:Dictionary in parts:
			var low:=INF
			for point:Vector3 in part.vertices:low=minf(low,point.y)
			result.patches.append({"surface":"roof","base_y":low,"vertices":part.vertices,"cell_id":str(row.cell.id),"part":part.name,"roof_skin":part.roof_skin})
	cache[id]={"token":token,"plan":result};city.set_meta("renaissance_pitched_plans",cache);return result
