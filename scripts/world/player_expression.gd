extends RefCounted
## Player choices become real families and existing score parts, never preview filters.
const IDS := ["deep","weave","warm"]

static func catalogue() -> Array[Dictionary]:
	return [
		{"id":"deep","label":"深流","midi":36,"type":"residential","growth_phrase_multiplier":2,
			"sound":"低音 · 慢拍长音","city":"住宅缓慢生长，留下更多规划时间",
			"rhythm_beats":4.0,"rhythm_tail":1.6,"rhythm_attack":0.04,"rhythm_decay":0.55,"rhythm_offset":0,
			"theme_tail":2.2,"theme_attack":0.05,"theme_decay":0.85,"theme_octave":36,"theme_steps":[0,8,16,24]},
		{"id":"weave","label":"织机","midi":60,"type":"commercial","growth_phrase_multiplier":1,
			"sound":"高音 · 短促织拍","city":"商业优先生长，把街坊织成活跃节奏",
			"rhythm_beats":0.5,"rhythm_tail":0.12,"rhythm_attack":0.004,"rhythm_decay":0.04,"rhythm_offset":12,
			"theme_tail":0.24,"theme_attack":0.005,"theme_decay":0.065,"theme_octave":60,"theme_steps":[0,1,2,4,6,8,10,12,16,18,20,24,26,28,30]},
		{"id":"warm","label":"留地","midi":48,"type":"residential","growth_phrase_multiplier":1,
			"sound":"中音 · 长和声与留白","city":"住宅生长，保住邻近一块真实空地，主题留出空隙",
			"rhythm_beats":8.0,"rhythm_tail":2.2,"rhythm_attack":0.09,"rhythm_decay":0.8,"rhythm_offset":7,
			"theme_tail":3.0,"theme_attack":0.08,"theme_decay":1.2,"theme_octave":48,"theme_steps":[0,12,24]}
	]

static func definition(id: String) -> Dictionary:
	for choice in catalogue():
		if str(choice["id"]) == id: return choice
	return {}

static func operation(id: String,position: Variant) -> Dictionary:
	var choice := definition(id)
	if choice.is_empty(): return {}
	var p: Array = [position.x,position.y] if position is Vector2 else position.duplicate()
	return {"kind":"seed","position":p,"midi":choice["midi"],"expression":id,"player_expression":true}
