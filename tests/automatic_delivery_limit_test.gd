extends SceneTree
const State=preload("res://scripts/pet_state.gd")
const Main=preload("res://scripts/main.gd")
const Arrivals=preload("res://scripts/furniture_arrivals.gd")
class FakeRoom extends RefCounted:
	var app
	var pieces={}
	var placements=0
	func place(_id,_point,_persist): placements+=1
func _initialize() -> void:
	var state=State.new()
	state.save_path="user://auto-delivery-limit-test-%d.json"%Time.get_ticks_usec()
	assert(state.auto_delivery_limit==5)
	for key in ["prop:acorn","furniture:toy_ball","prop:basket","furniture:toy_mouse","prop:plant"]:
		assert(state.record_auto_delivery(key))
	assert(not state.record_auto_delivery("furniture:alarm_clock"),"Sixth arrival exceeded shared budget")
	assert(state.auto_delivery_consumed.size()==5)
	assert(not state.record_auto_delivery("prop:acorn"),"Duplicate replay")
	var loaded=State.new()
	loaded.save_path=state.save_path
	loaded.load_game()
	assert(loaded.auto_delivery_consumed.size()==5 and not loaded.can_auto_deliver("furniture:alarm_clock"),"Restart reset budget")
	loaded.auto_delivery_limit=0
	loaded.auto_delivery_consumed.clear()
	assert(not loaded.can_auto_deliver("prop:plant"),"Off setting still allowed props")
	loaded.play_affection={"0":100}
	var app=Main.new()
	app.state=loaded
	app.props={"acorn":true,"basket":true,"plant":true}
	app.queue_welcome_tools()
	assert(app.delivery_queue.is_empty(),"Off setting queued welcome drops")
	var room=FakeRoom.new()
	room.app=app
	assert(not Arrivals.new().start(room,"alarm_clock") and room.placements==0,"Furniture channel ignored off setting")
	loaded.auto_delivery_limit=3
	loaded.manual_tools["plant"]=true
	assert(not loaded.can_auto_deliver("prop:plant"),"Manually selected toy requeued")
	assert(loaded.auto_delivery_consumed.is_empty(),"Manual selection consumed automatic budget")
	loaded.save_game()
	var again=State.new()
	again.save_path=state.save_path
	again.load_game()
	assert(again.auto_delivery_limit==3 and again.manual_tools.has("plant"),"Preferences lost on restart")
	DirAccess.remove_absolute(state.save_path)
	app.free()
	print("AUTO_DELIVERY_LIMIT: PASS; shared 5, off, restart, duplicate, manual selection")
	quit()
