extends Node
signal changed
var active=false
var approved=true
var target=""
var last_error=""
func valid() -> bool: return active and approved
func set_target(product: String,_token: String) -> void:
	if active and target==product: return
	target=product
	active=true
	changed.emit()
func stop() -> void:
	active=false
	changed.emit()
func grant(value: bool) -> void:
	approved=value
	changed.emit()
