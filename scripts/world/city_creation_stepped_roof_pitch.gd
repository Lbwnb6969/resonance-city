extends RefCounted
## Stepped parapets follow the roof; coping, badges and vanes keep their size.
const P=preload("res://scripts/world/city_creation_roof_primitives.gd")
const Arch=preload("res://scripts/visual/city_creation_architecture.gd")
static func build(row:Dictionary,slope:float,bakery:bool)->Dictionary:
	var parts:Array=[];var outlets:Array[Vector3]=[];var half:float=row.depth*.5;var end:=half-.145;var rise:=.9*slope;var gain:=rise/.78
	P.box(parts,"GuildRoofSoffit",Vector3(1.8,.10,row.depth),Vector3(0,.025,0),"stone")
	P.prism(parts,"GuildTilePitch",[Vector3(-.9,.10,-end),Vector3(-.9,.10,end),Vector3(0,.10+rise,end),Vector3(0,.10+rise,-end)],"tile")
	P.prism(parts,"GuildTilePitch",[Vector3(0,.10+rise,-end),Vector3(0,.10+rise,end),Vector3(.9,.10,end),Vector3(.9,.10,-end)],"tile")
	var crown:=.38+3.*.22*gain;var lift:=crown-1.04
	for side:float in [-1.,1.]:
		var z:=side*(half-.085)
		for i in range(8):
			var height:=.38+mini(i,7-i)*.22*gain;var x:float=-.9+(i+.5)*.225
			P.box(parts,"GuildStepBody",Vector3(.225,height,.12),Vector3(x,height*.5,z),"plaster");P.box(parts,"GuildStepCap",Vector3(.225,.07,.17),Vector3(x,height-.035,z),"stone")
		P.cylinder(parts,"CarvedGuildRoundel",.105,.105,.026,Vector3(0,minf(.29,crown-.145),z+side*.073),"wood",12,Basis(Vector3.RIGHT,PI*.5))
		P.box(parts,"GuildWeatherStem",Vector3(.025,.23,.025),Vector3(0,1.15+lift,z),"iron");P.box(parts,"GuildWeatherArrow",Vector3(.30,.025,.025),Vector3(0,1.20+lift,z),"iron");P.box(parts,"GuildWeatherTail",Vector3(.055,.10,.025),Vector3(-.125,1.20+lift,z),"iron")
		var points:Array=[]
		for point:Vector3 in Arch._extrude(PackedVector2Array([Vector2(.18,1.20),Vector2(.10,1.25),Vector2(.10,1.15)]),.025):points.append(point+Vector3(0,lift,z))
		P.face(parts,"GuildWeatherHead",points,"iron")
	if bakery:
		var at:=Vector3(.43,.10+rise*(1.-.43/.9)+.22,0);P.box(parts,"GuildChimney",Vector3(.23,.48,.26),at,"stone");P.box(parts,"GuildChimneyCap",Vector3(.29,.07,.32),at+Vector3(0,.275,0),"plaster");outlets.append(at+Vector3(0,.32,0))
	return {"parts":parts,"outlets":outlets,"height":crown}
