extends RefCounted
## A local render added explicitly for one isolated audition.
const Record=preload("res://scripts/audio/city_creation_candidate_record.gd")
const Sparse=preload("res://scripts/audio/city_creation_sparse_music_bundle.gd")

static func row(path:String)->Dictionary:
	if not Record.manifest_path_valid(path):return {}
	var raw:=FileAccess.get_file_as_bytes(path)
	var data:Variant=JSON.parse_string(raw.get_string_from_utf8()) if not raw.is_empty() else null
	if not data is Dictionary or data.get("schema")!=Sparse.SCHEMA or data.get("kind")!="music":return {}
	var title:Variant=data.get("name")
	if not title is String or title.strip_edges().is_empty() or title.length()>200 or title.contains("\n"):return {}
	if not Record.digest(data.get("source_id")):return {}
	var hash:=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(raw)
	return {"kind":"music","name":title,"source_id":data.source_id,"manifest":path,
		"manifest_sha256":hash.finish().hex_encode(),"automatic_candidate":false,"session_candidate":true}

static func catalog(pointer:Variant)->Array:
	if not pointer is Dictionary:return []
	var path:=str(pointer.get("catalog",""))
	var signature:Variant=pointer.get("catalog_sha256")
	if not Record.digest(signature) or FileAccess.get_sha256(path)!=signature:return []
	var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return data.get("packs",[]) if data is Dictionary and data.get("packs") is Array else []
