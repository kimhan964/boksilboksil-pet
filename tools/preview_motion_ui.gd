extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Decor=preload("res://scripts/decor_art.gd")

func _initialize() -> void: call_deferred("run")

func add_pet(viewport: SubViewport, cell: Vector2i, stage: int, phase: String, elapsed: float, outfit: int, color: int, speech: String="") -> void:
	var origin=Vector2(cell)*View.WINDOW_SIZE
	if phase=="drink":
		var pond=Sprite2D.new()
		pond.centered=true
		pond.texture=Decor.icon("water")
		pond.position=origin+Vector2(195,184)
		pond.scale=Vector2.ONE*minf(105.0/pond.texture.get_width(),58.0/pond.texture.get_height())
		viewport.add_child(pond)
	var motion=Motion.new()
	motion.species=0
	motion.growth_stage=stage
	motion.growth_scale=.93 if stage==0 else 1.0
	motion.phase=phase
	motion.elapsed=elapsed
	motion.walk_phase=fposmod(elapsed,1.0)
	motion.travel_speed=Motion.SPEEDS[0] if phase=="wander" else 0.0
	motion.visit_id="water" if phase=="drink" else ""
	motion.voice_left=2.0 if not speech.is_empty() else 0.0
	motion.voice_text=speech
	motion.outfit_style=outfit
	motion.outfit_color=color
	var view=View.new()
	view.motion=motion
	view.position=origin
	viewport.add_child(view)
	view.refresh(1.0/60.0)

func run() -> void:
	var viewport=SubViewport.new()
	viewport.size=Vector2i(View.WINDOW_SIZE)*Vector2i(4,2)
	viewport.transparent_bg=false
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background=ColorRect.new()
	background.color=Color("e8ece8")
	background.size=viewport.size
	viewport.add_child(background)
	add_pet(viewport,Vector2i(0,0),2,"idle",.4,0,0,"안녕!")
	add_pet(viewport,Vector2i(1,0),0,"idle",.4,0,0,"안녕!")
	add_pet(viewport,Vector2i(2,0),2,"playful",.4,1,0)
	add_pet(viewport,Vector2i(3,0),2,"drink",1.6,2,2)
	add_pet(viewport,Vector2i(0,1),0,"drink",1.6,3,3)
	add_pet(viewport,Vector2i(1,1),2,"wander",.42,1,4)
	add_pet(viewport,Vector2i(2,1),2,"idle",.4,2,1)
	add_pet(viewport,Vector2i(3,1),2,"idle",.4,3,5)
	await process_frame
	await process_frame
	await process_frame
	var image=viewport.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://design/runtime-review")
	var error=image.save_png("res://design/runtime-review/motion-ui-preview.png")
	print("MOTION_UI_PREVIEW=",image.get_width(),"x",image.get_height()," ERROR=",error)
	quit(0 if error==OK else 1)
