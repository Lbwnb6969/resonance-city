extends RefCounted
## Four static rings follow species-shaped centre lines; endpoints stay joined.
const RINGS:=4
const SIDES:=7
static func _center(start:Vector3,end:Vector3,t:float,normal:Vector3,side:Vector3,bend:float,twist:float)->Vector3:
	return start.lerp(end,t)+normal*sin(PI*t)*bend+side*(sin(TAU*t)*twist+sin(PI*t)*.22)*bend
static func append(data:Dictionary,start:Vector3,end:Vector3,low:float,high:float,kind:String)->void:
	var axis:Vector3=(end-start).normalized();var length:float=start.distance_to(end)
	var normal:Vector3=axis.cross(Vector3.FORWARD).normalized()
	if normal.length_squared()<.1:normal=Vector3.RIGHT
	var side:Vector3=axis.cross(normal).normalized()
	var strength:float={"olive":.12,"cypress":.027,"golden_tree":.15,"flower":.04}.get(kind,.08)
	var phase:float=float(posmod(hash([start,end]),997))/997.*TAU
	if kind=="golden_tree":
		var up:Vector3=Vector3.UP-axis*axis.dot(Vector3.UP)
		if up.length_squared()>.01:normal=up.normalized();side=axis.cross(normal).normalized()
	else:
		var turned:Vector3=normal*cos(phase)+side*sin(phase);side=axis.cross(turned).normalized();normal=turned
	var bend:float=length*strength;var twist:float=.32 if kind=="cypress" else .18
	var first:int=data.vertices.size()
	for ring in range(RINGS):
		var t:float=float(ring)/float(RINGS-1)
		var at:Vector3=_center(start,end,t,normal,side,bend,twist)
		var tangent:Vector3=(_center(start,end,minf(1.,t+.001),normal,side,bend,twist)-_center(start,end,maxf(0.,t-.001),normal,side,bend,twist)).normalized()
		var across:Vector3=(normal-tangent*normal.dot(tangent)).normalized();var around:Vector3=tangent.cross(across).normalized()
		var radius:float=lerpf(low,high,pow(t,.88))
		if start.y<.08 and low>.03:radius*=1.+.36*exp(-t*8.)
		var ring_start:int=data.vertices.size()
		for sector in range(SIDES):
			var angle:float=TAU*float(sector)/float(SIDES)
			var radial:Vector3=across*cos(angle)+around*sin(angle)
			var root_ridge:float=1.+.14*pow(maxf(0.,cos(angle*3.+phase)),4.)*exp(-t*10.) if start.y<.08 and low>.03 else 1.
			data.vertices.append(at+radial*radius*root_ridge)
			data.normals.append((radial+tangent*(low-high)/maxf(.0001,length)).normalized())
			data.colors.append(Color("70553f").lerp(Color("b49b7c"),clampf(at.y/3.5,0.,1.)))
		var centroid:=Vector3.ZERO
		for i in range(SIDES):centroid+=data.vertices[ring_start+i]/float(SIDES)
		for i in range(SIDES):data.vertices[ring_start+i]+=at-centroid
	for ring in range(RINGS-1):
		for sector in range(SIDES):
			var a:int=first+ring*SIDES+sector;var b:int=first+ring*SIDES+(sector+1)%SIDES
			data.indices.append_array([a,a+SIDES,b,b,a+SIDES,b+SIDES])

static func caps(data:Dictionary,first:int)->void:
	for top:bool in [false,true]:
		var ring:=first+(RINGS-1)*SIDES if top else first
		var center:=Vector3.ZERO
		for i in range(SIDES):center+=data.vertices[ring+i]/float(SIDES)
		var normal:Vector3=(data.vertices[ring+1]-data.vertices[ring]).cross(data.vertices[ring+2]-data.vertices[ring]).normalized()*(1. if top else -1.)
		var base:int=data.vertices.size()
		for i in range(SIDES):data.vertices.append(data.vertices[ring+i]);data.normals.append(normal);data.colors.append(data.colors[ring+i])
		var middle:int=data.vertices.size();data.vertices.append(center);data.normals.append(normal);data.colors.append(data.colors[ring])
		for i in range(SIDES):
			var next:int=base+(i+1)%SIDES
			data.indices.append_array([base+i,middle,next] if top else [base+i,next,middle])
