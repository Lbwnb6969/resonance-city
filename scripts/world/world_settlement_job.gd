extends RefCounted
## Each task owns all mutable city data. Only the main thread starts, polls and adopts.
## Cache containers are private; published geometry/path/edge records are immutable.
const World = preload("res://scripts/world/continuous_world.gd")
const WORLD_CACHE_FIELDS = ["fabric_cache","fabric_anchor_cache","fabric_geometry_identity","edge_cache",
	"environment_cache","environment_pending","public_service_cache","resonance","planning_revision"]
const FROZEN_CACHE_FIELDS = ["edge_cache","environment_cache","environment_pending"]
const NETWORK_CACHE_FIELDS = ["route_cache","route_trees","access_cache","walking_distance_cache","mobile_candidates"]
var version: Array = []
var commit_frame := 0
var snapshot: Dictionary = {}
var caches: Dictionary = {}
var network_caches: Dictionary = {}
var result: ContinuousWorld
# Built on the worker from the exact input snapshot; never serialized as an object.
var presentation_view: ContinuousWorld
var worker_ms := 0.0
var task_id := -1

func start(city: ContinuousWorld, key: Array, frame: int) -> void:
	version = key.duplicate(true)
	commit_frame = frame
	snapshot = city.snapshot()
	for field in WORLD_CACHE_FIELDS:
		var value: Variant = city.get(field)
		if field in FROZEN_CACHE_FIELDS:
			value.make_read_only()
			caches[field] = value
		else: caches[field] = value.duplicate() if value is Dictionary else value
	for field in NETWORK_CACHE_FIELDS:
		network_caches[field] = city.network.get(field).duplicate()
	task_id = WorkerThreadPool.add_task(_compute,false,"City phrase settlement")

func _compute() -> void:
	var started := Time.get_ticks_usec()
	var private_city := World.new(snapshot["seed_hex"],false)
	private_city.restore(snapshot,false)
	# restore reconstructs membership in building order; preserve the live planning order.
	private_city.communities = snapshot["plan"]["communities"].duplicate(true)
	for field in WORLD_CACHE_FIELDS:
		private_city.set(field,caches[field].duplicate() if field in FROZEN_CACHE_FIELDS else caches[field])
	private_city.environment_cache.merge(private_city.environment_pending,true)
	private_city.environment_pending = {}
	for field in NETWORK_CACHE_FIELDS: private_city.network.set(field,network_caches[field])
	# The old audible city follows restore semantics (including member order),
	# while the input snapshot retains the original serializable world order.
	presentation_view = World.new(snapshot["seed_hex"],false)
	presentation_view.restore(snapshot,false)
	presentation_view.fabric_cache = private_city.fabric_cache.duplicate(true)
	presentation_view.edge_cache = private_city.edge_cache.duplicate(true)
	presentation_view.public_service_cache = private_city.public_service_cache.duplicate(true)
	presentation_view.resonance = private_city.resonance
	private_city.settle(commit_frame)
	result = private_city
	caches.clear()
	network_caches.clear()
	worker_ms = float(Time.get_ticks_usec()-started)/1000.0

func completed() -> bool:
	return task_id >= 0 and WorkerThreadPool.is_task_completed(task_id)

func join() -> void:
	if task_id < 0: return
	WorkerThreadPool.wait_for_task_completion(task_id)
	task_id = -1

func adopt(city: ContinuousWorld) -> void:
	# Keep the public World identity: UI, transport and tests can retain references.
	for property in city.get_script().get_script_property_list():
		var field := str(property["name"])
		var previous: Variant = city.get(field)
		city.set(field,result.get(field))
		result.set(field,previous)

func retire() -> void:
	task_id = WorkerThreadPool.add_task(_dispose,false,"City snapshot retirement")

func _dispose() -> void:
	result = null
	presentation_view = null
	# An adopted presentation may still own the snapshot. Release this reference
	# instead of clearing a published dictionary that is waiting to be heard.
	snapshot = {}
	caches.clear()
	network_caches.clear()
