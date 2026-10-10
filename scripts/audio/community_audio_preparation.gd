extends RefCounted
## Pure structural sound data. Worker owns construction; consumers copy mutable arrays.
static func landmark_records(landmarks: Array) -> Array:
	var city: Array = []
	for landmark in landmarks:
		var motif: Array = landmark.get("motif",[])
		var midi := int(motif[0].get("midi",48)) if not motif.is_empty() else 48
		city.append({"district_id":str(landmark["id"]),"position":landmark["position"],"radius":float(landmark["radius"]),
			"current_midi":midi,"base_midi":midi,"type":"residential","vitality":100.0,
			"community_id":"landmark:"+str(landmark["id"]),"family_id":"landmark:"+str(landmark["id"]),
			"expression":"bright","family_anchor":true,"is_anchor":true,"era":int(landmark.get("era",1)),
			"form":"央","form_count":0,"birth_frame":int(landmark.get("frame",0)),"voice_level":float(landmark.get("voice_level",0.34)),
			"landmark":true})
	return city

static func build(city: Array, config: Dictionary) -> Dictionary:
	var population: Dictionary = {}
	var groups: Dictionary = {}
	var targets: Dictionary = {}
	var stereo: Array[Vector2] = []
	var map_width := 16
	var space: Dictionary = config["space"]
	var score: Dictionary = config["score"]
	for district in city:
		var cid: String = district["community_id"]
		population[cid] = int(population.get(cid,0))+1
	for district in city:
		var id: String = district["district_id"]
		var midi := int(district["current_midi"])
		var cid: String = district["community_id"]
		var key := "%s:%s:%d" % [cid,district["type"],midi]
		var position: Array = district["position"]
		var pan := clampf((float(position[0])-float(position[1]))/float(space["pan_divisor"]),-float(space["pan_limit"]),float(space["pan_limit"]))
		stereo.append(Vector2(cos((pan+1.0)*PI/4.0),sin((pan+1.0)*PI/4.0)))
		map_width = maxi(map_width,16+4*maxi(0,int(district.get("era",1))-1))
		if not groups.has(key):
			groups[key] = {"key":key,"cid":cid,"midi":midi,"type":district["type"],"members":[],
				"pan_sum":0.0,"expression":district.get("expression","bright")}
		var group: Dictionary = groups[key]
		group["members"].append(id)
		group["pan_sum"] += pan
		targets[id] = float(district["voice_level"])
	for group in groups.values():
		var pan: float = float(group["pan_sum"])/group["members"].size()
		group["stereo"] = Vector2(cos((pan+1.0)*PI/4.0),sin((pan+1.0)*PI/4.0))
		group["target"] = float(score["pad_gain"])*sqrt(float(group["members"].size())/maxf(6.0,float(population[group["cid"]])))*sqrt(float(score.get("pad_reference_communities",3.0))/maxf(float(score.get("pad_reference_communities",3.0)),population.size()))
	return {"population":population,"groups":groups,"targets":targets,"stereo":stereo,"map_width":map_width,
		"score_signature":[score["pad_gain"],score.get("pad_reference_communities",3.0)]}
