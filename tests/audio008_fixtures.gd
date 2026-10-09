class_name Audio008Fixtures
extends RefCounted

const Schema = preload("res://scripts/city/district_schema.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Grouped = preload("res://scripts/audio/voice_group_budget.gd")
const SOURCE = "res://验证记录/P0/CITY-005_ring_round57.json"

static func source() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SOURCE))["details"]

static func static_city(count: int) -> Array:
	# Deliberately favourable grouping bound: three identical-phase timbres, no growth.
	var result: Array = []
	var types := ["residential","commercial","industrial"]
	for index in range(count):
		var district := Schema.create("static_%d" % index,str(types[index%3]),Vector2i(index%16,index/16))
		district["current_midi"] = 48
		result.append(district)
	return result

static func staged_city(count: int, same_pitch: bool = false) -> Array:
	# Real 27-district/two-ring source plus explicit mature stress extensions.
	# Extensions are fixtures, not a claim that production growth exceeds 27.
	var initial: Array = source()["controlled_full_city"].duplicate(true)
	var used: Dictionary = {}
	for district in initial:
		used[Schema.cell(district)] = true
	var notes := [48,50,52,55,57]
	for cell_index in range(256):
		if initial.size() >= count: break
		var cell := Vector2i(cell_index%16,cell_index/16)
		if used.has(cell): continue
		var index := initial.size()
		var district := Schema.create("stress_%d" % index,"residential" if index%2 == 0 else "commercial",cell)
		district["anchor_id"] = "west_source" if index%2 == 0 else "east_source"
		district["form"] = "腔"
		district["voice_level"] = 0.2
		district["current_midi"] = int(notes[index%notes.size()])
		initial.append(district)
	if same_pitch:
		for district in initial: district["current_midi"] = 48
	return initial

static func configured(count: int, grouped: bool, staged: bool, same_pitch: bool = false) -> Object:
	var city := staged_city(count,same_pitch) if staged else static_city(count)
	var renderer: Object = Grouped.new(city) if grouped else Synth.new(city)
	var synth: DistrictSynth = renderer.synth if grouped else renderer
	if staged:
		synth.gain = float(source()["calibration"]["gain"])
		synth.guard_enabled = true
		synth.sync_rings(source()["ring_states"],-44100)
	return renderer

static func actual_synth(renderer: Object) -> DistrictSynth:
	return renderer.synth if renderer is VoiceGroupBudget else renderer
