class_name AudioGrowthMask
extends Sprite2D
## Rendering primitive only; no CITY-004 trigger or growth rules.
const Transport = preload("res://scripts/audio/sample_transport.gd")

@export var use_master_clock := true
var STEP_FRAMES: int
var start_frame := -1
var progress := 0.0

func _init() -> void:
	var transport := Transport.new()
	STEP_FRAMES = transport.beat_frame(1)-transport.beat_frame(0)

func _ready() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = load("res://资源/着色器/音频一拍揭示.gdshader")
	material = shader_material
	shader_material.set_shader_parameter("growth_progress",progress)

func begin_at(audio_frame: int) -> void:
	start_frame = audio_frame
	sample_frame(float(audio_frame))

func end_frame() -> int:
	return start_frame+STEP_FRAMES

func sample_frame(audio_frame: float) -> float:
	progress = clampf((audio_frame-float(start_frame))/float(STEP_FRAMES),0.0,1.0) if start_frame >= 0 else 0.0
	if material is ShaderMaterial:
		material.set_shader_parameter("growth_progress",progress)
	return progress

func _process(_delta: float) -> void:
	if not use_master_clock or start_frame < 0:
		return
	var clock := get_node_or_null("/root/AudioClock") as AudibleAudioClock
	if clock != null and clock.renderer != null:
		sample_frame(clock.renderer.transport.audible_frame)
