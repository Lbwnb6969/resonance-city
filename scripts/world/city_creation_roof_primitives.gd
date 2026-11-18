extends RefCounted
## CPU triangle primitives; published meshes consume these exact vertices.
const Boxes=preload("res://scripts/world/city_creation_roof_detail_shapes.gd")
static func face(parts:Array,name:String,points:Array,material:String,roof:bool=false)->void:
	var clean:Array[Vector3]=[]
	for i in range(0,points.size(),3):
		var a:=Vector3(points[i]);var b:=Vector3(points[i+1]);var c:=Vector3(points[i+2])
		if (b-a).cross(c-a).length_squared()>.0000000001:clean.append_array([a,b,c])
	if not clean.is_empty():parts.append({"name":name,"vertices":clean,"material":material,"roof_skin":roof})
static func quad(parts:Array,name:String,a:Vector3,b:Vector3,c:Vector3,d:Vector3,material:String,roof:bool=false)->void:face(parts,name,[a,b,c,a,c,d],material,roof)
static func end_face(parts:Array,name:String,points:Array,material:String)->void:
	var out:Array=[]
	for i in range(0,points.size(),3):
		var a:=Vector3(points[i]);var b:=Vector3(points[i+1]);var c:=Vector3(points[i+2]);var normal:Vector3=(b-a).cross(c-a);var center:Vector3=(a+b+c)/3.
		out.append_array([a,c,b] if normal.dot(Vector3(center.x,0,center.z))<0. else [a,b,c])
	face(parts,name,out,material)
static func box(parts:Array,name:String,size:Vector3,at:Vector3,material:String,basis:Basis=Basis.IDENTITY)->void:
	var points:=Boxes.vertices({"type":"box","size":size,"at":at,"basis":basis});var out:Array=[]
	for i in range(0,points.size(),3):out.append_array([points[i],points[i+2],points[i+1]])
	face(parts,name,out,material)
static func beam(parts:Array,name:String,a:Vector3,b:Vector3,width:float,material:String)->void:
	var delta:=b-a
	if delta.length_squared()<.00000001:return
	var up:=delta.normalized();var right:=Vector3.FORWARD.cross(up)
	if right.length_squared()<.00001:right=Vector3.RIGHT.cross(up)
	right=right.normalized();box(parts,name,Vector3(width,delta.length(),width),(a+b)*.5,material,Basis(right,up,right.cross(up)))
static func cylinder(parts:Array,name:String,bottom:float,top:float,height:float,at:Vector3,material:String,sides:int=8,basis:Basis=Basis.IDENTITY)->void:
	var points:Array=[];var low:=Vector3.DOWN*height*.5;var high:=-low
	for i in range(sides):
		var a:=Vector3(sin(i*TAU/sides),0,cos(i*TAU/sides));var b:=Vector3(sin((i+1)*TAU/sides),0,cos((i+1)*TAU/sides));var p:=a*bottom+low;var q:=b*bottom+low;var r:=b*top+high;var s:=a*top+high
		points.append_array([p,q,r,p,r,s,high,s,r,low,q,p])
	face(parts,name,points.map(func(p):return at+basis*p),material)
static func crown(parts:Array,name:String,at:Vector3,size:Vector3,material:String)->void:
	var points:Array=[]
	for ring in range(6):
		for side in range(10):
			var corners:Array=[]
			for uv:Vector2i in [Vector2i(side,ring),Vector2i(side+1,ring),Vector2i(side+1,ring+1),Vector2i(side,ring+1)]:
				var latitude:float=-PI*.5+PI*uv.y/6.;var longitude:float=TAU*uv.x/10.;corners.append(at+Vector3(sin(longitude)*cos(latitude),sin(latitude),cos(longitude)*cos(latitude))*size)
			points.append_array([corners[0],corners[1],corners[2],corners[0],corners[2],corners[3]])
	face(parts,name,points,material)
static func prism(parts:Array,name:String,corners:Array,material:String)->void:
	# Sky-facing sheet, a real underside, and the four narrow closed edges.
	var top:Array=corners.duplicate()
	if (Vector3(top[1])-Vector3(top[0])).cross(Vector3(top[2])-Vector3(top[0])).y<0.:top.reverse()
	quad(parts,name,top[0],top[1],top[2],top[3],material,true)
	var down:=Vector3.DOWN*.045;quad(parts,name+"Under",top[3]+down,top[2]+down,top[1]+down,top[0]+down,material)
	for i in range(4):quad(parts,name+"Edge",top[i],top[i]+down,top[(i+1)%4]+down,top[(i+1)%4],material)
