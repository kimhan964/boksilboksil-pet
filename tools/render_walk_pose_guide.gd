extends SceneTree
func _initialize() -> void:
	for name in ["biped-contact-guide","quadruped-contact-guide"]:
		var source="res://design/walk-v6/"+name
		if not FileAccess.file_exists(source+".svg"): continue
		var image=Image.new()
		assert(image.load_svg_from_string(FileAccess.get_file_as_string(source+".svg"))==OK)
		image.save_png(source+".png")
	quit()
