extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Roof=preload("res://scripts/world/city_creation_round_roof_geometry.gd")
const UV=preload("res://scripts/visual/city_creation_roof_coordinates.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
static func fixture()->RefCounted:
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.add_cell("h1",0,0,1);city.set_house_style("h1","round_tower");city.add_house(Vector2(-18,-20));return city
static func blocked_fixture()->RefCounted:
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.set_house_style("h1","round_tower");city.set_house_roof_pitch("h1",0.);city.add_house(Vector2(-18,-20));city.houses[1].origin=[-23.1,-20.];city.houses[1].base_y=2.;return city
func run()->void:
	var out:="";var baseline_path:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-round="):baseline_path=arg.trim_prefix("--baseline-round=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var city:=fixture();var house:Dictionary=city.houses[0];var original:Dictionary=city.snapshot();var center:=Vector3(-25,3.48,-20)
	if not baseline_path.is_empty():
		var old:RefCounted=load(baseline_path).new();check(Roof.vertices(center)==old.roof_vertices(center),"legacy roof skin retains every pre-feature vertex bit")
	check(Pitch.supported(city,house) and not Pitch.Round.for_house(house,city.houses,city.roads).is_empty(),"real original round column is eligible")
	var heights:Array=[]
	for angle:float in [0.,15.,45.,78.]:
		var before:Dictionary=city.snapshot();var depth:int=city._undo.size();var result:Dictionary=city.set_house_roof_pitch("h1",angle);var plan:Dictionary=Pitch.Round.for_house(city.houses[0],city.houses,city.roads)
		check(result.ok and plan.cells==house.cells and city.houses[1]==original.houses[1] and city.houses[0].seed==original.houses[0].seed and city._undo.size()==depth+1,"round angle is one transaction preserving body author data "+str(angle))
		check(absf(float(plan.roof_height)-tan(deg_to_rad(angle))*Roof.RADIUS)<.00001,"real round height follows actual slope "+str(angle))
		var faces:=Roof.vertices(center,city.houses[0]);var coordinates:=UV.build(faces,center,true);var good:=true;var low:=INF;var high:=-INF;var area:=0.
		for i in range(0,faces.size(),3):
			var n:Vector3=(faces[i+1]-faces[i]).cross(faces[i+2]-faces[i]);good=good and n.length()>.0000001 and n.y>0.;area+=n.length()*.5
			var chart:float=absf((coordinates[i+1]-coordinates[i]).cross(coordinates[i+2]-coordinates[i]));good=good and chart>.00000001
			for j in range(3):low=minf(low,faces[i+j].y);high=maxf(high,faces[i+j].y);good=good and faces[i+j].is_finite() and coordinates[i+j].is_finite()
		check(good and coordinates.size()==faces.size() and faces.size()==1776 and high>=low and (angle!=0. or high==low),"complete finite nondegenerate round skin and metric UV including flat cap "+str(angle));heights.append(high)
		var cold:=State.new();check(cold.restore(city.snapshot()).ok and Pitch.Round.for_house(cold.houses[0],cold.houses,cold.roads)==plan,"cold round recipe restores exact physical plan "+str(angle))
		check(city.undo().ok and city.houses==before.houses and city.redo().ok and Pitch.Round.for_house(city.houses[0],city.houses,city.roads)==plan,"Undo/Redo restore exact original and pitched round plans "+str(angle))
	check(heights[-1]-heights[0]>4.9,"pointed round roof truly rises almost five metres")
	var file:=out+"/round.json";var cold:=State.new();check(city.snapshot().schema==36 and city.save_city(file).ok and cold.load_city(file).ok and cold.houses==city.houses,"schema36 round recipe survives actual disk I/O")
	var before:Dictionary=city.snapshot();city.set_house_roof_pitch("h1",null);check(not city.houses[0].has("roof_pitch") and Roof.vertices(center,city.houses[0])==Roof.vertices(center),"original roof restores exact legacy curved skin")
	# Equal apex heights still need distinct cache identities for curved versus straight skins.
	var legacy:Dictionary=Pitch.Round.for_house(city.houses[0],city.houses,city.roads);city.set_house_roof_pitch("h1",rad_to_deg(atan(Roof.LEGACY_HEIGHT/Roof.RADIUS)))
	check(Pitch.Round.for_house(city.houses[0],city.houses,city.roads).signature!=legacy.signature,"equal-height new skin invalidates the actual round geometry cache")
	var blocked:=blocked_fixture();var snapshot:Dictionary=blocked.snapshot();var depth:int=blocked._undo.size()
	check(State.new().restore(snapshot).ok,"clearance fixture is an actually valid restorable city")
	check(Pitch.supported(blocked,blocked.houses[0]) and not blocked.set_house_roof_pitch("h1",78.).ok and blocked.snapshot()==snapshot and blocked._undo.size()==depth,"roof cannot switch round body to square when desired slope hits elevated neighbour")
	var flat:=fixture();flat.houses[0].cells.resize(1);flat.set_house_roof_pitch("h1",0.);var h:Dictionary=flat.houses[0];var plan:Dictionary=Pitch.Round.for_house(h,flat.houses,flat.roads)
	check(Pitch.blocks(flat,h,Vector2(-27,-20),Vector2(-23,-20),float(plan.roof_top_y)+.20,.04),"wind vane above flat cap participates in real clearance")
	flat.set_house_role("h1","bakery");check(Pitch.blocks(flat,flat.houses[0],Vector2(-25+.25,-20.3),Vector2(-25+.62,-20.3),float(plan.roof_top_y)+.40,.02),"bakery stack above flat cap participates in real clearance")
	check(not Pitch.blocks(flat,flat.houses[0],Vector2(-25.7,-22),Vector2(-25.7,-18),float(plan.roof_top_y)+.25,.01),"clear side corridor is not blocked by distant centre crown")
	var historical:=fixture();historical.houses[0].roof_pitch={"version":1,"degrees":78.};var old_snapshot:Dictionary=historical.snapshot();var legacy_plan:=Pitch.Round.for_house(historical.houses[0],historical.houses,historical.roads)
	check(old_snapshot.schema==35 and not Roof.authored(historical.houses[0]) and not Pitch.active(historical,historical.houses[0]) and is_equal_approx(legacy_plan.roof_height,Roof.LEGACY_HEIGHT),"schema35 dormant ordinary slope on round style keeps legacy curved roof")
	var restored:=State.new();check(restored.restore(old_snapshot).ok and restored.snapshot()==old_snapshot and Pitch.Round.for_house(restored.houses[0],restored.houses,restored.roads)==legacy_plan,"old dormant recipe cold reads without silently activating a new round roof")
	check(historical.set_house_roof_pitch("h1",45.).ok and historical.snapshot().schema==36 and historical.houses[0].roof_pitch.version==2 and historical.undo().ok and historical.houses==old_snapshot.houses,"explicit author edit alone upgrades round recipe and Undo restores dormant old choice")
	var invalid:Dictionary=city.snapshot().duplicate(true);invalid.schema=35;check(not restored.restore(invalid).ok,"schema35 cannot accept new round-profile recipe")
	invalid=city.snapshot().duplicate(true);invalid.houses[0].roof_pitch.profile="unknown";check(not restored.restore(invalid).ok,"unknown round profile is rejected before changing city")
	invalid=city.snapshot().duplicate(true);invalid.houses[0].roof_pitch.extra=true;check(not restored.restore(invalid).ok,"new round recipe rejects extra fields")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"tops":heights};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROUND_ROOF_PITCH_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
