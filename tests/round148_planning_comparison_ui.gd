extends SceneTree
## Round 148 UI contract: each public-planning branch exposes role conditions
## without presenting them as a separate future audio preview.

const Guide = preload("res://scripts/ui/planning_guide.gd")

var failures: Array[String] = []
var checks := 0

func check(condition: bool,label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func role(role_id: String,title: String,ready: bool) -> Dictionary:
	return {"role":role_id,"title":title,"qualified":ready,
		"qualification":{"qualified":ready},"current":"当前"+title,
		"next":"下一步"+title}

func community(ready: Dictionary) -> Dictionary:
	var rows: Array = [role("Lead","社区主题",true),
		role("Bass","低音表达",bool(ready.get("Bass",false))),
		role("Rhythm","商业律动",bool(ready.get("Rhythm",false))),
		role("Response","跨岸应答",bool(ready.get("Response",false)))]
	var role_map: Dictionary = {}
	for item in rows: role_map[item["role"]] = item
	return {"community_id":"west-1","opportunities":rows,"role_opportunities":role_map}

func variant(ready: Dictionary,with_preview: bool) -> Dictionary:
	var branch := {"accepted":true,"score":{"theme":{"cid":"west-1"}},"theme_events":1,
		"service":{"served":4},"houses":18,"anchor":{"served":["a"],"service_capacity":18},
		"newly_served_ids":[],"lost_service_ids":[]}
	var data := community(ready)
	if with_preview: branch["opportunity_preview"] = {"communities":[{"community_id":"west-1","roles":data["role_opportunities"]}]}
	else: branch["opportunities"] = [data]
	return branch

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Control.new()
	root.add_child(host)
	var guide = Guide.new()
	root.add_child(guide)
	guide.setup(host)
	guide.anchor_kind = "park"
	guide.comparison = {"variants":{
		"none":variant({"Bass":false,"Rhythm":false,"Response":false},false),
		"park":variant({"Bass":true,"Rhythm":false,"Response":true},true),
		"civic":variant({"Bass":true,"Rhythm":true,"Response":true},true)}}
	guide._show_comparison()
	var text: String = guide.detail.text
	for label in ["暂不建","公园","文化馆","低音表达","商业律动","跨岸应答"]:
		check(text.contains(label),"comparison keeps "+label)
	var role_rows := Array(text.split("\n")).filter(func(line: String) -> bool: return line.begins_with("低音表达 ·") or line.begins_with("商业律动 ·") or line.begins_with("跨岸应答 ·"))
	check(role_rows.size() == 3,"comparison expands one selected branch without duplicate role rows")
	check(text.contains("已就绪") and text.contains("待条件"),"comparison distinguishes qualified and waiting roles")
	check(text.count("现 ") >= 3 and text.count("下 ") >= 3,"comparison exposes current and next for selected roles")
	check(text.contains("试听是完整合奏") and text.contains("切换下方方案对比"),"comparison explains full mix and branch controls")
	for choice: String in ["none","park","civic"]:
		guide.anchor_kind = choice
		guide._show_comparison()
		check(guide.detail.text.contains("低音表达") and guide.detail.text.contains("商业律动") and guide.detail.text.contains("跨岸应答"),choice+" exposes its role opportunities when selected")
	print("ROUND148_PLANNING_COMPARISON_UI checks=%d failures=%s" % [checks,JSON.stringify(failures)])
	guide.free()
	host.free()
	quit(0 if failures.is_empty() else 1)
