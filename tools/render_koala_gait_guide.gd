extends SceneTree
func _initialize() -> void:
	var image=Image.new()
	assert(image.load_svg_from_string(FileAccess.get_file_as_string("res://design/walk-v13/koala/guide.svg"))==OK)
	image.save_png("res://design/walk-v13/koala/guide.png")
	quit()
