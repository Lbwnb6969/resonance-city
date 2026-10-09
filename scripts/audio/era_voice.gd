extends RefCounted
## Harmonic-limited synthesis, keeping the diagnosis families and continuous phase.
static var tables: Dictionary = {}
static func table(kind: String, era: int, size: int) -> PackedFloat32Array:
	var key := "%s:%d:%d" % [kind,era,size]
	if tables.has(key): return tables[key]
	var profiles := {"residential":[1.0,0.02,0.10],"commercial":[1.0,0.045,0.13],"industrial":[1.0,0.18,0.08]}
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
