extends RefCounted
const Safe=preload("res://scripts/ui/city_creation_life_capsules.gd")
static func lines(music:Node)->PackedStringArray:
	var node:Node=music.get_node_or_null("GameMusicPlayer")
	if node==null:
		return PackedStringArray(["自然底景 · 音乐留白","当前尚无已采用的背景曲目。可继续自由营造。 "]) if preload("res://scripts/audio/city_creation_free_music_route.gd").holds(music) else PackedStringArray()
	if node.has_meta("candidate_record_owner"):
		return PackedStringArray(["留声机回放 · 保存的同源混音",Safe.safe(str(node.recorded_mix.name)),"曲目已结束 · 静候收针" if node.ended else "已静音" if music.muted else "按保存的分层回放 · 待听评"])
	if node.sequence.breathing:
		var status:="曲尾呼吸留白 · 自然声"
		if node.sequence.failed=="no_era_candidate":status="当前场景暂无适配候选 · 保留自然声"
		elif not node.sequence.failed.is_empty():status="后续候选未准备好 · 保留自然声"
		elif node.paused:status="曲尾呼吸留白 · 已暂停"
		elif node.sequence.wait_reason()=="construction":status="曲尾呼吸留白 · 营造中，保留自然声"
		elif node.sequence.wait_reason()=="era_observation":status="曲尾呼吸留白 · 风貌观察中，保留自然声"
		return PackedStringArray(["隔离候选 · 技术通过 · 待听评",status])
	if not node.active:return PackedStringArray(["隔离候选 · 准备中，尚未接管播放"])
	var result:=PackedStringArray(["[b]隔离候选 · 技术通过 · 待听评[/b]",Safe.safe(str(node.prepared.manifest.get("name","当前候选"))),"当前为完整作品候选；稀疏背景方案尚待制作。"])
	if node.get_meta("background_intent_trial",false):result[2]="背景候选 · 旋律存在感与留白待听评。"
	if node.prepared.manifest.schema=="city_sparse_music_v2":result[2]="同源背景分层候选 · 旋律存在感与分离品质待听评。"
	if not node.prepared.manifest.get("automatic_candidate",true):result[2]="仅手选完整曲 · "+("用户标记含人声" if "含人声" in str(node.prepared.manifest.get("manual_only_reason","")) else "保留完整场景作品")
	if music.muted:result.append("已静音 · 保持当前播放与空间观察")
	if node.paused:result.append("已暂停 · 空间观察与播放同步冻结")
	for id:String in node.prepared.ids:
		var title:String={"background":"背景","core":"主曲","body":"温暖","motion":"流动","detail":"点缀"}[id]
		if id in ["core","background"]:result.append(title+" · "+("已暂停" if node.paused else "已静音" if music.muted else "正在发声"));continue
		var observes:=true
		var packet:Dictionary=node.envelope_state if id=="body" else node.color_states.get("flow" if id=="motion" else "craft",{})
		if node.prepared.manifest.schema=="city_sparse_music_v2":
			for row:Dictionary in node.prepared.manifest.layers:
				if row.id==id:
					observes=float(row.automatic_max)>0.;title=str(row.get("label",title));packet=preload("res://scripts/audio/city_creation_sparse_music_bundle.gd").context(node,row)
		if node.prepared.manifest.schema!="city_sparse_music_v2" and id=="motion" and float(packet.get("value",0.))==0. and (node.contour_state.get("candidate",false) or float(node.contour_state.get("value",0.))>0.):packet=node.contour_state
		var state:="手动对照" if node.manual_expression and id!="body" else "余韵" if packet.get("historical_tail",false) else "正在发声" if float(packet.get("value",0.))>0. else "观察中" if observes and packet.get("candidate",false) else "开放基线"
		result.append(title+" · "+("已暂停" if node.paused else "已静音" if music.muted else "观察中" if observes and packet.get("candidate",false) and float(packet.get("value",0.))==0. else "未发声" if node.prepared.manifest.schema=="city_sparse_music_v2" and float(node.values.get(id,0.))==0. else state))
	if node.prepared.fallback:result.append("颜色层未采用 · 播放已校验完整原混音")
	return result
