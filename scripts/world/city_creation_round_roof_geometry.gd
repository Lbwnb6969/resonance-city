extends RefCounted
## One physical skin for rendering, picking, clearance and the flat-cap UV chart.
const SIDES:=16
const SAMPLES:=20
const RADIUS:=1.06
const LEGACY_HEIGHT:=1.35
const RADIUS_POWER:=.78
const EAVE_HEIGHT:=.065
const STEM_BOTTOM:=.028
const STEM_TOP:=.020
const STEM_HEIGHT:=.32
const STEM_SIZE:=Vector3(STEM_BOTTOM*2.,STEM_HEIGHT,STEM_BOTTOM*2.)
const BAR_SIZE:=Vector3(.42,.025,.025)
const FLAG:=[Vector3(.23,.26,0),Vector3(.09,.34,0),Vector3(.09,.18,0)]
static func authored(house:Dictionary)->bool:return house.get("roof_pitch",{}).get("version",0)==2 and house.get("roof_pitch",{}).get("profile","")=="round"
static func height(house:Dictionary)->float:return tan(deg_to_rad(float(house.roof_pitch.degrees)))*RADIUS if authored(house) else LEGACY_HEIGHT
static func eave_lift(house:Dictionary)->float:return -.0365 if authored(house) else .01
static func reach(y:float,house:Dictionary)->float:
	var h:=height(house)
	if h<.000001:return RADIUS if y<=0. else 0.
	var t:=clampf(y/h,0.,1.)
	return RADIUS*(1.-t) if authored(house) else RADIUS*pow(1.-t,RADIUS_POWER)+.03
static func surface_height(radius:float,house:Dictionary)->float:
	var t:=maxf(0.,1.-radius/RADIUS) if authored(house) else 1.-pow(radius/RADIUS,1./RADIUS_POWER)
	return height(house)*t
static func vertices(center:Vector3,house:Dictionary={})->Array[Vector3]:
	var result:Array[Vector3]=[];var h:=height(house);var custom:=authored(house)
	for row in range(SAMPLES-1):
		var t0:=float(row)/float(SAMPLES-1);var t1:=float(row+1)/float(SAMPLES-1)
		var r0:=RADIUS*(1.-t0) if custom else RADIUS*pow(1.-t0,RADIUS_POWER)
		var r1:=RADIUS*(1.-t1) if custom else RADIUS*pow(1.-t1,RADIUS_POWER)
		var y0:=h*t0+(0. if custom else .03*pow(maxf(0.,1.-t0/.18),2.))
		var y1:=h*t1+(0. if custom else .03*pow(maxf(0.,1.-t1/.18),2.))
		for side in range(SIDES):
			var a:=float(side)*TAU/float(SIDES);var b:=float(side+1)*TAU/float(SIDES)
			var aa:=center+Vector3(cos(a)*r0,y0,sin(a)*r0);var bb:=center+Vector3(cos(b)*r0,y0,sin(b)*r0);var cc:=center+Vector3(cos(b)*r1,y1,sin(b)*r1);var dd:=center+Vector3(cos(a)*r1,y1,sin(a)*r1)
			var normal:=Vector3(cos((a+b)*.5),.5,sin((a+b)*.5))
			_triangle(result,aa,bb,cc,normal)
			if row<SAMPLES-2:_triangle(result,aa,cc,dd,normal)
	return result
static func _triangle(vertices:Array[Vector3],a:Vector3,b:Vector3,c:Vector3,normal:Vector3)->void:
	if (b-a).cross(c-a).dot(normal)>=0.:vertices.append_array([a,b,c])
	else:vertices.append_array([a,c,b])
static func crown_bounds(at:Vector3)->Array[ AABB ]:
	return [AABB(at+Vector3(-.028,-.02,-.028),STEM_SIZE),AABB(at+Vector3(-.21,.2475,-.0125),BAR_SIZE),AABB(at+Vector3(.09,.18,-.003),Vector3(.14,.16,.006))]
static func parts(center:Vector2,eave:float,house:Dictionary)->Array:
	var result:Array=[];var top:=Vector3(center.x,eave+height(house),center.y)
	for box:AABB in crown_bounds(top):result.append({"bounds":box})
	result.append({"bounds":AABB(Vector3(center.x-RADIUS,eave+eave_lift(house)-EAVE_HEIGHT*.5,center.y-RADIUS),Vector3(RADIUS*2.,EAVE_HEIGHT,RADIUS*2.)),"radius":RADIUS})
	if house.get("role","")=="bakery":
		var offset:=Vector2(.43,-.30);var at:=Vector3(center.x+offset.x,eave+surface_height(offset.length(),house)+.24,center.y+offset.y)
		result.append({"bounds":AABB(at-Vector3(.10,.27,.10),Vector3(.20,.54,.20))})
		result.append({"bounds":AABB(at+Vector3(-.135,.245,-.135),Vector3(.27,.07,.27))})
	return result
static func footprint(part:Dictionary)->PackedVector2Array:
	var box:AABB=part.bounds;var result:=PackedVector2Array()
	if part.has("radius"):
		var center:=box.get_center()
		for i in range(SIDES):result.append(Vector2(center.x,center.z)+Vector2.from_angle(float(i)*TAU/SIDES)*float(part.radius))
	else:result=PackedVector2Array([Vector2(box.position.x,box.position.z),Vector2(box.end.x,box.position.z),Vector2(box.end.x,box.end.z),Vector2(box.position.x,box.end.z)])
	return result
