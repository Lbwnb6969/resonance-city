extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
const Tower=preload("res://scripts/world/city_creation_round_tower_plan.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:
 if not OS.get_cmdline_user_args().has("--isolated-session"):quit(1);return
 var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20))
 var saved:Dictionary=city.snapshot();var depth:int=city._undo.size()
 for style:String in ["round_tower","timber"]:
  for era:String in city.Eras.IDS:
   for prototype:String in Brush.prototypes(era):
    var appearance:Dictionary={"style":style,"palette":2,"finish":{"roof":"slate"},"custom_colors":{"roof":"#47586b"}}
    city.set_meta("new_house_brush",{"era":"pastoral","prototype":"","appearance":appearance.duplicate(true)})
    check(Brush.select(city,era,prototype) and Brush.current(city).appearance.style=="classic","explicit silhouette replaces stale "+style+" "+era+"/"+prototype)
    var expected:Dictionary=appearance.duplicate(true);expected.style="classic"
    check(Brush.current(city).appearance==expected,"shape selection preserves finish and colors "+era+"/"+prototype)
 check(city.snapshot()==saved and city._undo.size()==depth,"browsing all silhouettes leaves author city/history unchanged")
 city.set_meta("new_house_brush",{"era":"pastoral","prototype":"","appearance":{"style":"round_tower","palette":2}})
 check(Brush.select(city,"modern_eco") and Brush.current(city).appearance.style=="round_tower","era-only selection preserves chosen basic shape")
 for choice:Array in [["modern_eco","chalet"],["clockwork","clock_turret"]]:
  city.set_meta("new_house_brush",{"era":"pastoral","prototype":"","appearance":{"style":"round_tower"}})
  Brush.select(city,choice[0],choice[1]);var built:Dictionary=city.add_house(Vector2(-16,-20));var h:Dictionary=city.houses[-1]
  check(built.ok and h.get("architecture")==choice[1] and Tower.for_house(h,city.houses,city.roads).is_empty(),"actual new house uses selected silhouette "+choice[1])
  var cold:=State.new();check(cold.restore(city.snapshot()).ok and cold.houses==city.houses,"cold restore preserves silhouette "+choice[1])
  check(city.undo().ok and city.houses==saved.houses,"one Undo removes complete shape "+choice[1])
  check(city.redo().ok and city.houses[-1]==h,"one Redo restores complete shape "+choice[1]);city.undo()
 print("BRUSH_SHAPE_SELECTION ",JSON.stringify({"ok":failures.is_empty(),"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
