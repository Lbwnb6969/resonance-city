extends RefCounted
## Harmonic-limited synthesis, keeping the diagnosis families and continuous phase.
static var tables: Dictionary = {}
static func table(kind: String, era: int, size: int) -> PackedFloat32Array:
	var key := "%s:%d:%d" % [kind,era,size]
	if tables.has(key): return tables[key]
	var era_profiles := {
		1: {"residential":[1.0,0.02,0.10],"commercial":[1.0,0.045,0.13],"industrial":[1.0,0.18,0.08]},
		2: {"residential":[1.0,0.055,0.085],"commercial":[1.0,0.09,0.115],"industrial":[1.0,0.15,0.10]},
		3: {"residential":[1.0,0.035,0.14],"commercial":[1.0,0.075,0.16],"industrial":[1.0,0.20,0.10]},
		4: {"residential":[1.0,0.025,0.12],"commercial":[1.0,0.06,0.18],"industrial":[1.0,0.25,0.12]},
		5: {"residential":[1.0,0.04,0.16],"commercial":[1.0,0.08,0.20],"industrial":[1.0,0.22,0.14]}
	}
	var profiles: Dictionary = era_profiles.get(era,era_profiles[1])
	var partials: Array = profiles[kind]
	var weight := 0.0
	for value in partials: weight += float(value)
	var result := PackedFloat32Array()
	result.resize(size)
	for index in range(size):
		var sample := 0.0
		for harmonic in range(partials.size()): sample += sin(TAU*index*(harmonic+1)/size)*float(partials[harmonic])
		result[index] = sample/weight
	tables[key] = result
	return result
