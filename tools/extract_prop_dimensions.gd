extends SceneTree
func _initialize() -> void:
	var ratios=[]
	for species in range(16):
		var animal=load(preload("res://scripts/animal_catalog.gd").path(species))
		var original: Texture2D=animal.frames[0][0]
		ratios.append(float(original.get_width())/float(original.get_height()))
	print("PROP WIDTH RATIOS ",JSON.stringify(ratios))
	quit()
