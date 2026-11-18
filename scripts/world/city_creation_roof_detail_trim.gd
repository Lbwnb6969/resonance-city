extends RefCounted
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const Original=preload("res://scripts/visual/city_creation_gable_trim.gd")
const Shapes=preload("res://scripts/world/city_creation_roof_detail_shapes.gd")
static func outlines(house:Dictionary,patches:Array)->Array:
	var edges:Dictionary={}
	for patch:Dictionary in patches:
		if not patch.get("roof_skin",false):continue
		for i in range(0,patch.vertices.size(),3):
			var a:Vector3=patch.vertices[i];var b:Vector3=patch.vertices[i+1];var c:Vector3=patch.vertices[i+2]
			if (b-a).cross(c-a).y<=.00001:continue
			for pair:Array in [[a,b],[b,c],[c,a]]:
				var first:=Vector3(pair[0]);var last:=Vector3(pair[1]);var ka:=str(first.snapped(Vector3.ONE*.0001));var kb:=str(last.snapped(Vector3.ONE*.0001));var key:=ka+"|"+kb if ka<kb else kb+"|"+ka
				var row:Dictionary=edges.get(key,{"a":first,"b":last,"count":0,"cell_id":patch.cell_id});row.count+=1;edges[key]=row
	var result:Array=[]
	for row:Dictionary in edges.values():
		if row.count!=1:continue
		var a:Vector3=row.a;var b:Vector3=row.b;var normal:=Vector2(-(b-a).z,(b-a).x).normalized();var mid:=Vector2((a.x+b.x)*.5,(a.z+b.z)*.5)
		if normal.dot(mid-Frame.origin(house))<0:normal=-normal
		result.append({"surface":"fascia" if is_equal_approx(a.y,b.y) else "simple_verge","side":Vector2i(roundi(normal.x),roundi(normal.y)),"a":a,"b":b,"base_y":minf(a.y,b.y),"cell_id":str(row.cell_id)})
	return result
static func plan(city,house:Dictionary,patches:Array,key:String,seed_value:int)->Dictionary:
	var parts:Array=[];var records:Array=[]
	for patch:Dictionary in outlines(house,patches):
		var outward:=Vector3(patch.side.x,0,patch.side.y);var a:Vector3=patch.a;var b:Vector3=patch.b
		if patch.surface=="simple_verge":
			a+=outward*.055-Vector3.UP*.032;b+=outward*.055-Vector3.UP*.032;add(city,house,parts,records,patch,a,b,.065 if key=="timber_verge" else .075,"verge");continue
		a+=outward*.032-Vector3.UP*.045;b+=outward*.032-Vector3.UP*.045
		add(city,house,parts,records,patch,a,b,.07 if key=="timber_verge" else .10,"eave")
		var count:=maxi(1,floori(a.distance_to(b)/(.42 if key=="timber_verge" else .19)));var phase:=.35+posmod(seed_value,3)*.10
		for i in range(count):
			var at:=a.lerp(b,(i+phase)/count)-Vector3.UP*(.09 if key=="timber_verge" else .085)
			add(city,house,parts,records,patch,at-outward*.06-Vector3.UP*.035 if key=="timber_verge" else at-Vector3.UP*.025,at+outward*.025+Vector3.UP*.035 if key=="timber_verge" else at+Vector3.UP*.025,.04 if key=="timber_verge" else .065,"bracket" if key=="timber_verge" else "dentil")
	return {"parts":parts,"records":records}
static func add(city,house:Dictionary,parts:Array,records:Array,patch:Dictionary,a:Vector3,b:Vector3,width:float,kind:String)->void:
	if a.distance_to(b)<.0001 or not Original.clear(city,house,a,b,width):return
	var up:=Vector3.RIGHT if absf((b-a).normalized().dot(Vector3.UP))>.999 else Vector3.UP
	Shapes.box(parts,"GableTrim_"+kind,Vector3(width,width,a.distance_to(b)+.004),(a+b)*.5,"trim",Basis.looking_at(b-a,up));parts[-1].cell_id=str(patch.cell_id)
	records.append({"kind":kind,"a":a,"b":b,"width":width,"cell_id":str(patch.cell_id),"surface":patch.surface})
