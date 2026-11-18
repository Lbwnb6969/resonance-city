extends RefCounted
## City policy3: depth-scaled cut shoulders; one envelope instead of repeated cuts.
const VERSION:=3
const SCHEMA:=47
static func protect(city:RefCounted,rows:Array)->Array:
 if city.terrain_policy!=VERSION:return rows
 for row:Dictionary in rows:
  if not row.get("cut_only",false):continue
  var side:Vector2=Vector2(row.b-row.a).normalized().orthogonal()
  var high:float=row.target_y
  for at:Vector2 in [row.a,Vector2(row.a).lerp(row.b,.5),row.b]:
   for sign_value:float in [-1.,1.]:high=maxf(high,city.raw_terrain_height(at+side*(float(row.radius)+.65)*sign_value))
  row.transition=maxf(.65,(high-float(row.target_y))*1.5)
  row.natural_cut=true
 return rows
static func height(at:Vector2,base:float,rows:Array,influence:Callable)->float:
 var hard:=0.
 for row:Dictionary in rows:
  if not row.get("cut_only",false) and float(row.get("priority",1.))>=3.:hard=maxf(hard,float(influence.call(at,row)))
 var result:=base
 for row:Dictionary in rows:
  if not row.get("natural_cut",false):continue
  var weight:float=float(influence.call(at,row))*(1.-hard)
  result=minf(result,lerpf(base,minf(base,float(row.target_y)),weight))
 return result
