extends "res://tools/check_game_music_live.gd"

const Brush = preload("res://scripts/world/city_creation_build_brush.gd")
const WEST := Vector2(-32., -25.)
const EAST := Vector2(-14., -25.)
const POND_OFFSET := Vector2(0., -2.4)

func focus_at(at: Vector2) -> void:
	demo.focus = Vector3(at.x, .8, at.y)
	demo.zoom = 16.
	demo._update_camera()

func measure(node: Node) -> Dictionary:
	return {"at":str(demo.music._listener_focus), "sources":node.spatial_facts.flow_sources.duplicate(),
		"flow":node.spatial_facts.flow, "target":node.color_states.flow.target,
		"gain":node.values.motion, "mix":node.color_states.flow.value, "cursor":node.player.get_playback_position(),
		"era":node.spatial_facts.era, "tail":node.color_states.flow.historical_tail}

func traverse(node: Node, snapshot: Dictionary) -> void:
	check(await wait_for(func(): return float(node.color_states.get("flow", {}).get("value", 0.)) > .6, 18000),
		"west pond enters after the existing observation window")
	var player: AudioStreamPlayer = node.player
	var stream: AudioStream = player.stream
	var record := Span.start()
	facts.west = measure(node)
	focus_at(WEST.lerp(EAST, .5))
	await create_timer(.3).timeout
	facts.overlap = measure(node)
	check(facts.west.era == "pastoral" and facts.west.sources.has("h1") and not facts.west.sources.has("h2"),
		"first focus belongs to the actual western district")
	check(facts.overlap.sources.has("h1") and facts.overlap.sources.has("h2") and facts.overlap.flow > .85,
		"both independently authored ponds contribute at the junction")
	check(facts.overlap.target > .40 and facts.overlap.target < .55,
		"still-visible west pond supports its share while east is being observed")
	await create_timer(2.).timeout
	facts.sweep = measure(node)
	check(facts.sweep.mix > .39 and facts.sweep.target < .55,
		"brief focus sustains the observed source without enabling the unobserved contribution")
	check(await wait_for(func():return float(node.color_states.flow.target) > .85, 7000),
		"staying at the junction admits the new pond after observation")
	facts.settled = measure(node)
	focus_at(EAST)
	await create_timer(.4).timeout
	facts.east = measure(node)
	check(facts.east.era == "clockwork" and facts.east.sources.has("h2") and not facts.east.sources.has("h1"),
		"second focus belongs to the actual eastern district")
	check(facts.east.target > .85 and not facts.east.tail,
		"remaining observed east pond keeps its target as west falls outside the lens")
	check(node.player == player and player.stream == stream and facts.east.cursor > facts.west.cursor,
		"crossing the districts changes the same playing mix in place")
	check(demo.state.snapshot() == snapshot, "camera and music observation do not edit the city")
	if node.prepared.manifest.schema == "city_sparse_music_v2":
		var layers: Array = node.prepared.manifest.layers
		var voice: Dictionary = layers.filter(func(row): return row.id == "motion")[0]
		var index: int = node.prepared.ids.find("motion")
		check(voice.control == "flow" and is_equal_approx(facts.east.gain, facts.east.mix * float(voice.automatic_max)),
			"sparse source receives the same mix within its declared voice cap")
		check(is_equal_approx(db_to_linear(stream.get_sync_stream_volume(index)), float(facts.east.gain)),
			"the mix is installed on the real synchronized stream")
	await capture("east_pond")
	var removal: Dictionary = demo.state.remove_water_at(EAST + POND_OFFSET)
	check(removal.ok, "remove the real eastern pond")
	if removal.ok:
		demo._after_edit(removal, "water")
		await settle()
		facts.removed = measure(node)
		check(facts.removed.sources.is_empty() and facts.removed.target == 0. and facts.removed.tail,
			"deletion revokes current contribution and leaves a bounded tail")
		await key(KEY_Z, true)
		await settle()
		facts.restored = measure(node)
		check(demo.state.waters == snapshot.waters and facts.restored.target > .85 and not facts.restored.tail,
			"Undo restores the exact pond and recovers its observed mix")
	facts.pcm = Span.finish(record, OUT + "/cross_district_Master.wav")
	check(facts.pcm.ok, "actual WASAPI Master capture has signal and zero clipped samples")

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):
			OUT = arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):
		quit(1)
		return
	var began := Time.get_ticks_msec()
	var personal := FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1440, 900)
	Engine.max_fps = 60
	demo = Scene.instantiate()
	demo.persistence = false
	demo.collection_directory = OUT + "/works"
	root.add_child(demo)
	await settle()
	isolate_input()
	var city := State.new()
	city.initialize_free()
	check(city.add_house(WEST).ok and Brush.select(city, "clockwork") and city.add_house(EAST).ok, "author two distinct-era districts")
	for at: Vector2 in [WEST, EAST]:
		check(city.add_water([at + POND_OFFSET] as Array[Vector2], 2.4, "pond").ok, "author independent pond " + str(at))
	await show(city, WEST, "双岸街区")
	quiet()
	demo.life.set_process(false)
	focus_at(WEST)
	var snapshot: Dictionary = demo.state.snapshot()
	var voices := pool()
	var pointer: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/active_game_music.json"))
	var sparse := "--sparse" in OS.get_cmdline_user_args()
	var path: String = pointer.sparse_trial.catalog if sparse else pointer.catalog
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var packs: Array = catalog.packs.filter(func(row): return row.name.begins_with("2-04 ·")) if sparse else catalog.packs
	var ticket := GamePlayer.request(demo.music, packs[0].manifest)
	var node: Node = ticket.get("node")
	var active := await wait_for(func():return is_instance_valid(node) and node.active, 30000)
	check(active, "opt-in same-source candidate activates")
	if active:
		await traverse(node, snapshot)
	check(pool() == voices, "pooled voice and bus identities remain fixed")
	check(personal == FileAccess.get_file_as_bytes(State.DEFAULT_PATH), "personal save remains byte-identical")
	var result := {"ok":failures.is_empty(), "checks":checks, "failures":failures, "facts":facts,
		"seconds":(Time.get_ticks_msec()-began)/1000., "listening_approved":false}
	FileAccess.open(OUT + "/report.json", FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print("CROSS_DISTRICT ", JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(int(not failures.is_empty()))
