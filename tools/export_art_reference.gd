extends SceneTree
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/reference")
	for id in ["rabbit","otter","squirrel","hedgehog","raccoon","fox","bear","owl"]:
		var animal=load("res://assets/animals/"+id+".res")
		animal.frames[0][0].get_image().save_png("res://assets/reference/"+id+".png")
	quit()
