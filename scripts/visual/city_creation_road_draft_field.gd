extends RefCounted
## One temporary visual mask. Scan active polygon edges, never terrain cells.
const ShaderSource=preload("res://scripts/visual/shaders/creation_road_draft.gdshader")
const PIXEL:=.04
const BLOCK:=4.0
var rect: Rect2
var image: Image
var texture: ImageTexture
var material: ShaderMaterial
var updates:=0
var last_ms:=0.

func clear(renderer)->void:
	var pending:Array=renderer.get_meta("pending_road_masks",[])
	if not pending.is_empty():update(renderer,pending[0].points,pending[0].width);return
	for part: String in ["lawn","grass"]:
		if renderer.meadow!=null and renderer.meadow.materials.has(part):renderer.meadow.materials[part].set_shader_parameter("road_draft_enabled",false)

func update(renderer,points: Array[Vector2],width: float)->void:
	var started:=Time.get_ticks_usec()
	var strokes:Array=renderer.get_meta("pending_road_masks",[]).duplicate()
	strokes.append({"points":points,"width":width})
	var bounds:=Rect2(points[0],Vector2.ZERO)
	var contours:Array=[];var contour_groups:Array[int]=[]
	for stroke_index:int in range(strokes.size()):
		var stroke:Dictionary=strokes[stroke_index]
		var area:=Rect2(stroke.points[0],Vector2.ZERO)
		for point:Vector2 in stroke.points:area=area.expand(point)
		bounds=bounds.merge(area.grow(float(stroke.width)*.5+.5))
		var parts:Array=renderer._stroke_contours(stroke.points,float(stroke.width)*.5)
		for part in parts:contour_groups.append(stroke_index)
		contours.append_array(parts)
	var origin:=Vector2(floorf(bounds.position.x/BLOCK),floorf(bounds.position.y/BLOCK))*BLOCK
	var end_at:=Vector2(ceilf(bounds.end.x/BLOCK),ceilf(bounds.end.y/BLOCK))*BLOCK
	rect=Rect2(origin,end_at-origin)
	var dimensions:=Vector2i(roundi(rect.size.x/PIXEL),roundi(rect.size.y/PIXEL))
	var resized: bool=image==null or image.get_size()!=dimensions
	if resized:image=Image.create(dimensions.x,dimensions.y,false,Image.FORMAT_R8)
	image.fill(Color.BLACK)
	var buckets: Dictionary={};var first_row:=dimensions.y;var last_row:=0
	for contour_index:int in range(contours.size()):
		var contour:PackedVector2Array=contours[contour_index]
		for i in range(contour.size()):
			var a:=contour[i];var b:=contour[(i+1)%contour.size()]
			if a.y>b.y:var swap:=a;a=b;b=swap
			if b.y-a.y<.000001:continue
			var start:=clampi(ceili((a.y-rect.position.y)/PIXEL-.5),0,dimensions.y)
			var end:=clampi(ceili((b.y-rect.position.y)/PIXEL-.5),0,dimensions.y)
			if start>=end:continue
			var slope: float=(b.x-a.x)/(b.y-a.y)
			var x: float=a.x+(rect.position.y+(start+.5)*PIXEL-a.y)*slope
			if not buckets.has(start):buckets[start]=[]
			buckets[start].append(Vector4(x,slope*PIXEL,end,contour_groups[contour_index]))
			first_row=mini(first_row,start);last_row=maxi(last_row,end)
	var active: Array[Vector4]=[]
	for row in range(first_row,last_row):
		for i in range(active.size()-1,-1,-1):
			if int(active[i].z)<=row:active.remove_at(i)
		for edge: Vector4 in buckets.get(row,[]):active.append(edge)
		# Keep the original even/odd rule inside each stroke; union strokes by
		# painting white so crossing or retraced roads never XOR a grass hole.
		var groups:Dictionary={}
		for edge:Vector4 in active:
			if not groups.has(int(edge.w)):groups[int(edge.w)]=[]
			groups[int(edge.w)].append(edge.x)
		for crossings:Array in groups.values():
			crossings.sort()
			for i:int in range(0,crossings.size()-1,2):
				var x0:=clampi(ceili((crossings[i]-rect.position.x)/PIXEL-.5),0,dimensions.x)
				var x1:=clampi(ceili((crossings[i+1]-rect.position.x)/PIXEL-.5),0,dimensions.x)
				if x1>x0:image.fill_rect(Rect2i(x0,row,x1-x0,1),Color.WHITE)
		for i in range(active.size()):active[i].x+=active[i].y
	if texture==null:
		texture=ImageTexture.create_from_image(image)
		material=ShaderMaterial.new();material.shader=ShaderSource
		material.set_shader_parameter("draft_field",texture)
	elif resized:texture.set_image(image)
	else:texture.update(image)
	var world_rect:=Vector4(rect.position.x,rect.position.y,rect.size.x,rect.size.y)
	material.set_shader_parameter("draft_world_rect",world_rect)
	for part: String in ["lawn","grass"]:
		if not renderer.meadow.materials.has(part):continue
		var lawn: ShaderMaterial=renderer.meadow.materials[part]
		lawn.set_shader_parameter("road_draft_field",texture)
		lawn.set_shader_parameter("road_draft_enabled",true)
		lawn.set_shader_parameter("road_draft_world_rect",world_rect)
	updates+=1;last_ms=(Time.get_ticks_usec()-started)/1000.
