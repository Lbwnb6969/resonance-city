extends RefCounted
## The real eight arch/window openings and fixed bands surround an authored cap.
const Parts=preload("res://scripts/world/city_creation_renaissance_roof_parts.gd")
const P=Parts.P
const Shell=preload("res://scripts/visual/city_creation_recessed_facade.gd")
const Arch=preload("res://scripts/visual/city_creation_architecture.gd")
static func build(slope:float)->Array:
	var parts:Array=[]
	for index in range(4):
		var angle:=index*PI*.5;var wall:Array=[];var holes:Array=[]
		if index<2:
			for x:float in [-.47,0.,.47]:holes.append({"x":x,"radius":.205,"bottom":.26,"spring":1.18,"arched":true})
		else:holes=[{"x":0.,"radius":.17,"bottom":.60,"spring":1.04,"arched":true}]
		P.face(wall,"LoggiaPierAndArch",Shell.faces({"width":1.60,"height":1.52,"holes":holes}),"plaster")
		var trim:Array=[]
		for hole:Dictionary in holes:
			for side:float in [-1.,1.]:P.box(wall,"LoggiaStoneJamb",Vector3(.055,hole.spring-hole.bottom,.17),Vector3(hole.x+side*(hole.radius+.0275),(hole.spring+hole.bottom)*.5,.015),"stone")
			for i in range(12):
				var a:=PI*i/12.;var b:=PI*(i+1)/12.;var radius:float=hole.radius;var x:float=hole.x;var y:float=hole.spring
				for point:Vector3 in Arch._extrude(PackedVector2Array([Vector2(x+cos(a)*radius,y+sin(a)*radius),Vector2(x+cos(b)*radius,y+sin(b)*radius),Vector2(x+cos(b)*(radius+.05),y+sin(b)*(radius+.05)),Vector2(x+cos(a)*(radius+.05),y+sin(a)*(radius+.05))]),.17):trim.append(point+Vector3(0,0,.015))
		P.face(wall,"LoggiaArchStoneBand",trim,"stone");P.box(wall,"LoggiaGalleryPlinth",Vector3(1.67,.09,.20),Vector3(0,.17,.015),"stone");P.box(wall,"LoggiaGalleryCornice",Vector3(1.67,.09,.20),Vector3(0,1.48,.015),"stone")
		if index<2:Parts.rail(wall,1.47,.015,true)
		else:
			var points:Array=[]
			for point:Vector3 in Arch._extrude(Shell.outline(holes[0]),.012):points.append(point+Vector3(0,0,-.035))
			P.face(wall,"LoggiaRearGlass",points,"glass")
		parts.append_array(Parts.transform(wall,Transform3D(Basis(Vector3.UP,angle),Vector3(sin(angle)*.735,0,cos(angle)*.735))))
	P.box(parts,"LoggiaCrownSoffit",Vector3(1.70,.09,1.70),Vector3(0,1.56,0),"stone");Parts.hip(parts,1.74,1.74,1.61,.87*slope)
	return parts
