extends SceneTree
# Import generated full-frame strips; alpha and artwork are kept intact.
func _initialize() -> void:
	for animal in ["panda","red_panda"]:
		var folder="res://assets/typing-soft-v2/"+animal
		var sheet=Image.new()
		assert(sheet.load(folder+"/source.png")==OK)
		for i in range(3):
			var edges=[0,710,1408,sheet.get_width()] if animal=="red_panda" else [0,724,1448,sheet.get_width()]
			var x0=edges[i]
			var x1=edges[i+1]
			var cel=sheet.get_region(Rect2i(x0,0,x1-x0,sheet.get_height()))
			var lo=Vector2i(cel.get_width(),cel.get_height())
			var hi=Vector2i.ZERO
			for y in range(cel.get_height()):
				for x in range(cel.get_width()):
					if cel.get_pixel(x,y).a>.5:
						lo=lo.min(Vector2i(x,y))
						hi=hi.max(Vector2i(x,y))
			var bounds=Rect2i(lo,hi-lo+Vector2i.ONE).grow(2).intersection(Rect2i(Vector2i.ZERO,cel.get_size()))
			var content=cel.get_region(bounds)
			content.resize(1080,roundi(content.get_height()*1080.0/content.get_width()),Image.INTERPOLATE_LANCZOS)
			var canvas=Image.create(1280,1280,false,Image.FORMAT_RGBA8)
			canvas.blit_rect(content,Rect2i(Vector2i.ZERO,content.get_size()),Vector2i(100,1184-content.get_height()))
			assert(canvas.save_png(folder+"/"+["idle","left","right"][i]+".png")==OK)
	print("SOFT_FRIENDS_IMPORTED")
	quit()

