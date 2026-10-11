extends RefCounted
## Compact read-only card for the three real first-expression preview branches.
##
## The comparison dictionary is produced by ExpressionPreview.build().  This
## helper only formats accepted branch data; it never invents a consequence or
## changes the pending operation.  A row is shown as actual only when that
## branch contains the accepted PCM and its branch consequence.
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const ExpressionCompareResult = preload("res://scripts/world/expression_compare_result.gd")

const ROUTE_LABELS := {"deep":"深流", "weave":"织机", "warm":"留地"}
const TYPE_LABELS := {"commercial":"商业", "residential":"住宅"}

static func _route_label(id: String) -> String:
	return str(ROUTE_LABELS.get(id,id))

static func _type_label(kind: String) -> String:
	return str(TYPE_LABELS.get(kind,kind if not kind.is_empty() else "建筑"))

static func _actual_audio_text(variant: Dictionary,comparison: Dictionary) -> String:
	var metrics: Dictionary = variant.get("metrics",{})
	var profiles: Array = metrics.get("rhythm_profiles",[])
	var rate := int(comparison.get("sample_rate",0))
	if profiles.is_empty() or not (profiles[0] is Dictionary) or rate <= 0: return ""
	var profile: Dictionary = profiles[0]
	var pitch := int(profile.get("pitch",0))
	var spacing := float(profile.get("spacing_frames",0.0))/float(rate)
	var tail := float(profile.get("tail",0.0))
	return " · %s · 每%.2f秒/尾%.2f秒" % [ExpressionCompareResult.note_label(pitch),spacing,tail]

static func _pcm_differs_from(variants: Dictionary,id: String) -> Array[String]:
	var current: Variant = variants.get(id,{})
	if not current is Dictionary or not bool(current.get("accepted",false)):
		return []
	var pcm: PackedByteArray = current.get("pcm",PackedByteArray())
	if pcm.is_empty(): return []
	var result: Array[String] = []
	for other: String in PlayerExpression.IDS:
		if other == id: continue
		var candidate: Variant = variants.get(other,{})
		if not candidate is Dictionary or not bool(candidate.get("accepted",false)): continue
		var other_pcm: PackedByteArray = candidate.get("pcm",PackedByteArray())
		if not other_pcm.is_empty() and other_pcm != pcm: result.append(_route_label(other))
	return result

static func _row(id: String,variant: Dictionary,selected: String,comparison: Dictionary) -> String:
	var prefix := "▶ " if id == selected else "  "
	if not bool(variant.get("accepted",false)):
		return prefix+_route_label(id)+" · 未生成实际试听 · "+str(variant.get("reason","暂不可用"))
	var definition := PlayerExpression.definition(id)
	var consequence: Dictionary = variant.get("consequences",{})
	var sound := str(definition.get("sound",""))+_actual_audio_text(variant,comparison)
	var differs := _pcm_differs_from(comparison.get("variants",{}),id)
	var pcm_text := "PCM与"+"、".join(differs)+"不同" if not differs.is_empty() else "PCM暂未显示差异"
	var next_phrase := int(consequence.get("next_growth_phrase",-1))
	var growth := "下一句%s" % ("第%d句" % next_phrase if next_phrase >= 0 else "等待实际生长")
	var city := growth+" · "+_type_label(str(consequence.get("type","")))
	city += " · 成熟%d栋" % int(consequence.get("mature",0))
	if int(consequence.get("reservation_count",0)) > 0: city += " · 保留1片真实空地"
	return prefix+_route_label(id)+" · "+sound+" · "+pcm_text+"\n    "+city

static func text(comparison: Dictionary,selected: String = "") -> String:
	if comparison.is_empty(): return ""
	var variants: Variant = comparison.get("variants",{})
	if not variants is Dictionary or variants.is_empty(): return ""
	var lines: Array[String] = ["同一冻结下一句 · 四秒实际试听（未提交）"]
	for id: String in PlayerExpression.IDS:
		if variants.has(id): lines.append(_row(id,variants[id],selected,comparison))
		else: lines.append("  "+_route_label(id)+" · 未生成实际试听")
	return "\n".join(lines)
