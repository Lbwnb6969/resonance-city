extends Node
## Installed only by the isolated construction launcher; never a default music policy.
const Player=preload("res://scripts/audio/city_creation_game_music_player.gd")
var demo:Node3D
var packs:Array=[]
var picker:OptionButton
var background_button:Button
var request_serial:=0
var pending_request:=false
var play_button:Button
var pause_button:Button
var stop_button:Button
var status:Label
var conductor:Node
var background:Array=[]
var background_pool:Array=[]
var background_source_ids:Array=[]
func install(owner:Node3D)->bool:
	demo=owner
	var pointer:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/active_game_music.json"))
	if not pointer is Dictionary or FileAccess.get_sha256(pointer.catalog)!=pointer.catalog_sha256:return false
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(pointer.catalog))
	var sparse:Dictionary=pointer.get("sparse_trial",{})
	if not sparse.is_empty() and FileAccess.get_sha256(sparse.catalog)==sparse.catalog_sha256:
		var extra:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(sparse.catalog))
		catalog.packs.append_array(extra.packs)
	for row:Dictionary in catalog.packs:
		if row.kind=="music":packs.append(row)
	if packs.is_empty():return false
	var background_ids:Array=pointer.get("trial_background",{}).get("source_ids",[])
	for row:Dictionary in packs:
		if row.source_id in background_ids:
			background.append(row)
			background_source_ids.append(row.source_id)
		if _is_sparse_background(row):
			background_pool.append(row)
			if not background_source_ids.has(row.source_id):background_source_ids.append(row.source_id)
	var box:=VBoxContainer.new();box.name="MusicTrialControls";demo.ledger.scroll.get_child(0).add_child(box);demo.ledger.scroll.get_child(0).move_child(box,0)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.text="隔离候选试听 · 技术通过 · 待听评";box.add_child(status)
	picker=OptionButton.new();picker.name="MusicTrialPicker";picker.clip_text=true;picker.fit_to_longest_item=false;picker.custom_minimum_size.x=220;box.add_child(picker)
	for row:Dictionary in packs:picker.add_item(("仅手选 · " if not row.get("automatic_candidate",true) else "")+("背景候选 · " if row.source_id in background_source_ids else "")+str(row.name).get_basename())
	for i in range(packs.size()):
		if packs[i].source_id==pointer.get("trial_background",{}).get("first_source_id",""):picker.select(i)
	background_button=demo._button("试听时代背景",start_background);box.add_child(background_button)
	var buttons:=HBoxContainer.new();box.add_child(buttons)
	play_button=demo._button("试听所选",start_selected);buttons.add_child(play_button)
	pause_button=demo._button("暂停",toggle_pause);buttons.add_child(pause_button)
	stop_button=demo._button("结束试听",stop);buttons.add_child(stop_button)
	demo.set_meta("music_trial",self);return true
func start_background()->void:
	if demo.edit_pending() or demo.gallery.busy or demo.music._loading:return
	var affinity=preload("res://scripts/audio/city_creation_music_affinity.gd").new();affinity.refresh(demo.state)
	var weights:Dictionary=affinity.sample(demo.music._listener_focus,float(demo.music.acoustic.zoom)).weights
	var fit=preload("res://scripts/audio/city_creation_music_era_fit.gd")
	var choice:Dictionary=preload("res://scripts/audio/city_creation_background_candidate.gd").select(packs,fit.read(),fit.city_era(demo.state,weights))
	if choice.is_empty():stop();status.text="当前时代暂无背景候选 · 保留自然声";return
	picker.select(choice.index);start_selected()
func start_selected()->void:
	var row:Dictionary=packs[picker.selected];var city:int=demo.state.get_instance_id();var epoch:int=demo.state._wish_epoch
	stop();var serial:int=request_serial;pending_request=true;status.text="隔离候选试听 · 技术通过 · 待听评"
	while demo.music.get_node_or_null("GameMusicPlayer")!=null:await get_tree().process_frame
	if request_serial!=serial:return
	pending_request=false
	if demo.state.get_instance_id()!=city or demo.state._wish_epoch!=epoch:return
	if FileAccess.get_sha256(row.manifest)!=row.manifest_sha256:status.text="候选文件与目录签名不符";return
	var ticket:Dictionary=Player.request(demo.music,row.manifest)
	if not ticket.ok:status.text="当前音乐正在使用，请结束留声机或其他试听";return
	conductor=ticket.node
	var legacy_background:bool=background.has(row)
	var sparse_background:bool=background_pool.has(row)
	var is_background:bool=legacy_background or sparse_background
	conductor.set_meta("background_intent_trial",is_background)
	var sequence_rows:Array=background if legacy_background else background_pool if sparse_background else packs
	conductor.sequence.configure(conductor,sequence_rows);demo.ledger._last_refresh=-500

func _is_sparse_background(row:Dictionary)->bool:
	if not row.get("automatic_candidate",true) or not FileAccess.file_exists(row.manifest):return false
	if FileAccess.get_sha256(row.manifest)!=row.manifest_sha256:return false
	var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(row.manifest))
	return data is Dictionary and data.get("schema") == "city_sparse_music_v2" and data.get("automatic_candidate",true)
func toggle_pause()->void:
	if is_instance_valid(conductor):conductor.set_paused(not conductor.paused)
func stop()->void:
	request_serial+=1;pending_request=false
	if is_instance_valid(conductor):conductor.stop()
	conductor=null
func _process(_delta:float)->void:
	if status==null:return
	var present:=is_instance_valid(conductor)
	pause_button.disabled=not present;stop_button.disabled=not present and not pending_request
	play_button.disabled=pending_request or (present and conductor.worker!=null)
	background_button.disabled=play_button.disabled or demo.edit_pending() or demo.gallery.busy or demo.music._loading
	pause_button.text="继续" if present and conductor.paused else "暂停"
