extends RefCounted
## The second click fixes a centre, so endpoint assistance must stay on its circle.
const Targets=preload("res://scripts/world/city_creation_road_endpoint_targets.gd")
static func sweep(a:Vector2,center:Vector2,target:Vector2,previous:float)->float:
	var angle:float=(a-center).angle_to(target-center)
	return clampf(previous+wrapf(angle-previous,-PI,PI),-TAU,TAU)
static func intersections(a:Vector2,b:Vector2,center:Vector2,radius:float)->Array[Vector2]:
	var axis:=b-a;var offset:=a-center;var length:=axis.length_squared();var result:Array[Vector2]=[]
	if length<.000001:return result
	var dot:=offset.dot(axis);var determinant:=dot*dot-length*(offset.length_squared()-radius*radius)
	if determinant<0.:return result
	for t:float in [(-dot-sqrt(determinant))/length,(-dot+sqrt(determinant))/length]:
		if t>=0. and t<=1.:result.append(a+axis*t)
	return result
static func endpoint(city:RefCounted,raw:Vector2,a:Vector2,center:Vector2,radius:float,turn:float)->Dictionary:
	if absf(turn)>PI and raw.distance_to(a)<=minf(1.8,radius*.25):return {"at":a,"self":true,"lock":"圆弧","kind":"circle"}
	var radial:Vector2=(a-center).rotated(turn);var tangent:=Vector2(-radial.y,radial.x)*signf(turn)
	var hit:=Targets.pick(city,raw,1.8,true,center+(a-center).rotated(turn)-tangent*.5)
	if hit.is_empty():return {}
	var points:Array[Vector2]=[]
	if absf(Vector2(hit.at).distance_to(center)-radius)<.00001:points.append(hit.at)
	if hit.has("a") and hit.has("b"):points.append_array(intersections(hit.a,hit.b,center,radius))
	var best:=1.8;var result:Dictionary={}
	for point:Vector2 in points:
		var distance:=raw.distance_to(point)
		if distance>best:continue
		if absf(sweep(a,center,point,turn)-turn)>PI*.5:continue
		best=distance;result=hit.duplicate();result.at=point;result.lock="同圆接入"
		if point.distance_to(hit.at)>.00001:result.kind="segment"
	return result
static func plan(city:RefCounted,a:Vector2,center:Vector2,raw:Vector2,previous:float,enabled:bool,width:float,style:String,decoration:String)->Dictionary:
	var points:Array[Vector2]=[a]
	var result:={"points":points,"end":raw,"control":center,"center":center,"circle":false,"turn":0.,"radius":0.,"arcs":[],"closure":{},"label":"点圆心 · 线段表示半径，不是道路","snap_enabled":enabled}
	if center.is_finite():
		var radius:=a.distance_to(center)
		var turn:=sweep(a,center,raw,previous) if raw.distance_to(center)>.001 else previous
		var hit:Dictionary=endpoint(city,raw,a,center,radius,turn) if enabled and radius>=.25 else {}
		if not hit.is_empty():turn=signf(turn)*TAU if hit.self else sweep(a,center,hit.at,turn)
		elif enabled and absf(rad_to_deg(turn)-snappedf(rad_to_deg(turn),15.))<=2.5:turn=deg_to_rad(snappedf(rad_to_deg(turn),15.))
		var count:=maxi(1,ceili(radius*absf(turn)/.25))
		if radius>=.25 and absf(turn)>.0001:
			points.clear()
			for i in range(count+1):points.append(center+(a-center).rotated(turn*float(i)/count))
			points[0]=a
			if not hit.is_empty():points[-1]=hit.at
		result.merge({"points":points,"end":points[-1],"circle":true,"turn":turn,"radius":radius,"closure":hit,"arcs":[{"at":center,"axis":(a-center).normalized(),"turn":turn,"radius":minf(2.2,radius*.4),"strong":enabled and absf(rad_to_deg(turn)-snappedf(rad_to_deg(turn),15.))<.001}],"label":"圆心已定 · R %.2fm · 扫角 %.1f°"%[radius,absf(rad_to_deg(turn))]},true)
		if not hit.is_empty():result.label+="\n✦ 圆弧闭合" if hit.self else "\n✦ 同圆接入"
	result.valid=city.preview_road(points,style,"none",width,decoration)
	return result
