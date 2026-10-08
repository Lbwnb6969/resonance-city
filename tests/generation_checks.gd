class_name GenerationChecks
extends RefCounted

const Contract = preload("res://tests/contract_support.gd")
const Generator = preload("res://scripts/city/city_generator.gd")
const Streams = preload("res://scripts/city/named_random.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Harmony = preload("res://scripts/city/harmony.gd")

static func city(tree: SceneTree) -> int:
	var test := Contract.new("CITY-002", "initial_r")
	var generator := Generator.new()
	var harmony := Harmony.new()
	var first := generator.generate("0123456789abcdef")
	var second := generator.generate("0123456789abcdef")
	test.check(first == second, "Fixed seed exactly reproduces city and generation records")
	test.check(first["city"].size() == 9, "P0 city has 9 districts")
	var counts := {"residential":0,"commercial":0,"industrial":0}
	for district in first["city"]:
		counts[district["type"]] += 1
	test.check(counts == {"residential":3,"commercial":3,"industrial":3}, "Three districts per type")
	test.check(first["resonance"] >= 65 and first["resonance"] == harmony.resonance(first["city"], harmony.adjacency(first["city"])), "Initial R is computed before presenting city")
	var failed: Array = []
	for index in range(3):
		failed.append(Schema.create("a"+str(index), "residential", Vector2i(index*2,0)))
		failed.append(Schema.create("b"+str(index), "industrial", Vector2i(index*2+1,0)))
		failed.append(Schema.create("c"+str(index), "commercial", Vector2i(index*2,4)))
	test.check(harmony.resonance(failed, harmony.adjacency(failed)) == 0, "Forced failure fixture is genuinely below R floor")
	var same_layout := func(city: Array) -> Array: return city
	var daily := generator.generate("fedcba9876543210", true, failed, same_layout)
	test.check(daily["fallback"] and daily["seed"] == "fedcba9876543210", "Daily fallback preserves fixed seed")
	test.check(daily["generation_records"].size() == 10, "Initial + 8 local attempts + recorded safe fallback")
	test.check(daily["generation_records"][8]["local_attempt"] == 8, "Local resample stops at 8")
	test.check(absf(float(daily["resonance"]) - 85.0) <= float(generator.space["comparison_tolerance"]), "Safe fixture is genuinely R=85 within approved multiedge tolerance")
	var normal := generator.generate("fedcba9876543210", false, failed, same_layout)
	test.check(not normal["fallback"] and normal["seed"] != "fedcba9876543210" and normal["requested_seed"] == "fedcba9876543210", "Non-daily failed seed changes with retained provenance")
	test.details = {"normal_seed":first["seed"],"initial_R":first["resonance"],"forced_daily_records":daily["generation_records"]}
	test.finish(tree, "P0 seed generation and measured initial R, finite local retry and fixed-daily safe fallback", false)
	return test.failures

static func streams(tree: SceneTree) -> int:
	var rng_test := Contract.new("RUN-002", "rng_replay")
	var untouched := Streams.new("0123456789abcdef")
	var changed := Streams.new("0123456789abcdef")
	changed.bounded("events", 100)
	rng_test.check(untouched.bounded("terrain", 100) == changed.bounded("terrain", 100), "Events do not alter terrain")
	rng_test.check(untouched.bounded("boons", 100) == changed.bounded("boons", 100), "Events do not alter boons")
	var saved := untouched.snapshot()
	var preview := untouched.fork()
	preview.bounded("events", 100)
	rng_test.check(untouched.snapshot() == saved, "Preview fork leaves true counters unchanged")
	var word := untouched.next_u32("form")
	untouched.restore(saved)
	rng_test.check(untouched.next_u32("form") == word, "Counter snapshot replays exactly")
	rng_test.check(Streams.daily_seed("2026-10-08","p0-1") == ("daily:2026-10-08p0-1").sha256_text().substr(0,16), "Explicit UTC text and version generate stable daily seed")
	rng_test.check(Streams.daily_seed("2026-10-08","p0-1") != Streams.daily_seed("2026-10-09","p0-1"), "UTC date changes daily seed")
	rng_test.check(Streams.daily_seed("2026-10-08","p0-1") != Streams.daily_seed("2026-10-08","p0-2"), "Version changes daily seed")
	rng_test.details = {"seed":"0123456789abcdef","daily":"2026-10-08","full_run_replay":"PENDING beyond P0"}
	rng_test.finish(tree, "Five named counter streams + P0 city reproducibility; full run decisions replay pending", false)
	return rng_test.failures
