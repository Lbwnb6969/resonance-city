extends "res://tools/check_creation_modern_roof_pitch_live.gd"
const Details=preload("res://scripts/world/city_creation_modern_roof_details.gd")
const Bridge=preload("res://scripts/world/city_creation_skybridge_plan.gd")
const DeckFixture=preload("res://tests/test_city_creation_tea_deck.gd")
const Deck=DeckFixture.Deck
func same_triangles(actual:Array,expected:Array)->bool:
	if actual.size()!=expected.size():return false
	var remaining:Array=[]
	for i in range(0,expected.size(),3):remaining.append([expected[i],expected[i+1],expected[i+2]])
	for i in range(0,actual.size(),3):
		var triangle:Array=[actual[i],actual[i+1],actual[i+2]];var found:=-1
		for index in range(remaining.size()):
			var candidate:Array=remaining[index]
			if not candidate.any(func(point):return Vector3(triangle[0]).distance_to(point)<.00015):continue
			if triangle.all(func(point):return candidate.any(func(other):return Vector3(point).distance_to(other)<.00015)):
				found=index;break
		if found<0:
			var best:=INF;var nearest:Array=[]
			for candidate:Array in remaining:
				var distance:=0.
				for point:Vector3 in triangle:
					var closest:=INF
					for other:Vector3 in candidate:closest=minf(closest,point.distance_to(other))
					distance=maxf(distance,closest)
				if distance<best:best=distance;nearest=candidate
			facts["geometry_mismatch_"+str(facts.size())]={"distance":best,"actual":triangle,"expected":nearest};return false
		for point:Vector3 in triangle:
			var error:=INF
			for other:Vector3 in remaining[found]:error=minf(error,point.distance_to(other))
			facts.max_detail_vertex_error=maxf(float(facts.get("max_detail_vertex_error",0.)),error)
		remaining.remove_at(found)
	return remaining.is_empty()
func detail_keys(renderer,slot:String)->Array:
	var points:Array=[];var house:Node3D=renderer.house_roots.h1;var inverse:=house.global_transform.affine_inverse()
	for body:StaticBody3D in house.find_children("ModernDetailPick*","StaticBody3D",true,false):
		if not body.has_meta(slot):continue
		for shape:CollisionShape3D in body.get_children():
			for point:Vector3 in shape.shape.get_faces():points.append(inverse*shape.global_transform*point)
	return points
func verify_details(label:String)->void:
	var h:Dictionary=demo.state.houses[0];var source:Dictionary=demo.state.snapshot();var plan:=Details.plan(demo.state,h);var root_node:Node3D=demo.town.house_roots.h1
	for item:Dictionary in plan.details:
		var points:Array=[]
		for patch:Dictionary in plan.patches:
			if patch.detail==item.slot:points.append_array(patch.vertices)
		var actual:=detail_keys(demo.town,item.slot)
		check(same_triangles(actual,points),"CPU detail triangles equal actual transformed picking geometry within 0.15mm "+label+"/"+str(item.slot))
		var metadata:Dictionary=root_node.get_meta(item.slot,{})
		check(metadata.get("active",false)==item.active and metadata.get("id")==item.id,"published detail metadata follows shared site "+label+"/"+str(item.slot))
		if item.slot=="chimney_detail":check(root_node.get_meta("chimneys",[])==item.outlets,"smoke outlets follow same CPU chimney plan "+label)
	check(demo.state.snapshot()==source,"detail CPU/render reads preserve all author data "+label)
	var cold:=State.new();var file:=OUT+"/cold_"+label+".json";check(demo.state.save_city(file).ok and cold.load_city(file).ok and Details.plan(cold,cold.houses[0])==plan,"disk schema38 cold read reproduces exact detail plan "+label)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);demo=Scene.instantiate();demo.persistence=false;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control")
	if "--water-deck-only" in OS.get_cmdline_user_args():await water_deck_case();await modern_report(personal);return
	for pair:Array in [["gable_light","brick_twin_pots","timber_verge"],["shed_light","copper_cowl","stone_dentils"],["off","off","timber_verge"]]:
		var city:=Fixture.fixture("recessed_townhouse");city.add_cell("h1",1,0,0);city.add_cell("h1",1,0,1)
		check(city.set_house_dormer("h1",pair[0]).ok and city.set_house_chimney("h1",pair[1]).ok and city.set_house_architecture_variant("h1",pair[2],"gable_trim").ok,"existing three authored slots remain available "+str(pair))
		var choices:Dictionary=city.houses[0].architecture_variant.duplicate(true);var rooms:Array=city.houses[0].cells.duplicate(true)
		for angle:float in [0.,15.,45.,78.]:
			check(city.set_house_roof_pitch("h1",angle).ok,"real modern deep-window author edit "+str(angle));await show(city,Vector2(-25,-20),"现代深窗与手选细部");await settle();quiet()
			var label:=str(pair[0])+"_"+str(int(angle));verify_details(label)
			check(demo.state.houses[0].architecture_variant==choices and demo.state.houses[0].cells==rooms,"slope retains selected recipes and every author room "+label)
			facts[label]=demo.town.house_roots.h1.get_meta("chimney_detail",{})
			if angle==0. and pair[0]!="off":check(demo.town.house_roots.h1.get_meta("roof_detail",{}).get("active",false) and demo.town.house_roots.h1.get_meta("chimney_detail",{}).get("active",false),"flat roof supports combined dormer and chimney "+label)
			if angle in [0.,78.]:await capture(label)
	# Reproduce the original horizontal ray and compare true hollow pot interior.
	var city:=Fixture.fixture("recessed_townhouse");city.set_house_chimney("h1","brick_twin_pots");city.set_house_roof_pitch("h1",0.);await show(city,Vector2(-25,-20),"烟囱实际净空");await settle();quiet()
	var info:Dictionary=demo.town.house_roots.h1.get_meta("chimney_detail");var site:Dictionary=info.site;var a:=Vector2(site.at.x-.4,site.at.y);var b:=Vector2(site.at.x+.4,site.at.y);var y:float=site.high+.35
	var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(a.x,y,a.y),Vector3(b.x,y,b.y)))
	check(not hit.is_empty() and hit.collider.get_meta("chimney_detail","")=="brick_twin_pots" and Pitch.blocks(demo.state,demo.state.houses[0],a,b,y,.02),"reproduced visible chimney corridor now blocked by both physics and CPU")
	var outlet:Vector3=info.outlets[0];hit=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(outlet+Vector3.UP*.08,outlet-Vector3.UP*.18))
	check(hit.is_empty() and not Pitch.blocks(demo.state,demo.state.houses[0],Vector2(outlet.x-.008,outlet.z),Vector2(outlet.x+.008,outlet.z),outlet.y-.08,.008),"hollow pot throat stays open in both real collision and CPU clearance")
	var signature:=Bridge.adjacency_signature(demo.state,demo.state.houses[0]);var change:Dictionary=demo.state.set_house_chimney("h1","copper_cowl")
	check(change.ok and Bridge.adjacency_signature(demo.state,demo.state.houses[0])!=signature,"detail selection invalidates neighbouring bridge adjacency signature")
	demo._after_edit(change,"room",true,"h1");await settle();quiet();verify_details("incremental_copper");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses[0].architecture_variant.slots.chimney.id=="brick_twin_pots","one native Undo restores exact chimney choice");verify_details("undo_twin")
	await detail_bridge_case()
	# Native roof preview/publication on both special facades; cold renderer and history.
	for kind:String in ["recessed_townhouse","cantilever_tea_deck"]:
		city=Fixture.fixture(kind)
		if kind=="recessed_townhouse":city.add_cell("h1",1,0,0);city.add_cell("h1",1,0,1);city.set_house_dormer("h1","gable_light");city.set_house_chimney("h1","copper_cowl");city.set_house_architecture_variant("h1","timber_verge","gable_trim")
		await show(city,Vector2(-25,-20),kind);await settle();quiet();var original:Dictionary=demo.state.snapshot();var body:=body_physics(demo.town)
		for angle:float in [0.,45.,78.]:
			await open_editor();var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();await drag_slider(angle,false)
			check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-angle)<.2,18000),"special-form native preview ready "+kind+str(angle))
			if control.current==null:await modern_report(personal);return
			check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"special-form preview is author/history pure "+kind+str(angle));var expected:=construction(control.current.renderer);await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
			check(construction(demo.town)==expected and body_physics(demo.town)==body,"special facade preview/publish GPU transforms match and lower collisions remain "+kind+str(angle));verify_details(kind+str(int(angle)))
			check(demo.state._undo.size()==depth+1 and demo.state.houses[0].cells==original.houses[0].cells,"one roof gesture preserves actual special rooms "+kind+str(angle));await capture(kind+str(int(angle)))
			var cold:=State.new();cold.restore(demo.state.snapshot());var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
			while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
			check(preview.ready and construction(preview.renderer)==construction(demo.town),"independent cold production geometry equals published special form "+kind+str(angle));preview.clear()
			await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"native Undo restores whole special house "+kind+str(angle));await key(KEY_Y,true);await settle();quiet()
		await open_editor();before_cancel=demo.state.snapshot();await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);await key(KEY_ESCAPE);await release_slider();check(demo.state.snapshot()==before_cancel and control.current==null,"Escape retracts special roof/detail preview "+kind)
	await modern_report(personal)
var before_cancel:Dictionary
func detail_bridge_case()->void:
	var city:=Fixture.fixture("recessed_townhouse");city.set_house_roof_pitch("h1",0.)
	for at:Vector2 in [Vector2(-30,-20),Vector2(-21.5,-20)]:city.add_house(at)
	for id:String in ["h2","h3"]:city.houses[city._house_index(id)].base_y=.2;city.set_house_era(id,"modern_eco");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
	city.set_house_skybridge_span("h3",true);await show(city,Vector2(-25,-20),"手选烟囱与真实九米云廊");await settle();quiet()
	var before:Dictionary=demo.state.snapshot();check(not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"actual long cloud bridge clears low flat deep-window roof")
	var change:Dictionary=demo.state.set_house_chimney("h1","brick_twin_pots");demo._after_edit(change,"room",true,"h1");await settle();quiet()
	check(demo.town.house_roots.h1.get_meta("chimney_detail",{}).get("active",false) and demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"incremental detail edit retracts physically obstructed neighbour cloud bridge")
	check(demo.state.houses[2].skybridge_span==before.houses[2].skybridge_span,"blocked cloud bridge retains nine-metre author choice");await capture("chimney_blocks_actual_cloud_bridge")
	await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"one native Undo restores original chimney and real cloud bridge")
func deck_shapes()->Array:
	var result:Array=[];var house:Node3D=demo.town.house_roots.h1;var node:Node3D=house.find_child("CantileverTeaDeck",true,false)
	if node==null:return result
	for body:StaticBody3D in node.find_children("*","StaticBody3D",true,false):
		for shape:CollisionShape3D in body.get_children():result.append([shape.shape.size,shape.transform,body.transform,node.transform])
	return result
func water_deck_case()->void:
	var city:=DeckFixture.fixture();city.add_cell("h1",0,0,1);await show(city,Vector2(-28,-20),"真实亲水茶台调坡");await settle();quiet()
	var physical:=deck_shapes();var original:Dictionary=demo.state.snapshot();var planned:Dictionary=Deck.find(demo.state,"h1").duplicate(true)
	check(not physical.is_empty() and not planned.is_empty(),"actual authored pond publishes real cantilever boards and rails before slope edit")
	for angle:float in [0.,45.,78.]:
		await open_editor();var before:Dictionary=demo.state.snapshot();await drag_slider(angle,false)
		check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-angle)<.2,18000),"water-facing native roof preview completes "+str(angle))
		if control.current==null:return
		var expected:=construction(control.current.renderer);check(demo.state.snapshot()==before,"water-facing roof preview preserves author pond and rooms "+str(angle));await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
		check(construction(demo.town)==expected,"actual water-facing deck and pitched roof preview/publish buffers agree "+str(angle))
		check(deck_shapes()==physical and Deck.find(demo.state,"h1")==planned and demo.state.waters==original.waters and demo.state.houses[0].cells==original.houses[0].cells,"actual deck/guard transforms and all authored water/rooms remain unchanged "+str(angle))
		await physics_frame;var p:=Deck.at(planned,Vector2(.2,1.17));var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x,planned.top+.3,p.y),Vector3(p.x,planned.top-.15,p.y)))
		check(not hit.is_empty() and hit.collider.get_meta("tea_deck",false) and absf(hit.position.y-planned.top)<.002,"actual cantilever slab still supports walking at exact planned height "+str(angle))
		p=Deck.at(planned,Vector2(planned.wing*1.25,1.17));hit=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x,planned.top+.3,p.y),Vector3(p.x,planned.top-.15,p.y)))
		check(hit.is_empty(),"actual L-shaped deck leaves adjacent water open "+str(angle))
		var a:=Deck.at(planned,Vector2(.5,1.55));var b:=Deck.at(planned,Vector2(.5,1.18));hit=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(a.x,planned.top+.4,a.y),Vector3(b.x,planned.top+.4,b.y)))
		check(not hit.is_empty() and hit.collider.get_meta("tea_deck",false),"actual glass guard retains physical protection "+str(angle))
		var cold:=State.new();cold.restore(demo.state.snapshot());var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
		while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
		check(preview.ready and construction(preview.renderer)==construction(demo.town),"independent cold renderer retains exact actual water-facing construction "+str(angle));preview.clear();await capture("water_deck_"+str(int(angle)))
		await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and deck_shapes()==physical,"one native Undo restores roof while retaining real water deck "+str(angle));await key(KEY_Y,true);await settle();quiet()
	await open_editor();var before:Dictionary=demo.state.snapshot();await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);await key(KEY_ESCAPE);await release_slider();check(control.current==null and demo.state.snapshot()==before and deck_shapes()==physical,"Escape retracts water-facing roof preview without changing real deck or pond")
