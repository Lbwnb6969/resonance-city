class_name RunContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Checks = preload("res://tests/generation_checks.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var selected := Contract.selected_case("rng_replay")
	if selected != "rng_replay":
		var invalid := Contract.new("RUN", "invalid")
		invalid.check(false, "P0 only implements rng_replay; full Run cases are pending")
		invalid.finish(self)
		return
	quit(0 if Checks.streams(self) == 0 else 1)
