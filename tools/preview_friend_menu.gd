extends SceneTree
const Pet=preload("res://scripts/desktop_pet.gd")
const State=preload("res://scripts/pet_state.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i.ONE
	var pet=Pet.new()
	pet.state=State.new()
	pet.species=9
	root.add_child(pet)
	pet.set_process(false)
	pet.view.refresh()
	pet.open_menu()
	var menu=pet.menu
	DirAccess.make_dir_recursive_absolute("res://builds/menu-review")
	for section in range(4):
		menu.section=section
		menu.rebuild()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		menu.get_texture().get_image().save_png("res://builds/menu-review/tab-%d.png"%section)
	menu.open_source(menu.get_node("Foods"))
	menu.open_source(menu.get_node("Foods/Species0"))
	await process_frame
	await RenderingServer.frame_post_draw
	menu.get_texture().get_image().save_png("res://builds/menu-review/foods.png")
	print("MENU_PREVIEWS=5")
	var failures=0
	var chosen=[]
	menu.id_pressed.disconnect(pet.menu_action)
	menu.id_pressed.connect(func(id): chosen.append(id))
	for section in range(4):
		menu.section=section
		menu.source=null
		menu.rebuild()
		var row=1
		for id in menu.SECTIONS[section]:
			var index=menu.get_item_index(id)
			if index<0: continue
			var button=menu.body.get_child(row)
			row+=1
			if not menu.entries[index].submenu.is_empty(): continue
			button.pressed.emit()
			if chosen.is_empty() or chosen[-1]!=id: failures+=1
	var meals=[]
	pet.activity_requested.connect(func(id): meals.append(id))
	menu.source=null
	menu.open_source(menu.get_node("Foods/Species0"))
	for i in range(4):
		menu.body.get_child(i+1).pressed.emit()
		if meals.is_empty() or meals[-1]!=100+i: failures+=1
	print("MENU_ACTION_FAILURES=",failures)
	pet.free()
	quit(0 if failures==0 else 1)
