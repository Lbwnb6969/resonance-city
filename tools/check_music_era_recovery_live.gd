extends "res://tools/check_music_era_observation_live.gd"
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
 var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
 var town:=State.new();town.initialize_free();Brush.select(town,"pastoral");check(town.add_house(Fixture.ORIGIN).ok,"real pastoral context");Brush.select(town,"clockwork");var clock_at:=Vector2(12,18);check(town.add_house(clock_at).ok,"real separated clockwork context")
 await show(town,Fixture.ORIGIN,"无曲时代返回恢复");quiet();trial=Trial.new();demo.add_child(trial);check(trial.install(demo),"actual L catalog")
 var row:Dictionary={}
 for i in range(trial.packs.size()):
  if trial.packs[i].name.begins_with("1-01") and "remaining_v2" in trial.packs[i].manifest:trial.picker.select(i);row=trial.packs[i];break
 demo.ledger.open_panel();await create_timer(.3).timeout;await ui_click(trial.play_button);check(await wait_for(active,30000),"actual L action starts signed pastoral source")
 if not active():quit(1);return
 var node:Node=trial.conductor
 # Supported configure API with a signed one-era inventory, no fabricated WAV.
 node.sequence.configure(node,[row]);check(node.sequence.rows.size()==1,"one-era signed repertoire explicitly configured for missing-era path")
 check(await wait_for(func():return node.sequence.era_observation.established=="pastoral",2000),"actual focused pastoral era seeds")
 await key(KEY_ESCAPE);var original:Dictionary=demo.state.snapshot();focus_at(clock_at)
 check(await wait_for(func():return node.sequence.era_observation.established=="clockwork",9000),"real stable no-candidate era observed")
 check(node.player.playing and not node.sequence.breathing,"camera change never cuts current source")
 check(node.seek(float(node.prepared.manifest.frames)/44100.-.3),"seek only to test natural finished, not full-length listening")
 check(await wait_for(func():return node.sequence.failed=="no_era_candidate",5000),"natural finished keeps nature when established era has no candidate")
 await create_timer(3.2).timeout;check(node.sequence.breathing and node.sequence.worker==null and node.sequence.ready.is_empty() and not node.player.playing,"unchanged unavailable era stays idle without retries")
 focus_at(Fixture.ORIGIN);await create_timer(2.).timeout;check(node.sequence.failed=="no_era_candidate" and node.sequence.worker==null,"two-second return sweep cannot trigger source preparation")
 node.set_paused(true);var observed:float=node.sequence.era_observation.observed;await create_timer(.5).timeout;check(node.sequence.era_observation.observed==observed and node.sequence.failed=="no_era_candidate","pause freezes return observation and recovery");node.set_paused(false)
 var recording:=Span.start()
 var recovered:bool=await wait_for(func():return node.sequence.transitions.size()==1 and node.player.playing,10000)
 check(recovered,"stable return to available era resumes candidate without manual restart")
 if recovered:
  check(node.sequence.failed.is_empty() and node.prepared.manifest.source_id==row.source_id and node.prepared.manifest.schema=="city_sparse_music_v2","recovery uses signed same-protocol eligible source")
  check(node.sequence.transitions[0].breath_seconds>9.,"recovery records full nature/observation hold")
 await create_timer(2.).timeout;facts.pcm=Span.finish(recording,OUT+"/recovery_Master.wav")
 if recovered:check(facts.pcm.ok,"actual recovered source Master is non-silent and unclipped")
 facts.transitions=node.sequence.transitions.duplicate(true);facts.ending_seek_used=true;facts.repertoire_scope="One real signed pastoral row configured through supported Sequence API; full current trial catalog still covers four eras."
 check(demo.state.snapshot()==original and pool()==voices and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"camera/scheduling keep author city original voice pool and personal bytes")
 await capture("era_recovery")
 var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-began)/1000.,"persistence":demo.persistence,"default_changed":false,"listening_approved":false}
 FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ERA_RECOVERY ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
