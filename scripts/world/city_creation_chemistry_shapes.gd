extends RefCounted
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
## Thin semantic outlines derived from the production plans, in world metres.
const Bridge = preload("res://scripts/world/city_creation_bridge_plan.gd")
static func row(kind: String, label: String, lines: Array, at: Vector3) -> Dictionary:
	return {"kind":kind,"label":label,"lines":lines,"at":at}
static func circle(at: Vector3, radius: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for i in range(33): points.append(at+Vector3(cos(i*TAU/32.),0,sin(i*TAU/32.))*radius)
	return points
static func court(plan: Dictionary) -> Dictionary:
	var at: Vector2 = plan.fountain.at; var center := Vector3(at.x,float(plan.base_y)+.15,at.y)
	return row("courtyard","围院清泉",[circle(center,.73),circle(center+Vector3.UP*.3,.38)],center+Vector3.UP*.65)
static func arcade(house: Dictionary, face: Dictionary) -> Dictionary:
	var cell := {}
	for item: Dictionary in house.cells:
		if item.id == face.cell_id: cell = item; break
	var normal:=Basis(Vector3.UP,Frame.yaw(house))*Vector3(face.side.x,0,face.side.y); var tangent := Vector3(normal.z,0,-normal.x)
	var center := Frame.world3(house,Vector3(float(house.origin[0])+cell.x*1.8,float(house.get("base_y",0.)),float(house.origin[1])+cell.z*1.8))+normal*.94
	var arch: Array[Vector3] = [center-tangent*.72+Vector3.UP*.1,center-tangent*.72+Vector3.UP*.91]
	for i in range(17):
		var angle := PI-float(i)*PI/16.; arch.append(center+tangent*cos(angle)*.72+Vector3.UP*(.91+sin(angle)*.63))
	arch.append(center+tangent*.72+Vector3.UP*.1)
	return row("arcade","临街连拱",[arch],center+Vector3.UP*1.83)
static func glass(plan: Dictionary) -> Dictionary:
	var box: Rect2 = plan.bounds; var lines: Array = []; var center: Vector2 = plan.center
	for fraction: float in [0.08,.5,.92]:
		var rib: Array[Vector3] = []
		for i in range(17):
			var angle := PI-float(i)*PI/16.; var across := cos(angle)
			var at := Vector2(lerpf(box.position.x,box.end.x,fraction),center.y+across*box.size.y*.46) if plan.axis=="x" else Vector2(center.x+across*box.size.x*.46,lerpf(box.position.y,box.end.y,fraction))
			rib.append(Vector3(at.x,float(plan.base_y)+.6+sin(angle)*1.1,at.y))
		lines.append(rib)
	return row("conservatory","连格玻璃花房",lines,Vector3(center.x,float(plan.roof_top_y)+.25,center.y))
static func skybridge(plan: Dictionary) -> Dictionary:
	var a := Vector3(plan.a.x,plan.floor_y,plan.a.y); var b := Vector3(plan.b.x,plan.floor_y,plan.b.y)
	var across := Vector3(-(b-a).z,0,(b-a).x).normalized()*float(plan.width)*.5
	return row("skybridge",("九米云廊" if float(plan.length)+1.74>7.2 else "空中连桥")+" · 第%d层同高相接"%(int(plan.level)+1),[[a-across,b-across,b+across,a+across,a-across],[a-across+Vector3.UP*1.3,b-across+Vector3.UP*1.3,b+across+Vector3.UP*1.3,a+across+Vector3.UP*1.3,a-across+Vector3.UP*1.3]],(a+b)*.5+Vector3.UP*1.6)
static func bridge(plan: Dictionary) -> Dictionary:
	var lines:Array=[];var first:float=plan.start;var last:float=plan.end;var y:float=plan.deck_y
	var family:String=plan.get("family","");var label:="钢桁连桥" if family=="clockwork_truss" else "现代单拱桥" if family=="modern_single_arch" else "双拱石桥"
	var half:=float(plan.width)*.5+(.16 if family=="clockwork_truss" else .15 if family=="modern_single_arch" else .13)
	for side:float in [-1.,1.]:
		lines.append([_bridge_at(plan,first,side*half,y),_bridge_at(plan,last,side*half,y)])
		if family=="clockwork_truss":
			var rib:Array=[]
			for i in range(33):
				var t:=float(i)/32.;rib.append(_bridge_at(plan,lerpf(first,last,t),side*half,y+.30+2.1*sin(PI*t)))
			lines.append(rib)
		else:
			var count:=1 if family=="modern_single_arch" else 2
			var middle:float=(first+last)*.5;var pier:=minf(.28,(last-first)*.1)
			for span in range(count):
				var lo:=first if count==1 else first+.12 if span==0 else middle+pier*.5
				var hi:=last if count==1 else middle-pier*.5 if span==0 else last-.12
				var spring:=-.19;var rise:=maxf(.10,y-(.20 if count==1 else .18)-spring);var arch:Array=[]
				for i in range(33):
					var t:=float(i)/32.;arch.append(_bridge_at(plan,lerpf(lo,hi,t),side*half,spring+rise*sin(PI*t)))
				lines.append(arch)
	var center:=_bridge_at(plan,(first+last)*.5,0.,y+.8)
	return row("bridge",label+" · 两岸接通后成桥",lines,center)
static func _bridge_at(plan:Dictionary,arc:float,across:float,height:float)->Vector3:
	var point:=Bridge._point(plan.samples,arc);var at:Vector2=point.at+Vector2(-point.tangent.y,point.tangent.x)*across
	return Vector3(at.x,height,at.y)
static func simple_bridge(profile:Dictionary,width:float)->Array:
	var lines:Array=[];var run:Array=[]
	var reserved:Array=profile.get("bridge_runs",[])+profile.get("stepping_runs",[])
	for sample:Dictionary in profile.samples:
		var covered:bool=reserved.any(func(span):return float(sample.distance)>=float(span.start)-.000001 and float(sample.distance)<=float(span.get("end",span.get("finish",0.)))+.000001)
		if sample.bridge and not covered:run.append(sample)
		else:
			if run.size()>1:_simple_lines(run,width,lines,profile.samples)
			run=[]
	if run.size()>1:_simple_lines(run,width,lines,profile.samples)
	return [row("bridge","跨水小桥 · 两岸接通后成桥",lines,lines[0][0]+Vector3.UP*.8)] if not lines.is_empty() else []
static func _simple_lines(samples:Array,width:float,lines:Array,full_samples:Array)->void:
	for side:float in [-1.,1.]:
		var line:Array=[]
		for sample:Dictionary in samples:
			var tangent:Vector2=Bridge._point(full_samples,float(sample.distance)).tangent;var at:Vector2=sample.xz+Vector2(-tangent.y,tangent.x)*width*.5*side
			line.append(Vector3(at.x,float(sample.y),at.y))
		lines.append(line)

static func stairs(treads: Array) -> Dictionary:
	var lines: Array = []
	for tread: Dictionary in treads:
		var a: Vector2 = tread.a; var b: Vector2 = tread.b; var normal := Vector2(-(b-a).y,(b-a).x).normalized()*.55
		lines.append([Vector3(a.x-normal.x,tread.y+.04,a.y-normal.y),Vector3(a.x+normal.x,tread.y+.04,a.y+normal.y)])
	var mid: Dictionary = treads[treads.size()/2]
	return row("stairs","跨阶石琴",lines,Vector3(mid.a.x,mid.y+.65,mid.a.y))
