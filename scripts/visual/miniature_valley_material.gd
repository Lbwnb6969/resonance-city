extends RefCounted
## Material geometry for the miniature river town. All marks derive from the
## heard terrain and road graph; no simulation RNG or World data is changed.
const COLORS := {
	"left":["d6c9a8","c5c8a5","b6c1a0","a6b796"],
	"right":["cfd0ad","c6cdab","b8c6a4","a8bb9c"],
	"rim":"c7c4a3","water":"538f94","channel":"3c7180","shallow":"9abbaa",
	"shore":"8b9b88","edge":"dfd8bc","road":"c6b898","road_edge":"ded2b3",
	"road_joint":"8d8972","plot":"cabd9c","park":"97ae87","park_path":"d1c7a6",
	"civic":"d1c3a1",
}
const WATER_DEPTH_STEPS := 32

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
		var accumulated := 0.0
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
				var ordinal := floori((accumulated+distance*(float(step)+0.5)/steps)/0.65)
				var edge_a := -0.80 if ordinal%2 == 0 else -0.12
				var edge_b := 0.12 if ordinal%2 == 0 else 0.80
				if not _inside_other_road(city,midpoint,str(road["id"])):
					result["joints"].append(PackedVector2Array([midpoint+normal*width*edge_a,midpoint+normal*width*edge_b]))
			accumulated += distance
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
