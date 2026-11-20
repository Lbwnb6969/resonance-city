extends RefCounted
## Transient scheduling only: never edits a city or interrupts a playing song.
const OBSERVE:=6.
const IDLE:=3.
var established:=""
var candidate:=""
var observed:=0.
var elapsed:=0.
var last_edit:=-INF
var serial:=-1
var was_dragging:=false
func step(era:String,delta:float,sculpt_serial:int,dragging:bool)->void:
	elapsed+=maxf(0.,delta)
	if established.is_empty():established=era
	var changed:=era!=candidate
	if changed:candidate=era;observed=0.
	if dragging or was_dragging or serial>=0 and sculpt_serial!=serial:last_edit=elapsed
	was_dragging=dragging
	serial=sculpt_serial
	if elapsed-last_edit<IDLE:observed=0.;return
	# The interval before a different era is sampled belongs to the previous view.
	if candidate!=established and not changed:
		observed+=minf(maxf(0.,delta),maxf(0.,elapsed-last_edit-IDLE))
		if observed>=OBSERVE:established=candidate
func reason()->String:
	if elapsed-last_edit<IDLE:return "construction"
	return "era_observation" if candidate!=established else ""
