extends Node
const Parts=preload("res://scripts/world/city_creation_compound_parts.gd")
const Fork=preload("res://scripts/world/city_creation_chemistry_preview.gd")
const Preview=preload("res://scripts/visual/city_creation_batch_preview.gd")
var pop:RefCounted
var box:VBoxContainer
var choices:VBoxContainer
var levels:SpinBox
var kind:=0
var kinds:Array[Button]=[]
var status:Label
var accept:Button
var preview:RefCounted
var plan:Dictionary={}
var city:RefCounted
var target:=""
var epoch:Array=[]
var side:=Vector2i.RIGHT
var committing:=false
var holding:Array=[]
func setup(owner:RefCounted,parent:Control)->void:
	pop=owner;pop.demo.add_child(self);pop.demo.set_meta("compound_controls",self)
	box=VBoxContainer.new();box.name="CompoundParts";parent.add_child(box)
	var open:=Button.new();open.name="CompoundOpen";open.text="拼接分体 · 方楼 / 圆塔";open.pressed.connect(_open);box.add_child(open)
	choices=VBoxContainer.new();choices.name="CompoundChoices";box.add_child(choices)
	var row:=HBoxContainer.new();choices.add_child(row)
	for i in range(2):
		var button:=Button.new();button.name="CompoundRound" if i==0 else "CompoundSquare";button.text="圆柱塔" if i==0 else "方楼 · 平顶";button.toggle_mode=true;button.pressed.connect(_kind.bind(i));row.add_child(button);kinds.append(button)
	var title:=Label.new();title.text="层数";row.add_child(title);levels=SpinBox.new();levels.name="CompoundLevels";levels.min_value=1;levels.max_value=8;levels.step=1;row.add_child(levels);levels.value_changed.connect(func(_v):_refresh())
	row=HBoxContainer.new();choices.add_child(row)
	var directions:=[Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN,Vector2i.RIGHT]
	for i in range(4):
		var b:=Button.new();b.text=["←","↑","↓","→"][i];b.name="CompoundSide%d"%i;b.custom_minimum_size=Vector2(45,30);row.add_child(b);b.pressed.connect(_direction.bind(directions[i]))
	status=Label.new();status.name="CompoundStatus";status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.custom_minimum_size.x=260;status.add_theme_font_size_override("font_size",12);choices.add_child(status)
	row=HBoxContainer.new();choices.add_child(row);accept=Button.new();accept.name="CompoundAccept";accept.text="建成此分体";accept.pressed.connect(_commit);row.add_child(accept)
	var cancel:=Button.new();cancel.name="CompoundCancel";cancel.text="取消";cancel.pressed.connect(clear);row.add_child(cancel);choices.hide()
func _open()->void:
	if committing or pop.demo.edit_pending() or pop.demo.save_blocked:return
	clear();city=pop.demo.state;target=pop.target_house_id;epoch=[city.revision,city._wish_epoch]
	var index:int=city._house_index(target)
	if index<0:return
	var high:=0
	for c:Dictionary in city.houses[index].cells:high=maxi(high,int(c.level)+1)
	levels.set_value_no_signal(mini(8,high+1));kind=0;
	for i in range(kinds.size()):kinds[i].set_pressed_no_signal(i==kind)
	choices.show();_refresh();pop.inspector.fit()
func _kind(value:int)->void:
	kind=value
	for i in range(kinds.size()):kinds[i].set_pressed_no_signal(i==kind)
	_refresh()
func _direction(value:Vector2i)->void:side=value;_refresh()
func valid()->bool:return city==pop.demo.state and epoch==[city.revision,city._wish_epoch] and target==pop.target_house_id and (committing or pop.inspector.appearance.is_visible_in_tree()) and pop.demo.tool in [0,4] and not pop.demo.gallery.panel.visible
func clear()->void:
	if preview!=null:preview.clear()
	preview=null;plan={};city=null;target="";epoch=[];holding=[];choices.hide()
func _refresh()->void:
	if city==null or committing:return
	if preview!=null:preview.clear();preview=null
	plan=Parts.plan(city,target,side,"round_tower" if kind==0 else "classic",int(levels.value));accept.disabled=true;status.text=str(plan.message)
	if not plan.ok:return
	var draft:=Fork.fork(city);draft.houses.append(plan.house)
	var before:RefCounted=pop.demo.town.building_context;var context:=Parts.Context.new();context.copy_cache_from(before);context.prepare(draft.houses,draft.roads,draft);var ids:Array=[str(plan.house.id)]
	var influence:Rect2=Parts.Frame.house_bounds(plan.house).grow(10.)
	for h:Dictionary in city.houses:
		if before.signature(str(h.id))!=context.signature(str(h.id)) or influence.intersects(Parts.Frame.house_bounds(h),true):ids.append(str(h.id))
	preview=Preview.new();preview.start(pop.demo,{"city":draft,"changed":ids,"context":context});status.text="预览中 · 箭头选主楼的局部方向；各分体可单独加建和调坡。"
func _commit()->void:
	if committing or not valid() or preview==null or not preview.ready or not plan.get("ok",false) or pop.demo.edit_pending() or pop.demo.save_blocked:return
	committing=true;var source:RefCounted=city;var id:=target;var key:=epoch.duplicate()
	if int(city.snapshot().schema)<Parts.SCHEMA:
		preview.renderer.hide()
		for node:Variant in preview.hidden:
			if is_instance_valid(node):node.show()
		pop.demo.gallery._set_busy(true);var backup:Dictionary=await pop.demo.gallery._capture("拼接分体前的城市","before_compound_parts");pop.demo.gallery._set_busy(false)
		if not backup.ok:committing=false;clear();pop.demo._message("原城未能收藏，分体未建成。");return
	if city!=source or pop.demo.state!=source or key!=[source.revision,source._wish_epoch] or not valid():committing=false;clear();return
	var result:Dictionary=source.add_compound_part(id,side,"round_tower" if kind==0 else "classic",int(levels.value))
	if not result.ok:committing=false;clear();pop.demo._message(result.message);return
	preview.renderer.show()
	for node:Variant in preview.hidden:
		if is_instance_valid(node):node.hide()
	holding=[source.get_instance_id(),source.revision,source._wish_epoch];committing=false;choices.hide();pop.demo._after_edit(result,"room",true,str(result.house_id));pop.refresh()
func _process(_delta:float)->void:
	if preview==null:return
	if committing:return
	if not holding.is_empty():
		if pop.demo.state!=city or holding!=[city.get_instance_id(),city.revision,city._wish_epoch] or not pop.demo.edit_pending():clear()
		return
	if not valid():clear();return
	preview.step();accept.disabled=not preview.ready
func _input(event:InputEvent)->void:
	if choices.visible and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:clear();get_viewport().set_input_as_handled()
