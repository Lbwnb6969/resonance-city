extends "res://tools/check_game_music_live.gd"
const Trial=preload("res://scripts/ui/city_creation_music_trial.gd")
const Record=preload("res://scripts/audio/city_creation_candidate_record.gd")
const Phono=preload("res://scripts/audio/city_creation_phonograph.gd")
var trial:Node
func active()->bool:return is_instance_valid(trial.conductor) and trial.conductor.active
func replay_active()->bool:return demo.music.phonograph.active and demo.music.phonograph.candidate_player!=null and demo.music.phonograph.candidate_player.active
func canonical(value:Variant)->String:return JSON.stringify(JSON.parse_string(JSON.stringify(value)),"",true,true)
func click_replay(id:String)->void:
	demo.gallery.open_panel();await process_frame;await process_frame
	var button:Control=demo.gallery.panel.preview_buttons[id];demo.gallery.panel.scroll.ensure_control_visible(button);await process_frame;await ui_click(button)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=60;var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	trial=Trial.new();demo.add_child(trial);check(trial.install(demo),"actual current L trial installs")
	for i in range(trial.packs.size()):
		if trial.packs[i].name.begins_with("1-04") and "remaining_v2" in trial.packs[i].manifest:trial.picker.select(i);break
	demo.ledger.open_panel();await create_timer(.4).timeout;await ui_click(trial.play_button);check(await wait_for(active,30000),"actual L action starts layered sparse source")
	if not active():quit(1);return
	var node:Node=trial.conductor;node.set_expression(1.,0.);await create_timer(1.).timeout;check(node.seek(37.25),"one cursor addresses all actual source layers");await process_frame;node.set_paused(true);demo.music.set_muted(true);await process_frame
	var original:=var_to_bytes(demo.state.snapshot());var source:String=node.prepared.manifest.source_id;var gains:Dictionary=node.values.duplicate(true);var old_id:=node.get_instance_id()
	var saved:Dictionary=await demo.gallery._capture("稀疏曲目定格","manual");check(saved.ok,"real viewport collection captures muted paused source")
	var read:Dictionary=demo.gallery.library.read(saved.id) if saved.ok else {};check(read.get("ok",false) and read.phonograph_mix.version==2,"actual immutable collection cold reads candidate format")
	if not read.get("ok",false):quit(1);return
	var mix:Dictionary=read.phonograph_mix
	check(mix.source_id==source and mix.bundle_schema=="city_sparse_music_v2" and mix.manifest_sha256==node.prepared.signature and absf(mix.position-37.25)<.15,"source, sparse protocol, signed manifest and actual cursor survive disk")
	check(canonical(mix.values)==canonical(gains) and mix.master_gain==.8 and mix.values.body>.24 and mix.values.motion>.09 and mix.values.detail==0.,"muted save retains frozen positive gains and exact silent residual")
	demo.music.set_muted(false)
	var missing:=mix.duplicate(true);missing.manifest="res://数据/音乐资产/游戏音乐包/missing/bundle.json"
	check(not Record.begin(demo.music,missing).ok and is_instance_valid(node) and node.active and node.get_instance_id()==old_id,"missing source admission leaves current paused audition intact")
	var wrong:=mix.duplicate(true);wrong.source_id="0".repeat(64);check(Record.begin(demo.music,wrong).ok,"identity failure checked in background before takeover")
	check(await wait_for(func():return demo.music.phonograph.candidate_player==null,30000) and is_instance_valid(node) and node.active and node.get_instance_id()==old_id,"background identity refusal preserves prior actual player")
	if demo.music.has_meta("candidate_record_error"):demo.music.remove_meta("candidate_record_error")
	check(Record.begin(demo.music,mix).ok,"actual asynchronous replay request accepted");var cancelled:Node=demo.music.phonograph.candidate_player;var cancelled_id:=cancelled.get_instance_id();demo.music.phonograph.stop(demo.music)
	check(await wait_for(func():return not is_instance_id_valid(cancelled_id),30000) and is_instance_valid(node) and node.active and not demo.music.phonograph.active,"cancelled real preparation cannot take original audition lease")
	var recording:=Span.start();await click_replay(saved.id);check(await wait_for(replay_active,30000),"real gallery replay button prepares and adopts saved source")
	if not replay_active():quit(1);return
	var replay:Node=demo.music.phonograph.candidate_player;check(not is_instance_id_valid(old_id) and replay.player==demo.music._players.foundation,"successful replay alone retires old audition and reuses original pooled player")
	check(replay.prepared.manifest.source_id==mix.source_id and replay.prepared.signature==mix.manifest_sha256 and canonical(replay.values)==canonical(mix.values),"replay actual stream and frozen layers match immutable record")
	check(absf(replay.player.get_playback_position()-mix.position)<1.5 and not replay.sequence.enabled,"replay resumes saved complete-song cursor without automatic successor queue")
	await create_timer(1.5).timeout;check(canonical(replay.values)==canonical(mix.values) and replay.spatial_facts.is_empty(),"empty-city geometry cannot revoice frozen recorded mix")
	demo.gallery.tick_preview();check(absf(demo.gallery.panel.playback_progress.max_value-float(mix.frames)/44100.)<.001 and "同源混音" in demo.gallery.panel.playback_title.text,"actual gallery uses full source duration and honest candidate title")
	await capture("candidate_replay");demo.music.set_muted(true);await process_frame;await process_frame;check(replay.player.volume_linear==0.,"global mute applies during recorded replay");demo.music.set_muted(false)
	await create_timer(.5).timeout;facts.pcm=Span.finish(recording,OUT+"/candidate_replay_Master.wav");check(facts.pcm.ok,"actual frozen same-source replay PCM non-silent and unclipped")
	replay.player.play(float(mix.frames)/44100.-.5);check(await wait_for(func():return replay.ended,4000),"recorded source naturally finishes without queueing another song")
	check(not replay.player.playing and demo.music.phonograph.active and replay.sequence.transitions.is_empty(),"record end remains silent and owns no automatic fallback")
	await ui_click(demo.gallery.panel.stop_button);await process_frame;check(not demo.music.phonograph.active and demo.music.phonograph.candidate_player==null and not demo.music.has_meta("candidate_record"),"real stop button releases candidate record owner")
	var stopped:=true
	for player:AudioStreamPlayer in demo.music._players.values():stopped=stopped and not player.playing
	check(stopped,"free-city release cannot resurrect old synthetic long music")
	# Ended snapshots preserve a genuine nature-only end rather than a zero cursor restart.
	var ended:=mix.duplicate(true);ended.position=float(mix.frames)/44100.;ended.ended=true;check(Record.begin(demo.music,ended).ok and await wait_for(replay_active,30000),"saved ended snapshot can be reopened")
	check(demo.music.phonograph.candidate_player.ended and not demo.music.phonograph.candidate_player.player.playing,"ended replay does not restart from zero");demo.music.phonograph.stop(demo.music);await process_frame;await process_frame
	check(Record.begin(demo.music,mix).ok,"fresh pending replay for city-switch cancellation");var pending_id:int=demo.music.phonograph.candidate_player.get_instance_id();var other:=State.new();other.initialize_free();await show(other,Vector2.ZERO,"换城撤回收藏准备");quiet()
	check(await wait_for(func():return not is_instance_id_valid(pending_id),30000) and not demo.music.phonograph.active,"real city replacement cancels pending recorded source")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save bytes unchanged");check(pool()==voices,"12 long / 4 short / 6 buses player identities preserved");check(var_to_bytes(read.world)==var_to_bytes(demo.gallery.library.read(saved.id).world),"stored author snapshot remains immutable")
	facts.saved_id=saved.id;facts.mix=mix;facts.author_before=original.hex_encode().sha256_text();facts.saved_file_sha256=FileAccess.get_sha256(saved.path);facts.ending_seek_used=true
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"facts":facts,"default_changed":false,"listening_approved":false};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("CANDIDATE_RECORD_LIVE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
