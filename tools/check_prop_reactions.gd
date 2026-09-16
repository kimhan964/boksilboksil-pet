extends SceneTree
const Motion=preload("res://scripts/desktop_pet_motion.gd")
func _initialize() -> void:
	for pair in [["plant","inspect"],["lamp","pet"],["shelter","pet"],["basket","askplay"]]:
		var motion=Motion.new()
		motion.configure(Rect2(0,0,1280,720),Vector2(600,400))
		motion.autonomy=false
		var rewards: Array=[]
		var finished: Array=[]
		motion.activity_bonded.connect(func(id): rewards.append(id))
		motion.activity_finished.connect(func(id): finished.append(id))
		motion.visit(motion.feet,pair[1],pair[0],true)
		for i in range(240): motion.advance(1.0/60)
		assert(rewards==[pair[0]] and finished==[pair[0]])
		rewards.clear()
		finished.clear()
		motion.visit(motion.feet,pair[1],pair[0],true)
		motion.advance(.1)
		motion.cancel_play()
		for i in range(240): motion.advance(1.0/60)
		assert(rewards.is_empty() and finished.is_empty())
	print("PROP_REACTION_CHECK_PASSED")
	quit()
