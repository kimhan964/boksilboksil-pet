extends SceneTree
func _initialize() -> void:
	for id in ["cat","puppy","hamster","panda","red_panda","lamb","koala","penguin"]:
		var animal=load("res://assets/animals/"+id+".res")
		var banks=[]
		for bank in animal.frames: banks.append(bank.size())
		print(id," banks=",banks)
		animal.frames[0][0].get_image().save_png("res://assets/reference/"+id+".png")
	quit()
