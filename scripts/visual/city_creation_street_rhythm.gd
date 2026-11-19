extends RefCounted
## End walls, inner bays and courtyard faces derive from real adjacent cells.
const Wall=preload("res://scripts/visual/city_creation_wall_material.gd")
static func lute_sign(renderer,wall:Node3D)->void:
 var iron:Material=renderer._material(Color("405950"));var maple:=Color("d6a25a")
 renderer._box(wall,Vector3(.09,.10,.85),Vector3(.82,1.60,.45),iron)
 var sign:=Node3D.new();sign.name="WorkshopLute";wall.add_child(sign);sign.position=Vector3(.82,1.02,.82);sign.rotation.z=-.20
 renderer._crown(sign,Vector3(0,-.12,0),Vector3(.24,.30,.08),Color("63412f"))
 renderer._crown(sign,Vector3(0,-.12,.05),Vector3(.214,.278,.06),maple)
 renderer._box(sign,Vector3(.075,.40,.08),Vector3(0,.22,.04),iron)
 renderer._box(sign,Vector3(.13,.12,.09),Vector3(0,.43,.04),renderer._material(maple))
 renderer._crown(sign,Vector3(0,-.04,.105),Vector3(.064,.067,.014),Color("493d34"))
 for offset:float in [-.018,0.,.018]:renderer._box(sign,Vector3(.006,.56,.008),Vector3(offset,.05,.121),renderer._material(Color("ecdaac")))
 renderer._box(wall,Vector3(.023,.15,.025),Vector3(.91,1.51,.82),iron)
static func atelier_banner(renderer,wall:Node3D)->void:
 var banner:=Node3D.new();banner.name="AtelierWeaving";wall.add_child(banner);banner.position=Vector3(-.65,.95,.16)
 var brass:Material=renderer._material(Color("b99755"));var cloth:=Color("954d60");var hem:=Color("dfbc78")
 renderer._box(banner,Vector3(.57,.045,.065),Vector3(0,.40,0),brass)
 for side:float in [-1.,1.]:
  renderer._box(banner,Vector3(.04,.05,.22),Vector3(side*.22,.40,-.08),brass)
  renderer._quad(banner,Vector3(0,.38,.01),Vector3(side*.23,.38,0),Vector3(side*.23,-.37,.045),Vector3(0,-.22,.065),cloth)
  renderer._quad(banner,Vector3(0,-.16,.068),Vector3(side*.23,-.31,.050),Vector3(side*.23,-.34,.050),Vector3(0,-.19,.068),hem)
 renderer._quad(banner,Vector3(0,.28,.04),Vector3(.15,.09,.048),Vector3(0,-.10,.070),Vector3(-.15,.09,.048),hem)
 renderer._quad(banner,Vector3(0,.20,.052),Vector3(.075,.09,.061),Vector3(0,-.025,.076),Vector3(-.075,.09,.061),Color("477674"))
static func entry_gable(renderer,wall:Node3D,palette:Array)->void:
 var roof:Material=renderer._material(palette[1]);var timber:Material=renderer._material(palette[2]);var fascia:Material=renderer._material(Color("decba8"))
 for side:float in [-1.,1.]:
  var pitch:float=-side*atan2(.26,.62)
  var panel:MeshInstance3D=renderer._box(wall,Vector3(.682,.065,.74),Vector3(side*.31,1.51,.41),roof);panel.rotation.z=pitch
  var verge:MeshInstance3D=renderer._box(wall,Vector3(.682,.072,.055),Vector3(side*.31,1.49,.777),fascia);verge.rotation.z=pitch
  var bracket:MeshInstance3D=renderer._box(wall,Vector3(.068,.07,.54),Vector3(side*.46,1.30,.33),timber);bracket.rotation.x=-.34
 renderer._box(wall,Vector3(1.10,.065,.065),Vector3(0,1.39,.72),timber)
 wall.set_meta("residential_entry_gable",true)
static func room(row:Dictionary)->bool:return not row.is_empty() and row.cell.kind=="room"
static func profile(context:RefCounted,house:Dictionary,cell:Dictionary,direction:Vector2i)->Dictionary:
 var tangent:=Vector2i(direction.y,-direction.x)
 var left:bool=room(context.neighbor(house,cell,-tangent));var right:bool=room(context.neighbor(house,cell,tangent))
 var back:bool=room(context.neighbor(house,cell,-direction))
 var front:Dictionary=context.neighbor(house,cell,direction)
 var court:bool=not front.is_empty() and front.cell.kind=="terrace"
 var top:bool=not room(context.neighbor(house,cell,Vector2i.ZERO,1))
 return {"left":left,"right":right,"back":back,"top":top,"court":court,"kind":"courtyard" if court else "gable_end" if back and not left and not right else "inner_row" if left and right else "row_end" if left or right else "detached"}
static func opening(renderer,house:Dictionary,cell:Dictionary,wall:Node3D)->Dictionary:
 var outward:=Vector2i(roundi(wall.basis.z.x),roundi(wall.basis.z.z))
 var view:=profile(renderer.building_context,house,cell,outward)
 view.positions=[0.] if view.kind=="gable_end" else [-.43,.43]
 view.radius=.24 if view.kind=="gable_end" else .17 if view.kind=="inner_row" else .19
 return view
static func timber_windows(view:Dictionary,level:int)->Array:
 var openings:Array[Vector2]=[]
 var bottom:=.71 if level==0 else .62
 var top:=1.31
 match view.kind:
  "gable_end":
   openings=[Vector2(0.,.23)];top=1.37
  "inner_row":openings=[Vector2(-.43,.16),Vector2(.43,.16)]
  "row_end":openings=[Vector2(-.43,.19 if not view.left else .15),Vector2(.43,.19 if not view.right else .15)]
  "courtyard":
   openings=[Vector2(0.,.28)];bottom=.65;top=1.20
 var holes:Array=[]
 for opening_size:Vector2 in openings:
  holes.append({"x":opening_size.x,"radius":opening_size.y,"bottom":bottom,"spring":top,"arched":false})
 return holes
static func decorate(renderer,job,frame,wall:Node3D,direction:Vector2i,width:float)->void:
 if job.house.has("signature") or width<1.79 or not frame.retreats.is_empty():return
 var view:=profile(renderer.building_context,job.house,frame.cell,direction)
 var node:=Node3D.new();node.name="StreetRhythm_"+str(view.kind);node.set_meta("street_rhythm",view);node.set_meta("era",job.era);wall.add_child(node)
 var kind:int=Wall.Kind.CANTILEVER if job.era=="modern_eco" else Wall.Kind.STONE
 var color:Color=job.palette[2].lerp(Color("94724e"),.35) if job.era=="modern_eco" else job.palette[0].lerp(Color("d9c7a2"),.55)
 var key:="rhythm/"+str(kind)+"/"+color.to_html()
 if not renderer.materials.has(key):renderer.materials[key]=Wall.source(color,null,"component",kind)
 var material:Material=renderer.materials[key]
 # Shallow terminal details stay on the existing facade; entrances are untouched.
 for index in range(2):
  if view.left if index==0 else view.right:continue
  var x:float=-.83 if index==0 else .83
  if job.era=="modern_eco":
   var brace:MeshInstance3D=renderer._box(node,Vector3(.055,.35,.07),Vector3(x*.80,1.34,.16),material);brace.rotation.z=.65 if index==0 else -.65;brace.name="TerminalTimberBrace"
  elif job.era=="clockwork":
   renderer._box(node,Vector3(.08,1.4,.07),Vector3(x,.83,.14),material).name="EndBrickPier"
   for y:float in [.35,.85,1.35]:renderer._box(node,Vector3(.12,.035,.10),Vector3(x,y,.15),material).name="IronCourseTie"
  else:
   for band in range(4 if job.era=="renaissance" else 3):
    renderer._box(node,Vector3(.12,.22,.085),Vector3(x,.35+band*.32,.13),material).name="TerminalStoneQuoin"
 if view.top and view.kind in ["gable_end","row_end"]:
  renderer._box(node,Vector3(width-.12,.065,.12),Vector3(0,1.49,.17),material).name="TerminalCorniceReturn"
 if view.court:
  renderer._box(node,Vector3(width-.25,.06,.12),Vector3(0,1.49 if job.house.get("architecture","")=="recessed_townhouse" else 1.30,.17),material).name="CourtyardLintel"
