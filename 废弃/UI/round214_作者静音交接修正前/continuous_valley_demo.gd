class_name ContinuousValleyDemo
extends Control
const World = preload("res://scripts/world/continuous_world.gd")
const PlanningCard = preload("res://scripts/world/planning_card.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Projection2D = preload("res://scripts/world/world_projection.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const PublicRelocation = preload("res://scripts/world/public_site_relocation.gd")
const PublicReuse = preload("res://scripts/world/public_site_reuse.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const TransitPlanning = preload("res://scripts/world/transit_planning.gd")
const TransitCharter = preload("res://scripts/world/transit_charter_anchor.gd")
const TransitRework = preload("res://scripts/world/transit_line_rework.gd")
const TransitReworkPreview = preload("res://scripts/world/transit_rework_preview.gd")
const FirstComposition = preload("res://scripts/world/first_composition.gd")
const FirstSoundPlacement = preload("res://scripts/world/first_sound_placement.gd")
const RefinedUi = preload("res://scripts/ui/valley_ui_theme.gd")
const CityVoiceCard = preload("res://scripts/ui/city_voice_card.gd")
const FirstSoundStatus = preload("res://scripts/ui/first_sound_status.gd")
const StreetOrientation = preload("res://scripts/visual/building_street_orientation.gd")
const AuthoredDuet = preload("res://scripts/world/authored_duet.gd")
const FirstAuthoredWork = preload("res://scripts/world/first_authored_work.gd")
const FirstAuthoredContinuation = preload("res://scripts/world/first_authored_continuation.gd")
const FirstAuthoredRouteResult = preload("res://scripts/ui/first_authored_route_result.gd")
const FirstExpressionComparisonCard = preload("res://scripts/ui/first_expression_comparison_card.gd")
const GrowthFeedback = preload("res://scripts/world/growth_feedback.gd")
const PendingCompositionChoice = preload("res://scripts/ui/pending_composition_choice.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const ExpressionPreview = preload("res://scripts/world/expression_preview.gd")
const Config = preload("res://scripts/world/world_values.gd")
const GrowthSprite = preload("res://scripts/visual/audio_growth_mask.gd")
const FacadeLight = preload("res://scripts/visual/classical_facade_light.gd")
const Shadows = preload("res://scripts/visual/city_shadow_layer.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const GroundLayer = preload("res://scripts/visual/valley_ground_layer.gd")
const WaterFlow = preload("res://scripts/visual/valley_water_flow.gd")
const BuildingVariants = preload("res://scripts/visual/building_variant_catalog.gd")
const FirstExpressionIdentity = preload("res://scripts/visual/first_expression_identity.gd")
const StreetEaves = preload("res://scripts/visual/street_eaves_layer.gd")
const Daylight = preload("res://scripts/visual/valley_daylight.gd")
const ArtDirection = preload("res://scripts/visual/city_art_direction.gd")
var building_catalog := BuildingVariants.new()
var art_study_enabled := false
var art_direction := ArtDirection.new()
var art_review_panel: PanelContainer
var street_eaves_layer: Node2D
var daylight_state: Dictionary = {}
var daylight_manual_phase := -1.0
var scenery := ValleyScenery.new()
var frontage_details: Node2D
var core_slice_hud: Node2D
var expression := "bright"
var starter := true
var first_composition_mode := true
var first_composition_guide: Button
var composition_source_id := ""
var authored_composition_choices: VBoxContainer
var expression_choices: Dictionary = {}
var expression_choice := ""
var expression_comparison: Dictionary = {}
var expression_comparison_key: Array = []
var expression_confirm: Button
var expression_listen: Button
var expression_status: Control
var expression_click_preview := false
var authored_badge_style: StyleBoxFlat
var expression_summary: Label
var expression_comparison_summary: Label
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
var facade_lights: Dictionary = {}
var buildings_layer: Node2D
var shadow_layer: CityShadowLayer
var backdrop: ColorRect
var terrain_layer: Node2D
var city_ground_layer: Node2D
var water_flow: Node2D
var community_label_layer: Node2D
var community_workbench: PanelContainer
var community_member_focus: Node2D
var community_entry: Button
var community_camera_key: Array = []
var community_listening_owned := false
var community_saved_listening: Dictionary = {}
var community_saved_mutes: Dictionary = {}
var expression_audition_layer: Node2D
var first_sound_focus: Node2D
var authored_growth_trail: Node2D
var pending_authored_path: Node2D
var pending_composition_choice: Dictionary = {}
var pending_expression_choice: Dictionary = {}
var music_activity_layer: Node2D
var public_space_activity_layer: Node2D
var authored_reservation_layer: Node2D
var authored_voice_badges: Node2D
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
var partial_courtyard_mode := false
var partial_hole_drawing := false
var partial_polygon_holes: Array[PackedVector2Array] = []
var transit_route_mode := false
var transit_route_stops: Array[Vector2] = []
var transit_preview: Dictionary = {}
var transit_preview_key: Array = []
## Transient P12 context; only charter_id is submitted with the authored line.
var transit_charter_context: Dictionary = {}
var transit_edit_context: Dictionary = {}
var transit_edit_choices: VBoxContainer
var transit_edit_choices_key: Array = []
var transit_station_focus_id := ""
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
var street_orientation_cache: Dictionary = {}
var street_orientation_key: Array = []
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
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--art-study" or arg.begins_with("--art-study="):
			art_study_enabled = true
			session_persistence = false
			if arg.begins_with("--art-study="):
				var requested_style := arg.trim_prefix("--art-study=")
				art_direction.selected_id = requested_style if requested_style in ArtDirection.STYLE_IDS else "baseline"
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
	building_catalog.load_catalog()
	for entry: Dictionary in assets.values():
		building_catalog.texture_for(entry)
		building_catalog.image_for(entry)
	building_catalog.prewarm_first_expressions(assets)
	if art_study_enabled:
		art_direction.load_catalog(building_catalog)
		building_catalog.art_direction = art_direction
		daylight_manual_phase = 0.0
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
	building_catalog.prewarm_masks(shadow_layer)
	buildings_layer = Node2D.new()
	buildings_layer.name = "Buildings"
	buildings_layer.y_sort_enabled = true
	add_child(buildings_layer)
	street_eaves_layer = StreetEaves.new()
	street_eaves_layer.name = "StreetEaves"
	buildings_layer.add_child(street_eaves_layer)
	frontage_details = preload("res://scripts/visual/classical_frontage_details.gd").new()
	frontage_details.name = "ClassicalFrontageDetails"
	buildings_layer.add_child(frontage_details)
	frontage_details.setup(self)
	community_label_layer = preload("res://scripts/visual/community_label_layer.gd").new()
	community_label_layer.name = "CommunityNames"
	community_label_layer.z_index = 50
	add_child(community_label_layer)
	expression_audition_layer = preload("res://scripts/visual/expression_audition_layer.gd").new()
	expression_audition_layer.name = "ExpressionAudition"
	expression_audition_layer.z_index = 54
	add_child(expression_audition_layer)
	first_sound_focus = preload("res://scripts/visual/first_sound_focus.gd").new()
	first_sound_focus.name = "FirstSoundFocus"
	add_child(first_sound_focus)
	authored_growth_trail = preload("res://scripts/visual/authored_growth_trail.gd").new()
	authored_growth_trail.name = "AuthoredGrowthTrail"
	authored_growth_trail.z_index = 56
	add_child(authored_growth_trail)
	pending_authored_path = preload("res://scripts/visual/pending_authored_path.gd").new()
	pending_authored_path.name = "PendingAuthoredPath"
	pending_authored_path.setup(self)
	add_child(pending_authored_path)
	authored_voice_badges = preload("res://scripts/visual/authored_voice_badges.gd").new()
	authored_voice_badges.name = "AuthoredVoiceBadges"
	authored_voice_badges.z_index = 65
	add_child(authored_voice_badges)
	core_slice_hud = preload("res://scripts/ui/core_slice_hud.gd").new()
	core_slice_hud.name = "CoreSliceHud"
	core_slice_hud.z_index = 100
	core_slice_hud.setup(self)
	add_child(core_slice_hud)
	music_activity_layer = preload("res://scripts/visual/city_music_activity_layer.gd").new()
	music_activity_layer.name = "MusicActivity"
	music_activity_layer.z_index = 60
	add_child(music_activity_layer)
	authored_reservation_layer = preload("res://scripts/visual/authored_reservation_layer.gd").new()
	authored_reservation_layer.name = "AuthoredReservation"
	add_child(authored_reservation_layer)
	public_space_activity_layer = preload("res://scripts/visual/public_space_activity_layer.gd").new()
	public_space_activity_layer.name = "PublicSpaceActivity"
	public_space_activity_layer.z_index = 59
	add_child(public_space_activity_layer)
	tooltip = Label.new()
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.add_theme_font_size_override("font_size",13)
	tooltip.add_theme_color_override("font_color",RefinedUi.INK)
	tooltip.add_theme_stylebox_override("normal",RefinedUi.panel(12))
	tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip.custom_minimum_size.x = 340.0
	tooltip.size.x = 340.0
	tooltip.z_index = 100
	add_child(tooltip)
	caption = Label.new()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_font_size_override("font_size",14)
	caption.add_theme_color_override("font_color",RefinedUi.PAPER)
	var caption_style := StyleBoxFlat.new()
	caption_style.bg_color = Color(RefinedUi.GREEN,0.96)
	caption_style.set_corner_radius_all(6)
	caption_style.content_margin_left = 14
	caption_style.content_margin_right = 14
	caption_style.content_margin_top = 8
	caption_style.content_margin_bottom = 8
	caption.add_theme_stylebox_override("normal",caption_style)
	caption.z_index = 100
	add_child(caption)
	_make_menu()
	planning_guide = preload("res://scripts/ui/planning_guide.gd").new()
	add_child(planning_guide)
	planning_guide.setup(self)
	menu.theme = planning_guide.theme
	community_workbench = preload("res://scripts/ui/community_workbench.gd").new()
	add_child(community_workbench)
	community_workbench.setup(self)
	community_workbench.listen_requested.connect(_listen_workbench_community)
	community_workbench.planning_requested.connect(_plan_workbench_community)
	community_workbench.author_requested.connect(_open_workbench_author)
	community_workbench.closed.connect(_restore_workbench_listening)
	community_member_focus = preload("res://scripts/visual/community_member_focus.gd").new()
	community_member_focus.name = "CommunityMemberFocus"
	community_member_focus.z_index = 21
	add_child(community_member_focus)
	community_member_focus.setup(self)
	community_entry = Button.new()
	community_entry.text = "街坊 · C"
	community_entry.tooltip_text = "查看整片街坊，听它的声音并继续规划；也可点击地图社区名"
	community_entry.theme = planning_guide.theme
	community_entry.position = Vector2(280,24)
	community_entry.custom_minimum_size = Vector2(108,44)
	community_entry.z_index = 115
	community_entry.pressed.connect(_toggle_community_workbench)
	add_child(community_entry)
	first_composition_guide = preload("res://scripts/ui/first_composition_guide.gd").new()
	add_child(first_composition_guide)
	first_composition_guide.setup(self)
	if art_study_enabled:
		art_review_panel = preload("res://scripts/ui/art_direction_review.gd").new()
		add_child(art_review_panel)
		art_review_panel.setup(self)
	light_player = AudioStreamPlayer.new()
	light_player.volume_db = -8.0
	add_child(light_player)
	preview_player = AudioStreamPlayer.new()
	add_child(preview_player)
	preview_player.finished.connect(func() -> void:
		if expression_click_preview: _cancel_preview_playback())
	var calibration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))
	fixed_gain = float(calibration["gain"])
	clock = get_node("/root/AudioClock") as AudibleAudioClock
	var sample_world: ContinuousWorld = null
	if art_study_enabled and "--art-sample" in OS.get_cmdline_user_args():
		sample_world = preload("res://scripts/world/art_direction_sample.gd").build()
	_start_world({},sample_world)
	if sample_world != null: _message("示例河湾 · 换一套画面，点房屋改音，或按P继续规划")
	_warm_notes()
	if not session_persistence or not load_city(true): clock.start_output(model._mix_frame,{},clock.renderer.snapshot())
	mouse_exited.connect(func() -> void: pointer_inside = false)

func _start_world(saved: Dictionary = {}, example_world: ContinuousWorld = null) -> void:
	if community_workbench.opened: community_workbench.close_tool()
	community_camera_key.clear()
	composition_source_id = ""
	_stop_preview()
	clock.stop_output()
	for sprite in sprites.values(): sprite.queue_free()
	sprites.clear()
	facade_lights.clear()
	if saved.is_empty():
		var world := example_world if example_world != null else World.new("2026100900000062",true,terrain_family)
		if example_world == null:
			if expanded_town_starter: world.build_expanded_town()
			elif town_starter: world.build_town()
			elif starter:
				if first_composition_mode: world.build_first_composition_starter()
				else: world.build_rework_starter(expression)
		model = Model.new(world,fixed_gain)
	else:
		model = Model.from_state(saved["model"])
		expression = str(saved["view"]["expression"])
		first_composition_mode = bool(saved["view"].get("first_composition_mode",false))
		starter = bool(saved["view"]["starter"])
		town_starter = bool(saved["view"].get("town_starter",false))
		expanded_town_starter = bool(model.world.expanded_plan)
		terrain_family = str(model.world.terrain.family)
		fixed_gain = model.synth.gain
	model.enable_music_activity()
	shown_world = model.world
	selected_id = ""
	context.clear()
	expression_choice = ""
	expression_comparison.clear()
	expression_comparison_key.clear()
	pending_expression_choice.clear()
	pending_composition_choice.clear()
	relocation_mode = false
	relocation_site_id = ""
	transit_station_focus_id = ""
	reservation_draw_mode = false
	reservation_draw_points.clear()
	partial_mode = false
	partial_kind = ""
	partial_reservation_id = ""
	partial_polygon_mode = false
	partial_polygon_points.clear()
	partial_multi_component_mode = false
	partial_polygon_components.clear()
	partial_courtyard_mode = false
	partial_hole_drawing = false
	partial_polygon_holes.clear()
	_clear_transit_route()
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
	if saved.is_empty() and shown_world.phrase_index > 0:
		var start_frame := shown_world.phrase_index*int(shown_world.cfg["timing"]["phrase_frames"])
		model.rendered_until = start_frame
		clock.renderer.transport.rendered_frames = start_frame
		clock.renderer.transport.audible_frame = float(start_frame)
	if example_world != null or (saved.is_empty() and first_composition_mode):
		_home_city()
		view_zoom = zoom_target
		pan = pan_target
	_sync_buildings()
	scenery.sync(self)
	frontage_details.sync(self)
	last_saved_event_count = model.world.events.size()
	last_presented_event_count = model.world.events.size()
	last_checkpoint_phrase = model.world.phrase_index
	selected_landmark_candidate = -1
	planning_guide.reset_for_city()
	first_composition_guide.reset_for_city()
	if not saved.is_empty():
		_message("%s · %d栋 · %d个社区" % [shown_world.terrain_title(),shown_world.buildings.size(),shown_world.active_community_count()])
	elif first_composition_mode:
		planning_guide.hide_tool()
		_message("河湾序曲 · 24栋年轻房屋，三个社区 · 先听城市，再写你的第一段")
	elif town_starter:
		_message("%s · 林荫交响 · 完整河谷起点，可继续生长" % shown_world.terrain_title())
	elif starter:
		planning_guide.hide_tool()
		_message("%s · %d栋 · 单圈主题，双虚圈应答 · 点房屋改音，P规划" % [shown_world.terrain_title(),shown_world.buildings.size()])
	else:
		_message("%s · 空地开局 · 点击街边播下第一段声音" % shown_world.terrain_title())

func _make_menu() -> void:
	menu = PanelContainer.new()
	menu.z_index = 110
	menu.set_meta("regular_panel",RefinedUi.panel(18))
	var voice_panel := RefinedUi.panel(16)
	voice_panel.set_corner_radius_all(6)
	voice_panel.border_color = Color("b9aa88")
	menu.set_meta("voice_panel",voice_panel)
	menu.add_theme_stylebox_override("panel",menu.get_meta("regular_panel"))
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation",12)
	menu.add_child(shell)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	shell.add_child(scroll)
	menu.set_meta("scroll",scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	menu.set_meta("content",box)
	menu_info = Label.new()
	menu_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_info.add_theme_color_override("font_color",Color("435c59"))
	menu_info.add_theme_font_size_override("font_size",21)
	box.add_child(menu_info)
	var expression_box := VBoxContainer.new()
	expression_box.add_theme_constant_override("separation",6)
	for choice: Dictionary in PlayerExpression.catalogue():
		var button := CityVoiceCard.new()
		button.setup(choice,self)
		button.pressed.connect(_select_player_expression.bind(str(choice["id"])))
		expression_choices[choice["id"]] = button
		expression_box.add_child(button)
	expression_summary = Label.new()
	expression_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	expression_summary.add_theme_font_size_override("font_size",13)
	expression_summary.add_theme_color_override("font_color",Color("435c59"))
	expression_comparison_summary = Label.new()
	expression_comparison_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	expression_comparison_summary.add_theme_font_size_override("font_size",13)
	expression_comparison_summary.add_theme_color_override("font_color",Color("51665c"))
	expression_comparison_summary.hide()
	expression_box.add_child(expression_comparison_summary)
	var expression_footer := VBoxContainer.new()
	expression_footer.add_theme_constant_override("separation",6)
	menu.set_meta("expression_footer",expression_footer)
	shell.add_child(expression_footer)
	expression_status = FirstSoundStatus.new()
	expression_footer.add_child(expression_status)
	expression_footer.add_child(expression_summary)
	var listen_row := HBoxContainer.new()
	listen_row.add_theme_constant_override("separation",8)
	expression_listen = Button.new()
	expression_listen.text = "试听"
	expression_listen.tooltip_text = "试听当前声音四秒；也可按住空格，松开回到城市"
	expression_listen.custom_minimum_size.y = 34
	expression_listen.pressed.connect(_toggle_expression_listen)
	expression_listen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listen_row.add_child(expression_listen)
	expression_confirm = Button.new()
	expression_confirm.text = "种下这个声音"
	expression_confirm.tooltip_text = "确认后在下一乐句种下当前选中的声音 · Enter"
	expression_confirm.custom_minimum_size.y = 38
	RefinedUi.primary(expression_confirm)
	expression_confirm.pressed.connect(_confirm_player_expression)
	expression_footer.add_child(expression_confirm)
	var expression_back := Button.new()
	expression_back.text = "回到河湾"
	expression_back.tooltip_text = "收起面板并结束试听 · Esc / 右键"
	expression_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.set_meta("expression_back",expression_back)
	expression_back.pressed.connect(func() -> void:
		_cancel_preview_playback()
		menu.hide())
	listen_row.add_child(expression_back)
	expression_footer.add_child(listen_row)
	box.add_child(expression_box)
	menu.set_meta("expression_choices",expression_box)
	transit_edit_choices = VBoxContainer.new()
	box.add_child(transit_edit_choices)
	var notes := HFlowContainer.new()
	for choice: int in [48,50,52,55,57]:
		var button := Button.new()
		button.text = {48:"地基 · C",50:"张力 · D",52:"暖和 · E",55:"开阔 · G",57:"伸展 · A"}[choice]
		button.custom_minimum_size = Vector2(72,38)
		button.pressed.connect(_choose_note.bind(choice))
		button.mouse_entered.connect(func() -> void: _light_note(choice))
		notes.add_child(button)
	box.add_child(notes)
	menu.set_meta("notes",notes)
	low_octave = CheckBox.new()
	low_octave.text = "低八度 · 深流"
	var expressions := HFlowContainer.new()
	expressions.add_child(low_octave)
	for item in [["晴岸合奏","bright"],["深流慢板","deep"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(_set_expression.bind(item[1]))
		expressions.add_child(button)
	box.add_child(expressions)
	menu.set_meta("legacy_expressions",expressions)
	var verbs := HFlowContainer.new()
	for item in [["查看这个街坊","community"],["独听社区","solo"],["静音社区","mute"],["聚焦","focus"],["跨河应答","response"],["规划社区 · P","planning"]]:
		var button := Button.new()
		button.text = item[0]
		if item[1] == "response":
			response_button = button
			button.tooltip_text = "全城唯一跨河应答槽；切换在下一拍生效"
		button.pressed.connect(_verb.bind(item[1]))
		verbs.add_child(button)
	box.add_child(verbs)
	menu.set_meta("listening_verbs",verbs)
	var compose_more := Button.new()
	compose_more.text = "下一段 · 街坊 / 公共空间 / 声音"
	compose_more.tooltip_text = "从街坊开始：选章程、变化卡、公共空间，再听下一段声音；也可按 P"
	compose_more.pressed.connect(_begin_next_composition)
	box.add_child(compose_more)
	menu.set_meta("compose_more",compose_more)
	var care_for_land := Button.new()
	care_for_land.text = "照看这段留下的空地"
	care_for_land.pressed.connect(func() -> void:
		if _authored_retune():
			_begin_first_authored_continuation(str(shown_world.families[str(shown_world.by_id[selected_id]["family_id"])]["root"])))
	box.add_child(care_for_land)
	menu.set_meta("care_for_land",care_for_land)
	authored_composition_choices = preload("res://scripts/ui/authored_composition_choices.gd").new()
	authored_composition_choices.setup(self)
	box.add_child(authored_composition_choices)
	var reservation_choices := HFlowContainer.new()
	for item in [["保持留白 · 回到城市","keep"],["这里建公园","park"],["这里建文化馆","civic"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(func() -> void:
			if item[1] == "keep": menu.hide()
			else: _verb(item[1]))
		reservation_choices.add_child(button)
	box.add_child(reservation_choices)
	menu.set_meta("authored_reservation_choices",reservation_choices)
	var reuse_button := Button.new()
	reuse_button.text = "原位改用 · 试听"
	reuse_button.tooltip_text = "固定现有占地，比较保留当前用途、公园与文化馆"
	reuse_button.pressed.connect(_verb.bind("reuse_public"))
	planning_buttons["reuse_public"] = reuse_button
	box.add_child(reuse_button)
	var details_toggle := Button.new()
	details_toggle.text = "声部详细条件 · 展开 / 收起"
	details_toggle.toggle_mode = true
	box.add_child(details_toggle)
	var details := Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_color_override("font_color",Color("51665c"))
	details.add_theme_font_size_override("font_size",14)
	details.hide()
	box.add_child(details)
	details_toggle.toggled.connect(func(expanded: bool) -> void:
		details.visible = expanded
		_planning_menu())
	menu.set_meta("details_toggle",details_toggle)
	menu.set_meta("details_label",details)
	var public_toggle := Button.new()
	public_toggle.text = "公共空间与公交工具 · 展开 / 收起"
	public_toggle.toggle_mode = true
	box.add_child(public_toggle)
	var public_row := HFlowContainer.new()
	for item in [["建公园","park"],["文化设施","civic"],["局部公园","partial_park"],["局部文化馆","partial_civic"],["自由局部公园","free_partial_park"],["自由局部文化馆","free_partial_civic"],["自由分块公园","free_multi_partial_park"],["自由分块文化馆","free_multi_partial_civic"],["自由内院公园","free_courtyard_park"],["自由内院文化馆","free_courtyard_civic"],["搬迁公共设施","relocate_public"],["留地","reserve"],["自由留地","free_reserve"],["释放留地","release_reservation"],["连接两岸","bridge"],["规划公交线路","plan_transit"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(_verb.bind(item[1]))
		public_row.add_child(button)
		planning_buttons[item[1]] = button
	box.add_child(public_row)
	public_toggle.toggled.connect(func(expanded: bool) -> void:
		public_row.visible = expanded
		_planning_menu())
	menu.set_meta("public_toggle",public_toggle)
	menu.set_meta("public_tools",public_row)
	var city_toggle := Button.new()
	city_toggle.text = "作品与城市入口 · 展开 / 收起"
	city_toggle.toggle_mode = true
	box.add_child(city_toggle)
	var city_tools := VBoxContainer.new()
	city_tools.add_theme_constant_override("separation",8)
	city_tools.hide()
	box.add_child(city_tools)
	city_toggle.toggled.connect(func(expanded: bool) -> void:
		city_tools.visible = expanded
		_planning_menu())
	menu.set_meta("city_toggle",city_toggle)
	menu.set_meta("city_tools",city_tools)
	var archive_row := HFlowContainer.new()
	for item in [["存一版 · Ctrl+S","save"],["继续上次 · F9","load"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(func() -> void:
			if item[1] == "save": save_city()
			else: load_city()
			menu.hide())
		archive_row.add_child(button)
	city_tools.add_child(archive_row)
	var dna_row := HFlowContainer.new()
	var dna_button := Button.new()
	dna_button.text = "继续最近DNA"
	dna_button.tooltip_text = "从最近导出的 City DNA JSON 恢复城市、音乐与镜头"
	dna_button.pressed.connect(load_dna)
	dna_row.add_child(dna_button)
	city_tools.add_child(dna_row)
	var export_button := Button.new()
	export_button.text = "导出城市DNA · Ctrl+Shift+E"
	export_button.tooltip_text = "导出可读的城市、地形、道路、设施、交通与音乐编曲 JSON"
	export_button.clip_text = true
	export_button.pressed.connect(export_dna)
	city_tools.add_child(export_button)
	var first_button := Button.new()
	first_button.text = "新河湾 · 写第一段 · Shift+R"
	first_button.pressed.connect(_start_first_composition)
	city_tools.add_child(first_button)
	var town_button := Button.new()
	town_button.text = "林荫交响 · T"
	town_button.tooltip_text = "切换到完整河谷起点；当前作品先保存，之后仍可继续生长"
	town_button.pressed.connect(_start_town)
	city_tools.add_child(town_button)
	var expanded_button := Button.new()
	expanded_button.text = "多中心街坊 · E"
	expanded_button.tooltip_text = "48个规划社区、内外台地支路、绿廊与150栋以上成长起点"
	expanded_button.pressed.connect(_start_expanded_town)
	city_tools.add_child(expanded_button)
	var regional_button := Button.new()
	regional_button.text = "三河段大城 · Shift+E"
	regional_button.tooltip_text = "进入1500栋以上自然成长样本；可继续成长、调音和规划公共空间，当前作品先保存"
	regional_button.pressed.connect(_start_regional_town)
	city_tools.add_child(regional_button)
	var terrain_button := Button.new()
	terrain_button.text = "切换地形族 · Y"
	terrain_button.tooltip_text = "河谷、湖盆、林岭、海湾平原、高地峡谷共享连续城市操作"
	terrain_button.pressed.connect(_cycle_terrain)
	city_tools.add_child(terrain_button)
	add_child(menu)
	menu.visibility_changed.connect(func() -> void:
		if not menu.visible and _expression_context(): _cancel_preview_playback())
	menu.hide()

func _apply_expression_button_style(button: Button, choice_id: String) -> void:
	## Give each first-composition route a quiet visual identity before the
	## player hears it. The pressed/hover states stay in the same family so the
	## card remains calm while the three choices are easy to scan.
	var palette: Dictionary = {
		"deep":{"fill":Color("e8e6f0"),"hover":Color("dcd9e8"),"pressed":Color("c7c1df"),"edge":Color("7c78a5")},
		"weave":{"fill":Color("f0ead4"),"hover":Color("e7ddbd"),"pressed":Color("d8c793"),"edge":Color("b18b55")},
		"warm":{"fill":Color("e2ecdf"),"hover":Color("d4e5d0"),"pressed":Color("bdd6ba"),"edge":Color("6f9b74")},
	}.get(choice_id,{"fill":Color("eef0e8"),"hover":Color("e2e8dc"),"pressed":Color("cbd9c6"),"edge":Color("789272")})
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = palette["fill"]
		if state == "hover": style.bg_color = palette["hover"]
		elif state == "pressed": style.bg_color = palette["pressed"]
		style.border_color = palette["edge"]
		style.set_border_width(SIDE_LEFT,4)
		style.set_border_width(SIDE_TOP,1)
		style.set_border_width(SIDE_RIGHT,1)
		style.set_border_width(SIDE_BOTTOM,1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 12
		style.content_margin_right = 12
		button.add_theme_stylebox_override(state,style)

func _cycle_terrain() -> void:
	_save_before_switch()
	first_composition_mode = false
	var families: Array[String] = ValleyTerrain.family_ids()
	var index := families.find(terrain_family)
	terrain_family = families[posmod(index+1,families.size())]
	town_starter = true
	starter = true
	expression = "bright"
	_start_world()
	clock.start_output(model._mix_frame,{},clock.renderer.snapshot())
	_message("已切换到"+shown_world.terrain_title()+" · 新地形城市已准备，P选择发展方向")

func _save_before_switch() -> void:
	if session_persistence and model != null and clock.active: save_city("切换前保存")

func _start_regional_town() -> void:
	_save_before_switch()
	first_composition_mode = false
	starter = true
	town_starter = true
	expanded_town_starter = true
	expression = "bright"
	_start_world({},World.regional_sample())
	clock.start_output(model._mix_frame,{},clock.renderer.snapshot())
	_message("三河段大城 · %d栋 · %d个社区 · 滚轮放大查看街坊，H看全城" % [shown_world.buildings.size(),shown_world.active_community_count()])

func _home_city() -> void:
	if first_composition_mode and not shown_world.buildings.is_empty():
		_frame_first_composition()
		return
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

func _frame_first_composition() -> void:
	var bounds := Rect2()
	var first := true
	for building: Dictionary in shown_world.buildings:
		var p := Coupling.position_of(building)
		var projected := Projection2D.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),shown_world.terrain.height_at(p))
		if first:
			bounds = Rect2(projected,Vector2.ZERO)
			first = false
		else: bounds = bounds.expand(projected)
	zoom_target = clampf(minf((size.x-260.0)/maxf(1.0,bounds.size.x),(size.y-260.0)/maxf(1.0,bounds.size.y)),0.65,1.65)
	pan_target = -bounds.get_center()*zoom_target+Vector2(0,-12)

func _start_expanded_town() -> void:
	_save_before_switch()
	first_composition_mode = false
	starter = true
	town_starter = true
	expanded_town_starter = true
	expression = "bright"
	_start_world()
	clock.start_output(model._mix_frame,{},clock.renderer.snapshot())
	_message("多中心街坊 · "+str(shown_world.active_community_count())+"个社区 · "+str(shown_world.buildings.size())+"栋起点")

func _start_town() -> void:
	_save_before_switch()
	first_composition_mode = false
	starter = true
	town_starter = true
	expanded_town_starter = false
	expression = "bright"
	_start_world()
	clock.start_output(model._mix_frame,{},clock.renderer.snapshot())

func _cancel_preview_playback() -> void:
	preview_requested = false
	preview_started = false
	expression_click_preview = false
	if is_instance_valid(preview_player): preview_player.stop()
	if preview_duck_owned and model != null:
		model.synth.ducking = preview_saved_ducking
		model.synth.duck_release_at = preview_saved_release
	preview_duck_owned = false
	_sync_expression_listen()

func _invalidate_transit_preview() -> void:
	# A route redraw/cancel makes any in-flight PCM result stale.  The worker may
	# finish later, but its old request key must not be accepted for the new map.
	if preview_requested or preview_started:
		_cancel_preview_playback()
	preview_context_key.clear()
	if planning_guide != null: planning_guide.clear_transit_comparison()

func _stop_preview() -> void:
	_cancel_preview_playback()
	if preview_thread != null:
		preview_thread.wait_to_finish()
		preview_thread = null
	if is_instance_valid(preview_player): preview_player.stop()

func capture_city() -> Dictionary:
	return {"model":model.capture_state(),"renderer":clock.renderer.snapshot(),
		"view":{"expression":expression,"first_composition_mode":first_composition_mode,"starter":starter,"town_starter":town_starter,"zoom":view_zoom,"pan":pan,
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
	for base: int in [36,38,40,43,45,48,50,52,55,57,60,62,64,67,69]:
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
	var pitch := _note_pitch(note)
	light_player.stream = light_notes[pitch]
	light_player.play()

func _authored_retune() -> bool:
	return context.get("kind","") == "retune" and bool(shown_world.by_id.get(str(context.get("id","")),{}).get("player_expression",false))

func _note_pitch(base: int) -> int:
	if _authored_retune():
		var id := str(context["id"])
		var current := int(model.audible_pitches().get(id,shown_world.by_id[id]["current_midi"]))
		var register := floori(float(current)/12.0)*12
		if Input.is_key_pressed(KEY_SHIFT): register = maxi(36,register-12)
		return base-48+register
	return base-12 if low_octave.button_pressed or Input.is_key_pressed(KEY_SHIFT) else base

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
	var road_style_key: String = shown_world.network.topology+":"+art_direction.selected_id
	if road_draw_key == road_style_key: return
	road_draw_key = road_style_key
	road_draw_polygons.clear()
	# Polygon projections depend on mutable occupancy/derived geometry too;
	# prune those entries at each topology or city phrase instead of keeping history.
	projected_ground.clear()
	for road in shown_world.roads:
		var width := 0.55 if road["bridge"] else (float(shown_world.cfg["city"]["branch_road_half_width"]) if road.get("kind","") == "branch" else float(shown_world.cfg["terrain"]["template_road_half_width"]))
		for polygon in Geometry2D.offset_polyline(road["path"],width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
			var palette: Dictionary = art_direction.palette()
			road_draw_polygons.append({"polygon":polygon,"color":Color(palette.get("bridge","d3bb93")) if road["bridge"] else Color(palette.get("road","f1eee0"))})

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
		var image: Image = building_geometry[id]["image"]
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
			if community_workbench.opened:
				community_workbench.close_tool()
				return
			var cancelling_transit_edit := not transit_edit_context.is_empty()
			_clear_transit_route()
			transit_station_focus_id = ""
			_clear_partial_draft()
			reservation_draw_mode = false
			reservation_draw_points.clear()
			relocation_mode = false
			relocation_site_id = ""
			if not cancelling_transit_edit: model.cancel_pending()
			menu.hide()
			planning_guide.hide_tool()
			context.clear()
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not black:
			if transit_route_mode:
				_append_transit_stop(world_at(pointer))
				return
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
			var station_click := _transit_station_at(world_at(pointer))
			if not station_click.is_empty():
				transit_station_focus_id = str(station_click.get("id",""))
				selected_id = ""
				context = {"kind":"transit_station","id":transit_station_focus_id}
				menu_info.text = _transit_station_context_text(station_click)
				_show_context_menu()
				return
			if planning_guide.map_click(world_at(pointer),Input.is_key_pressed(KEY_SHIFT)): return
			var named_community: String = community_label_layer.hit_community(pointer)
			if not named_community.is_empty():
				_open_community_workbench(named_community)
				return
			if community_workbench.opened:
				var member_id := _hit(pointer)
				if not member_id.is_empty():
					_open_community_workbench(str(shown_world.by_id[member_id]["community_id"]))
				else: community_workbench.close_tool()
				return
			var authored_root: String = authored_voice_badges.hit_root(pointer)
			if not authored_root.is_empty():
				_open_authored_root(authored_root)
				return
			var landmark_index := _landmark_candidate_at(pointer)
			if landmark_index >= 0:
				_select_landmark_candidate(landmark_index)
				menu.hide()
				return
			var authored_target: Dictionary = authored_reservation_layer.hit_reservation(pointer)
			var id := _hit(pointer) if authored_target.is_empty() else ""
			if not id.is_empty():
				selected_id = id
				context = {"kind":"retune","id":id}
				menu_info.text = "给这栋建筑换一个音"
			else:
				var p: Vector2 = world_at(pointer) if authored_target.is_empty() else authored_target["position"]
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
				if first_composition_mode:
					context["first_composition"] = true
					context["community_id"] = str(check.get("community_id",""))
				menu_info.text = "播种声音 · "+str(check["preview"])+"\n也可选定这片地营造公共空间"
			_planning_menu()
			_show_context_menu()

func _toggle_community_workbench() -> void:
	if community_workbench.opened:
		community_workbench.close_tool()
		return
	var cid := str(shown_world.by_id.get(selected_id,{}).get("community_id",""))
	if cid.is_empty():
		var nearest := INF
		for community: Dictionary in overlay_communities:
			if int(community["members"]) == 0: continue
			var distance: float = point(community["position"]).distance_squared_to(pointer)
			if distance < nearest:
				nearest = distance
				cid = str(community["id"])
	if cid.is_empty():
		_message("先种下一段声音，再查看它所在的街坊")
		return
	_open_community_workbench(cid)

func _open_community_workbench(cid: String) -> void:
	_cancel_preview_playback()
	_clear_transit_route()
	_clear_partial_draft()
	reservation_draw_mode = false
	reservation_draw_points.clear()
	relocation_mode = false
	relocation_site_id = ""
	planning_guide.hide_tool()
	menu.hide()
	selected_id = ""
	context.clear()
	community_camera_key.clear()
	community_workbench.open_community(cid)

func _workbench_sound(operation: Dictionary) -> void:
	var tagged := operation.duplicate(true)
	tagged["workbench_listener"] = true
	model.submit(tagged)

func _listen_workbench_community(cid: String) -> void:
	if cid.is_empty():
		_restore_workbench_listening(true)
		return
	if not community_listening_owned:
		var score := model.audible_score()
		community_saved_listening = {"listener":str(score.get("listener_community","")),"focus":str(score.get("focused_community",""))}
		community_listening_owned = true
	if not community_saved_mutes.has(cid):
		community_saved_mutes[cid] = bool(model.audible_score().get("muted_communities",{}).get(cid,false))
	# Replace only this temporary workbench's not-yet-rendered controls.
	model.sound_events = model.sound_events.filter(func(event: Dictionary) -> bool: return not bool(event.get("workbench_listener",false)))
	_workbench_sound({"kind":"mute","community":cid,"enabled":false})
	_workbench_sound({"kind":"focus","community":""})
	_workbench_sound({"kind":"solo","community":cid})

func _restore_workbench_listening(full_city: bool = false) -> void:
	if not community_listening_owned and not full_city: return
	model.sound_events = model.sound_events.filter(func(event: Dictionary) -> bool: return not bool(event.get("workbench_listener",false)))
	for cid: String in community_saved_mutes:
		_workbench_sound({"kind":"mute","community":cid,"enabled":community_saved_mutes[cid]})
	_workbench_sound({"kind":"solo","community":"" if full_city else str(community_saved_listening.get("listener",""))})
	_workbench_sound({"kind":"focus","community":"" if full_city else str(community_saved_listening.get("focus",""))})
	community_listening_owned = false
	community_saved_listening.clear()
	community_saved_mutes.clear()

func _plan_workbench_community(cid: String) -> void:
	_restore_workbench_listening(true)
	community_workbench.close_tool()
	planning_guide.open_tool_from_community(cid)

func _open_workbench_author(root_id: String) -> void:
	_restore_workbench_listening(true)
	community_workbench.close_tool()
	_open_authored_root(root_id)

func _frame_workbench_community() -> void:
	var bounds := Rect2()
	var first := true
	for id: String in community_workbench.state.get("member_ids",[]):
		var p: Vector2 = Coupling.position_of(shown_world.by_id[id])
		var projected: Vector2 = Projection2D.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),shown_world.terrain.height_at(p))
		if first:
			bounds = Rect2(projected,Vector2.ZERO)
			first = false
		else: bounds = bounds.expand(projected)
	if first: return
	var clear := Rect2(Vector2(86,166),Vector2(community_workbench.position.x-172,size.y-292))
	zoom_target = clampf(minf(clear.size.x/maxf(1,bounds.size.x),clear.size.y/maxf(1,bounds.size.y)),0.55,1.65)
	pan_target = clear.get_center()-Vector2(size.x*0.5,size.y*0.52)-bounds.get_center()*zoom_target

func _start_first_composition() -> void:
	_save_before_switch()
	first_composition_mode = true
	starter = true
	town_starter = false
	expanded_town_starter = false
	terrain_family = "river_valley"
	expression = "warm"
	_start_world()
	clock.start_output(model._mix_frame,{},clock.renderer.snapshot())

func _expression_context() -> bool:
	return first_composition_mode and context.get("kind","") == "seed"

func _first_authored_state(preferred_root: String = "") -> Dictionary:
	if not first_composition_mode: return {}
	var work := FirstAuthoredWork.state(shown_world,model.audible_score(),model.audible_pitches(),preferred_root)
	if work.is_empty(): return work
	work["root_heard_retune"] = false
	if bool(work["retuned"]):
		for event: Dictionary in model.audible_music_activity(clock.renderer.transport.audible_frame):
			if int(event["generation"]) == 0 and str(event["source_id"]) == str(work["root_id"]) and posmod(int(event["pitch"]),12) == posmod(int(work["current_midi"]),12):
				work["root_heard_retune"] = true
				break
	return work

func _begin_first_authored_theme() -> bool:
	var work := _first_authored_state()
	return _begin_authored_theme(str(work.get("root_id","")))

func _open_authored_root(root_id: String) -> void:
	var work := _first_authored_state(root_id)
	if work.is_empty(): return
	if bool(work["theme_eligible"]):
		_begin_authored_theme(root_id)
		return
	_cancel_preview_playback()
	planning_guide.hide_tool()
	selected_id = root_id
	context = {"kind":"retune","id":root_id}
	planning_guide._focus_planning_position(work["position"])
	pointer = point(Coupling.position_of(shown_world.by_id[root_id]))
	_show_context_menu()
	_message("你的"+str(PlayerExpression.definition(str(work["expression"]))["label"])+" · 点音符改音，或选择下一段继续规划")

func _begin_authored_theme(root_id: String) -> bool:
	if root_id.is_empty(): return false
	var work := _first_authored_state(root_id)
	if work.is_empty() or not bool(work["theme_eligible"]): return false
	var id := str(work["root_id"])
	if not shown_world.by_id.has(id): return false
	_cancel_preview_playback()
	planning_guide.hide_tool()
	selected_id = id
	context = {"kind":"retune","id":id,"first_authored_theme":true}
	# This explicit listening action targets the player's own community. The
	# ordinary beat-level controls preserve the unique theme slot and rest bars.
	var score := model.audible_score()
	if not str(score.get("listener_community","")).is_empty() and str(score["listener_community"]) != str(work["community_id"]):
		model.submit({"kind":"solo","community":""})
	if bool(score.get("muted_communities",{}).get(str(work["community_id"]),false)):
		model.submit({"kind":"mute","community":work["community_id"],"enabled":false})
	model.submit({"kind":"focus","community":work["community_id"]})
	planning_guide._focus_planning_position(shown_world.by_id[id]["position"])
	pointer = point(Coupling.position_of(shown_world.by_id[id]))
	_show_context_menu()
	_message(str(work["community_name"])+" · 听自己种下的主题，亲自改一个音；Esc回到全城")
	return true

func _begin_first_authored_continuation(preferred_root: String = "") -> bool:
	## Locate the next real authored result without creating a new save state.
	## A live reservation gets the planning context; otherwise the actual root
	## house is opened for listening/retuning. Theme entry keeps its existing
	## focus behavior once the community is genuinely eligible.
	var work := _first_authored_state(preferred_root)
	if work.is_empty() or shown_world == null: return false
	var score: Dictionary = model.audible_score()
	var continuation := FirstAuthoredContinuation.state(shown_world,work,score)
	var action: Dictionary = continuation.get("action",{})
	if not bool(action.get("available",false)): return false
	var kind := str(action.get("kind",""))
	if kind == "reservation":
		var reservation_id := str(action.get("id",""))
		var raw: Array = action.get("position",[])
		if reservation_id.is_empty() or raw.size() != 2: return false
		var reservation := shown_world.planning_at(Vector2(float(raw[0]),float(raw[1])))
		if reservation.is_empty() or str(reservation.get("reservation_id",reservation.get("id",""))) != reservation_id: return false
		_cancel_preview_playback()
		planning_guide.hide_tool()
		selected_id = ""
		context = {"kind":"reservation","id":reservation_id,"position":raw.duplicate()}
		menu_info.text = "你留下的空地 · "+str(work["community_name"])+"\n继续保留呼吸的位置，或亲自营造公共空间"
		planning_guide._focus_planning_position(raw)
		_show_context_menu()
		_message(str(work["community_name"])+" · 已定位真实留地，继续规划或释放")
		return true
	if kind in ["root","community","child"]:
		# A community target has no invented future building position. Locate the
		# actual authored root as the player's concrete entry to that community.
		var root_id := str(action.get("id",work.get("root_id",""))) if kind == "child" else str(work.get("root_id",action.get("id","")))
		if root_id.is_empty() or not shown_world.by_id.has(root_id): return false
		if kind != "child" and bool(work.get("theme_eligible",false)): return _begin_authored_theme(root_id)
		_cancel_preview_playback()
		planning_guide.hide_tool()
		selected_id = root_id
		context = {"kind":"retune","id":root_id}
		planning_guide._focus_planning_position(shown_world.by_id[root_id]["position"])
		_show_context_menu()
		var building: Dictionary = shown_world.by_id[root_id]
		var label := "已定位最近新屋" if kind == "child" else "已定位首作房屋"
		_message(str(work["community_name"])+" · "+label+" · 音级"+note_name(int(building.get("current_midi",work.get("current_midi",48)))))
		return true
	return false

func _begin_next_composition() -> void:
	_cancel_preview_playback()
	var work := _first_authored_state()
	composition_source_id = str(work.get("root_id",""))
	if _authored_retune():
		var family_id := str(shown_world.by_id[selected_id]["family_id"])
		composition_source_id = str(shown_world.families[family_id]["root"])
	model.submit({"kind":"focus","community":""})
	model.submit({"kind":"solo","community":""})
	selected_id = ""
	context.clear()
	menu.hide()
	_home_city()
	planning_guide.open_tool()
	_message("继续规划 · 选发展方向、街坊、公共空间和声音；让不同声音一起演奏")

func _listen_authored_duet(root_id: String) -> void:
	if not shown_world.by_id.has(root_id): return
	var cid := str(shown_world.by_id[root_id]["community_id"])
	_cancel_preview_playback()
	model.submit({"kind":"solo","community":""})
	model.submit({"kind":"focus","community":cid})
	planning_guide.hide_tool()
	menu.hide()
	_home_city()
	_message(str(shown_world.communities[cid]["name"])+"先唱 · 协和的对岸房屋延两拍回答；点任一段继续改音")

func _resume_full_composition() -> void:
	model.submit({"kind":"solo","community":""})
	model.submit({"kind":"focus","community":""})
	menu.hide()
	planning_guide.hide_tool()
	_home_city()
	_message("回到全城合奏 · 点击左上“下一段”或按 P：从街坊开始，再选公共空间和声音")

func _authored_reservation_context() -> bool:
	if not first_composition_mode or context.get("kind","") != "reservation": return false
	var id := str(context.get("id",""))
	return shown_world.families.values().any(func(family: Dictionary) -> bool:
		return bool(family.get("player_expression",false)) and not id.is_empty() and str(family.get("expression_reservation_id","")) == id)

func _begin_first_sound_choice(cid: String,_at: Vector2 = Vector2.INF) -> bool:
	var choices: Array = FirstComposition.opportunities(shown_world).get("seed_candidates",[])
	var candidates: Array = []
	for possible: Dictionary in choices:
		if str(possible.get("community_id","")) == cid:
			candidates.append(possible)
	if shown_world.by_id.has(composition_source_id):
		var duet_candidates: Array = AuthoredDuet.candidates(shown_world,composition_source_id,cid,-1)
		if not duet_candidates.is_empty(): candidates = duet_candidates
	var candidate := FirstSoundPlacement.recommend(model.world,candidates,model.next_boundary)
	if candidate.is_empty():
		_message("这片社区的空地已占用 · 点另一处街边继续选声音")
		return false
	var raw: Array = candidate["position"]
	var position := Vector2(float(raw[0]),float(raw[1]))
	# Use the street opportunity, including continuous land beside a real
	# block. A closer lot to the civic anchor can be a disconnected road end.
	planning_guide.hide_tool()
	selected_id = ""
	context = {"kind":"seed","position":[position.x,position.y],"community_id":cid,"first_composition":true}
	planning_guide._focus_planning_position(context["position"])
	pointer = point(position)
	_show_context_menu()
	_message("选择这块地怎样唱 · 点方向立即听四秒，确认才种下；可点其他空地换落点")
	return true

func _select_player_expression(choice: String) -> void:
	if not _expression_context(): return
	expression_choice = choice
	# A deliberate route click is the audition action. Keep held Space's
	# release-to-return behavior, otherwise the four-second stream ends itself.
	expression_click_preview = not Input.is_key_pressed(KEY_SPACE)
	_update_expression_menu()
	_request_expression_preview()
	_sync_expression_listen()

func _toggle_expression_listen() -> void:
	if not _expression_context() or expression_choice.is_empty(): return
	if preview_requested:
		_cancel_preview_playback()
		return
	expression_click_preview = true
	_request_expression_preview()
	_sync_expression_listen()

func _sync_expression_listen() -> void:
	if not is_instance_valid(expression_listen): return
	for choice_id: String in expression_choices:
		expression_choices[choice_id].set_listening(preview_started and preview_requested and choice_id == expression_choice)
	expression_listen.disabled = expression_choice.is_empty()
	expression_listen.text = "停止试听" if preview_requested else "再听四秒"
	if expression_choice.is_empty(): expression_listen.text = "试听"

func _update_expression_menu() -> void:
	_sync_expression_listen()
	for choice: String in expression_choices:
		(expression_choices[choice] as Button).set_pressed_no_signal(choice == expression_choice)
		if context.has("position"):
			var at := Vector2(float(context["position"][0]),float(context["position"][1]))
			expression_choices[choice].set_building_entry(building_catalog.preview_entry(choice,_street_orientation(at)),self)
	expression_confirm.disabled = expression_choice.is_empty()
	var comparison_ready := not expression_comparison.is_empty() and expression_comparison_key == _expression_preview_identity()
	if is_instance_valid(expression_comparison_summary):
		# Each illustrated route already states its identity. Keep the full
		# comparison text available without repeating all three beneath it.
		expression_comparison_summary.hide()
		if comparison_ready:
			expression_comparison_summary.text = FirstExpressionComparisonCard.text(expression_comparison,expression_choice)
	var cid := str(context.get("community_id",""))
	var name_text := str(shown_world.communities.get(cid,{}).get("name","这片街坊"))
	menu_info.text = name_text+" · 声音性格"
	if expression_choice.is_empty():
		expression_summary.text = "确认后，在这块地长出你的房屋。"
		return
	var choice := PlayerExpression.definition(expression_choice)
	expression_summary.text = str(choice["city"])
	if not expression_comparison.is_empty() and expression_comparison_key == _expression_preview_identity():
		var variant: Dictionary = expression_comparison["variants"][expression_choice]
		if not bool(variant["accepted"]):
			expression_summary.text = str(variant["reason"])
			expression_confirm.disabled = true
		else:
			var consequence: Dictionary = variant["consequences"]
			expression_summary.text = "下一句长出%s" % ("商业" if consequence["type"] == "commercial" else "住宅")
			if int(consequence.get("reservation_count",0)) > 0: expression_summary.text += " · 留下可规划空地"

func _expression_preview_identity() -> Array:
	# The preview worker freezes the renderer at the current render cursor.  A
	# same-phrase cursor shift changes oscillator phases and the four-second PCM,
	# even when the world and boundary are unchanged.  Use a four-second cursor
	# slice: it is long enough for the real worker to finish, while a result from
	# a player who leaves the menu open across a slice is rejected before it is
	# played or attached to the confirmation UI.
	var preview_cursor_bucket := maxi(1,int(clock.renderer.transport.sample_rate)*4)
	var render_cursor := floori(float(clock.renderer.transport.rendered_frames)/preview_cursor_bucket)
	return [context.get("position",[]),model.next_boundary,render_cursor,model.world.action_serial,hash(model.world.pending_actions),
		hash(model.sound_events),hash(model.synth.pitch_overrides),model.synth.focused_community,model.synth.listener_community,
		model.synth.response_enabled,hash(model.synth.muted_communities),model.synth.gain,hash(model.synth.score)].duplicate(true)

func _request_expression_preview() -> void:
	if expression_choice.is_empty():
		_message("点深流、织机或暖庭，立即试听；确认才种下")
		return
	preview_requested = true
	preview_public = false
	var key := _expression_preview_identity()
	if not expression_comparison.is_empty() and expression_comparison_key == key:
		_play_expression_preview()
		return
	_prepare_expression_comparison()

func _prepare_expression_comparison() -> void:
	var key := _expression_preview_identity()
	if not expression_comparison.is_empty() and expression_comparison_key == key: return
	if preview_thread != null: return
	# A stale branch must stop before a new worker starts. Its finished signal
	# must not cancel the new click's request while the replacement is preparing.
	if preview_player.playing:
		preview_player.stop()
		if preview_duck_owned:
			model.synth.ducking = preview_saved_ducking
			model.synth.duck_release_at = preview_saved_release
			preview_duck_owned = false
	var frozen := model.freeze()
	if preview_duck_owned:
		frozen.synth.ducking = preview_saved_ducking
		frozen.synth.duck_release_at = preview_saved_release
	preview_started = false
	preview_thread = Thread.new()
	preview_thread.start(_build_expression_preview.bind(frozen,context["position"].duplicate(),clock.renderer.state.duplicate(true),clock.renderer.transport.rendered_frames,key))
	if preview_requested: _message("取得同一下一句 · 三种真实声音正在准备")

func _build_expression_preview(source: ContinuousAudioModel,position: Array,state: Dictionary,at: int,key: Array) -> Dictionary:
	var result := ExpressionPreview.build(source,position,state,at)
	result["request_key"] = key
	return result

func _play_expression_preview() -> void:
	var variant: Dictionary = expression_comparison["variants"][expression_choice]
	if not bool(variant["accepted"]):
		_cancel_preview_playback()
		_message(str(variant["reason"]))
		return
	_play_preview_pcm(variant["pcm"])
	_sync_expression_listen()
	_message(str(PlayerExpression.definition(expression_choice)["label"])+("试听 · 四秒后回到城市；切换方向听同一下一句" if expression_click_preview else "试听 · 松开恢复城市；切换方向听同一下一句"))

func _confirm_player_expression() -> void:
	if not _expression_context() or expression_choice.is_empty() or expression_confirm.disabled: return
	var operation := PlayerExpression.operation(expression_choice,context["position"])
	var visual_variant: Dictionary = expression_comparison.get("variants",{}).get(expression_choice,{}) if expression_comparison_key == _expression_preview_identity() else {}
	_cancel_preview_playback()
	var result := model.submit(operation)
	if not bool(result["accepted"]):
		_message(str(result["reason"]))
		return
	pending_expression_choice = {"operation":operation.duplicate(true),"boundary_frame":int(result["frame"]),"event_id":int(result["event_id"]),"source_model":model}
	if not visual_variant.is_empty() and int(expression_comparison["boundary_frame"]) == int(result["frame"]) and visual_variant["operation"] == operation:
		expression_audition_layer.queue_choice(visual_variant,int(result["frame"]),int(result["event_id"]))
	var p: Array = operation["position"]
	ripple_position = Vector2(float(p[0]),float(p[1]))
	ripple_seconds = 0.6
	menu.hide()
	_message(str(PlayerExpression.definition(expression_choice)["label"])+"已选好 · 下一句长出房屋；落成后可改音或继续下一段")

func _choose_note(choice: int) -> void:
	if _expression_context(): return
	midi = _note_pitch(choice)
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
	authored_voice_badges.hide()
	var retuning: bool = context.get("kind","") == "retune"
	if _expression_context():
		_cancel_preview_playback()
		expression_choice = ""
		expression_comparison.clear()
		expression_comparison_key.clear()
		_update_expression_menu()
		zoom_target = 1.9
	var details_toggle: Button = menu.get_meta("details_toggle")
	details_toggle.set_pressed_no_signal(false)
	(menu.get_meta("details_label") as Label).hide()
	var public_toggle: Button = menu.get_meta("public_toggle")
	public_toggle.set_pressed_no_signal(not retuning and not _expression_context() and not _authored_reservation_context())
	(menu.get_meta("public_tools") as Control).visible = public_toggle.button_pressed
	var city_toggle: Button = menu.get_meta("city_toggle")
	city_toggle.set_pressed_no_signal(false)
	(menu.get_meta("city_tools") as Control).hide()
	(menu.get_meta("scroll") as ScrollContainer).scroll_vertical = 0
	opportunity_key.clear()
	_update_selected_opportunity()
	_planning_menu()
	menu.size = menu.get_combined_minimum_size()
	menu.position = Vector2(clampf(pointer.x-100,12,maxf(12,size.x-menu.size.x-12)),clampf(pointer.y+22,70,maxf(70,size.y-menu.size.y-12)))
	menu.set_meta("target_on_right",pointer.x >= size.x*0.5)
	_place_first_composition_menu()
	menu.show()
	if _expression_context(): expression_choices["deep"].grab_focus()

func _place_first_composition_menu() -> void:
	if not first_composition_mode or not (_expression_context() or _authored_retune() or _authored_reservation_context()): return
	# Keep the player's actual parcel/house visible beside its choices.
	var target_on_right := bool(menu.get_meta("target_on_right",true))
	menu.position.x = 12.0 if target_on_right else maxf(12.0,size.x-menu.size.x-12.0)
	menu.position.y = clampf(size.y*0.5-menu.size.y*0.5,78.0,maxf(78.0,size.y-menu.size.y-82.0))
	var at := Vector2.INF
	if context.has("position"):
		at = Vector2(float(context["position"][0]),float(context["position"][1]))
	elif _authored_retune() and shown_world.by_id.has(selected_id):
		at = Coupling.position_of(shown_world.by_id[selected_id])
	if at == Vector2.INF: return
	var free_left := menu.position.x+menu.size.x+12.0 if target_on_right else 12.0
	var free_right := size.x-12.0 if target_on_right else menu.position.x-12.0
	var target_screen := Projection2D.to_screen(at-Vector2(16,16),Vector2(size.x*0.5,size.y*0.52)+pan_target,zoom_target,Vector2(28,14),shown_world.terrain.height_at(at))
	# Account for the whole parcel and facade, not just their centre. Use the
	# destination camera so animation does not repeatedly add the same offset.
	if target_screen.x < free_left+90.0 or target_screen.x > free_right-90.0:
		pan_target.x += (free_left+free_right)*0.5-target_screen.x

func _sync_note_buttons() -> void:
	var note_choices: Array = [48,50,52,55,57]
	var labels := ["地基","张力","暖和","开阔","伸展"]
	var row: Control = menu.get_meta("notes")
	var authored := _authored_retune()
	var partners: Array = []
	if authored:
		for relation: Dictionary in AuthoredDuet.relations(shown_world,model.audible_pitches()):
			if str(relation["a"]) == selected_id: partners.append(str(relation["b"]))
			elif str(relation["b"]) == selected_id: partners.append(str(relation["a"]))
	for index in range(note_choices.size()):
		var button: Button = row.get_child(index)
		var candidate := _note_pitch(int(note_choices[index]))
		button.text = str(labels[index])+" · "+note_name(candidate)+(str(candidate/12-1) if authored else "")
		button.tooltip_text = "下一拍换成 "+note_name(candidate)+str(candidate/12-1)
		if partners.any(func(id: String) -> bool:
			return float(shown_world.coupling.interval(candidate,int(model.audible_pitches().get(id,shown_world.by_id[id]["current_midi"])))["score"]) >= 0.85):
			button.text += " · 呼应"
			button.tooltip_text += " · 与实际对岸作者房屋协和"

func _update_selected_opportunity() -> void:
	_sync_note_buttons()
	if context.get("kind","") != "retune" or not shown_world.by_id.has(selected_id): return
	var current_score := model.audible_score()
	var key: Array = [model.presentation_token,shown_world.phrase_index,selected_id,hash(current_score),hash(model.audible_pitches()),Input.is_key_pressed(KEY_SHIFT)]
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
	var building: Dictionary = shown_world.by_id[selected_id]
	var pitch := int(model.audible_pitches().get(selected_id,building["current_midi"]))
	var route_detail := ""
	menu_info.text = "%s · %s\n这栋 · %s · %s\n音型 · %s%s\n选音改编 · 下一拍换音；F聚焦 · Tab独听\n详细条件 · 低音表达 / 商业律动 / 跨岸应答" % [
		shown_world.communities[cid]["name"],str(selected_opportunity.get("current","当前以长音融入合奏")),
		note_name(pitch),str(building["form"]),"  ".join(displayed)," …" if notes.size() > 8 else ""]
	if _authored_retune():
		var choice := PlayerExpression.definition(str(building["expression"]))
		menu_info.text = "%s · 你种下的%s\n这栋 · %s%d · %s\n音型 · %s%s\n选一个音，下一拍改写 · Esc回到全城" % [
			shown_world.communities[cid]["name"],choice["label"],note_name(pitch),pitch/12-1,str(building["form"]),
			"  ".join(displayed)," …" if notes.size() > 8 else ""]
		var family_id := str(building["family_id"])
		var authored_work := FirstAuthoredWork.state(shown_world,current_score,model.audible_pitches(),str(shown_world.families[family_id]["root"]))
		var route_result := FirstAuthoredRouteResult.summary(authored_work,current_score)
		if not route_result.is_empty() and bool(route_result.get("available",false)):
			menu_info.text += "\n实际路线结果 · 家族%d栋 · 社区成熟%d栋" % [int(route_result.get("family_houses",0)),int(route_result.get("mature",0))]
			route_detail = "\n\n"+FirstAuthoredRouteResult.text(route_result)+"\n保持当前声域 · Shift低一个八度（最低C2）"
	var details: Label = menu.get_meta("details_label")
	details.text = next_text+"\n"+("公园给主题留白" if selected_opportunity["facility"]["park"] else ("文化馆实际服务%d栋" % int(selected_opportunity["facility"]["served"]) if selected_opportunity["facility"]["civic"] else "可自由选择留白、文化或商业布局"))
	details.text += "\n跨河应答 · "+_response_state_label()+"\nEsc回到全城合奏"+route_detail

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
	_refresh_transit_edit_choices()
	authored_composition_choices.sync()
	var choosing_expression := _expression_context()
	var authored_reservation := _authored_reservation_context()
	(menu.get_meta("compose_more") as Control).visible = first_composition_mode and (_authored_retune() or authored_reservation)
	var care_for_land := menu.get_meta("care_for_land") as Button
	care_for_land.visible = false
	if _authored_retune():
		var root_id := str(shown_world.families[str(shown_world.by_id[selected_id]["family_id"])]["root"])
		care_for_land.visible = not str(_first_authored_state(root_id).get("reservation_id","")).is_empty()
	(menu.get_meta("authored_reservation_choices") as Control).visible = authored_reservation
	(menu.get_meta("expression_choices") as Control).visible = choosing_expression
	(menu.get_meta("expression_footer") as Control).visible = choosing_expression
	(menu.get_meta("notes") as Control).visible = not choosing_expression and not authored_reservation
	(menu.get_meta("legacy_expressions") as Control).visible = not choosing_expression and not _authored_retune() and not authored_reservation
	(menu.get_meta("listening_verbs") as Control).visible = not choosing_expression
	if authored_reservation: (menu.get_meta("listening_verbs") as Control).hide()
	(menu.get_meta("public_toggle") as Control).visible = not choosing_expression
	(menu.get_meta("public_tools") as Control).visible = not choosing_expression and (menu.get_meta("public_toggle") as Button).button_pressed
	(menu.get_meta("city_toggle") as Control).visible = not choosing_expression
	(menu.get_meta("city_tools") as Control).visible = not choosing_expression and (menu.get_meta("city_toggle") as Button).button_pressed
	var retuning: bool = context.get("kind","") == "retune"
	var active_public := false
	for site in model.world.public_sites:
		if str(site.get("id","")) == str(context.get("id","")):
			active_public = bool(site.get("active",false)) and str(context.get("kind","")) in ["park","civic"]
	planning_buttons["reuse_public"].visible = active_public
	planning_buttons["reuse_public"].disabled = not active_public
	(menu.get_meta("details_toggle") as Button).visible = retuning
	(menu.get_meta("details_label") as Label).visible = retuning and (menu.get_meta("details_toggle") as Button).button_pressed
	# The same menu remains usable when details are expanded or the window is
	# small. Flow rows wrap; only content beyond the available height scrolls.
	var scroll: ScrollContainer = menu.get_meta("scroll")
	var box: VBoxContainer = menu.get_meta("content")
	var width := maxf(1.0,minf(560.0,size.x-52.0))
	if choosing_expression: width = minf(324.0,width)
	menu.add_theme_stylebox_override("panel",menu.get_meta("voice_panel" if choosing_expression else "regular_panel"))
	box.custom_minimum_size.x = maxf(1.0,width if choosing_expression else width-18.0)
	var footer := menu.get_meta("expression_footer") as Control
	var footer_height := footer.get_combined_minimum_size().y+12.0 if choosing_expression else 0.0
	var available_height := maxf(1.0,minf(590.0,size.y-94.0)-(32.0 if choosing_expression else 36.0)-footer_height)
	scroll.custom_minimum_size = Vector2(width,minf(box.get_combined_minimum_size().y,available_height))
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
	planning_buttons["free_courtyard_park"].disabled = context.get("kind","") != "reservation"
	planning_buttons["free_courtyard_civic"].disabled = context.get("kind","") != "reservation"
	for verb in ["park","civic"]:
		var existing := false
		for site in model.world.public_sites:
			if str(site["id"]) == str(context.get("id","")) and bool(site["active"]) and verb == "civic" and str(site["kind"]) == "civic":
				existing = int(site.get("service_level",1)) < 3
		planning_buttons[verb].disabled = not selectable and not existing
	planning_buttons["relocate_public"].disabled = not active_public
	planning_buttons["plan_transit"].disabled = false
	if context.get("kind","") == "transit_station":
		planning_buttons["plan_transit"].tooltip_text = "沿已选站点继续规划第二/第三条线路；下一乐句先试听再落定"
	else:
		planning_buttons["plan_transit"].tooltip_text = "沿真实道路逐站规划公交线路；至少两站后试听，Enter排入下一乐句"

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
	if planning_guide.opened and planning_guide.stage == "partial_anchor":
		_submit_partial_comparison()
		return
	if partial_reservation_id.is_empty() or partial_kind.is_empty():
		partial_mode = false
		return
	var preview: Dictionary = PartialPublic.preview(model.world,partial_reservation_id,partial_kind,target)
	if not bool(preview.get("accepted",false)):
		_message(str(preview.get("reason","局部公共空间不可用")))
		return
	_submit_partial_operation(_partial_site_from_preview(preview),partial_kind)

func _clear_transit_route() -> void:
	if transit_route_mode or not transit_route_stops.is_empty(): _invalidate_transit_preview()
	transit_route_mode = false
	transit_route_stops.clear()
	transit_preview.clear()
	transit_preview_key.clear()
	transit_charter_context.clear()
	transit_edit_context.clear()

func _refresh_transit_edit_choices() -> void:
	var sources: Array[Dictionary] = []
	var station_id := str(context.get("id","")) if context.get("kind","") == "transit_station" else ""
	for line in shown_world.transit_lines:
		if station_id.is_empty() or not line.get("stops",[]).has(station_id): continue
		var source := TransitRework.candidate(shown_world,str(line["id"]))
		if not bool(source.get("accepted",false)): continue
		var writable := TransitRework.candidate(model.world,str(line["id"]))
		source["writable"] = bool(writable.get("accepted",false)) and writable.get("source_revision","") == source["source_revision"] and writable.get("source_topology","") == source["source_topology"]
		sources.append(source)
	var key: Array = [station_id,sources]
	transit_edit_choices.visible = not sources.is_empty()
	if key == transit_edit_choices_key: return
	transit_edit_choices_key = key.duplicate(true)
	for child in transit_edit_choices.get_children():
		transit_edit_choices.remove_child(child)
		child.queue_free()
	for source in sources:
		var button := Button.new()
		button.text = "改站 · %s · %d站" % [str(source["line_name"]),source["stop_positions"].size()]
		button.set_meta("line_id",str(source["id"]))
		button.disabled = not bool(source["writable"])
		button.tooltip_text = "带入这条作者线路的原站序，试听并在下一句更新同一线路" if not button.disabled else "改站已排入，等下一句可听落成后再编辑这条线路"
		button.pressed.connect(_begin_transit_edit.bind(str(source["id"])))
		transit_edit_choices.add_child(button)

func _begin_transit_edit(line_id: String) -> void:
	var source := TransitRework.candidate(shown_world,line_id)
	if not bool(source.get("accepted",false)):
		_message(str(source.get("reason","这条作者线路不可编辑")))
		return
	var writable := TransitRework.candidate(model.world,line_id)
	if not bool(writable.get("accepted",false)) or writable.get("source_revision","") != source["source_revision"] or writable.get("source_topology","") != source["source_topology"]:
		_message("改站已排入 · 等下一句可听落成后再编辑这条线路")
		return
	planning_guide.hide_tool()
	_clear_transit_route()
	_clear_partial_draft()
	reservation_draw_mode = false
	reservation_draw_points.clear()
	relocation_mode = false
	relocation_site_id = ""
	transit_station_focus_id = ""
	transit_route_mode = true
	transit_edit_context = source.duplicate(true)
	for position in source["stop_positions"]: transit_route_stops.append(Vector2(float(position[0]),float(position[1])))
	context.clear()
	menu.hide()
	planning_guide.begin_transit_edit(source)
	_message("改站 · "+str(source["line_name"])+" · 已带入原站序；Backspace撤回、沿路加站，空格试听，Enter更新")

func _redraw_transit_edit() -> void:
	if transit_edit_context.is_empty(): return
	_invalidate_transit_preview()
	transit_route_stops.clear()
	transit_preview.clear()
	transit_preview_key.clear()
	planning_guide.refresh()
	_message("已清空改站草稿 · 沿真实道路重画同一条线路")

func _transit_edit_is_current() -> bool:
	if transit_edit_context.is_empty(): return true
	var source := TransitRework.candidate(model.world,str(transit_edit_context["id"]))
	return bool(source.get("accepted",false)) and source.get("source_revision","") == transit_edit_context["source_revision"] and source.get("source_topology","") == transit_edit_context["source_topology"]

func _transit_source_is_current() -> bool:
	return _transit_charter_is_current() and _transit_edit_is_current()

func _begin_charter_transit(payload: Dictionary) -> void:
	_clear_transit_route()
	_clear_partial_draft()
	reservation_draw_mode = false
	reservation_draw_points.clear()
	relocation_mode = false
	relocation_site_id = ""
	transit_station_focus_id = ""
	transit_route_mode = true
	transit_charter_context = payload.duplicate(true)
	context.clear()
	menu.hide()
	_message("公交锚点 · 沿真实道路加站，Backspace撤回；按住空格试听，Enter排入下一句")

func _transit_charter_is_current() -> bool:
	return transit_charter_context.is_empty() or bool(TransitCharter.source(model.world,str(transit_charter_context["charter_id"])).get("accepted",false))

func _transit_preview_identity(positions: Array) -> Array:
	return [model.presentation_token,model.world.phrase_index,model.world.action_serial,model.world.network.topology,positions,transit_charter_context.duplicate(true),transit_edit_context.duplicate(true),
		hash(model.world.pending_actions),hash(model.sound_events),hash(model.sound_overrides),model.synth.focused_community,
		model.synth.listener_community,model.synth.response_enabled,hash(model.synth.muted_communities),model.synth.gain,hash(model.synth.score)]

func _transit_route_operation(preview: Dictionary) -> Dictionary:
	var positions: Array = []
	for stop in transit_route_stops: positions.append([stop.x,stop.y])
	var operation := {"kind":"transit_line","stop_positions":positions,"source_topology":str(preview.get("source_topology",model.world.network.topology))}
	if not transit_edit_context.is_empty():
		operation["edit_id"] = str(transit_edit_context["id"])
		operation["source_revision"] = str(transit_edit_context["source_revision"])
		operation["source_topology"] = str(transit_edit_context["source_topology"])
	elif not transit_charter_context.is_empty(): operation["charter_id"] = str(transit_charter_context["charter_id"])
	return operation

func _transit_route_preview(include_hover := false) -> Dictionary:
	if model == null or transit_route_stops.is_empty(): return {}
	var positions: Array = []
	for stop in transit_route_stops: positions.append([stop.x,stop.y])
	if include_hover and pointer_inside:
		var candidate := TransitPlanning.stop_preview(model.world,world_at(pointer))
		if bool(candidate.get("accepted",false)):
			var cp := Vector2(float(candidate["position"][0]),float(candidate["position"][1]))
			if positions.is_empty() or cp.distance_to(transit_route_stops.back()) > 0.18: positions.append([cp.x,cp.y])
	var key := _transit_preview_identity(positions)
	if not include_hover and transit_preview_key == key: return transit_preview
	var result: Dictionary = TransitPlanning.preview(model.world,positions)
	if not transit_edit_context.is_empty():
		var operation := _transit_route_operation(result)
		operation["stop_positions"] = positions
		result = TransitRework.preview(model.world,operation)
	elif not transit_charter_context.is_empty():
		var anchor := TransitCharter.preview(model.world,result,str(transit_charter_context["charter_id"]))
		result["charter_anchor"] = anchor
		if not bool(anchor.get("accepted",false)):
			result["accepted"] = false
			result["reason"] = str(anchor.get("reason","线路需要实际覆盖所选社区"))
	if not include_hover:
		transit_preview_key = key
		transit_preview = result
	return result

func _transit_route_mode_label(preview: Dictionary) -> String:
	return "闭环" if str(preview.get("route_mode", "")) == "loop" else "往返"

func _transit_road_ids(preview: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var seen: Dictionary = {}
	for leg in preview.get("legs", []):
		for raw_id in leg.get("edges", []):
			var road_id := str(raw_id)
			if road_id.is_empty() or seen.has(road_id): continue
			seen[road_id] = true
			ids.append(road_id)
	if ids.is_empty():
		for raw_id in preview.get("edges", []):
			var road_id := str(raw_id)
			if road_id.is_empty() or seen.has(road_id): continue
			seen[road_id] = true
			ids.append(road_id)
	return ids

func _transit_community_names(raw_ids: Variant) -> Array[String]:
	var names: Array[String] = []
	if shown_world == null: return names
	for raw_id in raw_ids:
		var community_id := str(raw_id)
		if community_id.is_empty() or not shown_world.communities.has(community_id): continue
		var name := str(shown_world.communities[community_id].get("name", community_id))
		if not names.has(name): names.append(name)
	return names

func _transit_line_names(raw_ids: Variant, city: ContinuousWorld = null) -> Array[String]:
	var names: Array[String] = []
	var world := city if city != null else (model.world if model != null and model.world != null else shown_world)
	if world == null: return names
	for raw_id in raw_ids:
		var line_id := str(raw_id)
		for line in world.transit_lines:
			if str(line.get("id", "")) != line_id: continue
			var name := str(line.get("name", line_id))
			if not name.is_empty() and not names.has(name): names.append(name)
			break
	return names

func _transit_line_ids_at_stop(stop_id: String, city: ContinuousWorld = null) -> Array[String]:
	## A route preview has no authored line id yet.  Resolve the existing
	## memberships directly so a second player line can advertise a transfer
	## before it is submitted.  Keep the fallback tolerant of old snapshots that
	## do not carry the cached `line_ids` field on a stop record.
	var ids: Array[String] = []
	var world := city if city != null else (model.world if model != null and model.world != null else shown_world)
	if world == null or stop_id.is_empty(): return ids
	var record := world.transit_stop_record(stop_id)
	for raw_id in record.get("line_ids",[]):
		var line_id := str(raw_id)
		if not line_id.is_empty() and not ids.has(line_id): ids.append(line_id)
	for line in world.transit_lines:
		if not line.get("stops",[]).has(stop_id): continue
		var line_id := str(line.get("id",""))
		if not line_id.is_empty() and not ids.has(line_id): ids.append(line_id)
	return ids

func _transit_transfer_stop_ids(preview: Dictionary, summary: Dictionary = {}) -> Array[String]:
	## Merge the world summary with the preview-side single-line case.  The
	## world contract marks existing multi-line stations; the player also needs
	## to see a station where this *new* line will join one existing line.
	var ids: Array[String] = []
	for raw_id in summary.get("transfer_stop_ids",[]):
		var stop_id := str(raw_id)
		if not stop_id.is_empty() and not ids.has(stop_id): ids.append(stop_id)
	var stops: Array = preview.get("stops",preview.get("route_stops",preview.get("stop_ids",[])))
	for raw_stop in stops:
		var stop_id := str(raw_stop.get("id","") if raw_stop is Dictionary else raw_stop)
		if stop_id.is_empty() or ids.has(stop_id): continue
		var members := _transit_line_ids_at_stop(stop_id)
		var own_id := str(preview.get("edit_id",""))
		if members.any(func(id: String) -> bool: return own_id.is_empty() or id != own_id): ids.append(stop_id)
	return ids

func _transit_transfer_feedback(preview: Dictionary, summary: Dictionary = {}) -> Dictionary:
	var transfer_stop_ids := _transit_transfer_stop_ids(preview,summary)
	var line_ids: Array[String] = []
	var details: Array[String] = []
	for stop_id in transfer_stop_ids:
		var stop_line_ids := _transit_line_ids_at_stop(stop_id)
		var own_id := str(preview.get("edit_id",""))
		if not own_id.is_empty(): stop_line_ids.erase(own_id)
		var line_names := _transit_line_names(stop_line_ids)
		for line_id in stop_line_ids:
			if not line_ids.has(line_id): line_ids.append(line_id)
		var label := stop_id
		if not line_names.is_empty(): label += " → "+"、".join(line_names)
		details.append(label)
	var role := str(summary.get("route_role","社区往返线"))
	if role.is_empty(): role = "社区往返线"
	if not transfer_stop_ids.is_empty(): role = "换乘走廊"
	return {"transfer_stop_ids":transfer_stop_ids,"line_ids":line_ids,
		"line_names":_transit_line_names(line_ids),"details":details,"route_role":role}

func _transit_next_phrase_text(transfer: Dictionary, summary: Dictionary) -> String:
	var names: Array = transfer.get("line_names",[])
	if not transfer.get("transfer_stop_ids",[]).is_empty():
		var lines := "、".join(names) if not names.is_empty() else "既有线路"
		return "下一乐句：换乘站接入%s，落定后观察真实客流脉冲" % lines
	var mode := "闭环" if str(summary.get("route_mode","")) == "loop" else "往返"
	return "下一乐句：%s线路落定并开始接客" % mode

func _transit_station_feedback(station: Dictionary) -> Dictionary:
	## Convert one authoritative station into the short causal feedback used by
	## both the hover card and the click-to-plan context.  The station itself is
	## spatial truth; passenger values come from committed demand memory only.
	var stop_id := str(station.get("id",""))
	var line_ids: Array = station.get("line_ids",[]).duplicate(true)
	var line_names: Array = station.get("line_names",[]).duplicate(true)
	var world = shown_world
	var demand := 0.0
	var visits := 0
	var transfers := 0
	if world != null:
		demand = world.transit_demand_score(stop_id)
		var record: Dictionary = world.transit_demand.get(stop_id,{})
		visits = int(record.get("visits",0))
		transfers = int(record.get("transfers",0))
	var state := "coverage_only"
	var state_text := "等待真实客流"
	var next_action: Dictionary = {}
	var growth_action: Dictionary = {}
	if world != null:
		for line_id in line_ids:
			var line_feedback: Dictionary = {}
			for world_line in world.transit_lines:
				if str(world_line.get("id","")) == str(line_id):
					var cached_feedback: Variant = world_line.get("music_feedback",{})
					if cached_feedback is Dictionary: line_feedback = cached_feedback.duplicate(true)
					break
			if line_feedback.is_empty() and world.has_method("transit_music_feedback"):
				line_feedback = world.transit_music_feedback(str(line_id))
			var candidate_action: Variant = line_feedback.get("next_action",{})
			if next_action.is_empty() and candidate_action is Dictionary and not candidate_action.is_empty():
				next_action = candidate_action.duplicate(true)
			var candidate_growth: Variant = line_feedback.get("growth_action",{})
			if candidate_growth is Dictionary and not candidate_growth.is_empty():
				var candidate_growth_dict: Dictionary = candidate_growth
				if growth_action.is_empty() or float(candidate_growth_dict.get("strength",0.0)) > float(growth_action.get("strength",-1.0)):
					growth_action = candidate_growth_dict.duplicate(true)
	if line_ids.size() > 1:
		if transfers > 0:
			state = "passenger_transfer"
			state_text = "已发生%d次换乘" % transfers
		elif demand > 0.0 or visits > 0:
			state = "shared_station_waiting"
			state_text = "已有上下客，等待线路交换"
		else:
			state = "shared_station_waiting"
			state_text = "等待两条线路的真实交换"
	elif demand > 0.0 or visits > 0:
		state = "passenger_memory"
		state_text = "已有客流 %.1f，继续观察城市脉冲" % demand
	var next_text := "下一乐句：可沿此站继续规划第三条线路，观察换乘客流脉冲" if line_ids.size() > 1 else "下一乐句：可在此规划第二条线路，先试听再落定"
	if not next_action.is_empty():
		var action_message := str(next_action.get("message",next_action.get("title","")))
		if not action_message.is_empty():
			next_text = "下一乐句："+action_message
			if line_ids.size() > 1 and not next_text.contains("规划第三条线路"):
				next_text += "；也可从共享站规划第三条线路"
	return {"stop_id":stop_id,"line_ids":line_ids,"line_names":line_names,
		"demand":demand,"visits":visits,"transfers":transfers,"state":state,
		"state_text":state_text,"next_text":next_text,"next_action":next_action,
		"growth_action":growth_action,"growth_hint":str(growth_action.get("message",next_action.get("growth_hint","")))}

func _transit_station_context_text(station: Dictionary) -> String:
	var feedback := _transit_station_feedback(station)
	var line_names: Array = feedback.get("line_names",[])
	var line_text := "、".join(line_names) if not line_names.is_empty() else "公交线路"
	var station_record: Dictionary = station.get("record",{})
	var community_names := _transit_community_names(station_record.get("community_ids",[]))
	var community_text := "、".join(community_names) if not community_names.is_empty() else "暂无直接覆盖社区"
	var role_text := "共享换乘站" if feedback.get("line_ids",[]).size() > 1 else "线路站点"
	var growth_hint := str(feedback.get("growth_hint",feedback.get("next_action",{}).get("growth_hint","")))
	if growth_hint.is_empty(): growth_hint = "客流结算后，站点步行范围内的合法空地会获得轻微成长偏好"
	return "站点 · %s · %s\n线路：%s\n真实道路：%s · 覆盖%d栋 · 社区：%s\n当前换乘：%s\n%s\n成长：%s\nP规划社区会预选这些覆盖范围，仍可修改或多选；点击‘规划公交线路’沿此站继续组合" % [
		role_text,str(feedback.get("stop_id","")),line_text,str(station_record.get("road","真实道路")),
		station_record.get("covered_building_ids",[]).size(),community_text,str(feedback.get("state_text","等待真实客流")),
		str(feedback.get("next_text","下一乐句继续组合线路")),growth_hint]

func _transit_station_at(position: Vector2) -> Dictionary:
	if shown_world == null: return {}
	var best_id := ""
	var best_position := Vector2.INF
	var best_distance := INF
	var seen: Dictionary = {}
	for line in shown_world.transit_lines:
		for raw_id in line.get("stops", []):
			var stop_id := str(raw_id)
			if stop_id.is_empty() or seen.has(stop_id): continue
			seen[stop_id] = true
			var stop_position := shown_world.transit_stop_position(stop_id)
			if stop_position == Vector2.INF: continue
			var distance := position.distance_to(stop_position)
			if distance > 0.72 or distance >= best_distance: continue
			best_id = stop_id
			best_position = stop_position
			best_distance = distance
	if best_id.is_empty(): return {}
	var record := shown_world.transit_stop_record(best_id)
	if record.is_empty(): return {}
	var line_ids: Array = _transit_line_ids_at_stop(best_id,shown_world)
	return {"id":best_id,"position":best_position,"record":record,"line_ids":line_ids,
		"line_names":_transit_line_names(line_ids,shown_world),"distance":best_distance}

func _append_transit_stop(position: Vector2) -> void:
	_invalidate_transit_preview()
	var preview := TransitPlanning.stop_preview(model.world,position)
	if not bool(preview.get("accepted",false)):
		_message(str(preview.get("reason","站点需要靠近真实道路")))
		return
	var projected := Vector2(float(preview["position"][0]),float(preview["position"][1]))
	if not transit_route_stops.is_empty() and projected.distance_to(transit_route_stops.back()) <= 0.18:
		_message("连续两站不能是同一站")
		return
	transit_route_stops.append(projected)
	transit_preview_key.clear()
	transit_preview.clear()
	_message("已放置第%d站 · %s" % [transit_route_stops.size(),str(preview.get("road_id",preview.get("road","真实道路")))])

func _remove_last_transit_stop() -> void:
	_invalidate_transit_preview()
	if not transit_route_stops.is_empty():
		transit_route_stops.pop_back()
		transit_preview_key.clear()
		transit_preview.clear()
		_message("已撤回最后一站 · 当前%d站" % transit_route_stops.size())

func _submit_transit_route() -> void:
	if not transit_edit_context.is_empty() and planning_guide.transit_choice == "edit" and planning_guide.transit_comparison_is_current():
		var compared: Dictionary = planning_guide.transit_comparison["variants"]["edit"]
		if not bool(compared.get("accepted",false)):
			_message(str(compared.get("reason","改站没有在下一句落定，请继续修改或保留原线")))
			return
	if not transit_edit_context.is_empty() and planning_guide.transit_choice == "keep":
		var keep_operation := {"kind":"transit_line","keep":true,"edit_id":str(transit_edit_context["id"]),
			"source_revision":str(transit_edit_context["source_revision"]),"source_topology":str(transit_edit_context["source_topology"])}
		var kept: Dictionary = model.submit(keep_operation)
		if bool(kept.get("accepted",false)):
			if bool(planning_guide.next_action.get("transit_edit",false)) and planning_guide.next_action.get("edit_id","") == transit_edit_context["id"] and planning_guide.next_action.get("state","") == "queued": planning_guide.next_action["state"] = "consumed"
			planning_guide.hide_tool()
			menu.hide()
			_message("已保留原线路 · 只撤回这条线尚未落定的改站")
		else: _message(str(kept.get("reason","原线路已经变化，请重新点选")))
		return
	var preview := _transit_route_preview()
	if not bool(preview.get("accepted",false)):
		_message(str(preview.get("reason","公交线路至少需要两处真实道路站位")))
		return
	var result: Dictionary = model.submit(_transit_route_operation(preview))
	if bool(result.get("accepted",false)):
		if not transit_edit_context.is_empty(): planning_guide.queue_transit_edit_action(preview,result,transit_edit_context)
		elif not transit_charter_context.is_empty(): planning_guide.queue_transit_anchor_action(preview,result,transit_charter_context)
		_message(("原线路改站已排入下一乐句" if not transit_edit_context.is_empty() else "公交线路已排入下一乐句")+" · %d站 · 覆盖%d栋、%d个社区" % [transit_route_stops.size(),preview.get("covered_building_ids",[]).size(),preview.get("community_ids",[]).size()])
		_clear_transit_route()
		menu.hide()
	else:
		_message(str(result.get("reason","公交线路未能排入下一乐句")))

func _clear_partial_draft() -> void:
	_invalidate_partial_comparison()
	partial_mode = false
	partial_polygon_mode = false
	partial_polygon_points.clear()
	partial_multi_component_mode = false
	partial_polygon_components.clear()
	partial_courtyard_mode = false
	partial_hole_drawing = false
	partial_polygon_holes.clear()
	partial_kind = ""
	partial_reservation_id = ""

func _invalidate_partial_comparison() -> void:
	if planning_guide.stage == "partial_anchor":
		_cancel_preview_playback()
		planning_guide.clear_partial_comparison()

func _partial_site_from_preview(preview: Dictionary) -> Dictionary:
	var site := preview.duplicate(true)
	site["partial"] = true
	site["allowed"] = bool(preview.get("accepted",false))
	site["position"] = preview.get("target_position",[]).duplicate()
	site["polygon"] = preview.get("target_polygon",PackedVector2Array()).duplicate()
	site["community_id"] = preview.get("target_community_id","")
	var reservation := PartialPublic._reservation(shown_world,partial_reservation_id)
	site["source_site_id"] = reservation.get("source_site_id","")
	return site

func _partial_comparison_site() -> Dictionary:
	if partial_polygon_mode:
		if partial_polygon_points.size() > 0 and partial_polygon_points.size() < 3:
			_message("当前边界至少需要三个点 · 完成后按住空格比较")
			return {}
		if partial_courtyard_mode and partial_polygon_holes.is_empty() and (not partial_hole_drawing or partial_polygon_points.size() < 3):
			_message("先绘制至少一处内院，再按住空格比较")
			return {}
	var preview: Dictionary = _partial_preview_for_draw() if partial_polygon_mode else PartialPublic.preview(shown_world,partial_reservation_id,partial_kind,world_at(pointer))
	if not bool(preview.get("accepted",false)):
		_message(str(preview.get("reason","先完成可用的公共边界，再按住空格比较")))
		return {}
	return _partial_site_from_preview(preview)

func _submit_partial_comparison() -> void:
	if planning_guide.anchor_kind == "none":
		model.cancel_planning()
		if planning_guide.next_action.get("state","") == "queued": planning_guide.next_action.clear()
		_clear_partial_draft()
		context.clear()
		_message("暂不建设 · 待播公共规划已取消，原留地完整保留")
		return
	_submit_partial_operation(planning_guide.candidate.duplicate(true),planning_guide.anchor_kind)

func _submit_public_reuse() -> void:
	if not planning_guide.opened or planning_guide.stage != "reuse_anchor": return
	if not planning_guide.public_reuse_is_current():
		planning_guide.hide_tool()
		_message("这处公共空间已经变化，请重新点选用途")
		return
	if planning_guide.anchor_kind == "none":
		var site_id := str(planning_guide.reuse_site["public_id"])
		model.cancel_public_reuse(site_id)
		if bool(planning_guide.next_action.get("reuse",false)) and planning_guide.next_action.get("public_id","") == site_id and planning_guide.next_action.get("state","") == "queued":
			planning_guide.next_action.clear()
		planning_guide.hide_tool()
		_message("保留当前用途 · 现有公共空间继续运行")
		return
	var site: Dictionary = planning_guide.reuse_site.duplicate(true)
	var kind: String = planning_guide.anchor_kind
	var operation := {"kind":kind,"reuse":true,"id":str(site["public_id"]),
		"position":site["position"].duplicate(),"source_revision":str(site["source_revision"])}
	var result: Dictionary = model.submit(operation)
	if not bool(result.get("accepted",false)):
		_message(str(result.get("reason","这处公共空间未能排入下一句")))
		return
	planning_guide.queue_public_reuse_action(site,result)
	context.clear()
	ripple_position = Vector2(float(site["position"][0]),float(site["position"][1]))
	ripple_seconds = 0.6
	menu.hide()
	_message("原位改用已确认 · 下一句改作"+("公园" if kind == "park" else "文化馆")+"，原占地与设施身份保留")

func _submit_partial_operation(site: Dictionary,kind: String) -> void:
	var operation := {"kind":kind,"partial":true,"source_reservation_id":site.get("source_reservation_id",partial_reservation_id),
		"position":site.get("position",[]).duplicate(),"target_position":site.get("position",[]).duplicate(),
		"target_polygon":site.get("target_polygon",site.get("polygon",PackedVector2Array())).duplicate(),
		"target_polygons":site.get("target_polygons",site.get("footprint_components",[])).duplicate(true),
		"hole_polygons":site.get("hole_polygons",site.get("target_holes",[])).duplicate(true),
		"source_revision":str(site.get("source_revision",""))}
	var result: Dictionary = model.submit(operation)
	if not bool(result.get("accepted",false)):
		_message(str(result.get("reason","局部兑现未能排入下一句")))
		return
	site["kind"] = kind
	planning_guide.queue_partial_action(site,result)
	var target_position := _partial_position_from_preview(site,Vector2.ZERO)
	_clear_partial_draft()
	context.clear()
	ripple_position = target_position
	ripple_seconds = 0.6
	menu.hide()
	_message(("局部公园" if kind == "park" else "局部文化馆")+"已确认 · 下一句落成后可继续规划剩余留地")

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
		var holes := partial_polygon_holes.duplicate(true)
		if partial_polygon_points.size() >= 3:
			if partial_courtyard_mode and partial_hole_drawing: holes.append(partial_polygon_points.duplicate())
			else: components.append(partial_polygon_points.duplicate())
		if components.is_empty(): return {}
		return PartialPublic.preview_footprints(shown_world,partial_reservation_id,partial_kind,components,holes)
	return _partial_footprint_preview(partial_polygon_points)

func _partial_action_title() -> String:
	var kind: String = planning_guide.anchor_kind if planning_guide.opened and planning_guide.stage == "partial_anchor" else partial_kind
	if kind == "none": return "暂不兑现"
	if partial_courtyard_mode: return "自由内院公园" if kind == "park" else "自由内院文化馆"
	if partial_multi_component_mode: return "自由分块公园" if kind == "park" else "自由分块文化馆"
	return "自由局部公园" if kind == "park" else "自由局部文化馆"

func _partial_preview_fill_polygons(preview: Dictionary) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var holes := SpatialPlanning.footprint_holes(preview)
	for component in _partial_preview_polygons(preview):
		if holes.is_empty(): result.append(component)
		else: result.append_array(PartialPublic._subtract_components(component,holes))
	return result

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
		_message("目标足迹已接近起点 · "+("按 Tab 收束或 Enter 提交" if partial_multi_component_mode else "按 Enter 闭合并确认"))
		return
	partial_polygon_points.append(world_position)
	_invalidate_partial_comparison()
	var action := "按 Tab 完成这一块，Enter 提交全部" if partial_multi_component_mode else "至少三点后按 Enter 确认"
	if partial_courtyard_mode:
		action = "Tab 收束内院，Enter 提交" if partial_hole_drawing else "Tab 完成外环后绘制内院"
	_message(_partial_action_title()+" · 已选%d点 · %s；Esc/右键取消" % [partial_polygon_points.size(),action])

func _finish_partial_component() -> bool:
	if not partial_multi_component_mode: return false
	if partial_polygon_points.size() < 3:
		_message("当前组件至少需要三个点")
		return false
	if _partial_polygon_area(partial_polygon_points) < 0.25:
		_message("当前组件范围太小，请拉开边界")
		return false
	if not SpatialPlanning.valid_simple_polygon(partial_polygon_points):
		_message("当前边界自交，请重新绘制 · Esc/右键取消")
		return false
	_invalidate_partial_comparison()
	if partial_courtyard_mode and partial_hole_drawing:
		partial_polygon_holes.append(partial_polygon_points.duplicate())
	else:
		partial_polygon_components.append(partial_polygon_points.duplicate())
	partial_polygon_points.clear()
	if partial_courtyard_mode:
		partial_hole_drawing = true
		_message("外环已完成 · 点击绘制内院，Tab 收束内院，Enter 提交" if partial_polygon_holes.is_empty() else "已留下%d处内院 · 继续绘制或 Enter 提交" % partial_polygon_holes.size())
	else:
		_message("已完成第%d块 · 继续点击绘制下一块，按 Tab 收束，Enter 提交全部" % partial_polygon_components.size())
	return true

func _submit_partial_polygon() -> void:
	if not partial_polygon_mode: return
	if partial_multi_component_mode:
		if partial_polygon_points.size() > 0 and partial_polygon_points.size() < 3:
			_message("当前组件至少需要三个点 · 继续绘制或按 Esc 取消")
			return
		if partial_polygon_points.size() >= 3 and not _finish_partial_component(): return
	if partial_polygon_components.is_empty() and partial_polygon_points.size() < 3:
		_message("自由局部目标至少需要三个点")
		return
	if partial_courtyard_mode and partial_polygon_holes.is_empty():
		_message("外环已完成 · 再绘制至少一处内院，Enter 提交")
		return
	var polygon := partial_polygon_points.duplicate() if partial_polygon_components.is_empty() else partial_polygon_components[0].duplicate()
	var components: Array[PackedVector2Array] = partial_polygon_components.duplicate(true)
	if components.is_empty(): components.append(polygon.duplicate())
	var preview := PartialPublic.preview_footprints(shown_world,partial_reservation_id,partial_kind,components,partial_polygon_holes) if partial_multi_component_mode else _partial_footprint_preview(polygon)
	if not bool(preview.get("accepted",false)):
		_message(str(preview.get("reason","这片目标足迹暂时不能兑现")))
		return
	_submit_partial_operation(_partial_site_from_preview(preview),partial_kind)

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
	if verb == "community":
		var cid := str(shown_world.by_id.get(selected_id,{}).get("community_id",""))
		if not cid.is_empty(): _open_community_workbench(cid)
		return
	var station_context := context.duplicate(true) if context.get("kind","") == "transit_station" else {}
	var transit_anchor_id := str(station_context.get("id",""))
	var station_record: Dictionary = shown_world.transit_stop_record(transit_anchor_id) if not transit_anchor_id.is_empty() else {}
	if verb in ["free_reserve","partial_park","partial_civic","free_partial_park","free_partial_civic","free_multi_partial_park","free_multi_partial_civic","free_courtyard_park","free_courtyard_civic","relocate_public","plan_transit"]:
		planning_guide.hide_tool()
	if verb != "plan_transit": _clear_transit_route()
	if verb != "plan_transit": transit_station_focus_id = ""
	if verb == "reuse_public":
		var site := PublicReuse.candidate(model.world,str(context.get("id","")))
		if not bool(site.get("allowed",false)):
			_message(str(site.get("reason","先点一处已落成的公园或文化馆")))
			return
		_clear_partial_draft()
		reservation_draw_mode = false
		reservation_draw_points.clear()
		relocation_mode = false
		relocation_site_id = ""
		selected_id = ""
		context.clear()
		planning_guide.begin_public_reuse(site)
		_message("已固定现有公共空间 · 按住空格比较用途，确认后下一句改用；Esc取消")
		return
	if verb == "planning":
		if not station_context.is_empty() and not station_record.is_empty():
			planning_guide.open_tool_from_transit_station({"id":transit_anchor_id,"record":station_record})
		elif shown_world.by_id.has(selected_id):
			planning_guide.open_tool_from_community(str(shown_world.by_id[selected_id]["community_id"]))
		else:
			planning_guide.open_tool()
		return
	if verb == "plan_transit":
		_clear_transit_route()
		_invalidate_transit_preview()
		_clear_partial_draft()
		reservation_draw_mode = false
		reservation_draw_points.clear()
		relocation_mode = false
		relocation_site_id = ""
		transit_route_mode = true
		transit_route_stops.clear()
		var anchor_position := model.world.transit_stop_position(transit_anchor_id) if not transit_anchor_id.is_empty() else Vector2.INF
		if anchor_position != Vector2.INF:
			var anchor_preview := TransitPlanning.stop_preview(model.world,anchor_position)
			if bool(anchor_preview.get("accepted",false)):
				transit_route_stops.append(Vector2(float(anchor_preview["position"][0]),float(anchor_preview["position"][1])))
		transit_preview.clear()
		transit_preview_key.clear()
		context.clear()
		menu.hide()
		_message(("公交线路预影开启 · 已带入站点%s · 左键继续沿真实道路加站，至少两站后按住空格试听，Enter 排入下一乐句；右键取消" % transit_anchor_id) if not transit_anchor_id.is_empty() and not transit_route_stops.is_empty() else "公交线路预影开启 · 左键沿真实道路逐站放置，至少两站后按住空格试听，Enter 排入下一乐句；右键取消")
		return
	if verb == "free_reserve":
		partial_polygon_mode = false
		partial_polygon_points.clear()
		partial_multi_component_mode = false
		partial_polygon_components.clear()
		partial_courtyard_mode = false
		partial_hole_drawing = false
		partial_polygon_holes.clear()
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
		partial_courtyard_mode = false
		partial_hole_drawing = false
		partial_polygon_holes.clear()
		partial_mode = false
		menu.hide()
		_message(("自由局部公园" if partial_kind == "park" else "自由局部文化馆")+"预影开启 · 左键逐点绘制目标足迹，至少三点后按 Enter 确认；Esc/右键取消")
		return
	if verb in ["free_multi_partial_park","free_multi_partial_civic","free_courtyard_park","free_courtyard_civic"]:
		if context.get("kind","") != "reservation" or str(context.get("id","")).is_empty():
			_message("先点选一片留地，再选择自由分块兑现")
			return
		partial_kind = "park" if verb in ["free_multi_partial_park","free_courtyard_park"] else "civic"
		partial_reservation_id = str(context["id"])
		reservation_draw_mode = false
		reservation_draw_points.clear()
		partial_polygon_mode = true
		partial_multi_component_mode = true
		partial_polygon_points.clear()
		partial_polygon_components.clear()
		partial_courtyard_mode = false
		partial_hole_drawing = false
		partial_polygon_holes.clear()
		partial_mode = false
		menu.hide()
		partial_courtyard_mode = verb in ["free_courtyard_park","free_courtyard_civic"]
		_message(_partial_action_title()+"预影开启 · "+("先绘外环，Tab 后绘内院，Enter 提交；Esc/右键取消" if partial_courtyard_mode else "左键逐点绘制；Tab完成当前块，Enter提交全部，Esc/右键取消"))
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
		partial_courtyard_mode = false
		partial_hole_drawing = false
		partial_polygon_holes.clear()
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
	if not event is InputEventKey: return
	if community_workbench.opened:
		if event.keycode in [KEY_TAB,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]: return
		if event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_M,KEY_F]:
			get_viewport().set_input_as_handled()
			return
		if event.pressed and not event.echo and event.keycode in [KEY_C,KEY_ESCAPE,KEY_P]:
			get_viewport().set_input_as_handled()
			if event.keycode == KEY_P: _plan_workbench_community(community_workbench.community_id)
			else: community_workbench.close_tool()
			return
		if event.pressed and event.keycode == KEY_B: community_workbench.close_tool()
	if event.pressed and not event.echo and event.keycode == KEY_C and not black:
		get_viewport().set_input_as_handled()
		_toggle_community_workbench()
		return
	if planning_guide.PlanningKeyboard.route(self,event): return
	if event.echo: return
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
	# In the sound picker Tab belongs to the native buttons, not city solo.
	if menu.visible and _expression_context() and event.keycode == KEY_TAB: return
	if event.keycode in [KEY_SPACE,KEY_ESCAPE,KEY_B,KEY_G,KEY_TAB,KEY_BACKSPACE,KEY_M,KEY_F,KEY_R,KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_N,KEY_V,KEY_H,KEY_T,KEY_Y,KEY_E,KEY_ENTER,KEY_P]: get_viewport().set_input_as_handled()
	if event.keycode == KEY_SPACE and not event.pressed:
		_cancel_preview_playback()
		return
	if not event.pressed: return
	match event.keycode:
		KEY_P:
			if planning_guide.opened: planning_guide.hide_tool()
			elif menu.visible and context.get("kind","") == "transit_station": _verb("planning")
			else: planning_guide.open_tool()
		KEY_ESCAPE:
			if transit_route_mode:
				_clear_transit_route()
				if planning_guide.opened and planning_guide.stage == "transit_anchor":
					planning_guide.stage = "anchor"
					planning_guide.refresh()
				elif planning_guide.opened and planning_guide.stage == "transit_edit": planning_guide.hide_tool()
				_message("公交线路预影已取消")
				return
			if partial_mode or partial_polygon_mode:
				_clear_partial_draft()
				_message("局部公共目标已取消 · 原留地保留")
				return
			if reservation_draw_mode:
				reservation_draw_mode = false
				reservation_draw_points.clear()
				_message("自由留地已取消")
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
		KEY_BACKSPACE:
			if transit_route_mode: _remove_last_transit_stop()
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
			first_composition_mode = false
			town_starter = false
			expanded_town_starter = false
			starter = false
			_start_world()
			clock.start_output(model._mix_frame,{},clock.renderer.snapshot())
		KEY_V:
			_save_before_switch()
			first_composition_mode = false
			town_starter = false
			expanded_town_starter = false
			starter = true
			expression = "deep"
			_start_world()
			clock.start_output(model._mix_frame,{},clock.renderer.snapshot())
		KEY_R:
			if event.shift_pressed:
				_start_first_composition()
				return
			_save_before_switch()
			first_composition_mode = false
			town_starter = false
			expanded_town_starter = false
			starter = true
			expression = "bright"
			_start_world()
			clock.start_output(model._mix_frame,{},clock.renderer.snapshot())
		KEY_SPACE:
			expression_click_preview = false
			_request_preview()
		KEY_ENTER:
			if menu.visible and _expression_context():
				_confirm_player_expression()
			elif transit_route_mode:
				_submit_transit_route()
			elif planning_guide.opened and planning_guide.stage == "partial_anchor":
				_submit_partial_comparison()
			elif planning_guide.opened and planning_guide.stage == "reuse_anchor":
				_submit_public_reuse()
			elif reservation_draw_mode:
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
	var labels := {"reserve":"留地","release_reservation":"释放留地","park":"公园","civic":"文化设施","bridge":"桥","transit_line":"公交线路"}
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
	var pending_operations: Array = model.world.pending_actions.duplicate(true)
	if pending_operations.is_empty() and not model.world.pending.is_empty(): pending_operations.append(model.world.pending.duplicate(true))
	for operation in pending_operations:
		var kind := str(operation.get("kind", ""))
		var label: String = str({"charter":"章程", "park":"公园", "civic":"文化馆", "relocate_public":"搬迁公共设施", "reserve":"留地", "release_reservation":"释放留地", "bridge":"跨河连接", "transit_line":"公交线路"}.get(kind, ""))
		if bool(operation.get("partial",false)):
			label = "局部公园" if kind == "park" else ("局部文化馆" if kind == "civic" else label)
		if not str(label).is_empty(): pending_labels.append(str(label))
	if not pending_labels.is_empty():
		return "待播规划 · %s · 下一乐句落定" % "、".join(pending_labels)
	if first_composition_mode:
		var authored := _first_authored_state()
		if not authored.is_empty():
			return "你的%s已在%s落成 · 点左上改音与继续，或按 P 规划下一段" % [str(PlayerExpression.definition(str(authored["expression"]))["label"]),str(authored.get("community_name","社区"))]
	# A bridge is a structural player choice whose one-shot toast expires after
	# a few seconds. Keep the resulting road and acoustic connection in the
	# persistent caption so the planning cause remains visible while the city
	# continues to grow.
	if model.world.bridge:
		return "跨河已连接 · 两岸道路与合奏已接通 · 下一段从街坊开始 · 点击左上入口或按 P"
	# Author-created voices can already form a cross-bank duet before a bridge
	# operation exists. Keep the next composition entry discoverable in that
	# route too; the button itself remains the same single planning action.
	if first_composition_mode and shown_world != null and AuthoredDuet.roots(shown_world,model.audible_pitches()).size() >= 2:
		return "两岸作者合奏已接通 · 下一段从街坊开始 · 点击左上入口或按 P"
	if model.world.development_charters.is_empty():
		return "P规划：选章程 → 变化卡 → 社区 → 公共空间"
	var charter: Dictionary = model.world.development_charters[0]
	var title := str(World.Charter.PLANS.get(str(charter.get("plan_id", "")), {}).get("title", "发展章程"))
	var card_text := _charter_card_feedback(charter)
	if card_text.is_empty(): return "当前规划 · %s · P重新规划" % title
	return "当前规划 · %s · %s · P重新规划" % [title, card_text]

func _request_preview() -> void:
	if menu.visible and _expression_context() and not planning_guide.opened:
		_request_expression_preview()
		return
	if transit_route_mode:
		if not transit_edit_context.is_empty():
			_request_transit_comparison()
			return
		var transit_candidate := _transit_route_preview()
		if not bool(transit_candidate.get("accepted",false)):
			_message(str(transit_candidate.get("reason","公交线路至少需要两处真实道路站位")))
			return
		var transit_operation := _transit_route_operation(transit_candidate)
		var frozen_transit := model.freeze()
		var state_transit := clock.renderer.state.duplicate(true)
		var at_transit := clock.renderer.transport.rendered_frames
		preview_context_key = _transit_preview_identity(transit_operation["stop_positions"])
		preview_public = false
		preview_requested = true
		preview_started = false
		if preview_thread != null: return
		preview_thread = Thread.new()
		preview_thread.start(_build_preview.bind(frozen_transit,transit_operation,state_transit,at_transit,preview_context_key.duplicate(true)))
		_message("线路试听 · %d站、覆盖%d栋 · 松开恢复，Enter 排入下一乐句" % [transit_route_stops.size(),transit_candidate.get("covered_building_ids",[]).size()])
		return
	if (partial_mode or partial_polygon_mode) and (not planning_guide.opened or planning_guide.stage != "partial_anchor"):
		var site := _partial_comparison_site()
		if site.is_empty(): return
		planning_guide.begin_partial_comparison(site,partial_kind)
		_message("这一范围已固定 · 按住空格比较，按钮切换用途，Enter 确认")
	var operation := context.duplicate(true)
	if planning_guide.opened:
		if planning_guide.stage not in ["anchor","partial_anchor","reuse_anchor"]: return
		if planning_guide.stage == "anchor": planning_guide.update_candidate(world_at(pointer))
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
	if preview_duck_owned:
		frozen.synth.ducking = preview_saved_ducking
		frozen.synth.duck_release_at = preview_saved_release
	var state := clock.renderer.state.duplicate(true)
	if planning_guide.opened and planning_guide.stage == "anchor": state["include_reserve"] = true
	var at := clock.renderer.transport.rendered_frames
	preview_requested = true
	preview_started = false
	preview_thread = Thread.new()
	preview_thread.start(_build_preview.bind(frozen,operation,state,at,preview_context_key.duplicate(true)))

func _request_transit_comparison() -> void:
	if not planning_guide.opened or planning_guide.stage != "transit_edit" or not _transit_edit_is_current(): return
	var operation := _transit_route_operation({})
	preview_context_key = _transit_preview_identity(operation["stop_positions"])
	preview_public = false
	preview_requested = true
	if not planning_guide.transit_comparison.is_empty() and planning_guide.transit_comparison_key == preview_context_key:
		_play_transit_comparison()
		return
	if preview_thread != null: return
	var frozen := model.freeze()
	if preview_duck_owned:
		frozen.synth.ducking = preview_saved_ducking
		frozen.synth.duck_release_at = preview_saved_release
	var state := clock.renderer.state.duplicate(true)
	var at := clock.renderer.transport.rendered_frames
	preview_started = false
	preview_thread = Thread.new()
	preview_thread.start(_build_transit_comparison.bind(frozen,operation,state,at,preview_context_key.duplicate(true)))
	_message("公交两方案试听 · 正在取得同一下一句，按钮切换保留 / 改站")

func _build_transit_comparison(frozen: ContinuousAudioModel,operation: Dictionary,state: Dictionary,at: int,request_key: Array) -> Dictionary:
	var result := TransitReworkPreview.build(frozen,operation,state,at)
	result["request_key"] = request_key
	return result

func _play_transit_comparison() -> void:
	if not preview_requested or not planning_guide.transit_comparison_is_current(): return
	var variant: Dictionary = planning_guide.transit_comparison["variants"][planning_guide.transit_choice]
	if not bool(variant.get("accepted",false)):
		_cancel_preview_playback()
		preview_requested = true
		_message(str(variant.get("reason","改站草稿还未完成；可切换保留原线")))
		return
	_play_preview_pcm(variant["pcm"])
	_message(("保留原线" if planning_guide.transit_choice == "keep" else "改站")+"试听 · 松开恢复城市，Enter确认当前选择")

func _build_preview(frozen: ContinuousAudioModel, operation: Dictionary, state: Dictionary, at: int, request_key: Array) -> Dictionary:
	if operation["kind"] == "public_compare":
		var result := PublicPreview.build(frozen,operation["candidate"],state,at)
		result["request_key"] = request_key
		return result
	var rate := int(Config.load_values()["timing"]["sample_rate"])
	return {"pcm":Renderer.pcm16(frozen.forecast(operation,state,at,rate*3)),"request_key":request_key}

func _play_public_preview() -> void:
	var variant: Dictionary = planning_guide.comparison["variants"][planning_guide.anchor_kind]
	if not variant["accepted"]:
		_message(str(variant["reason"]))
		_cancel_preview_playback()
		return
	_play_preview_pcm(variant["pcm"])
	if planning_guide.stage == "partial_anchor":
		_message(str({"none":"暂不兑现","reserve":"留地 · 呼吸","park":"公园","civic":"文化馆"}[planning_guide.anchor_kind])+"试听 · 松开恢复原合奏，Enter 确认这一范围")
	elif planning_guide.stage == "reuse_anchor":
		_message(str({"none":"保留当前用途","reserve":"留地 · 呼吸","park":"公园","civic":"文化馆"}[planning_guide.anchor_kind])+"试听 · 松开恢复原合奏，确认后下一句原位改用")

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
	model.synth.duck_release_at = clock.renderer.transport.rendered_frames+pcm.size()/4

func _hover_placement(p: Vector2) -> Dictionary:
	var key := [model.world,model.world.phrase_index,model.world.action_serial,p]
	if hover_placement_key != key:
		hover_placement_key = key
		hover_placement = model.world.placement(p)
	return hover_placement

func _pending_reservation_at(p: Vector2) -> Dictionary:
	## A queued reserve is already the player's visible choice, even though the
	## WorldDelta has not reached the next phrase boundary yet. Keep hover and
	## drawing on the same pending geometry so it cannot read as a buildable lot.
	if model == null or model.world == null: return {}
	for operation: Dictionary in model.world.pending_actions:
		if str(operation.get("kind", "")) != "reserve": continue
		if SpatialPlanning.point_in_footprint(operation,p): return operation
	return {}

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
		if result.get("contract","") == "P12-EXPRESSION-COMPARE/v1":
			if menu.visible and _expression_context() and result.get("request_key",[]) == _expression_preview_identity():
				expression_comparison = result
				expression_comparison_key = result["request_key"].duplicate(true)
				_update_expression_menu()
				if preview_requested: _play_expression_preview()
			elif preview_requested and menu.visible and _expression_context(): _request_expression_preview()
			else: _cancel_preview_playback()
		elif result.get("contract","") == "P12-TRANSIT-REWORK-COMPARE/v1":
			if preview_requested and planning_guide.accept_transit_comparison(result,result["request_key"]): _play_transit_comparison()
			else: _cancel_preview_playback()
		elif result.has("variants"):
			if planning_guide.accept_comparison(result,result["request_key"]):
				if preview_requested: _play_public_preview()
			elif preview_requested and planning_guide.opened and planning_guide.stage == "reuse_anchor" and planning_guide.public_reuse_is_current():
				_request_preview()
			else: _cancel_preview_playback()
		elif preview_requested:
			if transit_route_mode:
				var operation := _transit_route_operation({})
				if _transit_source_is_current() and result.get("request_key",[]) == _transit_preview_identity(operation["stop_positions"]): _play_preview_pcm(result["pcm"])
				elif (not transit_charter_context.is_empty() or not transit_edit_context.is_empty()) and _transit_source_is_current(): _request_preview()
				else: _cancel_preview_playback()
			elif not planning_guide.opened and result.get("request_key",preview_context_key) == preview_context_key: _play_preview_pcm(result["pcm"])
			else: _cancel_preview_playback()
	if menu.visible and _expression_context() and not expression_choice.is_empty() and not preview_started and expression_comparison_key != _expression_preview_identity():
		_prepare_expression_comparison()
	var frame_started := Time.get_ticks_usec()
	_sync_buildings()
	_profile_frame("buildings_ms",frame_started)
	street_eaves_layer.sync(self)
	_sync_daylight()
	expression_audition_layer.sync(self)
	first_sound_focus.sync(self)
	expression_status.sync(self)
	authored_growth_trail.sync(self)
	pending_authored_path.sync()
	authored_voice_badges.sync(self)
	core_slice_hud.sync()
	if first_composition_mode: authored_reservation_layer.sync(self)
	else: authored_reservation_layer.hide()
	music_activity_layer.sync(self)
	public_space_activity_layer.sync(self)
	frame_started = Time.get_ticks_usec()
	scenery.sync(self)
	frontage_details.sync(self)
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
		var authored_birth_seen := false
		for event in presented_events.slice(last_presented_event_count):
			if str(event.get("kind","")) == "birth":
				var birth_feedback := GrowthFeedback.for_birth(shown_world,event,model.audible_pitches(),model.audible_music_activity(clock.renderer.transport.audible_frame))
				if not birth_feedback.is_empty() and (bool(birth_feedback["authored"]) or not authored_birth_seen):
					_message(GrowthFeedback.text(birth_feedback))
					authored_birth_seen = bool(birth_feedback["authored"])
			elif str(event.get("kind","")) == "planning_rejected": _message(_planning_rejection_message(event))
			elif str(event.get("kind","")) == "transit_line":
				var event_communities := _transit_community_names(event.get("community_ids",[]))
				var event_community_text := "、".join(event_communities) if not event_communities.is_empty() else "%d个社区" % event.get("community_ids",[]).size()
				var route_mode := "闭环" if str(event.get("route_mode","")) == "loop" else "往返"
				var event_transfer := _transit_transfer_feedback(event,event.get("coverage",{}))
				var event_role := str(event_transfer.get("route_role",event.get("route_role","社区往返线")))
				var event_transfer_text := ""
				if not event_transfer.get("details",[]).is_empty(): event_transfer_text = " · 换乘："+"、".join(event_transfer["details"])
				var feedback_value: Variant = event.get("music_feedback",event.get("music_role",""))
				var feedback := ""
				var feedback_message := ""
				if feedback_value is Dictionary:
					feedback = str(feedback_value.get("state",feedback_value.get("functional_role","")))
					feedback_message = str(feedback_value.get("message",""))
				else:
					feedback = str(feedback_value)
				var feedback_text := "下一句客流会进入城市节奏"
				if feedback == "pulse_dense": feedback_text = "换乘客流已接入密集脉冲"
				elif feedback == "pulse": feedback_text = "客流已接入脉冲"
				elif feedback == "pulse_dense_active": feedback_text = "换乘客流已接入密集脉冲"
				elif feedback == "pulse_active": feedback_text = "客流已接入脉冲"
				elif feedback == "waiting_for_passengers": feedback_text = "等候真实客流进入脉冲"
				elif not feedback_message.is_empty(): feedback_text = feedback_message
				_message("公交线路已落定 · %s · %s · %d站 · 覆盖%d栋 · %s%s · %s" % [route_mode,event_role,event.get("stop_ids",[]).size(),event.get("covered_building_ids",[]).size(),event_community_text,event_transfer_text,feedback_text])
		last_presented_event_count = presented_events.size()
	notice_seconds = maxf(0.0,notice_seconds-delta)
	ripple_seconds = maxf(0.0,ripple_seconds-delta)
	planning_guide.sync()
	community_workbench.sync()
	if community_workbench.opened:
		var community_key: Array = [size,community_workbench.community_id]
		if community_camera_key != community_key:
			community_camera_key = community_key
			_frame_workbench_community()
	community_member_focus.sync()
	community_entry.visible = first_composition_mode and not black and not community_workbench.opened and not planning_guide.opened and not menu.visible
	first_composition_guide.sync()
	if community_workbench.opened: first_composition_guide.hide()
	caption.position = Vector2(48,size.y-68)
	tooltip.visible = not black and pointer_inside and not menu.visible and not planning_guide.opened and not community_workbench.opened
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
	var station_hover := _transit_station_at(p)
	var landmark := shown_world.landmark_at(p)
	var hover_card_status := ""
	var hovered_author_root: String = authored_voice_badges.hit_root(pointer)
	if not hovered_author_root.is_empty():
		hover_id = hovered_author_root
		var author_house: Dictionary = shown_world.by_id[hovered_author_root]
		var author_label := str(PlayerExpression.definition(str(author_house["expression"]))["label"])
		tooltip.text = "你的"+author_label+" · "+str(shown_world.communities[str(author_house["community_id"])]["name"])+"\n点击听自己的声音 / 改音，也可继续规划下一段"
	elif transit_route_mode:
		var transit_hover := _transit_route_preview(true)
		if bool(transit_hover.get("accepted",false)):
			var road_ids := _transit_road_ids(transit_hover)
			var road_text := "、".join(road_ids) if not road_ids.is_empty() else "待计算"
			var community_names := _transit_community_names(transit_hover.get("community_ids",[]))
			var community_text := "、".join(community_names) if not community_names.is_empty() else "%d个社区" % transit_hover.get("community_ids",[]).size()
			var coverage_summary: Dictionary = planning_guide.transit_preview_feedback(transit_hover)
			var transfer := _transit_transfer_feedback(transit_hover,coverage_summary)
			var transfer_text := ""
			if not transfer.get("details",[]).is_empty(): transfer_text = "\n换乘站："+"、".join(transfer["details"])
			var role_text := str(transfer.get("route_role",coverage_summary.get("route_role","社区往返线")))
			var next_phrase := _transit_next_phrase_text(transfer,coverage_summary)
			var coverage_lines: Array = str(coverage_summary.get("text","")).split("\n")
			var community_detail := ""
			if coverage_lines.size() > 1: community_detail += "\n"+str(coverage_lines[1])
			if coverage_lines.size() > 2: community_detail += "\n"+str(coverage_lines[2])
			tooltip.text = "公交线路预影 · %d站 · %s · %s\n真实道路：%s\n覆盖%d栋 · 社区：%s%s%s\n%s\n左键加站 · Backspace撤回 · 空格试听 · Enter排入下一乐句 · 右键取消" % [transit_route_stops.size(),_transit_route_mode_label(transit_hover),role_text,road_text,transit_hover.get("covered_building_ids",[]).size(),community_text,community_detail,transfer_text,next_phrase]
		else:
			tooltip.text = "公交线路预影 · %d站（至少两站）\n左键沿真实道路放置 · Backspace撤回 · 空格试听 · Enter排入下一乐句 · 右键取消" % transit_route_stops.size()
	elif not landmark.is_empty():
		var progress := clampf(float(clock.renderer.transport.audible_frame-int(landmark.get("reveal_frame",landmark.get("frame",0))))/float(maxi(1,int(landmark.get("reveal_frames",1)))),0.0,1.0)
		var effect := "独立长音 · 吸收%d栋 · 动机%d音" % [landmark.get("absorbed_buildings",[]).size(),landmark.get("motif",[]).size()]
		tooltip.text = "%s · %s\n%s\n落成 %.0f%% · 悬停查看历史" % [str(landmark["name"]),"古典遗产" if int(landmark.get("era",1)) == 1 else "时代地标",effect,progress*100.0]
	elif not station_hover.is_empty():
		var station_record: Dictionary = station_hover["record"]
		var station_feedback := _transit_station_feedback(station_hover)
		var station_communities := _transit_community_names(station_record.get("community_ids",[]))
		var station_community_text := "、".join(station_communities) if not station_communities.is_empty() else "暂无直接覆盖社区"
		var line_names: Array = station_hover.get("line_names",[])
		var line_text := "、".join(line_names) if not line_names.is_empty() else "公交线路"
		var demand := float(station_feedback.get("demand",0.0))
		var role_text := "换乘站" if station_hover.get("line_ids",[]).size() > 1 else "中途站"
		var rhythm_text := str(station_feedback.get("state_text","等待真实客流"))
		if demand > 0.1 and station_hover.get("line_ids",[]).size() > 1 and int(station_feedback.get("transfers",0)) > 0:
			rhythm_text += " · 已进入密集脉冲"
		var transfer_hint := "可换乘至："+line_text if station_hover.get("line_ids",[]).size() > 1 else "接入线路："+line_text
		tooltip.text = "站点 · %s · %s\n%s · %s\n覆盖%d栋 · 社区：%s\n%s\n%s\n点击查看站点并规划下一条线路" % [role_text,str(station_hover["id"]),transfer_hint,str(station_record.get("road", "真实道路")),station_record.get("covered_building_ids",[]).size(),station_community_text,rhythm_text,str(station_feedback.get("next_text","下一乐句继续组合线路"))]
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
		if first_composition_mode:
			tooltip.text = "%s · %s\n%s\n点击改音 · Tab独听这个街坊" % ["律动街" if b["type"] == "commercial" else "长音房",note_name(int(model.audible_pitches().get(b["district_id"],b["current_midi"]))),shown_world.communities[b["community_id"]]["name"]]
	elif not bridge_hover.is_empty():
		var names: Array = bridge_hover.get("community_names",[])
		var before := "未连通" if is_inf(float(bridge_hover.get("route_before",INF))) else ("%.1f步" % float(bridge_hover.get("route_before",0.0)))
		tooltip.text = "桥位预影 · %s\n真实道路：%s\n步行 %s → %.1f步 · %s\nG确认；下一乐句接入两岸道路、交通与空间声学" % [" ↔ ".join(names),"、".join(bridge_hover.get("road_ids",[])),before,float(bridge_hover.get("route_after",0.0)),str(bridge_hover.get("traffic_after","两岸联奏线"))]
	else:
		var pending_reservation := _pending_reservation_at(p)
		var reservation := shown_world.planning_at(p)
		var site := shown_world.public_at(p)
		if not pending_reservation.is_empty():
			tooltip.text = "待留地 · 下一句普通成长绕开这里\n当前合奏保持不变；留地本身不新增声音\n边界落定后可继续保持、释放或改作公园/文化馆"
		elif not reservation.is_empty():
			tooltip.text = "你留下的空地 · 房屋不会长进来\n点击选择释放、建公园或文化设施；规划面板也可自由留地"
		elif check["allowed"]:
			tooltip.text = "%s\n%s\n点击选音；Shift低八度；按住空格试听" % [str(check["preview"]),note_name(midi)]
			if first_composition_mode: tooltip.text = "可生长的空地 · %s\n点击选择声音 · 按住空格试听" % note_name(midi)
			var lot: String = check["lot_id"]
			hover_seconds = hover_seconds+delta if lot == last_hover_lot else 0.0
			if lot != last_hover_lot: last_hover_lot = lot
			if hover_seconds > 0.18 and hover_seconds < 0.18+delta: _light_note(midi+12 if midi < 48 else midi)
		elif not site.is_empty():
			tooltip.text = site["name"]+"\n"+("已落成 · 沿道路覆盖%d栋\n公园为主题留白" % site.get("covered",[]).size() if site["active"] else "公共保留地 · 点击营造\n公园让音乐呼吸，文化设施组织主题")
			if first_composition_mode and not bool(site["active"]): tooltip.visible = false
			if site["active"] and site["kind"] == "civic":
				tooltip.text = "%s · 文化设施%d级\n覆盖%d栋 · 已服务%d/%d栋\n%s" % [site["name"],int(site.get("service_level",1)),site.get("covered",[]).size(),site.get("served",[]).size(),int(site.get("service_capacity",18)),"点击后选公共设施，下一句扩容" if int(site.get("service_level",1)) < 3 else "三级扩容完成 · 文化主题继续演奏"]
		else:
			tooltip.text = str(check["reason"])+("\n滚轮缩放 · 中键移动" if first_composition_mode else "\n滚轮缩放 · 中键移动 · G建桥 · H全城 · Y切换地形 · E扩展城\nR晴岸 · V深流 · T林荫交响 · N空地\nCtrl+S存一版 · F9继续")
	pending_composition_choice = PendingCompositionChoice.state(self)
	var status_line := notice if notice_seconds > 0.0 else _planning_status_hint()
	if _show_pending_composition_choice():
		var result_text := "下一句长出你的房屋" if str(pending_composition_choice["kind"]) in ["deep","weave","warm"] else "下一句落定，再给社区选声音"
		if str(pending_composition_choice["kind"]) == "none": result_text = "下一句给社区选声音"
		status_line = "%s · %s已选好 · %s" % [pending_composition_choice["community"],pending_composition_choice["label"],result_text]
		if pointer_inside and pointer.y >= size.y-45:
			status_line += " · 还剩%d拍（%.1f秒）" % [ceili(float(pending_composition_choice["beats_to_boundary"])),float(pending_composition_choice["time_to_boundary"])]
	elif not hover_card_status.is_empty():
		status_line = hover_card_status if status_line.is_empty() else status_line+" · "+hover_card_status
	caption.text = status_line
	caption.visible = not black and not status_line.is_empty() and not community_workbench.opened and (not first_composition_mode or not (menu.visible or planning_guide.opened))
	tooltip.size.y = tooltip.get_combined_minimum_size().y
	tooltip.position = Vector2(clampf(pointer.x+18,12,maxf(12,size.x-tooltip.size.x-12)),clampf(pointer.y+20,118,maxf(118,size.y-tooltip.size.y-110)))
	if menu.visible:
		_update_selected_opportunity()
		menu.size = menu.get_combined_minimum_size()
		menu.position = Vector2(clampf(menu.position.x,12,maxf(12,size.x-menu.size.x-12)),clampf(menu.position.y,70,maxf(70,size.y-menu.size.y-12)))
		_planning_menu()
		_place_first_composition_menu()
		if pointer_inside and not _expression_context() and not _authored_retune() and not _authored_reservation_context() and not menu.get_global_rect().grow(100).has_point(pointer): menu.hide()
	queue_redraw()
	_profile_frame("interaction_ms",frame_started)

func _show_pending_composition_choice() -> bool:
	return not pending_composition_choice.is_empty() and not black and not menu.visible and not planning_guide.opened and not preview_started

func _sync_daylight() -> void:
	daylight_state = Daylight.sample(clock.renderer.transport.audible_frame,clock.renderer.transport.sample_rate,daylight_manual_phase)
	daylight_state = art_direction.daylight(daylight_state)
	if art_direction.selected_id == "baseline" and shown_world.era == 1:
		daylight_state = Daylight.classical(daylight_state)
	if art_review_panel != null: art_review_panel.sync()
	var tint: Color = daylight_state["world_tint"]
	terrain_layer.modulate = tint
	city_ground_layer.modulate = tint
	water_flow.modulate = daylight_state["water_tint"]
	var frame := clock.renderer.transport.audible_frame
	var warmth := 0.03*sin(TAU*frame/float(clock.renderer.transport.sample_rate)/4.0)
	buildings_layer.modulate = tint*Color(0.96+warmth,1.0,1.0)
	buildings_layer.set_meta("world_tint",tint)
	frontage_details.modulate = Color(tint.r/buildings_layer.modulate.r,1.0,1.0)
	var night := float(daylight_state["night_strength"])
	for id: String in facade_lights:
		var light: FacadeLight = facade_lights[id]
		if int(shown_world.by_id[id]["birth_frame"]) > frame:
			light.hide()
		else:
			light.sync(sprites[id].progress >= 1.0,night,buildings_layer.modulate*sprites[id].modulate)
	backdrop.color = Color.BLACK if black else daylight_state["backdrop"]
	shadow_layer.modulate.a = float(daylight_state["shadow_strength"])
	caption.add_theme_color_override("font_color",RefinedUi.PAPER)
	tooltip.add_theme_color_override("font_color",RefinedUi.INK)

func set_art_direction(id: String) -> void:
	if not art_study_enabled or id not in ArtDirection.STYLE_IDS or id == art_direction.selected_id: return
	art_direction.selected_id = id
	# Retained cornices use the new entry's real roof height and extents.
	street_eaves_layer.clear()
	_sync_buildings()
	_sync_daylight()
	for prop: ValleyProp in scenery.props.values(): scenery._sync_prop_art(self,prop)
	street_eaves_layer.sync(self)
	expression_audition_layer.sync(self)
	queue_redraw()

func _street_orientation(at: Vector2,entrance: Vector2 = Vector2.INF) -> int:
	# The displayed road graph owns orientation; never scan it at every draw.
	var key := _shown_city_key()+[shown_world.road_index_identity]
	if street_orientation_key != key:
		street_orientation_key = key
		street_orientation_cache.clear()
	var query := Vector4(at.x,at.y,entrance.x,entrance.y)
	if not street_orientation_cache.has(query):
		street_orientation_cache[query] = StreetOrientation.street_orientation(shown_world,at,entrance)
	return int(street_orientation_cache[query])

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
	var display_key := _shown_city_key()+[shown_world.buildings.size(),pitches.hash(),art_direction.selected_id,shown_world.road_index_identity]
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
		facade_lights.erase(id)
		building_geometry.erase(id)
		shadow_records.erase(id)
		shadows_dirty = true
		append_only = false
	for building in shown_world.buildings:
		var id: String = building["district_id"]
		var world_position := Coupling.position_of(building)
		var entry: Dictionary = building_catalog.entry_for(building,assets[building["type"]],shown_world.families.get(str(building.get("family_id","")),{}),_street_orientation(world_position))
		var key := [world_position,entry["id"]]
		var geometry_dirty := false
		if not building_geometry.has(id) or building_geometry[id]["key"] != key:
			geometry_dirty = true
			if building_geometry.has(id): append_only = false
			building_geometry[id] = {"key":key,"entry":entry,"image":building_catalog.image_for(entry),"position":Projection2D.to_screen(world_position-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),shown_world.terrain.height_at(world_position)),
				"scale":28.0*sqrt(2.0)*0.8/maxf(float(entry["model_bounds"]["size"][0]),float(entry["model_bounds"]["size"][2]))/float(entry["pixels_per_world"])}
			shadows_dirty = true
		var geometry: Dictionary = building_geometry[id]
		var scale_factor: float = geometry["scale"]
		if not sprites.has(id):
			shadows_dirty = true
			# A restored city can reuse geometry while owning entirely new sprites.
			# Attach its facade to the new actual parent even when that cache hits.
			geometry_dirty = true
			var sprite := GrowthSprite.new()
			sprite.use_master_clock = false
			sprite.texture = building_catalog.texture_for(entry)
			sprite.centered = false
			sprite.offset = -Vector2(entry["origin"][0],entry["origin"][1])
			buildings_layer.add_child(sprite)
			sprite.begin_at(maxi(0,int(building["birth_frame"])))
			sprites[id] = sprite
		var sprite: AudioGrowthMask = sprites[id]
		if geometry_dirty:
			sprite.texture = building_catalog.texture_for(entry)
			sprite.offset = -Vector2(entry["origin"][0],entry["origin"][1])
			var mask := building_catalog.emission_for(entry)
			if mask != null and not facade_lights.has(id):
				var light := FacadeLight.new()
				sprite.add_child(light)
				facade_lights[id] = light
			if facade_lights.has(id): facade_lights[id].set_entry(entry,mask)
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
	if not transit_station_focus_id.is_empty():
		var focus_position := shown_world.transit_stop_position(transit_station_focus_id)
		if focus_position != Vector2.INF:
			draw_arc(point(focus_position),15.0*view_zoom,0,TAU,40,Color("e5b64e",0.95),2.4*view_zoom,true)
			draw_string(ThemeDB.fallback_font,point(focus_position)+Vector2(10,-12),"已选站点",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("8a6825"))
	var flow := float(clock.renderer.transport.audible_frame)/float(clock.renderer.transport.sample_rate)
	_draw_community_names()
	_draw_public_labels()
	_draw_authored_selection()
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
		if bool(op.get("player_expression",false)):
			color = Color(FirstExpressionIdentity.STYLES[str(op["expression"])]["ink"],0.35)
		draw_colored_polygon(_project_polygon(shown_world.building_polygon(p)),color)
		draw_arc(point(p),10.0*view_zoom,0,TAU,24,color,1.0,true)
	if ripple_seconds > 0.0:
		draw_arc(point(ripple_position),(1.0-ripple_seconds/0.6)*55.0*view_zoom,0,TAU,48,Color(0.83,0.74,0.48,ripple_seconds/0.6),1.7,true)
	if not hover_id.is_empty():
		draw_arc(point(Coupling.position_of(shown_world.by_id[hover_id])),18*view_zoom,0,TAU,48,Color(0.62,0.72,0.5,0.8),1.5,true)
	var font := ThemeDB.fallback_font
	var ui_ink: Color = daylight_state.get("ui_ink",Color("4b6561"))
	if not first_composition_mode:
		draw_string(font,Vector2(46,44),"共鸣之城",HORIZONTAL_ALIGNMENT_LEFT,-1,22,ui_ink)
		draw_string(font,Vector2(47,67),_composition_title(),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(ui_ink,0.78))
	_draw_authored_voice_legend(ui_ink)
	_draw_landmark_bar()
	if not black and (not first_composition_mode or not (menu.visible or planning_guide.opened)):
		var lead := str(model.audible_theme().get("cid",""))
		var name := str(shown_world.communities.get(lead,{}).get("name","留白"))
		var decree_slots := " · 政令槽%d" % shown_world.landmark_intervention_slots() if shown_world.landmark_intervention_slots() > 1 else ""
		var service := overlay_service
		var status := "第%d句 · %s · %s · %d栋/%d社区 · %d功能区 · %d条线路 · 文化%d/%d栋 · %d段待播 · 主题%s%s" % [shown_world.phrase_index,shown_world.era_title(),shown_world.vehicle_label(),shown_world.buildings.size(),shown_world.active_community_count(),shown_world.functional_zones.size(),shown_world.transit_lines.size(),int(service.get("served",0)),shown_world.buildings.size(),model.world.pending_actions.size(),name,decree_slots]
		if first_composition_mode: status = "第%d句 · %d栋房屋 · %s主题%s" % [shown_world.phrase_index,shown_world.buildings.size(),name," · 选择待播" if not pending_composition_choice.is_empty() or not model.world.pending_actions.is_empty() else ""]
		draw_string(font,Vector2(size.x-(380 if first_composition_mode else 760),size.y-64),status,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(ui_ink,0.85))
	var duration := float(model.phrase_frames)
	var progress := fposmod(float(clock.renderer.transport.audible_frame),duration)/duration
	draw_line(Vector2(48,size.y-32),Vector2(size.x-48,size.y-32),Color(0.59,0.66,0.6,0.25),2.0)
	if _show_pending_composition_choice():
		var ink := Color("a89059")
		var kind := str(pending_composition_choice["kind"])
		if FirstExpressionIdentity.STYLES.has(kind): ink = FirstExpressionIdentity.STYLES[kind]["ink"]
		var group_width := (size.x-96)/8.0
		for group in range(8):
			var from := Vector2(48+group_width*group,size.y-32)
			var to := from+Vector2(group_width-5,0)
			draw_line(from,to,Color(ink,0.24),4.0)
			var group_progress := clampf(float(pending_composition_choice["progress"])*8.0-group,0.0,1.0)
			if group_progress > 0.0: draw_line(from,from.lerp(to,group_progress),Color(ink,0.9),4.0)
	else:
		draw_line(Vector2(48,size.y-32),Vector2(48+(size.x-96)*progress,size.y-32),Color("af9c6a"),3.0)
	_profile_frame("draw_ms",draw_started)

func _composition_title() -> String:
	if not first_composition_mode:
		return shown_world.terrain_title()+" · 晴岸合奏" if expression == "bright" else shown_world.terrain_title()+" · 深流慢板"
	var authored_count := AuthoredDuet.roots(shown_world,model.audible_pitches()).size()
	if authored_count <= 1: return "河湾 · 第一段"
	if authored_count == 2: return "河湾 · 两岸合奏"
	return "河湾 · %d段合奏" % authored_count

func _draw_authored_voice_legend(ui_ink: Color) -> void:
	if not first_composition_mode: return
	if is_instance_valid(core_slice_hud) and core_slice_hud.visible: return
	var roots: Array[Dictionary] = AuthoredDuet.roots(shown_world,model.audible_pitches())
	if roots.size() < 2: return
	var font := ThemeDB.fallback_font
	var x := 47.0
	draw_string(font,Vector2(x,88),"你的声音",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(ui_ink,0.62))
	x += font.get_string_size("你的声音",HORIZONTAL_ALIGNMENT_LEFT,-1,11).x+12.0
	for root: Dictionary in roots:
		var expression := str(root.get("expression",""))
		var choice: Dictionary = PlayerExpression.definition(expression)
		var family: Dictionary = shown_world.families.get(str(root.get("family_id","")),{})
		var identity: Dictionary = FirstExpressionIdentity.identity(root,family)
		var ink: Color = identity.get("ink",Color("7b8b81"))
		var pitch := int(root.get("current_midi",48))
		var community := str(root.get("community_name",root.get("community_id","")))
		var text := "%s · %s %s%d · %s" % [community,str(choice.get("label",expression)),note_name(pitch),pitch/12-1,str(choice.get("sound",""))]
		draw_circle(Vector2(x+4,84),4.0,Color(ink,0.92))
		draw_string(font,Vector2(x+12,88),text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(ink,0.95))
		x += font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x+22.0

func _draw_authored_selection() -> void:
	if not first_composition_mode or not _authored_retune() or not shown_world.by_id.has(selected_id): return
	var building: Dictionary = shown_world.by_id[selected_id]
	var choice := PlayerExpression.definition(str(building["expression"]))
	var at := point(Coupling.position_of(building))
	var label := "你种下的"+str(choice["label"])
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,13)
	var origin := at-Vector2(text_size.x*0.5,55.0*view_zoom)
	draw_line(at-Vector2(0,10),origin+Vector2(text_size.x*0.5,10),Color("aa8956",0.85),1.3,true)
	draw_style_box(_authored_label_style(),Rect2(origin-Vector2(7,15),text_size+Vector2(14,8)))
	draw_string(font,origin,label,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("6d5737"))

func _authored_label_style() -> StyleBoxFlat:
	if authored_badge_style == null:
		authored_badge_style = StyleBoxFlat.new()
		authored_badge_style.bg_color = Color("f3ecd6",0.96)
		authored_badge_style.set_corner_radius_all(6)
	return authored_badge_style

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
	if first_composition_mode: return
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
	var title := _partial_action_title() if free_target else ("局部公园" if partial_kind == "park" else "局部文化馆")
	var label := title+"预影 · "+("按 Enter 确认" if free_target else "点击确认")
	if not bool(preview.get("accepted",false)):
		return label.replace(" · "+("按 Enter 确认" if free_target else "点击确认")," · "+str(preview.get("reason","位置不可用")))
	return label+" · 按住空格比较 · 下一乐句落成 · 入口 %s · %s · 保留%d片留地" % [str(preview.get("road_id","未知道路")),str(preview.get("target_community_id","未知社区")),int(preview.get("remaining_count",0))]

func _draw_planning_preview() -> void:
	if transit_route_mode and pointer_inside:
		var transit_draw := _transit_route_preview(true)
		var route_color := Color("c88942") if bool(transit_draw.get("accepted",false)) else Color("b35e58")
		var transit_summary: Dictionary = planning_guide.transit_preview_feedback(transit_draw)
		var transfer_stop_ids := _transit_transfer_stop_ids(transit_draw,transit_summary)
		for leg in transit_draw.get("legs",[]):
			var raw_path: PackedVector2Array = leg.get("path",PackedVector2Array())
			if raw_path.size() > 1:
				var projected := PackedVector2Array()
				for p in raw_path: projected.append(point(p,shown_world.terrain.height_at(p)+0.12))
				draw_polyline(projected,Color(route_color,0.22),7.0*view_zoom,true)
				draw_polyline(projected,Color(route_color,0.90),2.0*view_zoom,true)
		for index in range(transit_draw.get("stops",[]).size()):
			var stop: Dictionary = transit_draw["stops"][index]
			var p := Vector2(float(stop["position"][0]),float(stop["position"][1]))
			var screen := point(p,shown_world.terrain.height_at(p)+0.28)
			var is_transfer := transfer_stop_ids.has(str(stop.get("id","")))
			if is_transfer:
				draw_circle(screen,10.0*view_zoom,Color(0.96,0.76,0.32,0.20))
				draw_arc(screen,9.0*view_zoom,0,TAU,24,Color("e5b64e",0.95),1.8*view_zoom,true)
			draw_circle(screen,7.0*view_zoom,Color(0.98,0.92,0.68,0.92))
			draw_circle(screen,4.0*view_zoom,Color(route_color,0.95))
			draw_string(ThemeDB.fallback_font,screen+Vector2(7,-7)*view_zoom,str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("604c32"))
			if is_transfer:
				draw_string(ThemeDB.fallback_font,screen+Vector2(7,9)*view_zoom,"换",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("8a6825"))
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
				if not partial_courtyard_mode: draw_colored_polygon(component_polygon,Color(0.35,0.78,0.65,0.12))
			for vertex in component:
				draw_circle(point(vertex),4.0,Color("4f9f7b",0.95))
		if partial_polygon_points.size() >= 2:
			var drawn := _project_polygon(partial_polygon_points)
			var closed := drawn.duplicate()
			closed.append(drawn[0])
			draw_polyline(closed,Color(draw_color,0.9),2.0,true)
		if partial_polygon_points.size() >= 3:
			var target_preview_polygon := _project_polygon(partial_polygon_points)
			if not partial_courtyard_mode: draw_colored_polygon(target_preview_polygon,Color(0.35,0.78,0.65,0.12))
			draw_line(point(partial_polygon_points[partial_polygon_points.size()-1]),point(world_at(pointer)),Color(draw_color,0.68),1.3,true)
		for vertex in partial_polygon_points:
			draw_circle(point(vertex),4.0,Color(draw_color,0.95))
		var partial_preview: Dictionary = planning_guide.candidate if planning_guide.opened and planning_guide.stage == "partial_anchor" else _partial_preview_for_draw()
		for residual in partial_preview.get("remaining_polygons",[]):
			var residual_polygon := _project_polygon(residual)
			draw_colored_polygon(residual_polygon,Color(0.45,0.72,0.48,0.13))
			if residual_polygon.size() > 1:
				residual_polygon.append(residual_polygon[0])
				draw_polyline(residual_polygon,Color(0.42,0.67,0.45,0.40),1.0,true)
		var target_polygons := _partial_preview_polygons(partial_preview)
		if not target_polygons.is_empty():
			var accepted := bool(partial_preview.get("accepted",false))
			for filled_target in _partial_preview_fill_polygons(partial_preview):
				draw_colored_polygon(_project_polygon(filled_target),Color(0.35,0.78,0.65,0.30) if accepted else Color(0.82,0.36,0.34,0.20))
			for raw_target in target_polygons:
				var target_polygon := _project_polygon(raw_target)
				if target_polygon.size() > 1:
					target_polygon.append(target_polygon[0])
					draw_polyline(target_polygon,Color("4f9f7b") if accepted else Color("b35e58"),2.0,true)
			for hole in SpatialPlanning.footprint_holes(partial_preview):
				var inner_outline := _project_polygon(hole)
				inner_outline.append(inner_outline[0])
				draw_polyline(inner_outline,Color("b18b55"),2.0,true)
				draw_string(ThemeDB.fallback_font,point(PartialPublic._representative_point(hole)),"内院留地",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("776247"))
			_draw_partial_access_preview(partial_preview)
			var partial_text := _partial_preview_label(partial_preview,true)
			draw_string(ThemeDB.fallback_font,point(world_at(pointer))+Vector2(10,-12),partial_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("41665b") if accepted else Color("9b4b4b"))
	if partial_mode and not partial_reservation_id.is_empty() and pointer_inside:
		var partial_preview: Dictionary = planning_guide.candidate if planning_guide.opened and planning_guide.stage == "partial_anchor" else PartialPublic.preview(shown_world,partial_reservation_id,partial_kind,world_at(pointer))
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
			var accepted := bool(relocation_preview.get("accepted",false))
			for filled_target in _partial_preview_fill_polygons(relocation_preview):
				draw_colored_polygon(_project_polygon(filled_target),Color(0.35,0.78,0.65,0.28) if accepted else Color(0.82,0.36,0.34,0.18))
			for component in _partial_preview_polygons(relocation_preview)+SpatialPlanning.footprint_holes(relocation_preview):
				var outline := _project_polygon(component)
				outline.append(outline[0])
				draw_polyline(outline,Color("4f9f7b") if accepted else Color("b35e58"),2.0,true)
			_draw_partial_access_preview(relocation_preview)
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
		if _expression_context() and expression_choice == "warm" and not expression_comparison.is_empty() and expression_comparison_key == _expression_preview_identity():
			for reservation: Dictionary in expression_comparison["variants"]["warm"]["consequences"].get("reservations",[]):
				var projected := _project_polygon(reservation["polygon"])
				draw_colored_polygon(projected,Color(0.34,0.70,0.59,0.20))
				projected.append(projected[0])
				draw_polyline(projected,Color("4f927f"),2.0,true)
	for op in model.world.pending_actions:
		if str(op.get("kind","")) == "transit_line":
			var positions: Array = op.get("stop_positions",[])
			var pending_route := TransitPlanning.preview(shown_world,positions)
			for leg in pending_route.get("legs",[]):
				var pending_path: PackedVector2Array = leg.get("path",PackedVector2Array())
				if pending_path.size() < 2: continue
				var pending_screen := PackedVector2Array()
				for p in pending_path: pending_screen.append(point(p,shown_world.terrain.height_at(p)+0.16))
				draw_polyline(pending_screen,Color(0.80,0.54,0.25,0.72),2.5*view_zoom,true)
			for stop in pending_route.get("stops",[]):
				var stop_p := Vector2(float(stop["position"][0]),float(stop["position"][1]))
				draw_circle(point(stop_p,shown_world.terrain.height_at(stop_p)+0.30),5.5*view_zoom,Color(0.96,0.76,0.35,0.86))
			continue
		if str(op.get("kind", "")) == "reserve":
			var reserve_color := Color("849b78")
			var reserve_components := SpatialPlanning.footprint_components(op)
			for reserve_polygon in reserve_components:
				var projected_reserve := _project_polygon(reserve_polygon)
				draw_colored_polygon(projected_reserve,Color(reserve_color,0.24))
				var closed_reserve := projected_reserve.duplicate()
				closed_reserve.append(closed_reserve[0])
				draw_polyline(closed_reserve,Color(reserve_color,0.92),2.0,true)
			var reserve_center := SpatialPlanning.bounds(reserve_components[0]).get_center() if not reserve_components.is_empty() else Vector2.ZERO
			draw_string(ThemeDB.fallback_font,point(reserve_center)+Vector2(9,-9),"待留地 · 下一句绕开",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("536d56"))
			continue
		var polygons: Array[PackedVector2Array] = []
		if op.has("target_polygon") or op.has("target_polygons"):
			polygons = _partial_preview_fill_polygons(op)
		elif op.has("polygon"):
			polygons.append(op["polygon"])
		var color := Color(0.65,0.78,0.56,0.55) if op["kind"] != "civic" else Color(0.82,0.73,0.56,0.55)
		for polygon in polygons: draw_colored_polygon(_project_polygon(polygon),color)

func _draw_bridge_preview() -> void:
	if shown_world == null: return
	if first_composition_mode and (not pointer_inside or planning_guide.opened or menu.visible or _bridge_preview_at(world_at(pointer)).is_empty()): return
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
	if not pointer_inside or menu.visible or planning_guide.opened: return
	var p := world_at(pointer)
	for site in shown_world.near_public_sites(p):
		if first_composition_mode and not bool(site["active"]): continue
		if not SpatialPlanning.point_in_footprint(site,p): continue
		var center := Vector2(site["position"][0],site["position"][1])
		draw_string(ThemeDB.fallback_font,point(center)+Vector2(-30,30)*view_zoom,site["name"],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("617b69"))

func _sync_map_labels() -> void:
	community_label_layer.sync(self)
	if menu.visible and _expression_context(): community_label_layer.hide()

func _draw_community_names() -> void:
	# CommunityNames retains these commands independently of the live HUD.
	pass
