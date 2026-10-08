class_name NamedRandom
extends RefCounted
## SHA-256 counter streams: stable text serialization, no global RNG.

const STREAMS := ["terrain", "mode", "boons", "form", "events"]
const UINT32_RANGE := 4294967296

var seed_hex: String
var counters: Dictionary = {}
var stream_seeds: Dictionary = {}

func _init(seed: String) -> void:
	assert(seed.length() == 16 and seed.is_valid_hex_number(false), "Expected 16 hex characters")
	seed_hex = seed.to_lower()
	for stream in STREAMS:
		counters[stream] = 0
		stream_seeds[stream] = (seed_hex + ":" + stream).sha256_text()

static func daily_seed(utc_date: String, version: String) -> String:
	return ("daily:" + utc_date + version).sha256_text().substr(0, 16)

static func current_daily_seed() -> String:
	var utc := Time.get_date_dict_from_system(true)
	var date := "%04d-%02d-%02d" % [utc["year"], utc["month"], utc["day"]]
	return daily_seed(date, str(ProjectSettings.get_setting("application/config/version")))

func next_u32(stream: String) -> int:
	assert(counters.has(stream))
	var word := (str(stream_seeds[stream]) + ":" + str(counters[stream])).sha256_text().substr(0, 8).hex_to_int()
	counters[stream] = int(counters[stream]) + 1
	return word

func bounded(stream: String, upper: int) -> int:
	assert(upper > 0 and upper <= UINT32_RANGE)
	var limit := (UINT32_RANGE / upper) * upper
	while true:
		var word := next_u32(stream)
		if word < limit:
			return word % upper
	return 0

func snapshot() -> Dictionary:
	return {"seed_hex": seed_hex, "counters": counters.duplicate(true)}

func restore(saved: Dictionary) -> void:
	assert(saved["seed_hex"] == seed_hex)
	for stream in STREAMS:
		counters[stream] = int(saved["counters"][stream])

func fork() -> NamedRandom:
	var copy := NamedRandom.new(seed_hex)
	copy.restore(snapshot())
	return copy
