extends RefCounted
## Free-city L page consumes the same geometry report used by later orchestration.
const Safe=preload("res://scripts/ui/city_creation_life_capsules.gd")
const SpaceFocus=preload("res://scripts/ui/city_creation_space_focus.gd")
static func open_records(widget:RefCounted)->void:
	if not widget.demo.state.CreationPolicy.is_free(widget.demo.state):widget.demo.guide.open_panel(1);return
	widget.demo.journal.open_panel()
	var page:Node=widget.demo.get_meta("growth_rights_page");page.open_rights()
	var city:RefCounted=widget.demo.state;var epoch:int=city._wish_epoch
	# Wait for the expanded text to contribute its real height to the scroll.
	await widget.demo.get_tree().process_frame;await widget.demo.get_tree().process_frame
	if widget.demo.state!=city or city._wish_epoch!=epoch or not widget.demo.journal.panel.visible or not page.detail.visible:return
	var scroll:ScrollContainer=widget.demo.journal.cards.get_parent()
	scroll.scroll_vertical+=roundi(page.read.get_global_rect().position.y-scroll.get_global_rect().position.y)
static func caption(widget:RefCounted)->void:
	var free:bool=widget.demo.state.CreationPolicy.is_free(widget.demo.state)
	widget.button.text="城市总谱 · L" if free else "生活账本 · L"
	widget.button.tooltip_text="查看实际空间与当前合奏 · L" if free else "查看真实库存与已发生的日常 · L"
	widget.scrollbook.tabs.ledger.text="总谱" if free else "账本"
static func refresh(widget:RefCounted)->bool:
	var free:bool=widget.demo.state.CreationPolicy.is_free(widget.demo.state)
	var heading:Label=widget.paper.find_child("LedgerHeading",true,false)
	heading.text="城市总谱" if free else "生活账本";widget.guide_button.show()
	widget.guide_button.text="查看经营与历史权益 · J" if free else "经营手札 · F1"
	var entries:Node=widget.scroll.get_child(0)
	for child:Control in entries.get_children():
		if child==widget.body or child.name=="MusicTrialControls":continue
		if free:
			if not child.has_meta("before_functional_ledger"):child.set_meta("before_functional_ledger",child.visible)
			child.hide()
		elif child.has_meta("before_functional_ledger"):
			child.visible=child.get_meta("before_functional_ledger");child.remove_meta("before_functional_ledger")
	if not free:
		if widget.body.has_meta("before_functional_ledger"):widget.body.visible=widget.body.get_meta("before_functional_ledger");widget.body.remove_meta("before_functional_ledger")
		return false
	if not widget.body.has_meta("before_functional_ledger"):widget.body.set_meta("before_functional_ledger",widget.body.visible)
	widget.body.show();widget.rows.clear()
	var report:Dictionary=widget.demo.state.functional_zones()
	var lines:=PackedStringArray(["[b]城市的空间[/b]", "特色来自建筑，成区还需真实公共空间。"])
	if not report.network_ready:lines.append("道路正在更新，空间激活待道路发布。")
	lines.append("\n[b]场所空间[/b]")
	for space_index in range(report.spaces.size()):
		var space:Dictionary=report.spaces[space_index]
		var names:Array=[]
		for id:String in space.members:
			var index:int=widget.demo.state._house_index(id)
			names.append(Safe.safe(str(widget.demo.state.houses[index].name) if index>=0 else str(widget.demo.state.PlacedLandmarks.Legacy.TITLES[widget.demo.state.PlacedLandmarks.row(widget.demo.state,id).blueprint])))
		var stage:String={"trait":"特色","cluster":"局部空间","district":"成区"}[space.stage]
		var detail:String=preload("res://scripts/ui/city_creation_space_description.gd").detail(space,report.network_ready)
		if space.evidence.geometry=="paved_plaza":names=["扇石广场" if space.evidence.paving=="fan_stone" else "砖石广场"]
		lines.append("%s · %s · %s\n%s"%["、".join(names),stage,SpaceFocus.link(widget.demo.state,space_index,space),detail])
	var plan:Dictionary=widget.demo.music.get_meta("orchestration_plan",{})
	lines.append("\n[b]当前合奏[/b]")
	var trial:=preload("res://scripts/ui/city_creation_music_trial_caption.gd").lines(widget.demo.music)
	if not trial.is_empty():lines.append_array(trial)
	elif plan.is_empty():lines.append("落下第一间房屋，静候初吟。")
	else:
		var style:String={"pastoral_breeze":"庭院微风","felt_nocturne":"毡琴夜曲","deep_flow":"低音深流"}.get(str(plan.get("style","")),"当前主题")
		lines.append("%s · 第%d段 / 六段"%[style,int(plan.get("passage",0))+1])
		lines.append("回答声部 · "+("接腔" if plan.get("response",false) else "静候应答"))
	widget._text="\n".join(lines);widget.body.text=widget._text
	return true
