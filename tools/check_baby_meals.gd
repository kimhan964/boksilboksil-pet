extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Catalog=preload("res://scripts/animal_catalog.gd")
var failures=0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i.ONE
	var viewport=SubViewport.new()
	viewport.size=Vector2i(204,190)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	DirAccess.make_dir_recursive_absolute("res://builds/baby-meal-fix")
	for group in range(4):
		var sheet=Image.create(816,760,false,Image.FORMAT_RGBA8)
		sheet.fill(Color("324454"))
		for row in range(4):
			var species=group*4+row
			var motion=Motion.new()
			motion.species=species
			motion.growth_stage=0
			motion.growth_scale=.85
			motion.food_id=Catalog.DEFAULT_MEALS[species]
			var view=View.new()
			view.motion=motion
			viewport.add_child(view)
			for pose in range(4):
				motion.phase="eat" if pose<2 else "drink"
				motion.visit_id="hand_feed" if pose<2 else "water"
				motion.elapsed=0 if pose%2==0 else (.26 if pose<2 else .34)
				view.refresh()
				var rect: Vector4=view.sprite.material.get_shader_parameter("prop_rect")
				if rect.x<0 or rect.y<0 or rect.x+rect.z>1 or rect.y+rect.w>1: failures+=1
				await process_frame
				await RenderingServer.frame_post_draw
				sheet.blend_rect(viewport.get_texture().get_image(),Rect2i(0,0,204,190),Vector2i(pose*204,row*190))
			motion.growth_stage=2
			view.refresh()
			if view.sprite.material.get_shader_parameter("baby_meal"): failures+=1
			view.free()
		sheet.save_png("res://builds/baby-meal-fix/group-%d.png"%group)
	print("BABY_MEAL_POSES=64 FAILURES=",failures)
	quit(0 if failures==0 else 1)
