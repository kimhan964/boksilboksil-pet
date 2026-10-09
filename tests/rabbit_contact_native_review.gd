extends SceneTree
const Main=preload("res://scripts/main.gd")
const State=preload("res://scripts/pet_state.gd")
class MemoryState extends State:
	func load_game() -> void: guide_seen=true
	func save_game() -> void: pass
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var folder="res://builds/rabbit-contact-20261009/"
	DirAccess.make_dir_recursive_absolute(folder)
	var app=Main.new()
	app.state=MemoryState.new()
	root.add_child(app)
	app.set_process(false)
	var rows=[]
	for stage in [0,2]:
		app.state.growth["0"]=0 if stage==0 else 36
		app.choose_friend(0)
		await process_frame
		var pet=app.pet
		pet.set_process(false)
		for direction in [-1,1]:
			var m=pet.motion
			m.cancel_play()
			m.autonomy=false
			m.resting=true
			m.phase="wander"
			m.feet=m.bounds.get_center()
			m.target=m.feet+Vector2(direction*160,0)
			var start=m.feet
			var sheet=Image.create(360*4,220*4,false,Image.FORMAT_RGBA8)
			for tick in range(160):
				pet._process(1.0/60)
				await process_frame
				await RenderingServer.frame_post_draw
				if tick%10==0:
					var i=tick/10
					var crop=Rect2i(Vector2i(start-Vector2(180,190))-pet.position,Vector2i(360,220))
					var frame=pet.get_texture().get_image().get_region(crop)
					sheet.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),Vector2i(i%4*360,i/4*220))
					rows.append({"stage":stage,"direction":direction,"seconds":(tick+1)/60.0,"phase":m.walk_phase,"feet":[m.feet.x,m.feet.y]})
			sheet.save_png(folder+"stage-%d-direction-%d.png"%[stage,direction])
	FileAccess.open(folder+"frames.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
	print("RABBIT_CONTACT_NATIVE: captured both ages and directions")
	app.free()
	quit()
