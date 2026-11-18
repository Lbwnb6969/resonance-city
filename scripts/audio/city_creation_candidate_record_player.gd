extends "res://scripts/audio/city_creation_game_music_player.gd"
## Same lease/worker/cleanup as audition; playback has no spatial or song scheduler.
const Record=preload("res://scripts/audio/city_creation_candidate_record.gd")
var recorded_mix:Dictionary={}
var ended:=false
func _ready()->void:
	city_id=music._pluck_city.get_instance_id();city_epoch=music._pluck_city._wish_epoch;preferences=JSON.stringify(music._pluck_city.creative_settings.music)
	cues.setup(self);var value:=recorded_mix.duplicate(true)
	worker=Thread.new();worker.start(func():return Record.prepare(value))
func activate()->void:
	super.activate();values=recorded_mix.values.duplicate(true);apply_volumes()
	ended=recorded_mix.ended or float(recorded_mix.position)>=float(recorded_mix.frames)/44100.
	if ended:player.stop()
	else:player.play(float(recorded_mix.position))
func finished()->void:
	ended=true
func _process(_delta:float)->void:
	if worker!=null:
		if worker.is_alive():return
		prepared=worker.wait_to_finish();worker=null
		if cancelled or not valid_context() or Record.conflict(music) or music.phonograph.candidate_player!=self:stop();return
		if not prepared.get("ok",false):music.set_meta("candidate_record_error",str(prepared.get("reason","saved_source_unavailable")));stop();return
	if not active:
		if cancelled or not valid_context() or Record.conflict(music) or music.phonograph.candidate_player!=self:stop();return
		var old:Node=music.get_node_or_null("GameMusicPlayer")
		if old!=null and old!=self:
			old.stop()
			if not old.retired:return
			music.remove_child(old)
		name="GameMusicPlayer";music.phonograph.active=true
		activate()
	if not active:return
	if not valid_context() or Record.conflict(music) or not music.phonograph.active or music.phonograph.mix!=recorded_mix or player.stream!=prepared.stream:stop();return
	player.volume_linear=0. if music.muted else float(recorded_mix.master_gain)
	music.set_meta("candidate_record",{"source_id":recorded_mix.source_id,"bundle_schema":recorded_mix.bundle_schema,"signature":prepared.signature,"position":float(recorded_mix.frames)/44100. if ended else player.get_playback_position(),"values":values.duplicate(true),"ended":ended})
func release()->void:
	if music.phonograph.candidate_player==self:
		music.phonograph.candidate_player=null;music.phonograph.active=false;music.phonograph.mix={}
		if music.has_meta("candidate_record"):music.remove_meta("candidate_record")
	super.release()
