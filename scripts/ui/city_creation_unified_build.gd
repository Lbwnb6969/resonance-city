extends RefCounted
## One build gesture: ground room, attached room, or supported upper terrace.
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const UNIT:=1.8
static func cell_candidate(city:RefCounted,house:Dictionary,target:Dictionary)->Dictionary:
	var below:bool=house.cells.any(func(c):return c.x==target.x and c.z==target.z and int(c.level)==int(target.level)-1 and c.kind=="room")
	target.kind="terrace" if int(target.level)>0 and not below else "room"
	var check:Dictionary=city.validate_add_cell(house.id,int(target.x),int(target.z),int(target.level),target.kind)
	return {"house_id":house.id,"cell":target,"valid":check.ok,"reason":check.message,"snap":true,"stroke_height":float(house.get("base_y",0.))+int(target.level)*1.7,"host_name":house.name}
static func resolve(city:RefCounted,hit:Dictionary,ground:Vector2,free:bool=false)->Dictionary:
	var body:Object=hit.get("collider")
	var id:String=str(hit.get("house_id",""))
	if id.is_empty() and body!=null and body.has_meta("house_id"):id=str(body.get_meta("house_id"))
	if not id.is_empty():
		var index:int=city._house_index(id)
		if index>=0:
			var house:Dictionary=city.houses[index]
			var cid:String=str(hit.get("cell_id",body.get_meta("cell_id") if body!=null and body.has_meta("cell_id") else ""))
			for cell:Dictionary in house.cells:
				if cell.id!=cid:continue
				var normal:Vector3=Frame.design_normal(house,hit.normal,cell)
				var target:=cell.duplicate(true)
				if _roof_hit(hit,body) or normal.y>.45:target.level=int(cell.level)+1
				elif absf(normal.x)>absf(normal.z):target.x=int(cell.x)+(1 if normal.x>0. else -1)
				else:target.z=int(cell.z)+(1 if normal.z>0. else -1)
				return cell_candidate(city,house,target)
	if not free:
		var nearest:Dictionary={};var best:=.55*.55
		for house:Dictionary in city.houses:
			if house.has("signature"):continue
			for cell:Dictionary in house.cells:
				if int(cell.level)!=0 or cell.kind!="room":continue
				for side:Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var target:={"x":int(cell.x)+side.x,"z":int(cell.z)+side.y,"level":0,"kind":"room"}
					if house.cells.any(func(c):return c.x==target.x and c.z==target.z and c.level==0):continue
					var at:=Frame.center(house,target);var distance:=at.distance_squared_to(ground)
					if distance>=best:continue
					best=distance;nearest=cell_candidate(city,house,target)
		if not nearest.is_empty():return nearest
	var check:Dictionary=city.validate_add_house(ground)
	return {"new_house":ground,"base_y":city.sample_house_base_y(ground),"valid":check.ok,"reason":check.message}
static func _roof_hit(hit:Dictionary,body:Object)->bool:
	if body==null:return false
	if body.get_meta("roof_surface",false):return true
	if not body is CollisionObject3D or not hit.has("shape"):return false
	var owner:Object=body.shape_owner_get_owner(body.shape_find_owner(int(hit.shape)))
	return owner!=null and owner.get_meta("roof_surface",false)
static func hover(demo:Node3D)->bool:
	if demo.tool!=0:return false
	demo.candidate=resolve(demo.state,demo.hovered,demo._ground_at(demo.pointer),Input.is_key_pressed(KEY_ALT))
	var key:=str(demo.candidate)
	if key==demo.preview_key:return true
	demo.preview_key=key;demo.town.clear_preview()
	if demo.candidate.has("cell"):demo.town.set_preview(demo.candidate.house_id,demo.candidate.cell,demo.candidate.valid)
	else:
		var at:Vector2=demo.candidate.new_house
		demo.town.set_preview("",{"x":0,"z":0,"level":0,"kind":"room","origin":[at.x,at.y],"base_y":demo.candidate.base_y},demo.candidate.valid)
	demo.chemistry_brush.building(demo.candidate)
	return true
static func stroke_height(demo:Node3D)->float:
	return float(demo.candidate.get("stroke_height",demo.hovered.get("position",Vector3.ZERO).y))
static func hint(demo:Node3D)->String:
	if demo.house_drawing:
		return "松开建成整笔 · Esc 取消" if demo.house_stroke_result.get("ok",false) else str(demo.house_stroke_result.get("message","本笔未落定"))
	if not demo.candidate.get("valid",true):return str(demo.candidate.reason)
	if demo.candidate.has("cell"):
		return "吸附 %s · 第%d层%s · 拖动连建"%[demo.candidate.get("host_name",demo.candidate.house_id),int(demo.candidate.cell.level)+1,"露台" if demo.candidate.cell.kind=="terrace" else "房间"]
	return "点地筑屋 · 靠屋吸附营造 · Alt 自由落点"
