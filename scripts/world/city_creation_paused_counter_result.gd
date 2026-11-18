extends RefCounted
## One immutable history source owns this result across worker captures.
## External snapshots still serialize complete counters, never this cache.
var _mutex:=Mutex.new()
var _ready:=false
var _counts:Dictionary={}
var _computations:=0
var _reuses:=0

func resolve(build:Callable)->Dictionary:
	_mutex.lock()
	if not _ready:
		_counts=build.call().duplicate(true);_ready=true;_computations+=1
	else:_reuses+=1
	var result:=_counts.duplicate(true)
	_mutex.unlock()
	return result

func stats()->Dictionary:
	_mutex.lock()
	var result:={"computations":_computations,"reuses":_reuses}
	_mutex.unlock()
	return result
