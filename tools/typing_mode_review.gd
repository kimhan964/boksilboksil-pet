extends SceneTree
class ReviewState extends "res://scripts/pet_state.gd":
	func load_game() -> void:
		guide_seen=true
		selected=0
		for i in range(16):
			growth[str(i)]=36
			play_affection[str(i)]=70
		furniture={"sofa":[450,450],"table":[700,450]}
	func save_game() -> void: pass

var app
func _initialize() -> void: run.call_deferred()
func run() -> void:
	app=load("res://scripts/main.gd").new()
	app.state=ReviewState.new()
	root.add_child(app)
	app.set_play_mode("typing")
	if OS.get_cmdline_user_args().has("--capture"):
		await create_timer(2).timeout
		print("TYPING_BRIDGE_CONNECTED=",app.typing_companion.input_bridge.connected)
		var folder="res://builds/typing-review"
		DirAccess.make_dir_recursive_absolute(folder)
		for i in range(10):
			if i==1 or i==5: app.typing_companion.pending=true
			await create_timer(.055).timeout
			await RenderingServer.frame_post_draw
			app.typing_companion.get_texture().get_image().save_png(folder+"/rabbit-%02d.png"%i)
			print("TYPING_POSE ",i," pivot=",app.typing_companion.pivot.position," scale=",app.typing_companion.view.sprite.scale)
		print("TYPING_COUNT=",app.typing_companion.total)
		app.set_play_mode("living")
		await create_timer(.2).timeout
		print("TYPING_HELPER_STOPPED=",not is_instance_valid(app.typing_companion))
		quit()
	if OS.get_cmdline_user_args().has("--automated"):
		await process_frame
		var session_activity=app.typing_activity
		session_activity.update(Time.get_ticks_msec(),5,true)
		var stored=app.state.furniture.duplicate(true)
		var feet=app.pet.motion.feet
		var elapsed=app.pet.motion.elapsed
		await create_timer(.5).timeout
		assert(app.pet.motion.feet==feet and app.pet.motion.elapsed==elapsed,"Life should pause")
		assert(not app.pet.visible)
		for prop in app.props.values(): assert(not prop.visible)
		for piece in app.furniture_room.pieces.values(): assert(not piece.visible)
		for i in range(3):
			app.set_play_mode("living")
			assert(not session_activity.sampling,"Living mode suspends usage time")
			assert(app.pet.visible and app.pet.process_mode!=Node.PROCESS_MODE_DISABLED)
			assert(app.state.furniture==stored,"Layout survives switching")
			app.set_play_mode("typing")
			await process_frame
		for species in [1,14]:
			app.choose_friend(species)
			await process_frame
			assert(app.typing_activity==session_activity and session_activity.total>=5,"Species switch preserves session stats")
			assert(app.typing_companion.view.motion.species==species)
			assert(not app.pet.visible and app.pet.process_mode==Node.PROCESS_MODE_DISABLED)
			var visible_typing=0
			for child in app.get_children():
				if child is Window and child.get_script()==preload("res://scripts/typing_companion.gd") and child.visible: visible_typing+=1
			assert(visible_typing==1,"Only one typing pet may be visible")
		app.set_play_mode("living")
		assert(app.pet.visible)
		assert(app.state.furniture==stored)
		print("TYPING_MODE_ROUNDTRIP_PASS; species switch remains exclusive")
		quit()
