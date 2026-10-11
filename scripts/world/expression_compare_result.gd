extends RefCounted
## Read-only comparison for the three first-expression preview branches.
##
## ExpressionPreview remains the source of truth.  This adapter deliberately
## reports only fields present in that actual preview result: it never fills a
## missing route, predicts later growth, or ranks one choice as better.
const PlayerExpression = preload("res://scripts/world/player_expression.gd")

const CONTRACT := "P12-EXPRESSION-COMPARE-RESULT/v1"
const LABELS := {"deep":"深流", "weave":"织机", "warm":"留地"}
const NOTE_NAMES := {0:"C", 2:"D", 4:"E", 7:"G", 9:"A"}
const CITY_TYPES := {"residential":"住宅", "commercial":"商业", "industrial":"工业", "park":"公园", "civic":"公共设施"}

static func note_label(midi: int) -> String:
	var name := str(NOTE_NAMES.get(posmod(midi,12),"音"))
	return "%s%d" % [name, floori(float(midi) / 12.0) - 1]

static func _profile(variant: Dictionary) -> Dictionary:
	var profiles: Array = variant.get("metrics",{}).get("rhythm_profiles",[])
	if profiles.is_empty() or not (profiles[0] is Dictionary): return {}
	return profiles[0]

static func _events(variant: Dictionary) -> Array:
	var events: Array = variant.get("metrics",{}).get("pulse_events",[])
	return events.duplicate(true)

static func _pcm_difference(first: Variant,second: Variant) -> float:
	if not (first is PackedByteArray) or not (second is PackedByteArray): return 0.0
	var maximum := 0.0
	for offset in range(0,mini(first.size(),second.size()),2):
		maximum = maxf(maximum,absf(float(first.decode_s16(offset)-second.decode_s16(offset))/32767.0))
	return maximum

static func _variant_card(id: String,variant: Dictionary,comparison: Dictionary) -> Dictionary:
	if variant.is_empty() or not bool(variant.get("accepted",false)):
		return {"available":false,"route":id,"route_label":str(LABELS.get(id,id)),"reason":str(variant.get("reason","未生成实际结果"))}
	var definition := PlayerExpression.definition(id)
	var operation: Dictionary = variant.get("operation",{})
	var birth: Dictionary = variant.get("birth",{}).get("building",{})
	var profile := _profile(variant)
	var consequences: Dictionary = variant.get("consequences",{})
	var pcm: PackedByteArray = variant.get("pcm",PackedByteArray())
	if pcm.is_empty() or consequences.is_empty():
		return {"available":false,"route":id,"route_label":str(LABELS.get(id,id)),"reason":"试听尚未生成"}
	var pitch := int(profile.get("pitch",operation.get("midi",definition.get("midi",0))))
	var spacing_frames := float(profile.get("spacing_frames",0.0))
	var rate := int(comparison.get("sample_rate",0))
	var duration_frames := int(comparison.get("duration_frames",0))
	var events := _events(variant)
	return {"available":true,"route":id,"route_label":str(LABELS.get(id,id)),
		"description":str(definition.get("sound","")),"city_description":str(definition.get("city","")),
		"source":{"building_id":str(birth.get("district_id","")),"community_id":str(birth.get("community_id",consequences.get("community_id",""))),
			"position":birth.get("position",[]).duplicate(true)},
		"audio":{"pcm_bytes":pcm.size(),"pcm_frames":pcm.size()/4,"sample_rate":rate,
			"duration_frames":duration_frames,"duration_seconds":float(comparison.get("seconds",0.0)),
			"peak":float(variant.get("peak",0.0)),"max_voices":int(variant.get("max_voices",0))},
		"register":{"midi":pitch,"label":note_label(pitch),"base_midi":int(operation.get("midi",definition.get("midi",pitch))),
			"base_label":note_label(int(operation.get("midi",definition.get("midi",pitch))))},
		"rhythm":{"spacing_frames":spacing_frames,"spacing_seconds":spacing_frames/float(maxi(1,rate)),
			"tail_seconds":float(profile.get("tail",0.0)),"attack_seconds":float(profile.get("attack",0.0)),
			"decay_seconds":float(profile.get("decay",0.0)),"offset":int(profile.get("offset",definition.get("rhythm_offset",0))),
			"event_count":events.size(),"events":events},
		"city":{"community_id":str(consequences.get("community_id",birth.get("community_id",""))),
			"building_type":str(consequences.get("type",birth.get("type",""))),"expression":str(consequences.get("expression",id)),
			"family_buildings":int(consequences.get("family_buildings",0)),"city_buildings":int(consequences.get("city_buildings",0)),
			"next_growth_phrase":int(consequences.get("next_growth_phrase",-1)),"mature":int(consequences.get("mature",0)),
			"theme_eligible":bool(consequences.get("theme_eligible",false)),"reservation_count":int(consequences.get("reservation_count",0)),
			"reservations":consequences.get("reservations",[]).duplicate(true)},
		"actual":true}

static func summary(comparison: Dictionary) -> Dictionary:
	if comparison.is_empty(): return {}
	var routes: Dictionary = {}
	var missing: Array[String] = []
	for id: String in PlayerExpression.IDS:
		var variant: Dictionary = comparison.get("variants",{}).get(id,{})
		var card := _variant_card(id,variant,comparison)
		if bool(card.get("available",false)): routes[id] = card
		else: missing.append(id)
	var pairs: Dictionary = {}
	var pcm: Dictionary = comparison.get("variants",{})
	for pair in [["deep","weave"],["deep","warm"],["weave","warm"]]:
		var left: Dictionary = pcm.get(pair[0],{})
		var right: Dictionary = pcm.get(pair[1],{})
		if bool(left.get("accepted",false)) and bool(right.get("accepted",false)):
			pairs[pair[0]+"_"+pair[1]] = _pcm_difference(left.get("pcm",PackedByteArray()),right.get("pcm",PackedByteArray()))
	return {"contract":CONTRACT,"actual_only":true,"complete":missing.is_empty() and routes.size() == PlayerExpression.IDS.size(),
		"source":{"key":str(comparison.get("source_key","")),"frame":int(comparison.get("source_frame",-1)),
			"boundary_frame":int(comparison.get("boundary_frame",-1)),"same_source":not str(comparison.get("source_key","" )).is_empty()},
		"audio":{"sample_rate":int(comparison.get("sample_rate",0)),"gain":float(comparison.get("gain",0.0)),
			"seconds":float(comparison.get("seconds",0.0)),"duration_frames":int(comparison.get("duration_frames",0))},
		"routes":routes,"missing":missing,"pair_pcm_max_abs":pairs}

static func _sound_character(route: Dictionary) -> String:
	var rhythm: Dictionary = route.get("rhythm",{})
	var spacing := float(rhythm.get("spacing_seconds",0.0))
	if spacing <= 0.0: return str(route.get("description","")).replace(" · ","，")
	var pitch := int(route.get("register",{}).get("midi",0))
	# Keep the readable card aligned with the three authored routes.  The
	# first-expression roots are C2 (deep), C3 (warm), and C4 (weave); using a
	# generic octave cutoff of 64 mislabeled the weave C4 as "中音" even though
	# the choice and button promise a high, bright register.
	var register := "低音" if pitch < 48 else ("中音" if pitch < 60 else "高音")
	var length := "短促" if float(rhythm.get("tail_seconds",0.0)) < 0.5 else "长响"
	var movement := "密集织拍" if spacing < 1.0 else ("慢慢铺底" if spacing < 3.0 else "留出空隙")
	return register+length+"，"+movement

static func _city_consequence(route: Dictionary) -> String:
	var city: Dictionary = route.get("city",{})
	var type := str(city.get("building_type",""))
	var description := str(CITY_TYPES.get(type,"建筑"))+"生长"
	var reserved := int(city.get("reservation_count",0))
	if reserved > 0: description += "，保留%d片空地" % reserved
	return description

static func text(result: Dictionary,selected: String = "") -> String:
	## Three short player choices; detailed measurements remain available below.
	if result.is_empty(): return ""
	var lines: Array[String] = []
	var routes: Dictionary = result.get("routes",{})
	for id: String in PlayerExpression.IDS:
		var prefix := "▶ " if id == selected else ""
		var route: Dictionary = routes.get(id,{})
		if not bool(route.get("available",false)):
			var reason := str(result.get("missing_reasons",{}).get(id,""))
			lines.append(prefix+str(LABELS.get(id,id))+" · 未生成试听"+(" · "+reason if not reason.is_empty() else ""))
			continue
		lines.append(prefix+str(route.get("route_label",id))+" · "+_sound_character(route)+" · "+_city_consequence(route))
	return "\n".join(lines)

static func player_text(comparison: Dictionary,selected: String = "") -> String:
	## Formatting a live card does not rescan or compare sample buffers.
	if comparison.is_empty() or comparison.get("variants",{}).is_empty(): return ""
	var result := {"routes":{},"missing_reasons":{}}
	for id: String in PlayerExpression.IDS:
		var card := _variant_card(id,comparison.get("variants",{}).get(id,{}),comparison)
		if bool(card.get("available",false)): result["routes"][id] = card
		else: result["missing_reasons"][id] = str(card.get("reason",""))
	return text(result,selected)

static func technical_text(result: Dictionary) -> String:
	if result.is_empty(): return ""
	var lines: Array[String] = []
	var source: Dictionary = result.get("source",{})
	var audio: Dictionary = result.get("audio",{})
	lines.append("同一试听来源 · %dHz · %.2f秒 · 边界%d" % [int(audio.get("sample_rate",0)),float(audio.get("seconds",0.0)),int(source.get("boundary_frame",-1))])
	for id: String in PlayerExpression.IDS:
		if not result.get("routes",{}).has(id): continue
		var route: Dictionary = result["routes"][id]
		var rhythm: Dictionary = route.get("rhythm",{})
		var city: Dictionary = route.get("city",{})
		var reserve := "留地%d块" % int(city.get("reservation_count",0))
		lines.append("%s · %s · PCM%d帧 · 每%.2f秒/尾%.2f秒 · %s · 第%d句 · %s" % [
			str(route.get("route_label",id)),str(route.get("register",{}).get("label","音域未知")),
			int(route.get("audio",{}).get("pcm_frames",0)),
			float(rhythm.get("spacing_seconds",0.0)),float(rhythm.get("tail_seconds",0.0)),
			str(CITY_TYPES.get(str(city.get("building_type","")),city.get("building_type","未知用地"))),
			int(city.get("next_growth_phrase",-1)),reserve])
	var differences: Array[String] = []
	for pair: String in ["deep_weave","deep_warm","weave_warm"]:
		if result.get("pair_pcm_max_abs",{}).has(pair): differences.append("%s %.5f" % [pair,float(result["pair_pcm_max_abs"][pair])])
	if not differences.is_empty(): lines.append("PCM差异（实际试听） · "+" · ".join(differences))
	if not result.get("missing",[]).is_empty(): lines.append("未生成实际结果 · "+"、".join(result["missing"]))
	return "\n".join(lines)
