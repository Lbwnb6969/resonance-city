extends RefCounted
## Editorial candidate fit only; never promotes listening/default approval.
const ERAS=["pastoral","renaissance","clockwork","modern_eco"]
const REVIEW="res://数据/音乐制作/音乐分类建议_20261104.json"
static func read()->Dictionary:
	var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(REVIEW))
	var result:Dictionary={}
	if not data is Dictionary or data.get("schema")!="music_style_scene_review_v1":return result
	for row:Dictionary in data.get("songs",[]):
		var era:String=str(row.get("era",""));if era=="modern":era="modern_eco"
		if era in ERAS:result[str(row.source_id)]=era
	return result
static func city_era(city:RefCounted,weights:Dictionary)->String:
	var totals:Dictionary={}
	for id:String in weights:
		var index:int=city._house_index(id)
		if index<0:continue
		var era:String=city.house_era(city.houses[index])
		if era in ERAS:totals[era]=float(totals.get(era,0.))+float(weights[id])
	var winner:=dominant(totals)
	return winner if not winner.is_empty() else str(preload("res://scripts/world/city_creation_build_brush.gd").current(city).era)
static func dominant(totals:Dictionary)->String:
	var best:="";var maximum:=0.
	for era:String in ERAS:
		if float(totals.get(era,0.))>maximum:best=era;maximum=totals[era]
	return best
static func eligible(rows:Array,fit:Dictionary,era:String)->Array:
	return rows.filter(func(row):return fit.get(str(row.source_id),"")==era and era in ERAS)
