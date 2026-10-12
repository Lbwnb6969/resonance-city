extends Node2D
const IsoProjection = preload("res://scripts/world/world_projection.gd")
var city: ContinuousWorld
var seconds := 0.0
var zoom := 1.0
var draws := 0
var art_style_id := "baseline"

func sync(demo: Control) -> void:
	city = demo.shown_world
	seconds = demo.clock.renderer.transport.audible_frame/float(demo.clock.renderer.transport.sample_rate)
	zoom = demo.view_zoom
	art_style_id = demo.art_direction.selected_id
	position = Vector2(demo.size.x*0.5,demo.size.y*0.52)+demo.pan
	scale = Vector2.ONE*zoom
	visible = not demo.black
	queue_redraw()

func _point(p: Vector2,height: float) -> Vector2:
	return IsoProjection.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),height)

func _draw() -> void:
	if city == null: return
	draws += 1
	var family := city.terrain.family
	var length := float(city.terrain.cfg.get("template_land_max_y",city.terrain.cfg["template_land_max"]))+2.0
	if family == "river_valley" and art_style_id == "baseline":
		_draw_river_glints(length)
		return
	for i in range(floori(length/2.1)):
		var y := -3.0+fposmod(float(i)*2.1+seconds*0.35,length)
		var x := city.terrain.river_x(y)
		var span := 0.4 if family != "lake_basin" else 0.8
		draw_line(_point(Vector2(x-span,y),0.0),_point(Vector2(x+span,y+0.12),0.0),Color(0.8,0.91,0.9,0.28),1.0,true)
	if family == "lake_basin":
		for i in range(6):
			var ripple := Vector2(city.terrain.river_x(10.0+i*3.2),10.0+i*3.2)
			draw_arc(_point(ripple,0.01),(0.38+0.08*sin(seconds*2.0+i))/zoom,0,TAU,20,Color(0.86,0.93,0.9,0.22),0.8,true)

func _draw_river_glints(length: float) -> void:
	# The slow traces follow the real channel, with staggered lengths and
	# gentle breathing. They read as reflections rather than repeated white
	# transverse dashes or a second animated grid.
	for index in range(ceili(length/3.4)):
		var y := -2.0+fposmod(float(index)*3.4+seconds*0.13,length)
		var lane: float = [-0.26,0.13,0.31,-0.08][index%4]
		var span := 0.42+float(index%3)*0.19
		var path := reflection_path(y,lane,span)
		if path.size() < 2: continue
		var alpha := 0.13+0.055*sin(seconds*0.36+float(index)*1.73)
		draw_polyline(path,Color("b8d3c3",alpha*0.45),2.4/zoom,true)
		draw_polyline(path,Color("d5e4cf",alpha),0.85/zoom,true)

func reflection_path(y: float,lane: float,span: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(6):
		var at_y := y+(float(index)/5.0-0.5)*span
		var width: float = city.terrain.river_width(at_y)
		var x: float = city.terrain.river_x(at_y)+lane*width
		var p := Vector2(x,at_y)
		if not Geometry2D.is_point_in_polygon(p,city.terrain.water): return PackedVector2Array()
		result.append(_point(p,0.0))
	return result
