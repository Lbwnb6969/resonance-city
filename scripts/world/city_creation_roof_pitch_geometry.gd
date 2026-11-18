extends RefCounted
const FIELD:="roof_pitch"
const MAX_DEGREES:=78.
static func ordinary(house:Dictionary)->bool:
	return not house.has("signature") and str(house.get("architecture","")) in ["","townhouse","recessed_townhouse"] and house.get("style","classic") in ["classic","timber","stone"] and house.get("era_theme","pastoral") in ["pastoral","renaissance"] and is_zero_approx(float(house.get("bend_angle_deg",0.)))
static func degrees(house:Dictionary)->float:
	if house.get("era_theme","pastoral")=="pastoral" and house.get("architecture","")=="portico" and house.get(FIELD,{}).get("version")==10 and house.roof_pitch.get("profile")=="portico" and not house.has("signature") and house.get("style","") not in ["timber","round_tower"] and is_zero_approx(float(house.get("bend_angle_deg",0.))):return float(house.roof_pitch.degrees)
	if preload("res://scripts/world/city_creation_boathouse_roof_pitch.gd").authored(house):return float(house.roof_pitch.degrees)
	return float(house[FIELD].degrees) if house.get(FIELD,{}).get("version",0)==1 and ordinary(house) else -1.
static func point(p:Vector2,base:float,nearest:float,axis:float,pitch:float)->Vector3:
	var rise:=tan(deg_to_rad(pitch))*nearest if pitch>=0. else .55*pow(nearest,.5+.62)
	var sag:=0. if pitch>=0. else -.025*sin(axis*PI)*minf(nearest,1.)
	return Vector3(p.x,base+rise+sag,p.y)
static func temple(house:Dictionary)->Dictionary:
	if degrees(house)<0. or (str(house.get("architecture","")) not in ["","portico"] and not preload("res://scripts/world/city_creation_boathouse_roof_pitch.gd").authored(house)) or house.get("style","")=="timber" or house.get("era_theme","pastoral")!="pastoral" or house.cells.any(func(c):return int(c.level)!=0 or c.kind!="room"):return {}
	var low:=Vector2i(house.cells[0].x,house.cells[0].z);var high:=low
	for c:Dictionary in house.cells:low=Vector2i(mini(low.x,c.x),mini(low.y,c.z));high=Vector2i(maxi(high.x,c.x),maxi(high.y,c.z))
	if house.cells.size()!=(high.x-low.x+1)*(high.y-low.y+1):return {}
	return {"center":Vector2(house.origin[0],house.origin[1])+Vector2(low+high)*.9,"width":(high.x-low.x+1)*1.8,"depth":(high.y-low.y+1)*1.8,"base":float(house.get("base_y",0.))}
static func temple_patches(group:Array,id:String)->Array:
	var row:Dictionary=group[0];var plan:Dictionary=row.pitch_temple;var center:Vector2=plan.center;var half:float=plan.width*.5+.13;var back:float=center.y-plan.depth*.5-.12;var front:float=center.y+plan.depth*.5+.47;var base:float=plan.base+1.8;var top:float=base+tan(deg_to_rad(row.pitch))*half
	var a:=Vector3(center.x-half,base,back);var b:=Vector3(center.x+half,base,back);var c:=Vector3(center.x-half,base,front);var d:=Vector3(center.x+half,base,front);var r0:=Vector3(center.x,top,back);var r1:=Vector3(center.x,top,front)
	var faces:Array[Vector3]=[a,c,r1,a,r1,r0,r0,r1,d,r0,d,b];var bounds:=Rect2(Vector2(a.x,a.z),Vector2(half*2.,front-back));var result:Array=[{"house_id":row.house_id,"cell_id":row.cell_id,"vertices":faces,"surface":"roof","group_id":id,"bounds":bounds,"base_y":base,"roof_kind":"temple"}]
	var sample:=func(p:Vector2)->Vector3:return Vector3(p.x,base+tan(deg_to_rad(row.pitch))*maxf(0.,half-absf(p.x-center.x)),p.y)
	preload("res://scripts/visual/city_creation_joined_roof_coordinates.gd").assign(result,{"along_x":false},bounds,sample)
	return result
