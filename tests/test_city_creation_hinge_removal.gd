extends SceneTree
const Fixture=preload("res://tools/fixtures/city_creation_hinge_removal_fixture.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func blocked(c:RefCounted,id:String,target:String,label:String)->void:
	var before:Dictionary=c.snapshot();var depth:int=c._undo.size();var redo:int=c._redo.size()
	check(not c.preview_remove_cell(id,target).ok,"preview refuses transformed collision "+label)
	check(not c.remove_cell(id,target).ok and c.snapshot()==before and c._undo.size()==depth and c._redo.size()==redo,"rejected removal preserves full author data and history "+label)
func _initialize()->void:
	if not OS.get_cmdline_user_args().has("--isolated-session"):quit(1);return
	var f:=Fixture.build();var c:RefCounted=f.city;check(f.ok,"genuine folded two-floor fixture")
	check(c.add_house(Vector2(-23,-20)).ok and not Frame.overlaps(c.houses[0],c.houses[1]),"neighbour legitimately fits folded wing")
	blocked(c,f.id,f.target,"unfolding into neighbour")
	var original:Array=c.houses.duplicate(true)
	check(c.remove_house(f.id).ok and c.houses.size()==1,"whole-house removal remains available")
	check(c.undo().ok and c.houses==original,"whole-house Undo restores original folded house")
	check(c.remove_house(str(c.houses[1].id)).ok,"remove blocking neighbour")
	var before:Array=c.houses.duplicate(true);var depth:int=c._undo.size()
	check(c.remove_cell(f.id,f.target).ok and c._undo.size()==depth+1 and is_zero_approx(Frame.Hinge.angle(c.houses[0])),"valid unfolding remains one removal transaction")
	var after:Array=c.houses.duplicate(true)
	check(c.undo().ok and c.houses==before,"Undo restores original fold and removed cell")
	check(c.redo().ok and c.houses==after,"Redo restores legal unfolded house")
	var cold:=Fixture.State.new();check(cold.restore(c.snapshot()).ok and cold.houses==c.houses,"cold restore preserves valid removal")
	f=Fixture.build();c=f.city
	var points:Array[Vector2]=[Vector2(-23.8,-21),Vector2(-22.2,-19)]
	check(c.add_road(points,"path","none").ok,"road legitimately fits folded wing")
	blocked(c,f.id,f.target,"unfolding across road")
	f=Fixture.build();c=f.city
	var pond:Array[Vector2]=[Vector2(-22.6,-19.4)]
	check(c.add_water(pond,1.2,"pond").ok,"water legitimately fits folded wing")
	blocked(c,f.id,f.target,"unfolding into water")
	f=Fixture.build();c=f.city
	var passage:Array[Vector2]=[Vector2(-23,-21),Vector2(-23,-18)]
	check(c.add_road(passage,"path","none").ok and c.remove_cell(f.id,f.target).ok,"legal automatic passage remains allowed when wing unfolds")
	f=Fixture.build();c=f.city
	check(c.add_cell(f.id,0,1,0).ok and is_zero_approx(Frame.Hinge.angle(c.houses[0])),"side room naturally suspends fold")
	var side:Dictionary=c.houses[0].cells[-1]
	check(c.add_house(Frame.center(f.city.houses[0],{"x":5,"z":0})+Vector2(-.95,-3.8)).ok,"neighbour legitimately fits dormant wing")
	blocked(c,f.id,str(side.id),"reactivating fold into neighbour")
	var legacy:=Fixture.State.new();legacy.initialize_free();legacy.add_house(Vector2(-25,-20));legacy.add_cell("h1",-1,0,0);legacy.add_cell("h1",1,0,0);Fixture.Hinge.set_angle(legacy,"h1",28.)
	var snapshot:Dictionary=legacy.snapshot();snapshot.houses[0].erase("bend_axis")
	check(legacy.restore(snapshot).ok,"existing optional-axis snapshot remains compatible")
	check(legacy.add_house(Vector2(-26.8,-17.8)).ok,"neighbour legitimately fits original implicit axis")
	var right:Dictionary=legacy.houses[0].cells.filter(func(t):return t.x==1)[0]
	blocked(legacy,"h1",str(right.id),"same-angle implicit axis change")
	var ordinary:=Fixture.State.new();ordinary.initialize_free();ordinary.add_house(Vector2(-25,-20));ordinary.add_cell("h1",0,0,1)
	check(ordinary.remove_cell("h1",str(ordinary.houses[0].cells[-1].id)).ok,"ordinary upper removal retains existing behaviour")
	print("HINGE_REMOVAL ",JSON.stringify({"ok":failures.is_empty(),"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
