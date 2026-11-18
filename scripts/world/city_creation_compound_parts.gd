extends RefCounted
## A compound consists of real, independently editable houses joined in space.
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const Round=preload("res://scripts/world/city_creation_round_tower_plan.gd")
const Context=preload("res://scripts/visual/city_creation_building_context.gd")
const SCHEMA:=37
static func authored(h:Dictionary)->bool:return h.get("assembly_part",{}).get("version",0)==1
static func plan(city,id:String,side:Vector2i,style:String,levels:int)->Dictionary:
	var index:int=city._house_index(id)
	if index<0:return city._fail("主楼不存在")
	var host:Dictionary=city.houses[index]
	if not Context.Pitch.ordinary(host) or city.house_era(host) not in ["pastoral","renaissance"]:return city._fail("选择古典或文艺时代的普通主楼")
	if side not in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN] or style not in ["classic","round_tower"] or levels<1 or levels>8:return city._fail("选择拼接方向、方楼或圆塔及1～8层")
	var rooms:Array=[];var mean:=Vector2.ZERO
	for cell:Dictionary in host.cells:
		if int(cell.level)==0 and cell.kind=="room":rooms.append(cell);mean+=Vector2(cell.x,cell.z)
	if rooms.is_empty():return city._fail("主楼没有可接地的房间")
	mean/=rooms.size()
	rooms.sort_custom(func(a,b):
		var aa:=Vector2(a.x,a.z);var bb:=Vector2(b.x,b.z);var d:=aa.dot(Vector2(side))-bb.dot(Vector2(side))
		return d>0. if absf(d)>.001 else absf((aa-mean).cross(Vector2(side)))<absf((bb-mean).cross(Vector2(side))))
	var at:=Frame.center(host,rooms[0])+Frame.direction(host,Vector2(side))*1.8
	var h:Dictionary=city._new_stroke_house(at);h.base_y=float(host.get("base_y",0.));h.era_theme=city.house_era(host);h.palette=int(host.get("palette",0));h.style=style;h.assembly_part={"version":1};h.name="圆塔" if style=="round_tower" else "拼接方楼"
	if host.has("custom_colors"):h.custom_colors=host.custom_colors.duplicate(true)
	if not is_zero_approx(Frame.yaw(host)):h.yaw=Frame.yaw(host)
	if style=="classic":h.architecture="townhouse";h.roof_pitch={"version":1,"degrees":0.}
	else:h.roof_pitch={"version":2,"profile":"round","degrees":45.}
	var next:int=maxi(city._next_cell_id,int(city._high_watermark.cell)+1)
	for level in range(levels):h.cells.append({"id":"c%d"%(next+level),"x":0,"z":0,"level":level,"kind":"room","source":"new_house" if level==0 else "player"})
	var valid:Dictionary=city._validate_house(h)
	if valid.ok and city._house_overlaps(h):valid=city._fail("这个方向已有建筑，换一面拼接")
	if valid.ok:valid=city._validate_house_site(h)
	var houses:Array=city.houses.duplicate();houses.append(h)
	if valid.ok and style=="round_tower" and Round.for_house(h,houses,city.roads).is_empty():valid=city._fail("塔顶与邻楼冲突；增加塔层数或换一面")
	if not valid.ok:return valid
	for other:Dictionary in city.houses:
		if other.get("style","")=="round_tower" and not Round.for_house(other,city.houses,city.roads).is_empty() and Round.for_house(other,houses,city.roads).is_empty():return city._fail("这个分体会挤掉已有圆塔，换一面拼接")
	if not clear_roofs(houses,city.roads,city):return city._fail("主楼屋顶高于塔檐；增加塔层数")
	return {"ok":true,"house":h,"house_id":str(h.id),"message":"分体已拼接，可单独改屋式、加层与调坡"}
static func clear_roofs(houses:Array,roads:Array,city:Variant=null)->bool:
	var towers:Array=[]
	for h:Dictionary in houses:
		if authored(h) and h.get("style","")=="round_tower":
			var plan:=Round.for_house(h,houses,roads)
			if not plan.is_empty():towers.append({"house":h,"plan":plan})
	if towers.is_empty():return true
	var context:=Context.new();context.prepare(houses,roads,city)
	for tower:Dictionary in towers:
		var h:Dictionary=tower.house;var plan:Dictionary=tower.plan;var polygon:=PackedVector2Array()
		for i in range(16):polygon.append(Frame.point(h,plan.center+Vector2.from_angle(float(i)*TAU/16.)*1.06))
		for other:Dictionary in houses:
			if other.id==h.id or other.get("style","")=="round_tower":continue
			for patch:Dictionary in context.roof_patches(str(other.id)):
				if patch.surface!="roof":continue
				for i in range(0,patch.vertices.size(),3):
					var a:=Frame.world3(other,patch.vertices[i]);var b:=Frame.world3(other,patch.vertices[i+1]);var c:=Frame.world3(other,patch.vertices[i+2]);var normal:Vector3=(b-a).cross(c-a)
					if absf(normal.y)<.000001:continue
					for clipped:PackedVector2Array in Geometry2D.intersect_polygons(PackedVector2Array([Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z)]),polygon):
						for p:Vector2 in clipped:
							if a.y-(normal.x*(p.x-a.x)+normal.z*(p.y-a.z))/normal.y>float(plan.roof_base_y)-.02:return false
	return true
static func check_roof(city,house:Dictionary)->bool:
	if not city.houses.any(func(h):return authored(h) and h.get("style","")=="round_tower"):return true
	var houses:Array=city.houses.duplicate()
	for i in range(houses.size()):
		if houses[i].id==house.id:houses[i]=house
	return clear_roofs(houses,city.roads,city)
static func add(city,id:String,side:Vector2i,style:String,levels:int)->Dictionary:
	var result:=plan(city,id,side,style,levels)
	if not result.ok:return result
	var before:Dictionary=city.snapshot();var h:Dictionary=result.house
	city.houses.append(h);var number:=int(h.id.substr(1));city._next_house_id=number+1;city._high_watermark.house=number;city._issue_stroke_cells(h.cells);city.Eras.refresh(city);city._commit(before,"拼接建筑分体")
	result.before_upgrade=before if int(before.schema)<SCHEMA else {};return result
static func write(city,result:Dictionary)->void:
	for h:Dictionary in city.houses:
		if h.has("assembly_part"):result.schema=maxi(int(result.schema),SCHEMA)
static func validate(city,data:Dictionary)->Dictionary:
	for h:Variant in data.get("houses",[]):
		if not h is Dictionary or not h.has("assembly_part"):continue
		var value:Variant=h.assembly_part
		if int(data.schema)<SCHEMA or not value is Dictionary or value.size()!=1 or not city._is_integer(value.get("version")) or value.version!=1:return city._fail("拼接分体配方需要版本37")
	return {"ok":true}
