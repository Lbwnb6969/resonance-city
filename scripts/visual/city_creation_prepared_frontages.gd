extends RefCounted
## Used only by detached, read-only worker snapshots. Live State still derives
## frontages on demand, including edits made by existing external APIs.
static func capture(city:RefCounted)->Dictionary:
	return {"signature":city.get_meta("prepared_frontage_signature",-1),"rows":city.get_meta("prepared_frontages",{}).duplicate(true)}
static func history_seed(city:RefCounted)->Dictionary:
	var life=preload("res://scripts/world/city_creation_economy_pause.gd").owner(city)
	return capture(life._network.state) if life!=null and life._network!=null and life._network.state!=null else {}
static func prepare(city:RefCounted,seed:Dictionary={})->void:
	var signature:=hash([city.houses,city.roads])
	if seed.get("signature",null)==signature:
		city.set_meta("prepared_frontages",seed.rows);city.set_meta("prepared_frontage_signature",signature);return
	var rows:Dictionary={}
	preload("res://scripts/world/city_creation_frontage_neighborhoods.gd").build(city)
	for house:Dictionary in city.houses:
		var id:=str(house.id)
		rows[id]=city.house_entrances(id)
	city.set_meta("prepared_frontages",rows)
	city.set_meta("prepared_frontage_signature",signature)

static func read(city:RefCounted,id:String)->Array[Dictionary]:
	var rows:Array[Dictionary]=[]
	rows.assign(city.get_meta("prepared_frontages").get(id,[]).duplicate(true))
	return rows
