extends RefCounted
## Existing authored dimensions, now readable by rendering and CPU clearance.
const Architecture=preload("res://scripts/visual/city_creation_architecture.gd")
const Chimney=preload("res://scripts/visual/city_creation_chimney_details.gd")
static func box(parts:Array,name:String,size:Vector3,at:Vector3,material:String,basis:Basis=Basis.IDENTITY)->void:parts.append({"type":"box","name":name,"size":size,"at":at,"basis":basis,"rotation":Vector3.ZERO,"material":material})
static func skin(parts:Array,name:String,points:Array,material:String,at:Vector3=Vector3.ZERO,basis:Basis=Basis.IDENTITY)->void:parts.append({"type":"skin","name":name,"vertices":points,"at":at,"basis":basis,"material":material})
static func vertices(part:Dictionary)->Array[Vector3]:
	var points:Array=[]
	if part.type=="skin":points=part.vertices
	else:
		var corners:Array[Vector3]=[]
		for z:float in [-.5,.5]:
			for y:float in [-.5,.5]:
				for x:float in [-.5,.5]:corners.append(Vector3(x,y,z)*Vector3(part.size))
		# BoxMesh face diagonals, without allocating render resources on workers.
		for i:int in [6,7,4,7,5,4,3,2,1,2,0,1,7,3,5,3,1,5,2,6,0,6,4,0,7,6,3,6,2,3,4,5,0,5,1,0]:points.append(corners[i])
	var frame:=Transform3D(part.get("basis",Basis.IDENTITY),part.get("at",Vector3.ZERO))
	var result:Array[Vector3]=[]
	for p:Vector3 in points:
		result.append(frame*p)
	return result
static func dormer(site:Dictionary,key:String)->Array:
	var parts:Array=[];var base:float=site.high-site.low+.015;var eave:float=base+(.34 if key=="gable_light" else .16);var back:float=eave if key=="gable_light" else base+.40
	for x:float in [-.275,.275]:skin(parts,"DormerCheek",Architecture._extrude(PackedVector2Array([Vector2(-.31,0),Vector2(.31,0),Vector2(.31,eave),Vector2(-.31,back)]),.05),"cream",Vector3(x,0,0),Basis(Vector3.UP,-PI*.5))
	box(parts,"DormerBack",Vector3(.55,back,.045),Vector3(0,back*.5,-.29),"cream")
	if key=="gable_light":
		box(parts,"DormerSill",Vector3(.50,base+.045,.05),Vector3(0,(base+.045)*.5,.29),"cream")
		for x:float in [-.25,.25]:box(parts,"DormerFrame",Vector3(.045,.295,.055),Vector3(x,base+.19,.29),"wood")
		box(parts,"DormerLintel",Vector3(.50,.035,.065),Vector3(0,base+.325,.29),"wood");box(parts,"DormerGlass",Vector3(.45,.23,.025),Vector3(0,base+.1775,.295),"glass");box(parts,"DormerMullion",Vector3(.022,.23,.045),Vector3(0,base+.1775,.315),"wood")
		box(parts, "DormerStoneLedge", Vector3(.62, .045, .10), Vector3(0, base+.04, .31), "cream")
		var ridge:=eave+.22
		var verge_length := Vector2(.35, .22).length()
		for side: float in [-1.0, 1.0]:
			var rake := Basis(Vector3.BACK, -side * atan2(.22, .35))
			box(parts, "DormerBargeboard", Vector3(verge_length, .044, .052), Vector3(side*.175, eave+.095, .338), "wood", rake)
			box(parts, "DormerEave", Vector3(.042, .046, .70), Vector3(side*.333, eave-.012, 0), "wood")
		for z:float in [-.29,.29]:skin(parts,"DormerGableInfill",Architecture._extrude(PackedVector2Array([Vector2(-.30,eave),Vector2(.30,eave),Vector2(0,ridge)]),.035),"cream",Vector3(0,0,z))
		skin(parts,"DormerTilePitch",[Vector3(-.35,eave,-.36),Vector3(-.35,eave,.36),Vector3(0,ridge,.36),Vector3(-.35,eave,-.36),Vector3(0,ridge,.36),Vector3(0,ridge,-.36),Vector3(0,ridge,-.36),Vector3(0,ridge,.36),Vector3(.35,eave,.36),Vector3(0,ridge,-.36),Vector3(.35,eave,.36),Vector3(.35,eave,-.36)],"tile")
	else:
		box(parts,"DormerFront",Vector3(.55,eave,.045),Vector3(0,eave*.5,.29),"cream")
		var angle:=atan2(back-eave,.62);var length:=Vector2(.62,back-eave).length();var origin:=Vector3(0,(back+eave)*.5,0);var basis:=Basis(Vector3.RIGHT,angle)
		box(parts,"DormerGlass",Vector3(.49,.025,length-.04),origin,"glass",basis)
		for x:float in [-.265,0.,.265]:box(parts,"DormerSlopeFrame",Vector3(.027,.045,length+.04),origin+basis*Vector3(x,0,0),"wood",basis)
		for z:float in [-length*.5,length*.5]:box(parts,"DormerSlopeCap",Vector3(.56,.045,.028),origin+basis*Vector3(0,0,z),"wood",basis)
	return parts
static func chimney(site:Dictionary,key:String)->Dictionary:
	var parts:Array=[];var top:float=site.high-site.low+.025+.50;var outlets:Array[Vector3]=[]
	for x:float in [-.135,.135]:box(parts,"ChimneyBrick",Vector3(.04,top,.27),Vector3(x,top*.5,0),"brick")
	for z:float in [-.115,.115]:box(parts,"ChimneyBrick",Vector3(.23,top,.04),Vector3(0,top*.5,z),"brick")
	if key=="brick_twin_pots":
		for side:float in [-1.,1.]:
			var center:=Vector2(side*.075,0);var half:=Rect2(-.18 if side<0 else 0.,-.17,.18,.34)
			skin(parts,"TwinPotStoneCap",Chimney.ring(center,.034,half,top,top+.055),"stone");skin(parts,"HollowTerracottaPot",Chimney.ring(center,.034,Rect2(),top+.04,top+.25,.052),"clay");outlets.append(Vector3(center.x,top+.26,0))
	else:
		skin(parts,"CopperCollar",Chimney.ring(Vector2.ZERO,.085,Rect2(-.17,-.16,.34,.32),top,top+.035),"stone")
		for x:float in [-.13,.13]:
			for z:float in [-.12,.12]:box(parts,"CopperHoodPost",Vector3(.025,.22,.025),Vector3(x,top+.145,z),"copper")
		skin(parts,"CopperVentHood",Chimney.hood(top+.25,top+.40),"copper");outlets.append(Vector3(.24,top+.13,0))
	return {"parts":parts,"outlets":outlets,"top":top}
