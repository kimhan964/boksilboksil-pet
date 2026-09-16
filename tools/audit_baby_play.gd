extends SceneTree
const Baby=preload("res://scripts/baby_art.gd")
const Decor=preload("res://scripts/decor_art.gd")
func _initialize() -> void:
	var sheet=Image.create(1024,2048,false,Image.FORMAT_RGBA8)
	sheet.fill(Color("324454"))
	var failures=0
	for species in range(16):
		var frames=Baby.extra_frames(species)
		if frames.size()!=8: failures+=1
		for i in range(frames.size()):
			var pic=frames[i].get_image()
			var used=pic.get_used_rect()
			if not used.has_area() or used.position.x<2 or used.position.y<2 or used.end.x>=pic.get_width()-2 or used.end.y>=pic.get_height()-2: failures+=1
			var factor=minf(120.0/pic.get_width(),120.0/pic.get_height())
			pic.resize(int(pic.get_width()*factor),int(pic.get_height()*factor))
			sheet.blend_rect(pic,Rect2i(Vector2i.ZERO,pic.get_size()),Vector2i(i*128,species*128))
		for kind in ["plant","lamp"]:
			if Decor.icon(kind,species)==null: failures+=1
	sheet.save_png("res://builds/baby-review/extra-poses.png")
	print("NEW_BABY_FRAMES=128 SPECIES_PROPS=32 FAILURES=",failures)
	quit(1 if failures else 0)
