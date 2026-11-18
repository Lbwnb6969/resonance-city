extends RefCounted
## Shared phase gate for small architectural lamps; geometry stays static.
static func material(renderer,albedo:Color,emission:Color,night_energy:float)->StandardMaterial3D:
	var lamp:=StandardMaterial3D.new();lamp.albedo_color=albedo;lamp.emission=emission;lamp.emission_enabled=true;lamp.set_meta("creation_phase_lamp",true);lamp.set_meta("creation_phase_energy",night_energy);apply_material(lamp,renderer.light_phase);return lamp
static func apply_material(lamp:StandardMaterial3D,phase:int)->void:
	lamp.emission_energy_multiplier=float(lamp.get_meta("creation_phase_energy",.35))*(0.30 if phase==1 else 1.0 if phase==2 else 0.0)
static func apply(root:Node3D,phase:int)->void:
	for mesh:MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		var lamp:=mesh.material_override as StandardMaterial3D
		if lamp!=null and bool(lamp.get_meta("creation_phase_lamp",false)):apply_material(lamp,phase)
