extends SceneTree
const Pet=preload("res://scripts/desktop_pet.gd")
const View=preload("res://scripts/desktop_pet_view.gd")
var failures=0
func _initialize() -> void:
	for species in range(16):
		var pet=Pet.new()
		pet.motion.species=species
		pet.motion.bounds=Rect2(-1500,-500,3000,1500)
		pet.motion.feet=Vector2(400,300)
		pet.sync_position()
		pet.begin_pointer(Vector2(405,260))
		for step in range(100):
			var cursor=Vector2(405,260)+Vector2(step*3-200,sin(step*.2)*60)
			var previous=pet.position
			pet.move_pointer(cursor)
			if pet.position!=previous: failures+=1
			pet.sync_position()
			var expected=Vector2(400,300)+cursor-Vector2(405,260)
			if not pet.motion.feet.is_equal_approx(expected): failures+=1
			var stable=pet.position
			# Simulate a delayed local event after the window has already moved.
			var stale=InputEventMouseMotion.new()
			stale.position=Vector2(70+step,50)
			pet.handle_input(stale)
			pet.move_pointer(cursor)
			pet.sync_position()
			if pet.position!=stable: failures+=1
		pet.free()
	print("DRAG_SAMPLES=1600 FAILURES=",failures)
	quit(0 if failures==0 else 1)
