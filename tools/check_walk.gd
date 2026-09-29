extends SceneTree
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const View=preload("res://scripts/desktop_pet_view.gd")
var failures=0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for species in range(16):
		for fps in [30,60,144]:
			var m=Motion.new()
			m.species=species
			m.feet=Vector2.ZERO
			m.target=Vector2(200,0)
			var first=0.0
			for tick in range(fps*12):
				var previous=m.feet.x
				m.advance_travel(1.0/fps)
				if tick==0: first=m.travel_speed
				if m.feet.x<previous or m.feet.x>200.001: failures+=1
			if m.feet.distance_to(m.target)>.01 or first>=Motion.SPEEDS[species]: failures+=1
	var viewport=SubViewport.new()
	viewport.size=Vector2i(816,760)
	viewport.transparent_bg=false
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var views=[]
	for species in range(16):
		var v=View.new()
		v.motion=Motion.new()
		v.motion.species=species
		v.motion.growth_scale=.62
		v.motion.growth_stage=0
		v.motion.phase="wander"
		v.motion.travel_speed=Motion.SPEEDS[species]
		v.position=Vector2(species%4*204,species/4*190)
		viewport.add_child(v)
		if v.baby_walk.size()!=8: failures+=1
		views.append(v)
	DirAccess.make_dir_recursive_absolute("res://builds/walk-preview")
	for frame in range(32):
		for v in views:
			v.motion.walk_phase=frame/32.0
			v.refresh(1.0/32.0)
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://builds/walk-preview/%02d.png"%frame)
	for v in views:
		v.motion.phase="idle"
		for tick in range(60): v.refresh(1.0/60.0)
		if v.settle_offset.length()>.001: failures+=1
		v.motion.held=true
		v.refresh(1.0/60.0)
		if v.previous_gait.length()>.01: failures+=1
	print("WALK_SPECIES=16 MOTION_CASES=48 SETTLE_CASES=16 FAILURES=",failures)
	quit(1 if failures else 0)
