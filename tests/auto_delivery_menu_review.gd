extends SceneTree
const Main=preload("res://scripts/main.gd")
class MemoryState extends "res://scripts/pet_state.gd":
	func load_game() -> void: pass
	func save_game() -> void: pass
func _initialize() -> void: call_deferred("review")
func review() -> void:
	ProjectSettings.set_setting("commerce/enabled",false)
	var app=Main.new()
	app.state=MemoryState.new()
	app.state.guide_seen=true
	app.state.home_initialized=true
	app.state.starter_layout_version=1
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.pet.set_process(false)
	app.furniture_room.set_process(false)
	var room=app.furniture_room
	for mode in ["home","toys"]:
		room.open(mode)
		await create_timer(.15).timeout
		await RenderingServer.frame_post_draw
		assert(room.panel_done.get_global_rect().end.y<=room.panel.size.y-4,"Panel close button clipped")
		assert(room.auto_delivery_picker.get_global_rect().end.x<=room.panel.size.x-4,"Arrival setting clipped")
		room.panel.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0]+"/settings-"+mode+".png")
	room.auto_delivery_picker.item_selected.emit(0)
	assert(app.state.auto_delivery_limit==0 and app.delivery_queue.is_empty())
	app.set_tool_visible("plant",false)
	room.small_tool_buttons.plant.pressed.emit()
	assert(app.props.plant.visible and app.falling_gifts.is_empty(),"Manual toy started falling")
	assert(app.state.auto_delivery_consumed.is_empty(),"Manual tool consumed arrival budget")
	room.small_tool_buttons.plant.pressed.emit()
	assert(not app.props.plant.visible,"Manual hide failed")
	print("AUTO_DELIVERY_MENU: PASS; settings fit, off, manual show/hide, no falls")
	quit()
