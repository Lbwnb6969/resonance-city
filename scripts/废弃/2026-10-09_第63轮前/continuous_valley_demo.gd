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
var view_zoom := 0.58
var zoom_target := 0.58
var pan := Vector2.ZERO
var pan_target := Vector2.ZERO
var dragging := false
var black := false
var notice := "在街道旁播下一段声音，城市会在乐句里长大"
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
	var calibration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_audio_calibration.json"))
	fixed_gain = float(calibration["gain"])
	clock = get_node("/root/AudioClock") as AudibleAudioClock
	_start_world()
	_warm_notes()
	clock.start_output(model._mix_frame,{})
	mouse_exited.connect(func() -> void: pointer_inside = false)

func _start_world() -> void:
	clock.stop_output()
	for sprite in sprites.values(): sprite.queue_free()
	sprites.clear()
	model = Model.new(World.new(),fixed_gain)
	shown_world = model.world
	selected_id = ""
	context.clear()
	menu.hide()
	last_birth_count = 0
	zoom_target = 0.58
	pan_target = Vector2.ZERO

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
		button.text = note_name(choice)
		button.custom_minimum_size = Vector2(45,34)
		button.pressed.connect(_choose_note.bind(choice))
		button.mouse_entered.connect(func() -> void: _light_note(choice))
		notes.add_child(button)
	box.add_child(notes)
	low_octave = CheckBox.new()
	low_octave.text = "低八度 · 深流"
	box.add_child(low_octave)
	var verbs := HBoxContainer.new()
	for item in [["独听社区","solo"],["静音社区","mute"],["聚焦","focus"],["连接两岸","bridge"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(_verb.bind(item[1]))
		verbs.add_child(button)
	box.add_child(verbs)
	add_child(menu)
	menu.hide()

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
			model.world.pending.clear()
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
				var check := model.world.placement(p)
				if not check["allowed"]:
					_message(check["reason"])
					return
				selected_id = ""
				context = {"kind":"seed","position":[p.x,p.y]}
				menu_info.text = "播下一段声音 · 用途由临街地块决定"
			menu.position = Vector2(clampf(pointer.x-100,12,size.x-370),clampf(pointer.y+22,70,size.y-220))
			menu.show()

func _choose_note(choice: int) -> void:
	midi = choice-12 if low_octave.button_pressed or Input.is_key_pressed(KEY_SHIFT) else choice
	_light_note(choice)
	if context.is_empty(): return
	var operation := context.duplicate(true)
	operation["midi"] = midi
	var result := model.submit(operation)
	if result["accepted"]:
		if operation["kind"] == "seed": ripple_position = Vector2(operation["position"][0],operation["position"][1])
		else: ripple_position = Coupling.position_of(shown_world.by_id[operation["id"]])
		ripple_seconds = 0.6
		_message("这一段会在下一个乐句里落定")
		menu.hide()
	else: _message(result["reason"])

func _verb(verb: String) -> void:
	if verb == "bridge":
		var result := model.submit({"kind":"bridge"})
		_message("桥会在下一乐句连接两岸" if result["accepted"] else str(result["reason"]))
		menu.hide()
		return
	if selected_id.is_empty(): return
	var community: String = shown_world.by_id[selected_id]["community_id"]
	if verb == "solo": model.synth.listener_community = community if model.synth.listener_community != community else ""
	elif verb == "mute": model.synth.muted_communities[community] = not bool(model.synth.muted_communities.get(community,false))
	elif verb == "focus":
		zoom_target = 1.65
		var p := Coupling.position_of(shown_world.by_id[selected_id])-Vector2(16,16)
		pan_target = -Vector2((p.x-p.y)*28,(p.x+p.y)*14)*zoom_target
	menu.hide()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo: return
	if event.keycode in [KEY_SPACE,KEY_ESCAPE,KEY_B,KEY_G,KEY_TAB,KEY_M,KEY_F,KEY_R,KEY_1,KEY_2,KEY_3,KEY_4,KEY_5]: get_viewport().set_input_as_handled()
	if event.keycode == KEY_SPACE and not event.pressed:
		preview_requested = false
		preview_player.stop()
		return
	if not event.pressed: return
	match event.keycode:
		KEY_ESCAPE:
			black = false
			menu.hide()
			model.synth.listener_community = ""
		KEY_B: black = not black
		KEY_G: _verb("bridge")
		KEY_TAB: _verb("solo")
		KEY_M: _verb("mute")
		KEY_F: _verb("focus")
		KEY_R:
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
	if preview_thread != null: return
	var operation := context.duplicate(true)
	if operation.is_empty():
		var p := world_at(pointer)
		if not model.world.placement(p)["allowed"]: return
		operation = {"kind":"seed","position":[p.x,p.y]}
	operation["midi"] = midi
	var frozen := Model.new(model.world.fork(),fixed_gain)
	frozen.next_boundary = model.next_boundary
	frozen.event_cursor = model.event_cursor
	frozen.synth.restore_stages(model.synth.stage_snapshot())
	frozen.synth.gray_enabled = model.synth.gray_enabled
	frozen.synth.gray_from = model.synth.gray_from
	frozen.synth.gray_change_at = model.synth.gray_change_at
	frozen.synth.listener_community = model.synth.listener_community
	frozen.synth.muted_communities = model.synth.muted_communities.duplicate(true)
	frozen.synth.targets = model.synth.targets.duplicate(true)
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
		tooltip.text = "%s · %s · %s\n%s  ·  活力 %.0f\n点击选音   Tab独听社区   F聚焦" % ["律动街" if b["type"] == "commercial" else "长音房",note_name(int(b["current_midi"])),b["form"],shown_world.communities[b["community_id"]]["name"],b["vitality"]]
	elif check["allowed"]:
		tooltip.text = "%s · 街道旁的一段新声音\n点击选音；Shift低八度；按住空格试听" % note_name(midi)
		var lot: String = check["lot_id"]
		hover_seconds = hover_seconds+delta if lot == last_hover_lot else 0.0
		if lot != last_hover_lot: last_hover_lot = lot
		if hover_seconds > 0.18 and hover_seconds < 0.18+delta: _light_note(midi+12 if midi < 48 else midi)
	else: tooltip.text = "街道旁的空地可以播种\n滚轮缩放 · 中键移动 · G建桥 · R重新开始"
	tooltip.position = Vector2(clampf(pointer.x+18,12,size.x-350),clampf(pointer.y+20,70,size.y-100))
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
			sprite.begin_at(int(building["birth_frame"]))
			sprites[id] = sprite
		var sprite: AudioGrowthMask = sprites[id]
		sprite.position = point(Coupling.position_of(building))
		sprite.scale = Vector2.ONE*scale_factor*view_zoom
		sprite.sample_frame(clock.renderer.transport.audible_frame)
		sprite.modulate = Color(1.0,1.0,0.96,1.0)
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
	draw_colored_polygon(_project_polygon(sea,0.0),Color("9bbcc0"))
	draw_colored_polygon(_project_polygon(shown_world.terrain.left_bank),Color("e9e1cb"))
	draw_colored_polygon(_project_polygon(shown_world.terrain.right_bank),Color("e0e5d6"))
	# Contours show the seeded hill without introducing a second terrain model.
	for radius: float in [3.0,5.0,7.0,9.0]:
		var contour := PackedVector2Array()
		for step in range(65):
			var p := Vector2(4,2)+Vector2.from_angle(TAU*step/64.0)*radius
			if shown_world.terrain.land_at(p): contour.append(point(p))
		if contour.size() > 2: draw_polyline(contour,Color(0.54,0.64,0.49,0.16),1.0,true)
	draw_colored_polygon(_project_polygon(shown_world.terrain.water,0.0),Color("78a4ad"))
	var flow := float(clock.renderer.transport.audible_frame)/float(clock.renderer.transport.sample_rate)
	for i in range(18):
		var y := -3.0+fposmod(float(i)*2.1+flow*0.35,38.0)
		var x := shown_world.terrain.river_x(y)
		draw_line(point(Vector2(x-0.3,y),0.0),point(Vector2(x+0.4,y+0.12),0.0),Color(0.8,0.91,0.9,0.28),1.0*view_zoom,true)
	for road in shown_world.roads:
		var width := 0.55 if road["bridge"] else float(Config.load_values()["terrain"]["template_road_half_width"])
		for polygon in Geometry2D.offset_polyline(road["path"],width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
			draw_colored_polygon(_project_polygon(polygon),Color("d3bb93") if road["bridge"] else Color("f1eee0"))
	for lot in shown_world.lots:
		var center := Vector2(lot["center"][0],lot["center"][1])
		if lot["occupant"] != "":
			draw_colored_polygon(_project_polygon(lot["polygon"]),Color(0.68,0.73,0.57,0.2))
		elif pointer_inside and center.distance_to(world_at(pointer)) < 1.0:
			draw_colored_polygon(_project_polygon(lot["polygon"]),Color(0.9,0.94,0.8,0.5))
	if shown_world.buildings.is_empty():
		var target: Dictionary = shown_world.lots[18]
		var p := Vector2(target["center"][0],target["center"][1])
		draw_arc(point(p),13.0*view_zoom,0,TAU,36,Color(0.72,0.8,0.54,0.65),1.7,true)
	if not model.world.pending.is_empty() and model.world.pending["kind"] == "seed":
		var op: Dictionary = model.world.pending
		var p := Vector2(op["position"][0],op["position"][1])
		var color := Color(0.87,0.78,0.53,0.65+0.15*sin(flow*TAU*2.0))
		draw_colored_polygon(_project_polygon(shown_world.building_polygon(p)),color)
		var check := shown_world.placement(p)
		if check["allowed"]:
			var kind := "residential"
			for lot in shown_world.lots:
				if lot["id"] == check["lot_id"]:
					kind = lot["use"]
					break
			var entry: Dictionary = assets[kind]
			var fit := 28.0*sqrt(2.0)*0.8/maxf(float(entry["model_bounds"]["size"][0]),float(entry["model_bounds"]["size"][2]))/float(entry["pixels_per_world"])*view_zoom
			var rect := Rect2(point(p)-Vector2(entry["origin"][0],entry["origin"][1])*fit,textures[kind].get_size()*fit)
			draw_texture_rect(textures[kind],rect,false,Color(1,1,1,0.45))
	if ripple_seconds > 0.0:
		draw_arc(point(ripple_position),(1.0-ripple_seconds/0.6)*55.0*view_zoom,0,TAU,48,Color(0.83,0.74,0.48,ripple_seconds/0.6),1.7,true)
	if not hover_id.is_empty():
		draw_arc(point(Coupling.position_of(shown_world.by_id[hover_id])),18*view_zoom,0,TAU,48,Color(0.62,0.72,0.5,0.8),1.5,true)
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(46,44),"共鸣之城",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("4b6561"))
	draw_string(font,Vector2(47,67),"河谷 · 一座正在演奏的城市",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("758c85"))
	var duration := float(model.phrase_frames)
	var progress := fposmod(float(clock.renderer.transport.audible_frame),duration)/duration
	draw_line(Vector2(48,size.y-32),Vector2(size.x-48,size.y-32),Color(0.59,0.66,0.6,0.25),2.0)
	draw_line(Vector2(48,size.y-32),Vector2(48+(size.x-96)*progress,size.y-32),Color("af9c6a"),3.0)

func diagnostics() -> Dictionary:
	return {"buildings":shown_world.buildings.size(),"planned_communities":shown_world.communities.size(),
		"lots":shown_world.lots.size(),"resonance":shown_world.resonance,"phrase":shown_world.phrase_index,
		"skips":clock.underruns,"audible_frame":clock.renderer.transport.audible_frame,"pending":model.world.pending.duplicate(true),
		"preview_started":preview_started,"seed_hex":model.world.rng.seed_hex}

func _exit_tree() -> void:
	if preview_thread != null: preview_thread.wait_to_finish()
	if is_instance_valid(clock): clock.stop_output()
