extends RefCounted
## Local source references and a frozen mix, never a recording or adoption approval.
const ROOT:="res://数据/音乐资产/游戏音乐包/"
static func number(value:Variant)->bool:return (value is float or value is int) and is_finite(float(value))
static func digest(value:Variant)->bool:
	if not value is String or value.length()!=64:return false
	for c:String in value:
		if c not in "0123456789abcdef":return false
	return true
static func manifest_path_valid(path:Variant)->bool:
	return path is String and path.begins_with(ROOT) and path.ends_with("/bundle.json") and not path.contains("..") and not path.contains("\\") and not path.substr(6).contains(":")

static func valid(value:Variant)->bool:
	if not value is Dictionary or value.size()!=12 or value.get("version")!=2:return false
	if value.get("bundle_schema") not in ["city_adaptive_music_v1","city_sparse_music_v2"] or not digest(value.get("source_id")) or not digest(value.get("manifest_sha256")):return false
	if not manifest_path_valid(value.get("manifest")):return false
	if not number(value.get("frames")) or value.frames!=floorf(value.frames) or value.frames<=0.:return false
	if not number(value.get("position")) or value.position<0. or value.position>float(value.frames)/44100.:return false
	if not number(value.get("master_gain")) or value.master_gain<0. or value.master_gain>1.:return false
	if not value.get("ended") is bool or not value.get("fallback") is bool or not value.get("values") is Dictionary:return false
	if not value.get("name") is String or value.name.length()>200 or value.name.contains("\n"):return false
	if value.values.is_empty() or value.values.size()>4:return false
	for id:Variant in value.values:
		if id not in ["core","background","body","motion","detail"] or not number(value.values[id]) or value.values[id]<0. or value.values[id]>1.:return false
	return true
static func capture(music:Node)->Dictionary:
	var node:Node=music.get_node_or_null("GameMusicPlayer")
	if node==null or not node.active or node.cancelled or node.retired or not node.valid_context():return {}
	if node.has_meta("candidate_record_owner"):
		var saved:Dictionary=node.recorded_mix.duplicate(true)
		saved.position=float(saved.frames)/44100. if node.ended else minf(float(saved.frames)/44100.,node.player.get_playback_position());saved.ended=node.ended
		return saved
	var value:={"version":2,"source_id":node.prepared.manifest.source_id,"bundle_schema":node.prepared.manifest.schema,"manifest":node.manifest_path,"manifest_sha256":node.prepared.signature,"frames":node.prepared.manifest.frames,"position":minf(float(node.prepared.manifest.frames)/44100.,node.player.get_playback_position()) if not node.sequence.breathing else float(node.prepared.manifest.frames)/44100.,"values":node.values.duplicate(true),"master_gain":.8*minf(1.,node.clock/.8),"ended":node.sequence.breathing,"fallback":node.prepared.fallback,"name":str(node.prepared.manifest.name)}
	return value if valid(value) else {}
static func prepare(value:Dictionary)->Dictionary:
	if not valid(value) or FileAccess.get_sha256(value.manifest)!=value.manifest_sha256:return {"ok":false,"reason":"saved_source_unavailable"}
	var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(value.manifest))
	if not data is Dictionary or data.get("kind")!="music" or data.get("source_id")!=value.source_id or data.get("schema")!=value.bundle_schema or data.get("frames")!=value.frames:return {"ok":false,"reason":"saved_source_identity_changed"}
	var packet:Dictionary=preload("res://scripts/audio/city_creation_game_music_bundle.gd").read(value.manifest)
	if not packet.get("ok",false):return packet
	if packet.signature!=value.manifest_sha256:return {"ok":false,"reason":"saved_source_identity_changed"}
	if packet.fallback!=value.fallback or packet.ids.size()!=value.values.size():return {"ok":false,"reason":"saved_mix_layers_changed"}
	for id:String in packet.ids:
		if not value.values.has(id):return {"ok":false,"reason":"saved_mix_layers_changed"}
		if not packet.fallback:
			for layer:Dictionary in data.layers:
				if layer.id==id and (float(value.values[id])>float(layer.get("automatic_max",1.)) or id in ["core","background"] and float(value.values[id])!=1.):return {"ok":false,"reason":"saved_mix_gain_changed"}
	return packet
static func begin(music:Node,value:Dictionary)->Dictionary:
	if not valid(value) or FileAccess.get_sha256(value.manifest)!=value.manifest_sha256:return {"ok":false,"message":"保存的本地曲目缺失或签名已变，未改播其他音乐"}
	if conflict(music):return {"ok":false,"message":"请先结束当前音乐试听或演出"}
	if music.phonograph.active or music.phonograph.candidate_player!=null:music.phonograph.stop(music)
	var node:Node=load("res://scripts/audio/city_creation_candidate_record_player.gd").new()
	node.music=music;node.manifest_path=value.manifest;node.recorded_mix=value.duplicate(true);node.name="CandidateRecordPreparation";node.set_meta("candidate_record_owner",true)
	music.phonograph.mix=value.duplicate(true);music.phonograph.candidate_player=node;music.add_child(node)
	return {"ok":true,"message":"正在准备保存的同源混音"}
static func conflict(music:Node)->bool:
	var authored:Node=music.get_node_or_null("AuthoredScore")
	return music._loading or music.concert_active or music.has_meta("authored_score") or music.has_meta("authored_score_ready") or (authored!=null and authored.worker!=null) or music.get_node_or_null("LyriaSpatialPreview")!=null
