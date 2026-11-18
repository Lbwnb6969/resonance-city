extends RefCounted
## Nearby endpoint diagnostics, using the production skybridge proof verbatim.
const Plan=preload("res://scripts/world/city_creation_skybridge_plan.gd")
static func building(city:RefCounted,changed:Dictionary)->Array:
	var best:=INF;var selected:Dictionary={}
	for cell:Dictionary in changed.cells:
		if int(cell.level) not in [1,2] or cell.kind!="room":continue
		var at:=Plan.Frame.center(changed,cell)
		for other:Dictionary in city.houses:
			if other.id==changed.id:continue
			for target:Dictionary in other.cells:
				if target.kind!="room":continue
				var to:=Plan.Frame.center(other,target);var delta:=to-at
				if delta.length()>12. or delta.length()<2.2:continue
				var local:=delta.rotated(Plan.Frame.yaw(changed))
				var side:=Vector2i(1 if local.x>0. else -1,0) if absf(local.x)>absf(local.y) else Vector2i(0,1 if local.y>0. else -1)
				var height:=absf(float(changed.get("base_y",0.))+int(cell.level)*1.7-float(other.get("base_y",0.))-int(target.level)*1.7)
				var score:=delta.length()+height*10.-int(cell.level)*.001
				if score>=best:continue
				best=score;selected=Plan.assess(city,changed,cell,other,target,side)
	if selected.is_empty() or selected.ok:return []
	return [{"kind":"bridge_hint","label":"连桥未成立 · "+str(selected.reason),"valid":false,"lines":[[selected.a,selected.b]],"at":(selected.a+selected.b)*.5+Vector3.UP*.8,"reason":selected.reason}]
