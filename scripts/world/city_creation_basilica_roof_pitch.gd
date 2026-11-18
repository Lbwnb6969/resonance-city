extends RefCounted
## Three basilican roofs share one authored gain; the lower hall stays unchanged.
const Plan=preload("res://scripts/world/city_creation_ancient_extension_plan.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const P=preload("res://scripts/world/city_creation_roof_primitives.gd")
const Arch=preload("res://scripts/visual/city_creation_architecture.gd")
const ID:="roman_basilica"
const CONTACT_GAP:=.001
static func eligible(h:Dictionary)->bool:return h.get("architecture","")==ID and not h.has("signature") and h.get("style","") not in ["timber","round_tower"] and is_zero_approx(Frame.Hinge.angle(h))
static func supported(city,h:Dictionary)->bool:return city.house_era(h)=="pastoral" and eligible(h) and not Plan.massing(city,h).is_empty()
static func authored(h:Dictionary)->bool:return h.get("architecture","")==ID and not h.has("signature") and h.get("roof_pitch",{}).get("version")==9 and h.roof_pitch.get("profile")=="roman_basilica"
static func active(city,h:Dictionary)->bool:return authored(h) and supported(city,h)
static func source_angle(city,h:Dictionary)->float:
	var p:=Plan.massing(city,h)
	return rad_to_deg(atan(.38/(float(p.width)*.23+.10))) if not p.is_empty() else 0.
static func for_house(city,h:Dictionary)->Dictionary:return from_plan(h,Plan.massing(city,h)) if active(city,h) else {"plan":{},"records":[],"patches":[],"apex":Vector3.ZERO}
static func _chart(vertices:Array,reference:float)->PackedVector2Array:
	var uv:=PackedVector2Array()
	for p:Vector3 in vertices:uv.append(Vector2(p.z/.22,signf(p.x)*Vector2(p.x,p.y-reference).length()/.28))
	return uv
static func _tile(parts:Array,name:String,vertices:Array,reference:float)->void:
	P.face(parts,name,vertices,"tile",true)
	parts[-1].uv=_chart(parts[-1].vertices,reference)
static func _clerestory(parts:Array,x:float,bottom:float,top:float,depth:float,main_slope:float,aisle_slope:float)->void:
	var start:=parts.size();var nave:=absf(x)
	var count:=maxi(2,roundi(depth*2/.75));var step:=depth*2/count
	P.box(parts,"BasilicaClerestorySill",Vector3(.10,.07,depth*2),Vector3(x,bottom+.035,0),"stone")
	P.box(parts,"BasilicaClerestoryLintel",Vector3(.13,.07,depth*2+.12),Vector3(x,top-.035,0),"stone")
	for i in range(count):
		P.box(parts,"BasilicaClerestoryPier",Vector3(.11,top-bottom,.09),Vector3(x,(top+bottom)*.5,-depth+i*step),"stone")
		P.box(parts,"BasilicaClerestoryGlass",Vector3(.018,top-bottom-.14,step-.12),Vector3(x,(top+bottom)*.5,-depth+(i+.5)*step),"glass")
	P.box(parts,"BasilicaClerestoryPier",Vector3(.11,top-bottom,.09),Vector3(x,(top+bottom)*.5,depth),"stone")
	for index in range(start,parts.size()):
		var part:Dictionary=parts[index]
		for j in range(part.vertices.size()):
			var point:Vector3=part.vertices[j];var original_y:=point.y;var low:=bottom+(nave-absf(point.x))*aisle_slope;var high:=top+(nave-absf(point.x))*main_slope
			if part.name=="BasilicaClerestorySill":point.y=low+point.y-bottom
			elif part.name=="BasilicaClerestoryLintel":point.y=high+point.y-top
			elif part.name=="BasilicaClerestoryGlass":point.y=high+point.y-top if point.y>(bottom+top)*.5 else low+point.y-bottom
			else:point.y=lerpf(low,high,(point.y-bottom)/(top-bottom))
			if part.name=="BasilicaClerestorySill" and original_y<bottom+.035:point.y+=CONTACT_GAP
			if part.name=="BasilicaClerestoryLintel" and original_y>top-.035 or part.name=="BasilicaClerestoryPier" and original_y>(bottom+top)*.5:point.y-=CONTACT_GAP
			part.vertices[j]=point
static func _closed_band(parts:Array,name:String,ring:Array[Vector3],heights:Array[float])->void:
	var corners:Array[Vector3]=ring.duplicate();var center:=Vector3.ZERO
	for i in range(4):corners.append(Vector3(ring[i].x,heights[i]-CONTACT_GAP,ring[i].z))
	for point:Vector3 in corners:center+=point
	center/=8.
	var faces:Array[Vector3]=[]
	for q:Array in [[0,1,2,3],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]]:
		for triangle:Array in [[q[0],q[1],q[2]],[q[0],q[2],q[3]]]:
			var a:Vector3=corners[triangle[0]];var b:Vector3=corners[triangle[1]];var c:Vector3=corners[triangle[2]]
			faces.append_array([a,c,b] if (b-a).cross(c-a).dot((a+b+c)/3.-center)<0. else [a,b,c])
	P.face(parts,name,faces,"stone")
static func _aisle_closures(parts:Array,half:float,nave:float,height:float,apse_z:float,depth:float,slope:float)->void:
	for side:float in [-1.,1.]:
		var outer:=side*half;var inner:=side*(half-.12);var yo:=height+.06+.10*slope;var yi:=height+.06+.22*slope
		_closed_band(parts,"BasilicaAisleRoofClosure",[Vector3(outer,height,apse_z),Vector3(outer,height,depth),Vector3(inner,height,depth),Vector3(inner,height,apse_z)],[yo,yo,yi,yi])
		for end:Vector2 in [Vector2(apse_z,apse_z+.12),Vector2(depth-.12,depth)]:
			var inside:=side*nave;var top_inner:=height+.06+(half+.10-nave)*slope
			_closed_band(parts,"BasilicaAisleEndClosure",[Vector3(outer,height,end.x),Vector3(outer,height,end.y),Vector3(inside,height,end.y),Vector3(inside,height,end.x)],[yo,yo,top_inner,top_inner])
static func _apse_closure(parts:Array,radius:float,apse_z:float,height:float,rise:float)->void:
	var high_outer:=height+.04+.07/(radius+.07)*rise;var high_inner:=height+.04+.17/(radius+.07)*rise
	for i in range(32):
		var a:=PI*i/32.;var b:=PI*(i+1)/32.;var ring:Array[Vector3]=[]
		for point:Vector2 in [Vector2(cos(a)*radius,-sin(a)*radius),Vector2(cos(b)*radius,-sin(b)*radius),Vector2(cos(b)*(radius-.10),-sin(b)*(radius-.10)),Vector2(cos(a)*(radius-.10),-sin(a)*(radius-.10))]:ring.append(Vector3(point.x,height,apse_z+point.y))
		_closed_band(parts,"BasilicaApseRoofClosure",ring,[high_outer,high_outer,high_inner,high_inner])
static func _source(h:Dictionary,p:Dictionary)->Dictionary:
	var parts:Array=[];var half:float=float(p.width)*.5;var depth:float=float(p.depth)*.5;var nave:float=float(p.width)*.23;var height:float=float(p.height)
	var radius:=minf(half*.72,depth*.65);var apse_z:float=-depth+radius;var gain:=tan(deg_to_rad(float(h.roof_pitch.degrees)))*(nave+.10)/.38
	var aisle_top:float=height+.06+.25*gain;var upper:float=height+.64+maxf(0.,.25*(gain-1.));var ridge:float=upper+.38*gain;var main_slope:=tan(deg_to_rad(float(h.roof_pitch.degrees)));var aisle_slope:float=.25*gain/(half+.10-nave);var clere_top:float=upper+.10*main_slope
	var nave_faces:Array[Vector3]=[];var aisle_faces:Array[Vector3]=[]
	for side:float in [-1.,1.]:
		var x:=side*(nave+.10);var outer:=side*(half+.10)
		var a:=Vector3(x,upper,-depth-.08);var b:=Vector3(x,upper,depth+.10);var c:=Vector3(0,ridge,depth+.10);var d:=Vector3(0,ridge,-depth-.08)
		nave_faces.append_array([a,c,b,a,d,c] if side>0. else [a,b,c,a,c,d])
		var u:=Vector3(outer,height+.06,apse_z);var v:=Vector3(outer,height+.06,depth+.10);var w:=Vector3(side*nave,aisle_top,depth+.10);var t:=Vector3(side*nave,aisle_top,apse_z)
		aisle_faces.append_array([u,w,v,u,t,w] if side>0. else [u,v,w,u,w,t])
		_clerestory(parts,side*nave,aisle_top,clere_top,depth,main_slope,aisle_slope)
	_tile(parts,"BasilicaNaveTileRoof",nave_faces,ridge);_tile(parts,"BasilicaAisleTileRoof",aisle_faces,upper)
	for z:float in [-depth,depth]:
		var polygon:=PackedVector2Array([Vector2(-nave,height),Vector2(nave,height),Vector2(nave,clere_top-CONTACT_GAP),Vector2(0,ridge-CONTACT_GAP),Vector2(-nave,clere_top-CONTACT_GAP)]);var faces:Array[Vector3]=[]
		for point:Vector3 in Arch._extrude(polygon,.12):faces.append(point+Vector3(0,0,z))
		P.face(parts,"CivicClosedGable",faces,"stone")
	var cap:Array[Vector3]=[];var uv:=PackedVector2Array();var columns:=maxi(8,roundi(PI*radius/.22));var rise:=.26*gain
	for i in range(32):
		var a:=PI*i/32.;var b:=PI*(i+1)/32.
		cap.append_array([Vector3(0,height+.04+rise,apse_z),Vector3(cos(a)*(radius+.07),height+.04,apse_z-sin(a)*(radius+.07)),Vector3(cos(b)*(radius+.07),height+.04,apse_z-sin(b)*(radius+.07))])
		uv.append_array(PackedVector2Array([Vector2((i+.5)*columns/32.,0),Vector2(float(i)*columns/32.,Vector2(radius+.07,rise).length()/.28),Vector2(float(i+1)*columns/32.,Vector2(radius+.07,rise).length()/.28)]))
	P.face(parts,"BasilicaApseTileRoof",cap,"tile",true);parts[-1].uv=uv
	_aisle_closures(parts,half,nave,height,apse_z,depth,aisle_slope);_apse_closure(parts,radius,apse_z,height,rise)
	return {"parts":parts,"clerestory_top":clere_top,"ridge":ridge,"upper":upper,"aisle_top":aisle_top,"apse_radius":radius,"gain":gain}
static func _clip(polygon:Array,axis:int,bound:float,keep_above:bool)->Array:
	var result:Array=[]
	if polygon.is_empty():return result
	var previous:Dictionary=polygon[-1];var before:bool=previous.p[axis]>=bound if keep_above else previous.p[axis]<=bound
	for current:Dictionary in polygon:
		var inside:bool=current.p[axis]>=bound if keep_above else current.p[axis]<=bound
		if inside!=before:
			var weight:float=(bound-float(previous.p[axis]))/(float(current.p[axis])-float(previous.p[axis]));result.append({"p":Vector3(previous.p).lerp(current.p,weight),"uv":Vector2(previous.uv).lerp(current.uv,weight)})
		if inside:result.append(current)
		previous=current;before=inside
	return result
static func _cut(part:Dictionary,bounds:Rect2)->Dictionary:
	var vertices:Array[Vector3]=[];var uv:=PackedVector2Array()
	for i in range(0,part.vertices.size(),3):
		var polygon:Array=[]
		for j in range(3):polygon.append({"p":part.vertices[i+j],"uv":part.uv[i+j] if part.has("uv") else Vector2.ZERO})
		polygon=_clip(polygon,0,bounds.position.x,true);polygon=_clip(polygon,0,bounds.end.x,false);polygon=_clip(polygon,2,bounds.position.y,true);polygon=_clip(polygon,2,bounds.end.y,false)
		for j in range(1,polygon.size()-1):
			var a:Vector3=polygon[0].p;var b:Vector3=polygon[j].p;var c:Vector3=polygon[j+1].p
			if (b-a).cross(c-a).length_squared()<=.0000000001:continue
			for index:int in [0,j,j+1]:vertices.append(polygon[index].p);uv.append(polygon[index].uv)
	return {"name":part.name,"vertices":vertices,"material":part.material,"roof_skin":part.roof_skin,"uv":uv}
static func from_plan(h:Dictionary,p:Dictionary)->Dictionary:
	var result:={"plan":p,"records":[],"patches":[],"apex":Vector3.ZERO}
	if p.is_empty():return result
	var source:=_source(h,p);var pose:=Transform3D(Basis.IDENTITY,Vector3(p.center.x,float(h.get("base_y",0.)),p.center.y));result.pose=pose
	for key:String in ["ridge","upper","aisle_top","apse_radius","gain","clerestory_top"]:result[key]=source[key]
	var high:=-INF
	for cell:Dictionary in h.cells:
		if int(cell.level)!=int(p.floors)-1:continue
		var at:Vector2=Frame.origin(h)+Vector2(cell.x,cell.z)*1.8-Vector2(p.center);var low:=at-Vector2.ONE*.9;var top:=at+Vector2.ONE*.9
		if is_equal_approx(low.x,-float(p.width)*.5):low.x-=.2
		if is_equal_approx(top.x,float(p.width)*.5):top.x+=.2
		if is_equal_approx(low.y,-float(p.depth)*.5):low.y-=.2
		if is_equal_approx(top.y,float(p.depth)*.5):top.y+=.2
		var parts:Array=[]
		for original:Dictionary in source.parts:
			var part:=_cut(original,Rect2(low,top-low))
			if part.vertices.is_empty():continue
			parts.append(part);var points:Array[Vector3]=[];var lowest:=INF
			for point:Vector3 in part.vertices:var world:Vector3=pose*point;points.append(world);lowest=minf(lowest,world.y)
			result.patches.append({"surface":"roof","base_y":lowest,"vertices":points,"cell_id":str(cell.id),"part":str(part.name),"roof_skin":part.roof_skin})
			if part.roof_skin:
				for i in range(0,points.size(),3):
					var center:Vector3=(points[i]+points[i+1]+points[i+2])/3.
					if center.y>high:high=center.y;result.apex=center
		result.records.append({"cell":cell.duplicate(true),"parts":parts})
	if float(h.roof_pitch.degrees)==0.:result.apex=pose*Vector3(float(p.width)*.23*.25,float(result.upper),float(p.depth)*.0615)
	return result
