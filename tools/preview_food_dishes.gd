extends SceneTree
const Prop=preload("res://scripts/desktop_prop.gd")
const Food=preload("res://scripts/food_catalog.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i.ONE
	var viewport=SubViewport.new()
	viewport.size=Vector2i(112,96)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var prop=Prop.new()
	prop.kind="bowl"
	var drawing=Prop.PropDrawing.new()
	drawing.prop=prop
	viewport.add_child(drawing)
	var sheet=Image.create(448,768,false,Image.FORMAT_RGBA8)
	sheet.fill(Color("324454"))
	for food in range(32):
		prop.food_texture=Food.icon_for(species,food)
		drawing.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		sheet.blend_rect(viewport.get_texture().get_image(),Rect2i(0,0,112,96),Vector2i(food%4*112,food/4*96))
	DirAccess.make_dir_recursive_absolute("res://builds/meal-review")
	sheet.save_png("res://builds/meal-review/dishes.png")
	prop.free()
	print("DISH_PREVIEWS=32")
	quit()
