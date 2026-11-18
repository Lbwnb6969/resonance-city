extends Node
## One value-only background candidate; scene resources install on the owner thread.
const Fork=preload("res://scripts/world/city_creation_chemistry_preview.gd")
const Bed=preload("res://scripts/visual/city_creation_shore_road_bed.gd")
const Triangles=preload("res://scripts/visual/city_creation_road_triangle_data.gd")
var thread:Thread
var context:Node3D
var owner_renderer:Node3D
var pending:Dictionary={}
var active_key:Array=[]
var stats:Dictionary={"capture_ms":0.,"worker_ms":0.,"completed":0,"discarded":0,"max_finalize_ms":0.}
static func bed(renderer:Node3D,road:Dictionary,arrays:Array)->Dictionary:
 var data:Dictionary=Bed.prepare(renderer,road,arrays)
 return {"bed":data,"mesh":Triangles.prepare(data.faces),"road":road}
func request(renderer:Node3D,key:Array,points:Array[Vector2],width:float,style:String)->void:
 owner_renderer=renderer
 if key==active_key or pending.get("key")==key:return
 var began:=Time.get_ticks_usec()
 var requested:float=0. if is_equal_approx(width,renderer.state.RoadUpgrade.width_for(style)) else width
 var check:Dictionary=renderer.state.preview_road(points,style,"none",requested)
 if not check.ok:return
 var city:RefCounted=Fork.fork(renderer.state)
 for field:String in ["houses","roads","plants","waters","terrain_strokes","districts","creative_settings","placed_landmarks","plaza_loops","harmony_journey","era_modifiers"]:city.set(field,renderer.state.get(field).duplicate(true))
 city.revision+=1
 var encoded:Array=[]
 for at:Vector2 in points:encoded.append([at.x,at.y])
 var id:String=check.upgrade_road_id
 var road:Dictionary
 if id.is_empty():
  id="r%d"%maxi(renderer.state._next_road_id,int(renderer.state._high_watermark.road)+1)
  road={"id":id,"points":encoded,"width":width,"style":style,"bridge":check.bridge,"source":"player"};city.roads.append(road)
 else:
  for i:int in range(city.roads.size()):
   if city.roads[i].id!=id:continue
   road=city.roads[i].duplicate(true);road.width=width;road.style=style;road.bridge=check.bridge;city.roads[i]=road;break
 pending={"key":key.duplicate(true),"city":city,"road":road}
 stats.capture_ms=(Time.get_ticks_usec()-began)/1000.
 _start()
func _start()->void:
 if thread!=null or pending.is_empty():return
 if not _current(pending.key):pending.clear();return
 var row:Dictionary=pending;pending={};active_key=row.key
 context=owner_renderer.get_script().new();context.state=row.city;context.record_only=true
 thread=Thread.new();thread.start(_work.bind(context,row.road))
static func _work(view:Node3D,road:Dictionary)->Dictionary:
 var began:=Time.get_ticks_usec()
 view.state.prepare_ground_height();view.state.road_junctions();view._prepare_road_layout()
 var result:Dictionary=view._prepare_road_data(road,true)
 result.ms=(Time.get_ticks_usec()-began)/1000.;return result
func _current(key:Array)->bool:
 var city:RefCounted=owner_renderer.state
 return key.slice(0,3)==[city.get_instance_id(),city._wish_epoch,city.revision] and owner_renderer.preview.get_meta("shore_request",[])==key
func _process(_delta:float)->void:
 if thread!=null and not thread.is_alive():
  var began:=Time.get_ticks_usec()
  var result:Dictionary=thread.wait_to_finish();thread=null
  _dispose();context=null
  stats.worker_ms=result.ms;stats.completed+=1
  if _current(active_key):
   result.key=active_key;owner_renderer.set_meta("shore_road_preview",result)
   Bed.install(owner_renderer,owner_renderer.preview,result.bed,result.road,true,result.mesh)
   owner_renderer.preview.set_meta("shore_bed_signature",hash(result.bed))
  else:stats.discarded+=1
  stats.max_finalize_ms=maxf(stats.max_finalize_ms,(Time.get_ticks_usec()-began)/1000.)
  active_key=[]
 _start()
func _dispose()->void:
 var budget=owner_renderer.budget_rebuild
 if budget==null:budget=owner_renderer.BudgetRebuild.new()
 budget._dispose_context(context)
func _exit_tree()->void:
 pending.clear()
 if thread!=null:thread.wait_to_finish();thread=null
 if context!=null:_dispose();context=null
