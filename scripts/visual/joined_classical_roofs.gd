class_name JoinedClassicalRoofs
extends Node2D
## Visual-only roof unions for real, heard first-era buildings.
##
## A roof union is a derived presentation patch.  It never replaces a Sprite,
## a building ID, a pitch, a community, or a World object.  The input edges
## are the already-derived shared-wall candidates, then receive stricter road,
## water, courtyard and orientation checks here before a patch is published.
const Coupling = preload("res://scripts/world/world_coupling.gd")
const IsoProjection = preload("res://scripts/world/world_projection.gd")
const Frontage = preload("res://scripts/world/community_frontage.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")

const MAX_ROW := 6
const FACING := [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
# Exact surfaces in tools/build_refined_valley_art.py, not the manifest's
# generic roof_eave_y (which incorrectly labels a terrace as a pitched roof).
# tiled_roof: pitch along model x, ridge along z. Terrace has no roof ridge.
const ROOF_PROFILES := {
	"terrace":{"edge":0.575,"half_depth":0.515,"center_z":0.0,"eave":0.603,"rise":0.0,"ridge_x":0.0,"half_pitch":0.575,"thickness":0.072},
	"gabled":{"edge":0.60,"half_depth":0.55,"center_z":0.0,"eave":0.574,"rise":0.26,"ridge_x":0.0,"half_pitch":0.60,"thickness":0.014},
	"courtyard":{"edge":0.61,"half_depth":0.49,"center_z":0.0,"eave":0.552,"rise":0.115,"ridge_x":0.39,"half_pitch":0.22,"thickness":0.014},
	"commercial":{"edge":0.60,"half_depth":0.505,"center_z":-0.03,"eave":0.607,"rise":0.17,"ridge_x":0.0,"half_pitch":0.60,"thickness":0.014}}
const PALETTES := {
	"tile":[Color("b97859"),Color("8d5747"),Color("d39170")],
	"deep":[Color("597a83"),Color("3e5b66"),Color("79949a")],
	"warm":[Color("728a72"),Color("536c5d"),Color("92a089")]}

var view: Control
var rows: Array[Dictionary] = []
var patches: Array[RoofPatch] = []
var geometry_key: Array = []
var rebuild_count := 0

class RoofPatch extends Node2D:
	var row_ids: Array[String] = []
	var world_footprint := PackedVector2Array()
	var top_a := PackedVector2Array()
	var top_b := PackedVector2Array()
	var fascia_a := PackedVector2Array()
	var fascia_b := PackedVector2Array()
	var ridge := PackedVector2Array()
	var tile_lines: Array[PackedVector2Array] = []
	var surfaces: Array[Dictionary] = []
	var join_kind := ""
	var source_roles: Array[String] = []
	var seam_heights := Vector2.ZERO
	var actual_depth := 0.0
	var roof_color := Color("b87859")
	func _draw() -> void:
		for surface: Dictionary in surfaces:
			draw_colored_polygon(surface["polygon"],surface["color"])
			for detail: Dictionary in surface["details"]:
				draw_polyline(detail["line"],detail["color"],float(detail["width"]),true)

func _ready() -> void:
	y_sort_enabled = true

func setup(view_owner: Control) -> void:
	view = view_owner
	position = Vector2.ZERO
	scale = Vector2.ONE
	sync(view_owner)

func clear() -> void:
	for patch: RoofPatch in patches:
		if is_instance_valid(patch): patch.queue_free()
	patches.clear()
	rows.clear()
	geometry_key.clear()

func sync(view_owner: Control = null) -> void:
	if view_owner != null: view = view_owner
	if view == null or bool(view.get("black")) or view.get("shown_world") == null:
		visible = false
		clear()
		return
	visible = true
	var city: RefCounted = view.shown_world
	var frame := _audible_frame()
	var heard: Dictionary = {}
	var entries: Dictionary = {}
	var signature: Array = [city.get_instance_id(),city.terrain.noise_seed,city.terrain.river_phase,city.terrain.family,
		hash(city.terrain.water),hash(city.terrain.cfg),city.road_index_identity,city.fabric_cache.get("shared_walls",[]).hash()]
	for building: Dictionary in city.buildings:
		var id := str(building.get("district_id",""))
		if id.is_empty() or int(building.get("era",1)) != 1: continue
		if str(building.get("type","")) not in ["residential","commercial"]: continue
		if int(building.get("birth_frame",0)) > frame: continue
		if not _sprite_complete(id): continue
		if not view.building_geometry.has(id): continue
		var entry: Dictionary = view.building_geometry[id].get("entry",{})
		if not bool(entry.get("refined_valley",false)): continue
		heard[id] = building
		entries[id] = entry
		signature.append([id,Coupling.position_of(building),entry.get("id",""),entry.get("orientation",-1),view.building_geometry[id].get("scale",0.0)])
	if signature == geometry_key:
		return
	var next_rows := _derive_rows(city,heard,entries)
	clear()
	geometry_key = signature
	rows = next_rows
	rebuild_count += 1
	for row: Dictionary in rows:
		var ids: Array[String] = row["ids"]
		for index in range(ids.size()-1):
			var patch := _make_patch(city,[ids[index],ids[index+1]],heard,entries)
			if patch == null: continue
			add_child(patch)
			patches.append(patch)

func _audible_frame() -> int:
	if view != null and view.get("clock") != null:
		var clock = view.clock
		if clock.get("renderer") != null and clock.renderer.get("transport") != null:
			return int(clock.renderer.transport.audible_frame)
	return 0

func _sprite_complete(id: String) -> bool:
	if view == null or not view.get("sprites").has(id): return false
	var sprite = view.sprites[id]
	return float(sprite.progress) >= 1.0

func _derive_rows(city: RefCounted,heard: Dictionary,entries: Dictionary) -> Array[Dictionary]:
	var edge_by_id: Dictionary = {}
	var street_of: Dictionary = {}
	var arc_of: Dictionary = {}
	var tangent_of: Dictionary = {}
	for id: String in heard:
		var building: Dictionary = heard[id]
		var p := Coupling.position_of(building)
		var projected := Frontage.projection(city,city.building_polygon(p),p)
		if projected.is_empty(): continue
		street_of[id] = str(projected.get("street",""))
		var context := _road_context(city,p,str(projected.get("street","")).split(":")[0])
		arc_of[id] = context["arc"]
		tangent_of[id] = context["tangent"]
		if not entries[id].has("orientation"): street_of.erase(id)
		if not street_of.has(id): continue
		edge_by_id[id] = []
	for relation: Dictionary in city.fabric_cache.get("shared_walls",[]):
		var a := str(relation.get("a","")); var b := str(relation.get("b",""))
		if not heard.has(a) or not heard.has(b) or not edge_by_id.has(a) or not edge_by_id.has(b): continue
		if Fabric.gap(heard[a],heard[b]) > 0.10+0.000001: continue
		if street_of[a] != street_of[b]: continue
		if int(entries[a].get("orientation",-1)) != int(entries[b].get("orientation",-2)): continue
		if absf(Vector2(tangent_of[a]).dot(Vector2(tangent_of[b]))) < cos(PI/6.0): continue
		var along := Coupling.position_of(heard[a]).direction_to(Coupling.position_of(heard[b]))
		if absf(along.dot(Vector2(tangent_of[a]))) < cos(PI/6.0): continue
		if _blocked_seam(city,Coupling.position_of(heard[a]),Coupling.position_of(heard[b])): continue
		edge_by_id[a].append(b); edge_by_id[b].append(a)
	var grouped: Dictionary = {}
	for id: String in edge_by_id:
		if not grouped.has(street_of[id]): grouped[street_of[id]] = []
		grouped[street_of[id]].append(id)
	var result: Array[Dictionary] = []
	for street: String in grouped:
		var ids: Array = grouped[street]
		ids.sort_custom(func(a: String,b: String) -> bool:
			if float(arc_of.get(a,0.0)) != float(arc_of.get(b,0.0)): return float(arc_of.get(a,0.0)) < float(arc_of.get(b,0.0))
			return a < b)
		var chain: Array[String] = []
		for id: String in ids:
			if chain.is_empty() or edge_by_id[chain[-1]].has(id):
				chain.append(id)
			else:
				_append_chunks(result,chain,street); chain = [id]
		_append_chunks(result,chain,street)
	return result

func _append_chunks(result: Array[Dictionary],chain: Array[String],street: String) -> void:
	var cursor := 0
	while cursor < chain.size():
		var chunk: Array[String] = chain.slice(cursor,min(chain.size(),cursor+MAX_ROW))
		if chunk.size() >= 2: result.append({"ids":chunk,"street":street})
		cursor += MAX_ROW

func _road_context(city: RefCounted,p: Vector2,road_id: String) -> Dictionary:
	var road: Dictionary = {}
	for candidate: Dictionary in city.roads:
		if str(candidate.get("id","")) == road_id: road = candidate; break
	if road.is_empty(): return {"arc":p.y,"tangent":Vector2.DOWN}
	var total := 0.0
	var nearest := INF
	var result := 0.0
	var tangent := Vector2.DOWN
	for i in range(road["path"].size()-1):
		var a: Vector2 = road["path"][i]; var b: Vector2 = road["path"][i+1]
		var q := Geometry2D.get_closest_point_to_segment(p,a,b)
		var distance := q.distance_squared_to(p)
		if distance < nearest:
			nearest = distance
			result = total+a.distance_to(q)
			tangent = a.direction_to(b)
		total += a.distance_to(b)
	return {"arc":result,"tangent":tangent}

func _blocked_seam(city: RefCounted,a: Vector2,b: Vector2) -> bool:
	var line := PackedVector2Array([a,b])
	if not Geometry2D.intersect_polyline_with_polygon(line,city.terrain.water).is_empty(): return true
	# Actual near-touching outer walls cannot span a >=0.8 clear courtyard.
	# Do not use the old center-triangle court hull here: its boundary passes
	# through house centers and would reject genuine shared-wall neighbors.
	var steps := 8
	for i in range(1,steps):
		var p := a.lerp(b,float(i)/steps)
		if Fabric.on_road(city,p,0.025): return true
	return false

func _make_patch(city: RefCounted,ids: Array[String],heard: Dictionary,entries: Dictionary) -> RoofPatch:
	var first := Coupling.position_of(heard[ids[0]])
	var last := Coupling.position_of(heard[ids[1]])
	var orientation := int(entries[ids[0]]["orientation"])
	var front: Vector2 = FACING[orientation]
	var right := Vector2(front.y,-front.x)
	var side := 1.0 if (last-first).dot(right) > 0.0 else -1.0
	var along := right*side
	# Shared street direction alone is insufficient on a bend: the two baked
	# side walls must have overlapping depth and actually face one another.
	if absf(first.direction_to(last).dot(right)) < cos(PI/6.0): return null
	var a := _roof_source(city,ids[0],entries[ids[0]],first,side)
	var b := _roof_source(city,ids[1],entries[ids[1]],last,-side)
	if a.is_empty() or b.is_empty(): return null
	var distance := (last-first).dot(along)
	var offset := (last-first).dot(front)
	var a_scale := float(a["ground_scale"]); var b_scale := float(b["ground_scale"])
	var a_profile: Dictionary = a["profile"]; var b_profile: Dictionary = b["profile"]
	var lo := maxf((float(a_profile["center_z"])-float(a_profile["half_depth"]))*a_scale,
		offset+(float(b_profile["center_z"])-float(b_profile["half_depth"]))*b_scale)
	var hi := minf((float(a_profile["center_z"])+float(a_profile["half_depth"]))*a_scale,
		offset+(float(b_profile["center_z"])+float(b_profile["half_depth"]))*b_scale)
	if hi-lo < 0.18: return null
	var edge_a := float(a_profile["edge"])*a_scale
	var edge_b := distance-float(b_profile["edge"])*b_scale
	# Exact outer eaves, plus only a 0.006-model overlap to seal raster alpha.
	# In particular the courtyard x=+/-0.17 inner roof edge is never touched.
	var start := edge_a-0.006*a_scale
	var finish := edge_b+0.006*b_scale
	if finish-start <= 0.002: return null
	var seam := (edge_a+edge_b)*0.5
	var patch := RoofPatch.new()
	patch.name = "JoinedRoof_"+"_".join(ids)
	patch.row_ids = ids.duplicate()
	patch.source_roles.assign([str(a["role"]),str(b["role"])])
	patch.join_kind = "continuous_"+str(a["role"]) if a["role"] == b["role"] else "stepped_"+str(a["role"])+"_"+str(b["role"])
	patch.actual_depth = hi-lo
	patch.world_footprint = PackedVector2Array([first+along*start+front*lo,first+along*finish+front*lo,
		first+along*finish+front*hi,first+along*start+front*hi])
	if a["style"] == b["style"]: patch.roof_color = PALETTES[a["style"]][0]
	# Neither half interpolates toward the OTHER roof. They are continuations
	# of their own actual model planes, on their own Sprite's fixed ground.
	_add_roof_half(patch,a,first,along,front,start,seam,lo,hi)
	_add_roof_half(patch,b,first,along,front,seam,finish,lo,hi)
	var seam_ground := first+along*seam
	var height_a := _surface_height(a,seam_ground)
	var height_b := _surface_height(b,seam_ground)
	patch.seam_heights = Vector2(height_a,height_b)
	if absf(height_a-height_b) > 0.00001:
		var p := seam_ground+front*lo; var q := seam_ground+front*hi
		var stone := Color("d3c0a0") if along.dot(Vector2(1,1)) > 0.0 else Color("af9e84")
		_add_surface(patch,"height_step","",PackedVector3Array([_point3(p,height_a),_point3(q,height_a),
			_point3(q,height_b),_point3(p,height_b)]),stone)
		# Only a short coping/flashing at the top of the real vertical step;
		# never a broad diagonal plane across a terrace and a low tiled house.
		if absf(height_a-height_b) > 0.035:
			var high: Dictionary = a if height_a > height_b else b
			var height := maxf(height_a,height_b)+0.005
			var lip := 0.009
			_add_surface(patch,"short_step_cap",str(high["id"]),PackedVector3Array([
				_point3(p-along*lip,height),_point3(q-along*lip,height),
				_point3(q+along*lip,height),_point3(p+along*lip,height)]),high["roof_color"])
	# Each face carries its own fine tile joints; later foreground faces can
	# correctly hide those details, unlike an always-on-top invented ridge.
	patch.surfaces.sort_custom(func(x: Dictionary,y: Dictionary) -> bool: return float(x["depth"]) < float(y["depth"]))
	var position_a: Vector2 = view.building_geometry[ids[0]]["position"]
	var position_b: Vector2 = view.building_geometry[ids[1]]["position"]
	patch.position = Vector2((position_a.x+position_b.x)*0.5,maxf(position_a.y,position_b.y)+0.01)
	for surface: Dictionary in patch.surfaces:
		var polygon := PackedVector2Array()
		for point: Vector3 in surface["vertices"]: polygon.append(_project_vertex(point)-patch.position)
		surface["polygon"] = polygon
		for detail: Dictionary in surface["details"]:
			var line := PackedVector2Array()
			for point: Vector3 in detail["vertices"]: line.append(_project_vertex(point)-patch.position)
			detail["line"] = line
	# Retain the diagnostics fields used by the existing Demo comparison.
	for surface: Dictionary in patch.surfaces:
		if surface["kind"] == "roof" and surface["owner"] == ids[0]: patch.top_a = surface["polygon"]
		if surface["kind"] == "roof" and surface["owner"] == ids[1]: patch.top_b = surface["polygon"]
		if surface["kind"] == "fascia" and surface["owner"] == ids[0]: patch.fascia_a = surface["polygon"]
		if surface["kind"] == "fascia" and surface["owner"] == ids[1]: patch.fascia_b = surface["polygon"]
	return patch

func _roof_source(city: RefCounted,id: String,entry: Dictionary,p: Vector2,side: float) -> Dictionary:
	var role := str(entry.get("role",""))
	if not ROOF_PROFILES.has(role): return {}
	var pixels_per_model := float(view.building_geometry[id]["scale"])*float(entry["pixels_per_world"])
	var style := str(entry.get("first_expression_style","tile"))
	if not PALETTES.has(style): style = "tile"
	var palette: Array = PALETTES[style]
	var front: Vector2 = FACING[int(entry["orientation"])]
	var right := Vector2(front.y,-front.x)
	return {"id":id,"role":role,"profile":ROOF_PROFILES[role],"position":p,"side":side,
		"right":right,"front":front,"ground_height":city.terrain.height_at(p),
		"ground_scale":pixels_per_model/(28.0*sqrt(2.0)),
		"height_scale":pixels_per_model*sqrt(3.0)/(2.0*14.0),"style":style,
		"roof_color":palette[2] if role == "terrace" else palette[0 if side < 0.0 else 1],
		"tile_color":palette[2],"shade_color":palette[1]}

func _surface_height(source: Dictionary,p: Vector2) -> float:
	var profile: Dictionary = source["profile"]
	var model_x := (p-Vector2(source["position"])).dot(Vector2(source["right"]))/float(source["ground_scale"])
	var ridge_x := float(profile["ridge_x"])*float(source["side"])
	# tiled_roof() has a real 0.011-model tile lip at the outer eave.
	var tile_lip := 0.0 if source["role"] == "terrace" else 0.011
	var height := float(profile["eave"])+tile_lip+float(profile["rise"])*(1.0-absf(model_x-ridge_x)/float(profile["half_pitch"]))
	return float(source["ground_height"])+height*float(source["height_scale"])

func _add_roof_half(patch: RoofPatch,source: Dictionary,origin: Vector2,along: Vector2,front: Vector2,
	start: float,finish: float,lo: float,hi: float) -> void:
	var a := origin+along*start+front*lo; var b := origin+along*finish+front*lo
	var c := origin+along*finish+front*hi; var d := origin+along*start+front*hi
	var ha := _surface_height(source,a); var hb := _surface_height(source,b)
	var thickness := float(source["profile"]["thickness"])*float(source["height_scale"])
	var face := _add_surface(patch,"roof",str(source["id"]),PackedVector3Array([
		_point3(a,ha),_point3(b,hb),_point3(c,hb),_point3(d,ha)]),source["roof_color"])
	face["source_role"] = source["role"]
	face["source_position"] = source["position"]
	face["source_orientation_right"] = source["right"]
	face["source_model_side"] = source["side"]
	face["source_eave"] = source["profile"]["eave"]
	face["source_rise"] = source["profile"]["rise"]
	face["source_half_pitch"] = source["profile"]["half_pitch"]
	face["source_ridge_x"] = float(source["profile"]["ridge_x"])*float(source["side"])
	face["source_ground_scale"] = source["ground_scale"]
	face["source_height_scale"] = source["height_scale"]
	face["source_ground_height"] = source["ground_height"]
	for points: Array in [[a,b],[d,c]]:
		var p: Vector2 = points[0]; var q: Vector2 = points[1]
		var ph := _surface_height(source,p); var qh := _surface_height(source,q)
		_add_surface(patch,"fascia",str(source["id"]),PackedVector3Array([
			_point3(p,ph),_point3(q,qh),_point3(q,qh-thickness),_point3(p,ph-thickness)]),source["shade_color"])
	# Eight tiles along model z exactly like tiled_roof(). Only continue those
	# existing joints through the narrow added material, without extra ridge.
	if source["role"] != "terrace":
		var profile: Dictionary = source["profile"]
		var step := float(profile["half_depth"])*2.0*float(source["ground_scale"])/8.0
		var offset := (Vector2(source["position"])-origin).dot(front)
		var tile_start := offset+(float(profile["center_z"])-float(profile["half_depth"]))*float(source["ground_scale"])
		for index in range(1,8):
			var z := tile_start+float(index)*step
			if z <= lo or z >= hi: continue
			var p := origin+along*start+front*z; var q := origin+along*finish+front*z
			face["details"].append({"vertices":PackedVector3Array([_point3(p,_surface_height(source,p)+0.004),
				_point3(q,_surface_height(source,q)+0.004)]),"color":Color(source["tile_color"],0.48),"width":0.45})

func _point3(p: Vector2,height: float) -> Vector3:
	return Vector3(p.x,height,p.y)

func _add_surface(patch: RoofPatch,kind: String,owner_id: String,vertices: PackedVector3Array,color: Color) -> Dictionary:
	var depth := 0.0
	for point: Vector3 in vertices: depth += point.x+point.z+point.y/3.0
	var surface := {"kind":kind,"owner":owner_id,"vertices":vertices,"color":color,
		"depth":depth/float(vertices.size()),"polygon":PackedVector2Array(),"details":[]}
	patch.surfaces.append(surface)
	return surface

func _project_vertex(point: Vector3) -> Vector2:
	return IsoProjection.to_screen(Vector2(point.x,point.z)-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),point.y)

func diagnostics() -> Dictionary:
	var output: Array = []
	for row: Dictionary in rows: output.append({"ids":row.get("ids",[]).duplicate(),"street":row.get("street","")})
	var geometry: Array = []
	for patch: RoofPatch in patches:
		var physical: Array = []
		for surface: Dictionary in patch.surfaces:
			physical.append({"kind":surface["kind"],"owner":surface["owner"],"vertices":surface["vertices"]})
		geometry.append({"ids":patch.row_ids.duplicate(),"footprint":patch.world_footprint,"face_count":patch.surfaces.size(),
			"actual_depth":patch.actual_depth,"join_kind":patch.join_kind,"source_roles":patch.source_roles,
			"seam_heights":patch.seam_heights,"surfaces":physical,
			"roof_color":patch.roof_color,"position":patch.position,"top_a":patch.top_a,"top_b":patch.top_b})
	return {"rows":output,"patches":patches.size(),"geometry":geometry,"rebuild_count":rebuild_count,"max_row":MAX_ROW}
