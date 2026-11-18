extends RefCounted

static func build(renderer, parent: Node3D, part: Dictionary, material: Material, surface_color: Color) -> MeshInstance3D:
	var mesh: MeshInstance3D
	if part.type == "box":
		mesh = renderer._box(parent, part.size, part.at, material)
	else:
		mesh = renderer._roof_surface(parent, part.vertices, surface_color)
		mesh.material_override = material
		mesh.position = part.at
	mesh.basis = part.basis
	mesh.name = part.name
	mesh.visibility_range_end = 64.0
	if part.material == "glass":
		mesh.set_meta("creation_live_visual", true)
	return mesh

static func glass_material() -> StandardMaterial3D:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("344e53")
	glass.roughness = 0.28
	glass.set_meta("creation_fixed_color", true)
	glass.set_meta("creation_facade_glass", true)
	return glass
