extends RefCounted
const Bough=preload("res://scripts/visual/city_creation_bough_curve.gd")
const Spray=preload("res://scripts/visual/city_creation_leaf_spray.gd")
## Leaves grow from short curved shoots, rather than floating in a volume.
static func append(f,leaves:Dictionary,wood:Dictionary,stem:Vector3,center:Vector3,radius:Vector3,rng:RandomNumberGenerator,kind:String,height:float,count:int)->void:
	var local:=RandomNumberGenerator.new();local.state=rng.state
	var shoots:int=6 if kind=="golden" else 5
	var size:=Vector2(.19,.064) if kind=="golden" else Vector2(.17,.046)
	var phase:float=local.randf()*TAU
	for shoot:int in range(shoots):
		var angle:float=phase+shoot*2.39996+local.randf_range(-.22,.22)
		var radial:=Vector3(cos(angle),0,sin(angle))
		var elevation:float=lerpf(-.8,.95,float(shoot)/float(shoots-1))+local.randf_range(-.10,.10)
		var reach:float=sqrt(maxf(.12,1.-elevation*elevation))*local.randf_range(.82,1.)
		var end:Vector3=center+radial*Vector3(radius.x,0,radius.z)*reach+Vector3(0,radius.y*elevation,0)
		var first:int=wood.vertices.size();f._branch(wood,stem,end,.005 if kind=="olive" else .006,.001, "olive" if kind=="olive" else "golden_tree")
		var line:Array[Vector3]=[]
		for ring:int in range(Bough.RINGS):
			var point:=Vector3.ZERO
			for side:int in range(Bough.SIDES):point+=wood.vertices[first+ring*Bough.SIDES+side]/float(Bough.SIDES)
			line.append(point)
		var on_shoot:int=count/shoots+(1 if shoot<count%shoots else 0)
		for node:int in range(on_shoot):
			var t:float=pow((node+.3+local.randf()*.4)/float(on_shoot),.65)
			var along:float=t*(line.size()-1);var index:int=mini(int(along),line.size()-2)
			var at:Vector3=line[index].lerp(line[index+1],along-index);var tangent:Vector3=(line[index+1]-line[index]).normalized()
			var across:Vector3=Vector3.UP.cross(tangent).normalized();var around:Vector3=tangent.cross(across).normalized()
			var turn:float=node*2.39996+phase+local.randf_range(-.4,.4)
			var side:Vector3=across*cos(turn)+around*sin(turn)
			var axis:Vector3=(tangent*local.randf_range(.15,.55)+side*local.randf_range(.75,1.)).normalized()
			var normal:Vector3=((at-center)/radius+Vector3.UP*1.15).normalized();var length:float=size.x*local.randf_range(.76,1.24)
			Spray.leaf(f,leaves,at+axis*length*.5,axis,normal,length,size.y*local.randf_range(.85,1.15),local,kind,height)
	# Preserve the shared stream used by all later main branches and species.
	for draw:int in range(count*8):rng.randf()
