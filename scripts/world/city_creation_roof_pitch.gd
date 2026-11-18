extends RefCounted
const Geometry=preload("res://scripts/world/city_creation_roof_pitch_geometry.gd")
const Context=preload("res://scripts/visual/city_creation_building_context.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const Round=preload("res://scripts/world/city_creation_round_tower_plan.gd")
const Modern=preload("res://scripts/world/city_creation_modern_roof_pitch.gd")
const Clockwork=preload("res://scripts/world/city_creation_clockwork_roof_pitch.gd")
const Renaissance=preload("res://scripts/world/city_creation_renaissance_roof_pitch.gd")
const Boathouse=preload("res://scripts/world/city_creation_boathouse_roof_pitch.gd")
const Acoustic=preload("res://scripts/world/city_creation_acoustic_roof_pitch.gd")
const Stoa=preload("res://scripts/world/city_creation_stoa_roof_pitch.gd")
const Basilica=preload("res://scripts/world/city_creation_basilica_roof_pitch.gd")
const Portico=preload("res://scripts/world/city_creation_portico_roof_pitch.gd")
const Guildhall=preload("res://scripts/world/city_creation_guildhall_roof_pitch.gd")
const GUILDHALL_SCHEMA:=46
const PORTICO_SCHEMA:=45
const BASILICA_SCHEMA:=44
const STOA_SCHEMA:=43
const ACOUSTIC_SCHEMA:=42
const BOATHOUSE_SCHEMA:=41
const RENAISSANCE_SCHEMA:=40
const CLOCKWORK_SCHEMA:=39
const MODERN_SCHEMA:=38
const FIELD:=Geometry.FIELD
const SCHEMA:=35
const ROUND_SCHEMA:=36
static func supported(city,house:Dictionary)->bool:
	if guildhall(house,city):return Guildhall.supported(city,house)
	if portico(house,city):return Portico.supported(city,house)
	if basilica(house,city):return Basilica.supported(city,house)
	if stoa(house,city):return Stoa.supported(city,house)
	if acoustic(house,city):return Acoustic.Plan.active(city,house)
	if boathouse(house,city):return Boathouse.eligible(house)
	if renaissance_special(house,city):return Renaissance.supported(city,house)
	if city.house_era(house)=="clockwork":return Clockwork.eligible(house)
	if city.house_era(house)=="modern_eco":return Modern.eligible(house)
	if city.house_era(house) not in ["pastoral","renaissance"]:return false
	return Geometry.ordinary(house) or not house.has("signature") and house.get("style","")=="round_tower" and not Round.for_house(house,city.houses,city.roads).is_empty()
static func modern(house:Dictionary,city:Variant=null)->bool:return (city.house_era(house) if city!=null else house.get("era_theme","pastoral"))=="modern_eco"
static func clockwork(house:Dictionary,city:Variant=null)->bool:return (city.house_era(house) if city!=null else house.get("era_theme","pastoral"))=="clockwork"
static func renaissance_special(house:Dictionary,city:Variant=null)->bool:return (city.house_era(house) if city!=null else house.get("era_theme","pastoral"))=="renaissance" and house.get("architecture","") in Renaissance.IDS
static func boathouse(house:Dictionary,city:Variant=null)->bool:return (city.house_era(house) if city!=null else house.get("era_theme","pastoral"))=="pastoral" and house.get("architecture","")==Boathouse.ID
static func acoustic(house:Dictionary,city:Variant=null)->bool:return modern(house,city) and house.get("architecture","")=="timber_acoustic_shell"
static func stoa(house:Dictionary,city:Variant=null)->bool:return (city.house_era(house) if city!=null else house.get("era_theme","pastoral"))=="pastoral" and house.get("architecture","")=="ionic_stoa"
static func basilica(house:Dictionary,city:Variant=null)->bool:return (city.house_era(house) if city!=null else house.get("era_theme","pastoral"))=="pastoral" and house.get("architecture","")=="roman_basilica"
static func portico(house:Dictionary,city:Variant=null)->bool:return (city.house_era(house) if city!=null else house.get("era_theme","pastoral"))=="pastoral" and house.get("architecture","")=="portico"
static func guildhall(house:Dictionary,city:Variant=null)->bool:return house.get("architecture","")=="guildhall"
static func recipe(house:Dictionary,degrees:float,city:Variant=null)->Dictionary:
	if guildhall(house,city):return {"version":11,"profile":"guildhall","degrees":degrees}
	if portico(house,city):return {"version":10,"profile":"portico","degrees":degrees}
	if basilica(house,city):return {"version":9,"profile":"roman_basilica","degrees":degrees}
	if stoa(house,city):return {"version":8,"profile":"ionic_stoa","degrees":degrees}
	if acoustic(house,city):return {"version":7,"profile":"acoustic_shell","degrees":degrees}
	if boathouse(house,city):return {"version":6,"profile":"boathouse","degrees":degrees}
	if renaissance_special(house,city):return {"version":5,"profile":"renaissance","degrees":degrees}
	if clockwork(house,city):return {"version":4,"profile":"clockwork","degrees":degrees}
	if modern(house,city):return {"version":3,"profile":"modern","degrees":degrees}
	return {"version":2,"profile":"round","degrees":degrees} if house.get("style","")=="round_tower" else {"version":1,"degrees":degrees}
static func required_schema(house:Dictionary,city:Variant=null)->int:return GUILDHALL_SCHEMA if guildhall(house,city) else PORTICO_SCHEMA if portico(house,city) else BASILICA_SCHEMA if basilica(house,city) else STOA_SCHEMA if stoa(house,city) else ACOUSTIC_SCHEMA if acoustic(house,city) else BOATHOUSE_SCHEMA if boathouse(house,city) else RENAISSANCE_SCHEMA if renaissance_special(house,city) else CLOCKWORK_SCHEMA if clockwork(house,city) else MODERN_SCHEMA if modern(house,city) else ROUND_SCHEMA if house.get("style","")=="round_tower" else SCHEMA
static func check_value(city,house:Dictionary,degrees:Variant)->Dictionary:
	if degrees!=null and (not city._is_number(degrees) or float(degrees)<0. or float(degrees)>Geometry.MAX_DEGREES):return city._fail("屋顶坡度范围为0～78度")
	if degrees==null:return {"ok":true}
	if not supported(city,house):return city._fail("此屋型暂不支持调坡，可保留原顶")
	if not modern(house,city) and not clockwork(house,city) and house.get("style","")=="round_tower":
		var candidate:=house.duplicate(true);candidate[FIELD]=recipe(house,float(degrees),city)
		if Round.for_house(candidate,city.houses,city.roads).is_empty():return city._fail("此坡度与邻屋净空冲突，原圆塔保持")
	var proposed:=house.duplicate(true);proposed[FIELD]=recipe(house,float(degrees),city)
	if not preload("res://scripts/world/city_creation_compound_parts.gd").check_roof(city,proposed):return city._fail("主楼屋顶与拼接塔檐冲突；先增高塔楼")
	return {"ok":true}
static func applies(house:Dictionary,city:Variant=null)->bool:
	if guildhall(house,city):return Guildhall.authored(house)
	if portico(house,city):return Portico.authored(house)
	if basilica(house,city):return Basilica.authored(house)
	if stoa(house,city):return Stoa.authored(house)
	if acoustic(house,city):return Acoustic.authored(house)
	if boathouse(house,city):return Boathouse.authored(house)
	if renaissance_special(house,city):return Renaissance.authored(house)
	if clockwork(house,city):return Clockwork.authored(house)
	if modern(house,city):return Modern.authored(house)
	return Round.Roof.authored(house) if house.get("style","")=="round_tower" else Geometry.degrees(house)>=0.
static func active(city,house:Dictionary)->bool:return Guildhall.active(city,house) if guildhall(house,city) else Portico.active(city,house) if portico(house,city) else Basilica.active(city,house) if basilica(house,city) else Stoa.active(city,house) if stoa(house,city) else Acoustic.active(city,house) if acoustic(house,city) else Renaissance.authored(house) if renaissance_special(house,city) else applies(house,city) and supported(city,house)
static func choose(city,id:String,degrees:Variant)->Dictionary:
	var index:int=city._house_index(id)
	if index<0:return city._fail("房屋不存在")
	var house:Dictionary=city.houses[index]
	var checked:=check_value(city,house,degrees)
	if not checked.ok:return checked
	var value:Variant=null if degrees==null else recipe(house,float(degrees),city)
	if house.get(FIELD)==value:return {"ok":true,"no_op":true}
	var before:Dictionary=city.snapshot()
	if value==null:house.erase(FIELD)
	else:house[FIELD]=value
	city._commit(before,"调整屋顶坡度")
	return {"ok":true,"house_id":id,"message":"已恢复原屋顶" if degrees==null else "屋顶坡度 %.1f°"%float(degrees),"before_upgrade":before if value!=null and int(before.schema)<required_schema(house,city) else {}}
static func write(city,result:Dictionary)->void:
	for house:Dictionary in city.houses:
		if house.has(FIELD):result.schema=maxi(int(result.schema),GUILDHALL_SCHEMA if int(house[FIELD].version)==11 else PORTICO_SCHEMA if int(house[FIELD].version)==10 else BASILICA_SCHEMA if int(house[FIELD].version)==9 else STOA_SCHEMA if int(house[FIELD].version)==8 else ACOUSTIC_SCHEMA if int(house[FIELD].version)==7 else BOATHOUSE_SCHEMA if int(house[FIELD].version)==6 else RENAISSANCE_SCHEMA if int(house[FIELD].version)==5 else CLOCKWORK_SCHEMA if int(house[FIELD].version)==4 else MODERN_SCHEMA if int(house[FIELD].version)==3 else ROUND_SCHEMA if int(house[FIELD].version)==2 else SCHEMA)
static func validate(city,data:Dictionary)->Dictionary:
	for house:Variant in data.get("houses",[]):
		if not house is Dictionary or not house.has(FIELD):continue
		var row:Variant=house[FIELD]
		if not row is Dictionary or not city._is_integer(row.get("version")) or not city._is_number(row.get("degrees")) or float(row.degrees)<0. or float(row.degrees)>Geometry.MAX_DEGREES:return city._fail("屋顶坡度配方无效")
		if row.version==1 and row.size()==2 and int(data.schema)>=SCHEMA:continue
		if row.version==2 and row.size()==3 and row.get("profile")=="round" and int(data.schema)>=ROUND_SCHEMA:continue
		if row.version==3 and row.size()==3 and row.get("profile")=="modern" and int(data.schema)>=MODERN_SCHEMA:continue
		if row.version==4 and row.size()==3 and row.get("profile")=="clockwork" and int(data.schema)>=CLOCKWORK_SCHEMA:continue
		if row.version==5 and row.size()==3 and row.get("profile")=="renaissance" and int(data.schema)>=RENAISSANCE_SCHEMA:continue
		if row.version==6 and row.size()==3 and row.get("profile")=="boathouse" and int(data.schema)>=BOATHOUSE_SCHEMA:continue
		if row.version==7 and row.size()==3 and row.get("profile")=="acoustic_shell" and int(data.schema)>=ACOUSTIC_SCHEMA:continue
		if row.version==8 and row.size()==3 and row.get("profile")=="ionic_stoa" and int(data.schema)>=STOA_SCHEMA:continue
		if row.version==9 and row.size()==3 and row.get("profile")=="roman_basilica" and int(data.schema)>=BASILICA_SCHEMA:continue
		if row.version==10 and row.size()==3 and row.get("profile")=="portico" and int(data.schema)>=PORTICO_SCHEMA:continue
		if row.version==11 and row.size()==3 and row.get("profile")=="guildhall" and int(data.schema)>=GUILDHALL_SCHEMA:continue
		return city._fail("屋顶配方需要对应版本：普通35，圆塔36，现代38，钟表39，文艺40，船坞41，木壳42，长馆43，殿堂44，门庭45，会馆46")
	return {"ok":true}
static func context(city)->RefCounted:
	var key:Array=[city.revision,city._wish_epoch]
	var saved:Dictionary=city.get_meta("roof_pitch_context",{})
	if saved.get("key")!=key:
		var ctx:=Context.new();ctx.prepare(city.houses,city.roads,city);saved={"key":key,"context":ctx};city.set_meta("roof_pitch_context",saved)
	return saved.context
static func blocks(city,house:Dictionary,a:Vector2,b:Vector2,y:float,half:float)->bool:
	var normal:=Vector2(-(b-a).y,(b-a).x).normalized()*half
	var corridor:=PackedVector2Array([a+normal,b+normal,b-normal,a-normal])
	if not modern(house,city) and not clockwork(house,city) and house.get("style","")=="round_tower":
		var plan:=Round.for_house(house,city.houses,city.roads)
		if not plan.is_empty():
			for part:Dictionary in Round.Roof.parts(plan.center,plan.roof_base_y,house):
				var box:AABB=part.bounds
				if box.end.y<y-.1 or box.position.y>y+1.4:continue
				var points:=Round.Roof.footprint(part)
				for i in range(points.size()):points[i]=Frame.point(house,points[i])
				if not Geometry2D.intersect_polygons(points,corridor).is_empty():return true
	for patch:Dictionary in patches(city,house):
		if patch.surface!="roof" or float(patch.base_y)>y+1.4:continue
		for i in range(0,patch.vertices.size(),3):
			var vertices:Array[Vector3]=[];var polygon:=PackedVector2Array()
			for j in range(3):var p:Vector3=Frame.world3(house,patch.vertices[i+j]);vertices.append(p);polygon.append(Vector2(p.x,p.z))
			var n:Vector3=(vertices[1]-vertices[0]).cross(vertices[2]-vertices[0])
			if absf(n.y)<.000001:continue
			for clipped:PackedVector2Array in Geometry2D.intersect_polygons(polygon,corridor):
				for p:Vector2 in clipped:
					var height:float=vertices[0].y-(n.x*(p.x-vertices[0].x)+n.z*(p.y-vertices[0].z))/n.y
					if height>=y-.1:return true
	return false
static func patches(city,house:Dictionary)->Array:
	if guildhall(house,city) and Guildhall.active(city,house):return Guildhall.for_house(city,house).patches
	if portico(house,city) and Portico.active(city,house):return Portico.for_house(city,house).patches
	if basilica(house,city) and Basilica.authored(house):return Basilica.for_house(city,house).patches
	if stoa(house,city) and Stoa.authored(house):return Stoa.for_house(city,house).patches
	if acoustic(house,city) and Acoustic.authored(house):return Acoustic.for_house(city,house).patches
	if boathouse(house,city) and Boathouse.authored(house):
		var result:Array=context(city).roof_patches(str(house.id)).duplicate();result.append_array(Boathouse.patches(house,preload("res://scripts/world/city_creation_boathouse_plan.gd").find(city,str(house.id))));return result
	if renaissance_special(house,city) and Renaissance.authored(house):return Renaissance.for_house(city,house).patches
	if clockwork(house,city) and Clockwork.authored(house):return Clockwork.for_house(city,house).patches
	if modern(house,city) and Modern.authored(house):
		var result:=Modern.patches(city,house);result.append_array(preload("res://scripts/world/city_creation_modern_roof_details.gd").plan(city,house,result).patches);return result
	if not modern(house,city) and not clockwork(house,city) and house.get("style","")=="round_tower":
		var plan:=Round.for_house(house,city.houses,city.roads)
		if plan.is_empty():return []
		return [{"surface":"roof","base_y":plan.roof_base_y,"vertices":Round.Roof.vertices(Vector3(plan.center.x,plan.roof_base_y,plan.center.y),house)}]
	return context(city).roof_patches(str(house.id))
