extends RefCounted
## Two metric roof planes retain the Ionic hall's unequal front/back overhangs.
const Plan=preload("res://scripts/world/city_creation_ancient_extension_plan.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const P=preload("res://scripts/world/city_creation_roof_primitives.gd")
const Arch=preload("res://scripts/visual/city_creation_architecture.gd")
const ID:="ionic_stoa"
static func eligible(h:Dictionary)->bool:return h.get("architecture","")==ID and not h.has("signature") and h.get("style","") not in ["timber","round_tower"] and is_zero_approx(Frame.Hinge.angle(h))
static func supported(city,h:Dictionary)->bool:return city.house_era(h)=="pastoral" and eligible(h) and not Plan.massing(city,h).is_empty()
static func authored(h:Dictionary)->bool:return h.get("architecture","")==ID and not h.has("signature") and h.get("roof_pitch",{}).get("version")==8 and h.roof_pitch.get("profile")=="ionic_stoa"
static func active(city,h:Dictionary)->bool:return authored(h) and supported(city,h)
static func source_angle(city,h:Dictionary)->float:
	var plan:=Plan.massing(city,h)
	return rad_to_deg(atan(minf(.65,float(plan.depth)*.25)/(float(plan.depth)*.5+.12))) if not plan.is_empty() else 0.
static func for_house(city,h:Dictionary)->Dictionary:
	return from_plan(h,Plan.massing(city,h)) if active(city,h) else {"plan":{},"records":[],"patches":[],"apex":Vector3.ZERO}
static func _height(z:float,back:float,front:float,eave:float,rise:float)->float:return eave+rise*(1.-z/(back if z<0. else front))
static func from_plan(h:Dictionary,plan:Dictionary)->Dictionary:
	var result:={"plan":plan,"records":[],"patches":[],"apex":Vector3.ZERO}
	if plan.is_empty():return result
	var pose:=Transform3D(Basis.IDENTITY,Vector3(plan.center.x,float(h.get("base_y",0.)),plan.center.y));result.pose=pose
	var half:float=float(plan.width)*.5+.14;var back:float=-float(plan.depth)*.5-.12;var front:float=float(plan.depth)*.5+.84
	var eave:float=float(plan.height)+.12;var rise:float=(-back)*tan(deg_to_rad(float(h.roof_pitch.degrees)));result.ridge=eave+rise
	var high:=-INF
	for cell:Dictionary in h.cells:
		if int(cell.level)!=int(plan.floors)-1:continue
		var center:Vector2=Frame.origin(h)+Vector2(cell.x,cell.z)*1.8-Vector2(plan.center);var x0:=center.x-.9;var x1:=center.x+.9;var z0:=center.y-.9;var z1:=center.y+.9
		if is_equal_approx(x0,-float(plan.width)*.5):x0=-half
		if is_equal_approx(x1,float(plan.width)*.5):x1=half
		if is_equal_approx(z0,-float(plan.depth)*.5):z0=back
		if is_equal_approx(z1,float(plan.depth)*.5):z1=front
		var parts:Array=[]
		for interval:Vector2 in [Vector2(z0,minf(z1,0.)),Vector2(maxf(z0,0.),z1)]:
			if interval.y-interval.x<.000001:continue
			var a:=Vector3(x0,_height(interval.x,back,front,eave,rise),interval.x);var b:=Vector3(x1,a.y,interval.x);var c:=Vector3(x1,_height(interval.y,back,front,eave,rise),interval.y);var d:=Vector3(x0,c.y,interval.y)
			P.face(parts,"IonicContinuousTileRoof",[a,c,b,a,d,c],"tile",true)
		for side:float in [-1.,1.]:
			if rise<.000001 or not is_equal_approx(center.x+side*.9,side*float(plan.width)*.5):continue
			# Each end wall belongs to the top room nearest its actual centroid.
			var gable_z:float=(back+front)/3.
			if gable_z<z0 or gable_z>z1:continue
			var transform:=Transform3D(Basis(Vector3.UP,-PI*.5),Vector3(side*half,0,0));var vertices:Array[Vector3]=[]
			for point:Vector3 in Arch._extrude(PackedVector2Array([Vector2(back,eave),Vector2(front,eave),Vector2(0,eave+rise)]),.12):vertices.append(transform*point)
			P.face(parts,"CivicClosedGable",vertices,"stone")
		result.records.append({"cell":cell.duplicate(true),"parts":parts})
		for part:Dictionary in parts:
			var vertices:Array[Vector3]=[];var low:=INF
			for point:Vector3 in part.vertices:var at:Vector3=pose*point;vertices.append(at);low=minf(low,at.y)
			result.patches.append({"surface":"roof","base_y":low,"vertices":vertices,"cell_id":str(cell.id),"part":str(part.name),"roof_skin":part.roof_skin})
			if part.roof_skin:
				for i in range(0,part.vertices.size(),3):
					var at:Vector3=pose*((part.vertices[i]+part.vertices[i+1]+part.vertices[i+2])/3.)
					if at.y>high:high=at.y;result.apex=at
	return result
