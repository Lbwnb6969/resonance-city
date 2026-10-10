extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Terrain = preload("res://scripts/world/valley_terrain.gd")

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _initialize() -> void:
	var signatures: Dictionary = {}
	for family in Terrain.family_ids():
		var world := World.new("2026101000000082",true,family)
		world.build_expanded_town()
		var model := Model.new(world)
		var score: Dictionary = model.synth.score_snapshot()
		var theme: Dictionary = score.get("theme",{})
		check(str(theme.get("terrain","")) == family,"theme records terrain family: "+family)
		check(score.get("rhythms",[]).any(func(part: Dictionary) -> bool: return str(part.get("terrain","")) == family),"facility rhythm records terrain family: "+family)
		var nodes := model.synth.musical_nodes.values()
		check(not nodes.is_empty(),"terrain has an authored musical node: "+family)
		if nodes.is_empty(): continue
		var node: Dictionary = nodes[0]
		var wave: PackedFloat32Array = model.synth._musical_block(node,0,model.phrase_frames,22050)
		var checksum := 0.0
		for index in range(wave.size()): checksum += wave[index]*float((index%97)+1)
		signatures[family] = snapped(checksum,0.0001)
	var unique_signatures: Dictionary = {}
	for signature in signatures.values(): unique_signatures[JSON.stringify(signature)] = true
	check(unique_signatures.size() == Terrain.family_ids().size(),"terrain families produce different theme onset signatures")
	print("TERRAIN_MUSIC ",JSON.stringify({"failures":failures,"signatures":signatures}))
	quit(0 if failures.is_empty() else 1)
