extends SceneTree
const View = preload("res://scripts/desktop_pet_view.gd")
const Motion = preload("res://scripts/desktop_pet_motion.gd")
const SPECIES = ["rabbit", "otter", "squirrel", "hedgehog", "raccoon", "fox", "bear", "owl", "cat", "puppy", "hamster", "panda", "red_panda", "lamb", "koala", "penguin"]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var species_name = "fox"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--species="):
			species_name = arg.trim_prefix("--species=")
	var species_index = SPECIES.find(species_name)
	if species_index < 0:
		printerr("Unknown species: ", species_name)
		quit(1)
		return
	var viewport = SubViewport.new()
	viewport.size = Vector2i(View.WINDOW_SIZE) * Vector2i(4, 2)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background = ColorRect.new()
	background.color = Color("edf2f4")
	background.size = viewport.size
	viewport.add_child(background)
	for row in range(2):
		for col in range(4):
			var motion = Motion.new()
			motion.species = species_index
			motion.growth_stage = 0 if row == 0 else 2
			motion.growth_scale = .93 if row == 0 else 1.0
			motion.outfit_style = 1 if col < 2 else col
			motion.outfit_color = 0
			motion.phase = "wander" if col == 1 else "idle"
			motion.elapsed = .45
			motion.walk_phase = .45
			motion.travel_speed = Motion.SPEEDS[motion.species] if col == 1 else 0.0
			var view = View.new()
			view.motion = motion
			view.position = Vector2(col * View.WINDOW_SIZE.x, row * View.WINDOW_SIZE.y)
			viewport.add_child(view)
			view.refresh(1.0 / 60.0)
	await process_frame
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute("res://design/runtime-review")
	var target = "res://design/runtime-review/dressed-%s-game-preview.png" % species_name
	var error = viewport.get_texture().get_image().save_png(target)
	print("DRESSED_GAME_PREVIEW=", target, " ERROR=", error)
	quit(0 if error == OK else 1)
