extends "res://tools/check_creation_three_road_modes_live.gd"
const Fixture=preload("res://tests/test_city_creation_road_connection_feedback.gd")
var feedback:Node
func has_hint(valid:bool)->bool:return demo.chemistry_brush.rows.any(func(r):return r.kind==("road_connected" if valid else "road_unconnected"))
func prepare_city(city)->void:
 await show(city,Vector2(-25,-18),"真实门前接路反馈");demo.zoom=15.;demo.pitch=.9;demo.yaw=.2;demo._update_camera();await settle();quiet();demo.life.set_process(true);await wait_for(func():return not feedback.dirty and not feedback.baseline);demo.life.set_process(false)
func stroke(near:Vector2,commit:bool,start:=Vector2(-25,-14))->void:
 demo.select_tool(2);road_tool.set_mode(0);await motion(start);await button(start,true)
 for i in range(1,9):await motion(start.lerp(near,float(i)/8.))
 if commit:await button(near,false)
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();road_tool=demo.get_meta("road_tool");feedback=demo.get_meta("road_connection_feedback")
 await prepare_city(Fixture.fixture());var before:Dictionary=demo.state.snapshot();var event_count:int=feedback.events.size();var cue_count:int=demo.chemistry_brush.cue_count
 await stroke(Vector2(-25,-18.55),false)
 check(await wait_for(func():return has_hint(true),16000),"native held road receives exact detached door connectivity preview")
 check(demo.state.snapshot()==before and feedback.events.size()==event_count and demo.chemistry_brush.cue_count==cue_count,"held preview keeps all author data and never plays a success cue")
 facts.preview_rows=demo.chemistry_brush.rows.duplicate(true);facts.preview_worker_ms=demo.chemistry_brush.planner.stats.worker_ms;await capture("door_connection_preview")
 var recorder:=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
 await button(Vector2(-25,-18.55),false);check(demo.edit_pending() and feedback.events.size()==event_count,"release waits for real geometry and network publication before feedback")
 await settle();quiet();check(await wait_for(func():return feedback.events.size()==event_count+1,8000),"published real door emits one connection event")
 check(demo.life.house_connected("h1") and feedback.events[-1].rows.size()==1 and feedback.events[-1].rows[0].entry==demo.life.selected_entrances.h1,"success refers to same actual route entrance as residents")
 check(feedback.events[-1].sounded and not feedback.events[-1].audio.is_empty(),"published success plays one idle pooled short voice")
 var porches:Array=demo.town.house_roots.h1.find_children("*","Node3D",true,false).filter(func(part):return part.has_meta("residential_entry_gable"))
 check(porches.size()==1 and porches[0].get_meta("entrance")==demo.life.selected_entrances.h1 and porches[0].has_meta("door_lamp") and porches[0].has_meta("porch_steps"),"one residential gable marks the real served entrance with steps and lamp intact")
 var ids:Array=demo.music._effects.map(func(p):return p.get_instance_id());facts.short_voice_ids=ids;facts.connected_event=feedback.events[-1].duplicate(true)
 await capture("door_connection_published");await create_timer(.6).timeout;recorder.set_recording_active(false);var pcm:AudioStreamWAV=recorder.get_recording();check(pcm!=null and pcm.save_to_wav(OUT+"/connection_master.wav")==OK,"actual Master PCM saved during native road confirmation")
 for i in range(AudioServer.get_bus_effect_count(0)-1,-1,-1):
  if AudioServer.get_bus_effect(0,i)==recorder:AudioServer.remove_bus_effect(0,i)
 await create_timer(1.).timeout;check(feedback.events.size()==event_count+1 and feedback.layer.get_child_count()==0,"stable connection does not repeat and temporary outline expires")
 await key(KEY_Z,true);await settle();quiet();check(not demo.life.house_connected("h1") and feedback.events.size()==event_count+1,"native Undo updates disconnection without replaying confirmation")
 await key(KEY_Y,true);await settle();quiet();check(demo.life.house_connected("h1") and feedback.events.size()==event_count+1,"native Redo rebases silently")
 var road_id:String=demo.state.roads[0].id;demo._after_edit(demo.state.remove_road(road_id),"erase");await settle();quiet();check(await wait_for(func():return feedback.events.size()==event_count+2) and not feedback.events[-1].rows[0].valid and not feedback.events[-1].sounded,"real road removal gets quiet disconnection outline");await capture("door_connection_removed")
 demo.music.muted=true;demo._after_edit(demo.state.add_road([Vector2(-25,-14),Vector2(-25,-18.55)] as Array[Vector2],"cobble"),"road");await settle();quiet();check(await wait_for(func():return feedback.events.size()==event_count+3) and feedback.events[-1].rows[0].valid and not feedback.events[-1].sounded,"muted actual reconnection keeps visual and suppresses short sound");demo.music.muted=false
 await prepare_city(Fixture.fixture());event_count=feedback.events.size();check(feedback.layer.get_child_count()==0,"new city clears all old connection outlines")
 await stroke(Vector2(-24,-18.1),false);check(await wait_for(func():return not demo.chemistry_brush.rows.is_empty() and not demo.chemistry_brush.planner.busy(),16000),"near-door detached preview completes");facts.nearby_preview=demo.chemistry_brush.rows.duplicate(true);await capture("nearby_door_preview");await key(KEY_ESCAPE);await button(Vector2(-24,-18.1),false);check(demo.state.roads.is_empty() and feedback.events.size()==event_count,"cancelled nearby stroke never changes real connectivity")
 await stroke(Vector2(-25,-18.55),false);await wait_for(func():return demo.chemistry_brush.planner.busy() or has_hint(true),16000);await key(KEY_ESCAPE);await button(Vector2(-25,-18.55),false);await prepare_city(Fixture.fixture());check(feedback.events.size()==event_count and feedback.layer.get_child_count()==0 and not demo.town.preview.has_node("ChemistryGhost"),"stale preview cannot publish success to a replaced city")
 check(ids==demo.music._effects.map(func(p):return p.get_instance_id()) and ids.size()==4,"all road feedback reuses the existing four short slots")
 await stroke(Vector2(-22,-15),true,Vector2(-28,-15));await settle();quiet()
 check(await wait_for(func():return not demo.edit_pending() and not feedback.dirty and not demo.life.budget_sync_pending()) and not demo.state.roads.is_empty() and not demo.life.house_connected("h1") and feedback.events.size()==event_count,"committed parallel street leaves door disconnected with no confirmation")
 await key(KEY_Z,true);await settle();quiet()
 for attempt in range(2):
  await stroke(Vector2(-25,-18.55),true);await settle();quiet()
  check(await wait_for(func():return feedback.events.size()>event_count) and feedback.events.size()==event_count+1 and feedback.events[-1].sounded and demo.life.house_connected("h1"),"hand-drawn connection gives one confirmation on attempt "+str(attempt+1))
  event_count=feedback.events.size()
  if attempt==0:
   await key(KEY_Z,true);await settle();quiet()
   check(await wait_for(func():return not feedback.dirty and not feedback.baseline and not demo.edit_pending()) and not demo.life.house_connected("h1") and feedback.events.size()==event_count,"Undo rebases before a fresh hand-drawn connection")
 check(not demo.persistence and FileAccess.get_file_as_bytes(State.DEFAULT_PATH)==personal,"personal save remains exact and persistence is disabled")
 var streets:RefCounted=Fixture.fixture();streets.add_house(Vector2(-19,-20))
 for column:float in [-25.,-19.]:streets.add_road([Vector2(column,-18.55),Vector2(column,-14)] as Array[Vector2],"cobble","none")
 await prepare_city(streets);event_count=feedback.events.size()
 var original:Dictionary=feedback.ports.duplicate(true)
 check(original.size()==2 and original.h1[1]!=original.h2[1],"both doors already served on separate published networks")
 await stroke(Vector2(-19,-14),true,Vector2(-25,-14));await settle();quiet()
 var joined:bool=await wait_for(func():return feedback.events.size()>event_count)
 check(joined and feedback.events.size()==event_count+1 and feedback.events[-1].merged_streets and feedback.events[-1].rows.is_empty() and feedback.events[-1].sounded,"connecting occupied streets plays one confirmation without inventing a new door")
 if joined:facts.merged_event=feedback.events[-1].duplicate(true)
 event_count=feedback.events.size();await key(KEY_Z,true);await settle();quiet()
 check(await wait_for(func():return not feedback.dirty and not feedback.baseline and not demo.edit_pending()) and feedback.ports==original and feedback.events.size()==event_count,"undo separates the original occupied streets silently")
 facts.elapsed_seconds=(Time.get_ticks_msec()-began)/1000.;facts.source_sha256={}
 for path:String in ["scripts/world/city_creation_road_connection_feedback.gd","scripts/ui/city_creation_road_connection_feedback.gd","scripts/ui/city_creation_chemistry_worker.gd","scripts/ui/city_creation_chemistry_brush.gd","scripts/ui/city_creation_juice_feedback.gd"]:facts.source_sha256[path]=FileAccess.get_file_as_string("res://"+path).sha256_text()
 var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_CONNECTION_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
