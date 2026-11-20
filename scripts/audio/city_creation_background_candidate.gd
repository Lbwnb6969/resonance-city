extends RefCounted
## Opt-in audition entry only. Editorial fit never changes formal approval.
const Fit=preload("res://scripts/audio/city_creation_music_era_fit.gd")
const START_CODES={"pastoral":"1-01","renaissance":"2-01","clockwork":"3-01","modern_eco":"4-01"}
static func select(packs:Array,fit:Dictionary,era:String,scene:String="")->Dictionary:
	var fallback:Dictionary={}
	var preferred:Dictionary={}
	if era not in Fit.ERAS:return {}
	for i in range(packs.size()):
		var row:Dictionary=packs[i]
		if not row.get("automatic_candidate",true) or fit.get(row.source_id,"")!=era:continue
		if FileAccess.get_sha256(row.manifest)!=row.manifest_sha256:continue
		var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(row.manifest))
		if not data is Dictionary or data.get("schema")!="city_sparse_music_v2" or not data.get("automatic_candidate",true) or data.get("source_id")!=row.source_id or data.get("era")!=era:continue
		var choice:={"index":i,"source_id":row.source_id,"era":era,"manifest":row.manifest}
		var tag:=str(data.get("scene",""))
		if not tag.is_empty():
			if tag==scene:return choice
			continue
		if fallback.is_empty():fallback=choice
		if preferred.is_empty() and str(data.get("name","")).begins_with(START_CODES.get(era,"?")):
			if scene.is_empty():return choice
			preferred=choice
	return fallback if preferred.is_empty() else preferred
