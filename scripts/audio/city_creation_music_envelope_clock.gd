extends RefCounted
## Sounding concert fades follow audio time; ordinary creation keeps its clock.
static func step(owner:Node,delta:float)->float:
	if not owner.concert_active:
		if owner.has_meta("concert_envelope_clock"):owner.remove_meta("concert_envelope_clock")
		return delta
	var city:RefCounted=owner._pluck_city
	var context:Array=[city.get_instance_id() if city!=null else 0,city._wish_epoch if city!=null else 0,owner._concert_venue,owner._concert_clock_origin]
	var now:float=owner._playback_clock()
	var previous:Dictionary=owner.get_meta("concert_envelope_clock",{})
	owner.set_meta("concert_envelope_clock",{"context":context,"at":now})
	return maxf(0.,now-float(previous.at)) if previous.get("context",[])==context else delta
