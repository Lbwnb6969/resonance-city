extends "res://tools/check_creation_shape_palette_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
const Player=preload("res://scripts/audio/city_creation_game_music_player.gd")
const ROOT="res://数据/音乐资产/游戏音乐包/"
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
 var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
 var voices:Array=[]
 for voice:AudioStreamPlayer in demo.music._players.values():voices.append(voice.get_instance_id())
 for row:Array in [["2_05","9ad221e9f33c712a","renaissance",76.,8.5],["3_05","49e3e4277732f2aa","clockwork",67.,15.5]]:
  var city:=State.new();city.initialize_free();Brush.select(city,row[2]);check(city.add_house(Vector2(-25,-20)).ok,"real isolated era house "+row[0]);await show(city,Vector2(-25,-20),row[0]+"背景连续性");await settle();quiet()
  var before:Dictionary=demo.state.snapshot();var trial:=Trial.new();demo.add_child(trial);check(trial.install(demo) and trial.packs.size()==84,"current L retains84 candidates "+row[0])
  var prior:String=ROOT+"20261106_remaining_v2/"+row[1]+"/bundle.json";var revised:String=ROOT+"20261108_continuous_background_v2/"+row[0]+"/bundle.json"
  var original:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(prior));var updated:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(revised))
  check(updated.layers[2]==original.layers[2] and updated.frames==original.frames and updated.common_gain==original.common_gain,"same residual timeline gain "+row[0])
  check(not updated.runtime_ready and not updated.listening_approved and updated.layers[1].automatic_max<original.layers[1].automatic_max,"response cap reduced and no approval promoted "+row[0])
  for label:String in ["prior","revised"]:
   var node:Node
   if label=="prior":node=Player.request(demo.music,prior).node
   else:
    for i in range(trial.packs.size()):
     if trial.packs[i].manifest==revised:trial.picker.select(i)
    if not demo.ledger.visible():demo.ledger.open_panel()
    await create_timer(.3).timeout;demo.ledger.scroll.ensure_control_visible(trial.play_button);await process_frame;await ui_click(trial.play_button);node=trial.conductor
   check(await wait_for(func():return is_instance_valid(node) and node.active,30000),"real candidate active "+row[0]+label)
   if not is_instance_valid(node) or not node.active:quit(1);return
   await create_timer(.7).timeout
   check(node.values=={"background":1.,"body":0.,"detail":0.} and node.prepared.signature==FileAccess.get_sha256(prior if label=="prior" else revised),"signed source plays background alone "+row[0]+label)
   check(node.seek(row[3]),"synchronized source seek "+row[0]+label);await create_timer(.15).timeout
   var key:String=row[0]+"_"+label;facts[key]=await Probe.record(OUT+"/"+key+"_Master.wav",row[4]);check(facts[key].ok,"actual problem interval PCM unclipped "+key)
   check(node.values.body==0. and node.values.detail==0. and demo.state.snapshot()==before,"background-only and author snapshot maintained "+key)
   if label=="revised":
    check(node.sequence.rows.any(func(v):return v.manifest==revised) and not node.sequence.rows.any(func(v):return v.manifest==prior),"successor catalog replaces version once "+row[0])
    node.set_paused(true);var cursor:float=node.player.get_playback_position();await create_timer(.3).timeout;check(absf(node.player.get_playback_position()-cursor)<.06,"pause preserves position "+row[0]);node.set_paused(false)
    node.manual_expression=true;node.expression.craft=1.;await process_frame;await process_frame
    check(is_equal_approx(node.values.body,updated.layers[1].automatic_max) and node.values.detail==0.,"actual craft maximum uses reduced cap "+row[0]);await capture(row[0]+"_revised")
   node.stop();check(await wait_for(func():return demo.music.get_node_or_null("GameMusicPlayer")==null,30000),"lease released "+key)
  trial.status.get_parent().queue_free();trial.queue_free();await process_frame
 var after:Array=[]
 for voice:AudioStreamPlayer in demo.music._players.values():after.append(voice.get_instance_id())
 check(after==voices and demo.music._players.size()==12 and demo.music._effects.size()==4,"original voice pool unchanged")
 check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save bytes unchanged")
 var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts,"persistence":demo.persistence,"default_changed":false,"listening_approved":false}
 FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("BACKGROUND_CONTINUITY ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
