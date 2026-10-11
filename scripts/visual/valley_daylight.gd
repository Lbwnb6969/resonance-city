extends RefCounted
## A visual cycle derived from the audible sample clock. No accumulated time,
## RNG, World changes, audio controls or additional archive fields.
const CYCLE_SECONDS := 150.0
const CITY_DELAY_SECONDS := 0.5
const STOPS := [0.0,0.16,0.30,0.48,0.60,0.77,0.92,1.0]
const WORLD_TINTS := [Color.WHITE,Color.WHITE,Color(1.0,0.90,0.79),Color(0.48,0.61,0.73),
	Color(0.48,0.61,0.73),Color(0.83,0.89,0.95),Color.WHITE,Color.WHITE]
const BACKDROPS := [Color("ecebe2"),Color("ecebe2"),Color("dccbc5"),Color("556d80"),
	Color("556d80"),Color("c1ced0"),Color("ecebe2"),Color("ecebe2")]
const WATER_TINTS := [Color.WHITE,Color.WHITE,Color(1.0,0.97,0.88),Color(0.56,0.76,0.85),
	Color(0.56,0.76,0.85),Color(0.94,1.0,1.0),Color.WHITE,Color.WHITE]
const NIGHT_STRENGTHS := [0.0,0.0,0.20,1.0,1.0,0.28,0.0,0.0]

static func _span(phase: float) -> Array:
	for index in range(STOPS.size()-1):
		if phase <= float(STOPS[index+1]):
			var t := (phase-float(STOPS[index]))/(float(STOPS[index+1])-float(STOPS[index]))
			return [index,t*t*(3.0-2.0*t)]
	return [STOPS.size()-2,1.0]

static func _color(values: Array,phase: float) -> Color:
	var span := _span(phase)
	return values[int(span[0])].lerp(values[int(span[0])+1],float(span[1]))

static func _night(phase: float) -> float:
	var span := _span(phase)
	return lerpf(float(NIGHT_STRENGTHS[int(span[0])]),float(NIGHT_STRENGTHS[int(span[0])+1]),float(span[1]))

static func sample(frame: float,rate: int,manual_phase: float = -1.0) -> Dictionary:
	var seconds := maxf(0.0,frame)/float(rate)
	var phase := fposmod(seconds,CYCLE_SECONDS)/CYCLE_SECONDS
	var city_phase := fposmod(maxf(0.0,seconds-CITY_DELAY_SECONDS),CYCLE_SECONDS)/CYCLE_SECONDS
	# Runtime screenshot/inspection control; callers never put it in a work save.
	if manual_phase >= 0.0:
		phase = fposmod(manual_phase,1.0)
		city_phase = phase
	var night := _night(city_phase)
	var label := "白昼"
	if phase >= 0.18 and phase < 0.38: label = "黄昏"
	elif phase >= 0.38 and phase < 0.67: label = "夜晚"
	elif phase >= 0.67 and phase < 0.90: label = "晨光"
	return {"phase":phase,"label":label,"world_tint":_color(WORLD_TINTS,city_phase),
		"backdrop":_color(BACKDROPS,phase),"water_tint":_color(WATER_TINTS,city_phase),
		"night_strength":night,"shadow_strength":lerpf(1.0,0.52,night),
		"ui_ink":Color("465b58").lerp(Color("e3eae6"),night),
		"window_color":Color("ffd98a"),"cycle_seconds":CYCLE_SECONDS}
