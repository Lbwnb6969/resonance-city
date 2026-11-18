extends SceneTree
## Targeted production audio check. Cast comes from an existing actual UI journey.
const State=preload("res://scripts/world/city_creation_state.gd")
const Music=preload("res://scripts/audio/city_creation_music.gd")
const Evidence=preload("res://tools/fixtures/city_creation_stream_evidence.gd")
const Span=preload("res://tools/fixtures/city_creation_recording_span.gd")
var out:=""
var baseline:=""
var checks:Array=[]
var failures:Array[String]=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks.append({"ok":ok,"label":label})
	if not ok:failures.append(label);push_error(label)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--cast-from="):baseline=arg.trim_prefix("--cast-from=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out) or baseline.is_empty():quit(1);return
	DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(640,360);Engine.max_fps=60
	var old:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(baseline));var source:String=old.facts.source
	var source_hash:=FileAccess.get_sha256(source);var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	var city:=State.new();var restored:Dictionary=city.restore(JSON.parse_string(FileAccess.get_file_as_string(source)))
	check(restored.ok and source_hash==old.facts.source_sha256,"actual previously tested work and cast source remain identical")
	var cast:Dictionary={}
	for phase:int in [0,2,4,6]:cast[old.observed[str(phase)].era]=old.observed[str(phase)].source
	var venue:String=old.observed["7"].source
	var view:={"phase":"playing","venue_id":venue,"grand_festival":true,"era_cast":cast,"elapsed":0.,"duration":24.,"source":"manual","chorus_house_ids":cast.values()}
	var data:Dictionary=city.snapshot();data.journey_checkpoint={"concert":view}
	check(city.GrandFestival.validate(city,data).ok,"existing four-era cast matches current real house roles and eras")
	var music:=Music.new();root.add_child(music);music.setup(city)
	var deadline:=Time.get_ticks_msec()+10000
	while music.audio_report.is_empty() and Time.get_ticks_msec()<deadline:await process_frame
	check(not music.audio_report.is_empty() and music.audio_report.get("bank_source","")=="precompiled" and music.audio_report.get("bank_codec","")=="qoa","current production compact bank loads without runtime synthesis")
	if music.audio_report.is_empty():music.queue_free();await process_frame;quit(1);return
	music.set_listener_frame(Vector2(5.,24.8),Vector2.RIGHT,17.)
	var identity:Array=music._players.values().map(func(player:AudioStreamPlayer):return player.get_instance_id())
	deadline=Time.get_ticks_msec()+8000
	while not music.concert_can_start() and Time.get_ticks_msec()<deadline:await process_frame
	music.set_concert_view(view)
	var recording:=Span.start();var capture:=AudioEffectCapture.new();capture.buffer_length=1.
	var bus:=AudioServer.get_bus_index(music.spatial.report().bus_names[0]);AudioServer.add_bus_effect(bus,capture)
	var observed:Dictionary={};var peaks:Dictionary={};var frames:Array=[];var began:=Time.get_ticks_usec();var prior:=began
	while Time.get_ticks_usec()-began<27000000:
		await process_frame
		var now:=Time.get_ticks_usec();frames.append({"wall_ms":(now-prior)/1000.,"engine_delta":root.get_process_delta_time()});prior=now
		var report:Dictionary=music.grand_festival_report();var peak:=0.
		for sample:Vector2 in capture.get_buffer(capture.get_frames_available()):peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		if float(report.elapsed)>float(report.phrase)*3.+.3:peaks[int(report.phrase)]=maxf(float(peaks.get(int(report.phrase),0.)),peak)
		if float(report.elapsed)>float(report.phrase)*3.+1.8 and not observed.has(int(report.phrase)):
			var roles:Dictionary=music.get_meta("chamber_roles");var stem:String=roles.lead_track;var role:Dictionary=roles.roles[stem]
			observed[int(report.phrase)]={"era":report.era,"stem":stem,"id":role.id,"layer":role.layer,"db":music._players[stem].volume_db,"audible":music.active_source().audible,"remote":report.remote,"weight":music._long_acoustic_weight(stem),"evidence":Evidence.capture(music,stem,str(role.id))}
		if report.elapsed>=24.4:break
		# Reproduce the real case: audio mixing continues while main-thread delta clamps.
		OS.delay_msec(350)
	var measured_seconds:float=(Time.get_ticks_usec()-began)/1000000.
	music.set_process(false);var pcm:=Span.finish(recording,out+"/Master.wav");AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
	check(observed.size()==8 and peaks.size()==8 and peaks.values().all(func(value:float)->bool:return value>.00001),"all eight production phrases have actual non-silent theme PCM")
	check(observed.size()==8 and observed.values().all(func(row:Dictionary)->bool:return row.audible and row.layer==3),"scheduled era melodies reach the original audible threshold under slow frames")
	check(observed.size()==8 and observed.values().all(func(row:Dictionary)->bool:return row.evidence.qualified and not "chamber_counter_" in str(row.id)),"actual stable streams and old/blended/target premix PCM agree with current melodies")
	check(observed.get(4,{}).get("db",-80.)>-38. and observed.get(4,{}).get("remote",false) and is_equal_approx(observed.get(4,{}).get("weight",0.),.25),"clockwork first phrase fades in at the original remote quarter gain")
	check(frames.any(func(row:Dictionary)->bool:return row.wall_ms>300. and row.engine_delta<.15),"real main-thread stalls reproduce audio time advancing beyond simulation delta")
	check(pcm.ok and measured_seconds>=24. and measured_seconds<27.,"real-time Master completes the eight-phrase observation without clipping")
	check(identity==music._players.values().map(func(player:AudioStreamPlayer):return player.get_instance_id()) and identity.size()==12 and music._effects.size()==4 and music.spatial.report().bus_count==6,"all existing voice and bus identities remain fixed")
	check(FileAccess.get_sha256(source)==source_hash and FileAccess.get_file_as_bytes(State.DEFAULT_PATH)==personal,"official source and personal continuation bytes remain unchanged")
	var result:={"ok":failures.is_empty(),"checks":checks,"count":checks.size(),"failures":failures,"observed":observed,"phase_peaks":peaks,"pcm":pcm,"seconds":measured_seconds,"frames":frames,"bank_source":music.audio_report.bank_source,"bank_codec":music.audio_report.get("bank_codec",""),"bank_signature":music.BankCache.source_signature(),"source":source,"source_sha256":source_hash,"cast_from":baseline,"scope":"Production Music with actual 350ms main-thread stalls; cast reused from the earlier real UI/arrival journey. No new Life, renderer or input acceptance claim."}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("FESTIVAL_AUDIO ",JSON.stringify({"ok":result.ok,"count":result.count,"failures":failures,"seconds":measured_seconds,"pcm":pcm}))
	music.queue_free();await process_frame;await create_timer(.1).timeout;quit(0 if failures.is_empty() else 1)
