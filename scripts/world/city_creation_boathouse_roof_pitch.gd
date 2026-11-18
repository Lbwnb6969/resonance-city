extends RefCounted
## The main roof and wet-slip canopy share an explicit recipe, never old v1 data.
const ID:="creek_boathouse"
static func eligible(h:Dictionary)->bool:
	return h.get("architecture","")==ID and not h.has("signature") and h.get("style","")!="round_tower" and is_zero_approx(float(h.get("bend_angle_deg",0.)))
static func authored(h:Dictionary)->bool:
	return eligible(h) and h.get("roof_pitch",{}).get("version")==6 and h.roof_pitch.get("profile")=="boathouse" and h.get("era_theme","pastoral")=="pastoral"
static func ridge(h:Dictionary)->float:return 1.64+1.08*tan(deg_to_rad(float(h.roof_pitch.degrees))) if authored(h) else 2.18
static func clearance(h:Dictionary)->float:return maxf(1.72,ridge(h)+.12) if authored(h) else 2.3
static func faces(h:Dictionary)->Array[Vector3]:
	var y:=ridge(h)
	return [Vector3(-1.08,1.64,-.02),Vector3(-1.08,1.64,2.14),Vector3(0,y,2.14),Vector3(-1.08,1.64,-.02),Vector3(0,y,2.14),Vector3(0,y,-.02),Vector3(0,y,-.02),Vector3(0,y,2.14),Vector3(1.08,1.64,2.14),Vector3(0,y,-.02),Vector3(1.08,1.64,2.14),Vector3(1.08,1.64,-.02)]
static func patches(h:Dictionary,plan:Dictionary)->Array:
	if plan.is_empty():return []
	var frame=preload("res://scripts/world/city_creation_house_frame.gd")
	var point:Vector2=frame.inverse(h,plan.wall)
	var pose:=Transform3D(Basis(Vector3.UP,atan2(float(plan.normal.x),float(plan.normal.y))-frame.yaw(h)),Vector3(point.x,float(plan.top),point.y))
	var vertices:Array[Vector3]=[]
	for p:Vector3 in faces(h):vertices.append(pose*p)
	return [{"surface":"roof","base_y":float(plan.top)+1.64,"vertices":vertices,"cell_id":plan.cell_id,"part":"BoathouseSlipRoof","roof_skin":true}]
