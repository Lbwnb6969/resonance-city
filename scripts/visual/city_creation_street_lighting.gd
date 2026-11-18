extends Node3D
## Real lantern sources share a bounded light pool; author data stays untouched.
const RANGE:=4.
const REFRESH:=.1
var focus:=Vector2.ZERO
var phase:=0
var _renderer
var _slots:Array=[]
var _desired:Array=[]
var _clock:=0.
func setup(renderer)->void:_renderer=renderer
func _ready()->void:
	name="StreetLighting"
	var capacity:=mini(8,int(ProjectSettings.get_setting("rendering/limits/opengl/max_lights_per_object",8)))
	for i:int in range(capacity):
		var light:=OmniLight3D.new();light.name="LanternLight_"+str(i);light.light_color=Color("ffc889");light.omni_range=RANGE;light.omni_attenuation=1.;light.shadow_enabled=false;light.light_energy=0.;light.hide();add_child(light)
		_slots.append({"light":light,"key":null,"source":null})
func set_view(point:Vector2)->void:focus=point
func set_phase(value:int)->void:
	phase=value;_clock=0.
	if phase==0:_dark()
func _live(reference:WeakRef)->bool:
	var node:Node3D=reference.get_ref()
	return node!=null and node.is_inside_tree() and node.is_visible_in_tree()
func _dark()->void:
	_desired.clear()
	for slot:Dictionary in _slots:slot.light.light_energy=0.;slot.light.hide();slot.key=null;slot.source=null
func _select()->void:
	_desired=[];var seen:Dictionary={}
	for reference:WeakRef in _renderer.promenade._lamp_rigs:
		if not _live(reference):continue
		var node:MultiMeshInstance3D=reference.get_ref()
		if node.name!="LampHalos":continue
		for point:Vector3 in node.get_meta("lamp_positions"):
			var at:Vector3=node.global_transform*point
			var key:=Vector3i((at*10000.).round())
			if seen.has(key):continue
			seen[key]=true
			var distance:float=focus.distance_squared_to(Vector2(at.x,at.z));var tie:=str(key);var index:=0
			while index<_desired.size() and (_desired[index].distance<distance or (_desired[index].distance==distance and _desired[index].tie<tie)):index+=1
			if index>=_slots.size():continue
			_desired.insert(index,{"key":key,"source":reference,"at":at,"distance":distance,"tie":tie})
			if _desired.size()>_slots.size():_desired.pop_back()
func _process(delta:float)->void:
	if phase==0 or not is_visible_in_tree():_dark();return
	_clock-=delta
	if _clock<=0.:_clock=REFRESH;_select()
	var wanted:Dictionary={};var occupied:Dictionary={}
	for source:Dictionary in _desired:
		if _live(source.source):wanted[source.key]=source
	for slot:Dictionary in _slots:
		if slot.source!=null and not _live(slot.source):slot.light.light_energy=0.;slot.light.hide();slot.key=null;slot.source=null
		if slot.key!=null:occupied[slot.key]=true
	var energy:=1. if phase==2 else .4
	for slot:Dictionary in _slots:
		var light:OmniLight3D=slot.light;var target:float=energy if wanted.has(slot.key) else 0.
		light.light_energy=move_toward(light.light_energy,target,delta*5.)
		if light.light_energy>.0001:light.show();continue
		light.hide()
		if slot.key!=null:occupied.erase(slot.key)
		slot.key=null;slot.source=null
		for source:Dictionary in _desired:
			if occupied.has(source.key) or not wanted.has(source.key):continue
			slot.key=source.key;slot.source=source.source;light.global_position=source.at;occupied[source.key]=true;break
