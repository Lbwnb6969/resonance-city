extends RefCounted
## Original narrow, arched blades. Derived roots/clearance and GPU wind stay shared.
static func blade(_owner,s:SurfaceTool,index:int,folded:bool,tall:bool=false)->void:
	var angle:float=[.14,1.13,2.46,4.34,.62,2.89,5.53,3.76,5.03][index]
	var height:float=[.18,.23,.20,.16,.29,.26,.245,.36,.32][index]
	var reach:float=[.11,.08,.12,.10,.055,.075,.07,.105,.12][index]
	var width:float=[.012,.011,.013,.010,.012,.010,.011,.013,.012][index]
	if tall:height*=1.65;reach*=1.15;width*=.94
	var outward:=Vector3(cos(angle),0,sin(angle));var across:=Vector3(-outward.z,0,outward.x)
	var root:=outward*(.006+.003*(index%3));var points:Array[Vector3]=[];var rows:=5 if folded else 4
	for row in range(rows):
		var t:float=[0.,.24,.52,.79,1.][row] if folded else [0.,.38,.73,1.][row]
		var w:float=width*(.55+.95*sin(t*PI))*(1.-pow(t,2.8))
		var center:=_center(root,outward,height,reach,t,index)
		var tangent:=(_center(root,outward,height,reach,minf(1.,t+.001),index)-_center(root,outward,height,reach,maxf(0.,t-.001),index)).normalized()
		var side:Vector3=(across+tangent.cross(across)*sin(t*1.4+index)*.20).normalized()
		var up:=side.cross(tangent).normalized()
		if folded:points.append_array([center-side*w,center+up*w*.32,center+side*w])
		else:points.append_array([center-side*w,center+side*w])
	var columns:=3 if folded else 2
	for half in range(columns-1):
		var faces:Array[int]=[];var normals:Dictionary={}
		for row in range(rows-1):
			var a:=row*columns+half;var b:=a+1;var c:=a+columns;var d:=b+columns
			faces.append_array([a,d,b])
			if row<rows-2:faces.append_array([a,c,d])
		for face in range(0,faces.size(),3):
			var a:=faces[face];var b:=faces[face+1];var c:=faces[face+2];var area:Vector3=(points[c]-points[a]).cross(points[b]-points[a])
			for vertex:int in [a,b,c]:
				if not normals.has(vertex):normals[vertex]=[]
				normals[vertex].append(area.normalized())
		# The bent tip can turn sharply: smooth each actual slope fan, with a
		# crease across a strong fold instead of averaging through its backside.
		for face in range(0,faces.size(),3):
			var face_normal:Vector3=(points[faces[face+2]]-points[faces[face]]).cross(points[faces[face+1]]-points[faces[face]]).normalized()
			for vertex:int in faces.slice(face,face+3):
				var normal:=Vector3.ZERO
				for adjacent:Vector3 in normals[vertex]:
					if adjacent.dot(face_normal)>.35:normal+=adjacent
				s.set_normal(normal.normalized());s.set_color(Color.WHITE)
				s.set_uv(Vector2(float(index+1)+float(vertex%columns)/float(columns-1)*.25,clampf(points[vertex].y/height,0.,1.)));s.add_vertex(points[vertex])
static func _center(root:Vector3,outward:Vector3,height:float,reach:float,t:float,index:int)->Vector3:
	var bend:=pow(maxf(0.,(t-.38)/.62),2.)
	var across:=Vector3(-outward.z,0,outward.x)
	return root+outward*reach*pow(t,1.65)+Vector3.UP*height*(sin(t*PI*.5)-(.18+.035*sin(index*1.7))*bend)+across*.016*sin(t*PI)*sin(index*2.1)
static func base(_s:SurfaceTool)->void:
	# Blades meet the ground individually; no broad three-petal rosette below them.
	pass
