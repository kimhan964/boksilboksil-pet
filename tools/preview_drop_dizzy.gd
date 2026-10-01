extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Prop=preload("res://scripts/desktop_prop.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var viewport=SubViewport.new()
	viewport.size=Vector2i(1024,672)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var bg=ColorRect.new()
	bg.size=viewport.size
	bg.color=Color("eaece5")
	viewport.add_child(bg)
	for row in range(3):
		for col in range(4):
			var motion=Motion.new()
			motion.species=[0,1,9][row]
			motion.growth_stage=0 if row==0 else 2
			motion.growth_scale=.93 if row==0 else 1.0
			motion.begin_dizzy()
			motion.elapsed=[.15,1.0,2.25,0.0][col]
			motion.landing_left=maxf(0,Motion.DIZZY_LANDING-motion.elapsed)
			if col==3:
				motion.phase="idle"
				motion.held=true
				motion.joy_left=.8
				motion.landing_left=0
			var view=View.new()
			view.motion=motion
			view.position=Vector2(col*256,row*224)
			viewport.add_child(view)
			view.refresh(1.0/60)
			preload("res://scripts/animation_outline.gd").fit(view.sprite,View.FEET,View.WINDOW_SIZE)
			if col==3:
				view.dizzy_effects.burst("heart",Vector2(128,85),7)
				view.dizzy_effects._process(.3)
	await process_frame
	await process_frame
	await process_frame
	var output=viewport.get_texture().get_image()
	var error=output.save_png("res://design/runtime-review/drop-dizzy-mouse-preview.png")
	print("DROP_DIZZY_PREVIEW=",error)
	quit(error)
