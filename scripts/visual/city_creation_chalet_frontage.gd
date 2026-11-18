extends RefCounted

const Wall = preload("res://scripts/visual/city_creation_wall_material.gd")

static func build(renderer, wall: Node3D, palette: Array, level: int, entrance: Dictionary, principal: bool, role: String) -> void:
	var face := Node3D.new()
	face.name = "ChaletFrontage"
	wall.add_child(face)
	var cedar := Wall.component(renderer, palette[2].lerp(Color("77523d"), .76), Wall.Kind.TIMBER)
	var lime := Wall.component(renderer, palette[0].lerp(Color("e6d9b9"), .72), Wall.Kind.PLASTER)
	var stone := Wall.component(renderer, Color("a8a28f"), Wall.Kind.STONE)
	var shutter := Wall.component(renderer, Color("516d64"), Wall.Kind.TIMBER)
	var upper := level > 0
	wall.set_meta("modern_glass", {"floor_to_ceiling":false,"alpine_kind":0,"warm":true})
	for edge: float in [-.855,.855]:
		renderer._box(face, Vector3(.085,1.48,.17), Vector3(edge,.87,.035), cedar)
	renderer._box(face, Vector3(1.8,.115,.20), Vector3(0,1.53,.045), cedar)
	if entrance.is_empty():
		windows(renderer, face, upper, lime, cedar, stone)
	else:
		door(renderer, face, principal, lime, cedar, shutter)
		if principal and not entrance.active and not entrance.get("upper_stoop",false) and role=="residential":
			canopy(renderer, face, cedar)

static func windows(renderer, face: Node3D, upper: bool, lime: Material, cedar: Material, stone: Material) -> void:
	var sill := .63 if upper else .52
	var head := 1.38
	var frame_half := .64 if upper else .55
	var jamb := .815-frame_half
	var glass: Material = renderer.conservatory.ensure_material(true)
	for sign_x: float in [-1.,1.]:
		renderer._box(face, Vector3(jamb,1.45,.13), Vector3(sign_x*(frame_half+jamb*.5),.85,0), lime)
		var pane: MeshInstance3D = renderer._box(face, Vector3(frame_half-.032,head-sill,.035), Vector3(sign_x*(frame_half+.032)*.5,(head+sill)*.5,-.012), glass)
		pane.set_meta("creation_live_visual",true)
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	renderer._box(face, Vector3(frame_half*2.,sill-.14,.15), Vector3(0,(sill+.14)*.5,0), cedar if upper else stone)
	renderer._box(face, Vector3(frame_half*2.,1.52-head,.15), Vector3(0,(1.52+head)*.5,0), lime)
	renderer._box(face, Vector3(.064,head-sill,.13), Vector3(0,(head+sill)*.5,.012), cedar)
	renderer._box(face, Vector3(frame_half*2.+.16,.07,.26), Vector3(0,sill,.057), cedar)
	if upper:
		renderer._box(face, Vector3(1.8,.10,.28), Vector3(0,.28,.07), cedar)

static func door(renderer, face: Node3D, principal: bool, lime: Material, cedar: Material, shutter: Material) -> void:
	var half := .34 if principal else .27
	var width := .82-half
	for sign_x: float in [-1.,1.]:
		renderer._box(face, Vector3(width,1.40,.14), Vector3(sign_x*(half+width*.5),.84,0), lime)
		renderer._box(face, Vector3(.065,1.28,.18), Vector3(sign_x*(half+.02),.78,.045), cedar)
	renderer._box(face, Vector3(2.*half,1.23,.075), Vector3(0,.755,.01), shutter if principal else cedar)
	renderer._box(face, Vector3(.035,.17,.055), Vector3(half-.08,.74,.072), renderer._material(Color("b59969")))
	renderer._box(face, Vector3(2.*half+.10,.12,.19), Vector3(0,1.42,.04), cedar)

static func canopy(renderer, face: Node3D, cedar: Material) -> void:
	var slate := Wall.component(renderer, Color("485a62"), Wall.Kind.SLATE)
	var porch := Node3D.new()
	porch.name = "ChaletEntryCanopy"
	face.add_child(porch)
	for sign_x: float in [-1.,1.]:
		var slope := Vector3(.57,.20,0)
		var roof: MeshInstance3D = renderer._box(porch,Vector3(slope.length(),.085,.54),Vector3(sign_x*.285,1.51,.29),slate)
		roof.rotation.z = -sign_x*atan2(slope.y,slope.x)
		var fascia: MeshInstance3D = renderer._box(porch,Vector3(slope.length(),.065,.055),Vector3(sign_x*.285,1.46,.535),cedar)
		fascia.rotation.z = roof.rotation.z
		var brace: MeshInstance3D = renderer._box(porch,Vector3(.065,.065,.44),Vector3(sign_x*.46,1.27,.27),cedar)
		brace.rotation.x = -.55
