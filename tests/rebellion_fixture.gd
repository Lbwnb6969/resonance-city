extends RefCounted
# Explicit test instrumentation only: never used by the playable city or generator.
const Values = preload("res://scripts/spec_values.gd")
static func inject(synth: DistrictSynth, renderer: SampleRenderer, id: String, deviation: float, at: int) -> bool:
	var settings: Dictionary = Values.load_values()["rebellion_fixture"]
	var magnitude := absf(deviation)
	if not is_finite(deviation) or magnitude < float(settings["minimum_deviation"]) or magnitude > float(settings["maximum_deviation"]): return false
	if at != renderer.transport.rendered_frames or at%renderer.transport.phrase_frame(1) != 0: return false
	if not synth.routing.any(func(route: Dictionary) -> bool: return route["id"] == id): return false
	var key := "_rhythm_fixture_"+id
	if renderer.state.has(key): return false
	var original := int(renderer.state[id])
	renderer.state[id] = original+int(settings["pitch_offset"])
	renderer.state[key] = {"start_frame":at,"start_grid_frame":at,"speed":1.0+deviation,"original_midi":original}
	return true
static func restore(renderer: SampleRenderer, id: String, at: int) -> bool:
	var key := "_rhythm_fixture_"+id
	if not renderer.state.has(key) or at != renderer.transport.rendered_frames or at%renderer.transport.phrase_frame(1) != 0: return false
	renderer.state[id] = int(renderer.state[key]["original_midi"])
	renderer.state.erase(key)
	return true
