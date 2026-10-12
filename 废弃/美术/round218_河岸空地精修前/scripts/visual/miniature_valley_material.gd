extends RefCounted
## Material geometry for the miniature river town. All marks derive from the
## heard terrain and road graph; no simulation RNG or World data is changed.
const COLORS := {
	"left":["d6c9a8","cfc9a5","c4c59f","b9c09a"],
	"right":["d0cbaa","c9c8a5","c1c39f","b7bd99"],
	"rim":"c7c4a3","water":"538f94","channel":"3c7180","shallow":"9abbaa",
	"shore":"8b9b88","edge":"dfd8bc","road":"c6b898","road_edge":"ded2b3",
	"road_joint":"8d8972","plot":"cabd9c","park":"97ae87","park_path":"d1c7a6",
	"civic":"d1c3a1",
}
const WATER_DEPTH_STEPS := 32
const PAVING_COLOR := Color("d7c9ac")
const DIRT_COLOR := Color("baa88c")

static func earth_color(terrain: RefCounted,p: Vector2) -> Color:
	var side := "left" if p.x < terrain.river_x(p.y) else "right"
	var height: float = terrain.height_at(p)
	var rise := smoothstep(0.22,1.9,height)
	var color := Color(COLORS[side][0]).lerp(Color(COLORS[side][3]),rise)
	# A restrained directional lift reads the actual slope without drawing a
	# second relief field or discrete contour rings over the small town.
	var dx: float = terrain.height_at(p+Vector2(0.35,0))-terrain.height_at(p-Vector2(0.35,0))
	var dy: float = terrain.height_at(p+Vector2(0,0.35))-terrain.height_at(p-Vector2(0,0.35))
	var lift := clampf(-(dx+dy)*0.055,-0.018,0.018)
	return Color(clampf(color.r+lift,0.0,1.0),clampf(color.g+lift,0.0,1.0),clampf(color.b+lift,0.0,1.0))

static func earth_colors(terrain: RefCounted,polygon: PackedVector2Array) -> PackedColorArray:
	var result := PackedColorArray()
	for p in polygon: result.append(earth_color(terrain,p))
	return result

static func dirt_colors(terrain: RefCounted,polygon: PackedVector2Array) -> PackedColorArray:
	var result := PackedColorArray()
	for p in polygon: result.append(earth_color(terrain,p).lerp(DIRT_COLOR,0.23))
	return result

static func water_bands(terrain: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count: int = terrain.water.size()/2
	for index in range(WATER_DEPTH_STEPS):
		var depth := float(index)/float(WATER_DEPTH_STEPS-1)
		var fraction := depth*0.46
		var color := Color(COLORS["shallow"]).lerp(Color(COLORS["channel"]),depth)
		var polygon := PackedVector2Array()
		for at in range(count):
			polygon.append(terrain.water[at].lerp(terrain.water[terrain.water.size()-1-at],fraction))
		for at in range(count-1,-1,-1):
			polygon.append(terrain.water[terrain.water.size()-1-at].lerp(terrain.water[at],fraction))
		result.append({"polygon":polygon,"color":color})
	return result

static func land_grain(terrain: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var length := float(terrain.cfg.get("template_land_max_y",terrain.cfg["template_land_max"]))
	var phase := float(posmod(hash(str(terrain.noise_seed)),1000))*0.001
	for index in range(260):
		var p := Vector2(-1.0+fposmod(float(index)*0.6180339887+phase,1.0)*34.0,
			-1.0+fposmod(float(index)*0.4142135623+phase*0.7,1.0)*(length+2.0))
		if not terrain.land_at(p): continue
		var span := 0.045+float(index%4)*0.014
		var q := p+Vector2(span,span*0.3)
		if terrain.land_at(q): result.append({"path":PackedVector2Array([p,q]),"light":index%3 == 0})
	return result

static func street_geometry(city: RefCounted) -> Dictionary:
	var result := {"curbs":[],"joints":[],"paving":[]}
	for road: Dictionary in city.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road["path"]
		var width := road_width(city,road)
		for index in range(path.size()-1):
			var a := path[index]
			var b := path[index+1]
			var distance := a.distance_to(b)
			if distance <= 0.001: continue
			var direction := (b-a)/distance
			var normal := Vector2(-direction.y,direction.x)
			var steps := maxi(1,ceili(distance/0.65))
			for step in range(steps):
				var start := a.lerp(b,float(step)/steps)
				var finish := a.lerp(b,float(step+1)/steps)
				var midpoint := (start+finish)*0.5
				# Fine stone work belongs to occupied frontages. The unbuilt
				# network stays quiet instead of becoming a tiled planning grid.
				var neighbors: Array = city.index.query_circle(midpoint,2.1)
				if neighbors.is_empty(): continue
				var classical := 0
				for id: String in neighbors:
					if int(city.by_id[id].get("era",1)) == 1: classical += 1
				if classical == 0: continue
				var strength := float(classical)/float(neighbors.size())
				for polygon in Geometry2D.offset_polyline(PackedVector2Array([start,finish]),width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
					result["paving"].append({"polygon":polygon,"strength":strength})
				for side: float in [-1.0,1.0]:
					var offset := normal*width*side
					if not _inside_other_road(city,midpoint+offset,str(road["id"])):
						result["curbs"].append(PackedVector2Array([start+offset,finish+offset]))
				# Three slender courses with alternating cross joints are readable
				# stonework at close range, rather than marks across an empty grid.
				for row in range(3):
					var edge_a := lerpf(-0.90,0.90,float(row)/3.0)
					var edge_b := lerpf(-0.90,0.90,float(row+1)/3.0)
					for seam: float in [0.18,0.68] if row%2 == 0 else [0.43,0.93]:
						var at := start.lerp(finish,seam)
						if not _inside_other_road(city,at,str(road["id"])):
							result["joints"].append(PackedVector2Array([at+normal*width*edge_a,at+normal*width*edge_b]))
				for divider: float in [-0.30,0.30]:
					var offset := normal*width*divider
					if not _inside_other_road(city,midpoint+offset,str(road["id"])):
						result["joints"].append(PackedVector2Array([start+offset,finish+offset]))
	return result

static func road_width(city: RefCounted,road: Dictionary) -> float:
	return 0.55 if bool(road.get("bridge",false)) else (float(city.cfg["city"]["branch_road_half_width"]) if str(road.get("kind","")) == "branch" else float(city.cfg["terrain"]["template_road_half_width"]))

static func _inside_other_road(city: RefCounted,p: Vector2,road_id: String) -> bool:
	for segment: Dictionary in city.near_road_segments(p,0.9):
		var other: Dictionary = segment["road"]
		if str(other["id"]) == road_id: continue
		var closest := Geometry2D.get_closest_point_to_segment(p,segment["a"],segment["b"])
		if p.distance_to(closest) < road_width(city,other)+0.045: return true
	return false
