extends Control
## The logical ring is already settled; this layer only projects its audible state.
const Values = preload("res://scripts/spec_values.gd")
var view: CityDemoView
var cfg: Dictionary = Values.load_values()["ring"]
var last_dots: Dictionary = {}
var bpm: float = Values.load_values()["timing"]["bpm"]
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void: queue_redraw()
func phase_position(record: Dictionary, audible: float, rate: int, reduced: bool) -> Dictionary:
	var beat := audible/float(rate)*bpm/60.0
	var index := posmod(floori(beat),int(cfg["beats"]))
	var progress := fposmod(beat,1.0)
	var blend := 0.0
	var hold := float(cfg["tail"])*bpm/60.0
	if not reduced and progress > hold:
		blend = clampf((progress-hold)/(1.0-hold),0.0,1.0)
		blend = blend*blend*(3.0-2.0*blend)
	var origin := Vector2i(record["cell"][0],record["cell"][1])
	var offset: Array = cfg["offsets"][index]
	var next: Array = cfg["offsets"][(index+1)%int(cfg["beats"])]
	var at := view.point(origin+Vector2i(offset[0],offset[1]))
	var to := view.point(origin+Vector2i(next[0],next[1]))
	return {"index":index,"progress":progress,"position":at.lerp(to,blend)}
func _draw() -> void:
	last_dots.clear()
	if view == null or view.session == null: return
	var clock: Node = get_node("/root/AudioClock")
	var audible: float = clock.renderer.transport.audible_frame
	var color := Color(cfg["color"])
	for record in view.session.rings.values():
		if record["status"] not in ["unison","candidate","formed"]: continue
		var vertices := PackedVector2Array()
		var origin := Vector2i(record["cell"][0],record["cell"][1])
		for offset in cfg["offsets"]: vertices.append(view.point(origin+Vector2i(offset[0],offset[1])))
		vertices.append(vertices[0])
		color.a = float(cfg["active_alpha"] if record["status"] == "formed" else cfg["embryo_alpha"])
		draw_polyline(vertices,color,float(cfg["line_width"])*view.view_zoom,true)
		if record["status"] != "formed": continue
		var dot := phase_position(record,audible,clock.renderer.transport.sample_rate,view.reduced_motion)
		last_dots[record["anchor"]] = dot
		var point: Vector2 = dot["position"]
		draw_circle(point,float(cfg["glow_radius"])*view.view_zoom,Color(color.r,color.g,color.b,0.18))
		draw_circle(point,float(cfg["dot_radius"])*view.view_zoom,Color("f8e4ac"))
