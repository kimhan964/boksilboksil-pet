extends SceneTree
func _initialize() -> void:
	for method in DisplayServer.get_method_list():
		if "show_window" in method.name or "window_set_visible" in method.name: print(method.name)
	quit()
