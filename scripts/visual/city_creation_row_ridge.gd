extends RefCounted
## A fitted clay roll shares the row's tile scale and follows its real ridge.
const Wall=preload("res://scripts/visual/city_creation_wall_material.gd")
const HALF_WIDTH:=.105
const LAP:=.38
const END_CLEARANCE:=.045

static func guide(gable:Dictionary,bounds:Rect2,xs:Array[float],zs:Array[float],points:Array)->Dictionary:
	var along_x:bool=gable.along_x
	var along:Array[float]=xs if along_x else zs
	var across:Array[float]=zs if along_x else xs
	var crest:=across.find(float(gable.cross))
	if crest<=0 or crest>=across.size()-1:
		return {}
	var sections:Array[PackedVector3Array]=[]
	for index in range(along.size()):
		var section:=PackedVector3Array()
		for cross_index:int in [crest-1,crest,crest+1]:
			section.append(points[index][cross_index] if along_x else points[cross_index][index])
		sections.append(section)
	var first:=sections.front() as PackedVector3Array
	if first[1].y==first[0].y and first[1].y==first[2].y:
		return {}
	return {"sections":sections,"along":along,"along_x":along_x,
		"group_start":bounds.position.x if along_x else bounds.position.y,
		"group_end":bounds.end.x if along_x else bounds.end.y}

static func faces(rail:Dictionary)->Array[Vector3]:
	var vertices:Array[Vector3]=[]
	var along:Array[float]=rail.along
	var start:=maxf(along.front(),float(rail.group_start)+END_CLEARANCE)
	var end:=minf(along.back(),float(rail.group_end)-END_CLEARANCE)
	if end-start<.0001:
		return vertices
	var stations:Array[float]=[start,end]
	for at:float in along:
		if at>start and at<end:
			stations.append(at)
	var origin:float=rail.group_start
	for tile in range(floori((start-origin)/LAP),ceili((end-origin)/LAP)):
		for lip:float in [0.,.035,.095]:
			var at:=origin+tile*LAP+lip
			if at>start and at<end:
				stations.append(at)
	stations.sort()
	var span:=0
	var previous:=PackedVector3Array()
	var previous_at:=-INF
	for at:float in stations:
		if at-previous_at<.00001:
			continue
		while span+1<along.size()-1 and at>along[span+1]:
			span+=1
		var blend:=inverse_lerp(along[span],along[span+1],at)
		var section:=_section(rail.sections[span],rail.sections[span+1],blend,rail.along_x,fposmod(at-origin,LAP))
		if not previous.is_empty():
			for strip in range(section.size()-1):
				var a:=previous[strip]
				var b:=section[strip]
				var c:=section[strip+1]
				var d:=previous[strip+1]
				vertices.append_array([a,c,b,a,d,c] if rail.along_x else [a,b,c,a,c,d])
		previous=section
		previous_at=at
	return vertices

static func _section(a:PackedVector3Array,b:PackedVector3Array,blend:float,along_x:bool,phase:float)->PackedVector3Array:
	var crest:=a[1].lerp(b[1],blend)
	var low:=a[0].lerp(b[0],blend)
	var high:=a[2].lerp(b[2],blend)
	var outer_distance:=minf(absf(crest.z-low.z),absf(high.z-crest.z)) if along_x else minf(absf(crest.x-low.x),absf(high.x-crest.x))
	var width:=minf(HALF_WIDTH,outer_distance)
	var lip:=.018*(1.-smoothstep(0.,.095,absf(phase-.035)))
	var section:=PackedVector3Array()
	for offset:float in [-1.,-.56,0.,.56,1.]:
		var edge:=low if offset<0. else high
		var distance:=absf(crest.z-edge.z) if along_x else absf(crest.x-edge.x)
		var point:=crest.lerp(edge,absf(offset)*width/distance)
		point.y+=.004+(.075+lip)*sqrt(maxf(0.,1.-offset*offset))
		section.append(point)
	return section

static func collect(parent:Node3D,house:Dictionary,patch:Dictionary,combined:Array[Vector3])->void:
	var rail:Dictionary=patch.get("ridge_guide",{})
	if rail.is_empty():
		return
	var vertices:=faces(rail)
	if vertices.is_empty():
		return
	combined.append_array(vertices)
	var body:=StaticBody3D.new()
	body.name="RowRidgePick_"+str(patch.cell_id)
	body.set_meta("house_id",house.id)
	body.set_meta("cell_id",patch.cell_id)
	body.set_meta("roof_surface",true)
	for cell:Dictionary in house.cells:
		if str(cell.id)==str(patch.cell_id):
			body.set_meta("cell",cell)
			break
	parent.add_child(body)
	var collision:=CollisionShape3D.new()
	var shape:=ConcavePolygonShape3D.new()
	shape.set_faces(PackedVector3Array(vertices))
	shape.backface_collision=true
	collision.shape=shape
	body.add_child(collision)

static func finish(renderer,parent:Node3D,combined:Array[Vector3],roof_color:Color)->void:
	if combined.is_empty():
		return
	var color:=roof_color.lerp(Color("c38969"),.16).darkened(.15)
	var mesh:MeshInstance3D=renderer._triangles(parent,combined,color)
	mesh.name="RowRidgeCover"
	mesh.material_override=Wall.component(renderer,color,Wall.Kind.TERRACOTTA)
