extends RefCounted
## Authored route identity changes presentation only. Every silhouette keeps
## the source entry's plot, origin, alpha contour and shadow geometry.
const STYLES := {
	"deep":{"label":"深流","residential_id":"valley_house_terrace","ink":Color("6f8d92"),
		"textures":{"valley_house_terrace":"资源/首作声音路线/SVG/deep_valley_house_terrace.svg"},
		"hashes":{"valley_house_terrace":"72665e550cbde4848fbdcb8fdb48f61e891a808270108fe5787b22de0fcc914e"},
		"palette":{"#DBB9A8":"#879D9F","#C8A691":"#829397","#9F8A87":"#76858C",
			"#E5DBCC":"#E0E5E2","#BDBBBD":"#ABB9B9","#F6EFE5":"#F0F1EA"}},
	"weave":{"label":"织机","residential_id":"valley_house_hipped","ink":Color("bd8760"),
		"textures":{"era1_commercial_01":"资源/首作声音路线/SVG/weave_era1_commercial_01.svg","valley_house_hipped":"资源/首作声音路线/SVG/weave_valley_house_hipped.svg"},
		"hashes":{"era1_commercial_01":"f367ecbabd32b4a41874e1b570aaeac0e95b7742097e8eee6701449f364a5f49","valley_house_hipped":"fbf7d0723b69b61f583f966d1486ee054d2b157c6bacbf5d86ea2988535fdb1e"},
		"palette":{"#DAB8A7":"#D49C79","#DBB9A8":"#D49C79","#D9B7A6":"#D49C79","#D6B5A5":"#C88F70",
			"#E5DBCC":"#EBD9BC","#BDBBBD":"#C9B7A7","#F6EFE5":"#FFF0D7"}},
	"warm":{"label":"留地","residential_id":"valley_house_gabled","ink":Color("809475"),
		"textures":{"valley_house_gabled":"资源/首作声音路线/SVG/warm_valley_house_gabled.svg"},
		"hashes":{"valley_house_gabled":"c3961eb0dfc1d70028f3b017c1d11381406fd2e788b6afba9641863dc9983e04"},
		"palette":{"#D6B5A5":"#91A483","#D9B7A6":"#A5B494","#DBB9A8":"#A5B494",
			"#E5DBCC":"#E5E4CF","#BDBBBD":"#BEC4B4","#7D8E9A":"#83938B"}},
}

static func expression_for(building: Dictionary,family: Dictionary = {}) -> String:
	if not bool(building.get("player_expression",false)) and not bool(family.get("player_expression",false)): return ""
	var expression := str(building.get("expression",family.get("expression","")))
	return expression if STYLES.has(expression) else ""

static func styled_entry(entry: Dictionary,expression: String) -> Dictionary:
	if not STYLES.has(expression): return entry
	var textures: Dictionary = STYLES[expression]["textures"]
	if not textures.has(str(entry["id"])): return entry
	var styled := entry.duplicate(true)
	styled["source_texture"] = entry["texture"]
	styled["texture"] = textures[str(entry["id"])]
	styled["source_texture_sha256"] = entry.get("texture_sha256","")
	styled["texture_sha256"] = STYLES[expression]["hashes"][str(entry["id"])]
	styled["source"] = str(entry.get("source",""))+"; first_expression_identity.gd palette only"
	styled["id"] = str(entry["id"])+":first_expression:"+expression
	styled["first_expression_style"] = expression
	return styled

static func entry_for(building: Dictionary,fallback: Dictionary,variants: Array,family: Dictionary = {}) -> Dictionary:
	var expression := expression_for(building,family)
	if expression.is_empty(): return fallback
	var chosen := fallback
	# Commercial identity remains a shop. Do not turn the weave's actual use
	# into a decorative house just to obtain another roof.
	if str(building.get("type","")) == "residential":
		for entry: Dictionary in variants:
			if str(entry.get("id","")) == str(STYLES[expression]["residential_id"]):
				chosen = entry
				break
	return styled_entry(chosen,expression)

static func svg_for(source: String,expression: String) -> String:
	if not STYLES.has(expression): return source
	var result := source
	var palette: Dictionary = STYLES[expression]["palette"]
	for color: String in palette:
		result = result.replace('fill="'+color+'"','fill="'+str(palette[color])+'"')
	return result

static func identity(building: Dictionary,family: Dictionary = {}) -> Dictionary:
	var expression := expression_for(building,family)
	if expression.is_empty(): return {}
	return {"expression":expression,"label":STYLES[expression]["label"],
		"ink":STYLES[expression]["ink"],"residential_id":STYLES[expression]["residential_id"]}
