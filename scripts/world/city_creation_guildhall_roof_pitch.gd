extends RefCounted
## Authored Renaissance hall: related roof gains preserve its three-tier silhouette.
const Plan=preload("res://scripts/world/city_creation_neoclassical_civic_plan.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const P=preload("res://scripts/world/city_creation_roof_primitives.gd")
const A=preload("res://scripts/visual/city_creation_architecture.gd")
const Cut=preload("res://scripts/world/city_creation_basilica_roof_pitch.gd")
const ID:="guildhall"
static func authored(h:Dictionary)->bool:return h.get("architecture","")==ID and h.get("roof_pitch",{}).get("version")==11 and h.roof_pitch.get("profile")==ID
static func supported(city,h:Dictionary)->bool:return h.get("architecture","")==ID and city.house_era(h)=="renaissance" and is_zero_approx(Frame.Hinge.angle(h)) and not Plan.guild(city,h).is_empty()
static func active(city,h:Dictionary)->bool:return authored(h) and supported(city,h)
static func source_angle(city,h:Dictionary)->float:
 var plan:=Plan.guild(city,h)
 return rad_to_deg(atan(.4/((minf(1.65,float(plan.span)*.55)+.22)*.5))) if not plan.is_empty() else 0.
static func _gable(parts:Array,name:String,half:float,x:float,bottom:float,eave:float,rise:float,z:float,thickness:float)->void:
 if eave+rise<=bottom+.000001:return
 var polygon:=PackedVector2Array([Vector2(x-half,bottom),Vector2(x+half,bottom),Vector2(x,eave+rise)]) if is_equal_approx(bottom,eave) else PackedVector2Array([Vector2(x-half,bottom),Vector2(x+half,bottom),Vector2(x+half,eave),Vector2(x,eave+rise),Vector2(x-half,eave)])
 var points:Array[Vector3]=[]
 for point:Vector3 in A._extrude(polygon,thickness):points.append(point+Vector3(0,0,z))
 P.face(parts,name,points,"stone")
static func _roof(parts:Array,name:String,width:float,depth:float,eave:float,rise:float,x:float,z:float,bottom:float)->void:
 var start:=parts.size();var half:=width*.5
 for side:float in [-1.,1.]:
  P.prism(parts,name,[Vector3(x+side*half,eave,z-depth*.5),Vector3(x+side*half,eave,z+depth*.5),Vector3(x,eave+rise,z+depth*.5),Vector3(x,eave+rise,z-depth*.5)],"tile")
 for index in range(start,parts.size()):
  var uv:=PackedVector2Array()
  for point:Vector3 in parts[index].vertices:uv.append(Vector2(point.z/.22,signf(point.x-x)*Vector2(point.x-x,point.y-eave-rise).length()/.28))
  parts[index].uv=uv
 for end:float in [-1.,1.]:_gable(parts,name+"End",half,x,bottom,eave-.046,rise,z+end*(depth*.5-.07),.12)
static func for_house(city,h:Dictionary)->Dictionary:
 var result:={"plan":{},"patches":[],"apex":Vector3.ZERO,"records":[]}
 if not active(city,h):return result
 var plan:=Plan.guild(city,h);result.plan=plan
 var span:float=plan.span;var middle:=minf(1.65,span*.55);var wing:float=(span-middle)*.5;var half:float=(middle+.22)*.5
 var main_rise:=half*tan(deg_to_rad(float(h.roof_pitch.degrees)));var gain:=main_rise/.4;var parts:Array=[]
 _roof(parts,"GuildPitchNaveTileRoof",middle+.22,2.08,.556,main_rise,0.,0.,.510)
 # The old solid .54m nave stays. Only its two end infills bridge to the new cover.
 var slope:=tan(deg_to_rad(float(h.roof_pitch.degrees)))
 for side:float in [-1.,1.]:
  if .11*slope>.001:
   var outer:=side*middle*.5;var inner:=side*(middle*.5-.10)
   Cut._closed_band(parts,"GuildPitchNaveSideWall",[Vector3(outer,.511,-.90),Vector3(outer,.511,.90),Vector3(inner,.511,.90),Vector3(inner,.511,-.90)],[.511+.11*slope,.511+.11*slope,.511+.21*slope,.511+.21*slope])
 for z:float in [-.90,.90]:_gable(parts,"GuildPitchNaveWall",middle*.5,0.,.510,.510+.11*tan(deg_to_rad(float(h.roof_pitch.degrees))),main_rise-.11*tan(deg_to_rad(float(h.roof_pitch.degrees))),z,.12)
 for side:float in [-1.,1.]:
  _roof(parts,"GuildPitchWingTileRoof",wing+.14,2.03,.106,.28*gain,side*(middle+wing)*.5,0.,.060)
  var outer:=side*span*.5;var inner:=side*(span*.5-.10);var wing_slope:=.28*gain/((wing+.14)*.5)
  Cut._closed_band(parts,"GuildPitchWingSideWall",[Vector3(outer,.001,-.90),Vector3(outer,.001,.90),Vector3(inner,.001,.90),Vector3(inner,.001,-.90)],[.061+.07*wing_slope,.061+.07*wing_slope,.061+.17*wing_slope,.061+.17*wing_slope])
 # Original front base -1.70 and Y scale 1.42 are baked only into the new cover.
 _roof(parts,"GuildPitchPorchTileRoof",1.60,.63,.3482,.3976*gain,0.,1.365,.3022)
 var pose:=Transform3D(Basis(Vector3.UP,float(plan.yaw)),Vector3(plan.center.x,plan.y,plan.center.y));result.pose=pose
 var high:=-INF;var low:=Vector2(INF,INF);var top:=Vector2(-INF,-INF)
 for cell:Dictionary in h.cells:
  var at:=Frame.origin(h)+Vector2(cell.x,cell.z)*1.8;low=low.min(at-Vector2.ONE*.9);top=top.max(at+Vector2.ONE*.9)
 var source:Array=[]
 for part:Dictionary in parts:
  var row:Dictionary=part.duplicate(true);row.vertices=[]
  for point:Vector3 in part.vertices:row.vertices.append(pose*point)
  source.append(row)
 for cell:Dictionary in h.cells:
  var at:=Frame.origin(h)+Vector2(cell.x,cell.z)*1.8;var a:=at-Vector2.ONE*.9;var b:=at+Vector2.ONE*.9
  for axis in range(2):
   if is_equal_approx(a[axis],low[axis]):a[axis]-=2.
   if is_equal_approx(b[axis],top[axis]):b[axis]+=2.
  for original:Dictionary in source:
   var part:=Cut._cut(original,Rect2(a,b-a))
   if part.vertices.is_empty():continue
   var bottom:=INF
   for point:Vector3 in part.vertices:bottom=minf(bottom,point.y)
   var patch:={"surface":"roof","base_y":bottom,"vertices":part.vertices,"uv":part.uv,"cell_id":str(cell.id),"part":part.name,"roof_skin":part.roof_skin,"material":part.material}
   result.patches.append(patch)
   if part.roof_skin:
    for i in range(0,part.vertices.size(),3):
     var center:Vector3=(part.vertices[i]+part.vertices[i+1]+part.vertices[i+2])/3.
     if center.y>high:high=center.y;result.apex=center
 return result
