extends RefCounted
## Extra edit-time guard. Historical snapshot overlap rules stay unchanged.
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const FLOOR:=1.7
const TERRACE:=.18
const EPS:=.000001
static func houses(first:Dictionary,second:Dictionary)->bool:
	var first_base:=float(first.get("base_y",0.));var second_base:=float(second.get("base_y",0.))
	if is_equal_approx(first_base,second_base):return false
	for a:Dictionary in first.cells:
		var low_a:=first_base+int(a.level)*FLOOR
		var high_a:=low_a+(TERRACE if a.kind=="terrace" else FLOOR)
		for b:Dictionary in second.cells:
			# Same authored levels already use the original overlap predicate.
			if int(a.level)==int(b.level):continue
			var low_b:=second_base+int(b.level)*FLOOR
			var high_b:=low_b+(TERRACE if b.kind=="terrace" else FLOOR)
			if minf(high_a,high_b)-maxf(low_a,low_b)<=EPS:continue
			# Retain the grid's 1mm horizontal contact tolerance.
			if Frame.boxes_overlap(Frame.footprint(first,a,-.0005),Frame.footprint(second,b,-.0005)):return true
	return false
