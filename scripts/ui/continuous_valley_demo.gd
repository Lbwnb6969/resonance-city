class_name ContinuousValleyDemo
extends Control
const World = preload("res://scripts/world/continuous_world.gd")
const PlanningCard = preload("res://scripts/world/planning_card.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Projection2D = preload("res://scripts/world/world_projection.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const PublicRelocation = preload("res://scripts/world/public_site_relocation.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const Config = preload("res://scripts/world/world_values.gd")
const GrowthSprite = preload("res://scripts/visual/audio_growth_mask.gd")
const Shadows = preload("res://scripts/visual/city_shadow_layer.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const GroundLayer = preload("res://scripts/visual/valley_ground_layer.gd")
const WaterFlow = preload("res://scripts/visual/valley_water_flow.gd")
var scenery := ValleyScenery.new()
var expression := "bright"
var starter := true
var town_starter := false
var expanded_town_starter := false
var terrain_family := "river_valley"
@export var session_persistence := true
var archive_directory := CityArchive.DIRECTORY
var last_saved_event_count := -1
var last_presented_event_count := -1
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
var backdrop: ColorRect
var terrain_layer: Node2D
var city_ground_layer: Node2D
var water_flow: Node2D
var community_label_layer: Node2D
var overlay_key: Array = []
var overlay_candidates: Array[Dictionary] = []
var overlay_communities: Array[Dictionary] = []
var overlay_service: Dictionary = {}
var tooltip: Label
var caption: Label
var menu: PanelContainer
var menu_info: Label
var planning_buttons: Dictionary = {}
var response_button: Button
var planning_guide: PanelContainer
const MusicRules = preload("res://scripts/world/community_music_rules.gd")
var opportunity_key: Array = []
var selected_opportunity: Dictionary = {}
var low_octave: CheckBox
var light_player: AudioStreamPlayer
var preview_player: AudioStreamPlayer
var light_notes: Dictionary = {}
var preview_thread: Thread
var preview_requested := false
var preview_started := false
var preview_skips := 0
var preview_public := false
var preview_context_key: Array = []
var preview_duck_owned := false
var preview_saved_ducking := false
var preview_saved_release := 0
const PublicPreview = preload("res://scripts/world/public_planning_preview.gd")
var fixed_gain := 1.0
var selected_id := ""
var hover_id := ""
var context: Dictionary = {}
var relocation_mode := false
var relocation_site_id := ""
var partial_mode := false
var partial_kind := ""
var partial_reservation_id := ""
var partial_polygon_mode := false
var partial_polygon_points := PackedVector2Array()
var partial_multi_component_mode := false
var partial_polygon_components: Array[PackedVector2Array] = []
var reservation_draw_mode := false
var reservation_draw_points := PackedVector2Array()
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
var selected_landmark_candidate := -1
var building_display_key: Array = []
var building_sync_count := 0
var overlay_rebuild_count := 0
var hit_sort_count := 0
var revealing_buildings: Dictionary = {}
var building_geometry: Dictionary = {}
var shadow_records: Dictionary = {}
var shadow_terrain_key: Array = []
var projected_ground: Dictionary = {}
var ground_terrain_key: Array = []
var ground_phrase_index := -1
var road_draw_key := ""
var road_draw_polygons: Array[Dictionary] = []
var ground_patches: Array[PackedVector2Array] = []
var ground_contours: Array[PackedVector2Array] = []
var frame_profile: Dictionary = {}
var frame_peaks: Dictionary = {}
var hit_order: Array = []
var hit_order_key: Array = []
var hover_placement_key: Array = []
var hover_placement: Dictionary = {}

func _profile_frame(stage: String, started: int) -> void:
	var elapsed := float(Time.get_ticks_usec()-started)/1000.0
	frame_profile[stage] = elapsed
	frame_peaks[stage] = maxf(float(frame_peaks.get(stage,0.0)),elapsed)

func _ready() -> void:
	if "--isolated-session" in OS.get_cmdline_user_args(): session_persistence = false
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
	backdrop = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.z_index = -40
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.color = Color("ecebe2")
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	terrain_layer = GroundLayer.new()
	terrain_layer.name = "RetainedTerrain"
	terrain_layer.z_index = -30
	add_child(terrain_layer)
	water_flow = WaterFlow.new()
	water_flow.name = "WaterFlow"
	water_flow.z_index = -29
	add_child(water_flow)
	city_ground_layer = GroundLayer.new()
	city_ground_layer.name = "RetainedCityGround"
	city_ground_layer.role = "urban"
	city_ground_layer.z_index = -28
	add_child(city_ground_layer)
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
	community_label_layer = preload("res://scripts/visual/community_label_layer.gd").new()
	community_label_layer.name = "CommunityNames"
	community_label_layer.z_index = 50
	add_child(community_label_layer)
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
	planning_guide = preload("res://scripts/ui/planning_guide.gd").new()
	add_child(planning_guide)
	planning_guide.setup(self)
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

func _start_world(saved: Dictionary = {}, example_world: ContinuousWorld = null) -> void:
	_stop_preview()
	clock.stop_output()
	for sprite in sprites.values(): sprite.queue_free()
	sprites.clear()
	if saved.is_empty():
		var world := example_world if example_world != null else World.new("2026100900000062",true,terrain_family)
		if example_world == null:
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
	reservation_draw_mode = false
	reservation_draw_points.clear()
	partial_mode = false
	partial_kind = ""
	partial_reservation_id = ""
	partial_polygon_mode = false
	partial_polygon_points.clear()
	partial_multi_component_mode = false
	partial_polygon_components.clear()
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
	# Destination and route queries belong to city preparation, before output starts.
	clock.renderer = Renderer.new()
	if saved.has("renderer"):
		clock.renderer.restore(saved["renderer"])
		clock.renderer.transport.audible_frame = float(clock.renderer.transport.rendered_frames)
	if example_world != null:
		var start_frame := shown_world.phrase_index*int(shown_world.cfg["timing"]["phrase_frames"])
		clock.renderer.transport.rendered_frames = start_frame
		clock.renderer.transport.audible_frame = float(start_frame)
		_home_city()
		view_zoom = zoom_target
		pan = pan_target
	_sync_buildings()
	scenery.sync(self)
	last_saved_event_count = model.world.events.size()
	last_presented_event_count = model.world.events.size()
	last_checkpoint_phrase = model.world.phrase_index
	selected_landmark_candidate = -1
	planning_guide.reset_for_city()
	_message("%s · %d栋 · %d个社区" % [shown_world.terrain_title(),shown_world.buildings.size(),shown_world.active_community_count()] if not saved.is_empty() else ("%s · 林荫交响 · 完整河谷起点，可继续生长" % shown_world.terrain_title() if town_starter else ("%s · 晴岸合奏 · 18栋制作示例" % shown_world.terrain_title() if starter and expression == "bright" else ("%s · 深流慢板 · 低音与留白" % shown_world.terrain_title() if starter else "%s · 空地开局 · 点击街边播下第一段声音" % shown_world.terrain_title()))))

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
	menu_info.custom_minimum_size.x = 560
	menu_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	for item in [["独听社区","solo"],["静音社区","mute"],["聚焦","focus"],["跨河应答","response"],["规划社区 · P","planning"]]:
		var button := Button.new()
		button.text = item[0]
		if item[1] == "response":
			response_button = button
			button.tooltip_text = "全城唯一跨河应答槽；切换在下一拍生效"
		button.pressed.connect(_verb.bind(item[1]))
		verbs.add_child(button)
	box.add_child(verbs)
	var public_row := HBoxContainer.new()
	for item in [["建公园","park"],["文化设施","civic"],["局部公园","partial_park"],["局部文化馆","partial_civic"],["自由局部公园","free_partial_park"],["自由局部文化馆","free_partial_civic"],["自由分块公园","free_multi_partial_park"],["自由分块文化馆","free_multi_partial_civic"],["搬迁公共设施","relocate_public"],["留地","reserve"],["自由留地","free_reserve"],["释放留地","release_reservation"],["连接两岸","bridge"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(_verb.bind(item[1]))
		public_row.add_child(button)
		planning_buttons[item[1]] = button
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
	var regional_button := Button.new()
	regional_button.text = "三河段大城 · Shift+E"
	regional_button.tooltip_text = "进入1500栋以上自然成长样本；可继续成长、调音和规划公共空间，当前作品先保存"
	regional_button.pressed.connect(_start_regional_town)
	box.add_child(regional_button)
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

func _start_regional_town() -> void:
	_save_before_switch()
	starter = true
	town_starter = true
	expanded_town_starter = true
	expression = "bright"
	_start_world({},World.regional_sample())
	clock.start_output(model._mix_frame,{},clock.renderer.snapshot())
	_message("三河段大城 · %d栋 · %d个社区 · 滚轮放大查看街坊，H看全城" % [shown_world.buildings.size(),shown_world.active_community_count()])

func _home_city() -> void:
	zoom_target = 0.88
	pan_target = Vector2(0,70)
	if int(shown_world.cfg["city"].get("regional_count",1)) == 1: return
	var low := float(shown_world.terrain.cfg["template_land_min"])
	var high_x := float(shown_world.terrain.cfg["template_land_max"])
	var high_y := float(shown_world.terrain.cfg["template_land_max_y"])
	var bounds := Rect2(Projection2D.to_screen(Vector2(low,low)-Vector2(16,16),Vector2.ZERO,1.0),Vector2.ZERO)
	for p: Vector2 in [Vector2(low,high_y),Vector2(high_x,low),Vector2(high_x,high_y)]:
		bounds = bounds.expand(Projection2D.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0))
	zoom_target = minf(0.88,minf((size.x-120.0)/bounds.size.x,(size.y-180.0)/bounds.size.y))
	pan_target = -bounds.get_center()*zoom_target+Vector2(0,30)

func _start_expanded_town() -> void:
	_save_before_switch()
	starter = true
	town_starter = true
	expanded_town_starter = true
	expression = "bright"
	_start_world()
	clock.start_output(model._mix_frame,{})
	_message("多中心街坊 · "+str(shown_world.active_community_count())+"个社区 · "+str(shown_world.buildings.size())+"栋起点")

func _start_town() -> void:
	_save_before_switch()
	starter = true
	town_starter = true
	expanded_town_starter = false
	expression = "bright"
	_start_world()
	clock.start_output(model._mix_frame,{})

func _cancel_preview_playback() -> void:
	preview_requested = false
	preview_started = false
	if is_instance_valid(preview_player): preview_player.stop()
	if preview_duck_owned and model != null:
		model.synth.ducking = preview_saved_ducking
		model.synth.duck_release_at = preview_saved_release
	preview_duck_owned = false

func _stop_preview() -> void:
	_cancel_preview_playback()
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
	if not projected_ground.has(height): projected_ground[height] = {}
	var cache: Dictionary = projected_ground[height]
	if not cache.has(polygon):
		var result := PackedVector2Array()
		for p in polygon:
			var h := shown_world.terrain.height_at(p) if height < 0.0 else height
			result.append(Projection2D.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),h))
		cache[polygon] = result
	return Transform2D(Vector2.RIGHT*view_zoom,Vector2.DOWN*view_zoom,Vector2(size.x*0.5,size.y*0.52)+pan)*PackedVector2Array(cache[polygon])

func _prepare_ground() -> void:
	if ground_phrase_index != shown_world.phrase_index:
		ground_phrase_index = shown_world.phrase_index
		projected_ground.clear()
	var terrain_key := [shown_world.terrain.noise_seed,shown_world.terrain.river_phase,shown_world.terrain.family]
	if ground_terrain_key != terrain_key:
		ground_terrain_key = terrain_key
		projected_ground.clear()
		ground_patches.clear()
		ground_contours.clear()
		for i in range(34):
			var p := Vector2(-1.0+float((i*37)%330)/10.0,-1.5+float((i*67)%330)/10.0)
			if not shown_world.terrain.land_at(p): continue
			var ring := PackedVector2Array()
			for j in range(24):
				var q := p+Vector2(cos(TAU*j/24)*1.1,sin(TAU*j/24)*0.75)
				if shown_world.terrain.land_at(q): ring.append(q)
			if ring.size() == 24: ground_patches.append(ring)
		for radius: float in [3.0,5.0,7.0,9.0]:
			var contour := PackedVector2Array()
			for step in range(65):
				var p := Vector2(4,2)+Vector2.from_angle(TAU*step/64.0)*radius
				if shown_world.terrain.land_at(p): contour.append(p)
			if contour.size() > 2: ground_contours.append(contour)
	if road_draw_key == shown_world.network.topology: return
	road_draw_key = shown_world.network.topology
	road_draw_polygons.clear()
	# Polygon projections depend on mutable occupancy/derived geometry too;
	# prune those entries at each topology or city phrase instead of keeping history.
	projected_ground.clear()
	for road in shown_world.roads:
		var width := 0.55 if road["bridge"] else (float(shown_world.cfg["city"]["branch_road_half_width"]) if road.get("kind","") == "branch" else float(shown_world.cfg["terrain"]["template_road_half_width"]))
		for polygon in Geometry2D.offset_polyline(road["path"],width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
			road_draw_polygons.append({"polygon":polygon,"color":Color("d3bb93") if road["bridge"] else Color("f1eee0")})

func _shown_city_key() -> Array:
	return [model.presentation_token,shown_world.phrase_index]

func _hit(screen: Vector2) -> String:
	var key := _shown_city_key()+[sprites.size()]
	if hit_order_key != key:
		hit_order_key = key
		hit_sort_count += 1
		hit_order = sprites.keys()
		hit_order.sort_custom(func(a: String,b: String) -> bool: return sprites[a].position.y > sprites[b].position.y)
	for id in hit_order:
		var sprite: AudioGrowthMask = sprites[id]
		if sprite.progress <= 0.0: continue
		var local := sprite.to_local(screen)-sprite.offset
		var image: Image = asset_images[shown_world.by_id[id]["type"]]
		if local.x >= 0 and local.y >= 0 and local.x < image.get_width() and local.y < image.get_height():
			if image.get_pixelv(Vector2i(local)).a > 0.1 and local.y/image.get_height() >= 1.0-sprite.progress: return id
	return ""

func _landmark_radius(index: int) -> float:
	return 1.35 if index == 0 else (1.15 if index == 1 else 1.55)

func _landmark_site_clear(position: Vector2, radius: float, reservation_id: String = "") -> bool:
	return shown_world != null and shown_world.landmark_site_clear(position,radius,reservation_id)

func _landmark_anchor_positions(index: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if index == 0 or index == 1:
		var wanted := "央" if index == 0 else "腔"
		for building in shown_world.buildings:
			if str(building.get("form","")) == wanted:
				positions.append(Coupling.position_of(building))
	if index == 2:
		var community_ids: Array = shown_world.communities.keys()
		community_ids.sort()
		for community_id in community_ids:
			var community: Dictionary = shown_world.communities[community_id]
			if community["members"].size() < 2: continue
			var center := Vector2.ZERO
			for id in community["members"]:
				if shown_world.by_id.has(id): center += Coupling.position_of(shown_world.by_id[id])
			center /= float(community["members"].size())
			positions.append(center)
	for center in shown_world.centers:
		positions.append(Vector2(float(center["position"][0]),float(center["position"][1])))
	for lot in shown_world.lots:
		positions.append(Vector2(float(lot["center"][0]),float(lot["center"][1])))
	return positions

func _landmark_preview_positions(index: int) -> Array[Dictionary]:
	var candidates := _landmark_candidates()
	if index < 0 or index >= candidates.size() or (not bool(candidates[index]["ready"]) and not bool(candidates[index].get("awakened",false))) or bool(candidates[index].get("built",false)): return []
	var radius := _landmark_radius(index)
	var offsets := [Vector2.ZERO,Vector2(0.8,0.0),Vector2(-0.8,0.0),Vector2(0.0,0.8),Vector2(0.0,-0.8),Vector2(1.5,0.0),Vector2(-1.5,0.0),Vector2(0.0,1.5),Vector2(0.0,-1.5)]
	# A reserved parcel can become a landmark without losing its untouched
	# remainder. Prefer its real center so the preview and commit share the same
	# source identity; ordinary city anchors remain the fallback.
	for reservation in shown_world.planning_reservations:
		var raw: Array = reservation.get("position",[])
		if raw.size() != 2: continue
		var reservation_id := str(reservation.get("reservation_id",reservation.get("id","")))
		for offset in offsets:
			var candidate_position := Vector2(float(raw[0]),float(raw[1]))+Vector2(offset)
			if not SpatialPlanning.reservation_contains_disc(reservation,candidate_position,radius): continue
			if _landmark_site_clear(candidate_position,radius,reservation_id):
				return [{"position":[candidate_position.x,candidate_position.y],"radius":radius,"candidate":str(candidates[index]["name"]),"reservation_id":reservation_id}]
	for position in _landmark_anchor_positions(index):
		for offset in offsets:
			var candidate_position: Vector2 = position+Vector2(offset)
			if _landmark_site_clear(candidate_position,radius):
				return [{"position":[candidate_position.x,candidate_position.y],"radius":radius,"candidate":str(candidates[index]["name"])}]
	return []

func _landmark_candidate_at(screen: Vector2) -> int:
	var candidates := _landmark_candidates()
	if candidates.is_empty() or screen.x < 20.0 or screen.x > 360.0: return -1
	for i in range(candidates.size()):
		var y := 122.0+float(i)*28.0
		if screen.y >= y-18.0 and screen.y <= y+17.0: return i
	return -1

func _select_landmark_candidate(index: int) -> void:
	var candidates := _landmark_candidates()
	if index < 0 or index >= candidates.size(): return
	selected_landmark_candidate = index
	var candidate: Dictionary = candidates[index]
	if bool(candidate.get("awakened",false)):
		var sites := _landmark_preview_positions(index)
		_message(str(candidate["name"])+" · 场地预影已显示 · Enter确认" if not sites.is_empty() else str(candidate["name"])+" · 觉醒已完成，但暂未找到连续陆地")
	elif bool(candidate["ready"]):
		var sites := _landmark_preview_positions(index)
		_message(str(candidate["name"])+" · 条件满足%d/2句 · 预影已显示，继续保持两句后可确认" % int(candidate.get("streak",0)) if not sites.is_empty() else str(candidate["name"])+" · 条件满足，但暂未找到连续陆地")
	else:
		_message(str(candidate["name"])+" · "+str(candidate["condition"])+" · 觉醒%d/2句" % int(candidate.get("streak",0)))

func _confirm_landmark() -> void:
	var candidates := _landmark_candidates()
	if selected_landmark_candidate < 0 or selected_landmark_candidate >= candidates.size(): return
	var candidate: Dictionary = candidates[selected_landmark_candidate]
	if bool(candidate.get("built",false)):
		_message(str(candidate["name"])+"已经落成")
		return
	if not bool(candidate.get("awakened",false)):
		_message(str(candidate["name"])+"还需连续两句满足条件 · 当前%d/2" % int(candidate.get("streak",0)))
		return
	var sites := _landmark_preview_positions(selected_landmark_candidate)
	if sites.is_empty():
		_message(str(candidate["name"])+"没有可用的连续陆地预影")
		return
	var site: Dictionary = sites[0]
	var operation := {"kind":"landmark","name":str(candidate["name"]),"position":site["position"],"radius":site["radius"]}
	if site.has("reservation_id"): operation["source_reservation_id"] = site["reservation_id"]
	var result := model.submit(operation)
	if result["accepted"]:
		_message(str(candidate["name"])+"已确认 · 下一句开始分段落成")
	else:
		_message(result["reason"])

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
			zoom_target = clampf(zoom_target*(1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/1.12),0.18 if int(shown_world.cfg["city"].get("regional_count",1)) > 1 else 0.55,1.9)
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			reservation_draw_mode = false
			reservation_draw_points.clear()
			partial_polygon_mode = false
			partial_polygon_points.clear()
			partial_multi_component_mode = false
			partial_polygon_components.clear()
			relocation_mode = false
			relocation_site_id = ""
			partial_mode = false
			partial_kind = ""
			partial_reservation_id = ""
			model.cancel_pending()
			menu.hide()
			planning_guide.hide_tool()
			context.clear()
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not black:
			if reservation_draw_mode:
				_append_reservation_draw_point(world_at(pointer))
				return
			if partial_polygon_mode:
				_append_partial_polygon_point(world_at(pointer))
				return
			if relocation_mode:
				_submit_relocation_at(world_at(pointer))
				return
			if partial_mode:
				_submit_partial_at(world_at(pointer))
				return
			if planning_guide.map_click(world_at(pointer),Input.is_key_pressed(KEY_SHIFT)): return
			var landmark_index := _landmark_candidate_at(pointer)
			if landmark_index >= 0:
				_select_landmark_candidate(landmark_index)
				menu.hide()
				return
			var id := _hit(pointer)
			if not id.is_empty():
				selected_id = id
				context = {"kind":"retune","id":id}
				menu_info.text = "给这栋建筑换一个音"
			else:
				var p := world_at(pointer)
				var reservation := shown_world.planning_at(p)
				if not reservation.is_empty():
					context = {"kind":"reservation","id":reservation["reservation_id"],"position":reservation["position"].duplicate()}
					selected_id = ""
					menu_info.text = "你留下的空地 · 可释放、整片营造或局部兑现"
					_planning_menu()
					_show_context_menu()
					return
				var site := shown_world.public_at(p)
				if not site.is_empty():
					context = {"kind":site["kind"],"id":site["id"]}
					if not bool(site["active"]): context["position"] = site["position"].duplicate()
					_planning_menu()
					selected_id = ""
					menu_info.text = site["name"]+(" · 点击公共设施扩容" if site["active"] and site["kind"] == "civic" else " · 点击下方营造")
					_show_context_menu()
					return
				var check := model.world.placement(p)
				if not check["allowed"]:
					_message(check["reason"])
					return
				selected_id = ""
				context = {"kind":"seed","position":[p.x,p.y]}
				menu_info.text = "播种声音 · "+str(check["preview"])+"\n也可选定这片地营造公共空间"
			_planning_menu()
			_show_context_menu()

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

func _show_context_menu() -> void:
	opportunity_key.clear()
	_update_selected_opportunity()
	_planning_menu()
	menu.size = menu.get_combined_minimum_size()
	menu.position = Vector2(clampf(pointer.x-100,12,maxf(12,size.x-menu.size.x-12)),clampf(pointer.y+22,70,maxf(70,size.y-menu.size.y-12)))
	menu.show()

func _update_selected_opportunity() -> void:
	if context.get("kind","") != "retune" or not shown_world.by_id.has(selected_id): return
	var current_score := model.audible_score()
	var key: Array = [model.presentation_token,shown_world.phrase_index,selected_id,hash(current_score),hash(model.audible_pitches())]
	if key == opportunity_key: return
	opportunity_key = key
	var cid := str(shown_world.by_id[selected_id]["community_id"])
	selected_opportunity = MusicRules.opportunity(shown_world,cid,current_score)
	var notes := shown_world.community_theme(cid,model.audible_pitches())
	var displayed: Array[String] = []
	for pitch in notes.slice(0,8): displayed.append(note_name(int(pitch)))
	var opportunity_lines := _opportunity_lines(selected_opportunity)
	var next_text := str(selected_opportunity.get("next",""))
	if not opportunity_lines.is_empty(): next_text = "\n".join(opportunity_lines)
	menu_info.text = "%s · %s\n音型 · %s%s\n%s\n%s" % [
		shown_world.communities[cid]["name"],str(selected_opportunity.get("current","当前以长音融入合奏")),"  ".join(displayed),
		" …" if notes.size() > 8 else "",next_text,
		"公园给主题留白" if selected_opportunity["facility"]["park"] else ("文化馆实际服务%d栋" % int(selected_opportunity["facility"]["served"]) if selected_opportunity["facility"]["civic"] else "可自由选择留白、文化或商业布局")]
	menu_info.text += "\n跨河应答 · "+_response_state_label()+"\n点击音级改编 · F聚焦主题 · Tab独听 · Esc回合奏"

func _opportunity_lines(opportunity: Dictionary) -> Array[String]:
	var rows_variant: Variant = opportunity.get("opportunities",[])
	if not rows_variant is Array: return []
	var lines: Array[String] = []
	for raw in rows_variant:
		if not raw is Dictionary: continue
		var item: Dictionary = raw
		var title := str(item.get("title",item.get("name","")))
		if title.is_empty():
			var rule_id := str(item.get("rule_id",""))
			title = {"P11-BASS":"低音","P11-BASS-EXPRESSION":"低音表达","P11-RHYTHM":"商业律动","P11-COMMERCIAL-RHYTHM":"商业律动","P11-RESPONSE":"跨岸应答","P11-RIVER-RESPONSE":"跨岸应答"}.get(rule_id,"下一步机会")
		var parts: Array[String] = []
		if item.has("qualified"): parts.append("已就绪" if bool(item["qualified"]) else "待条件")
		var current := str(item.get("current","")).replace("\n","；")
		var next := str(item.get("next","")).replace("\n","；")
		if not current.is_empty(): parts.append("现 "+current)
		if not next.is_empty(): parts.append("下 "+next)
		if parts.is_empty(): lines.append(title)
		else: lines.append(title+" · "+" · ".join(parts))
	return lines

func _pending_response() -> Dictionary:
	var pending: Dictionary = {}
	if model == null: return pending
	for event in model.sound_events:
		if str(event.get("kind", "")) == "response": pending = event
	return pending

func _response_state_label() -> String:
	if model == null: return "状态未知"
	var current_enabled := bool(model.synth.response_enabled)
	var enabled := current_enabled
	var pending := _pending_response()
	if not pending.is_empty():
		enabled = bool(pending.get("enabled", enabled))
		var frames_left := int(pending.get("sound_frame", 0))-int(clock.renderer.transport.audible_frame)
		if frames_left > 0:
			var rate := maxi(1, int(clock.renderer.transport.sample_rate))
			var seconds := float(frames_left)/float(rate)
			return "当前%s · 下一拍%s（%.1fs）" % ["开启" if current_enabled else "关闭", "开启" if enabled else "关闭", seconds]
	return "开启" if current_enabled else "关闭"

func _response_button_text() -> String:
	if model == null: return "跨河应答"
	var pending := _pending_response()
	if not pending.is_empty():
		return "跨河应答 · 下一拍%s" % ("开启" if bool(pending.get("enabled",true)) else "关闭")
	return "跨河应答 · "+("开" if bool(model.synth.response_enabled) else "关")

func _planning_menu() -> void:
	var candidate: Dictionary = {}
	if context.has("position"):
		candidate = model.world.planning_candidate(Vector2(float(context["position"][0]),float(context["position"][1])))
	var selectable := not candidate.is_empty() and bool(candidate.get("allowed",false))
	planning_buttons["reserve"].disabled = not selectable or candidate.has("reservation_id") or candidate.has("public_id")
	planning_buttons["free_reserve"].disabled = false
	planning_buttons["release_reservation"].disabled = context.get("kind","") != "reservation"
	planning_buttons["partial_park"].disabled = context.get("kind","") != "reservation"
	planning_buttons["partial_civic"].disabled = context.get("kind","") != "reservation"
	planning_buttons["free_partial_park"].disabled = context.get("kind","") != "reservation"
	planning_buttons["free_partial_civic"].disabled = context.get("kind","") != "reservation"
	planning_buttons["free_multi_partial_park"].disabled = context.get("kind","") != "reservation"
	planning_buttons["free_multi_partial_civic"].disabled = context.get("kind","") != "reservation"
	for verb in ["park","civic"]:
		var existing := false
		for site in model.world.public_sites:
			if str(site["id"]) == str(context.get("id","")) and bool(site["active"]) and verb == "civic" and str(site["kind"]) == "civic":
				existing = int(site.get("service_level",1)) < 3
		planning_buttons[verb].disabled = not selectable and not existing
	var active_public := false
	for site in model.world.public_sites:
		if str(site.get("id","")) == str(context.get("id","")):
			active_public = bool(site.get("active",false)) and str(context.get("kind","")) in ["park","civic"]
	planning_buttons["relocate_public"].disabled = not active_public

func _submit_relocation_at(target: Vector2) -> void:
	if relocation_site_id.is_empty():
		relocation_mode = false
		return
	var preview: Dictionary = PublicRelocation.preview(model.world,relocation_site_id,target)
	if not bool(preview.get("accepted",false)):
		_message(str(preview.get("reason","这片空间不可用于搬迁")))
		return
	var result: Dictionary = model.submit({"kind":"relocate_public","id":relocation_site_id,"position":[target.x,target.y],"source_revision":str(preview.get("source_revision",""))})
	if bool(result.get("accepted",false)):
		_message("搬迁预影已确认 · 下一句转移道路入口与公共服务")
		relocation_mode = false
		relocation_site_id = ""
		context.clear()
		ripple_position = target
		ripple_seconds = 0.6
		menu.hide()
	else:
		_message(str(result.get("reason","搬迁未能排入下一句")))

func _submit_partial_at(target: Vector2) -> void:
	if partial_reservation_id.is_empty() or partial_kind.is_empty():
		partial_mode = false
		return
	var preview: Dictionary = PartialPublic.preview(model.world,partial_reservation_id,partial_kind,target)
	if not bool(preview.get("accepted",false)):
		_message(str(preview.get("reason","局部公共空间不可用")))
		return
	var result := model.submit({"kind":partial_kind,"partial":true,"source_reservation_id":partial_reservation_id,"position":[target.x,target.y],"source_revision":str(preview.get("source_revision",""))})
	if bool(result.get("accepted",false)):
		_message(("局部公园" if partial_kind == "park" else "局部文化馆")+"已确认 · 剩余留地保留到下一次规划")
		partial_mode = false
		partial_kind = ""
		partial_reservation_id = ""
		context.clear()
		ripple_position = target
		ripple_seconds = 0.6
		menu.hide()
	else:
		_message(str(result.get("reason","局部兑现未能排入下一句")))

func _partial_polygon_center(polygon: PackedVector2Array) -> Vector2:
	var center := Vector2.ZERO
	for vertex in polygon: center += vertex
	return center/float(maxi(1,polygon.size()))

func _partial_polygon_area(polygon: PackedVector2Array) -> float:
	if polygon.size() < 3: return 0.0
	var twice := 0.0
	for index in range(polygon.size()):
		var a: Vector2 = polygon[index]
		var b: Vector2 = polygon[(index+1)%polygon.size()]
		twice += a.x*b.y-b.x*a.y
	return absf(twice)*0.5

func _partial_position_from_preview(preview: Dictionary, fallback: Vector2) -> Vector2:
	var raw: Variant = preview.get("target_position",[])
	if raw is Vector2: return raw
	if raw is Array and raw.size() == 2: return Vector2(float(raw[0]),float(raw[1]))
	return fallback

func _partial_footprint_preview(polygon: PackedVector2Array) -> Dictionary:
	if partial_reservation_id.is_empty() or partial_kind.is_empty() or polygon.size() < 3: return {}
	if partial_multi_component_mode:
		var components := partial_polygon_components.duplicate(true)
		components.append(polygon.duplicate())
		return PartialPublic.preview_footprints(shown_world,partial_reservation_id,partial_kind,components)
	return PartialPublic.preview_footprint(shown_world,partial_reservation_id,partial_kind,polygon)

func _partial_preview_for_draw() -> Dictionary:
	if partial_multi_component_mode:
		var components := partial_polygon_components.duplicate(true)
		if partial_polygon_points.size() >= 3: components.append(partial_polygon_points.duplicate())
		if components.is_empty(): return {}
		return PartialPublic.preview_footprints(shown_world,partial_reservation_id,partial_kind,components)
	return _partial_footprint_preview(partial_polygon_points)

func _partial_preview_polygons(preview: Dictionary) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var raw_components: Variant = preview.get("target_polygons",preview.get("footprint_components",[]))
	if raw_components is Array:
		for raw in raw_components:
			var polygon := SpatialPlanning.normalize_polygon(raw)
			if polygon.size() >= 3: result.append(polygon)
	if result.is_empty() and preview.has("target_polygon"):
		var legacy := SpatialPlanning.normalize_polygon(preview["target_polygon"])
		if legacy.size() >= 3: result.append(legacy)
	return result

func _append_partial_polygon_point(world_position: Vector2) -> void:
	if not partial_polygon_points.is_empty() and partial_polygon_points[partial_polygon_points.size()-1].distance_to(world_position) < 0.35:
		_message("这个点离上一个点太近，请拉开边界")
		return
	if partial_polygon_points.size() >= 3 and partial_polygon_points[0].distance_to(world_position) < 0.35:
		_message("目标足迹已接近起点 · 按 Enter 闭合并预览")
		return
	partial_polygon_points.append(world_position)
	var action := "按 Tab 完成这一块，Enter 提交全部" if partial_multi_component_mode else "至少三点后按 Enter 确认"
	var title := ("自由分块公园" if partial_kind == "park" else "自由分块文化馆") if partial_multi_component_mode else ("自由局部公园" if partial_kind == "park" else "自由局部文化馆")
	_message(title+" · 已选%d点 · %s；Esc/右键取消" % [partial_polygon_points.size(),action])

func _finish_partial_component() -> void:
	if not partial_multi_component_mode: return
	if partial_polygon_points.size() < 3:
		_message("当前组件至少需要三个点")
		return
	if _partial_polygon_area(partial_polygon_points) < 0.25:
		_message("当前组件范围太小，请拉开边界")
		return
	partial_polygon_components.append(partial_polygon_points.duplicate())
	partial_polygon_points.clear()
	_message("已完成第%d块 · 继续点击绘制下一块，按 Tab 收束，Enter 提交全部" % partial_polygon_components.size())

func _submit_partial_polygon() -> void:
	if not partial_polygon_mode: return
	if partial_multi_component_mode:
		if partial_polygon_points.size() > 0 and partial_polygon_points.size() < 3:
			_message("当前组件至少需要三个点 · 继续绘制或按 Esc 取消")
			return
		if partial_polygon_points.size() >= 3:
			_finish_partial_component()
	if partial_polygon_components.is_empty() and partial_polygon_points.size() < 3:
		_message("自由局部目标至少需要三个点")
		return
	var polygon := partial_polygon_points.duplicate() if partial_polygon_components.is_empty() else partial_polygon_components[0].duplicate()
	var components: Array[PackedVector2Array] = partial_polygon_components.duplicate(true)
	if not partial_polygon_components.is_empty():
		# _finish_partial_component() already moved the active component.
		polygon = components[0].duplicate()
	else:
		components.append(polygon.duplicate())
	var fallback := _partial_polygon_center(polygon)
	var preview := PartialPublic.preview_footprints(shown_world,partial_reservation_id,partial_kind,components) if partial_multi_component_mode else _partial_footprint_preview(polygon)
	if not bool(preview.get("accepted",false)):
		_message(str(preview.get("reason","这片目标足迹暂时不能兑现")))
		return
	var target_position := _partial_position_from_preview(preview,fallback)
	var operation := {"kind":partial_kind,"partial":true,"source_reservation_id":partial_reservation_id,
		"target_polygon":polygon,"target_position":[target_position.x,target_position.y],"position":[target_position.x,target_position.y],
		"source_revision":str(preview.get("source_revision",""))}
	if partial_multi_component_mode:
		operation["target_polygons"] = components.duplicate(true)
		operation["footprint_components"] = components.duplicate(true)
	var result: Dictionary = model.submit(operation)
	if bool(result.get("accepted",false)):
		var title := ("自由分块公园" if partial_kind == "park" else "自由分块文化馆") if partial_multi_component_mode else ("自由局部公园" if partial_kind == "park" else "自由局部文化馆")
		_message(title+"已确认 · 剩余留地保留到下一次规划")
		partial_polygon_mode = false
		partial_polygon_points.clear()
		partial_multi_component_mode = false
		partial_polygon_components.clear()
		partial_kind = ""
		partial_reservation_id = ""
		context.clear()
		ripple_position = target_position
		ripple_seconds = 0.6
		menu.hide()
	else:
		_message(str(result.get("reason","自由局部兑现未能排入下一句")))

func _reservation_draw_center() -> Vector2:
	var center := Vector2.ZERO
	for p in reservation_draw_points: center += p
	return center/float(maxi(1,reservation_draw_points.size()))

func _reservation_draw_area() -> float:
	if reservation_draw_points.size() < 3: return 0.0
	var twice := 0.0
	for i in range(reservation_draw_points.size()):
		var a: Vector2 = reservation_draw_points[i]
		var b: Vector2 = reservation_draw_points[(i+1)%reservation_draw_points.size()]
		twice += a.x*b.y-b.x*a.y
	return absf(twice)*0.5

func _append_reservation_draw_point(world_position: Vector2) -> void:
	if not reservation_draw_points.is_empty() and reservation_draw_points[reservation_draw_points.size()-1].distance_to(world_position) < 0.35:
		_message("这个点离上一个点太近，请拉开边界")
		return
	reservation_draw_points.append(world_position)
	_message("自由留地 · 已选%d点 · 继续点击，至少三点后按 Enter 确认；Esc/右键取消" % reservation_draw_points.size())

func _submit_free_reservation() -> void:
	if not reservation_draw_mode: return
	if reservation_draw_points.size() < 3:
		_message("自由留地至少需要三个点")
		return
	if _reservation_draw_area() < 0.25:
		_message("自由留地范围太小，请拉开边界")
		return
	var polygon := reservation_draw_points.duplicate()
	var center := _reservation_draw_center()
	var result: Dictionary = model.submit({"kind":"reserve","position":[center.x,center.y],"polygon":polygon})
	if bool(result.get("accepted",false)):
		_message("自由留地已确认 · 下一句保留这片连续空间")
		reservation_draw_mode = false
		reservation_draw_points.clear()
		context.clear()
		menu.hide()
	else:
		_message(str(result.get("reason","这片范围暂时不能留地")))

func _verb(verb: String) -> void:
	if verb == "planning":
		planning_guide.open_tool()
		return
	if verb == "free_reserve":
		partial_polygon_mode = false
		partial_polygon_points.clear()
		partial_multi_component_mode = false
		partial_polygon_components.clear()
		reservation_draw_mode = true
		reservation_draw_points.clear()
		menu.hide()
		_message("自由留地预影开启 · 左键逐点绘制，至少三点后按 Enter 确认；Esc/右键取消")
		return
	if verb in ["free_partial_park","free_partial_civic"]:
		if context.get("kind","") != "reservation" or str(context.get("id","")).is_empty():
			_message("先点选一片留地，再选择自由局部兑现")
			return
		partial_kind = "park" if verb == "free_partial_park" else "civic"
		partial_reservation_id = str(context["id"])
		reservation_draw_mode = false
		reservation_draw_points.clear()
		partial_polygon_mode = true
		partial_polygon_points.clear()
		partial_multi_component_mode = false
		partial_polygon_components.clear()
		partial_mode = false
		menu.hide()
		_message(("自由局部公园" if partial_kind == "park" else "自由局部文化馆")+"预影开启 · 左键逐点绘制目标足迹，至少三点后按 Enter 确认；Esc/右键取消")
		return
	if verb in ["free_multi_partial_park","free_multi_partial_civic"]:
		if context.get("kind","") != "reservation" or str(context.get("id","")).is_empty():
			_message("先点选一片留地，再选择自由分块兑现")
			return
		partial_kind = "park" if verb == "free_multi_partial_park" else "civic"
		partial_reservation_id = str(context["id"])
		reservation_draw_mode = false
		reservation_draw_points.clear()
		partial_polygon_mode = true
		partial_multi_component_mode = true
		partial_polygon_points.clear()
		partial_polygon_components.clear()
		partial_mode = false
		menu.hide()
		_message(("自由分块公园" if partial_kind == "park" else "自由分块文化馆")+"预影开启 · 左键逐点绘制；Tab完成当前块，Enter提交全部，Esc/右键取消")
		return
	if verb in ["reserve","release_reservation"] or (verb in ["park","civic"] and context.has("position")):
		var operation := {"kind":verb}
		if verb == "release_reservation": operation["id"] = context.get("id","")
		elif context.has("position"): operation["position"] = context["position"].duplicate()
		else:
			_message("先点选一片空地")
			return
		var result := model.submit(operation)
		var labels := {"reserve":"这片空地会在下一句保留","release_reservation":"下一句释放留地","park":"公园会在选中位置落成","civic":"文化设施会在选中位置落成"}
		_message(labels[verb] if result["accepted"] else str(result["reason"]))
		if result["accepted"]: menu.hide()
		return
	if verb in ["partial_park","partial_civic"]:
		if context.get("kind","") != "reservation" or str(context.get("id","")).is_empty():
			_message("先点选一片留地，再选择局部兑现")
			return
		partial_kind = "park" if verb == "partial_park" else "civic"
		partial_reservation_id = str(context["id"])
		partial_polygon_mode = false
		partial_polygon_points.clear()
		partial_multi_component_mode = false
		partial_polygon_components.clear()
		partial_mode = true
		menu.hide()
		_message(("局部公园" if partial_kind == "park" else "局部文化馆")+"预影开启 · 点击留地内的位置确认，右键取消")
		return
	if verb in ["park","civic"]:
		var site: Dictionary = {}
		for candidate in shown_world.public_sites:
			if candidate["kind"] != verb: continue
			if context.get("id","") == candidate["id"]:
				site = candidate
				break
			# Public actions always use the selected location.
		if site.is_empty():
			_message("公共空间已经落成，悬停查看它服务的街区")
			return
		var result := model.submit({"kind":verb,"id":site["id"]})
		var action_label := "会在下一句扩容" if site["active"] and verb == "civic" else "会在下一句落成"
		_message(site["name"]+action_label if result["accepted"] else result["reason"])
		menu.hide()
		return
	if verb == "relocate_public":
		var site_id := str(context.get("id",""))
		var site: Dictionary = PublicRelocation._site(model.world,site_id)
		if site.is_empty() or not bool(site.get("active",false)):
			_message("请先点选一座已经落成的公共设施")
			return
		relocation_site_id = site_id
		relocation_mode = true
		menu.hide()
		_message("搬迁预影开启 · 点击地图上的合法空地确认新位置，右键取消")
		return
	if verb == "bridge":
		var bridge_preview: Dictionary = model.world.bridge_preview()
		var operation := {"kind":"bridge"}
		if bool(bridge_preview.get("available",false)):
			operation["source_topology"] = str(bridge_preview.get("source_topology",""))
		var result := model.submit(operation)
		if result["accepted"]:
			_message("桥位已确认 · %s · 下一乐句接入路网与交通" % ", ".join(bridge_preview.get("community_names",[])))
		else: _message(str(result["reason"]))
		menu.hide()
		return
	if verb == "response":
		var pending := _pending_response()
		var enabled := not bool(model.synth.response_enabled)
		if not pending.is_empty(): enabled = not bool(pending.get("enabled",true))
		var result := model.submit({"kind":"response","enabled":enabled})
		_message(("跨河应答："+("开启" if enabled else "关闭")+" · 下一拍生效") if result["accepted"] else str(result.get("reason","")))
		menu.hide()
		return
	if selected_id.is_empty(): return
	var community: String = shown_world.by_id[selected_id]["community_id"]
	if verb == "solo": model.submit({"kind":"solo","community":community if model.synth.listener_community != community else ""})
	elif verb == "mute": model.submit({"kind":"mute","community":community,"enabled":not bool(model.synth.muted_communities.get(community,false))})
	elif verb == "focus":
		model.submit({"kind":"focus","community":community})
		_message("主题已聚焦这片社区，下一拍接入；留白句继续休息" if MusicRules.status(shown_world,community)["theme_eligible"] else "镜头与主题已聚焦；沿街成形并有六栋成熟房屋后开唱")
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
	if event.keycode in [KEY_SPACE,KEY_ESCAPE,KEY_B,KEY_G,KEY_TAB,KEY_M,KEY_F,KEY_R,KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_N,KEY_V,KEY_H,KEY_T,KEY_Y,KEY_E,KEY_ENTER,KEY_P]: get_viewport().set_input_as_handled()
	if event.keycode == KEY_SPACE and not event.pressed:
		_cancel_preview_playback()
		return
	if not event.pressed: return
	match event.keycode:
		KEY_P:
			if planning_guide.opened: planning_guide.hide_tool()
			else: planning_guide.open_tool()
		KEY_ESCAPE:
			if reservation_draw_mode:
				reservation_draw_mode = false
				reservation_draw_points.clear()
				_message("自由留地已取消")
				get_viewport().set_input_as_handled()
				return
			if partial_polygon_mode:
				partial_polygon_mode = false
				partial_polygon_points.clear()
				partial_multi_component_mode = false
				partial_polygon_components.clear()
				partial_kind = ""
				partial_reservation_id = ""
				_message("自由局部目标已取消")
				get_viewport().set_input_as_handled()
				return
			_cancel_preview_playback()
			planning_guide.hide_tool()
			black = false
			menu.hide()
			model.submit({"kind":"solo","community":""})
			model.submit({"kind":"focus","community":""})
		KEY_B: black = not black
		KEY_G: _verb("bridge")
		KEY_TAB:
			if partial_polygon_mode and partial_multi_component_mode:
				_finish_partial_component()
			else:
				_verb("solo")
		KEY_M: _verb("mute")
		KEY_F: _verb("focus")
		KEY_H: _home_city()
		KEY_T: _start_town()
		KEY_Y: _cycle_terrain()
		KEY_E:
			if event.shift_pressed: _start_regional_town()
			else: _start_expanded_town()
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
		KEY_ENTER:
			if reservation_draw_mode:
				_submit_free_reservation()
				get_viewport().set_input_as_handled()
			elif partial_polygon_mode:
				_submit_partial_polygon()
				get_viewport().set_input_as_handled()
			else:
				_confirm_landmark()
		KEY_1: _choose_note(48)
		KEY_2: _choose_note(50)
		KEY_3: _choose_note(52)
		KEY_4: _choose_note(55)
		KEY_5: _choose_note(57)

func _message(text: String) -> void:
	notice = text
	notice_seconds = 6.0

func _planning_rejection_message(event: Dictionary) -> String:
	var labels := {"reserve":"留地","release_reservation":"释放留地","park":"公园","civic":"文化设施","bridge":"桥"}
	var action := str(labels.get(str(event.get("operation_kind","")),"规划"))
	var reason := str(event.get("reason","规划条件在乐句边界失效，请重新选择"))
	return action+"没有落定 · "+reason+" · 本次介入槽已保留"

func _flatten_charter_card_refs(raw: Variant, result: Array) -> void:
	# Planning cards are deliberately read-only here.  Older saves may use a
	# string, a single dictionary, or a map of card ids to dictionaries.
	if raw is Array:
		for item in raw:
			_flatten_charter_card_refs(item,result)
		return
	if raw is Dictionary:
		var card := raw as Dictionary
		if card.has("cards"):
			_flatten_charter_card_refs(card["cards"],result)
			return
		if card.has("title") or card.has("name") or card.has("label") or card.has("card_title") or card.has("card_id") or card.has("id"):
			result.append(card)
			return
		for value in card.values():
			_flatten_charter_card_refs(value,result)
		return
	if raw is String and not str(raw).strip_edges().is_empty():
		result.append(str(raw))

func _planning_card_definition(id: String) -> Dictionary:
	if id.is_empty(): return {}
	return PlanningCard.definition(id)

func _card_ref_title(card: Variant) -> String:
	if card is Dictionary:
		var data := card as Dictionary
		for key in ["title","name","label","card_title"]:
			var value := str(data.get(key,""))
			if not value.is_empty(): return value
		for key in ["card_id","id"]:
			var value := str(data.get(key,""))
			if not value.is_empty():
				var definition := _planning_card_definition(value)
				return str(definition.get("title","变化卡 · "+value))
		return "本章变化"
	var definition := _planning_card_definition(str(card))
	return str(definition.get("title",str(card)))

func _card_ref_remaining(card: Variant, charter: Dictionary) -> String:
	if shown_world == null: return ""
	var data: Dictionary = card as Dictionary if card is Dictionary else {}
	for key in ["remaining_phrases","phrases_left","remaining"]:
		if data.has(key): return "剩%d乐句" % maxi(0,int(data[key]))
	for key in ["expires_phrase","until_phrase","end_phrase"]:
		if data.has(key):
			var remaining := int(data[key])-shown_world.phrase_index
			return "已退场" if remaining <= 0 else "剩%d乐句" % remaining
	var definition := _planning_card_definition(str(card)) if not card is Dictionary else {}
	if not definition.is_empty() and definition.has("duration_phrases") and charter.has("committed_phrase"):
		var remaining := int(definition["duration_phrases"])-int(shown_world.phrase_index)+int(charter["committed_phrase"])
		return "已退场" if remaining <= 0 else "剩%d乐句" % remaining
	return ""

func _charter_card_feedback(charter: Dictionary) -> String:
	if charter.is_empty() or not charter.has("card_refs"): return ""
	var cards: Array = []
	_flatten_charter_card_refs(charter.get("card_refs",[]),cards)
	if cards.is_empty(): return ""
	var labels: Array[String] = []
	for card in cards:
		var title := _card_ref_title(card)
		var remaining := _card_ref_remaining(card,charter)
		labels.append(title+((" · "+remaining) if not remaining.is_empty() else ""))
	if labels.size() > 3:
		labels = labels.slice(0,3)
		labels.append("+%d张" % (cards.size()-3))
	return "本章变化 · "+"、".join(labels)

func _planning_status_hint() -> String:
	## Keep the planning cause visible after the transient P panel closes. The
	## map and hover cards still carry the detailed spatial preview.
	if model == null or model.world == null: return "P规划：选章程 → 变化卡 → 社区 → 公共空间"
	var pending_labels: Array[String] = []
	for operation in model.world.pending_actions:
		var kind := str(operation.get("kind", ""))
		var label: String = str({"charter":"章程", "park":"公园", "civic":"文化馆", "relocate_public":"搬迁公共设施", "reserve":"留地", "release_reservation":"释放留地", "bridge":"跨河连接"}.get(kind, ""))
		if bool(operation.get("partial",false)):
			label = "局部公园" if kind == "park" else ("局部文化馆" if kind == "civic" else label)
		if not str(label).is_empty(): pending_labels.append(str(label))
	if not pending_labels.is_empty():
		return "待播规划 · %s · 下一个乐句落定" % "、".join(pending_labels)
	# A bridge is a structural player choice whose one-shot toast expires after
	# a few seconds. Keep the resulting road and acoustic connection in the
	# persistent caption so the planning cause remains visible while the city
	# continues to grow.
	if model.world.bridge:
		return "跨河已连接 · 两岸道路与合奏已接通 · P继续规划"
	if model.world.development_charters.is_empty():
		return "P规划：选章程 → 变化卡 → 社区 → 公共空间"
	var charter: Dictionary = model.world.development_charters[0]
	var title := str(World.Charter.PLANS.get(str(charter.get("plan_id", "")), {}).get("title", "发展章程"))
	var card_text := _charter_card_feedback(charter)
	if card_text.is_empty(): return "当前规划 · %s · P重新规划" % title
	return "当前规划 · %s · %s · P重新规划" % [title, card_text]

func _request_preview() -> void:
	var operation := context.duplicate(true)
	if planning_guide.opened:
		if planning_guide.stage != "anchor": return
		planning_guide.update_candidate(world_at(pointer))
		preview_context_key = planning_guide.comparison_identity()
		if preview_context_key.is_empty(): return
		preview_public = true
		preview_requested = true
		if not planning_guide.comparison.is_empty() and planning_guide.comparison_key == preview_context_key:
			_play_public_preview()
			return
		if preview_thread != null: return
		operation = {"kind":"public_compare","candidate":planning_guide.candidate.duplicate(true)}
	elif context.get("kind","seed") not in ["seed","retune"]: return
	else:
		if preview_thread != null: return
		preview_public = false
		preview_context_key.clear()
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
	preview_thread.start(_build_preview.bind(frozen,operation,state,at,preview_context_key.duplicate(true)))

func _build_preview(frozen: ContinuousAudioModel, operation: Dictionary, state: Dictionary, at: int, request_key: Array) -> Dictionary:
	if operation["kind"] == "public_compare":
		var result := PublicPreview.build(frozen,operation["candidate"],state,at)
		result["request_key"] = request_key
		return result
	var rate := int(Config.load_values()["timing"]["sample_rate"])
	return {"pcm":Renderer.pcm16(frozen.forecast(operation,state,at,rate*3))}

func _play_public_preview() -> void:
	var variant: Dictionary = planning_guide.comparison["variants"][planning_guide.anchor_kind]
	if not variant["accepted"]:
		_message(str(variant["reason"]))
		_cancel_preview_playback()
		return
	_play_preview_pcm(variant["pcm"])

func _play_preview_pcm(pcm: PackedByteArray) -> void:
	if pcm.is_empty(): return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(Config.load_values()["timing"]["sample_rate"])
	stream.stereo = true
	stream.data = pcm
	preview_player.stream = stream
	preview_player.play()
	preview_started = true
	preview_skips = clock.underruns
	if not preview_duck_owned:
		preview_saved_ducking = model.synth.ducking
		preview_saved_release = model.synth.duck_release_at
		preview_duck_owned = true
	model.synth.ducking = true
	model.synth.duck_release_at = clock.renderer.transport.rendered_frames+stream.mix_rate*3

func _hover_placement(p: Vector2) -> Dictionary:
	var key := [model.world,model.world.phrase_index,model.world.action_serial,p]
	if hover_placement_key != key:
		hover_placement_key = key
		hover_placement = model.world.placement(p)
	return hover_placement

func _bridge_preview_at(p: Vector2) -> Dictionary:
	if shown_world == null: return {}
	var preview: Dictionary = shown_world.bridge_preview()
	if not bool(preview.get("available",false)): return {}
	var raw_a: Array = preview.get("from_position",[])
	var raw_b: Array = preview.get("to_position",[])
	if raw_a.size() != 2 or raw_b.size() != 2: return {}
	var a := Vector2(float(raw_a[0]),float(raw_a[1]))
	var b := Vector2(float(raw_b[0]),float(raw_b[1]))
	var q := Geometry2D.get_closest_point_to_segment(p,a,b)
	return preview if p.distance_to(q) <= 1.45 else {}

func _process(delta: float) -> void:
	if model == null: return
	view_zoom = lerpf(view_zoom,zoom_target,1.0-exp(-delta/0.14))
	pan = pan.lerp(pan_target,1.0-exp(-delta/0.14))
	var presentation_started := Time.get_ticks_usec()
	shown_world = model.presentation_world(clock.renderer.transport.audible_frame)
	_profile_frame("presentation_ms",presentation_started)
	if preview_thread != null and not preview_thread.is_alive():
		var result: Dictionary = preview_thread.wait_to_finish()
		preview_thread = null
		if result.has("variants"):
			if planning_guide.accept_comparison(result,result["request_key"]):
				if preview_requested: _play_public_preview()
			else: _cancel_preview_playback()
		elif preview_requested:
			if not planning_guide.opened: _play_preview_pcm(result["pcm"])
			else: _cancel_preview_playback()
	var frame_started := Time.get_ticks_usec()
	_sync_buildings()
	_profile_frame("buildings_ms",frame_started)
	frame_started = Time.get_ticks_usec()
	scenery.sync(self)
	_profile_frame("traffic_ms",frame_started)
	frame_started = Time.get_ticks_usec()
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
	# Planning requests are accepted before the boundary, but geometry can change
	# before commit. Surface the authoritative rejection once the event becomes
	# audible so the player can choose another parcel immediately.
	var presented_events: Array = shown_world.events
	if presented_events.size() < last_presented_event_count:
		last_presented_event_count = presented_events.size()
	if presented_events.size() > last_presented_event_count:
		for event in presented_events.slice(last_presented_event_count):
			if str(event.get("kind","")) == "planning_rejected": _message(_planning_rejection_message(event))
		last_presented_event_count = presented_events.size()
	notice_seconds = maxf(0.0,notice_seconds-delta)
	ripple_seconds = maxf(0.0,ripple_seconds-delta)
	planning_guide.sync()
	caption.position = Vector2(48,size.y-68)
	caption.visible = not black
	tooltip.visible = not black and pointer_inside and not menu.visible
	shadow_layer.visible = not black
	buildings_layer.visible = not black
	if black: menu.hide()
	if response_button != null:
		response_button.text = _response_button_text()
		response_button.tooltip_text = "全城唯一跨河应答槽："+_response_state_label()+"；点击后在下一拍切换"
	hover_id = _hit(pointer) if pointer_inside else ""
	var p := world_at(pointer)
	var check := _hover_placement(p)
	var bridge_hover := _bridge_preview_at(p)
	var landmark := shown_world.landmark_at(p)
	var hover_card_status := ""
	if not landmark.is_empty():
		var progress := clampf(float(clock.renderer.transport.audible_frame-int(landmark.get("reveal_frame",landmark.get("frame",0))))/float(maxi(1,int(landmark.get("reveal_frames",1)))),0.0,1.0)
		var effect := "独立长音 · 吸收%d栋 · 动机%d音" % [landmark.get("absorbed_buildings",[]).size(),landmark.get("motif",[]).size()]
		tooltip.text = "%s · %s\n%s\n落成 %.0f%% · 悬停查看历史" % [str(landmark["name"]),"古典遗产" if int(landmark.get("era",1)) == 1 else "时代地标",effect,progress*100.0]
	elif not hover_id.is_empty():
		var b: Dictionary = shown_world.by_id[hover_id]
		tooltip.text = "%s · %s · %s\n%s  ·  活力 %.0f\n点击选音   Tab独听社区   F聚焦" % ["律动街" if b["type"] == "commercial" else "长音房",note_name(int(model.audible_pitches().get(b["district_id"],b["current_midi"]))),b["form"],shown_world.communities[b["community_id"]]["name"],b["vitality"]]
		var charter := World.Charter.for_community(shown_world,str(b["community_id"]))
		if not charter.is_empty(): tooltip.text += "\n发展章程 · "+str(World.Charter.PLANS[charter["plan_id"]]["title"])+" · P重新规划"
		var card_feedback := _charter_card_feedback(charter)
		if not card_feedback.is_empty():
			hover_card_status = card_feedback
			tooltip.text += "\n"+card_feedback
		tooltip.text += "\n跨河应答 · "+_response_state_label()+"\n点击查看社区音型、当前声部与下一步机会"
	elif not bridge_hover.is_empty():
		var names: Array = bridge_hover.get("community_names",[])
		var before := "未连通" if is_inf(float(bridge_hover.get("route_before",INF))) else ("%.1f步" % float(bridge_hover.get("route_before",0.0)))
		tooltip.text = "桥位预影 · %s\n真实道路：%s\n步行 %s → %.1f步 · %s\nG确认；下一乐句接入两岸道路、交通与空间声学" % [" ↔ ".join(names),"、".join(bridge_hover.get("road_ids",[])),before,float(bridge_hover.get("route_after",0.0)),str(bridge_hover.get("traffic_after","两岸联奏线"))]
	elif check["allowed"]:
		tooltip.text = "%s\n%s\n点击选音；Shift低八度；按住空格试听" % [str(check["preview"]),note_name(midi)]
		var lot: String = check["lot_id"]
		hover_seconds = hover_seconds+delta if lot == last_hover_lot else 0.0
		if lot != last_hover_lot: last_hover_lot = lot
		if hover_seconds > 0.18 and hover_seconds < 0.18+delta: _light_note(midi+12 if midi < 48 else midi)
	else:
		var reservation := shown_world.planning_at(p)
		var site := shown_world.public_at(p)
		if not reservation.is_empty():
			tooltip.text = "你留下的空地 · 房屋不会长进来\n点击选择释放、建公园或文化设施；规划面板也可自由留地"
		elif not site.is_empty():
			tooltip.text = site["name"]+"\n"+("已落成 · 沿道路覆盖%d栋\n公园为主题留白" % site.get("covered",[]).size() if site["active"] else "公共保留地 · 点击营造\n公园让音乐呼吸，文化设施组织主题")
			if site["active"] and site["kind"] == "civic":
				tooltip.text = "%s · 文化设施%d级\n覆盖%d栋 · 已服务%d/%d栋\n%s" % [site["name"],int(site.get("service_level",1)),site.get("covered",[]).size(),site.get("served",[]).size(),int(site.get("service_capacity",18)),"点击后选公共设施，下一句扩容" if int(site.get("service_level",1)) < 3 else "三级扩容完成 · 文化主题继续演奏"]
		else: tooltip.text = str(check["reason"])+"\n滚轮缩放 · 中键移动 · G建桥 · H全城 · Y切换地形 · E扩展城\nR晴岸 · V深流 · T林荫交响 · N空地\nCtrl+S存一版 · F9继续"
	var status_line := notice if notice_seconds > 0.0 else _planning_status_hint()
	if not hover_card_status.is_empty():
		status_line = hover_card_status if status_line.is_empty() else status_line+" · "+hover_card_status
	caption.text = status_line
	tooltip.position = Vector2(clampf(pointer.x+18,12,size.x-420),clampf(pointer.y+20,70,size.y-125))
	if menu.visible:
		_update_selected_opportunity()
		menu.size = menu.get_combined_minimum_size()
		menu.position = Vector2(clampf(menu.position.x,12,maxf(12,size.x-menu.size.x-12)),clampf(menu.position.y,70,maxf(70,size.y-menu.size.y-12)))
		_planning_menu()
		if pointer_inside and not menu.get_global_rect().grow(100).has_point(pointer): menu.hide()
	queue_redraw()
	_profile_frame("interaction_ms",frame_started)

func _sync_buildings() -> void:
	_prepare_ground()
	terrain_layer.sync(self)
	city_ground_layer.sync(self)
	water_flow.sync(self)
	backdrop.color = Color.BLACK if black else Color("ecebe2")
	_refresh_overlay()
	_sync_map_labels()
	var frame := clock.renderer.transport.audible_frame
	var warmth := 0.03*sin(TAU*frame/float(clock.renderer.transport.sample_rate)/4.0)
	var pitches := model.audible_pitches()
	var origin := Vector2(size.x*0.5,size.y*0.52)+pan
	buildings_layer.position = origin
	buildings_layer.scale = Vector2.ONE*view_zoom
	buildings_layer.modulate = Color(0.96+warmth,1.0,1.0,1.0)
	shadow_layer.position = origin
	shadow_layer.scale = Vector2.ONE*view_zoom
	var display_key := _shown_city_key()+[shown_world.buildings.size(),pitches.hash()]
	if building_display_key == display_key and sprites.size() == shown_world.buildings.size():
		var shadow_changes: Array[Dictionary] = []
		for id in revealing_buildings.keys():
			var sprite: AudioGrowthMask = sprites[id]
			sprite.sample_frame(frame-minf(0.0,float(shown_world.by_id[id]["birth_frame"])))
			var step := roundi(sprite.progress*int(shadow_layer.cfg["progress_steps"]))
			if step != int(shadow_records[id]["step"]):
				shadow_records[id]["progress"] = sprite.progress
				shadow_records[id]["step"] = step
				shadow_changes.append(shadow_records[id])
			if sprite.progress >= 1.0: revealing_buildings.erase(id)
		if not shadow_changes.is_empty(): shadow_layer.update_progress(shadow_changes)
		return
	building_display_key = display_key
	building_sync_count += 1
	revealing_buildings.clear()
	var terrain_key := [shown_world.terrain.noise_seed,shown_world.terrain.river_phase,shown_world.terrain.family]
	var shadows_dirty := shadow_terrain_key != terrain_key
	var append_only := not shadows_dirty
	var added_shadows: Array[Dictionary] = []
	if shadows_dirty:
		building_geometry.clear()
		shadow_records.clear()
		shadow_terrain_key = terrain_key
	for id in sprites.keys().duplicate():
		if shown_world.by_id.has(id): continue
		sprites[id].queue_free()
		sprites.erase(id)
		building_geometry.erase(id)
		shadow_records.erase(id)
		shadows_dirty = true
		append_only = false
	for building in shown_world.buildings:
		var id: String = building["district_id"]
		var entry: Dictionary = assets[building["type"]]
		var world_position := Coupling.position_of(building)
		var key := [world_position,entry["id"]]
		var geometry_dirty := false
		if not building_geometry.has(id) or building_geometry[id]["key"] != key:
			geometry_dirty = true
			if building_geometry.has(id): append_only = false
			building_geometry[id] = {"key":key,"position":Projection2D.to_screen(world_position-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),shown_world.terrain.height_at(world_position)),
				"scale":28.0*sqrt(2.0)*0.8/maxf(float(entry["model_bounds"]["size"][0]),float(entry["model_bounds"]["size"][2]))/float(entry["pixels_per_world"])}
			shadows_dirty = true
		var geometry: Dictionary = building_geometry[id]
		var scale_factor: float = geometry["scale"]
		if not sprites.has(id):
			shadows_dirty = true
			var sprite := GrowthSprite.new()
			sprite.use_master_clock = false
			sprite.texture = textures[building["type"]]
			sprite.centered = false
			sprite.offset = -Vector2(entry["origin"][0],entry["origin"][1])
			buildings_layer.add_child(sprite)
			sprite.begin_at(maxi(0,int(building["birth_frame"])))
			sprites[id] = sprite
		var sprite: AudioGrowthMask = sprites[id]
		sprite.position = geometry["position"]
		sprite.scale = Vector2.ONE*scale_factor
		if sprite.progress < 1.0:
			sprite.sample_frame(frame-minf(0.0,float(building["birth_frame"])))
			if sprite.progress < 1.0: revealing_buildings[id] = true
		var played := int(pitches.get(id,building["current_midi"]))
		sprite.modulate = Color(1.0,1.0,0.92 if played < 48 else 0.97,1.0)
		var step := roundi(sprite.progress*int(shadow_layer.cfg["progress_steps"]))
		var new_shadow := not shadow_records.has(id)
		if not new_shadow and shadow_records[id]["step"] != step: append_only = false
		if new_shadow or shadow_records[id]["step"] != step or geometry_dirty:
			shadow_records[id] = {"entry":entry,"position":geometry["position"],"base_scale":Vector2.ONE*scale_factor,"progress":sprite.progress,"visible":true,"step":step}
			if new_shadow: added_shadows.append(shadow_records[id])
			shadows_dirty = true
	if shadows_dirty and (not append_only or not shadow_layer.try_append_records(added_shadows)): _update_shadows()

func _update_shadows() -> void:
	var records: Array[Dictionary] = []
	for building in shown_world.buildings: records.append(shadow_records[building["district_id"]])
	shadow_layer.update_records(records)

func _draw() -> void:
	var draw_started := Time.get_ticks_usec()
	if black: return
	if shown_world == null: return
	_draw_planning_preview()
	var flow := float(clock.renderer.transport.audible_frame)/float(clock.renderer.transport.sample_rate)
	_draw_community_names()
	_draw_public_labels()
	_draw_landmarks()
	_draw_landmark_preview()
	if pointer_inside:
		var pointer_world := world_at(pointer)
		for lot in shown_world.lots:
			var center := Vector2(lot["center"][0],lot["center"][1])
			if lot["occupant"] == "" and center.distance_to(pointer_world) < 1.0:
				draw_colored_polygon(_project_polygon(lot["polygon"]),Color(0.9,0.94,0.8,0.5))
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
	_draw_landmark_bar()
	if not black:
		var lead := str(model.synth.theme.get("cid",""))
		var name := str(shown_world.communities.get(lead,{}).get("name","留白"))
		var decree_slots := " · 政令槽%d" % shown_world.landmark_intervention_slots() if shown_world.landmark_intervention_slots() > 1 else ""
		var service := overlay_service
		var status := "第%d句 · %s · %s · %d栋/%d社区 · %d功能区 · %d条线路 · 文化%d/%d栋 · %d段待播 · 主题%s%s" % [shown_world.phrase_index,shown_world.era_title(),shown_world.vehicle_label(),shown_world.buildings.size(),shown_world.active_community_count(),shown_world.functional_zones.size(),shown_world.transit_lines.size(),int(service.get("served",0)),shown_world.buildings.size(),model.world.pending_actions.size(),name,decree_slots]
		draw_string(font,Vector2(size.x-760,size.y-64),status,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("607974"))
	var duration := float(model.phrase_frames)
	var progress := fposmod(float(clock.renderer.transport.audible_frame),duration)/duration
	draw_line(Vector2(48,size.y-32),Vector2(size.x-48,size.y-32),Color(0.59,0.66,0.6,0.25),2.0)
	draw_line(Vector2(48,size.y-32),Vector2(48+(size.x-96)*progress,size.y-32),Color("af9c6a"),3.0)
	_profile_frame("draw_ms",draw_started)

func diagnostics() -> Dictionary:
	return {"buildings":shown_world.buildings.size(),"planned_communities":shown_world.active_community_count(),
		"lots":shown_world.lots.size(),"resonance":shown_world.resonance,"phrase":shown_world.phrase_index,
		"skips":clock.underruns,"audible_frame":clock.renderer.transport.audible_frame,"pending":model.world.pending.duplicate(true),
		"preview_started":preview_started,"seed_hex":model.world.rng.seed_hex,"blocks":shown_world.blocks.size(),
		"public_sites":shown_world.public_sites.duplicate(true),"functional_zones":shown_world.functional_zones.duplicate(true),"landmarks":shown_world.landmarks.duplicate(true),"landmark_candidates":shown_world.landmark_candidates(),"green_corridors":shown_world.green_corridors.duplicate(true),"centers":shown_world.centers.duplicate(true),"transit":shown_world.transit_lines.map(func(line: Dictionary) -> String: return line["name"]),"terrain_family":shown_world.terrain.family,"terrain_title":shown_world.terrain_title(),"era":shown_world.era,"era_title":shown_world.era_title(),"vehicle":shown_world.vehicle_kind(),"score":model.synth.score_snapshot(),"sound_trace":model.sound_trace.duplicate(true)}

func _exit_tree() -> void:
	if session_persistence and model != null and is_instance_valid(clock) and clock.active: save_city("离开时保存")
	if preview_thread != null: preview_thread.wait_to_finish()
	if is_instance_valid(clock): clock.stop_output()


func _set_expression(value: String) -> void:
	expression = value
	low_octave.button_pressed = value == "deep"
	_message("深流：低音、缓慢脉动与留白" if value == "deep" else "晴岸：明亮主题与商街节奏")

func _refresh_overlay() -> void:
	var key := _shown_city_key()
	if overlay_key == key: return
	overlay_key = key
	overlay_rebuild_count += 1
	overlay_candidates = shown_world.landmark_candidates()
	overlay_service = shown_world.public_service_summary()
	overlay_communities.clear()
	for community in shown_world.communities.values():
		var members: Array = community["members"]
		if members.size() < 4: continue
		var center := Vector2.ZERO
		for id in members: center += Coupling.position_of(shown_world.by_id[id])
		overlay_communities.append({"id":str(community["id"]),"position":center/members.size(),"name":community["name"],"members":members.size()})

func _landmark_candidates() -> Array[Dictionary]:
	if shown_world == null: return []
	_refresh_overlay()
	return overlay_candidates

func _draw_landmarks() -> void:
	var frame := int(clock.renderer.transport.audible_frame)
	for landmark in shown_world.landmarks:
		var position := Vector2(float(landmark["position"][0]),float(landmark["position"][1]))
		var radius := float(landmark["radius"])
		var reveal_start := int(landmark.get("reveal_frame",landmark.get("frame",0)))
		var reveal_frames := maxi(1,int(landmark.get("reveal_frames",1)))
		var progress := clampf(float(frame-reveal_start)/float(reveal_frames),0.0,1.0)
		var at := point(position,shown_world.terrain.height_at(position)+0.16)
		var tint := Color("b18b55")
		var sides := 12 if str(landmark.get("name","")) == "圆形剧场" else 8
		var ring := PackedVector2Array()
		for i in range(sides):
			ring.append(position+Vector2.from_angle(TAU*float(i)/sides)*radius*progress)
		if ring.size() >= 3:
			draw_colored_polygon(_project_polygon(ring,shown_world.terrain.height_at(position)+0.12),Color(tint,0.28+0.22*progress))
		draw_arc(at,radius*progress*view_zoom,0,TAU,32,Color(tint,0.95),2.0*view_zoom,true)
		for i in range(sides):
			var outer := point(position+Vector2.from_angle(TAU*float(i)/sides)*radius*progress,shown_world.terrain.height_at(position)+0.18)
			draw_line(at,outer,Color(tint,0.55+0.25*progress),1.0*view_zoom,true)
		draw_circle(at,2.5*view_zoom,Color(tint,0.92))
		draw_string(ThemeDB.fallback_font,at+Vector2(8,-10)*view_zoom,str(landmark["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("776247"))
		if progress < 1.0:
			draw_string(ThemeDB.fallback_font,at+Vector2(8,7)*view_zoom,"落成 %.0f%%" % (progress*100.0),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("8a7356"))

func _draw_landmark_bar() -> void:
	var candidates := _landmark_candidates()
	if candidates.is_empty(): return
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(28,98),"地标候选 · 当前时代",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("71837a"))
	for i in range(candidates.size()):
		var candidate: Dictionary = candidates[i]
		var y := 122.0+float(i)*28.0
		var tint := Color("79966e") if bool(candidate.get("built",false)) else (Color("b18b55") if bool(candidate.get("awakened",false)) else (Color("b39a63") if bool(candidate["ready"]) else Color("9aa69a")))
		draw_circle(Vector2(32,y-4),8.0,Color(tint,0.18))
		draw_arc(Vector2(32,y-4),8.0,0,TAU,18,tint,1.1,true)
		draw_string(font,Vector2(49,y),str(candidate["glyph"])+"  "+str(candidate["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("566d65") if bool(candidate["ready"]) or bool(candidate.get("awakened",false)) else Color("87948b"))
		var status_text := str(candidate["condition"])
		if bool(candidate.get("built",false)): status_text += " · 已落成"
		elif bool(candidate.get("awakened",false)): status_text += " · 已觉醒 · Enter确认"
		else: status_text += " · 觉醒%d/2句" % int(candidate.get("streak",0))
		draw_string(font,Vector2(49,y+13),status_text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("7e8d84"))

func _draw_landmark_preview() -> void:
	var candidates := _landmark_candidates()
	if selected_landmark_candidate < 0 or selected_landmark_candidate >= candidates.size(): return
	var candidate: Dictionary = candidates[selected_landmark_candidate]
	if not bool(candidate["ready"]) and not bool(candidate.get("awakened",false)): return
	var sites := _landmark_preview_positions(selected_landmark_candidate)
	var tint := Color("b18b55")
	for site in sites:
		var position := Vector2(float(site["position"][0]),float(site["position"][1]))
		var radius := float(site["radius"])
		var at := point(position,shown_world.terrain.height_at(position)+0.12)
		draw_circle(at,radius*view_zoom,Color(tint,0.16))
		draw_arc(at,radius*view_zoom,0,TAU,32,Color(tint,0.92),1.8*view_zoom,true)
		draw_line(at+Vector2(-5,0)*view_zoom,at+Vector2(5,0)*view_zoom,Color(tint,0.75),1.1*view_zoom,true)
		draw_line(at+Vector2(0,-5)*view_zoom,at+Vector2(0,5)*view_zoom,Color(tint,0.75),1.1*view_zoom,true)
		draw_string(ThemeDB.fallback_font,at+Vector2(8,-8)*view_zoom,"预影 · "+str(candidate["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("776247"))

func _draw_partial_access_preview(preview: Dictionary) -> void:
	## Keep the public target's real road connection visible while the player
	## is still drawing.  The target and remainder are already shown as filled
	## polygons; this line makes the access decision legible on a busy map.
	if not bool(preview.get("accepted",false)): return
	var path := _partial_access_path(preview)
	if path.size() < 2: return
	var projected := _project_polygon(path)
	draw_polyline(projected,Color("b18b55",0.92),2.4,true)
	draw_circle(projected[0],4.5,Color("4f9f7b",0.95))
	draw_circle(projected[projected.size()-1],4.5,Color("b18b55",0.95))
	var road_id := str(preview.get("road_id",""))
	if not road_id.is_empty():
		draw_string(ThemeDB.fallback_font,projected[projected.size()-1]+Vector2(7,-6),"入口 · "+road_id,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("776247"))

func _partial_access_path(preview: Dictionary) -> PackedVector2Array:
	var raw_path: Variant = preview.get("target_access_path",PackedVector2Array())
	if raw_path is PackedVector2Array: return raw_path
	return PackedVector2Array()

func _partial_preview_label(preview: Dictionary, free_target: bool) -> String:
	var title := ("自由分块公园" if partial_kind == "park" else "自由分块文化馆") if partial_multi_component_mode else (("自由局部公园" if partial_kind == "park" else "自由局部文化馆") if free_target else ("局部公园" if partial_kind == "park" else "局部文化馆"))
	var label := title+"预影 · "+("按 Enter 确认" if free_target else "点击确认")
	if not bool(preview.get("accepted",false)):
		return label.replace(" · "+("按 Enter 确认" if free_target else "点击确认")," · "+str(preview.get("reason","位置不可用")))
	return label+" · 下一乐句落成 · 入口 %s · %s · 保留%d片留地" % [str(preview.get("road_id","未知道路")),str(preview.get("target_community_id","未知社区")),int(preview.get("remaining_count",0))]

func _draw_planning_preview() -> void:
	if reservation_draw_mode and pointer_inside:
		var draw_color := Color("4f9f7b") if reservation_draw_points.size() >= 3 else Color("79966e")
		if reservation_draw_points.size() >= 2:
			var drawn := _project_polygon(reservation_draw_points)
			var closed := drawn.duplicate()
			closed.append(drawn[0])
			draw_polyline(closed,Color(draw_color,0.88),2.0,true)
		if reservation_draw_points.size() >= 3:
			var fill := _project_polygon(reservation_draw_points)
			draw_colored_polygon(fill,Color(0.35,0.78,0.65,0.16))
			var current := point(world_at(pointer))
			draw_line(point(reservation_draw_points[reservation_draw_points.size()-1]),current,Color(draw_color,0.68),1.3,true)
		for vertex in reservation_draw_points:
			draw_circle(point(vertex),4.0,Color(draw_color,0.95))
		var draw_text := "自由留地 · %d点" % reservation_draw_points.size()
		if reservation_draw_points.size() < 3:
			draw_text += " · 继续点击，至少三点"
		else:
			draw_text += " · 按 Enter 确认 · Esc/右键取消"
		draw_string(ThemeDB.fallback_font,point(world_at(pointer))+Vector2(10,-12),draw_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("41665b"))
	if partial_polygon_mode and not partial_reservation_id.is_empty() and pointer_inside:
		var reservation: Dictionary = PartialPublic._reservation(shown_world,partial_reservation_id)
		if not reservation.is_empty() and reservation.has("polygon"):
			var source_polygon := _project_polygon(reservation["polygon"])
			source_polygon.append(source_polygon[0])
			draw_polyline(source_polygon,Color(0.55,0.72,0.48,0.55),1.3,true)
		var draw_color := Color("4f9f7b") if partial_polygon_points.size() >= 3 or not partial_polygon_components.is_empty() else Color("79966e")
		for component in partial_polygon_components:
			var component_polygon := _project_polygon(component)
			if component_polygon.size() > 1:
				var component_closed := component_polygon.duplicate()
				component_closed.append(component_closed[0])
				draw_polyline(component_closed,Color("4f9f7b",0.88),2.0,true)
				draw_colored_polygon(component_polygon,Color(0.35,0.78,0.65,0.12))
			for vertex in component:
				draw_circle(point(vertex),4.0,Color("4f9f7b",0.95))
		if partial_polygon_points.size() >= 2:
			var drawn := _project_polygon(partial_polygon_points)
			var closed := drawn.duplicate()
			closed.append(drawn[0])
			draw_polyline(closed,Color(draw_color,0.9),2.0,true)
		if partial_polygon_points.size() >= 3:
			var target_preview_polygon := _project_polygon(partial_polygon_points)
			draw_colored_polygon(target_preview_polygon,Color(0.35,0.78,0.65,0.12))
			draw_line(point(partial_polygon_points[partial_polygon_points.size()-1]),point(world_at(pointer)),Color(draw_color,0.68),1.3,true)
		for vertex in partial_polygon_points:
			draw_circle(point(vertex),4.0,Color(draw_color,0.95))
		var partial_preview := _partial_preview_for_draw()
		for residual in partial_preview.get("remaining_polygons",[]):
			var residual_polygon := _project_polygon(residual)
			draw_colored_polygon(residual_polygon,Color(0.45,0.72,0.48,0.13))
			if residual_polygon.size() > 1:
				residual_polygon.append(residual_polygon[0])
				draw_polyline(residual_polygon,Color(0.42,0.67,0.45,0.40),1.0,true)
		var target_polygons := _partial_preview_polygons(partial_preview)
		if not target_polygons.is_empty():
			var accepted := bool(partial_preview.get("accepted",false))
			for raw_target in target_polygons:
				var target_polygon := _project_polygon(raw_target)
				draw_colored_polygon(target_polygon,Color(0.35,0.78,0.65,0.30) if accepted else Color(0.82,0.36,0.34,0.20))
				if target_polygon.size() > 1:
					target_polygon.append(target_polygon[0])
					draw_polyline(target_polygon,Color("4f9f7b") if accepted else Color("b35e58"),2.0,true)
			_draw_partial_access_preview(partial_preview)
			var partial_text := _partial_preview_label(partial_preview,true)
			draw_string(ThemeDB.fallback_font,point(world_at(pointer))+Vector2(10,-12),partial_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("41665b") if accepted else Color("9b4b4b"))
	if partial_mode and not partial_reservation_id.is_empty() and pointer_inside:
		var partial_preview: Dictionary = PartialPublic.preview(shown_world,partial_reservation_id,partial_kind,world_at(pointer))
		var reservation: Dictionary = PartialPublic._reservation(shown_world,partial_reservation_id)
		if not reservation.is_empty() and reservation.has("polygon"):
			var source_polygon := _project_polygon(reservation["polygon"])
			source_polygon.append(source_polygon[0])
			draw_polyline(source_polygon,Color(0.55,0.72,0.48,0.55),1.3,true)
		for residual in partial_preview.get("remaining_polygons",[]):
			var residual_polygon := _project_polygon(residual)
			draw_colored_polygon(residual_polygon,Color(0.45,0.72,0.48,0.13))
			if residual_polygon.size() > 1:
				residual_polygon.append(residual_polygon[0])
				draw_polyline(residual_polygon,Color(0.42,0.67,0.45,0.40),1.0,true)
		if partial_preview.has("target_polygon"):
			var target_polygon := _project_polygon(partial_preview["target_polygon"])
			var accepted := bool(partial_preview.get("accepted",false))
			draw_colored_polygon(target_polygon,Color(0.35,0.78,0.65,0.30) if accepted else Color(0.82,0.36,0.34,0.20))
			if target_polygon.size() > 1:
				target_polygon.append(target_polygon[0])
				draw_polyline(target_polygon,Color("4f9f7b") if accepted else Color("b35e58"),2.0,true)
			_draw_partial_access_preview(partial_preview)
			var partial_text := _partial_preview_label(partial_preview,false)
			draw_string(ThemeDB.fallback_font,point(world_at(pointer))+Vector2(10,-12),partial_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("41665b") if accepted else Color("9b4b4b"))
	if relocation_mode and not relocation_site_id.is_empty() and pointer_inside:
		var relocation_preview: Dictionary = PublicRelocation.preview(shown_world,relocation_site_id,world_at(pointer))
		if relocation_preview.has("target_polygon"):
			var target_polygon := _project_polygon(relocation_preview["target_polygon"])
			var accepted := bool(relocation_preview.get("accepted",false))
			draw_colored_polygon(target_polygon,Color(0.35,0.78,0.65,0.28) if accepted else Color(0.82,0.36,0.34,0.18))
			if target_polygon.size() > 1:
				target_polygon.append(target_polygon[0])
				draw_polyline(target_polygon,Color("4f9f7b") if accepted else Color("b35e58"),2.0,true)
			var source: Dictionary = PublicRelocation._site(shown_world,relocation_site_id)
			if not source.is_empty():
				var source_p := Vector2(source["position"][0],source["position"][1])
				draw_line(point(source_p),point(world_at(pointer)),Color(0.39,0.58,0.48,0.6),1.5,true)
			var preview_text := "搬迁预影 · " + ("点击确认" if accepted else str(relocation_preview.get("reason","位置不可用")))
			if accepted:
				var delta: Dictionary = relocation_preview.get("service_delta",{})
				preview_text += " · 覆盖 %+d · 服务 %+d · %s" % [int(delta.get("covered",0)),int(delta.get("served",0)),str(relocation_preview.get("target_community_id","未知社区"))]
			draw_string(ThemeDB.fallback_font,point(world_at(pointer))+Vector2(10,-12),preview_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("41665b") if accepted else Color("9b4b4b"))
	planning_guide.draw_map()
	_draw_bridge_preview()
	if menu.visible and context.has("position"):
		var raw: Array = context["position"]
		var candidate := model.world.planning_candidate(Vector2(float(raw[0]),float(raw[1])))
		if not candidate.is_empty():
			var polygon := _project_polygon(candidate["polygon"])
			draw_colored_polygon(polygon,Color(0.72,0.84,0.72,0.35))
			polygon.append(polygon[0])
			draw_polyline(polygon,Color("789978"),1.8,true)
	for op in model.world.pending_actions:
		if not op.has("polygon"): continue
		var polygon := _project_polygon(op["polygon"])
		var color := Color(0.65,0.78,0.56,0.55) if op["kind"] != "civic" else Color(0.82,0.73,0.56,0.55)
		draw_colored_polygon(polygon,color)

func _draw_bridge_preview() -> void:
	if shown_world == null: return
	var preview: Dictionary = shown_world.bridge_preview()
	if not bool(preview.get("available",false)): return
	var raw_a: Array = preview.get("from_position",[])
	var raw_b: Array = preview.get("to_position",[])
	if raw_a.size() != 2 or raw_b.size() != 2: return
	var a := Vector2(float(raw_a[0]),float(raw_a[1]))
	var b := Vector2(float(raw_b[0]),float(raw_b[1]))
	var pa := point(a,shown_world.terrain.height_at(a)+0.18)
	var pb := point(b,shown_world.terrain.height_at(b)+0.18)
	var pulse := 0.78+0.18*sin(float(clock.renderer.transport.audible_frame)/float(clock.renderer.transport.sample_rate)*TAU*1.5)
	var tint := Color(0.68,0.53,0.30,pulse)
	draw_line(pa,pb,Color(0.93,0.78,0.43,0.18),8.0*view_zoom,true)
	draw_line(pa,pb,tint,2.0*view_zoom,true)
	draw_circle(pa,4.5*view_zoom,Color(0.94,0.82,0.50,0.9))
	draw_circle(pb,4.5*view_zoom,Color(0.94,0.82,0.50,0.9))
	var label := "桥位预影 · G确认"
	if not preview.get("community_names",[]).is_empty(): label += " · "+" ↔ ".join(preview["community_names"])
	draw_string(ThemeDB.fallback_font,(pa+pb)*0.5+Vector2(8,-8)*view_zoom,label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("725d39"))

func _draw_public_labels() -> void:
	if not pointer_inside: return
	var p := world_at(pointer)
	for site in shown_world.near_public_sites(p):
		var inside := false
		for component in SpatialPlanning.footprint_components(site):
			if Geometry2D.is_point_in_polygon(p,component):
				inside = true
				break
		if not inside: continue
		var center := Vector2(site["position"][0],site["position"][1])
		draw_string(ThemeDB.fallback_font,point(center)+Vector2(-30,30)*view_zoom,site["name"],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("617b69"))

func _sync_map_labels() -> void:
	community_label_layer.sync(self)

func _draw_community_names() -> void:
	# CommunityNames retains these commands independently of the live HUD.
	pass
