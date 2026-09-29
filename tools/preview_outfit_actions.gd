extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Art=preload("res://scripts/animal_catalog.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var species=0
	var arguments=OS.get_cmdline_user_args()
	if arguments.size()>0: species=Art.IDS.find(arguments[0])
	if species<0: species=0
	var viewport=SubViewport.new()
	viewport.size=Vector2i(View.WINDOW_SIZE)*Vector2i(4,6)
	viewport.transparent_bg=false
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background=ColorRect.new()
	background.color=Color("eaf1f3")
	background.size=viewport.size
	viewport.add_child(background)
	var phases=["idle","wander","doze","carry"]
	for stage in [0,2]:
		for style in [1,2,3]:
			for col in range(phases.size()):
				var motion=Motion.new()
				motion.species=species
				motion.growth_stage=stage
				motion.growth_scale=.93 if stage==0 else 1.0
				motion.outfit_style=style
				motion.outfit_color=style-1
				motion.phase=phases[col]
				motion.elapsed=1.2
				motion.walk_phase=.47
				motion.carried=col==3
				motion.carry_elapsed=.35
				motion.travel_speed=Motion.SPEEDS[species] if col==1 else 0.0
				var view=View.new()
				view.motion=motion
				view.position=Vector2(col*View.WINDOW_SIZE.x,(stage/2*3+style-1)*View.WINDOW_SIZE.y)
				viewport.add_child(view)
				view.refresh(1.0/60.0)
	await process_frame
	await process_frame
	await process_frame
	var image=viewport.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://design/runtime-review")
	var error=image.save_png("res://design/runtime-review/"+Art.IDS[species]+"-outfits-actions.png")
	print("OUTFIT_ACTION_PREVIEW=",Art.IDS[species]," ERROR=",error)
	quit(0 if error==OK else 1)
