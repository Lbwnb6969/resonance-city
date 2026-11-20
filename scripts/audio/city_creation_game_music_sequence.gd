extends RefCounted
## Complete-song candidates only. Spatial/texture fit is not a listening approval.
const Bundle=preload("res://scripts/audio/city_creation_game_music_bundle.gd")
const BREATH_SECONDS:=3.
const EraFit=preload("res://scripts/audio/city_creation_music_era_fit.gd")
const Fit=preload("res://scripts/audio/city_creation_music_sequence_fit.gd")
const EraObservation=preload("res://scripts/audio/city_creation_music_era_observation.gd")
const SceneFit=preload("res://scripts/audio/city_creation_music_scene.gd")
var era_observation:=EraObservation.new()
var era_fit:Dictionary={}
var selected_era:=""
var owner:Node
var rows:Array=[]
var history:Array=[]
var recent:Array=[]
var play_counts:Dictionary={}
var enabled:=false
var breathing:=false
var remaining:=0.
var worker:Thread
var ready:Dictionary={}
var next_row:Dictionary={}
var requested_fixed:=false
var failed:=""
var last_second:=-1
var transitions:Array=[]
var ended_usec:=0
var breath_sample_usec:=0
var breath_clock:=0.
var era_sample_usec:=-1
func configure(host:Node,catalog:Array)->void:
	owner=host;rows=[];play_counts={};era_fit=EraFit.read();era_observation=EraObservation.new()
	era_sample_usec=-1
	for row:Dictionary in catalog:
		if row.get("kind")!="music" or FileAccess.get_sha256(row.manifest)!=row.manifest_sha256:continue
		var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(row.manifest))
		rows.append(row.merged({"automatic_candidate":row.get("automatic_candidate",true) and manifest.get("automatic_candidate",true),"bundle_schema":manifest.schema,"fit":Fit.vector(manifest),"scene":str(manifest.get("scene",""))},true))
	enabled=not rows.is_empty()
func observe()->void:
	if not enabled:return
	var second:=floori(owner.clock)
	if second==last_second:return
	last_second=second;var facts:Dictionary=owner.spatial_facts
	history.append(Fit.sample(facts))
	if history.size()>30:history.pop_front()
func average()->Array:
	var result:Array=[0.,0.,0.,0.]
	for sample:Array in history:
		for i in range(sample.size()):result[i]+=float(sample[i])/history.size()
	return result
func fixed_order()->bool:
	return owner.music._pluck_city.creative_settings.get("music",{}).get("mode","auto")=="fixed"
func current_scene()->String:
	return SceneFit.at(owner.music._pluck_city,owner.music._listener_focus,owner.music.acoustic.zoom)
func select_next()->Dictionary:
	var current:String=owner.prepared.manifest.source_id
	if not play_counts.has(current):play_counts[current]=1
	if fixed_order():
		var same_source:Dictionary={}
		for row:Dictionary in rows:
			if row.source_id!=current or row.get("bundle_schema","city_adaptive_music_v1")!=owner.prepared.manifest.get("schema","city_adaptive_music_v1"):continue
			if row.get("manifest_sha256","") == owner.prepared.get("signature",""):return row
			if same_source.is_empty():same_source=row
		if not same_source.is_empty():return same_source
	selected_era=era_observation.established if not era_observation.established.is_empty() else str(owner.spatial_facts.get("era",""))
	var suitable:Array=EraFit.eligible(rows,era_fit,selected_era).filter(func(row):return row.get("bundle_schema","city_adaptive_music_v1")==owner.prepared.manifest.get("schema","city_adaptive_music_v1") and row.get("automatic_candidate",true))
	if suitable.any(func(row):return not str(row.get("scene","")).is_empty()):
		var scene:=current_scene()
		suitable=suitable.filter(func(row):return row.get("scene","") in ["",scene])
	if suitable.is_empty():return {}
	var candidates:Array=suitable.filter(func(row):return row.source_id!=owner.prepared.manifest.source_id and not recent.has(row.source_id))
	if candidates.is_empty():candidates=suitable.filter(func(row):return row.source_id!=owner.prepared.manifest.source_id)
	if candidates.is_empty():return suitable[0]
	# Stable geometry must not trap a large repertoire in its four best fits.
	# Within the eligible era/protocol, give less-played songs their turn first.
	var least:int=play_counts.get(candidates[0].source_id,0)
	for row:Dictionary in candidates:least=mini(least,int(play_counts.get(row.source_id,0)))
	candidates=candidates.filter(func(row):return int(play_counts.get(row.source_id,0))==least)
	for row:Dictionary in candidates:
		if not str(row.get("scene","")).is_empty():return row
	var mean:=average();var best:Dictionary={};var score:=INF
	for row:Dictionary in candidates:
		var distance:=0.
		for i in range(row.fit.size()):distance+=pow(float(row.fit[i])-float(mean[i]),2.)
		if distance<score:best=row;score=distance
	return best
func prepare_next()->void:
	if worker!=null or not ready.is_empty() or not failed.is_empty():return
	requested_fixed=fixed_order()
	next_row=select_next()
	if next_row.is_empty():failed="no_era_candidate";return
	var path:String=next_row.manifest;var signature:String=next_row.manifest_sha256
	worker=Thread.new();worker.start(func():return Bundle.read(path) if FileAccess.get_sha256(path)==signature else {"ok":false,"reason":"candidate_signature_changed"})
func finish(now_usec:int=-1)->bool:
	if not enabled:return false
	breathing=true;remaining=BREATH_SECONDS;breath_clock=0.
	ended_usec=Time.get_ticks_usec() if now_usec<0 else now_usec
	breath_sample_usec=ended_usec
	return true
func sync_breath_clock(paused:bool,now_usec:int=-1)->void:
	if not breathing:return
	if now_usec<0:now_usec=Time.get_ticks_usec()
	if not paused:
		breath_clock+=float(now_usec-breath_sample_usec)/1000000.
		remaining=maxf(0.,BREATH_SECONDS-breath_clock)
	breath_sample_usec=now_usec
func pause_changed(was_paused:bool,now_usec:int=-1)->void:
	if now_usec<0:now_usec=Time.get_ticks_usec()
	sync_breath_clock(was_paused,now_usec)
	era_sample_usec=now_usec
func wait_reason()->String:
	var reason:=era_observation.reason()
	return "" if reason=="era_observation" and fixed_order() else reason
func step(now_usec:int=-1)->void:
	if not enabled:return
	var fixed:=fixed_order()
	if requested_fixed!=fixed:
		ready={};next_row={};failed=""
	if worker!=null and not worker.is_alive():
		var packet:Dictionary=worker.wait_to_finish()
		worker=null
		if requested_fixed==fixed:
			ready=packet
			if not ready.get("ok",false):failed=str(ready.get("reason","candidate_unavailable"));ready={}
	if now_usec<0:now_usec=Time.get_ticks_usec()
	var era_delta:=float(now_usec-era_sample_usec)/1000000. if era_sample_usec>=0 else 0.
	era_sample_usec=now_usec
	# Both scheduling gates run in active wall time, including the nature-only gap.
	sync_breath_clock(owner.paused,now_usec)
	if owner.paused:return
	era_observation.step(str(owner.spatial_facts.get("era","")),era_delta,owner.music.attention.sculpt_serial,owner.music.attention.dragging)
	if not breathing:return
	if not wait_reason().is_empty():return
	# Missing-era silence is transient; retry only after a new stable era.
	if failed=="no_era_candidate" and selected_era!=era_observation.established:failed=""
	if not ready.is_empty() and not fixed_order():
		var tag:=str(next_row.get("scene",""))
		if selected_era!=era_observation.established or (not tag.is_empty() and tag!=current_scene()):ready={};next_row={}
	prepare_next()
	if remaining>0. or ready.is_empty():return
	if not owner.valid_context():return
	transitions.append({"from":owner.prepared.manifest.source_id,"to":next_row.source_id,"breath_seconds":breath_clock,"wall_seconds":float(Time.get_ticks_usec()-ended_usec)/1000000.,"mean_affinity":average()})
	if transitions.size()>8:transitions.pop_front()
	recent.append(owner.prepared.manifest.source_id)
	if recent.size()>2:recent.pop_front()
	var packet:=ready;var path:String=next_row.manifest;ready={};next_row={};history=[];last_second=-1;breathing=false
	record_play(str(packet.manifest.source_id))
	owner.switch_packet(packet,path)
func record_play(source:String)->void:play_counts[source]=int(play_counts.get(source,0))+1
func close()->void:
	enabled=false
	if worker!=null:worker.wait_to_finish();worker=null
	ready={};rows=[]
