class_name GenerationContractTest
extends SceneTree

const Checks = preload("res://tests/generation_checks.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures := Checks.city(self) + Checks.streams(self)
	quit(0 if failures == 0 else 1)
