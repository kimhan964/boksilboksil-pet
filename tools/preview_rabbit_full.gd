extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const ACTIONS=["idle","wander","pet","eat","drink","doze","carry","signature","look","sniff","askplay","groom","stretch","rub","prop_use","relax"]
const LABELS=["대기","걷기","쓰다듬기","먹기","마시기","수면","들기","폴짝","바라보기","킁킁","인사","몸단장","기지개","부비기","장난감","휴식"]
func _initialize() -> void: call_deferred("run")
func create_view(vp: SubViewport, stage: int, action: String, at: Vector2, label: String) -> View:
	var m=Motion.new()
	m.species=0
	m.growth_stage=stage
	m.growth_scale=.62 if stage==0 else 1.0
	m.phase=action
	m.carried=action=="carry"
	m.visit_id="plant" if action=="prop_use" else ("water" if action=="drink" else "hand_feed")
	m.food_id=0
	m.elapsed=1.3
	m.action_left=4
	m.carry_elapsed=.5
	m.reaction="pet"
	m.reaction_time=.9
	m.walk_phase=.3
	var v=View.new()
	v.motion=m
	v.position=at
	vp.add_child(v)
	v.refresh()
	var l=Label.new()
	l.text=label
	l.position=at+Vector2(12,8)
	var font=SystemFont.new()
	font.font_names=PackedStringArray(["Malgun Gothic"])
	l.add_theme_font_override("font",font)
	l.add_theme_color_override("font_color",Color("49564b"))
	l.add_theme_font_size_override("font_size",13)
	vp.add_child(l)
	return v
func run() -> void:
	root.size=Vector2i.ONE
	root.position=Vector2i(-30000,-30000)
	var vp=SubViewport.new()
	vp.size=Vector2i(816,760)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	for stage in [0,2]:
		var bg=ColorRect.new()
		bg.size=Vector2(vp.size)
		bg.color=Color("f6f3ec")
		vp.add_child(bg)
		for i in range(16):
			create_view(vp,stage,ACTIONS[i],Vector2(i%4*204,i/4*190),("새끼 · " if stage==0 else "성체 · ")+LABELS[i])
		await process_frame
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png("res://design/rabbit-v3/"+("baby" if stage==0 else "adult")+"-game-preview.png")
		for child in vp.get_children(): child.queue_free()
		await process_frame
	vp.size=Vector2i(816,380)
	var bg=ColorRect.new()
	bg.size=Vector2(vp.size)
	bg.color=Color("f6f3ec")
	vp.add_child(bg)
	var views: Array=[]
	for stage in [0,2]:
		for col in range(4):
			views.append(create_view(vp,stage,["idle","wander","pet","eat"][col],Vector2(col*204,(0 if stage==0 else 190)),("새끼 · " if stage==0 else "성체 · ")+LABELS[col]))
	DirAccess.make_dir_recursive_absolute("res://design/rabbit-v3/animation-preview")
	for frame in range(96):
		for i in range(views.size()):
			var v=views[i]
			var time=frame/12.0
			v.motion.elapsed=time
			v.motion.walk_phase=fposmod(time/1.0,1)
			if i%4==2:
				v.motion.phase="pet" if time<3 else ("doze" if time<6 else "idle")
				v.motion.elapsed=time if time<3 else (time-3 if time<6 else time-6)
			v.refresh(1.0/12.0)
		await process_frame
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png("res://design/rabbit-v3/animation-preview/%03d.png"%frame)
	print("RABBIT_PREVIEWS_SAVED")
	quit()
