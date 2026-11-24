extends "res://scripts/typing_input.gd"
func start() -> void:
	helper_pid=1
	connected=true
func stop() -> void:
	helper_pid=0
	connected=false
