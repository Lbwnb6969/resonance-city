extends RefCounted
## One metric recipe drives the main roof, projecting porch, pick faces and clearance.
const Context=preload("res://scripts/visual/city_creation_building_context.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const P=preload("res://scripts/world/city_creation_roof_primitives.gd")
const A=preload("res://scripts/visual/city_creation_architecture.gd")
const Cut=preload("res://scripts/world/city_creation_basilica_roof_pitch.gd")
static func authored(h:Dictionary)->bool:return h.get("architecture","")=="portico" and h.get("roof_pitch",{}).get("version")==10 and h.roof_pitch.get("profile")=="portico"
static func supported(city,h:Dictionary)->bool:return city.house_era(h)=="pastoral" and h.get("architecture","")=="portico" and not h.has("signature") and h.get("style","") not in ["timber","round_tower"] and is_zero_approx(Frame.Hinge.angle(h))
static func active(city,h:Dictionary)->bool:return authored(h) and supported(city,h)
static func ground(h:Dictionary)->Dictionary:
	var cells:Array=h.cells.filter(func(c):return int(c.level)==0 and c.kind=="room")
	if cells.is_empty():return {}
	var low:=Vector2i(cells[0].x,cells[0].z);var high:=low
	for c:Dictionary in cells:low=Vector2i(mini(low.x,c.x),mini(low.y,c.z));high=Vector2i(maxi(high.x,c.x),maxi(high.y,c.z))
	if cells.size()!=(high.x-low.x+1)*(high.y-low.y+1):return {}
	return {"center":Frame.origin(h)+Vector2(low+high)*.9,"width":(high.x-low.x+1)*1.8,"depth":(high.y-low.y+1)*1.8,"cell":cells[0],"count":cells.size()}
static func kind(h:Dictionary)->String:
	var p:=ground(h)
	if p.is_empty():return "local"
	if h.cells.all(func(c):return int(c.level)==0 and c.kind=="room"):return "temple"
	var upper:int=h.cells.filter(func(c):return int(c.level)>0 and c.kind=="room").size()
	return "villa" if h.cells.any(func(c):return c.kind=="terrace") or upper>0 and upper<int(p.count) else "local"
static func source_angle(city,h:Dictionary)->float:
	var p:=ground(h)
	return rad_to_deg(atan(minf(.68,(float(p.width)*.5+.13)*.38)/(float(p.width)*.5+.13))) if kind(h)=="temple" else 18.
static func _gable(parts:Array,name:String,half:float,eave:float,rise:float,z:float,thickness:float,bottom:float=-INF)->void:
	if rise<.000001 and (bottom==-INF or bottom>=eave-.000001):return
	var points:Array[Vector3]=[]
	var polygon:=PackedVector2Array([Vector2(-half,eave),Vector2(half,eave),Vector2(0,eave+rise)]) if bottom==-INF else PackedVector2Array([Vector2(-half,bottom),Vector2(half,bottom),Vector2(half,eave),Vector2(0,eave+rise),Vector2(-half,eave)])
	for point:Vector3 in A._extrude(polygon,thickness):points.append(point+Vector3(0,0,z))
	P.face(parts,name,points,"stone")
static func _cover(parts:Array,half:float,back:float,front:float,eave:float,degrees:float,prefix:String)->float:
	var rise:=half*tan(deg_to_rad(degrees))
	var start:=parts.size()
	for side:float in [-1.,1.]:
		var a:=Vector3(side*half,eave,back);var b:=Vector3(side*half,eave,front);var c:=Vector3(0,eave+rise,front);var d:=Vector3(0,eave+rise,back)
		P.prism(parts,prefix+"TileRoof",[a,b,c,d],"tile")
	for index in range(start,parts.size()):
		var uv:=PackedVector2Array()
		for point:Vector3 in parts[index].vertices:uv.append(Vector2(point.z/.22,signf(point.x)*Vector2(point.x,point.y-eave-rise).length()/.28))
		parts[index].uv=uv
	return rise
static func _append(result:Dictionary,h:Dictionary,parts:Array,pose:Transform3D,owner:Dictionary,category:String)->void:
	for part:Dictionary in parts:
		var vertices:Array[Vector3]=[];var low:=INF
		for point:Vector3 in part.vertices:var p:Vector3=pose*point;vertices.append(p);low=minf(low,p.y)
		var patch:={"surface":"roof","base_y":low,"vertices":vertices,"cell_id":str(owner.id),"part":part.name,"roof_skin":part.roof_skin,"category":category,"material":part.material}
		if part.has("uv"):patch.uv=part.uv
		result.patches.append(patch)
		if part.roof_skin:
			for i in range(0,vertices.size(),3):
				var center:Vector3=(vertices[i]+vertices[i+1]+vertices[i+2])/3.
				if center.y>result.apex.y:result.apex=center
static func local_parts(h:Dictionary)->Array:
	var parts:Array=[];var rise:=_cover(parts,.85,-.02,.60,1.491,float(h.roof_pitch.degrees),"PorticoEntry")
	_gable(parts,"PorticoEntryPediment",.85,1.445,rise,.29,.62)
	return parts
static func for_house(city,h:Dictionary)->Dictionary:
	var result:={"patches":[],"apex":Vector3(0,-INF,0),"kind":kind(h)}
	if not active(city,h):return result
	var p:=ground(h);var base:=float(h.get("base_y",0.))
	if result.kind=="temple":
		var parts:Array=[];var half:float=p.width*.5+.13;var back:float=-p.depth*.5-.12;var front:float=p.depth*.5+.47;var eave:=1.806
		var rise:=_cover(parts,half,back,front,eave,float(h.roof_pitch.degrees),"PorticoMain")
		for z:float in [back,front]:
			_gable(parts,"PorticoMainPediment",half,eave-.046,rise,z,.13,1.7 if z==back else 1.760)
			for side:float in [-1.,1.]:
				var delta:=Vector3(side*half,-rise,0);var basis:=Basis(Vector3.FORWARD,side*atan2(rise,half))
				P.box(parts,"PorticoRakingCornice",Vector3(delta.length()+.08,.065,.20),Vector3(side*half*.5,eave+rise*.5-.046-.0325/cos(deg_to_rad(float(h.roof_pitch.degrees))),z+.015),"stone",basis)
		var pose:=Transform3D(Basis.IDENTITY,Vector3(p.center.x,base,p.center.y))
		for cell:Dictionary in h.cells:
			var at:=Frame.origin(h)+Vector2(cell.x,cell.z)*1.8-Vector2(p.center);var low:=at-Vector2.ONE*.9;var top:=at+Vector2.ONE*.9
			if is_equal_approx(low.x,-p.width*.5):low.x-=.3
			if is_equal_approx(top.x,p.width*.5):top.x+=.3
			if is_equal_approx(low.y,-p.depth*.5):low.y-=.3
			if is_equal_approx(top.y,p.depth*.5):top.y+=.7
			var cut:Array=[]
			for part:Dictionary in parts:
				var piece:=Cut._cut(part,Rect2(low,top-low))
				if not piece.vertices.is_empty():cut.append(piece)
			_append(result,h,cut,pose,cell,"main")
	else:
		var ctx:=Context.new();ctx.prepare(city.houses,city.roads,city)
		for patch:Dictionary in ctx.roof_patches(str(h.id)):
			var row:Dictionary=patch.duplicate(true);row.roof_skin=patch.surface=="roof";row.category="main";row.part="PorticoMainTileRoof" if row.roof_skin else "PorticoMainPediment";row.surface="roof";row.material="tile" if row.roof_skin else "stone"
			if patch.has("coordinates"):row.uv=patch.coordinates
			result.patches.append(row)
			if row.roof_skin:
				for i in range(0,row.vertices.size(),3):
					var center:Vector3=(row.vertices[i]+row.vertices[i+1]+row.vertices[i+2])/3.
					if center.y>result.apex.y:result.apex=center
		if result.kind=="villa":
			var parts:Array=[];var half:float=p.width*.5+.11;var back:float=p.depth*.5+.035;var front:float=back+.69;var rise:=_cover(parts,half,back,front,1.76,float(h.roof_pitch.degrees),"PorticoPorch")
			_gable(parts,"PorticoPorchPediment",half,1.714,rise,front,.10,1.655)
			P.box(parts,"PorticoPorchClosure",Vector3(half*2,.059,.69),Vector3(0,1.6845,(back+front)*.5),"stone")
			for side:float in [-1.,1.]:P.box(parts,"PorticoPorchCornice",Vector3(Vector2(half,rise).length()+.04,.065,.16),Vector3(side*half*.5,1.76+rise*.5-.046-.0325/cos(deg_to_rad(float(h.roof_pitch.degrees))),front+.025),"stone",Basis(Vector3.FORWARD,side*atan2(rise,half)))
			_append(result,h,parts,Transform3D(Basis.IDENTITY,Vector3(p.center.x,base,p.center.y)),p.cell,"porch")
		else:
			var entries:Array=city.house_entrances(str(h.id))
			if not entries.is_empty():
				var entry:Dictionary=entries[0];var cell:Dictionary=h.cells.filter(func(c):return str(c.id)==str(entry.cell_id))[0];var side:Vector2i=entry.side
				var normal:=Vector3(side.x,0,side.y);var pose:=Transform3D(Basis(Vector3.UP,atan2(normal.x,normal.z)),Vector3(entry.wall_at.x,base+int(cell.level)*1.7,entry.wall_at.y))
				_append(result,h,local_parts(h),pose,cell,"entry")
	return result
