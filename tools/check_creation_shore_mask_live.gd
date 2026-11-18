extends SceneTree
const Palette=preload("res://scripts/visual/city_creation_shore_palette.gd")
const Terrain=preload("res://scripts/world/city_creation_terrain.gd")
var failures:Array=[]
var checks:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec()
	var viewport:=SubViewport.new();viewport.size=Vector2i(128,128);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.;camera.position.z=2.;viewport.add_child(camera)
	var quad:=MeshInstance3D.new();var mesh:=QuadMesh.new();mesh.size=Vector2(2,2);quad.mesh=mesh
	var material:=ShaderMaterial.new();var shader:=Shader.new()
	shader.code="shader_type spatial;\nrender_mode unshaded,fog_disabled;\n#include \"res://scripts/visual/shaders/creation_meadow_palette.gdshaderinc\"\n#include \"res://scripts/visual/shaders/creation_shore_palette.gdshaderinc\"\nvoid fragment(){float distance=-.2+UV.x*1.4;float height=-.2+UV.y*.8;float cover=shore_sand_cover(vec3(12.,shore_water_level+height,9.),distance);ALBEDO=vec3(cover); }"
	material.shader=shader;Palette.configure(material);quad.material_override=material;viewport.add_child(quad)
	check(material.get_shader_parameter("shore_water_level")==Terrain.WATER_LEVEL,"production palette config uses authoritative water level")
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw;var image:=viewport.get_texture().get_image()
	check(image.save_png(out+"/mask_height_distance.png")==OK,"native shared shader height-distance image")
	var elevated_max:=0.;var far_max:=0.;var wet_min:=1.;var height_reversal:=0.;var distance_reversal:=0.;var coverage:=0
	for y in range(128):
		for x in range(128):
			var value:=image.get_pixel(x,y).r
			if y>=55:elevated_max=maxf(elevated_max,value)
			if x>=82:far_max=maxf(far_max,value)
			if y<=24 and x<=10:wet_min=minf(wet_min,value)
			if y>0:height_reversal=maxf(height_reversal,value-image.get_pixel(x,y-1).r)
			if x>0:distance_reversal=maxf(distance_reversal,value-image.get_pixel(x-1,y).r)
			if value>.5:coverage+=1
	check(elevated_max==0.,"surface higher than 14cm over water receives no sand")
	check(far_max==0.,"land farther than 70cm from shore receives no sand")
	check(wet_min>.99,"submerged near contact preserves complete bed-sand endpoint")
	check(height_reversal<=.004,"sand coverage retreats continuously with actual height")
	check(distance_reversal<=.004,"sand coverage retreats continuously inland")
	check(coverage>1000 and coverage<6000,"native render has a bounded shore band rather than blank/full mask")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":{"elevated_max":elevated_max,"far_max":far_max,"wet_min":wet_min,"height_reversal":height_reversal,"distance_reversal":distance_reversal,"coverage_pixels":coverage,"scope":"Actual shared GLSL mask in native spatial renderer; distance and surface-height coordinates independently supplied. This is not an art-quality oracle."},"source_sha256":{"palette":FileAccess.get_sha256("res://scripts/visual/shaders/creation_shore_palette.gdshaderinc"),"binding":FileAccess.get_sha256("res://scripts/visual/city_creation_shore_palette.gd"),"tool":FileAccess.get_sha256("res://tools/check_creation_shore_mask_live.gd")}}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("SHORE_MASK ",JSON.stringify(report));viewport.queue_free();await process_frame;quit(0 if report.ok else 1)
