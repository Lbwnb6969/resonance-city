extends Node2D
const IsoProjection = preload("res://scripts/world/world_projection.gd")
var city: ContinuousWorld
var seconds := 0.0
var zoom := 1.0
var draws := 0

func sync(demo: Control) -> void:
	city = demo.shown_world
	seconds = demo.clock.renderer.transport.audible_frame/float(demo.clock.renderer.transport.sample_rate)
	zoom = demo.view_zoom
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
	for i in range(18):
		var y := -3.0+fposmod(float(i)*2.1+seconds*0.35,38.0)
		var x := city.terrain.river_x(y)
		var span := 0.4 if family != "lake_basin" else 0.8
		draw_line(_point(Vector2(x-span,y),0.0),_point(Vector2(x+span,y+0.12),0.0),Color(0.8,0.91,0.9,0.28),1.0,true)
	if family == "lake_basin":
		for i in range(6):
			var ripple := Vector2(city.terrain.river_x(10.0+i*3.2),10.0+i*3.2)
			draw_arc(_point(ripple,0.01),(0.38+0.08*sin(seconds*2.0+i))/zoom,0,TAU,20,Color(0.86,0.93,0.9,0.22),0.8,true)
