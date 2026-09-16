extends SceneTree
const Baby=preload("res://scripts/baby_art.gd")
var failures=0
func _initialize() -> void:
	var sheet=Image.create(1024,2048,false,Image.FORMAT_RGBA8)
	sheet.fill(Color("324454"))
	for species in range(16):
		var frames=Baby.frames(species)
		if frames.size()!=8: failures+=1
		for pose in range(frames.size()):
			var image=frames[pose].get_image()
			var used=image.get_used_rect()
			if used.size==Vector2i.ZERO or used.position.x<2 or used.position.y<2 or used.end.x>=image.get_width()-2 or used.end.y>=image.get_height()-2: failures+=1
			var factor=minf(120.0/image.get_width(),120.0/image.get_height())
			image.resize(int(image.get_width()*factor),int(image.get_height()*factor),Image.INTERPOLATE_BILINEAR)
			sheet.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(pose*128,species*128))
	DirAccess.make_dir_recursive_absolute("res://builds/baby-review")
	sheet.save_png("res://builds/baby-review/all-poses.png")
	print("BABY_FRAMES=128 EMPTY_OR_EDGE_FAILURES=",failures)
	quit(1 if failures else 0)
