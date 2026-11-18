extends "res://tests/test_city_creation_modern_roof_pitch.gd"
const Details=preload("res://scripts/world/city_creation_modern_roof_details.gd")
const Choice=preload("res://scripts/world/city_creation_architecture_variants.gd")
func worker(source:Dictionary)->Dictionary:
	var city:=State.new();var restored:Dictionary=city.restore(source)
	return {"ok":restored.ok,"plan":Details.plan(city,city.houses[0]),"patches":Pitch.patches(city,city.houses[0]),"source":city.snapshot()}
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var started:=Time.get_ticks_usec();var rows:Array=[]
	for turned:bool in [false,true]:
		var city:=fixture("recessed_townhouse");city.add_cell("h1",1,0,0);city.add_cell("h1",1,0,1)
		if turned:city.houses[0].base_y=1.25;city.rotate_house("h1",.35)
		city.set_house_dormer("h1","gable_light");city.set_house_chimney("h1","brick_twin_pots");city.set_house_architecture_variant("h1","stone_dentils","gable_trim")
		var chosen:Dictionary=city.houses[0].architecture_variant.duplicate(true)
		for angle:float in [0.,15.,45.,78.,0.]:
			city.set_house_roof_pitch("h1",angle);var source:Dictionary=city.snapshot();var start:=Time.get_ticks_usec();var plan:=Details.plan(city,city.houses[0]);rows.append({"angle":angle,"turned_raised":turned,"plan_ms":(Time.get_ticks_usec()-start)/1000.})
			var label:=str(angle)+"/"+str(turned);check(plan.details.size()==3 and city.houses[0].architecture_variant==chosen and city.snapshot()==source,"all selected slots preserve author data "+label)
			var thread:=Thread.new();var error:=thread.start(worker.bind(source));var result:Dictionary=thread.wait_to_finish() if error==OK else {}
			check(error==OK and result.get("ok",false) and result.plan==plan and result.patches==Pitch.patches(city,city.houses[0]) and result.source==source,"real background worker and main CPU geometry exactly agree "+label)
			var chimney:Array=plan.details.filter(func(item):return item.slot=="chimney_detail");var dormer:Array=plan.details.filter(func(item):return item.slot=="roof_detail")
			if angle==0.:check(chimney[0].active and dormer[0].active,"lowering roof reactivates original dormer and chimney "+label)
			if angle==78.:check(not chimney[0].active and not dormer[0].active,"extreme slope retains dormant details without stretched geometry "+label)
			if chimney[0].active and dormer[0].active:check(not Rect2(chimney[0].site.footprint).intersects(dormer[0].site.footprint),"shared occupancy keeps chimney and dormer sites separate "+label)
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.,"cases":rows};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("MODERN_DETAILS_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
