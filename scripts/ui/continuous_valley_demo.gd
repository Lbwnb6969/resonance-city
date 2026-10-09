class_name ContinuousValleyDemo
extends Control
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Projection2D = preload("res://scripts/world/world_projection.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Config = preload("res://scripts/world/world_values.gd")
const GrowthSprite = preload("res://scripts/visual/audio_growth_mask.gd")
const Shadows = preload("res://scripts/visual/city_shadow_layer.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
var scenery := ValleyScenery.new()
var expression := "bright"
var starter := true
var town_starter := false
var expanded_town_starter := false
var terrain_family := "river_valley"
@export var session_persistence := true
var archive_directory := CityArchive.DIRECTORY
var last_saved_event_count := -1
var last_checkpoint_phrase := 0
var model: ContinuousAudioModel
var shown_world: ContinuousWorld
var clock: AudibleAudioClock
var assets: Dictionary = {}
var textures: Dictionary = {}
var asset_images: Dictionary = {}
var sprites: Dictionary = {}
var buildings_layer: Node2D
var shadow_layer: CityShadowLayer
var tooltip: Label
var caption: Label
var menu: PanelContainer
var menu_info: Label
var low_octave: CheckBox
var light_player: AudioStreamPlayer
var preview_player: AudioStreamPlayer
var light_notes: Dictionary = {}
var preview_thread: Thread
var preview_requested := false
var preview_started := false
var preview_skips := 0
var fixed_gain := 1.0
var selected_id := ""
var hover_id := ""
var context: Dictionary = {}
var pointer := Vector2.ZERO
var pointer_inside := false
var midi := 48
var view_zoom := 0.88
var zoom_target := 0.88
var pan := Vector2.ZERO
var pan_target := Vector2.ZERO
var dragging := false
var black := false
var notice := "点击房屋改编 · 空地播种 · G连接两岸 · Y切换地形 · H看全城 · N空白开局"
var notice_seconds := 10.0
var last_hover_lot := ""
var hover_seconds := 0.0
var last_birth_count := 0
var ripple_position := Vector2.ZERO
var ripple_seconds := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	clip_contents = true
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/时代城市/manifest.json"))
	for entry in manifest["entries"]:
		if int(entry["era"]) != 1: continue
		assets[entry["category"]] = entry
		textures[entry["category"]] = load("res://"+str(entry["texture"]))
		asset_images[entry["category"]] = textures[entry["category"]].get_image()
	shadow_layer = Shadows.new()
	shadow_layer.name = "GroundShadows"
	add_child(shadow_layer)
	# Ground-mask decoding belongs before audio starts.
	for entry in assets.values():
		for kind in ["shadow","contact"]:
			var path := "res://"+str(entry[kind+"_texture"])
			var texture: Texture2D = load(path)
			shadow_layer.mask_images[path] = texture.get_image()
	buildings_layer = Node2D.new()
	buildings_layer.name = "Buildings"
	buildings_layer.y_sort_enabled = true
	add_child(buildings_layer)
	tooltip = Label.new()
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.add_theme_font_size_override("font_size",15)
	tooltip.add_theme_color_override("font_color",Color("465b58"))
	tooltip.z_index = 100
	add_child(tooltip)
	caption = Label.new()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_font_size_override("font_size",18)
	caption.add_theme_color_override("font_color",Color("586a65"))
	caption.z_index = 100
	add_child(caption)
	_make_menu()
	light_player = AudioStreamPlayer.new()
	light_player.volume_db = -8.0
	add_child(light_player)
	preview_player = AudioStreamPlayer.new()
	add_child(preview_player)
	var calibration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))
	fixed_gain = float(calibration["gain"])
	clock = get_node("/root/AudioClock") as AudibleAudioClock
	_start_world()
	_warm_notes()
	if not session_persistence or not load_city(true): clock.start_output(model._mix_frame,{})
	mouse_exited.connect(func() -> void: pointer_inside = false)

func _start_world(saved: Dictionary = {}) -> void:
	_stop_preview()
	clock.stop_output()
	for sprite in sprites.values(): sprite.queue_free()
	sprites.clear()
	if saved.is_empty():
		var world := World.new("2026100900000062",true,terrain_family)
		if expanded_town_starter: world.build_expanded_town()
		elif town_starter: world.build_town()
		elif starter: world.build_starter(expression)
		model = Model.new(world,fixed_gain)
	else:
		model = Model.from_state(saved["model"])
		expression = str(saved["view"]["expression"])
		starter = bool(saved["view"]["starter"])
		town_starter = bool(saved["view"].get("town_starter",false))
		expanded_town_starter = bool(model.world.expanded_plan)
		terrain_family = str(model.world.terrain.family)
		fixed_gain = model.synth.gain
	shown_world = model.world
	selected_id = ""
	context.clear()
	menu.hide()
	last_birth_count = shown_world.buildings.size()
	zoom_target = 0.88
	pan_target = Vector2(0,70)
	view_zoom = zoom_target
	pan = pan_target
	scenery.rebuild(self)
	if not saved.is_empty():
		view_zoom = float(saved["view"]["zoom"])
		zoom_target = view_zoom
		var saved_pan: Variant = saved["view"].get("pan",Vector2.ZERO)
		pan = saved_pan if saved_pan is Vector2 else Vector2(float(saved_pan[0]),float(saved_pan[1]))
		pan_target = pan
		selected_id = str(saved["view"]["selected_id"])
		scenery.restore(saved["view"]["travelers"])
	last_saved_event_count = model.world.events.size()
	last_checkpoint_phrase = model.world.phrase_index
	_message("%s · %d栋 · %d个社区" % [shown_world.terrain_title(),shown_world.buildings.size(),shown_world.communities.size()] if not saved.is_empty() else ("%s · 林荫交响 · 完整河谷起点，可继续生长" % shown_world.terrain_title() if town_starter else ("%s · 晴岸合奏 · 18栋制作示例" % shown_world.terrain_title() if starter and expression == "bright" else ("%s · 深流慢板 · 低音与留白" % shown_world.terrain_title() if starter else "%s · 空地开局 · 点击街边播下第一段声音" % shown_world.terrain_title()))))

func _make_menu() -> void:
	menu = PanelContainer.new()
	menu.z_index = 110
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95,0.95,0.89,0.94)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	menu.add_theme_stylebox_override("panel",style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	menu.add_child(box)
	menu_info = Label.new()
	menu_info.add_theme_color_override("font_color",Color("435c59"))
	menu_info.add_theme_font_size_override("font_size",16)
	box.add_child(menu_info)
	var notes := HBoxContainer.new()
	for choice: int in [48,50,52,55,57]:
		var button := Button.new()
		button.text = {48:"地基 · C",50:"张力 · D",52:"暖和 · E",55:"开阔 · G",57:"伸展 · A"}[choice]
		button.custom_minimum_size = Vector2(72,38)
		button.pressed.connect(_choose_note.bind(choice))
		button.mouse_entered.connect(func() -> void: _light_note(choice))
		notes.add_child(button)
	box.add_child(notes)
	low_octave = CheckBox.new()
	low_octave.text = "低八度 · 深流"
	box.add_child(low_octave)
	var expressions := HBoxContainer.new()
	for item in [["晴岸合奏","bright"],["深流慢板","deep"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(_set_expression.bind(item[1]))
		expressions.add_child(button)
	box.add_child(expressions)
	var verbs := HBoxContainer.new()
	for item in [["独听社区","solo"],["静音社区","mute"],["聚焦","focus"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(_verb.bind(item[1]))
		verbs.add_child(button)
	box.add_child(verbs)
	var public_row := HBoxContainer.new()
	for item in [["营造公园","park"],["公共设施","civic"],["连接两岸","bridge"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(_verb.bind(item[1]))
		public_row.add_child(button)
	box.add_child(public_row)
	var archive_row := HBoxContainer.new()
	for item in [["存一版 · Ctrl+S","save"],["继续上次 · F9","load"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(func() -> void:
			if item[1] == "save": save_city()
			else: load_city()
			menu.hide())
		archive_row.add_child(button)
	box.add_child(archive_row)
	var dna_row := HBoxContainer.new()
	var dna_button := Button.new()
	dna_button.text = "继续最近DNA"
	dna_button.tooltip_text = "从最近导出的 City DNA JSON 恢复城市、音乐与镜头"
	dna_button.pressed.connect(load_dna)
	dna_row.add_child(dna_button)
	box.add_child(dna_row)
	var export_button := Button.new()
	export_button.text = "导出城市DNA · Ctrl+Shift+E"
	export_button.tooltip_text = "导出可读的城市、地形、道路、设施、交通与音乐编曲 JSON"
	export_button.pressed.connect(export_dna)
	box.add_child(export_button)
	var town_button := Button.new()
	town_button.text = "林荫交响 · T"
	town_button.tooltip_text = "切换到完整河谷起点；当前作品先保存，之后仍可继续生长"
	town_button.pressed.connect(_start_town)
	box.add_child(town_button)
	var expanded_button := Button.new()
	expanded_button.text = "多中心街坊 · E"
	expanded_button.tooltip_text = "48个规划社区、内外台地支路、绿廊与150栋以上成长起点"
	expanded_button.pressed.connect(_start_expanded_town)
	box.add_child(expanded_button)
	var terrain_button := Button.new()
	terrain_button.text = "切换地形族 · Y"
	terrain_button.tooltip_text = "河谷、湖盆、林岭、海湾平原、高地峡谷共享连续城市操作"
	terrain_button.pressed.connect(_cycle_terrain)
	box.add_child(terrain_button)
	add_child(menu)
	menu.hide()

func _cycle_terrain() -> void:
	_save_before_switch()
	var families: Array[String] = ValleyTerrain.family_ids()
	var index := families.find(terrain_family)
	terrain_family = families[posmod(index+1,families.size())]
	town_starter = true
	starter = true
	expression = "bright"
	_start_world()
	clock.start_output(model._mix_frame,{})
	_message("已切换到"+shown_world.terrain_title()+" · 规划、声音与时代交通保留")

func _save_before_switch() -> void:
	if session_persistence and model != null and clock.active: save_city("切换前保存")

func _start_expanded_town() -> void:
	_save_before_switch()
	starter = true
	town_starter = true
	expanded_town_starter = true
	expression = "bright"
	_start_world()
	clock.start_output(model._mix_frame,{})
	_message("多中心街坊 · "+str(shown_world.communities.size())+"个社区 · "+str(shown_world.buildings.size())+"栋起点")

func _start_town() -> void:
	_save_before_switch()
	starter = true
	town_starter = true
	expanded_town_starter = false
	expression = "bright"
	_start_world()
	clock.start_output(model._mix_frame,{})

func _stop_preview() -> void:
	preview_requested = false
	preview_started = false
	if preview_thread != null:
		preview_thread.wait_to_finish()
		preview_thread = null
	if is_instance_valid(preview_player): preview_player.stop()

func capture_city() -> Dictionary:
	return {"model":model.capture_state(),"renderer":clock.renderer.snapshot(),
		"view":{"expression":expression,"starter":starter,"town_starter":town_starter,"zoom":view_zoom,"pan":pan,
			"selected_id":selected_id,"travelers":scenery.snapshot()}}

func save_city(reason: String = "手动保存") -> Dictionary:
	var result := CityArchive.save(capture_city(),reason,archive_directory)
	if result["ok"]:
		last_saved_event_count = model.world.events.size()
		if reason == "手动保存": _message("这一版城市已保存 · F9继续上次，旧版本保留")
	else: _message(result["reason"])
	return result

func export_dna() -> Dictionary:
	var result := CityArchive.export_dna(capture_city())
	if result["ok"]: _message("城市DNA已导出 · "+str(result["path"]))
	else: _message(result["reason"])
	return result

func load_dna() -> bool:
	var saved := CityArchive.latest_dna()
	if not saved["ok"]:
		_message(saved["reason"])
		return false
	_save_before_switch()
	_start_world(saved)
	clock.start_output(model._mix_frame,{},saved.get("renderer",{}))
	_message("已从最近 City DNA 继续 · 音乐与城市状态已恢复" if saved.get("skipped",0) == 0 else "已恢复上一份完整 City DNA")
	return true

func load_city(silent_empty: bool = false) -> bool:
	var saved := CityArchive.latest(archive_directory)
	if not saved["ok"]:
		if not silent_empty: _message(saved["reason"])
		return false
	_save_before_switch()
	_start_world(saved["city"])
	clock.start_output(model._mix_frame,{},saved["city"]["renderer"])
	_message("已继续上次的城市 · 音乐与生长从这里接上" if saved["skipped"] == 0 else "已恢复上一份完整作品，损坏版本仍保留")
	return true

func _checkpoint() -> void:
	if session_persistence and model.world.events.size() != last_saved_event_count: save_city("城市生长")

func _warm_notes() -> void:
	var rate := int(Config.load_values()["timing"]["sample_rate"])
	for base: int in [36,38,40,43,45,48,50,52,55,57]:
		var samples := PackedVector2Array()
		var table: PackedFloat32Array = model.synth.tables["commercial" if posmod(base,12) == 4 else "residential"]
		var phase := 0.0
		for at in range(roundi(0.35*rate)):
			var position := phase*table.size()
			var index := int(position)
			var amplitude := sin(PI*float(at)/(0.35*rate))*0.035
			var sample := lerpf(table[index],table[(index+1)%table.size()],position-index)*amplitude
			samples.append(Vector2.ONE*sample)
			phase = fposmod(phase+model.synth.frequency(base)/rate,1.0)
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = rate
		stream.stereo = true
		stream.data = Renderer.pcm16(samples)
		light_notes[base] = stream
		for offset in [0,7,12]: model.synth.Stage.waveform(base+offset,rate,model.synth.values["stage_audio"],"ornament")
		model.synth.Stage.waveform(base+24,rate,model.synth.values["stage_audio"],"bell")

func _light_note(note: int) -> void:
	var pitch := note-12 if low_octave.button_pressed or Input.is_key_pressed(KEY_SHIFT) else note
	light_player.stream = light_notes[pitch]
	light_player.play()

func note_name(note: int) -> String:
	return str({0:"C",2:"D",4:"E",7:"G",9:"A"}.get(posmod(note,12),"·"))

func point(p: Vector2, height: float = -1.0) -> Vector2:
	var h := shown_world.terrain.height_at(p) if height < 0.0 else height
	return Projection2D.to_screen(p-Vector2(16,16),Vector2(size.x*0.5,size.y*0.52)+pan,view_zoom,Vector2(28,14),h)

func world_at(screen: Vector2) -> Vector2:
	var origin := Vector2(size.x*0.5,size.y*0.52)+pan
	var p := Projection2D.from_screen(screen,origin,view_zoom)+Vector2(16,16)
	for i in range(5): p = Projection2D.from_screen(screen,origin,view_zoom,Vector2(28,14),shown_world.terrain.height_at(p))+Vector2(16,16)
	return p

func _project_polygon(polygon: PackedVector2Array, height: float = -1.0) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in polygon: result.append(point(p,height))
	return result

func _hit(screen: Vector2) -> String:
	var ordered: Array = sprites.keys()
	ordered.sort_custom(func(a: String,b: String) -> bool: return sprites[a].position.y > sprites[b].position.y)
	for id in ordered:
		var sprite: AudioGrowthMask = sprites[id]
		if sprite.progress <= 0.0: continue
		var local := sprite.to_local(screen)-sprite.offset
		var image: Image = asset_images[shown_world.by_id[id]["type"]]
		if local.x >= 0 and local.y >= 0 and local.x < image.get_width() and local.y < image.get_height():
			if image.get_pixelv(Vector2i(local)).a > 0.1 and local.y/image.get_height() >= 1.0-sprite.progress: return id
	return ""

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer = event.position
		pointer_inside = true
		if dragging:
			pan += event.relative
			pan_target = pan
	if event is InputEventMouseButton:
		pointer = event.position
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_target = clampf(zoom_target*(1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/1.12),0.55,1.9)
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			model.cancel_pending()
			menu.hide()
			context.clear()
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not black:
			var id := _hit(pointer)
			if not id.is_empty():
				selected_id = id
				context = {"kind":"retune","id":id}
				menu_info.text = "给这栋建筑换一个音"
			else:
				var p := world_at(pointer)
				var site := shown_world.public_at(p)
				if not site.is_empty():
					context = {"kind":site["kind"],"id":site["id"]}
					selected_id = ""
					menu_info.text = site["name"]+" · 点击下方营造"
					menu.position = Vector2(clampf(pointer.x-100,12,size.x-460),clampf(pointer.y+22,80,size.y-290))
					menu.show()
					return
				var check := model.world.placement(p)
				if not check["allowed"]:
					_message(check["reason"])
					return
				selected_id = ""
				context = {"kind":"seed","position":[p.x,p.y]}
				menu_info.text = "播下一段声音 · "+str(check["preview"])+" · 用途由地块决定"
			menu.position = Vector2(clampf(pointer.x-100,12,size.x-460),clampf(pointer.y+22,70,size.y-290))
			menu.show()

func _choose_note(choice: int) -> void:
	midi = choice-12 if low_octave.button_pressed or Input.is_key_pressed(KEY_SHIFT) else choice
	_light_note(choice)
	if context.is_empty() or context["kind"] not in ["seed","retune"]: return
	var operation := context.duplicate(true)
	operation["midi"] = midi
	operation["expression"] = expression
	var result := model.submit(operation)
	if result["accepted"]:
		if operation["kind"] == "seed": ripple_position = Vector2(operation["position"][0],operation["position"][1])
		else: ripple_position = Coupling.position_of(shown_world.by_id[operation["id"]])
		ripple_seconds = 0.6
		_message("下一拍换音，下一句城市随之生长" if operation["kind"] == "retune" else "声音已播下，下一句会长出房屋；可以继续播种")
		menu.hide()
	else: _message(result["reason"])

func _verb(verb: String) -> void:
	if verb in ["park","civic"]:
		var site: Dictionary = {}
		for candidate in shown_world.public_sites:
			if candidate["kind"] != verb or candidate["active"]: continue
			if context.get("id","") == candidate["id"]:
				site = candidate
				break
			if site.is_empty(): site = candidate
		if site.is_empty():
			_message("公共空间已经落成，悬停查看它服务的街区")
			return
		var result := model.submit({"kind":verb,"id":site["id"]})
		_message(site["name"]+"会在下一句落成" if result["accepted"] else result["reason"])
		menu.hide()
		return
	if verb == "bridge":
		var result := model.submit({"kind":"bridge"})
		_message("桥会在下一乐句连接两岸" if result["accepted"] else str(result["reason"]))
		menu.hide()
		return
	if selected_id.is_empty(): return
	var community: String = shown_world.by_id[selected_id]["community_id"]
	if verb == "solo": model.submit({"kind":"solo","community":community if model.synth.listener_community != community else ""})
	elif verb == "mute": model.submit({"kind":"mute","community":community,"enabled":not bool(model.synth.muted_communities.get(community,false))})
	elif verb == "focus":
		zoom_target = 1.65
		var p := Coupling.position_of(shown_world.by_id[selected_id])-Vector2(16,16)
		pan_target = -Vector2((p.x-p.y)*28,(p.x+p.y)*14)*zoom_target
	menu.hide()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo: return
	if event.pressed and event.ctrl_pressed and event.keycode == KEY_S:
		save_city()
		get_viewport().set_input_as_handled()
		return
	if event.pressed and event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_E:
		export_dna()
		get_viewport().set_input_as_handled()
		return
	if event.pressed and event.keycode == KEY_F9:
		load_city()
		get_viewport().set_input_as_handled()
		return
	if event.keycode in [KEY_SPACE,KEY_ESCAPE,KEY_B,KEY_G,KEY_TAB,KEY_M,KEY_F,KEY_R,KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_N,KEY_V,KEY_H,KEY_T,KEY_Y,KEY_E]: get_viewport().set_input_as_handled()
	if event.keycode == KEY_SPACE and not event.pressed:
		preview_requested = false
		preview_player.stop()
		return
	if not event.pressed: return
	match event.keycode:
		KEY_ESCAPE:
			black = false
			menu.hide()
			model.submit({"kind":"solo","community":""})
		KEY_B: black = not black
		KEY_G: _verb("bridge")
		KEY_TAB: _verb("solo")
		KEY_M: _verb("mute")
		KEY_F: _verb("focus")
		KEY_H:
			zoom_target = 0.88
			pan_target = Vector2(0,70)
		KEY_T: _start_town()
		KEY_Y: _cycle_terrain()
		KEY_E: _start_expanded_town()
		KEY_N:
			_save_before_switch()
			town_starter = false
			expanded_town_starter = false
			starter = false
			_start_world()
			clock.start_output(model._mix_frame,{})
		KEY_V:
			_save_before_switch()
			town_starter = false
			expanded_town_starter = false
			starter = true
			expression = "deep"
			_start_world()
			clock.start_output(model._mix_frame,{})
		KEY_R:
			_save_before_switch()
			town_starter = false
			expanded_town_starter = false
			starter = true
			expression = "bright"
			_start_world()
			clock.start_output(model._mix_frame,{})
		KEY_SPACE: _request_preview()
		KEY_1: _choose_note(48)
		KEY_2: _choose_note(50)
		KEY_3: _choose_note(52)
		KEY_4: _choose_note(55)
		KEY_5: _choose_note(57)

func _message(text: String) -> void:
	notice = text
	notice_seconds = 6.0

func _request_preview() -> void:
	if preview_thread != null or context.get("kind","seed") not in ["seed","retune"]: return
	var operation := context.duplicate(true)
	if operation.is_empty():
		var p := world_at(pointer)
		if not model.world.placement(p)["allowed"]: return
		operation = {"kind":"seed","position":[p.x,p.y]}
	operation["midi"] = midi
	var frozen := model.freeze()
	var state := clock.renderer.state.duplicate(true)
	var at := clock.renderer.transport.rendered_frames
	preview_requested = true
	preview_started = false
	preview_thread = Thread.new()
	preview_thread.start(_build_preview.bind(frozen,operation,state,at))

func _build_preview(frozen: ContinuousAudioModel, operation: Dictionary, state: Dictionary, at: int) -> PackedByteArray:
	var rate := int(Config.load_values()["timing"]["sample_rate"])
	return Renderer.pcm16(frozen.forecast(operation,state,at,rate*3))

func _process(delta: float) -> void:
	if model == null: return
	view_zoom = lerpf(view_zoom,zoom_target,1.0-exp(-delta/0.14))
	pan = pan.lerp(pan_target,1.0-exp(-delta/0.14))
	shown_world = model.presentation_world(clock.renderer.transport.audible_frame)
	if preview_thread != null and not preview_thread.is_alive():
		var pcm: PackedByteArray = preview_thread.wait_to_finish()
		preview_thread = null
		if preview_requested and not pcm.is_empty():
			var stream := AudioStreamWAV.new()
			stream.format = AudioStreamWAV.FORMAT_16_BITS
			stream.mix_rate = int(Config.load_values()["timing"]["sample_rate"])
			stream.stereo = true
			stream.data = pcm
			preview_player.stream = stream
			preview_player.play()
			preview_started = true
			preview_skips = clock.underruns
			model.synth.ducking = true
			model.synth.duck_release_at = clock.renderer.transport.rendered_frames+stream.mix_rate*3
	_sync_buildings()
	scenery.sync(self)
	if shown_world.phrase_index != last_checkpoint_phrase:
		last_checkpoint_phrase = shown_world.phrase_index
		if not shown_world.events.is_empty() and shown_world.events.back().get("kind","") == "era":
			_message("时代进入 "+shown_world.era_title()+" · "+shown_world.vehicle_label()+" 已沿道路出现")
		call_deferred("_checkpoint")
	if shown_world.buildings.size() > last_birth_count:
		if last_birth_count == 0:
			zoom_target = 1.05
			var first := Coupling.position_of(shown_world.buildings[0])-Vector2(16,16)
			pan_target = -Vector2((first.x-first.y)*28,(first.x+first.y)*14)*zoom_target
		last_birth_count = shown_world.buildings.size()
		_message("你的声音正在长成城市")
	notice_seconds = maxf(0.0,notice_seconds-delta)
	ripple_seconds = maxf(0.0,ripple_seconds-delta)
	caption.text = notice if notice_seconds > 0.0 else ""
	caption.position = Vector2(48,size.y-68)
	caption.visible = not black
	tooltip.visible = not black and pointer_inside and not menu.visible
	shadow_layer.visible = not black
	buildings_layer.visible = not black
	if black: menu.hide()
	hover_id = _hit(pointer) if pointer_inside else ""
	var p := world_at(pointer)
	var check := model.world.placement(p)
	if not hover_id.is_empty():
		var b: Dictionary = shown_world.by_id[hover_id]
		tooltip.text = "%s · %s · %s\n%s  ·  活力 %.0f\n点击选音   Tab独听社区   F聚焦" % ["律动街" if b["type"] == "commercial" else "长音房",note_name(int(model.audible_pitches().get(b["district_id"],b["current_midi"]))),b["form"],shown_world.communities[b["community_id"]]["name"],b["vitality"]]
	elif check["allowed"]:
		tooltip.text = "%s\n%s\n点击选音；Shift低八度；按住空格试听" % [str(check["preview"]),note_name(midi)]
		var lot: String = check["lot_id"]
		hover_seconds = hover_seconds+delta if lot == last_hover_lot else 0.0
		if lot != last_hover_lot: last_hover_lot = lot
		if hover_seconds > 0.18 and hover_seconds < 0.18+delta: _light_note(midi+12 if midi < 48 else midi)
	else:
		var site := shown_world.public_at(p)
		if not site.is_empty():
			tooltip.text = site["name"]+"\n"+("已落成 · 沿道路服务%d栋\n公园为主题留白，文化设施让主题更清楚" % site.get("covered",[]).size() if site["active"] else "公共保留地 · 点击营造\n公园让音乐呼吸，文化设施组织主题")
		else: tooltip.text = "合法陆地都能播种；靠近道路会长得更快\n滚轮缩放 · 中键移动 · G建桥 · H全城 · Y切换地形 · E扩展城\nR晴岸 · V深流 · T林荫交响 · N空地\nCtrl+S存一版 · F9继续"
	tooltip.position = Vector2(clampf(pointer.x+18,12,size.x-420),clampf(pointer.y+20,70,size.y-125))
	if menu.visible and pointer_inside and not menu.get_global_rect().grow(100).has_point(pointer): menu.hide()
	queue_redraw()

func _sync_buildings() -> void:
	var records: Array[Dictionary] = []
	for building in shown_world.buildings:
		var id: String = building["district_id"]
		var entry: Dictionary = assets[building["type"]]
		var scale_factor := 28.0*sqrt(2.0)*0.8/maxf(float(entry["model_bounds"]["size"][0]),float(entry["model_bounds"]["size"][2]))/float(entry["pixels_per_world"])
		if not sprites.has(id):
			var sprite := GrowthSprite.new()
			sprite.use_master_clock = false
			sprite.texture = textures[building["type"]]
			sprite.centered = false
			sprite.offset = -Vector2(entry["origin"][0],entry["origin"][1])
			buildings_layer.add_child(sprite)
			sprite.begin_at(maxi(0,int(building["birth_frame"])))
			sprites[id] = sprite
		var sprite: AudioGrowthMask = sprites[id]
		sprite.position = point(Coupling.position_of(building))
		sprite.scale = Vector2.ONE*scale_factor*view_zoom
		sprite.sample_frame(clock.renderer.transport.audible_frame-minf(0.0,float(building["birth_frame"])))
		var played := int(model.audible_pitches().get(id,building["current_midi"]))
		var warmth := 0.03*sin(TAU*float(clock.renderer.transport.audible_frame)/float(clock.renderer.transport.sample_rate)/4.0)
		sprite.modulate = Color(0.96+warmth,1.0,0.92 if played < 48 else 0.97,1.0)
		records.append({"entry":entry,"position":(sprite.position-Vector2(size.x*0.5,size.y*0.52)-pan)/view_zoom,"base_scale":Vector2.ONE*scale_factor,"progress":sprite.progress,"visible":true})
	shadow_layer.position = Vector2(size.x*0.5,size.y*0.52)+pan
	shadow_layer.scale = Vector2.ONE*view_zoom
	shadow_layer.update_records(records)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("ecebe2"))
	if black:
		draw_rect(Rect2(Vector2.ZERO,size),Color.BLACK)
		return
	if shown_world == null: return
	var sea := PackedVector2Array([Vector2(-8,-8),Vector2(40,-8),Vector2(40,40),Vector2(-8,40)])
	var family := shown_world.terrain.family
	var water_color := Color("78a4ad") if family == "river_valley" else (Color("719ca8") if family == "lake_basin" else (Color("82aab0") if family == "coastal_plain" else (Color("5f8192") if family == "highland_pass" else Color("6e9c9a"))))
	var left_color := Color("e9e1cb") if family != "forest_ridge" and family != "highland_pass" else (Color("9eafad") if family == "highland_pass" else Color("b7c8a4"))
	var right_color := Color("e0e5d6") if family != "coastal_plain" and family != "highland_pass" else (Color("c4d0cc") if family == "highland_pass" else Color("e5d9bd"))
	draw_colored_polygon(_project_polygon(sea,0.0),Color("9bbcc0"))
	draw_colored_polygon(_project_polygon(shown_world.terrain.left_bank),left_color)
	draw_colored_polygon(_project_polygon(shown_world.terrain.right_bank),right_color)
	_draw_ground_details()
	# Contours show the seeded hill without introducing a second terrain model.
	for radius: float in [3.0,5.0,7.0,9.0]:
		var contour := PackedVector2Array()
		for step in range(65):
			var p := Vector2(4,2)+Vector2.from_angle(TAU*step/64.0)*radius
			if shown_world.terrain.land_at(p): contour.append(point(p))
		if contour.size() > 2: draw_polyline(contour,Color(0.54,0.64,0.49,0.16),1.0,true)
	draw_colored_polygon(_project_polygon(shown_world.terrain.water,0.0),water_color)
	var flow := float(clock.renderer.transport.audible_frame)/float(clock.renderer.transport.sample_rate)
	for i in range(18):
		var y := -3.0+fposmod(float(i)*2.1+flow*0.35,38.0)
		var x := shown_world.terrain.river_x(y)
		var span := 0.4 if family != "lake_basin" else 0.8
		draw_line(point(Vector2(x-span,y),0.0),point(Vector2(x+span,y+0.12),0.0),Color(0.8,0.91,0.9,0.28),1.0*view_zoom,true)
	if family == "lake_basin":
		for i in range(6):
			var ripple := Vector2(shown_world.terrain.river_x(10.0+i*3.2),10.0+i*3.2)
			draw_arc(point(ripple,0.01),0.38+0.08*sin(flow*2.0+i),0,TAU,20,Color(0.86,0.93,0.9,0.22),0.8*view_zoom,true)
	for road in shown_world.roads:
		var width := 0.55 if road["bridge"] else (float(shown_world.cfg["city"]["branch_road_half_width"]) if road.get("kind","") == "branch" else float(shown_world.cfg["terrain"]["template_road_half_width"]))
		for polygon in Geometry2D.offset_polyline(road["path"],width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
			draw_colored_polygon(_project_polygon(polygon),Color("d3bb93") if road["bridge"] else Color("f1eee0"))
	_draw_center_markers()
	_draw_green_corridors()
	_draw_public_space()
	for lot in shown_world.lots:
		var center := Vector2(lot["center"][0],lot["center"][1])
		if lot["occupant"] != "":
			draw_colored_polygon(_project_polygon(lot["polygon"]),Color(0.68,0.73,0.57,0.2))
		elif pointer_inside and center.distance_to(world_at(pointer)) < 1.0:
			draw_colored_polygon(_project_polygon(lot["polygon"]),Color(0.9,0.94,0.8,0.5))
	_draw_fabric_overlay()
	if shown_world.buildings.is_empty():
		var target: Dictionary = shown_world.lots[mini(18,shown_world.lots.size()-1)]
		var p := Vector2(target["center"][0],target["center"][1])
		draw_arc(point(p),13.0*view_zoom,0,TAU,36,Color(0.72,0.8,0.54,0.65),1.7,true)
	for op in model.world.pending_actions:
		if op["kind"] != "seed": continue
		var p := Vector2(op["position"][0],op["position"][1])
		var color := Color(0.87,0.78,0.53,0.55+0.10*sin(flow*TAU*2.0))
		draw_colored_polygon(_project_polygon(shown_world.building_polygon(p)),color)
		draw_arc(point(p),10.0*view_zoom,0,TAU,24,color,1.0,true)
	if ripple_seconds > 0.0:
		draw_arc(point(ripple_position),(1.0-ripple_seconds/0.6)*55.0*view_zoom,0,TAU,48,Color(0.83,0.74,0.48,ripple_seconds/0.6),1.7,true)
	if not hover_id.is_empty():
		draw_arc(point(Coupling.position_of(shown_world.by_id[hover_id])),18*view_zoom,0,TAU,48,Color(0.62,0.72,0.5,0.8),1.5,true)
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(46,44),"共鸣之城",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("4b6561"))
	draw_string(font,Vector2(47,67),shown_world.terrain_title()+" · 晴岸合奏" if expression == "bright" else shown_world.terrain_title()+" · 深流慢板",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("758c85"))
	if pointer.y > size.y-60 and pointer_inside:
		var score: Dictionary = model.synth.score_snapshot()
		var lead := str(score["theme"].get("cid",""))
		var name := str(shown_world.communities.get(lead,{}).get("name","留白"))
		draw_string(font,Vector2(size.x-500,size.y-64),"时代 · "+shown_world.era_title()+"   "+shown_world.vehicle_label()+"   "+shown_world.terrain_title()+"   主题 · "+name+"   "+str(shown_world.buildings.size())+"栋   "+str(model.world.pending_actions.size())+"段等待下一句",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("607974"))
	var duration := float(model.phrase_frames)
	var progress := fposmod(float(clock.renderer.transport.audible_frame),duration)/duration
	draw_line(Vector2(48,size.y-32),Vector2(size.x-48,size.y-32),Color(0.59,0.66,0.6,0.25),2.0)
	draw_line(Vector2(48,size.y-32),Vector2(48+(size.x-96)*progress,size.y-32),Color("af9c6a"),3.0)

func diagnostics() -> Dictionary:
	return {"buildings":shown_world.buildings.size(),"planned_communities":shown_world.communities.size(),
		"lots":shown_world.lots.size(),"resonance":shown_world.resonance,"phrase":shown_world.phrase_index,
		"skips":clock.underruns,"audible_frame":clock.renderer.transport.audible_frame,"pending":model.world.pending.duplicate(true),
		"preview_started":preview_started,"seed_hex":model.world.rng.seed_hex,"blocks":shown_world.blocks.size(),
		"public_sites":shown_world.public_sites.duplicate(true),"green_corridors":shown_world.green_corridors.duplicate(true),"centers":shown_world.centers.duplicate(true),"transit":shown_world.transit_lines.map(func(line: Dictionary) -> String: return line["name"]),"terrain_family":shown_world.terrain.family,"terrain_title":shown_world.terrain_title(),"era":shown_world.era,"era_title":shown_world.era_title(),"vehicle":shown_world.vehicle_kind(),"score":model.synth.score_snapshot(),"sound_trace":model.sound_trace.duplicate(true)}

func _exit_tree() -> void:
	if session_persistence and model != null and is_instance_valid(clock) and clock.active: save_city("离开时保存")
	if preview_thread != null: preview_thread.wait_to_finish()
	if is_instance_valid(clock): clock.stop_output()


func _set_expression(value: String) -> void:
	expression = value
	low_octave.button_pressed = value == "deep"
	_message("深流：低音、缓慢脉动与留白" if value == "deep" else "晴岸：明亮主题与商街节奏")

func _draw_center_markers() -> void:
	for center in shown_world.centers:
		if not bool(center.get("active",true)): continue
		var p := Vector2(float(center["position"][0]),float(center["position"][1]))
		var level := str(center.get("level","terrace"))
		var color := Color("b28b53") if level == "primary" else (Color("6e9290") if level == "secondary" else Color("829b69"))
		var radius := 5.8 if level == "primary" else (4.4 if level == "secondary" else 3.0)
		draw_circle(point(p,shown_world.terrain.height_at(p)+0.08),radius*view_zoom,Color(color,0.24))
		draw_arc(point(p,shown_world.terrain.height_at(p)+0.09),radius*view_zoom,0,TAU,24,color,1.4*view_zoom,true)
		if level != "terrace":
			draw_circle(point(p,shown_world.terrain.height_at(p)+0.10),1.6*view_zoom,color)

func _draw_green_corridors() -> void:
	for corridor in shown_world.green_corridors:
		if not bool(corridor.get("active",true)): continue
		var path: PackedVector2Array = corridor["path"]
		if path.size() < 2: continue
		var width := float(corridor.get("width",0.24))
		for polygon in Geometry2D.offset_polyline(path,width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
			draw_colored_polygon(_project_polygon(polygon,0.012),Color(0.55,0.69,0.43,0.36))
		draw_polyline(_project_polygon(path,0.025),Color(0.48,0.62,0.39,0.64),2.2*view_zoom,true)
		for i in range(0,path.size(),2):
			var p := path[i]
			draw_circle(point(p,0.04),2.4*view_zoom,Color(0.38,0.56,0.35,0.72))

func _draw_public_space() -> void:
	var font := ThemeDB.fallback_font
	for site in shown_world.public_sites:
		var polygon: PackedVector2Array = site["polygon"]
		var projected := _project_polygon(polygon)
		if site["active"]:
			var color := Color("bacda7") if site["kind"] == "park" else Color("ded5b9")
			draw_colored_polygon(projected,color)
			if site["kind"] == "park":
				var p := Vector2(site["position"][0],site["position"][1])
				var walk := PackedVector2Array([p+Vector2(-2,0.1),p+Vector2(0.2,-0.25),p+Vector2(2,0.15)])
				for part in Geometry2D.intersect_polyline_with_polygon(walk,polygon):
					draw_polyline(_project_polygon(part),Color("e6e2c9"),3.4*view_zoom,true)
				var pool := PackedVector2Array()
				for i in range(32): pool.append(p+Vector2(0.4,0.6)+Vector2(cos(TAU*i/32)*0.5,sin(TAU*i/32)*0.35))
				draw_colored_polygon(_project_polygon(pool),Color("9bb9af"))
		else:
			projected.append(projected[0])
			draw_polyline(projected,Color(0.45,0.59,0.43,0.34),1.1,true)
		if pointer_inside and Geometry2D.is_point_in_polygon(world_at(pointer),polygon):
			var p := Vector2(site["position"][0],site["position"][1])
			draw_string(font,point(p)+Vector2(-30,30)*view_zoom,site["name"],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("617b69"))
	for line in shown_world.transit_lines:
		for node in line["stops"]:
			var p: Array = shown_world.nodes[node]
			var at := point(Vector2(p[0],p[1]))
			draw_circle(at,3.5*view_zoom,Color("e9d4a0"))
			draw_arc(at,4.2*view_zoom,0,TAU,16,Color("899d87"),1.0,true)

func _draw_fabric_overlay() -> void:
	var cache: Dictionary = shown_world.fabric_cache
	for courtyard in cache.get("courtyards",[]):
		var center := Vector2(float(courtyard["center"][0]),float(courtyard["center"][1]))
		var polygon: PackedVector2Array = courtyard.get("polygon",PackedVector2Array())
		if polygon.size() < 3:
			polygon = PackedVector2Array([center+Vector2(-0.58,0),center+Vector2(0,-0.42),center+Vector2(0.58,0),center+Vector2(0,0.42)])
		var closed := polygon.duplicate()
		closed.append(closed[0])
		draw_colored_polygon(_project_polygon(polygon,0.01),Color(0.82,0.78,0.60,0.18))
		draw_polyline(_project_polygon(closed,0.015),Color(0.74,0.66,0.48,0.50),1.1*view_zoom,true)
		draw_circle(point(center,0.025),2.0*view_zoom,Color(0.88,0.80,0.52,0.56))
	for relation in cache.get("shared_walls",[]):
		if not shown_world.by_id.has(relation["a"]) or not shown_world.by_id.has(relation["b"]): continue
		var a := point(Coupling.position_of(shown_world.by_id[relation["a"]]),shown_world.terrain.height_at(Coupling.position_of(shown_world.by_id[relation["a"]]))+0.04)
		var b := point(Coupling.position_of(shown_world.by_id[relation["b"]]),shown_world.terrain.height_at(Coupling.position_of(shown_world.by_id[relation["b"]]))+0.04)
		draw_line(a,b,Color(0.74,0.52,0.31,0.72),2.1*view_zoom,true)
	for row in cache.get("rows",[]):
		var members: Array = row["members"]
		for i in range(members.size()-1):
			if not shown_world.by_id.has(members[i]) or not shown_world.by_id.has(members[i+1]): continue
			var a := point(Coupling.position_of(shown_world.by_id[members[i]]),0.05)
			var b := point(Coupling.position_of(shown_world.by_id[members[i+1]]),0.05)
			draw_line(a,b,Color(0.62,0.67,0.49,0.42),1.4*view_zoom,true)

func _draw_ground_details() -> void:
	# Broad patches and terraces keep the hill legible without raster tiles.
	for i in range(34):
		var p := Vector2(-1.0+float((i*37)%330)/10.0,-1.5+float((i*67)%330)/10.0)
		if not shown_world.terrain.land_at(p): continue
		var ring := PackedVector2Array()
		for j in range(24):
			var q := p+Vector2(cos(TAU*j/24)*1.1,sin(TAU*j/24)*0.75)
			if shown_world.terrain.land_at(q): ring.append(q)
		if ring.size() == 24:
			draw_colored_polygon(_project_polygon(ring),Color(0.72,0.77,0.59,0.12))
	for community in shown_world.communities.values():
		if community["members"].size() < 4: continue
		var center := Vector2.ZERO
		for id in community["members"]: center += Coupling.position_of(shown_world.by_id[id])
		center /= community["members"].size()
		if view_zoom < 1.0:
			draw_string(ThemeDB.fallback_font,point(center)+Vector2(-16,29),community["name"],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(0.40,0.48,0.42,0.72))
