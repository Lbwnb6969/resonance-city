extends RefCounted
## Exterior surfaces in the facing room's local frame, before the saved yaw.
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const Alpine=preload("res://scripts/world/city_creation_alpine_plan.gd")
const Policy=preload("res://scripts/world/city_creation_creation_policy.gd")
const Frontage=preload("res://scripts/world/city_creation_frontage.gd")
const DECK_SIZE:=Vector3(1.92,.10,.58)
const DECK_CENTER:=Vector3(0,.16,.75)
const DECK_TOP:=DECK_CENTER.y+DECK_SIZE.y*.5
const TREAD_HALF_WIDTH:=.48
const TREAD_FROM:=DECK_CENTER.z+DECK_SIZE.z*.5
const TREAD_TO:=1.29
const TREAD_TOP:=.095
const ENTRY_START:=.07

static func facing(house:Dictionary)->bool:
	return Alpine.kind_for(house)==Alpine.Kind.STEPPED_TERRACE_HOUSE

static func for_entry(city:RefCounted,house:Dictionary,entry:Dictionary)->Dictionary:
	if not facing(house) or entry.side!=Alpine.front(city,house):return {}
	var cell_pos:=Vector2(entry.cell_x,entry.cell_z)
	return build(city,house,cell_pos,entry.side,true)

static func signature(city:RefCounted,house:Dictionary)->Array:
	if city.house_era(house)!="modern_eco" or not facing(house):return []
	var side:=Alpine.front(city,house)
	var doors:Dictionary={}
	for entry:Dictionary in city.house_entrances(house.id):
		if entry.side==side and not entry.active:doors[entry.cell_id]=true
	var result:Array=[side]
	for cell:Dictionary in house.cells:
		if cell.level==0 and cell.kind=="room" and Frontage.exposed(house,cell,side):
			result.append(build(city,house,Vector2(cell.x,cell.z),side,doors.has(cell.id)))
	return result

static func build(city:RefCounted,house:Dictionary,cell_pos:Vector2,side:Vector2i,door:bool)->Dictionary:
	var direction:=Vector2(side)
	var tangent:=Vector2(direction.y,-direction.x)
	var center:=Frame.origin(house)+cell_pos*1.8
	var base:=float(house.get("base_y",0.))
	var supports:Array=[]
	for x:float in [-.76,0.,.76]:
		var at:=Frame.point(house,center+tangent*x+direction*.97)
		var ground:float=city.raw_terrain_height(at)-base
		if ground>.10:return {}
		supports.append({"x":x,"ground":ground})
	var result:={"supports":supports,"tread":false}
	if not door or not Policy.is_free(city):return result
	var bottom:=TREAD_TOP
	for x:float in [-TREAD_HALF_WIDTH,0.,TREAD_HALF_WIDTH]:
		for z:float in [TREAD_FROM,(TREAD_FROM+TREAD_TO)*.5,TREAD_TO]:
			var at:=Frame.point(house,center+tangent*x+direction*z)
			var ground:float=city.ground_height(at)-base
			if city.water_clearance(at)<.05 or ground<TREAD_TOP-.12 or ground>TREAD_TOP+.002:return result
			bottom=minf(bottom,ground)
	result.tread=true
	result.tread_size=Vector3(TREAD_HALF_WIDTH*2.,TREAD_TOP-bottom+.04,TREAD_TO-TREAD_FROM)
	result.tread_center=Vector3(0.,(TREAD_TOP+bottom-.04)*.5,(TREAD_FROM+TREAD_TO)*.5)
	return result

static func surfaces(plan:Dictionary,base:float)->Array:
	if plan.is_empty():return []
	var result:Array=[[DECK_CENTER.z-.9,DECK_SIZE.z*.5,DECK_SIZE.x*.5,base+DECK_TOP,"terrace_platform_step"]]
	if plan.tread:
		var size:Vector3=plan.tread_size;var center:Vector3=plan.tread_center
		result.append([center.z-.9,size.z*.5,size.x*.5,base+TREAD_TOP,"terrace_ground_step"])
	return result
