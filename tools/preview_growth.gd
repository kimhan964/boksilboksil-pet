extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const State=preload("res://scripts/pet_state.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1,1)
	var viewport=SubViewport.new()
	viewport.size=Vector2i(204,190)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var sheet=Image.create(1224,1520,false,Image.FORMAT_RGBA8)
	sheet.fill(Color("324454"))
	for species in range(16):
		var motion=Motion.new()
		motion.species=species
		var view=View.new()
		view.motion=motion
		viewport.add_child(view)
		for stage in range(3):
			motion.growth_scale=State.GROWTH_SCALES[stage]
			view.refresh()
			await process_frame
			await RenderingServer.frame_post_draw
			var cell=viewport.get_texture().get_image()
			sheet.blend_rect(cell,Rect2i(0,0,204,190),Vector2i((stage+(species%2)*3)*204,(species/2)*190))
		view.free()
	DirAccess.make_dir_recursive_absolute("res://builds/growth-review")
	sheet.save_png("res://builds/growth-review/stages.png")
	print("GROWTH_PREVIEWS=48")
	quit()
