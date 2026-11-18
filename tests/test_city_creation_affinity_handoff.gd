extends SceneTree
const Envelope = preload("res://scripts/audio/city_creation_affinity_envelope.gd")
const WEST := ["h1", "shared_river"]
const EAST := ["h2", "shared_river"]

var checks := 0
var failures: Array[String] = []
var envelope := Envelope.new()
var clock := 0.

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func facts(west: float, east: float, city: int = 1) -> Dictionary:
	var result := {"city":city, "source_ids":[], "enclosure":west + east, "contributions":[]}
	for side: Dictionary in [{"source_ids":WEST, "value":west}, {"source_ids":EAST, "value":east}]:
		if side.value <= 0.: continue
		result.contributions.append(side)
		for id: String in side.source_ids:
			if not result.source_ids.has(id): result.source_ids.append(id)
	return result

func advance(sample: Dictionary, steps: int, allow: bool = true) -> Dictionary:
	var response: Dictionary
	for i in range(steps):
		clock += .1
		response = envelope.step(sample, clock, .1, allow)
	return response

func run() -> void:
	var began := Time.get_ticks_msec()
	var out := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="): out = arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	var west := facts(.9, 0.)
	var middle := facts(.5, .4)
	var east := facts(0., .9)
	var packet := advance(west, 90, false)
	check(packet.target == 0. and packet.value == 0., "continuous construction never banks a new observation")
	packet = advance(west, 100)
	check(packet.target == .9 and packet.value > .6, "establish initial west mix")
	packet = advance(middle, 40)
	check(packet.target == .5 and not packet.historical_tail, "hold only the weighted west share during overlap")
	packet = advance(east, 4)
	check(packet.target == 0. and packet.historical_tail and packet.current_source_ids == EAST,
		"a distinct home on the same river does not inherit observation")
	packet = advance(east, 19)
	check(packet.target == .9 and not packet.historical_tail, "leaving west retains the elapsed east observation")
	packet = advance(facts(0., .45), 1)
	check(packet.target == .45, "established subset preserves release hysteresis")
	packet = advance(facts(0., 0.), 1)
	check(packet.target == 0. and packet.historical_source_ids == EAST, "withdrawn contributor reports only its bounded historical tail")
	packet = advance(east, 1)
	check(packet.target == .9 and not packet.historical_tail, "same source recovered within the release window")
	packet = advance(facts(0., 0.), 64)
	check(packet.value == 0. and packet.historical_source_ids.is_empty(), "tail expires without a new contributor")
	packet = advance(east, 1)
	check(packet.target == 0., "an expired source must be observed again")
	packet = advance(facts(0., .9, 2), 1)
	check(packet.value == 0. and packet.target == 0. and not packet.historical_tail, "same IDs from another city start fresh")
	var contour := {"city":3, "source_ids":["h3","h4"], "enclosure":.84}
	packet = advance(contour, 72)
	check(packet.target == .84, "nonadditive contour retains the whole-sample observation contract")
	var split := {"city":3, "source_ids":["h4"], "enclosure":.84}
	packet = advance(split, 1)
	check(packet.target == 0. and packet.historical_tail, "nonadditive contour does not invent a partial contribution")
	var result := {"ok":failures.is_empty(), "checks":checks, "failures":failures, "seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(out + "/report.json", FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print("AFFINITY_HANDOFF ", JSON.stringify(result))
	quit(int(not result.ok))
