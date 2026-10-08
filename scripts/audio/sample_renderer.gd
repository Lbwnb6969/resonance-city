class_name SampleRenderer
extends RefCounted
## One event path for live blocks, previews and offline PCM.

const Transport = preload("res://scripts/audio/sample_transport.gd")

var transport: SampleTransport
var state: Dictionary = {}
var source: Callable

func _init(rate: int = 0) -> void:
	transport = Transport.new(rate)

func render(count: int) -> PackedVector2Array:
	var block := PackedVector2Array()
	block.resize(count)
	for offset in range(count):
		var at := transport.rendered_frames
		for event in transport.take_events(at):
			state[str(event["district_id"])] = int(event["midi"])
		block[offset] = source.call(state, at, transport.sample_rate) if source.is_valid() else Vector2.ZERO
		transport.rendered_frames += 1
	return block

func snapshot() -> Dictionary:
	return {"transport": transport.snapshot(), "state": state.duplicate(true)}

func restore(saved: Dictionary) -> void:
	transport.restore(saved["transport"])
	state = saved["state"].duplicate(true)

static func pcm16(block: PackedVector2Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(block.size() * 4)
	for index in range(block.size()):
		bytes.encode_u16(index * 4, int(clampf(block[index].x, -1.0, 1.0) * 32767.0) & 0xffff)
		bytes.encode_u16(index * 4 + 2, int(clampf(block[index].y, -1.0, 1.0) * 32767.0) & 0xffff)
	return bytes
