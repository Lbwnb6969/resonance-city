extends RefCounted
## View-only input. Empty hand is tool -1; city transactions remain untouched.
var dragging:=false
const HINT:="空手 · 左键拖动镜头 · WASD 移动 · 点画具继续营造"
static func painted_tools(demo:Node3D)->Array:
	return range(demo.tool_buttons.size()) if demo._painted_tool<0 else [demo._painted_tool,demo.tool].filter(func(i):return i>=0)
static func hint(demo:Node3D)->String:
	return HINT if demo.tool<0 else demo.Copy.TOOL_HINTS[demo.tool]
func empty_hover(demo:Node3D)->bool:
	if demo.tool>=0:return false
	demo.hovered={};demo.candidate.clear();demo.preview_key="";demo.town.clear_preview();return true
func blocked(demo:Node3D)->bool:
	var focus:Control=demo.get_viewport().gui_get_focus_owner()
	return demo.camera_rig.strolling or demo.gallery.busy or demo.gallery.panel.visible or demo.journal.panel.visible or demo.ledger.visible() or demo.guide.visible() or focus is LineEdit or focus is TextEdit or demo.get_window().has_focus()==false
func input(demo:Node3D,event:InputEvent)->bool:
	if dragging and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		dragging=false;return true
	if dragging and event is InputEventMouseMotion:
		if blocked(demo) or demo.tool>=0:dragging=false;return false
		var right:Vector3=demo.camera.global_basis.x
		var forward:=Vector3(-right.z,0,right.x)
		demo.focus+=(-right*event.relative.x+forward*event.relative.y)*demo.zoom/demo.get_viewport().get_visible_rect().size.y
		demo._update_camera();return true
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE and not blocked(demo):
		dragging=false;demo.orbiting=false;demo.panning=false
		demo.selected_house="";demo.select_tool(-1);return true
	return false
func unhandled(demo:Node3D,event:InputEvent)->bool:
	if demo.tool<0 and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and not blocked(demo):
		demo.pointer=event.position;dragging=true;return true
	return false
func update(demo:Node3D,delta:float)->void:
	if blocked(demo):dragging=false;return
	if demo.tool>=0:dragging=false
	if demo.house_drawing or demo.road_drawing or demo.vegetation_drawing or demo.water_drawing or demo.district_drawing or demo.district_link_drawing or demo.terrain_brush.drawing:return
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT):return
	var axes:=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	if axes==Vector2.ZERO:return
	var right:=Vector3(cos(demo.yaw),0,-sin(demo.yaw));var back:=Vector3(sin(demo.yaw),0,cos(demo.yaw))
	demo.focus+=(right*axes.x+back*axes.y).normalized()*demo.zoom*.65*minf(delta,.05)
	demo._update_camera()
