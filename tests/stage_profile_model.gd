extends "res://scripts/audio/city_audio_model.gd"
var fills: Array[Dictionary] = []
func render_block(state: Dictionary,start: int,count: int,rate: int) -> PackedVector2Array:
	var begin := Time.get_ticks_usec()
	var pcm := super.render_block(state,start,count,rate)
	fills.append({"start":start,"count":count,"usec":Time.get_ticks_usec()-begin})
	return pcm
