class_name ContinuousSynth
extends "res://scripts/audio/district_synth.gd"
const WorldConfig = preload("res://scripts/world/world_values.gd")
var targets: Dictionary = {}
var listener_community := ""
var muted_communities: Dictionary = {}

func _pan_for(district: Dictionary) -> float:
	var p: Array = district["position"]
	var config: Dictionary = WorldConfig.load_values()["space"]
	return clampf((float(p[0])-float(p[1]))/float(config["pan_divisor"]),-float(config["pan_limit"]),float(config["pan_limit"]))

func _rebuild_assist_neighbors(city: Array) -> void:
	assist_neighbors.clear()
	for district in city: assist_neighbors[district["district_id"]] = []

func update_city(city: Array, state: Dictionary, marks: Dictionary = {}, events: Array = []) -> void:
	var voice_events := events.filter(func(event: Dictionary) -> bool: return event.has("district_id"))
	super(city,state,marks,voice_events)
	for district in city: targets[district["district_id"]] = float(district["voice_level"])

func render_block(state: Dictionary, start: int, count: int, rate: int) -> PackedVector2Array:
	var output := PackedVector2Array()
	# Smooth controls outside the per-sample inner loops; phases never reset.
	for offset in range(0,count,128):
		var amount := mini(128,count-offset)
		for route in routing:
			var community := ""
			var born := 0
			for district in districts:
				if district["district_id"] == route["id"]:
					community = str(district.get("community_id",""))
					born = int(district.get("birth_frame",0))
					break
			var audible: bool = not bool(muted_communities.get(community,false)) and (listener_community.is_empty() or listener_community == community)
			var target := float(targets.get(route["id"],0.2)) if audible else 0.0
			var previous := float(state.get("_world_level_"+str(route["id"]),0.0))
			var alpha := 1.0-exp(-float(amount)/(0.05*rate))
			var level := lerpf(previous,target,alpha)
			state["_world_level_"+str(route["id"])] = level
			route["level"] = level*clampf(float(start+offset-born)/(0.5*rate),0.0,1.0)
		output.append_array(super.render_block(state,start+offset,amount,rate))
	return output
