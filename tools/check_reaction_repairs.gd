extends SceneTree
const Art=preload("res://scripts/reaction_art.gd")
func _initialize() -> void:
	var failures=0
	var sheet=Image.create(1024,512,false,Image.FORMAT_RGBA8)
	sheet.fill(Color("324454"))
	for row in range(4):
		var species=[5,13,15,9][row]
		var offset=8 if species==9 else 56
		var frames=Art.frames(species)
		for i in range(8):
			var img=frames[offset+i].get_image()
			var used=img.get_used_rect()
			if not used.has_area() or used.position.x<=1 or used.position.y<=1 or used.end.x>=img.get_width()-1 or used.end.y>=img.get_height()-1: failures+=1
			var ratio=minf(120.0/img.get_width(),120.0/img.get_height())
			img.resize(int(img.get_width()*ratio),int(img.get_height()*ratio))
			sheet.blend_rect(img,Rect2i(Vector2i.ZERO,img.get_size()),Vector2i(i*128,row*128))
	sheet.save_png("res://builds/frame-audit/repaired-reactions.png")
	print("REPAIRED_REACTION_FRAMES=32 EDGE_FAILURES=",failures)
	quit(0 if failures==0 else 1)
