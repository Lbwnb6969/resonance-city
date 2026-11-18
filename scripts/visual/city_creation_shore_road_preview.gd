extends RefCounted
const Bed=preload("res://scripts/visual/city_creation_shore_road_bed.gd")
static func show(renderer,points:Array[Vector2],width:float,style:String)->void:
	if points.size()<2:return
	var near:=false
	for i in range(1,points.size()):
		var count:=maxi(1,ceili(points[i-1].distance_to(points[i])/.35))
		for j in range(count+1):near=near or renderer.state.water_clearance(points[i-1].lerp(points[i],float(j)/count))<width*.5+Bed.REACH
	if not near:return
	var key:Array=[renderer.state.get_instance_id(),renderer.state._wish_epoch,renderer.state.revision,points.duplicate(),width,style]
	var ready:Dictionary=renderer.get_meta("shore_road_preview",{})
	renderer.preview.set_meta("shore_request",key)
	if ready.get("key")==key:
		Bed.install(renderer,renderer.preview,ready.bed,ready.road,true,ready.mesh)
		renderer.preview.set_meta("shore_bed_signature",hash(ready.bed));return
	var worker=renderer.get_node_or_null("ShorePreviewWorker")
	if worker==null:
		worker=preload("res://scripts/visual/city_creation_shore_preview_worker.gd").new();worker.name="ShorePreviewWorker";renderer.add_child(worker)
	worker.request(renderer,key,points,width,style)
