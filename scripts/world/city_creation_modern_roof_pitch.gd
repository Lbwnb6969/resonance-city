extends RefCounted
## Authored modern roof geometry, shared by rendering, picking and clearance.
const Plan=preload("res://scripts/world/city_creation_alpine_plan.gd")
const ARCHITECTURES:=["","chalet","pavilion","terrace","panorama","twin_gable","green_lodge","recessed_townhouse","cantilever_tea_deck"]
static func eligible(h:Dictionary)->bool:return not h.has("signature") and h.get("architecture","") in ARCHITECTURES and is_zero_approx(float(h.get("bend_angle_deg",0.)))
static func authored(h:Dictionary)->bool:return eligible(h) and h.get("roof_pitch",{}).get("version",0)==3 and h.roof_pitch.get("profile","")=="modern"
static func top(h:Dictionary,c:Dictionary)->bool:return not h.cells.any(func(a):return a.x==c.x and a.z==c.z and int(a.level)>int(c.level))
static func source_angle(h:Dictionary)->float:return [34.48,13.91,0.,28.93,56.42,0.][Plan.kind_for(h)]
static func cell_plan(city,h:Dictionary,cell:Dictionary)->Dictionary:
	var angle:float=float(h.roof_pitch.degrees);var slope:=tan(deg_to_rad(angle));var kind:=Plan.kind_for(h);var y:float=(int(cell.level)+1)*1.7
	var parts:Array=[];var join:=Plan.seams(city,h,cell,Plan.front(city,h))
	var back:float=-.9 if join[0] else -1.08;var front:float=.9 if join[1] else 1.08
	match kind:
		0:
			var gain:=slope*.83/.57;var peak:=y+.03+.70*gain;_gable(parts,-1.06,1.06,.23,back,front,y+.03,peak,"Cedar",y+.03+.13*gain,y)
			_box_part(parts,"CedarRidge",Vector3(.095,.075,front-back),Vector3(.23,peak+.015,(back+front)*.5),"wood")
		1:
			var high:=y+.07+2.14*slope
			_prism(parts,"MonoPitch",[Vector3(-1.07,y+.07,-1.02),Vector3(-1.07,high,1.12),Vector3(1.07,high,1.12),Vector3(1.07,y+.07,-1.02)],"slate")
			for x:float in [-.9,.9]:
				var a:=Vector3(x,y,-.9);var b:=Vector3(x,y,.9);var c:=Vector3(x,y+.03+1.92*slope,.9);var d:=Vector3(x,y+.03+.12*slope,-.9);var side:Array=[a,b,c,a,c,d]
				if x>0.:side.reverse()
				_skin(parts,"MonoGlassSide",side,"glass")
				_box_part(parts,"MonoRafter",Vector3(.065,.065,sqrt(2.14*2.14+pow(2.14*slope,2.))),Vector3(x,(y+.07+high)*.5,.05),"wood",Vector3(-atan(slope),0,0))
			_box_part(parts,"MonoFrontBeam",Vector3(2.14,.07,.10),Vector3(0,high-.015,1.08),"wood")
			var back_height:=maxf(.015,.03+.12*slope);_box_part(parts,"MonoBackGlass",Vector3(1.74,back_height,.035),Vector3(0,y+back_height*.5,-.9),"glass")
			var height:=maxf(.015,.07+1.92*slope-.04);_box_part(parts,"MonoFrontGlass",Vector3(1.74,height,.035),Vector3(0,y+.02+height*.5,.9),"glass")
		2,5:
			# Planted ribbons retain the terraced identity at every authored angle.
			for index in range(2):
				var low:float=-1.02+index*1.02;var high:float=low+1.02;var base:float=y+.10+(1-index)*.30 if kind==2 else y+.10+index*.12
				_prism(parts,"PlantedRibbon",[Vector3(-1.02,base,low),Vector3(-1.02,base+slope*1.02,high),Vector3(1.02,base+slope*1.02,high),Vector3(1.02,base,low)],"green")
				for side:float in [-.9,.9]:
					var vertices:Array=[Vector3(side,y,low),Vector3(side,y,high),Vector3(side,base+slope*1.02-.04,high),Vector3(side,y,low),Vector3(side,base+slope*1.02-.04,high),Vector3(side,base-.04,low)]
					if side>0.:vertices.reverse()
					_skin(parts,"PlantedRoofGlass",vertices,"glass")
				for z:float in [low,high]:
					var cap:float=base+slope*(z-low)-.04
					var vertices:Array=[Vector3(-.9,y,z),Vector3(.9,y,z),Vector3(.9,cap,z),Vector3(-.9,y,z),Vector3(.9,cap,z),Vector3(-.9,cap,z)]
					if z==low:vertices.reverse()
					_skin(parts,"PlantedRoofEnd",vertices,"glass")
				if kind==2 and index==0 and angle<=15.:
					var deck:float=base+slope*1.02+.02
					_box_part(parts,"RoofGardenPlinth",Vector3(1.12,maxf(.04,deck-base+.04),.90),Vector3(0,(deck+base-.04)*.5,-.46),"stone")
					var garden_kind:int=preload("res://scripts/visual/city_creation_modern_archetypes.gd").roof_kind(h,cell);var footing:float=(.15 if garden_kind==2 else .16)*.62
					parts.append({"type":"garden","name":"EcoRoofGarden","at":Vector3(0,deck-footing,-.35),"size":Vector3(1.24,.744,.93),"rotation":Vector3.ZERO,"material":"garden"});continue
				for x:float in [-.66,0.,.66]:
					var z:float=(low+high)*.5;var size:=Vector3(.20,.10,.20);var normal:=Vector3(0,1,-slope).normalized()
					parts.append({"type":"crown","name":"SedumPlant","size":size,"at":Vector3(x,base+slope*(z-low),z)+normal*size.y,"rotation":Vector3(-atan(slope),0,0),"material":"leaf"})
		3:_gable(parts,-1.05,1.05,0.,-1.04,1.04,y+.05,y+.05+slope*1.05,"Panorama",-INF,y)
		4:
			for x:float in [-.60,.60]:_gable(parts,x-.405,x+.405,x,-1.04,1.04,y+.05,y+.05+slope*.405,"Twin",-INF,y)
			_box_part(parts,"TwinLinkDeck",Vector3(.45,.07,.65),Vector3(0,y+.07,0),"wood")
			var high:float=minf(.55,.05+slope*.405);_box_part(parts,"TwinLinkCap",Vector3(.49,.06,.71),Vector3(0,y+high,0),"wood")
			if high>.15:
				for z:float in [-.32,.32]:_box_part(parts,"TwinLinkGlass",Vector3(.45,high-.10,.025),Vector3(0,y+.10+(high-.10)*.5,z),"glass")
	if h.get("role","")=="bakery" and not preload("res://scripts/world/city_creation_architecture_variants.gd").chimney_active(city,h):
		var at:=Vector2(.56,-.48);var top:=surface(parts,at)+.24
		_box_part(parts,"ModernChimney",Vector3(.20,.54,.20),Vector3(at.x,top,at.y),"stone");_box_part(parts,"ModernChimneyCap",Vector3(.27,.07,.27),Vector3(at.x,top+.28,at.y),"stone")
	return {"parts":parts,"front":Plan.front(city,h),"kind":kind,"cell":cell,"joined_ends":join,"angle":angle,"roof_y":y+float(h.get("base_y",0.))}
static func _gable(parts:Array,left:float,right:float,ridge:float,back:float,front:float,eave:float,peak:float,label:String,right_eave:float=-INF,floor_y:float=0.)->void:
	if right_eave==-INF:right_eave=eave
	_prism(parts,label+"Left",[Vector3(left,eave,back),Vector3(left,eave,front),Vector3(ridge,peak,front),Vector3(ridge,peak,back)],"slate")
	_prism(parts,label+"Right",[Vector3(ridge,peak,back),Vector3(ridge,peak,front),Vector3(right,right_eave,front),Vector3(right,right_eave,back)],"slate")
	for z:float in [back,front]:
		var outline:Array=[Vector3(left,floor_y,z),Vector3(right,floor_y,z),Vector3(right,right_eave-.035,z),Vector3(ridge,peak-.035,z),Vector3(left,eave-.035,z)];var faces:Array=[]
		for i in range(1,outline.size()-1):faces.append_array([outline[0],outline[i],outline[i+1]])
		if z==back:faces.reverse()
		_skin(parts,label+"Gable",faces,"wood")
	for x:float in [left,right]:
		var top:float=(eave if x==left else right_eave)-.08
		if top<=floor_y+.00001:continue
		var faces:Array=[Vector3(x,floor_y,back),Vector3(x,floor_y,front),Vector3(x,top,front),Vector3(x,floor_y,back),Vector3(x,top,front),Vector3(x,top,back)]
		if x==right:faces.reverse()
		_skin(parts,label+"Clerestory",faces,"glass")
static func _skin(parts:Array,label:String,vertices:Array,material:String)->void:
	var clean:Array=[]
	for i in range(0,vertices.size(),3):
		if (vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).length_squared()>.0000000001:clean.append_array(vertices.slice(i,i+3))
	if not clean.is_empty():parts.append({"type":"skin","name":label,"vertices":clean,"material":material})
static func _prism(parts:Array,label:String,top:Array,material:String)->void:
	if (top[1]-top[0]).cross(top[2]-top[0]).y<0.:top.reverse()
	var low:Array=top.map(func(p):return p-Vector3.UP*.08);var faces:Array=[top[0],top[1],top[2],top[0],top[2],top[3],low[0],low[2],low[1],low[0],low[3],low[2]]
	for i in range(4):var j:=(i+1)%4;faces.append_array([low[i],top[j],top[i],low[i],low[j],top[j]])
	_skin(parts,label,faces,material)
static func _box_part(parts:Array,label:String,size:Vector3,at:Vector3,material:String,rotation:Vector3=Vector3.ZERO)->void:parts.append({"type":"box","name":label,"size":size,"at":at,"material":material,"rotation":rotation})
static func vertices(part:Dictionary)->Array:
	if part.type=="skin":return part.vertices
	# Decorative crowns use their actual ellipsoid bounds for CPU clearance;
	# structural boxes use exact faces, without render resources in workers.
	var size:Vector3=part.size if part.type in ["box","garden"] else part.size*2.;var corners:Array=[]
	for z:float in [-.5,.5]:
		for y:float in [-.5,.5]:
			for x:float in [-.5,.5]:corners.append(Vector3(x,y,z)*size)
	var faces:Array=[]
	for indices:Array in [[0,2,3,0,3,1],[4,5,7,4,7,6],[0,1,5,0,5,4],[2,6,7,2,7,3],[0,4,6,0,6,2],[1,3,7,1,7,5]]:
		for i:int in indices:faces.append(corners[i])
	var center:Vector3=part.at+Vector3.UP*part.size.y*.5 if part.type=="garden" else part.at
	var transform:=Transform3D(Basis.from_euler(part.rotation),center);var result:Array=[]
	for point:Vector3 in faces:result.append(transform*point)
	return result
static func surface(parts:Array,at:Vector2)->float:
	var result:=-INF
	for part:Dictionary in parts:
		if part.type!="skin" or part.material not in ["slate","green"]:continue
		for i in range(0,part.vertices.size(),3):
			var a:Vector3=part.vertices[i];var b:Vector3=part.vertices[i+1];var c:Vector3=part.vertices[i+2];var n:Vector3=(b-a).cross(c-a)
			if absf(n.y)<.000001 or not Geometry2D.is_point_in_polygon(at,PackedVector2Array([Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z)])):continue
			result=maxf(result,a.y-(n.x*(at.x-a.x)+n.z*(at.y-a.z))/n.y)
	return result
static func patches(city,h:Dictionary)->Array:
	var result:Array=[]
	for cell:Dictionary in h.cells:
		if cell.kind!="room" or not top(h,cell):continue
		var plan:=cell_plan(city,h,cell);var frame:=Transform3D(Basis(Vector3.UP,atan2(float(plan.front.x),float(plan.front.y))),Vector3(h.origin[0]+cell.x*1.8,float(h.get("base_y",0.)),h.origin[1]+cell.z*1.8))
		for part:Dictionary in plan.parts:
			var points:Array=[];var low:=INF
			for p:Vector3 in vertices(part):var at:Vector3=frame*p;points.append(at);low=minf(low,at.y)
			result.append({"surface":"roof","base_y":low,"vertices":points,"cell_id":str(cell.id),"part":str(part.name),"roof_skin":part.type=="skin" and part.material in ["slate","green"]})
	return result
