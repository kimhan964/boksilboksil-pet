extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Outline=preload("res://scripts/animation_outline.gd")
const Profiles=preload("res://scripts/companion_profiles.gd")
const Reactions=preload("res://scripts/reaction_art.gd")
var checked=0
var failures=0
func check(view) -> void:
	view.refresh()
	if view.sprite==null or view.sprite.texture==null: failures+=1
	Outline.fit(view.sprite,View.FEET,View.WINDOW_SIZE)
	var points=Outline.blended_points(view.sprite)
	if points.is_empty(): failures+=1
	for point in points:
		if point.x<4.9 or point.y<4.9 or point.x>View.WINDOW_SIZE.x-4.9 or point.y>View.WINDOW_SIZE.y-4.9:
			failures+=1
			break
	checked+=1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for species in range(16):
		var motion=Motion.new()
		motion.species=species
		if OS.get_cmdline_user_args().has("baby"):
			motion.growth_scale=.98 if OS.get_cmdline_user_args().has("baby-max") else .93
			motion.growth_stage=0
		else: motion.growth_stage=2
		var view=View.new()
		view.motion=motion
		root.add_child(view)
		for facing in [-1.0,1.0]:
			motion.facing=facing
			for phase in ["wander","drink","eat","pet","signature","doze","carry"]:
				motion.phase=phase
				motion.travel_speed=Motion.SPEEDS[species]
				motion.carried=phase=="carry"
				for step in range(64):
					motion.walk_phase=step/64.0
					motion.elapsed=step/64.0*(Profiles.HABIT_SECONDS[species] if phase=="signature" else 6.0)
					motion.carry_elapsed=motion.elapsed
					motion.action_left=6-motion.elapsed
					check(view)
			motion.carried=false
			motion.phase="react"
			for reaction in Reactions.ROWS:
				motion.reaction=reaction
				for step in range(32):
					motion.reaction_time=step/32.0*motion.reaction_duration
					check(view)
		view.free()
		print("VIEW_CHECK species=",species)
	print("VIEW_SAMPLES=",checked," FAILURES=",failures)
	quit(1 if failures else 0)
