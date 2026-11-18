extends RefCounted
## One synchronous lane derivation owns these immutable obstacle envelopes.
## The original narrow checks and source order still decide the first blocker.
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
var rows:Array=[]
var envelopes:Array[Rect2]=[]
static func create(obstacles:Array)->RefCounted:
	var prepared=load("res://scripts/world/city_creation_entry_obstacles.gd").new()
	prepared.rows=obstacles
	for row:Dictionary in obstacles:prepared.envelopes.append(Frame.bounds(row.shape))
	return prepared
func along(path:Array[Vector2],half_width:float)->Array:
	var bounds:=Rect2(path[0],Vector2.ZERO)
	for at:Vector2 in path:bounds=bounds.expand(at)
	# Includes both segment strips and the entry's distance-to-shape circle.
	# The existing geometric tolerance also covers float boundary rounding.
	bounds=bounds.grow(half_width+.002)
	var result:Array=[]
	for i in range(rows.size()):
		if bounds.intersects(envelopes[i],true):result.append(rows[i])
	return result
