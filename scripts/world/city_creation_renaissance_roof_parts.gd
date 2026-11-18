extends RefCounted
const P=preload("res://scripts/world/city_creation_roof_primitives.gd")
static func hip(parts:Array,width:float,depth:float,eave:float,rise:float)->void:
	var x:=width*.5;var z:=depth*.5;var peak:=Vector3(0,eave+rise,0)
	for edge:Array in [[Vector3(-x,eave,-z),Vector3(x,eave,-z)],[Vector3(x,eave,-z),Vector3(x,eave,z)],[Vector3(x,eave,z),Vector3(-x,eave,z)],[Vector3(-x,eave,z),Vector3(-x,eave,-z)]]:
		P.face(parts,"RenaissanceHippedRoof",[edge[0],peak,edge[1]],"tile",true);P.quad(parts,"HipClosedEdge",edge[1],edge[1]+Vector3.DOWN*.045,edge[0]+Vector3.DOWN*.045,edge[0],"tile")
	P.quad(parts,"HipUnderside",Vector3(-x,eave-.045,-z),Vector3(x,eave-.045,-z),Vector3(x,eave-.045,z),Vector3(-x,eave-.045,z),"tile")
static func rail(parts:Array,width:float=1.65,z:float=.80,corner:bool=false)->void:
	if corner:
		for i in range(7):P.box(parts,"LoggiaBaluster",Vector3(.035,.25,.055),Vector3((i-3)*width/7.,.325,z),"stone")
	else:
		for x:float in [-.80,-.55,-.28,0.,.28,.55,.80]:P.cylinder(parts,"VillaBaluster",.025,.03,.32,Vector3(x,.27,z),"stone")
	P.box(parts,"LoggiaBalustradeCap",Vector3(width,.065 if corner else .075,.09),Vector3(0,.475 if corner else .47,z),"stone")
static func transform(parts:Array,pose:Transform3D)->Array:
	for part:Dictionary in parts:
		for i in range(part.vertices.size()):part.vertices[i]=pose*part.vertices[i]
	return parts
static func lookout(parts:Array,slope:float)->void:
	P.box(parts,"RetreatedLookoutFloor",Vector3(1.27,.10,1.27),Vector3(0,.12,0),"stone")
	for x:float in [-.52,.52]:
		for z:float in [-.52,.52]:P.cylinder(parts,"OpenLoggiaColumn",.065,.048,.96,Vector3(x,.65,z),"stone",10);P.box(parts,"LookoutCapital",Vector3(.18,.07,.18),Vector3(x,1.14,z),"stone")
	for at:Vector3 in [Vector3(0,1.19,-.55),Vector3(0,1.19,.55)]:P.box(parts,"LookoutCornice",Vector3(1.3,.13,.17),at,"stone")
	for at:Vector3 in [Vector3(-.55,1.19,0),Vector3(.55,1.19,0)]:P.box(parts,"LookoutCornice",Vector3(.17,.13,1.3),at,"stone")
	hip(parts,1.48,1.48,1.27,.74*slope)
