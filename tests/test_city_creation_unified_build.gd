extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Build=preload("res://scripts/ui/city_creation_unified_build.gd")
var checks:=0
var failures:Array=[]
var out:=""
func check(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 var city=State.new();city.initialize_free()
 check(city.add_house(Vector2(-25,-20)).ok,"fixture house")
 var house:Dictionary=city.houses[0];var id:String=house.id;var cid:String=house.cells[0].id
 var before=city.snapshot()
 var row=Build.resolve(city,{},Vector2(-23.15,-20))
 check(row.has("cell") and row.house_id==id and row.cell.x==1 and row.cell.kind=="room" and row.valid,"ground automatically attaches instead of creating another house")
 check(city.snapshot()==before,"preview preserves full world")
 row=Build.resolve(city,{},Vector2(-23.15,-20),true)
 check(row.has("new_house"),"Alt bypasses ground attachment")
 row=Build.resolve(city,{"house_id":id,"cell_id":cid,"normal":Vector3.UP},Vector2.ZERO)
 check(row.cell.level==1 and row.cell.kind=="room" and row.valid,"roof adds a room with no extra mode")
 check(city.add_cells(id,[row.cell]).ok,"roof room commits")
 house=city.houses[0];cid=house.cells[-1].id
 row=Build.resolve(city,{"house_id":id,"cell_id":cid,"normal":Vector3.FORWARD},Vector2.ZERO)
 check(row.cell.level==1 and row.cell.kind=="terrace" and row.valid,"unsupported second-floor side automatically becomes supported neighbour terrace")
 before=city.snapshot();var depth:int=city._undo.size()
 check(city.add_cells(id,[row.cell]).ok and city._undo.size()==depth+1,"terrace uses one exact brush transaction")
 var built=city.houses.duplicate(true);check(city.undo().ok and city.houses==before.houses,"Undo removes complete automatic terrace")
 check(city.redo().ok and city.houses==built,"Redo restores exact terrace identity")
 check(city.add_cell(id,1,0,0).ok,"ground under prospective upper extension")
 row=Build.resolve(city,{"house_id":id,"cell_id":cid,"normal":Vector3.RIGHT},Vector2.ZERO)
 check(row.cell.kind=="room" and row.valid,"supported upper side stays a room")
 check(city.rotate_house(id,PI*.5).ok,"rotated fixture")
 # Query exact local neighbour after rotating, avoiding any world-axis snap.
 var h:Dictionary=city.houses[0];var at=Build.Frame.center(h,{"x":2,"z":0,"level":0,"kind":"room"})
 row=Build.resolve(city,{},at)
 check(row.has("cell") and row.cell.x==2 and row.valid,"rotated ground snap uses local house frame")
 row=Build.cell_candidate(city,city.houses[0],{"x":4,"z":0,"level":3,"kind":"room"})
 check(not row.valid and not row.reason.is_empty(),"unsupported upper neighbour retains actual invalid reason")
 row=Build.resolve(city,{},Vector2(100,100))
 check(not row.valid and row.has("new_house"),"outside parcel stays visibly invalid")
 var report={"ok":failures.is_empty(),"checks":checks,"failures":failures}
 FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report))
 print("UNIFIED_BUILD ",report);quit(0 if failures.is_empty() else 1)
