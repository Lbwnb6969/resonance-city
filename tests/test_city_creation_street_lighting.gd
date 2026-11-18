extends SceneTree
const Lighting=preload("res://scripts/visual/city_creation_street_lighting.gd")
const Instances=preload("res://scripts/visual/city_creation_safe_instances.gd")
class Lanterns:
	extends RefCounted
	var _lamp_rigs:Array[WeakRef]=[]
class Owner:
	extends Node3D
	var promenade:=Lanterns.new()
var checks:=0
var failures:Array=[]
var max_slew:=0.
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
func rig(owner:Owner,positions:Array[Vector3],label:String="LampHalos")->MultiMeshInstance3D:
	var group:=Node3D.new();owner.add_child(group);group.transform=Transform3D(Basis(Vector3.UP,.35),Vector3(4,.7,6))
	var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=QuadMesh.new();Instances.initialize(multi,positions.size())
	for at:Vector3 in positions:Instances.append(multi,Transform3D(Basis.IDENTITY,at))
	var node:=MultiMeshInstance3D.new();node.name=label;node.multimesh=multi;node.set_meta("lamp_positions",positions.duplicate());group.add_child(node);owner.promenade._lamp_rigs.append(weakref(node));return node
func active(lighting:Node3D)->Array:
	return lighting._slots.filter(func(s):return s.light.light_energy>.0001 and s.light.visible)
func positions(lighting:Node3D)->Array:
	var result:Array=active(lighting).map(func(s):return s.light.global_position);result.sort();return result
func near(a:Array,b:Array)->bool:
	if a.size()!=b.size():return false
	for i:int in range(a.size()):
		if a[i].distance_to(b[i])>.00001:return false
	return true
func settle_pool(lighting:Node3D,frames:int=60,monitor:bool=false)->bool:
	var bounded:=true
	for frame:int in range(frames):
		var old:Array=lighting._slots.map(func(s):return {"key":s.key,"energy":s.light.light_energy})
		lighting._process(1./60.);var keys:Dictionary={}
		for i:int in range(lighting._slots.size()):
			var slot:Dictionary=lighting._slots[i];max_slew=maxf(max_slew,absf(slot.light.light_energy-old[i].energy))
			if monitor and old[i].key!=slot.key and slot.light.light_energy>.0001:bounded=false
			if slot.light.light_energy>.0001:
				if keys.has(slot.key):bounded=false
				keys[slot.key]=true
		bounded=bounded and keys.size()<=lighting._slots.size()
	return bounded
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var owner:=Owner.new();root.add_child(owner);owner.position=Vector3(-.7,.2,.3)
	var points:Array[Vector3]=[]
	for i:int in range(24):points.append(Vector3(-22+i*2.25,1.86,2. if i%2==0 else -2.))
	var source:=rig(owner,points);var expected:Array=[]
	for point:Vector3 in points:expected.append(source.global_transform*point)
	var hidden:=rig(owner,[Vector3(0,1.86,0)]);hidden.get_parent().hide();rig(owner,[Vector3(0,1.86,0)],"LampPools")
	var lighting:=Lighting.new();owner.add_child(lighting);lighting.setup(owner);lighting.set_process(false)
	check(lighting._slots.size()==mini(8,int(ProjectSettings.get_setting("rendering/limits/opengl/max_lights_per_object",8))) and active(lighting).is_empty(),"real OmniLight pool respects configured GL limit and begins dark")
	lighting.set_view(Vector2(.31,3.7));lighting.set_phase(2);check(settle_pool(lighting),"initial fill never duplicates source or exceeds capacity")
	expected.sort_custom(func(a,b):return Vector2(a.x,a.z).distance_squared_to(lighting.focus)<Vector2(b.x,b.z).distance_squared_to(lighting.focus));var nearest:Array=expected.slice(0,lighting._slots.size());nearest.sort()
	check(near(positions(lighting),nearest),"only visible emitter rigs selected; correct world transform and nearest sources")
	check(active(lighting).all(func(s):return absf(s.light.light_energy-1.)<.0001 and not s.light.shadow_enabled),"night energy and chosen unshadowed mode")
	var before:=positions(lighting);lighting.set_view(Vector2(28,-3));max_slew=0.;check(settle_pool(lighting,90,true),"camera selection fades old source to zero before reassignment")
	check(max_slew<=5./60.+.000001 and positions(lighting)!=before,"energy changes are bounded and camera moves selection")
	lighting.set_phase(1);settle_pool(lighting);check(active(lighting).all(func(s):return absf(s.light.light_energy-.4)<.0001),"dusk is weaker than night")
	lighting.set_phase(0);check(active(lighting).is_empty() and lighting._slots.all(func(s):return s.light.light_energy==0.),"day transition immediately removes all local light")
	lighting.set_phase(2);settle_pool(lighting);var original:=positions(lighting);source.hide();lighting._process(0.)
	check(active(lighting).is_empty(),"hidden/removed published emitter cannot keep a ghost light")
	source.show();settle_pool(lighting);check(positions(lighting)==original,"revealing unchanged geometry restores exact emitters")
	source.get_parent().remove_child(source);lighting._process(0.);check(active(lighting).is_empty(),"detached emitter clears before end-of-frame deletion");source.queue_free();await process_frame
	var rebuilt:=rig(owner,points);settle_pool(lighting);check(positions(lighting)==original,"rebuilt source rigs restore exact cold selection")
	rig(owner,points);settle_pool(lighting);check(positions(lighting)==original and settle_pool(lighting),"coincident source rigs do not double physical light")
	owner.hide();lighting._process(0.);check(active(lighting).is_empty(),"hidden old city clears its complete pool immediately");owner.show();settle_pool(lighting);check(positions(lighting)==original,"same city resumes without altering emitters")
	check(rebuilt.is_inside_tree(),"only owned fixture nodes used; no author or save APIs")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"max_camera_energy_slew":max_slew,"seconds":(Time.get_ticks_msec()-began)/1000.,"scope":"headless real Node3D/MultiMesh/OmniLight resources with a minimal promenade owner; deterministic manual process; no city/personal-save writes"};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("STREET_LIGHTING ",JSON.stringify(report));owner.free();quit(0 if report.ok else 1)
