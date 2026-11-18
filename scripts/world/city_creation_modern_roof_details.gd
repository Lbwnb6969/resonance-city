extends RefCounted
## One immutable plan for modern authored roof details on CPU and GPU.
const Geometry=preload("res://scripts/world/city_creation_modern_roof_pitch.gd")
const Choice=preload("res://scripts/world/city_creation_architecture_variants.gd")
const Dormer=preload("res://scripts/visual/city_creation_dormer_sites.gd")
const Chimney=preload("res://scripts/visual/city_creation_chimney_sites.gd")
const Shapes=preload("res://scripts/world/city_creation_roof_detail_shapes.gd")
const Trim=preload("res://scripts/world/city_creation_roof_detail_trim.gd")
static func plan(city,h:Dictionary,base:Array=[])->Dictionary:
	var selected:bool=Choice.trim_supported(city,h) and not Choice.trim(h).is_empty() or Choice.dormer_supported(city,h) and not Choice.dormer(h).is_empty() or Choice.chimney_active(city,h)
	if not selected:return {"details":[],"patches":[]}
	var token:=hash([city.revision,city._wish_epoch,h]);var cached:Dictionary=city.get_meta("modern_roof_details",{});var id:=str(h.id)
	if cached.get(id,{}).get("token")==token:return cached[id].plan
	if base.is_empty():base=Geometry.patches(city,h)
	var result:={"details":[],"patches":[]};var surface:Array[Vector3]=[];var occupied:Array[Vector3]=[]
	for patch:Dictionary in base:
		for point:Vector3 in patch.vertices:
			if patch.get("roof_skin",false):surface.append(point)
			else:occupied.append(point)
	var key:=Choice.trim(h)
	if not key.is_empty() and Choice.trim_supported(city,h):
		var data:=Trim.plan(city,h,base,key,int(Choice.record(h,"gable_trim").seed));var item:={"slot":"gable_trim","id":key,"origin":Vector3.ZERO,"parts":data.parts,"active":not data.parts.is_empty(),"records":data.records,"seed":int(Choice.record(h,"gable_trim").seed)}
		append(result,item,occupied)
	key=Choice.dormer(h)
	if not key.is_empty() and Choice.dormer_supported(city,h):
		var diagnostics:Dictionary={};var site:Dictionary={} if key=="off" else Dormer.from_faces(city,h,surface,occupied,diagnostics)
		var item:={"slot":"roof_detail","id":key,"active":not site.is_empty(),"site":site,"parts":[],"origin":Vector3.ZERO,"rejected":diagnostics}
		if not site.is_empty():item.origin=Vector3(site.at.x,site.low-.015,site.at.y);item.parts=Shapes.dormer(site,key);item.seed=int(Choice.record(h,"dormer").seed)
		append(result,item,occupied)
	key=Choice.chimney(h)
	if Choice.chimney_active(city,h):
		var diagnostics:Dictionary={};var site:Dictionary={} if key=="off" else Chimney.from_faces(city,h,surface,occupied,diagnostics)
		var item:={"slot":"chimney_detail","id":key,"active":not site.is_empty(),"site":site,"parts":[],"origin":Vector3.ZERO,"outlets":[],"rejected":diagnostics}
		if not site.is_empty():
			var shape:=Shapes.chimney(site,key);item.origin=Vector3(site.at.x,site.low-.025,site.at.y);item.parts=shape.parts;item.top=shape.top
			for point:Vector3 in shape.outlets:item.outlets.append(item.origin+point)
		append(result,item,occupied)
	cached[id]={"token":token,"plan":result};city.set_meta("modern_roof_details",cached);return result
static func append(result:Dictionary,item:Dictionary,occupied:Array[Vector3])->void:
	result.details.append(item)
	for part:Dictionary in item.parts:
		var points:Array[Vector3]=[];var low:=INF
		for p:Vector3 in Shapes.vertices(part):var point:Vector3=p+Vector3(item.origin);points.append(point);occupied.append(point);low=minf(low,point.y)
		result.patches.append({"surface":"roof","base_y":low,"vertices":points,"cell_id":str(part.get("cell_id",item.get("site",{}).get("cell_id",""))),"part":str(part.name),"detail":str(item.slot)})
