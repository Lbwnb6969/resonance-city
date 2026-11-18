extends Node
## A detached production renderer previews the same authored roof as publication.
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
const Fork=preload("res://scripts/world/city_creation_chemistry_preview.gd")
const Preview=preload("res://scripts/visual/city_creation_batch_preview.gd")
var pop:RefCounted
var row:VBoxContainer
var slider:HSlider
var label:Label
var handle:Button
var reset:Button
var city:RefCounted
var target:=""
var epoch:Array=[]
var desired:=-1.
var prepared:=-1.
var dragging:=false
var releasing:=false
var committing:=false
var gesture_y:=0.
var gesture_pitch:=0.
var pending:RefCounted
var current:RefCounted
var backup:Dictionary={}
var holding:Array=[]
var support_key:Array=[]
var supported:=false
func setup(owner:RefCounted,parent:Control)->void:
	pop=owner;pop.demo.add_child(self);pop.demo.set_meta("roof_pitch_control",self)
	row=VBoxContainer.new();row.name="RoofPitchChoices";parent.add_child(row)
	var line:=HBoxContainer.new();row.add_child(line);label=Label.new();label.text="屋顶坡度";label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(label)
	reset=Button.new();reset.name="RoofPitchOriginal";reset.text="原顶";reset.pressed.connect(_reset);line.add_child(reset)
	slider=HSlider.new();slider.name="RoofPitchSlider";slider.min_value=0.;slider.max_value=78.;slider.step=.1;slider.custom_minimum_size=Vector2(220,26);row.add_child(slider)
	slider.drag_started.connect(func():_begin();releasing=false);slider.drag_ended.connect(func(_changed:bool):_release());slider.value_changed.connect(_value)
	var note:=Label.new();note.text="拖屋顶上的 ↕ 调坡，或用滑杆；0°平顶，角度越大越陡。";note.add_theme_font_size_override("font_size",12);row.add_child(note)
	handle=Button.new();handle.name="RoofPitchHandle";handle.text="↕";handle.tooltip_text="上下拖动调屋顶坡度 · 松手一笔提交 · Esc取消";handle.custom_minimum_size=Vector2(32,32);pop.overlay.add_child(handle);handle.gui_input.connect(_handle_input);handle.hide();row.hide()
func _house()->Dictionary:return pop.demo.town._house_record(pop.target_house_id)
func _initial_angle(h:Dictionary)->float:
	if Pitch.applies(h,pop.demo.state):return float(h[Pitch.FIELD].degrees)
	var root:Node3D=pop.demo.town.house_roots.get(str(h.id));var temple:Dictionary=root.get_meta("ancient_temple",{}) if root!=null else {}
	if not temple.is_empty():var half:float=temple.width*.5+.13;return rad_to_deg(atan(minf(.68,half*.38)/half))
	if root!=null and root.has_meta("round_tower"):
		var plan:Dictionary=root.get_meta("round_tower");return rad_to_deg(atan((float(plan.roof_top_y)-float(plan.eave_y))/float(plan.get("roof_radius",1.06))))
	if Pitch.guildhall(h,pop.demo.state):return Pitch.Guildhall.source_angle(pop.demo.state,h)
	if Pitch.portico(h,pop.demo.state):return Pitch.Portico.source_angle(pop.demo.state,h)
	if Pitch.basilica(h,pop.demo.state):return Pitch.Basilica.source_angle(pop.demo.state,h)
	if Pitch.stoa(h,pop.demo.state):return Pitch.Stoa.source_angle(pop.demo.state,h)
	if Pitch.acoustic(h,pop.demo.state):return Pitch.Acoustic.source_angle(pop.demo.state,h)
	if Pitch.boathouse(h,pop.demo.state):return 29.
	if Pitch.modern(h,pop.demo.state):return Pitch.Modern.source_angle(h)
	if Pitch.clockwork(h,pop.demo.state):return Pitch.Clockwork.source_angle(h)
	if Pitch.renaissance_special(h,pop.demo.state):return Pitch.Renaissance.source_angle(h)
	return 29.
func _begin()->void:
	if committing or dragging or pop.demo.edit_pending() or pop.demo.save_blocked:return
	var h:=_house()
	if h.is_empty() or not Pitch.supported(pop.demo.state,h):return
	cancel();city=pop.demo.state;target=str(h.id);epoch=[city.revision,city._wish_epoch];dragging=true;desired=float(slider.value);prepared=-1.
func _value(value:float)->void:
	if not dragging and not committing:
		_begin()
		if dragging:releasing=true
	if dragging:desired=value;label.text="屋顶坡度 %.1f°"%value
func _release()->void:
	if dragging:releasing=true
func cancel()->void:
	if pending!=null:pending.clear()
	if current!=null:current.clear()
	pending=null;current=null;dragging=false;releasing=false;city=null;target="";epoch=[];prepared=-1.;holding=[]
func _valid()->bool:return city==pop.demo.state and epoch==[city.revision,city._wish_epoch] and target==pop.target_house_id and pop.card.is_visible_in_tree() and pop.demo.tool in [0,4] and not pop.demo.gallery.busy and not pop.demo.gallery.panel.visible and pop.demo.ui_layer.visible
func _preview()->void:
	var checked:=Pitch.check_value(city,city.houses[city._house_index(target)],desired)
	if not checked.ok:
		if current!=null:current.clear();current=null
		prepared=desired;label.text=str(checked.message);handle.modulate=Color("cb7458");return
	handle.modulate=Color.WHITE
	var draft:RefCounted=Fork.fork(city);var i:int=city._house_index(target);draft.houses[i]=city.houses[i].duplicate(true);draft.houses[i][Pitch.FIELD]=Pitch.recipe(draft.houses[i],desired,draft)
	var before:RefCounted=pop.demo.town.building_context;var after:=Pitch.Context.new();after.copy_cache_from(before);after.prepare(draft.houses,draft.roads,draft);var ids:Array=[]
	var influence:Rect2=Pitch.Frame.house_bounds(draft.houses[i]).grow(10.)
	for h:Dictionary in draft.houses:
		var bridge_changed:bool=draft.house_era(h)=="modern_eco" and influence.intersects(Pitch.Frame.house_bounds(h),true) and Fork.Skybridge.adjacency_signature(city,h)!=Fork.Skybridge.adjacency_signature(draft,h)
		var round_changed:bool=h.get("style","")=="round_tower" and influence.intersects(Pitch.Frame.house_bounds(h),true) and Pitch.Round.for_house(h,city.houses,city.roads)!=Pitch.Round.for_house(h,draft.houses,draft.roads)
		var clock_changed:bool=Pitch.clockwork(h,draft) and influence.intersects(Pitch.Frame.house_bounds(h),true) and pop.demo.town.Clockwork.adjacency_signature(city,h)!=pop.demo.town.Clockwork.adjacency_signature(draft,h)
		if str(h.id)==target or before.signature(str(h.id))!=after.signature(str(h.id)) or bridge_changed or round_changed or clock_changed:ids.append(str(h.id))
	pending=Preview.new();pending.start(pop.demo,{"city":draft,"changed":ids,"context":after});prepared=desired
func _commit()->void:
	if committing:return
	var checked:=Pitch.check_value(city,city.houses[city._house_index(target)],desired)
	if not checked.ok:cancel();pop.demo._message(checked.message);return
	committing=true
	var source:RefCounted=city;var id:=target;var angle:=desired;var key:=epoch.duplicate()
	if int(source.snapshot().schema)<Pitch.required_schema(source.houses[source._house_index(id)],source):
		if current!=null:
			current.renderer.hide()
			for node:Node3D in current.hidden:
				if is_instance_valid(node):node.show()
		pop.demo.gallery._set_busy(true);backup=await pop.demo.gallery._capture("调整屋顶坡度前的城市","before_roof_pitch");pop.demo.gallery._set_busy(false)
		if not backup.ok:cancel();committing=false;pop.demo._message("原城未能收藏，屋顶未更改。");return
	if not dragging or city!=source or pop.demo.state!=source or key!=[source.revision,source._wish_epoch] or pop.target_house_id!=id:cancel();committing=false;return
	var result:Dictionary=source.set_house_roof_pitch(id,angle)
	if not result.ok:cancel();committing=false;pop.demo._message(result.message);return
	if current!=null:
		current.renderer.show()
		for node:Node3D in current.hidden:
			if is_instance_valid(node):node.hide()
	dragging=false;releasing=false;committing=false;pop.demo._after_edit(result,"room",true,id);pop.refresh();holding=[source.get_instance_id(),source.revision,source._wish_epoch]
func _reset()->void:
	if committing or pop.demo.edit_pending() or pop.demo.save_blocked:return
	cancel();var id:String=pop.target_house_id;pop.demo._after_edit(pop.demo.state.set_house_roof_pitch(id,null),"room",true,id);pop.refresh()
func _handle_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:_begin();gesture_y=event.global_position.y;gesture_pitch=desired
		else:_release()
		handle.accept_event()
	elif event is InputEventMouseMotion and dragging:
		desired=clampf(gesture_pitch+(gesture_y-event.global_position.y)*.35,0.,78.);slider.set_value_no_signal(desired);label.text="屋顶坡度 %.1f°"%desired;handle.position.y=event.global_position.y-16.;handle.accept_event()
func _process(_delta:float)->void:
	if pop.target_house_id.is_empty():
		if dragging or current!=null or pending!=null:cancel()
		row.hide();handle.hide();return
	var h:=_house();var visible:bool=pop.card.is_visible_in_tree() and pop.inspector.panel.visible and pop.inspector.mode=="appearance" and not h.is_empty()
	var key:Array=[pop.demo.state.get_instance_id(),pop.demo.state.revision,pop.demo.state._wish_epoch,pop.target_house_id]
	if visible and key!=support_key:support_key=key;supported=Pitch.supported(pop.demo.state,h)
	var preserve_form:bool=h.get("architecture","") in ["peristyle","rotunda"] and not supported
	row.visible=visible and (not preserve_form or h.has(Pitch.FIELD));handle.visible=visible and supported
	if committing:return
	if not holding.is_empty():
		if holding!=[pop.demo.state.get_instance_id(),pop.demo.state.revision,pop.demo.state._wish_epoch] or not pop.demo.edit_pending() and not pop.demo._edit_ui_pending:cancel()
		else:handle.hide();return
	if dragging:
		if not _valid() or not visible:cancel();return
		if pending!=null:
			pending.step()
			if pending.ready:
				if current!=null:current.clear()
				current=pending;pending=null
				for root:Node3D in current.hidden:root.hide()
		if pending==null and desired!=prepared:_preview()
		elif releasing and pending==null:_commit()
		return
	if not visible:return
	slider.editable=supported;reset.disabled=not h.has(Pitch.FIELD);handle.modulate=Color.WHITE
	slider.set_value_no_signal(_initial_angle(h));label.text=("屋顶坡度 %.1f°"%slider.value if Pitch.applies(h,pop.demo.state) else "原顶 · 拖动调坡") if supported else "保留原有屋盖" if preserve_form else "此屋形暂不能调坡 · 原顶保留"
	if not supported and Pitch.renaissance_special(h,pop.demo.state):label.text="望楼外角净空不足 · 原坡度保留" if h.architecture=="corner_loggia_tower" else "阶梯山墙需要完整矩形屋形 · 原坡度保留" if h.architecture=="stepped_guildhouse" else "此屋形暂不能调坡 · 原顶保留"
	if not supported and Pitch.acoustic(h,pop.demo.state):label.text="木壳需完整矩形且无穿堂 · 原坡度保留"
	if not supported and Pitch.stoa(h,pop.demo.state):label.text="长馆需完整矩形屋形 · 原坡度保留"
	if not supported and Pitch.basilica(h,pop.demo.state):label.text="殿堂需完整矩形且正面通达 · 原坡度保留"
	if not supported:return
	var apex:=Vector3.ZERO;var top:=-INF
	var root:Node3D=pop.demo.town.house_roots[str(h.id)];var modern_roof:Dictionary=root.get_meta("modern_roof_pitch",root.get_meta("clockwork_roof_pitch",root.get_meta("renaissance_roof_pitch",{})))
	if not modern_roof.is_empty():apex=modern_roof.apex
	else:
		for patch:Dictionary in pop.demo.town.building_context.roof_patches(str(h.id)):
			if patch.surface!="roof":continue
			for p:Vector3 in patch.vertices:
				if p.y>top:top=p.y;apex=p
		var round:Dictionary=root.get_meta("round_tower",{})
		if not round.is_empty():apex=Vector3(round.center.x,round.roof_top_y,round.center.y)
		if Pitch.clockwork(h,pop.demo.state):
			for cell:Dictionary in h.cells:
				var y:float=float(h.get("base_y",0.))+(int(cell.level)+1)*1.7+1.
				if y>apex.y:apex=Vector3(h.origin[0]+cell.x*1.8,y,h.origin[1]+cell.z*1.8)
		if Pitch.renaissance_special(h,pop.demo.state):
			if not root.has_meta("renaissance_original_anchor"):root.set_meta("renaissance_original_anchor",Pitch.Renaissance.source_anchor(pop.demo.state,h))
			apex=root.get_meta("renaissance_original_anchor")
	if Pitch.boathouse(h,pop.demo.state):
		if not root.has_meta("boathouse_roof_anchor"):root.set_meta("boathouse_roof_anchor",preload("res://scripts/visual/city_creation_boathouse.gd").anchor(root))
		apex=root.get_meta("boathouse_roof_anchor")
	if Pitch.acoustic(h,pop.demo.state):apex=root.get_meta("acoustic_roof_pitch",{}).get("apex",root.get_meta("acoustic_original_anchor",Vector3.ZERO))
	if Pitch.guildhall(h,pop.demo.state):apex=root.get_meta("guildhall_roof_pitch",{}).get("apex",root.get_meta("guildhall_original_anchor",apex))
	if Pitch.portico(h,pop.demo.state):
		apex=root.get_meta("portico_roof_pitch",{}).get("apex",root.get_meta("portico_original_anchor",apex))
	if Pitch.stoa(h,pop.demo.state):apex=root.get_meta("stoa_roof_pitch",{}).get("apex",root.get_meta("stoa_original_anchor",Vector3.ZERO))
	if Pitch.basilica(h,pop.demo.state):apex=root.get_meta("basilica_roof_pitch",{}).get("apex",root.get_meta("basilica_original_anchor",Vector3.ZERO))
	var at:Vector2=pop.demo.camera.unproject_position(Pitch.Frame.world3(h,apex));var size:Vector2=pop.overlay.get_viewport_rect().size
	handle.position=Vector2(clampf(at.x-16.,12.,size.x-44.),clampf(at.y-38.,84.,size.y-152.))
func _input(event:InputEvent)->void:
	if dragging and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:cancel();get_viewport().set_input_as_handled()
func _exit_tree()->void:cancel()
