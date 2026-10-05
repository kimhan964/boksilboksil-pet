extends SceneTree
func _initialize() -> void:
	for index in [0,6]:
		var path="res://design/walk-v10/contact-guide-%02d"%index
		var image=Image.new()
		assert(image.load_svg_from_string(FileAccess.get_file_as_string(path+".svg"))==OK)
		image.save_png(path+".png")
	quit()
