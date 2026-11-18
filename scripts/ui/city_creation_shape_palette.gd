extends PanelContainer
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
const UI=preload("res://scripts/ui/valley_ui_theme.gd")
const Seal=preload("res://scripts/ui/city_creation_seal_button.gd")
const Shape=preload("res://scripts/ui/city_creation_shape_button.gd")
const Book=preload("res://scripts/ui/city_creation_prototype_book.gd")
const Styles=preload("res://scripts/ui/city_creation_house_style_picker.gd")
var dock:RefCounted
var city:RefCounted
var eras:Dictionary={}
var cards:Dictionary={}
var strip:HBoxContainer
var scroll:ScrollContainer
var prototype:Button
func setup(owner:RefCounted,parent:Control)->void:
	dock=owner;city=dock.demo.state;name="NewHousePalette";add_theme_stylebox_override("panel",UI.panel(7));parent.add_child(self)
	if not city.has_meta("new_house_brush"):Brush.select(city,"pastoral")
	var column:=VBoxContainer.new();add_child(column)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",7);column.add_child(row)
	var caption:=Label.new();caption.text="新屋形状";caption.add_theme_font_size_override("font_size",12);row.add_child(caption)
	for i in range(city.Eras.IDS.size()):
		var id:String=city.Eras.IDS[i];var button:=Seal.new();button.name="NewHouseEra_"+id;button.configure(["prototype/portico","prototype/venetian_loggia","clockmaker","vegetation"][i],44.);button.caption=["古典","文艺","蒸汽","生态"][i];button.disabled=not city.can_build_era(id);row.add_child(button);eras[id]=button
		button.tooltip_text=city.Eras.NAMES[i]+(" · 尚未解锁" if button.disabled else " · 用于接下来新造的房屋")
		button.pressed.connect(_era.bind(id))
	prototype=Button.new();prototype.name="NewHousePrototype";prototype.text="原型册";prototype.pressed.connect(func():Book.obtain(dock.demo).for_brush(_rebuild));row.add_child(prototype)
	var landmarks:=Button.new();landmarks.name="NewHouseLandmarks";landmarks.text="地标形状";landmarks.pressed.connect(_landmarks);row.add_child(landmarks)
	scroll=ScrollContainer.new();scroll.name="NewHouseShapes";scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.custom_minimum_size.y=108;column.add_child(scroll)
	strip=HBoxContainer.new();strip.add_theme_constant_override("separation",6);scroll.add_child(strip)
	get_viewport().size_changed.connect(_fit);_fit();_rebuild()
func _fit()->void:scroll.custom_minimum_size.x=minf(640.,get_viewport_rect().size.x-64.)
func _landmarks()->void:
	dock.house_options=false;dock.refresh();dock.demo.signatures.open_panel()
func _era(id:String)->void:
	Brush.select(city,id);dock.demo.house_module_mode=false;scroll.scroll_horizontal=0;_rebuild()
func _rebuild()->void:
	for child:Node in strip.get_children():strip.remove_child(child);child.queue_free()
	cards.clear()
	for i in range(Styles.IDS.size()):_card("style/"+Styles.IDS[i],Styles.NAMES[i],"基础屋式 · "+Styles.NAMES[i]+"；只用于新屋")
	var choice:=Brush.current(city)
	for id:String in Brush.prototypes(str(choice.era)):_card("prototype/"+id,Brush.Architecture.label(id),str(Book.NOTES.get(id,"时代建筑原型")))
	_sync()
func _card(key:String,label:String,description:String)->void:
	var button:=Shape.new();button.name="NewHouseShape_"+key.replace("/","_");button.configure(key,label);button.toggle_mode=true;button.tooltip_text=description;strip.add_child(button);cards[key]=button;button.pressed.connect(_choose.bind(key))
func _choose(key:String)->void:
	var choice:=Brush.current(city)
	if key.begins_with("prototype/"):Brush.select(city,str(choice.era),key.trim_prefix("prototype/"))
	else:
		Brush.select(city,str(choice.era));choice=Brush.current(city).duplicate(true)
		var appearance:Dictionary=choice.get("appearance",{}).duplicate(true);appearance.style=key.trim_prefix("style/");choice.appearance=appearance;city.set_meta("new_house_brush",choice)
	dock.demo.house_module_mode=false;dock.demo.preview_key="";_sync()
	if get_global_rect().position.y<=get_viewport_rect().get_center().y:
		dock.house_options=false;dock.refresh()
func _sync()->void:
	var choice:=Brush.current(city);var selected:="prototype/"+str(choice.prototype) if not str(choice.prototype).is_empty() else "style/"+str(choice.get("appearance",{}).get("style","classic"))
	for id:String in eras:eras[id].active=id==choice.era
	for key:String in cards:cards[key].active=key==selected
	prototype.tooltip_text="当前："+Brush.Architecture.label(str(choice.prototype))+" · 查看全部轮廓和适配说明"
