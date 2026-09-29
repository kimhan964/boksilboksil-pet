extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var viewport=SubViewport.new()
	viewport.size=Vector2i(View.WINDOW_SIZE)*Vector2i(4,2)
	viewport.transparent_bg=false
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background=ColorRect.new()
	background.color=Color("edf2f4")
	background.size=viewport.size
	viewport.add_child(background)
	for row in range(2):
		for col in range(4):
			var motion=Motion.new()
			motion.species=1 if row==0 else 4
			motion.growth_stage=0 if col%2==0 else 2
			motion.growth_scale=.93 if col%2==0 else 1.0
			motion.outfit_style=1
			motion.outfit_color=0
			motion.phase="wander" if row==0 and col>=2 else "idle"
			motion.elapsed=.45
			motion.walk_phase=.45
			motion.travel_speed=Motion.SPEEDS[motion.species] if motion.phase=="wander" else 0.0
			var view=View.new()
			view.motion=motion
			view.position=Vector2(col*View.WINDOW_SIZE.x,row*View.WINDOW_SIZE.y)
			viewport.add_child(view)
			view.refresh(1.0/60.0)
	await process_frame
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute("res://design/runtime-review")
	var error=viewport.get_texture().get_image().save_png("res://design/runtime-review/dressed-other-species.png")
	print("DRESSED_OTHER_PREVIEW=",error)
	quit(0 if error==OK else 1)
