extends RefCounted
## Explicit v2: independent background plus optional same-source voices; no full-mix fallback.
const SCHEMA="city_sparse_music_v2"
const Wave=preload("res://scripts/audio/city_creation_lyria_bundle.gd")
const Harmony=preload("res://scripts/audio/city_creation_game_music_harmony.gd")
static func read_data(path:String,data:Dictionary)->Dictionary:
	var frames:=int(data.get("frames",0));var rows:Array=data.get("layers",[])
	if frames<=0 or data.get("sample_rate")!=44100 or data.get("channels")!=2 or data.get("operations",{}).get("loop_enabled",true):return {"ok":false,"reason":"invalid_sparse_timeline"}
	if rows.size()<1 or rows.size()>4:return {"ok":false,"reason":"invalid_sparse_layers"}
	var ids:Array=[];var streams:Array=[];var lead_count:=0
	for row:Dictionary in rows:
		var id:=str(row.get("id",""));var role:=str(row.get("role",""));var layer:=int(row.get("layer",-1));var cap:=float(row.get("automatic_max",-1.))
		if id not in ["background","body","motion","detail"] or ids.has(id) or row.get("source_id")!=data.get("source_id") or not is_finite(cap) or cap<0. or cap>1.:return {"ok":false,"reason":"invalid_sparse_voice"}
		if id=="background":
			if role!="background" or layer!=1 or cap!=1. or not ids.is_empty():return {"ok":false,"reason":"invalid_background"}
		elif role=="lead":
			lead_count+=1
			if layer!=3 or cap>.35:return {"ok":false,"reason":"invalid_sparse_lead"}
		elif role=="unassigned":
			if layer!=0 or cap!=0.:return {"ok":false,"reason":"unassigned_voice_enabled"}
		elif role not in ["response","motion"] or layer not in [2,4]:return {"ok":false,"reason":"invalid_sparse_role"}
		if control(row) not in ["none","enclosure","flow","craft","highland","civic"]:return {"ok":false,"reason":"invalid_sparse_control"}
		if control(row)=="civic" and (role!="response" or cap>.35):return {"ok":false,"reason":"invalid_civic_response"}
		var stream:=Wave.wave(row,frames,44100)
		if stream==null:return {"ok":false,"reason":"invalid_sparse_audio"}
		ids.append(id);streams.append(stream)
	if ids[0]!="background" or lead_count>1:return {"ok":false,"reason":"invalid_sparse_roles"}
	var synced:=AudioStreamSynchronized.new();synced.stream_count=streams.size()
	for i in range(streams.size()):synced.set_sync_stream(i,streams[i]);synced.set_sync_stream_volume(i,0. if i==0 else -INF)
	return {"ok":true,"stream":synced,"ids":ids,"fallback":false,"manifest":data,"signature":FileAccess.get_sha256(path),"timeline":Harmony.authored_timeline(data,frames)}
static func initial(packet:Dictionary,id:String)->float:
	return (1. if id=="background" else 0.) if packet.manifest.schema==SCHEMA else (1. if id=="core" else .35)
static func live_mode(host:Node)->bool:
	return host.active and host.prepared.manifest.schema==SCHEMA and not host.has_meta("candidate_record_owner")
static func compatible_preferences(host:Node,prefs:Dictionary)->bool:
	if prefs==host.preferences:return true
	if not live_mode(host) or prefs.size()!=host.preferences.size():return false
	# The first switch to fixed writes the default style into a previously empty field.
	var style:String=prefs.get("style","")
	var opened_style:String=host.preferences.get("style","")
	var default_styles:=["","pastoral_breeze"]
	var same_style:=style==opened_style or (style in default_styles and opened_style in default_styles)
	return same_style and prefs.get("seed")==host.preferences.get("seed")
static func control(row:Dictionary)->String:
	return str(row.get("control","enclosure" if row.id=="body" else "flow" if row.id=="motion" else "craft"))
static func context(host:Node,row:Dictionary)->Dictionary:
	var name:=control(row)
	if name=="enclosure":return host.envelope_state
	if name=="highland":return host.contour_state
	if name in ["flow","craft","civic"]:
		return {"value":host.expression.get(name,0.)} if host.manual_expression else host.color_states.get(name,{})
	return {}
static func step(host:Node,mix_delta:float,quiet:bool=false)->void:
	var target:=Vector2.ZERO
	if quiet or host.audition_mix==1:target.x=1.
	elif host.audition_mix==2:target.y=1.
	host.audition_weights=host.audition_weights.move_toward(target,mix_delta/.65)
	var weights:Vector2=host.audition_weights
	var spatial_weight:=1.-weights.x-weights.y
	for row:Dictionary in host.prepared.manifest.layers:
		var id:String=row.id
		if id=="background":host.values[id]=1.;continue
		var influence:float=float(context(host,row).get("value",0.))
		host.values[id]=float(row.automatic_max)*clampf(influence*spatial_weight+weights.y,0.,1.)
