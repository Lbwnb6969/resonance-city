extends RefCounted
## Shared clockwork roof plans, including real caps, frames and clock geometry.
const P=preload("res://scripts/world/city_creation_roof_primitives.gd")
const Types=preload("res://scripts/world/city_creation_clockwork_pitched_types.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const Choice=preload("res://scripts/world/city_creation_architecture_variants.gd")
const Details=preload("res://scripts/world/city_creation_modern_roof_details.gd")
const IDS:=["","recessed_townhouse","sawtooth_atrium","clock_turret","iron_conservatory","guild_arcade"]
static func eligible(h:Dictionary)->bool:return not h.has("signature") and h.get("architecture","") in IDS and h.get("style","")!="round_tower" and is_zero_approx(Frame.Hinge.angle(h))
static func authored(h:Dictionary)->bool:return eligible(h) and h.get("roof_pitch",{}).get("version")==4 and h.roof_pitch.get("profile")=="clockwork"
static func kind(h:Dictionary)->String:return str(h.get("architecture","")) if str(h.get("architecture","")) not in ["","recessed_townhouse"] else "mansard"
static func source_angle(h:Dictionary)->float:return rad_to_deg(atan({"mansard":.72/.28,"sawtooth_atrium":.66/.6,"clock_turret":.42/.9,"iron_conservatory":.82/.86,"guild_arcade":.56/.9}[kind(h)]))
static func tops(city,h:Dictionary)->Array:
	var rows:Array=[]
	for other:Dictionary in city.houses:
		if str(other.id)!=str(h.id) and (city.house_era(other)!="clockwork" or not authored(other) or kind(other)!=kind(h) or other.roof_pitch!=h.roof_pitch or absf(Frame.yaw(h)-Frame.yaw(other))>.00001):continue
		var source:Dictionary=h if str(other.id)==str(h.id) else other
		for cell:Dictionary in source.cells:
			if cell.kind!="room" or source.cells.any(func(c):return c.x==cell.x and c.z==cell.z and int(c.level)>int(cell.level)):continue
			rows.append({"house":str(source.id),"cell":cell,"center":Frame.inverse(h,Frame.center(source,cell)),"base":float(source.get("base_y",0.))+(int(cell.level)+1)*1.7})
	return rows
static func sides(row:Dictionary,rows:Array)->Array:
	var result:Array=[]
	for side:Vector2 in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		if not rows.any(func(other):return absf(other.base-row.base)<.002 and Vector2(other.center).distance_to(row.center+side*1.8)<.002):result.append(side)
	return result
static func roof_height(distance:float,slope:float)->float:return .06+(minf(maxf(0.,distance)/.28,1.)*.72+clampf((distance-.28)/.72,0.,1.)*.22)*slope/(.72/.28)
static func mansard(row:Dictionary,rows:Array,slope:float)->Array:
	var boundaries:Array=[];var exposed:=sides(row,rows);var center:=Vector2(row.center);var rect:=Rect2(center-Vector2.ONE*.9,Vector2.ONE*1.8)
	for other:Dictionary in rows:
		if absf(other.base-row.base)>.002:continue
		for side:Vector2 in sides(other,rows):
			var tangent:=Vector2(-side.y,side.x);boundaries.append([Vector2(other.center)+side-tangent,Vector2(other.center)+side+tangent])
	for side:Vector2 in exposed:
		if side.x<0.:rect.position.x-=.1;rect.size.x+=.1
		elif side.x>0.:rect.size.x+=.1
		elif side.y<0.:rect.position.y-=.1;rect.size.y+=.1
		else:rect.size.y+=.1
	var sample:=func(at:Vector2)->Vector3:
		var distance:=INF
		for edge:Array in boundaries:distance=minf(distance,at.distance_to(Geometry2D.get_closest_point_to_segment(at,edge[0],edge[1])))
		return Vector3(at.x,row.base+roof_height(distance,slope),at.y)
	var parts:Array=[];var points:Array=[];var nx:=ceili(rect.size.x/.1);var nz:=ceili(rect.size.y/.1)
	for z in range(nz):
		for x in range(nx):
			var vertices:Array=[]
			for corner:Vector2 in [Vector2(x,z),Vector2(x+1,z),Vector2(x+1,z+1),Vector2(x,z+1)]:vertices.append(sample.call(rect.position+corner/Vector2(nx,nz)*rect.size))
			points.append_array([vertices[0],vertices[2],vertices[1],vertices[0],vertices[3],vertices[2]])
	P.face(parts,"ClockworkMansard",points,"mansard",true)
	for side:Vector2 in exposed:
		var axis:=Vector2(-side.y,side.x);var half:=rect.size.y*.5 if absf(side.x)>.5 else rect.size.x*.5;var midpoint:=rect.get_center()+side*(rect.size.x*.5 if absf(side.x)>.5 else rect.size.y*.5);var count:=ceili(half*2./.1)
		for i in range(count):
			var a:Vector3=sample.call(midpoint+axis*lerpf(-half,half,float(i)/count));var b:Vector3=sample.call(midpoint+axis*lerpf(-half,half,float(i+1)/count));P.quad(parts,"MansardClosedEave",a,Vector3(a.x,row.base-.005,a.z),Vector3(b.x,row.base-.005,b.z),b,"mansard")
	return parts
static func for_house(city,h:Dictionary)->Dictionary:
	var token:=hash([city.revision,city._wish_epoch,h]);var cache:Dictionary=city.get_meta("clockwork_pitched_plans",{});var id:=str(h.id)
	if cache.get(id,{}).get("token")==token:return cache[id].plan
	var rows:=tops(city,h);var own:Array=rows.filter(func(row):return row.house==id);own.sort_custom(func(a,b):return str(a.cell.id).naturalnocasecmp_to(str(b.cell.id))<0 if is_equal_approx(a.base,b.base) else a.base>b.base)
	var result:={"records":[],"patches":[],"details":{"details":[],"patches":[]}};var slope:=tan(deg_to_rad(float(h.roof_pitch.degrees)))
	for row:Dictionary in own:
		var parts:=mansard(row,rows,slope) if kind(h)=="mansard" else Types.build(kind(h),slope,sides(row,rows),row==own[0])
		if kind(h)=="mansard":
			if not (Choice.dormer_supported(city,h) and not Choice.dormer(h).is_empty()):auto_lights(parts,row)
		else:
			var offset:=Vector3(row.center.x,row.base,row.center.y)
			for part:Dictionary in parts:
				for i in range(part.vertices.size()):part.vertices[i]+=offset
		var metadata:={"cell_id":str(row.cell.id),"prototype":kind(h),"base":row.base,"degrees":float(h.roof_pitch.degrees)}
		result.records.append({"authored_clockwork":true,"parts":parts,"cell":row.cell,"center":row.center,"base":row.base,"prototype":kind(h),"feature":row==own[0],"metadata":metadata})
		for part:Dictionary in parts:
			var low:=INF
			for point:Vector3 in part.vertices:low=minf(low,point.y)
			result.patches.append({"surface":"roof","vertices":part.vertices,"base_y":low,"cell_id":str(row.cell.id),"part":part.name,"roof_skin":part.roof_skin})
	if not result.patches.is_empty():result.details=Details.plan(city,h,result.patches);result.patches.append_array(result.details.patches)
	cache[id]={"token":token,"plan":result};city.set_meta("clockwork_pitched_plans",cache);return result
static func auto_lights(parts:Array,row:Dictionary)->void:
	for side:Vector2 in [Vector2.UP,Vector2.DOWN]:
		var at:Vector2=row.center+side*.68;var height:float=preload("res://scripts/visual/city_creation_dormer_sites.gd").height(parts[0].vertices,at);var center:=maxf(.29,height-row.base-.16)
		P.box(parts,"MansardDormerWall",Vector3(.47,.46,.12),Vector3(at.x,row.base+center,at.y),"warm_stone");P.box(parts,"MansardDormerGlass",Vector3(.30,.30,.135),Vector3(at.x,row.base+center+.03,at.y+side.y*.065),"window_glass");P.box(parts,"MansardDormerCopperCap",Vector3(.55,.06,.22),Vector3(at.x,row.base+center+.27,at.y),"copper")
static func records(city,h:Dictionary)->Array:return for_house(city,h).records
