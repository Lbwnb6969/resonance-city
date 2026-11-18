extends RefCounted
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const Span=preload("res://scripts/world/city_creation_skybridge_span.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
## Shared derived bridges connect real second/third floors without new save IDs.
const UNIT:=1.8
const FLOOR:=1.7
const WIDTH:=.84
static func for_house(city:RefCounted,house:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if city.house_era(house)!="modern_eco":return result
	for cell:Dictionary in house.cells:
		if cell.kind!="room" or int(cell.level) not in [1,2]:continue
		for direction:Vector2i in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
			if _neighbor(house,cell,direction):continue
			var closest:=INF;var selected:Dictionary={}
			for other:Dictionary in city.houses:
				if str(house.id)==str(other.id) or city.house_era(other)!="modern_eco" or absf(Frame.yaw(house)-Frame.yaw(other))>.00001:continue
				for target:Dictionary in other.cells:
					if target.kind!="room" or int(target.level) not in [1,2]:continue
					var proof:=assess(city,house,cell,other,target,direction)
					if not proof.ok or float(proof.distance)>=closest:continue
					closest=proof.distance;selected=proof.plan
			if not selected.is_empty() and int(str(house.id).substr(1))<int(str(selected.to_house).substr(1)):result.append(selected)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.floor_y)>float(b.floor_y) if not is_equal_approx(a.floor_y,b.floor_y) else float(a.length)<float(b.length))
	var selected_pairs:Dictionary={};var unique:Array[Dictionary]=[]
	for bridge:Dictionary in result:
		if selected_pairs.has(bridge.to_house):continue
		selected_pairs[bridge.to_house]=true;unique.append(bridge)
	return unique
static func _center(house:Dictionary,cell:Dictionary)->Vector2:
	return Frame.center(house,cell)
static func _neighbor(house:Dictionary,cell:Dictionary,direction:Vector2i)->bool:
	for other:Dictionary in house.cells:
		if other.kind=="room" and int(other.level)==int(cell.level) and int(other.x)==int(cell.x)+direction.x and int(other.z)==int(cell.z)+direction.y:return true
	return false
static func _clear(city:RefCounted,a:Vector2,b:Vector2,y:float,from_cell:String,to_cell:String)->bool:
	return obstruction(city,a,b,y,from_cell,to_cell).is_empty()
static func assess(city:RefCounted,house:Dictionary,cell:Dictionary,other:Dictionary,target:Dictionary,direction:Vector2i)->Dictionary:
	var reason:=""
	var at:=_center(house,cell);var to:=_center(other,target)
	var normal:=Frame.direction(house,Vector2(direction));var offset:=to-at;var distance:=offset.dot(normal)
	var y:=float(house.get("base_y",0.))+int(cell.level)*FLOOR+.15
	var height:=float(other.get("base_y",0.))+int(target.level)*FLOOR+.15
	if city.house_era(house)!="modern_eco" or city.house_era(other)!="modern_eco":reason="两端需要现代风貌房间"
	elif cell.kind!="room" or target.kind!="room" or int(cell.level) not in [1,2] or int(target.level) not in [1,2]:reason="两端需要第2或第3层房间，露台不能代替房间端点"
	elif absf(Frame.yaw(house)-Frame.yaw(other))>.00001:reason="两端房屋朝向需要一致"
	elif _neighbor(house,cell,direction) or _neighbor(other,target,-direction):reason="端点侧墙已被同层房间占用"
	elif absf(height-y)>.02:reason="两端楼面高度需一致（含地基高差）"
	elif distance<2.2 or absf(offset.cross(normal))>.02:reason="端点需要正对齐，房间中心距至少2.2米"
	elif distance>Span.limit(city,house,other):reason="超过当前跨度；烟火点屋→外观→九米云廊" if distance<=9. and Span.search_distance(city)>=9. else "超过允许的连桥跨度"
	var a:=at+normal*.87;var b:=to-normal*.87
	if reason.is_empty():
		var blocked:=obstruction(city,a,b,y,str(cell.id),str(target.id))
		if not blocked.is_empty():reason="净空不足："+str({"building":"房屋或屋顶挡住桥廊","terrain":"地形高于桥下净空","road":"下方道路净高不足"}[blocked.kind])
	var plan:Dictionary={}
	if reason.is_empty():plan={"from_house":str(house.id),"to_house":str(other.id),"from_cell":str(cell.id),"to_cell":str(target.id),"a":a,"b":b,"floor_y":y,"width":WIDTH,"level":int(cell.level),"length":a.distance_to(b)}
	return {"ok":reason.is_empty(),"reason":reason,"distance":distance,"plan":plan,"a":Vector3(at.x,y,at.y),"b":Vector3(to.x,height,to.y)}
static func obstruction(city:RefCounted,a:Vector2,b:Vector2,y:float,from_cell:String,to_cell:String)->Dictionary:
	var corridor:=Rect2(a,Vector2.ZERO).expand(b).grow(WIDTH*.5+.04)
	for house:Dictionary in city.houses:
		for cell:Dictionary in house.cells:
			if str(cell.id) in [from_cell,to_cell]:continue
			var bottom:=float(house.get("base_y",0.))+int(cell.level)*FLOOR
			var top:=bottom+(.18 if cell.kind=="terrace" else FLOOR)
			if cell.kind=="room":
				var covered:=false
				for above:Dictionary in house.cells:
					if int(above.x)==int(cell.x) and int(above.z)==int(cell.z) and int(above.level)>int(cell.level):covered=true;break
				if not covered and Pitch.active(city,house):
					if Pitch.blocks(city,house,a,b,y,WIDTH*.5+.04):return {"kind":"building","id":house.id}
				elif not covered:top+=.70 if city.house_era(house)=="modern_eco" else 1.8 if city.house_era(house)=="renaissance" or house.get("style","")=="round_tower" else 1.0
			if top<y-.1 or bottom>y+1.4:continue
			if Frame.segment(Frame.footprint(house,cell,WIDTH*.5+.04),a,b):return {"kind":"building","id":house.id}
	for i in range(1,6):
		var p:=a.lerp(b,float(i)/6.)
		if city.ground_height(p)>y-.2:return {"kind":"terrain","at":p}
		for road:Dictionary in city.roads:
			for j in range(1,road.points.size()):
				var u:=Vector2(road.points[j-1][0],road.points[j-1][1]);var v:=Vector2(road.points[j][0],road.points[j][1])
				if Geometry2D.get_closest_point_to_segment(p,u,v).distance_to(p)<float(road.width)*.5+.45 and y<city.street_height(p)+2.25:return {"kind":"road","id":road.id}
	return {}
static func adjacency_signature(city:RefCounted,house:Dictionary)->Array:
	if city.house_era(house)!="modern_eco":return []
	var bounds:=Rect2(Vector2(house.origin[0],house.origin[1]),Vector2.ZERO)
	for cell:Dictionary in house.cells:bounds=bounds.expand(_center(house,cell))
	var result:Array=[city.terrain_policy]
	for other:Dictionary in city.houses:
		for cell:Dictionary in other.cells:
			if bounds.grow(Span.search_distance(city)+1.).has_point(_center(other,cell)):result.append([other.id,other.origin,other.get("base_y",0.),other.cells,other.get("architecture",""),Frame.yaw(other),city.house_era(other),other.get(Span.FIELD,{}),other.get(Pitch.FIELD,{}),other.get("architecture_variant",{})]);break
	for field:String in ["roads","terrain_strokes","waters","districts"]:
		for row:Dictionary in city.get(field):
			var influence:=_stroke_bounds(row.points).grow(float(row.get("radius",row.get("width",0.)))*1.5)
			if bounds.grow(Span.search_distance(city)+1.).intersects(influence):result.append([field,row])
	return result

static func _stroke_bounds(points:Array)->Rect2:
	var result:=Rect2(Vector2(points[0][0],points[0][1]),Vector2.ZERO)
	for point:Array in points:result=result.expand(Vector2(point[0],point[1]))
	return result.grow(.001)
