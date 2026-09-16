extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Outline=preload("res://scripts/animation_outline.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var total=0
	for species in [0,5,9,15]:
		var motion=Motion.new()
		motion.species=species
		motion.growth_stage=0
		motion.growth_scale=.62
		motion.phase="eat"
		motion.visit_id="hand_feed"
		motion.food_id=0
		var view=View.new()
		view.motion=motion
		root.add_child(view)
		for i in range(60):
			motion.elapsed=i/60.0
			view.refresh()
			Outline.fit(view.sprite,View.FEET,Vector2(204,190))
		var started=Time.get_ticks_usec()
		for i in range(600):
			motion.elapsed=i/60.0
			view.refresh()
			Outline.fit(view.sprite,View.FEET,Vector2(204,190))
			Geometry2D.convex_hull(Outline.blended_points(view.sprite))
		total+=Time.get_ticks_usec()-started
		view.free()
	print("PET_UPDATE_2400_US=",total)
	quit()
