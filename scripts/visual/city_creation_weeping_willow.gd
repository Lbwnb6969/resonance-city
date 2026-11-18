extends RefCounted
const Bough=preload("res://scripts/visual/city_creation_bough_curve.gd")
const Spray=preload("res://scripts/visual/city_creation_leaf_spray.gd")
## Arching boughs carry fine hanging stems with alternating lance-shaped leaves.
static func append(f,leaves:Dictionary,wood:Dictionary,rng:RandomNumberGenerator,variant:int)->void:
	var fork:=Vector3(.09*(variant-1),1.30,.04);f._branch(wood,Vector3.ZERO,fork,.15,.075,"weeping_willow")
	for arm in range(7):
		var angle:=arm*2.39996+variant*.47;var radial:=Vector3(cos(angle),0,sin(angle))
		var crown:=fork+radial*(.78+rng.randf()*.15)+Vector3(0,.90+rng.randf()*.24,0)
		f._branch(wood,fork,crown,.055,.018,"weeping_willow");Spray.append(f,leaves,crown,Vector3(.41,.25,.37),rng,"willow",3.05,55)
		for strand in range(5):
			var phase:=angle+(strand-2)*.22;var outward:=Vector3(cos(phase),0,sin(phase))
			var top:=crown+outward*.18;var end:=top+outward*(.32+rng.randf()*.18)-Vector3(0,1.30+rng.randf()*.40,0)
			var middle:=top.lerp(end,.42)+outward*.12+Vector3(0,.10,0)
			var first:int=wood.vertices.size();f._branch(wood,crown,middle,.014,.007,"weeping_willow")
			var second:int=wood.vertices.size();f._branch(wood,middle,end,.007,.0015,"weeping_willow")
			var line:Array[Vector3]=[]
			# Sample the rings already emitted by the bent stem mesh. Every leaf
			# begins on that same piecewise centre line, including the bend join.
			for origin:int in [first,second]:
				for ring:int in range(Bough.RINGS):
					if origin==second and ring==0:continue
					var point:=Vector3.ZERO
					for sector:int in range(Bough.SIDES):point+=wood.vertices[origin+ring*Bough.SIDES+sector]/float(Bough.SIDES)
					line.append(point)
			var leaves_rng:=RandomNumberGenerator.new();leaves_rng.seed=7391+variant*223+arm*101+strand*997
			for step:int in range(32):
				var t:float=(step+.25+leaves_rng.randf()*.5)/32.
				var along:float=t*(line.size()-1);var index:int=mini(int(along),line.size()-2)
				var at:Vector3=line[index].lerp(line[index+1],along-index)
				var sign_value:float=-1. if step%2==0 else 1.
				var side:=Vector3(-outward.z,0,outward.x)*sign_value
				var axis:Vector3=(side*leaves_rng.randf_range(.25,.5)-Vector3.UP*.85+outward*leaves_rng.randf_range(-.15,.25)).normalized()
				var length:float=.20+leaves_rng.randf()*.07;var normal:=Vector3(outward.x,.45,outward.z).normalized()
				Spray.leaf(f,leaves,at+axis*length*.5,axis,normal,length,.035,leaves_rng,"willow",3.05)
			# Keep the shared RNG at its former position so every later branch,
			# crown cluster and authored-scale top remains identical.
			for draw:int in range(96):rng.randf()
