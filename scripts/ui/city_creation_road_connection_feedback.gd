extends Node
const Plan=preload("res://scripts/world/city_creation_road_connection_feedback.gd")
const Ghost=preload("res://scripts/visual/city_creation_chemistry_ghost.gd")
var demo:Node3D
var known:Dictionary={}
var ports:Dictionary={}
var road_end:Variant=null
var epoch:Array=[]
var dirty:=false
var baseline:=true
var layer:Node3D
var age:=0.
var events:Array[Dictionary]=[]
var last_sound:Dictionary={}
func setup(owner:Node3D)->void:
 demo=owner;name="RoadConnectionFeedback";demo.add_child(self);demo.set_meta("road_connection_feedback",self)
 layer=Node3D.new();layer.name="DoorConnectionOutlines";demo.add_child(layer)
func clear()->void:
 for child:Node in layer.get_children():layer.remove_child(child);child.queue_free()
 age=0.
func mark(kind:String,connection_at:Variant=null)->void:
 road_end=connection_at if kind=="road" else null
 if kind=="history":baseline=true;clear()
 dirty=true
func play(at:Vector2)->bool:
 last_sound={}
 var music:Node=demo.music
 if music.muted or music._loading or music.concert_active or music.phonograph.active or not demo.ui_layer.visible or music.acoustic.point_weight(at)<=0.:return false
 var wave:AudioStreamWAV=music._edit_streams.get("road")
 if wave==null:return false
 for voice:AudioStreamPlayer in music._effects:
  if voice.playing:continue
  music.play_effect_at(voice,wave,at,.32)
  last_sound={"player_id":voice.get_instance_id(),"serial":voice.get_meta("creation_voice_serial",0),"stream_id":voice.stream.get_instance_id(),"unpitched":voice.stream.get_meta("unpitched_touch",false),"position":at}
  return true
 return false
func _process(delta:float)->void:
 var key:Array=[demo.state.get_instance_id(),demo.town.get_instance_id(),demo.state._wish_epoch]
 if key!=epoch:epoch=key;baseline=true;dirty=true;clear()
 layer.visible=demo.ui_layer.visible
 if age>0.:
  age-=delta
  if age<=0.:clear()
 if demo.gallery.busy or demo.edit_pending() or demo.life.budget_sync_pending():return
 if not dirty and not baseline:return
 var current:=Plan.capture(demo.life._network)
 var merged:bool=not baseline and road_end is Vector2 and Plan.merged_streets(ports,demo.life._network)
 var endpoint:Variant=road_end;road_end=null;ports=Plan.occupied_ports(demo.life._network)
 if baseline:known=current;baseline=false;dirty=false;return
 var rows:=Plan.changes(demo.state,known,current);known=current;dirty=false
 if rows.is_empty() and not merged:return
 clear()
 if not rows.is_empty():Ghost.build(layer,rows);age=1.35
 var successful:Array=rows.filter(func(r):return r.valid)
 successful.sort_custom(func(a,b):return demo.focus.distance_squared_to(a.at)<demo.focus.distance_squared_to(b.at))
 var sounded:=false
 if merged:sounded=play(endpoint)
 elif not successful.is_empty():var at:Vector3=successful[0].at;sounded=play(Vector2(at.x,at.z))
 events.append({"revision":demo.state.revision,"rows":rows.duplicate(true),"merged_streets":merged,"sounded":sounded,"audio":last_sound.duplicate() if sounded else {}})
 if events.size()>64:events.pop_front()
