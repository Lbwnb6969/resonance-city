extends SceneTree
const Evidence=preload("res://tools/fixtures/city_creation_stream_evidence.gd")
const Transition=preload("res://scripts/audio/city_creation_stream_transition.gd")
class Owner extends Node:
	var _players:Dictionary={}
	var _variation_streams:Dictionary={}
	var _harmony_streams:Dictionary={}
	var _original_streams:Dictionary={}
	var at:=5.8
	func _playback_clock()->float:return at
var checks:=0
var failures:Array[String]=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func wave(value:int)->AudioStreamWAV:
	var data:=PackedByteArray();data.resize(Transition.FRAMES*2)
	for i in range(Transition.FRAMES):data.encode_s16(i*2,value)
	var result:=AudioStreamWAV.new();result.format=AudioStreamWAV.FORMAT_16_BITS;result.mix_rate=Transition.RATE;result.data=data;result.loop_mode=AudioStreamWAV.LOOP_FORWARD;result.loop_end=Transition.FRAMES
	return result
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(out)
	var owner:=Owner.new();root.add_child(owner)
	var transition:=Transition.new();transition.name="StreamTransition";owner.add_child(transition);transition.set_process(false)
	var old:=wave(3277);var target:=wave(6554);var mixed:AudioStreamWAV=transition.render({"old":old,"target":target,"boundary":6.})
	var player:=AudioStreamPlayer.new();owner.add_child(player);player.stream=mixed;player.play(5.8)
	owner._players.renaissance_fugue=player;owner._variation_streams["renaissance_fugue/0"]=target
	var row:={"stream":mixed,"old":old,"old_id":"renaissance_fugue/1","target":target,"id":"renaissance_fugue/0","boundary":6.,"local_boundary":6.,"until":6.15}
	transition.moving.renaissance_fugue=row
	var traces:Array=[]
	for at:float in [5.8,6.075,6.3]:
		owner.at=at;var result:=Evidence.capture(owner,"renaissance_fugue","renaissance_fugue/0");traces.append(result)
		check(result.qualified and result.kind=="premixed" and result.pcm.ok,"owned premix proves actual old, blended and target PCM at "+str(at))
	check(traces.map(func(value:Dictionary):return value.stage)==["old","blend","target"],"sounding side is derived from the real boundary rather than early target metadata")
	owner.at=5.8;row.old_id="0/chamber_counter_renaissance"
	check(not Evidence.capture(owner,"renaissance_fugue","renaissance_fugue/0").qualified,"a queued melody cannot disguise a still-sounding counter")
	row.old_id="wood/1"
	check(not Evidence.capture(owner,"renaissance_fugue","renaissance_fugue/0").qualified,"a different era cannot pass as the current era before the handover")
	owner.at=6.3;check(Evidence.capture(owner,"renaissance_fugue","renaissance_fugue/0").qualified,"after the checked fade the actual target PCM establishes the current melody")
	row.old_id="renaissance_fugue/1";var bytes:PackedByteArray=mixed.data;bytes.encode_s16((Transition.RATE*6+roundi(Transition.FADE*Transition.RATE)+64)*2,30000);mixed.data=bytes
	check(not Evidence.capture(owner,"renaissance_fugue","renaissance_fugue/0").qualified,"matching IDs and ownership cannot hide corrupted mixed PCM")
	player.stream=target;player.play();check(Evidence.capture(owner,"renaissance_fugue","renaissance_fugue/0").kind=="stable","completed transition returns to exact bank ownership")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"traces":traces}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("STREAM_EVIDENCE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures}))
	transition.moving.clear();owner.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
