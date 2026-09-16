extends Node
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Main=preload("res://scripts/main.gd")
func _ready() -> void: call_deferred("run")
func run() -> void:
	var failures=0
	var app=Main.new()
	app.free()
	var icon=Image.load_from_file("res://assets/icon/pet-icon.png")
	if icon==null or icon.is_empty(): failures+=1
	for species in range(16):
		print("PACKAGE_SPECIES=",species)
		var motion=Motion.new()
		motion.species=species
		motion.food_id=0
		var view=View.new()
		view.motion=motion
		add_child(view)
		for stage in [0,1,2]:
			motion.growth_stage=stage
			for action in ["idle","eat","drink","doze","playful"]:
				motion.phase=action
				motion.visit_id="hand_feed"
				view.refresh()
				if view.sprite.texture==null: failures+=1
		view.free()
	print("PACKAGE_POSES=240 FAILURES=",failures)
	get_tree().quit(0 if failures==0 else 1)
