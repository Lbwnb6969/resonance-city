extends RefCounted
## Authored bent timber: shared metric triangles for skin, ribs and reflectors.
const Plan=preload("res://scripts/world/city_creation_acoustic_shell.gd")
const P=preload("res://scripts/world/city_creation_roof_primitives.gd")
const THICKNESS:=.07
static func eligible(h:Dictionary)->bool:return Plan.selected(h) and is_zero_approx(Plan.Frame.Hinge.angle(h))
static func authored(h:Dictionary)->bool:return Plan.selected(h) and h.get("roof_pitch",{}).get("version")==7 and h.roof_pitch.get("profile")=="acoustic_shell"
static func active(city,h:Dictionary)->bool:return authored(h) and Plan.active(city,h)
static func supported(city,h:Dictionary)->bool:return eligible(h) and Plan.active(city,h)
static func source_angle(city,h:Dictionary)->float:
	var plan:=Plan.for_house(city,h)
	return rad_to_deg(atan(float(plan.height)/(float(plan.depth)-.08))) if not plan.is_empty() else 0.
static func for_house(city,h:Dictionary)->Dictionary:
	return from_plan(h,Plan.for_house(city,h)) if active(city,h) else {"plan":{},"records":[],"patches":[],"apex":Vector3.ZERO}
static func from_plan(h:Dictionary,plan:Dictionary)->Dictionary:
	var result:={"plan":plan,"records":[],"patches":[],"apex":Vector3.ZERO}
	if plan.is_empty():return result
	var pose:=Transform3D(Basis(Vector3.UP,float(plan.angle)),Vector3(plan.center.x,float(plan.base_y),plan.center.y));result.pose=pose
	var half:float=float(plan.width)*.5-.04;var lanes:=roundi(float(plan.width)/1.8);var steps:=maxi(12,roundi(float(plan.depth)/1.8)*12);var high:=-INF
	for lane in range(lanes):
		var x0:float=-half+lane*(half*2.)/lanes;var x1:float=-half+(lane+1)*(half*2.)/lanes
		for i in range(steps):
			var a:=Plan.point(plan,float(i)/steps);var b:=Plan.point(plan,float(i+1)/steps);var normal:=Vector2(b.y-a.y,-(b.x-a.x)).normalized()*THICKNESS
			var points:Array[Vector3]=[Vector3(x0,a.x,a.y),Vector3(x0,b.x,b.y),Vector3(x1,b.x,b.y),Vector3(x1,a.x,a.y)];var inside:Array[Vector3]=[]
			for p:Vector3 in points:inside.append(p-Vector3(0,normal.x,normal.y))
			var faces:Array[Vector3]=[points[0],points[1],points[2],points[0],points[2],points[3],inside[0],inside[2],inside[1],inside[0],inside[3],inside[2]]
			for j in range(4):var k:=(j+1)%4;faces.append_array([points[j],inside[j],inside[k],points[j],inside[k],points[k]])
			var parts:Array=[];P.face(parts,"CurvedTimberSkin",faces,"wood",true)
			for x:float in [x0,x1] if lane==lanes-1 else [x0]:P.beam(parts,"AcousticQuietRib",Vector3(x,a.x-normal.x-.018,a.y-normal.y),Vector3(x,b.x-normal.x-.018,b.y-normal.y),.045,"dark")
			var ends:Array=[]
			if lane==0:ends.append(x0)
			if lane==lanes-1:ends.append(x1)
			for x:float in ends:
				var corners:Array[Vector3]=[Vector3(x,.15,a.y),Vector3(x,a.x,a.y),Vector3(x,b.x,b.y),Vector3(x,.15,b.y)]
				var side:Array[Vector3]=[corners[0],corners[1],corners[2],corners[0],corners[2],corners[3]];var inward:=Vector3(THICKNESS if x<0. else -THICKNESS,0,0)
				if x<0.:
					for j in range(0,side.size(),3):var p:=side[j+1];side[j+1]=side[j+2];side[j+2]=p
				var outer:Array[Vector3]=side.duplicate()
				for j in range(0,outer.size(),3):side.append_array([outer[j]+inward,outer[j+2]+inward,outer[j+1]+inward])
				for j in range(4):var k:=(j+1)%4;side.append_array([corners[j],corners[k],corners[k]+inward,corners[j],corners[k]+inward,corners[j]+inward])
				var center:Vector3=(corners[0]+corners[1]+corners[2]+corners[3])*.25+inward*.5
				for j in range(0,side.size(),3):
					var normal3:Vector3=(side[j+1]-side[j]).cross(side[j+2]-side[j]);var middle:Vector3=(side[j]+side[j+1]+side[j+2])/3.
					if normal3.dot(middle-center)<0.:var p:=side[j+1];side[j+1]=side[j+2];side[j+2]=p
				P.face(parts,"TimberReflectorCheek",side,"wood")
			if i==0 and a.x>.180001:P.box(parts,"AcousticRearClosure",Vector3(x1-x0,a.x-.15,THICKNESS),Vector3((x0+x1)*.5,(a.x+.15)*.5,a.y+THICKNESS*.5),"wood")
			var cell:=Plan.cell_at(h,plan,Vector2((x0+x1)*.5,(a.y+b.y)*.5));result.records.append({"cell":cell,"lane":lane,"step":i,"parts":parts})
			for part:Dictionary in parts:
				var vertices:Array[Vector3]=[];var low:=INF
				for p:Vector3 in part.vertices:var transformed:Vector3=pose*p;vertices.append(transformed);low=minf(low,transformed.y)
				result.patches.append({"surface":"roof","base_y":low,"vertices":vertices,"cell_id":str(cell.id),"part":str(part.name),"roof_skin":part.roof_skin})
				if part.roof_skin:
					for j in range(0,part.vertices.size(),3):
						var center:Vector3=pose*((part.vertices[j]+part.vertices[j+1]+part.vertices[j+2])/3.)
						if center.y>high:high=center.y;result.apex=center
	var mouth:=Plan.point(plan,1.);var mouth_parts:Array=[];P.box(mouth_parts,"AcousticMouthLintel",Vector3(float(plan.width),.085,.085),Vector3(0,mouth.x-.035,mouth.y-.025),"dark")
	for x:float in [-half,half]:P.box(mouth_parts,"AcousticMouthJamb",Vector3(.075,mouth.x-.18,.075),Vector3(x,(mouth.x+.18)*.5,mouth.y-.025),"dark")
	var mouth_cell:=Plan.cell_at(h,plan,Vector2(0,mouth.y));result.records.append({"cell":mouth_cell,"lane":-1,"step":-1,"parts":mouth_parts})
	for part:Dictionary in mouth_parts:
		var vertices:Array[Vector3]=[];var low:=INF
		for p:Vector3 in part.vertices:var transformed:Vector3=pose*p;vertices.append(transformed);low=minf(low,transformed.y)
		result.patches.append({"surface":"roof","base_y":low,"vertices":vertices,"cell_id":str(mouth_cell.id),"part":str(part.name),"roof_skin":false})
	return result
