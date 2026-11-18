extends Node
## Successful author transactions are visible on their still-published ground.
## These meshes have no collision and never enter author data or music facts.
const Changes=preload("res://scripts/world/city_creation_change_set.gd")
const Terrain=preload("res://scripts/world/city_creation_terrain.gd")
var demo:Node
var renderer:Node3D
var root:Node3D
var rows:Dictionary={}
var context:Array=[]
static func can_paint(owner:Node)->bool:
	var budget=owner.town.budget_rebuild
	return budget!=null and budget.published_ground!=null and budget._published_snapshot.get("planting_ground",[])==Changes.planting_ground(owner.state)
static func keep(owner:Node,result:Dictionary)->void:
	if not result.get("ok",false) or int(result.get("added_count",0))==0:return
	if not can_paint(owner):return
	activate(owner)
	owner.get_meta("pending_plants")._keep(result.plant_ids)
static func activate(owner:Node)->void:
	if not owner.has_meta("pending_plants"):
		var pending=load("res://scripts/visual/city_creation_pending_plants.gd").new()
		pending.demo=owner;pending.name="PendingPlants";pending.process_priority=100;owner.add_child(pending);owner.set_meta("pending_plants",pending)
func clear()->void:
	if is_instance_valid(root):
		if root.get_parent()!=null:root.get_parent().remove_child(root)
		root.queue_free()
	rows.clear();root=null;renderer=null;context=[]
func _keep(ids:Array)->void:
	var began:=Time.get_ticks_usec()
	var current:=[demo.state.get_instance_id(),demo.state._wish_epoch,demo.town.get_instance_id()]
	if context!=current:clear();context=current;renderer=demo.town
	if not is_instance_valid(root):
		root=Node3D.new();root.name="PendingPlantSurfaces";root.transform=renderer.vegetation_layer.transform;renderer.add_child(root)
	for plant:Dictionary in demo.state.plants:
		if str(plant.id) not in ids or rows.has(str(plant.id)):continue
		var at:=Vector2(plant.position[0],plant.position[1]);var scale_value:=clampf(float(plant.scale),.25,2.5);var seed_value:=int(plant.seed)
		var pose:=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_value).rotated(Vector3.UP,fmod(absf(float(seed_value%6283))/1000.,TAU)),Vector3(at.x,renderer.budget_rebuild.published_ground.height_at(at)-Terrain.BASE_HEIGHT,at.y))
		var node:=Node3D.new();node.name=str(plant.id);root.add_child(node)
		for piece:String in renderer.foliage.parts(str(plant.kind),posmod(seed_value,3)):
			var mesh:=MeshInstance3D.new();mesh.name=piece;mesh.mesh=renderer.foliage.parts(str(plant.kind),posmod(seed_value,3))[piece];mesh.material_override=renderer.foliage.material(piece);mesh.transform=pose;mesh.extra_cull_margin=.12;node.add_child(mesh)
		rows[str(plant.id)]={"plant":plant.duplicate(true),"node":node,"pose":pose}
	set_meta("keep_ms",(Time.get_ticks_usec()-began)/1000.)
func _process(_delta:float)->void:
	# Prepare one selected-species variant per frame before the pen is released.
	# The renderer shares this same cache; no alternative geometry is generated.
	if demo.tool==5 and not demo.gallery.busy:
		for variant:int in range(3):
			if not demo.town.foliage._parts.has("%s:%d"%[demo.vegetation_kind,variant]):
				demo.town.foliage.parts(demo.vegetation_kind,variant);break
	if rows.is_empty():return
	if context!=[demo.state.get_instance_id(),demo.state._wish_epoch,demo.town.get_instance_id()]:clear();return
	var published:Array=renderer.budget_rebuild._published_snapshot.get("plants",[])
	for id:String in rows.keys():
		if demo.state.plants.has(rows[id].plant) and not published.has(rows[id].plant):continue
		var node:Node=rows[id].node;node.get_parent().remove_child(node);node.queue_free();rows.erase(id)
	if rows.is_empty():clear();return
	root.visible=renderer.vegetation_layer.visible and can_paint(demo)
func _exit_tree()->void:clear()
