extends RefCounted
## Published door ports are authoritative; preview uses the same graph on a fork.
const Fork=preload("res://scripts/world/city_creation_chemistry_preview.gd")
const Network=preload("res://scripts/world/city_creation_network.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
static func capture(network:RefCounted)->Dictionary:
 var result:Dictionary={}
 for id:String in network.connected_houses:
  if network.selected_entrances.has(id):result[id]=network.selected_entrances[id].duplicate(true)
 return result
static func occupied_ports(network:RefCounted)->Dictionary:
 var ports:Dictionary={}
 for house_id:String in network.connected_houses:
  var port:String=network.connected_houses[house_id]
  ports[house_id]=[port,network.component_of[port]]
 return ports
static func merged_streets(before:Dictionary,network:RefCounted)->bool:
 var origins:Dictionary={}
 for house_id:String in before:
  if not network.connected_houses.has(house_id):continue
  var prior:Array=before[house_id];var current:String=network.component_of[network.connected_houses[house_id]]
  if network.component_of.get(prior[0])!=current:continue
  if origins.has(current) and origins[current]!=prior[1]:return true
  origins[current]=prior[1]
 return false
static func row(city:RefCounted,id:String,entry:Dictionary,connected:bool,preview:bool=false)->Dictionary:
 var h:Dictionary=Fork.house(city,id);var wall:Vector2=entry.wall_at;var normal:Vector2=Frame.normal(entry);var tangent:=Vector2(normal.y,-normal.x)
 var y:=float(entry.get("sill_y",h.get("base_y",0.)))+.10
 var center:=Vector3(wall.x,y,wall.y);var side:=Vector3(tangent.x,0,tangent.y)*.42
 var arch:Array[Vector3]=[center-side,center-side+Vector3.UP*.48,center+side+Vector3.UP*.48,center+side]
 var toward:Vector2=entry.at
 var link:Array[Vector3]=[center,Vector3(toward.x,city.street_height(toward)+.10,toward.y)]
 return {"kind":"road_connected" if connected else "road_unconnected","label":("预演 · 门前可接通" if connected else "预演 · 门前未接通") if preview else ("门前小路已接通" if connected else "门前小路已断开"),"valid":connected,"lines":[arch,link],"at":center+Vector3.UP*.75,"house_id":id,"entry":entry.duplicate(true)}
static func changes(city:RefCounted,before:Dictionary,after:Dictionary)->Array:
 var rows:Array=[]
 for id:String in after:
  if not before.has(id):rows.append(row(city,id,after[id],true))
 for id:String in before:
  if not after.has(id) and city._house_index(id)>=0:
   var entries:Array=city.house_entrances(id);var entry:Dictionary=before[id]
   if not entries.is_empty():
    var matches:Array=entries.filter(func(e):return e.cell_id==entry.cell_id and e.side==entry.side)
    entry=matches[0] if not matches.is_empty() else entries[0]
   rows.append(row(city,id,entry,false))
 return rows
static func preview(source:RefCounted,request:Dictionary)->Array:
 if request.points.size()<2:return []
 var city:=Fork.fork(source)
 # Only this detached city is edited. Reuse the actual authoring validation,
 # road merging, terrain policy and bridge flags instead of guessing by radius.
 var result:Dictionary=city.add_road(request.points,request.style,"none",request.width,request.candidate.get("decoration","none"))
 if not result.ok or result.get("no_op",false):return []
 preload("res://scripts/visual/city_creation_prepared_frontages.gd").prepare(city)
 var network:=Network.new();network.state=city;network.connected_houses=request.candidate.get("connected",{}).duplicate();network._build_graph()
 var current:=capture(network);var rows:Array=[]
 for house:Dictionary in city.houses:
  var id:=str(house.id);var nearest:Dictionary={};var distance:=2.5
  for entry:Dictionary in city.house_entrances(id):
   for end:Vector2 in [request.points[0],request.points[-1]]:
    var d:=end.distance_to(entry.wall_at)
    if d<distance:distance=d;nearest=entry
  if nearest.is_empty():continue
  var connected:=current.has(id)
  rows.append(row(city,id,current[id] if connected else nearest,connected,true))
 return rows
