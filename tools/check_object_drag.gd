extends SceneTree
const Prop=preload("res://scripts/desktop_prop.gd")
const Main=preload("res://scripts/main.gd")
const HeldFood=preload("res://scripts/held_food.gd")
var failures=0
var layer_events=0
func _initialize() -> void:
	var app=Main.new()
	var samples=0
	for kind in ["bowl","water","cushion","shelter","basket","plant","lamp"]:
		var prop=Prop.new()
		prop.kind=kind
		prop.layer_changed.connect(func(): layer_events+=1)
		app.props={kind:prop}
		prop.dragging=true
		prop.drag_moved=true
		if not app.objects_are_dragging(): failures+=1
		for origin in [Vector2i(-1920,0),Vector2i.ZERO,Vector2i(1920,-400)]:
			var rect=Rect2i(origin,Vector2i(1920,1080))
			prop.press_position=Vector2(origin)+Vector2(100,100)
			prop.press_screen=Vector2(origin)+Vector2(120,115)
			for i in range(120):
				var cursor=Vector2(origin)+Vector2(i*23-100,i*11-80)
				prop.move_dragged_to(cursor,rect)
				var expected=Vector2i((cursor-Vector2(20,15)).clamp(Vector2(origin),Vector2(rect.end-prop.size)))
				if prop.position!=expected: failures+=1
				prop.move_dragged_to(cursor,rect)
				if prop.position!=expected: failures+=1
				samples+=1
		if layer_events!=0: failures+=1
		prop.finish_drag()
		if layer_events!=1 or app.objects_are_dragging(): failures+=1
		layer_events=0
		# Treat snack-hunt dishes like ordinary movable props.
		app.props={}
		app.hunt=[prop]
		prop.dragging=true
		if not app.objects_are_dragging(): failures+=1
		app.hunt=[]
		prop.free()
	var food=HeldFood.new()
	app.held_food=food
	if not app.objects_are_dragging(): failures+=1
	food.drawing=Node2D.new()
	food.follow_cursor(Vector2(-100,200),true)
	if food.position!=Vector2i(-140,160) or not food.in_reach: failures+=1
	food.follow_cursor(Vector2(-100,200),false)
	if food.position!=Vector2i(-140,160) or food.in_reach: failures+=1
	food.drawing.free()
	food.free()
	app.free()
	print("OBJECT_DRAG_SAMPLES=",samples," FAILURES=",failures)
	quit(0 if failures==0 else 1)
