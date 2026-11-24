extends SceneTree
func _initialize():
	var sheet=Image.new()
	assert(sheet.load("res://assets/combo-v2/source.png")==OK)
	for i in range(4):
		var cel=sheet.get_region(Rect2i((i%2)*sheet.get_width()/2,(i/2)*sheet.get_height()/2,sheet.get_width()/2,sheet.get_height()/2))
		cel.resize(256,256,Image.INTERPOLATE_LANCZOS)
		assert(cel.save_png("res://assets/combo-v2/effect-%d.png"%i)==OK)
	quit()
