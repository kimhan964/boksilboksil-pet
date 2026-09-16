extends SceneTree
const Carry=preload("res://scripts/carry_art.gd")
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/asset-check")
	for species in range(16):
		var frames=Carry.frames(species)
		assert(frames.size()==4)
		for texture in frames:
			var used=texture.get_image().get_used_rect()
			assert(used.has_area())
			# No fragment should touch the row's top or bottom cut.
			assert(used.position.y>0 and used.end.y<texture.get_height())
		if species==9:
			for i in range(4): frames[i].get_image().save_png("res://builds/asset-check/puppy-carry-%d.png"%i)
	print("CARRY_ATLAS_CHECK_PASSED")
	quit()
