extends SceneTree
const Art=preload("res://scripts/decor_art.gd")
func _initialize() -> void:
	var house=Art.icon("shelter",9)
	assert(house!=null)
	var pixels=house.get_image()
	# A complete house is wider than tall; the old cut included the tent poles
	# below and clipped the roof, leaving a taller, disconnected rectangle.
	assert(pixels.get_width()>pixels.get_height())
	DirAccess.make_dir_recursive_absolute("res://builds/asset-check")
	pixels.save_png("res://builds/asset-check/puppy-house.png")
	print("HOUSE_ATLAS_CHECK_PASSED")
	quit()
