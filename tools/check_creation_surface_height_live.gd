extends "res://tools/check_creation_terrain_chunk_seams_live.gd"
const Terrain=preload("res://scripts/world/city_creation_terrain.gd")
func field_bytes()->PackedByteArray:return demo.town.surface_height_field.texture.get_image().get_data()
func inspect_field(label:String)->void:
	var field=demo.town.surface_height_field
	check(demo.town.ground_material.get_shader_parameter("terrain_height_field")==field.texture,"published ground binds the exact field: "+label)
	check(field_bytes()==demo.state._ground_terrain.vertices.to_byte_array(),label+": native RF upload equals authoritative published vertices")
	check(field.bytes==193*193*4,label+": single RF field is 148996 bytes")
	var uploads:int=field.uploads;field.publish(demo.town)
	check(field.uploads==uploads,label+": unchanged field skips upload")
	var material:=ShaderMaterial.new();var shader:=Shader.new()
	shader.code="shader_type canvas_item;\n#include \"res://scripts/visual/shaders/creation_surface_height.gdshaderinc\"\nuniform vec2 probes[32];\nvoid fragment(){float h=terrain_surface_height(probes[int(floor(UV.x*32.))]);float q=round(clamp((h+2.)/16.,0.,1.)*65535.);COLOR=vec4(floor(q/256.)/255.,mod(q,256.)/255.,0.,1.);}"
	material.shader=shader;field.bind(material)
	var points:=PackedVector2Array([Vector2(-48,-48),Vector2(48,48),Vector2(-48,48),Vector2(48,-48)])
	for i in range(28):
		var cell:=Vector2((i*31)%191,(i*67)%191)
		points.append(Vector2(-48,-48)+(cell+(Vector2(.2,.7) if i%2==0 else Vector2(.8,.3)))*.5)
	material.set_shader_parameter("probes",points)
	var viewport:=SubViewport.new();viewport.size=Vector2i(32,1);viewport.disable_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var rect:=ColorRect.new();rect.size=Vector2(32,1);rect.material=material;viewport.add_child(rect)
	await process_frame;await RenderingServer.frame_post_draw
	var image:=viewport.get_texture().get_image();var maximum:=0.;var samples:Array=[]
	for i in range(32):
		var color:=image.get_pixel(i,0);var actual:float=(round(color.r*255.)*256.+round(color.g*255.))/65535.*16.-2.
		var expected:float=demo.state.ground_height(points[i]);maximum=maxf(maximum,absf(actual-expected));samples.append({"at":points[i],"cpu":expected,"gpu":actual})
	check(maximum<.00025,label+": actual GLSL sampler matches CPU triangles at boundaries and both halves")
	facts.samples.append({"label":label,"max_error":maximum,"uploads":uploads,"samples":samples})
	viewport.queue_free();await process_frame
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=100
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();facts={"edits":[],"samples":[]}
	var city:=State.new();check(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://数据/地貌河湾样例.json"))).ok,"old authored fixture restores")
	await show(city,Vector2(12,9),"实际河床高度");quiet();await inspect_field("old work")
	var original:=field_bytes();var water:ShaderMaterial=demo.town.water_material
	check(water.get_shader_parameter("terrain_height_field")==demo.town.surface_height_field.texture,"visible production water binds current height texture")
	var changed:Dictionary=demo.state.add_terrain_stroke([Vector2(19,9)] as Array[Vector2],"raise",3.,.65)
	check(changed.ok,"public terrain edit accepted");demo._after_edit(changed,"terrain")
	check(field_bytes()==original,"queued edit leaves published field untouched before worker commit")
	await settle();await inspect_field("edited")
	var edited:=field_bytes();check(edited!=original,"committed edit changes the visual height field")
	await key(KEY_Z,true);await settle();check(field_bytes()==original,"native Undo restores original field bytes")
	await key(KEY_Y,true);await settle();check(field_bytes()==edited,"native Redo restores edited field bytes")
	var saved:Dictionary=JSON.parse_string(JSON.stringify(demo.state.snapshot()));FileAccess.open(OUT+"/world.json",FileAccess.WRITE).store_string(JSON.stringify(saved))
	var cold:=State.new();check(cold.restore(saved).ok,"edited work cold restores")
	await show(cold,Vector2(12,9),"冷读河床");quiet();check(field_bytes()==edited,"fresh renderer publishes exact cold field");await inspect_field("cold")
	changed=demo.state.add_terrain_stroke([Vector2(19,9)] as Array[Vector2],"lower",4.,.7);demo.town.request_budget_rebuild()
	check(changed.ok and not demo.edit_pending(),"renderer-only pending generation exercises teardown while normal gallery edit lock remains respected")
	var empty:=State.new();empty.initialize_empty();await show(empty,Vector2(0,0),"在途换城");quiet();var new_field:=field_bytes()
	for i in range(90):await process_frame
	check(field_bytes()==new_field and demo.state.terrain_strokes.is_empty(),"old in-flight terrain edit cannot publish into the new city");await inspect_field("switched")
	check(not demo.persistence and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save bytes preserved")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("SURFACE_HEIGHT ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
