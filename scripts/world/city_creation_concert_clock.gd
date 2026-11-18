extends RefCounted
## An audible concert follows the transport even when simulation deltas clamp.
## Standalone Life simulations retain their deterministic delta clock.
static func elapsed(life:Node3D,delta:float)->float:
	var current:float=life._concert.elapsed
	if life.concert_elapsed_source.is_valid():
		var transport:float=life.concert_elapsed_source.call(str(life._concert.venue_id))
		if transport>=0.:return minf(life.CONCERT_DURATION,maxf(current,transport))
	return minf(life.CONCERT_DURATION,current+delta)

static func transport(music:Node,venue:String,resumed_elapsed:float=-1.)->float:
	if not music.concert_active or music._concert_venue!=venue:return -1.
	if resumed_elapsed>=0.:music._concert_clock_origin=music._playback_clock()-resumed_elapsed
	return maxf(0.,music._playback_clock()-music._concert_clock_origin)
