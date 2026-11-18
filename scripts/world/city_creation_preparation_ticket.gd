extends RefCounted
## A worker owns its snapshot; cancellation only tells it to stop preparing it.
var _mutex:=Mutex.new()
var _cancelled:=false

func cancel()->void:
	_mutex.lock();_cancelled=true;_mutex.unlock()

func cancelled()->bool:
	_mutex.lock();var value:=_cancelled;_mutex.unlock();return value
