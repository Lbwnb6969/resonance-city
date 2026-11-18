extends RefCounted
## Sparse fit describes declared spatial responses, never acoustic or listening quality.
const Sparse=preload("res://scripts/audio/city_creation_sparse_music_bundle.gd")
const CONTROLS:=["enclosure","flow","craft","highland"]
static func vector(manifest:Dictionary)->Array:
	if manifest.schema!=Sparse.SCHEMA:
		var d:Dictionary=manifest.get("descriptors",{})
		var body:Dictionary=d.get("body",{}).get("features",{});var motion:Dictionary=d.get("motion",{}).get("features",{});var detail:Dictionary=d.get("detail",{}).get("features",{})
		return [float(body.get("low_band_fraction",0.)),clampf(float(motion.get("positive_envelope_change",0.)),0.,1.),1.-float(detail.get("active_fraction",1.))]
	var result:Array=[0.,0.,0.,0.]
	for row:Dictionary in manifest.layers:
		if row.role in ["background","unassigned"] or float(row.automatic_max)<=0.:continue
		var index:=CONTROLS.find(Sparse.control(row))
		if index>=0:result[index]=1.
	return result
static func sample(facts:Dictionary)->Array:
	return [float(facts.get("enclosure",0.)),float(facts.get("flow",0.)),float(facts.get("craft",0.)),float(facts.get("highland",{}).get("value",0.))]
