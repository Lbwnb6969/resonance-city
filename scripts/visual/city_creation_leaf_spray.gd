extends RefCounted
## Folded opaque leaves. Crown normals soften individual leaf planes.
static func leaf(f,data:Dictionary,at:Vector3,axis:Vector3,normal:Vector3,length:float,width:float,rng:RandomNumberGenerator,kind:String,height:float)->void:
	var across:=Vector3.UP.cross(axis).normalized();var up:=axis.cross(across).normalized()
	var roll:=rng.randf_range(-.85,.85);var side:=across*cos(roll)+up*sin(roll)
	var leaf_up:=axis.cross(side).normalized();var shading:=normal.lerp(leaf_up,.32).normalized()
	var base:=at-axis*length*.5;var first:int=data.vertices.size();var hue:=rng.randf_range(-.022,.022)
	var outline:Array=[base,base+axis*length*.20-side*width*.55,base+axis*length*.45-side*width,base+axis*length*.73-side*width*.70,base+axis*length,base+axis*length*.73+side*width*.70,base+axis*length*.45+side*width,base+axis*length*.20+side*width*.55]
	for point:Vector3 in outline:f._leaf_vertex(data,point,shading,kind,height,hue)
	f._leaf_vertex(data,base+axis*length*.48+leaf_up*width*.32,shading,kind,height,hue)
	for i in range(8):f._triangle(data,first+i,first+8,first+(i+1)%8)
static func append(f,data:Dictionary,center:Vector3,radius:Vector3,rng:RandomNumberGenerator,kind:String,height:float,count:int)->void:
	var size:Vector2={"olive":Vector2(.17,.046),"golden":Vector2(.19,.064),"cypress":Vector2(.13,.028),"willow":Vector2(.20,.034),"shrub":Vector2(.13,.043)}[kind]
	for i in range(count):
		var y:=rng.randf_range(-1.,1.);var phase:=rng.randf()*TAU;var ring:=sqrt(1.-y*y)
		var unit:=Vector3(cos(phase)*ring,y,sin(phase)*ring)*pow(rng.randf(),.3333333)
		var at:=center+unit*radius;var normal:Vector3=(unit/radius+Vector3(0,1.15,0)).normalized()
		var direction:=phase+rng.randf_range(-1.4,1.4);var rise:=rng.randf_range(-.25,.65) if kind!="cypress" else rng.randf_range(.6,1.6)
		var axis:=Vector3(cos(direction),rise,sin(direction)).normalized();var scale_value:=rng.randf_range(.76,1.24)
		leaf(f,data,at,axis,normal,size.x*scale_value,size.y*scale_value,rng,kind,height)
