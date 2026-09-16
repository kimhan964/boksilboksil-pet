extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Art=preload("res://scripts/animal_catalog.gd")
const Consumption=preload("res://scripts/consumption_art.gd")
const Outline=preload("res://scripts/animation_outline.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1,1)
	var viewport=SubViewport.new()
	viewport.size=Vector2i(204,190)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var baby_mode=OS.get_cmdline_user_args().has("baby")
	var start_species=0 if baby_mode else 8
	var sheet=Image.create(1632,3040 if baby_mode else 1520,false,Image.FORMAT_RGBA8)
	sheet.fill(Color("324454"))
	for species in range(start_species,16):
		var motion=Motion.new()
		motion.species=species
		if OS.get_cmdline_user_args().has("baby"): motion.growth_scale=.62
		motion.food_id=Art.DEFAULT_MEALS[species]
		var view=View.new()
		view.motion=motion
		viewport.add_child(view)
		for bank in [2,1]:
			motion.phase="eat" if bank==2 else "drink"
			motion.visit_id="hand_feed" if bank==2 else "water"
			for step in range(4):
				motion.elapsed=(Consumption.SPEEDS[species-8] if species>=8 else 2.4)*[.0,.19,.4,.7][step]
				view.refresh()
				Outline.fit(view.sprite,View.FEET,Vector2(204,190))
				await process_frame
				await RenderingServer.frame_post_draw
				var cell=viewport.get_texture().get_image()
				sheet.blend_rect(cell,Rect2i(0,0,204,190),Vector2i((step+(4 if bank==1 else 0))*204,(species-start_species)*190))
		view.free()
	DirAccess.make_dir_recursive_absolute("res://builds/meal-review")
	sheet.save_png("res://builds/meal-review/babies.png" if OS.get_cmdline_user_args().has("baby") else "res://builds/meal-review/new-friends.png")
	print("MEAL_PREVIEWS=",(16-start_species)*8)
	quit()
