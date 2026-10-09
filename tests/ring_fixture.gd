extends RefCounted
const Schema = preload("res://scripts/city/district_schema.gd")
const Values = preload("res://scripts/spec_values.gd")
static func city(mixed: bool = true, center: Vector2i = Vector2i(8,8), prefix: String = "ring") -> Array:
	var result: Array = []
	var anchor := Schema.create(prefix+"_source","residential",center)
	anchor["current_midi"] = 48
	anchor["anchor_id"] = anchor["district_id"]
	anchor["is_anchor"] = true
	anchor["voice_level"] = 0.2
	anchor["form"] = "共鸣点"
	result.append(anchor)
	var notes := [48,52,48,55,48,57,48,48] if mixed else [48,48,48,48,48,48,48,48]
	var offsets: Array = Values.load_values()["ring"]["offsets"]
	for index in range(offsets.size()):
		var d := Schema.create(prefix+"_"+str(index),"residential",center+Vector2i(offsets[index][0],offsets[index][1]))
		d["current_midi"] = notes[index]
		d["anchor_id"] = anchor["district_id"]
		d["voice_level"] = 0.2
		d["form"] = ["群","央","腔"][index%3]
		result.append(d)
	return result
static func formed(city: Array) -> Dictionary:
	var Ring = load("res://scripts/city/city_ring.gd")
	var cfg: Dictionary = Values.load_values()
	var first: Dictionary = Ring.advance(city,{}, {},0,cfg)
	return Ring.advance(city,{},first["rings"],0,cfg)["rings"]
