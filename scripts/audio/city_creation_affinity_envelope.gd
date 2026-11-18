extends RefCounted
## Candidate observation and continuous mix are separate from current facts.
const OBSERVE:=6.
const TAIL:=6.
var value:=0.
var _candidate:=""
var _established: Dictionary = {}
var _since:=0.
var _latched:=false
var _missing_since:=-1.
var _city:=0
var _last_clock:=-1.
func step(facts:Dictionary,clock:float,delta:float,allow_observation:bool=true)->Dictionary:
	if _city!=facts.city or clock<_last_clock:
		_city=facts.city;value=0.;_candidate="";_established.clear();_latched=false;_missing_since=-1.;_since=clock
	_last_clock=clock
	var ids:Array=facts.source_ids.duplicate();ids.sort()
	var amount := float(facts.enclosure)
	var reusable := _latched or (value > 0. and _missing_since >= 0. and clock - _missing_since < TAIL)
	var additive := facts.has("contributions")
	var parts: Array = facts.get("contributions", [{"source_ids":ids, "value":amount}])
	var retained := 0.
	var awaiting: Dictionary = {}
	for part: Dictionary in parts:
		var sources: Array = part.source_ids
		if sources.is_empty(): continue
		if reusable and (additive or sources.size() == _established.size()) and sources.all(func(id): return _established.has(id)):
			retained += float(part.value)
		else:
			awaiting[JSON.stringify(sources)] = true
	var pending := awaiting.keys()
	pending.sort()
	var desired := amount >= (.35 if _latched and retained > 0. else .55) and not ids.is_empty()
	# Follow the new contributors during observation. An established neighbor
	# moving out of frame must not reset their timer.
	var candidate := JSON.stringify(pending) if amount >= .55 and not pending.is_empty() else ""
	if candidate != _candidate:
		_candidate = candidate
		_since = clock
	if not allow_observation: _since = clock
	var target := minf(retained, amount) if desired else 0.
	if desired and not candidate.is_empty() and clock - _since >= OBSERVE:
		target = amount
		_established.clear()
		for id: String in ids: _established[id] = true
	_latched = target > 0.
	if _latched: _missing_since = -1.
	elif _missing_since < 0.: _missing_since = clock
	value=lerpf(value,target,1.-exp(-maxf(0.,delta)/(3.2 if target>value else 1.5)))
	if _missing_since>=0. and clock-_missing_since>=TAIL:value=0.
	return {"value":value,"target":target,"candidate":desired,"observed_seconds":clock-_since,"current_source_ids":ids,"historical_tail":value>0. and not _latched,"historical_source_ids":_established.keys() if value>0. and not _latched else [],"tail_deadline":_missing_since+TAIL if _missing_since>=0. else -1.,"facts":facts}
