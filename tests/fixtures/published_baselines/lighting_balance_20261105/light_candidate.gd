extends RefCounted
## Visual comparison only. Every variant starts from the same production rig.
static func apply(demo:Node3D,variant:String,phase:int)->void:
	demo._set_light_phase(phase)
	var rig:RefCounted=demo.environment_rig
	# Replay the saved pre-change rig, even after the production rig advances.
	var control=preload("res://tests/fixtures/published_baselines/lighting_balance_20261105/baseline/city_creation_environment.gd").new()
	control.environment=rig.environment;control.sky_material=rig.sky_material;control.sun=rig.sun;control.view_pitch=rig.view_pitch;control.apply(phase)
	var env:Environment=rig.environment;var sun:DirectionalLight3D=rig.sun
	env.ssao_radius=.75;env.ssao_intensity=1.1;env.ssao_power=1.25;env.ssao_light_affect=.10
	sun.shadow_bias=.018;sun.shadow_normal_bias=1.15;sun.shadow_opacity=.82;sun.shadow_blur=1.4
	demo.get_viewport().msaa_3d=Viewport.MSAA_DISABLED
	for material:ShaderMaterial in preload("res://scripts/visual/city_creation_window_bounce.gd").materials(demo.town):material.set_shader_parameter("window_bounce_strength",1. if variant=="baseline" else 0.)
	if variant=="baseline":return
	demo.get_viewport().msaa_3d=Viewport.MSAA_2X
	var natural:=variant=="natural"
	env.tonemap_exposure=([.64,.76,1.04] if natural else [.67,.79,1.10])[phase]
	env.tonemap_white=([2.6,2.35,2.2] if natural else [2.4,2.25,2.1])[phase]
	env.ambient_light_energy=([.34,.36,.47] if natural else [.39,.37,.50])[phase]
	env.ambient_light_sky_contribution=([.60,.60,.40] if natural else [.55,.55,.35])[phase]
	sun.light_energy=([1.08,.86,.34] if natural else [1.,.80,.30])[phase]
	if natural:sun.rotation_degrees=[Vector3(-43,-53,0),Vector3(-22,-48,0),Vector3(-38,25,0)][phase]
	sun.shadow_bias=.012;sun.shadow_normal_bias=.65;sun.shadow_opacity=.86;sun.shadow_blur=1.2
	env.ssao_radius=.5;env.ssao_intensity=1.35;env.ssao_power=1.2;env.ssao_light_affect=.05
