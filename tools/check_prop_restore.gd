extends SceneTree
const Main=preload("res://scripts/main.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
class FakeProp extends RefCounted:
	var visible=true
	var in_use=false
	func set_in_use(value: bool) -> void: in_use=value
	func set_drop_hover(_value: bool) -> void: pass
class FakePet extends RefCounted:
	var motion=Motion.new()
	var dragging=false
func _initialize() -> void:
	var app=Main.new()
	app.layers_dirty=false
	app.pet=FakePet.new()
	app.props={"plant":FakeProp.new(),"lamp":FakeProp.new()}
	var failures=0
	for kind in ["plant","lamp"]:
		app.pet.motion.phase="prop_use"
		app.pet.motion.visit_id=kind
		app._process(0)
		if not app.props[kind].in_use: failures+=1
		app.pet.motion.cancel_play()
		app._process(0)
		if app.props[kind].in_use: failures+=1
		app.pet.motion.phase="prop_use"
		app.pet.motion.visit_id=kind
		app.props[kind].visible=false
		app._process(0)
		if app.pet.motion.phase!="idle" or app.props[kind].in_use: failures+=1
		app.props[kind].visible=true
	app.free()
	print("PROP_RESTORE_FAILURES=",failures)
	quit(0 if failures==0 else 1)
