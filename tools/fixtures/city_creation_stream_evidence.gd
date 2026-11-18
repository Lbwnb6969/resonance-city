extends RefCounted
## Read the owned player and actual premix PCM, including its still-sounding old side.
const Transition=preload("res://scripts/audio/city_creation_stream_transition.gd")
const Score=preload("res://scripts/audio/city_creation_chamber_score.gd")
static func samples(wave:AudioStreamWAV,at:int,count:int)->PackedFloat32Array:
	var result:=PackedFloat32Array();result.resize(count)
	if wave.format==AudioStreamWAV.FORMAT_16_BITS:
		for i in range(count):result[i]=wave.data.decode_s16((at+i)*2)/32768.
	else:
		var playback:=wave.instantiate_playback();playback.start(0.)
		var data:=playback.mix_audio(float(AudioServer.get_mix_rate())/wave.mix_rate,at+count+2)
		for i in range(count):result[i]=data[at+i+2].x
		playback.stop()
	return result
static func pcm(row:Dictionary)->Dictionary:
	var boundary:=roundi(float(row.local_boundary)*Transition.RATE);var fade:=roundi(Transition.FADE*Transition.RATE)
	var maximum:=0.
	for start:int in [boundary-64,boundary+fade/2,boundary+fade+64]:
		var actual:=samples(row.stream,start,32)
		var old:=samples(row.old,start%Transition.FRAMES,32);var target:=samples(row.target,start%Transition.FRAMES,32)
		for i in range(32):
			var u:=clampf(float(start+i-boundary)/fade,0.,1.);var blend:=u*u*(3.-2.*u)
			maximum=maxf(maximum,absf(actual[i]-(old[i]*(1.-blend)+target[i]*blend)))
	return {"ok":maximum<=1./32768.,"maximum_error":maximum,"sample_windows":3,"samples":96}
static func family(id:String,key:String)->String:
	if id=="original":return Score.FAMILIES.get(key,"concert" if key=="concert" else "")
	if "chamber_counter_" in id:return ""
	for stem:String in Score.FAMILIES:
		if stem in id.split("/"):return Score.FAMILIES[stem]
	return ""
static func capture(owner:Node,key:String,id:String)->Dictionary:
	var player:AudioStreamPlayer=owner._players[key]
	var target:AudioStream=owner._variation_streams.get(id,owner._harmony_streams.get(id))
	var result:={"kind":"unresolved","qualified":false,"target_id":id,"playing":player.playing,"position":player.get_playback_position()}
	if target!=null and player.stream==target:
		result.kind="stable";result.qualified=player.playing;return result
	var transition:Node=owner.get_node_or_null("StreamTransition")
	if transition==null or not transition.moving.has(key):return result
	var row:Dictionary=transition.moving[key]
	if player.stream!=row.stream or row.target!=target or row.id!=id:return result
	var now:float=owner._playback_clock();var stage:="old" if now<row.boundary else "blend" if now<row.until else "target"
	var old_family:=family(str(row.old_id),key);var target_family:=family(id,key)
	var old_ok:=not old_family.is_empty() and (old_family==target_family or key=="concert")
	if row.old_id=="original":old_ok=old_ok and row.old==owner._original_streams.get(key)
	var verified:=pcm(row)
	result.merge({"kind":"premixed","stage":stage,"clock":now,"boundary":row.boundary,"until":row.until,"old_id":row.old_id,"old_family":old_family,"target_family":target_family,"old_is_current_melody":old_ok,"pcm":verified},true)
	result.qualified=player.playing and verified.ok and (stage=="target" or old_ok)
	return result
