extends SceneTree
const Main=preload("res://scripts/main.gd")
const State=preload("res://scripts/pet_state.gd")
class MemoryState extends State:
	func load_game() -> void:
		selected=1
		guide_seen=true
		growth["1"]=36
	func save_game() -> void: pass
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=Main.new()
	app.state=MemoryState.new()
	root.add_child(app)
	await process_frame
	app.set_process(false)
	var m=app.pet.motion
	m.cancel_play()
	m.autonomy=true
	m.resting=false
	m.slapstick.cooldown=0
	m.social_cooldown=999
	m.phase="wander"
	m.target=m.feet+Vector2(-150,0)
	var output="res://builds/ui-play-review-20261009/"
	DirAccess.make_dir_recursive_absolute(output)
	var captures=0
	var seen=false
	var age=0.0
	while age<8:
		await process_frame
		age+=root.get_process_delta_time()
		if m.silly_kind=="stumble":
			seen=true
			if m.elapsed>captures*.6 and captures<5:
				await RenderingServer.frame_post_draw
				var im=app.pet.get_texture().get_image()
				im.get_region(im.get_used_rect().grow(16).intersection(Rect2i(Vector2i.ZERO,im.get_size()))).save_png(output+"stumble-%d.png"%captures)
				captures+=1
		elif seen: break
	print("SLAPSTICK_NATIVE_AUTO: ","PASS" if seen and captures>=4 and m.phase=="wander" else "FAIL"," captures=",captures," resumed=",m.phase)
	app.free()
	quit(0 if seen and captures>=4 else 1)
