extends "res://tools/check_creation_three_road_modes_live.gd"
const Unified=preload("res://scripts/ui/city_creation_unified_build.gd")

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):
		quit(1)
		return
	var began:=Time.get_ticks_msec()
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1440,900)
	Engine.max_fps=60
	demo=Scene.instantiate()
	demo.persistence=false
	demo.collection_directory=OUT+"/works"
	root.add_child(demo)
	await settle()
	isolate_input()
	var city:=State.new()
	city.initialize_free()
	var along_x:Array=[]
	var along_z:Array=[]
	for i:int in range(7):
		along_x.append({"x":i,"z":0,"level":0,"kind":"room"})
		if i<4:along_z.append({"x":0,"z":i,"level":0,"kind":"room"})
	check(city.add_house_stroke(Vector2(-33,-28),along_x).ok,"author seven rooms as a single row")
	check(city.add_house_stroke(Vector2(-15,-31),along_z).ok,"author the perpendicular row")
	check(city.set_house_style("h1","timber").ok and city.set_house_style("h2","timber").ok,"choose the wood-framed gabled house form")
	var road:Array[Vector2]=[Vector2(-35,-25.5),Vector2(-20,-25.5)]
	check(city.add_road(road,"cobble","none").ok,"author the shared street")
	await show(city,Vector2(-24,-28),"沿街连屋")
	quiet()
	demo.ui_layer.hide()
	demo.weather_visual.hide()
	city=demo.state
	var authored:Dictionary=city.snapshot()
	demo.yaw=.21
	demo.pitch=.52
	demo.zoom=25.
	demo._update_camera()
	await capture("street_day")
	demo._set_light_phase(2)
	await capture("street_night")
	demo._set_light_phase(0)
	demo.focus=Vector3(-28.5,1.3,-28)
	demo.zoom=9.
	demo._update_camera()
	await capture("ridge_detail")
	if not "--baseline" in OS.get_cmdline_user_args():
		await verify_ridges(authored)
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save remains byte-identical")
	var result:={"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("ROW_RIDGE ",JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(int(not failures.is_empty()))

func caps(id:String)->Array[StaticBody3D]:
	var result:Array[StaticBody3D]=[]
	for body:StaticBody3D in demo.town.house_roots[id].find_children("RowRidgePick_*","StaticBody3D",true,false):
		result.append(body)
	return result

func geometry(id:String)->Array:
	var result:Array=[]
	for body:StaticBody3D in caps(id):
		var collision:=body.get_child(0) as CollisionShape3D
		result.append(collision.shape.get_faces())
	return result

func verify_ridges(authored:Dictionary)->void:
	check(caps("h1").size()==7 and caps("h2").size()==4,"caps only follow the real gable ridge on both axes")
	var initial:=geometry("h1")
	var perpendicular:=geometry("h2")
	await physics_frame
	for id:String in ["h1","h2"]:
		for body:StaticBody3D in caps(id):
			if str(body.get_meta("cell_id"))!=str(demo.town._house_record(id).cells[1].id):continue
			var cell:Dictionary=body.get_meta("cell")
			var at:Vector3=demo.town._cell_position(demo.town._house_record(id),cell)+Vector3.UP*5.
			var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at,at+Vector3.DOWN*5.))
			check(hit.get("collider")==body,"ridge apex selects its original cell "+id)
			if hit.get("collider")==body:
				var candidate:=Unified.resolve(demo.state,hit,Vector2(at.x,at.z))
				check(candidate.valid and candidate.house_id==id and candidate.cell.level==1,"ridge pick targets an upper room "+id)
	check(demo.state.snapshot()==authored,"day and night leave the work snapshot intact")
	var city:RefCounted=demo.state
	var edit:Dictionary=city.add_cell("h1",0,-1,0)
	check(edit.ok,"extend the first row into a genuine L")
	demo._after_edit(edit,"room")
	await settle()
	check(caps("h1").is_empty() and geometry("h2")==perpendicular,"roof valley has no row cap and the other row is stable")
	await key(KEY_Z,true)
	await settle()
	check(geometry("h1")==initial and demo.state.houses==authored.houses,"Ctrl+Z restores the exact ridge and cells")
	var path:=OUT+"/works/row.json"
	DirAccess.make_dir_recursive_absolute(OUT+"/works")
	check(city.save_city(path).ok,"save the authored row to the isolated directory")
	var cold:=State.new()
	check(cold.load_city(path).ok,"independent city loads the saved row")
	await show(cold,Vector2(-24,-28),"沿街连屋冷读")
	check(geometry("h1")==initial and geometry("h2")==perpendicular,"cold publication reproduces both rows exactly")
