extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Decor=preload("res://scripts/decor_art.gd")
const KINDS=["surprised","happy","angry","sleepy"]

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var viewport=SubViewport.new()
	viewport.size=Vector2i(1024,448)
	viewport.transparent_bg=false
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background=ColorRect.new()
	background.color=Color("e8ece8")
	background.size=viewport.size
	viewport.add_child(background)
	for stage in range(2):
		for i in range(4):
			var origin=Vector2(i*256,stage*224)
			var motion=Motion.new()
			motion.species=0
			motion.growth_stage=0 if stage==0 else 2
			motion.growth_scale=.93 if stage==0 else 1.0
			motion.phase="react"
			motion.reaction=KINDS[i]
			motion.reaction_duration=2.5
			motion.reaction_time=1.0
			var view=View.new()
			view.motion=motion
			view.position=origin
			viewport.add_child(view)
			view.refresh(1.0/60.0)
			if i==1:
				var toy=Sprite2D.new()
				toy.texture=Decor.icon("acorn")
				toy.scale=Vector2.ONE*minf(46.0/toy.texture.get_width(),55.0/toy.texture.get_height())
				toy.position=origin+Vector2(189,165)
				viewport.add_child(toy)
	await process_frame
	await process_frame
	await process_frame
	var image=viewport.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://design/runtime-review")
	var error=image.save_png("res://design/runtime-review/emotions-acorn-preview.png")
	print("EMOTIONS_ACORN_PREVIEW=",image.get_width(),"x",image.get_height()," ERROR=",error)
	quit(0 if error==OK else 1)
