extends SceneTree
const Arc=preload("res://scripts/world/city_creation_road_center_arc.gd")
const State=preload("res://scripts/world/city_creation_state.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func radial(row:Dictionary,a:Vector2,c:Vector2)->bool:
	for p:Vector2 in row.points:
		if absf(p.distance_to(c)-a.distance_to(c))>.00003:return false
	return row.points[0]==a
func _initialize()->void:run.call_deferred()
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var city:=State.new();city.initialize_free();var before:=city.snapshot();var a:=Vector2(-22,-24);var c:=Vector2(-22,-20)
	for sign_side:float in [-1.,1.]:
		var previous:=0.
		for degrees:float in [30.,90.,150.,210.,270.,330.,360.]:
			var target:Vector2=c+(a-c).rotated(deg_to_rad(degrees*sign_side))*1.4
			var row:=Arc.plan(city,a,c,target,previous,false,1.25,"path","");previous=row.turn
			check(radial(row,a,c) and absf(row.turn-deg_to_rad(degrees*sign_side))<.00001,"fixed actual centre and radius including major arc "+str(sign_side*degrees))
			check(row.valid.ok and row.points.size()>5,"actual site validation and complete road points "+str(sign_side*degrees))
	var paused:=Arc.plan(city,a,Vector2.INF,c,0.,true,1.25,"path","")
	check(paused.points==[a] and not paused.valid.ok,"centre selection shows radius guide without promising a straight road")
	var snapped:=Arc.plan(city,a,c,c+(a-c).rotated(deg_to_rad(89.)),PI*.5,true,1.25,"path","")
	check(absf(rad_to_deg(snapped.turn)-90.)<.00001 and radial(snapped,a,c),"angle snap preserves exact centre and radius")
	var free:=Arc.plan(city,a,c,c+(a-c).rotated(deg_to_rad(89.)),PI*.5,false,1.25,"path","")
	check(absf(rad_to_deg(free.turn)-89.)<.0001,"Alt keeps continuous sweep")
	check(city.snapshot()==before,"all circle planning leaves source and history unchanged")
	var road:Array[Vector2]=[Vector2(-30,-20),Vector2(-14,-20)];check(city.add_road(road,"path","none",1.25).ok,"real intersecting road authored")
	var hit:=Arc.plan(city,a,c,Vector2(-17.7,-20.4),1.5,true,1.25,"path","")
	check(not hit.closure.is_empty() and Vector2(hit.end).distance_to(Vector2(-18,-20))<.00001 and radial(hit,a,c),"road assistance uses exact circle/segment intersection")
	var inside:=State.new();inside.initialize_free();var short:Array[Vector2]=[Vector2(-19,-20),Vector2(-19,-19)];inside.add_road(short,"path","none",1.25)
	var dooroff:=Arc.endpoint(inside,Vector2(-19,-20),a,c,4.,1.5)
	check(dooroff.is_empty(),"off-circle target cannot warp fixed radius")
	var clipped:=State.new();clipped.initialize_free();var crossing:Array[Vector2]=[Vector2(-19,-20),Vector2(-14,-20)];clipped.add_road(crossing,"path","none",1.25)
	var from_endpoint:=Arc.plan(clipped,a,c,Vector2(-17.7,-20.4),1.5,true,1.25,"path","")
	check(from_endpoint.closure.get("kind","")=="segment" and Vector2(from_endpoint.end).distance_to(Vector2(-18,-20))<.00001 and radial(from_endpoint,a,c),"off-circle endpoint priority still finds actual intersection on its segment")
	var doors:=State.new();doors.initialize_free();doors.add_house(Vector2(-25,-10));var entry:Dictionary=doors.house_entrances(str(doors.houses[0].id))[0]
	var normal:Vector2=entry.outward;var contact:Vector2=entry.wall_at+normal*Arc.Targets.Frontage.CONTACT
	var dc:Vector2=contact+normal.rotated(PI*.5)*4.;var da:Vector2=dc+normal*4.
	var approach:=Arc.plan(doors,da,dc,contact,-PI*.5,true,1.25,"path","")
	check(approach.closure.get("kind","")=="door" and approach.valid.ok and radial(approach,da,dc),"true circular tangent approaches real door from outside")
	var rear:=Arc.plan(doors,dc-normal*4.,dc,contact,PI*.5,true,1.25,"path","")
	check(rear.closure.is_empty(),"reverse tangent from wall side cannot claim a door connection")
	var loop:=Arc.plan(city,a,c,a+Vector2(.05,0),5.9,true,1.25,"path","")
	check(loop.closure.get("self",false) and loop.points[0]==loop.points[-1] and radial(loop,a,c) and is_equal_approx(loop.turn,TAU),"full swept circle closes exactly without deforming the boundary")
	var saved:=city.snapshot();var result:Dictionary=city.add_road(hit.points,"path","none",1.25)
	check(result.ok,"actual circular path commits through existing transaction")
	check(city.undo().ok and city.roads==saved.roads,"one Undo preserves earlier road")
	var cold:=State.new();city.redo();check(cold.restore(city.snapshot()).ok and cold.roads==city.roads,"cold restore keeps actual old and new point lists")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("CENTER_ARC_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
