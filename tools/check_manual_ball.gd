extends SceneTree
const Motion=preload("res://scripts/desktop_pet_motion.gd")

func landing(velocity: Vector2, rate: float=60) -> Vector2:
	var pet=Motion.new()
	pet.configure(Rect2(0,0,2400,1400),Vector2(1000,600))
	pet.prepare_ball()
	pet.release_ball(Vector2(1000,600),velocity)
	for i in range(int(rate*4)):
		if pet.phase=="chase": break
		pet.advance(1.0/rate)
	assert(pet.phase=="chase")
	assert(pet.bounds.has_point(pet.ball_position))
	return pet.ball_position

func _initialize() -> void:
	var slow=landing(Vector2(200,0))
	var fast=landing(Vector2(900,0))
	assert(fast.x>slow.x+100)
	assert(landing(Vector2(-600,0)).x<1000)
	assert(landing(Vector2(0,-600)).y<600)
	assert(fast.distance_to(landing(Vector2(900,0),30))<8)
	var pet=Motion.new()
	pet.configure(Rect2(0,0,1280,720),Vector2(600,400))
	pet.prepare_ball()
	pet.release_ball(Vector2(600,400),Vector2.ZERO)
	pet.advance(1)
	assert(pet.phase=="ball_ready" and pet.ball_visible)
	pet.release_ball(Vector2(600,400),Vector2(900,0))
	for i in range(2000):
		pet.advance(1.0/60)
		if pet.phase=="ball_ready": break
	assert(pet.phase=="ball_ready" and pet.ball_visible)
	pet.cancel_play()
	assert(not pet.ball_visible)
	print("MANUAL_BALL_CHECK_PASSED")
	quit()
