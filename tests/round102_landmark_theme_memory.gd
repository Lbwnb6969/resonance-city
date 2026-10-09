extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)

func _run() -> void:
	var world := World.new("2026101000000102",false,"river_valley")
	var community_id := "source-community"
	world.communities[community_id] = {"id":community_id,"members":["absorbed-1","survivor-1"],"bank":-1,"name":"记忆街坊","parent_id":""}
	var absorbed := {"district_id":"absorbed-1","position":[0.0,0.0],"radius":0.5,"current_midi":60,"type":"residential","form":"群","community_id":community_id,"family_id":"family-1"}
	var survivor := {"district_id":"survivor-1","position":[10.0,10.0],"radius":0.5,"current_midi":55,"type":"residential","form":"群","community_id":community_id,"family_id":"family-2"}
	world.buildings = [absorbed,survivor]
	world.by_id["absorbed-1"] = absorbed
	world.by_id["survivor-1"] = survivor
	world.index.put("absorbed-1",Vector2.ZERO,0.5)
	world.index.put("survivor-1",Vector2(10.0,10.0),0.5)
	world.families["family-1"] = {"root":"absorbed-1"}
	world.families["family-2"] = {"root":"survivor-1"}

	world._commit_landmark({"name":"元老院","position":[0.0,0.0],"radius":1.0},0)
	_check(world.landmarks.size() == 1,"landmark committed")
	var landmark: Dictionary = world.landmarks[0]
	_check(landmark.get("source_communities",[]).has(community_id),"source community recorded")
	_check(landmark.get("absorbed_buildings",[]).has("absorbed-1"),"absorbed building recorded")
	var theme: Array = world.community_theme(community_id)
	_check(theme.size() == 2,"survivor and motif remain")
	_check(int(theme[0]) == 60,"landmark motif leads theme")
	_check(int(theme[1]) == 55,"surviving member answers motif")
	_check(not world.community_theme("source-community",{"survivor-1":60}).is_empty(),"theme accepts live pitch override")
	print("LANDMARK_THEME_MEMORY ",JSON.stringify({"passed":failures.is_empty(),"checks":6,"theme":theme,"source_communities":landmark.get("source_communities",[]),"motif":landmark.get("motif",[]),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
