extends SceneTree
const Pet=preload("res://scripts/desktop_pet.gd")
const State=preload("res://scripts/pet_state.gd")
const Wardrobe=preload("res://scripts/wardrobe_motion_art.gd")
const Hold=preload("res://scripts/hold_transition_art.gd")
class MemoryState extends State:
	func load_game() -> void: pass
	func save_game() -> void: pass
var checks=0
var failures: Array=[]
var rows: Array=[]
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func verify(view,style: String,label: String) -> void:
	ProjectSettings.set_setting("testing/wardrobe_v3",false)
	view.refresh()
	var original=view.sprite.transform
	var original_sample=view.generated_sample.duplicate()
	ProjectSettings.set_setting("testing/wardrobe_v3",true)
	view.refresh()
	check(view.generated_sample.get("wardrobe_v3",false),style+" missing "+label)
	var adjusted=view.sprite.transform
	var padding: Vector2=view.generated_sample.get("wardrobe_padding",Vector2.ZERO)
	adjusted.origin+=adjusted.x*padding.x+adjusted.y*padding.y
	check(original.is_equal_approx(adjusted),style+" changed transform "+label)
	check(view.generated_sample.texture==original_sample.texture,style+" changed source calibration "+label)
	check(view.sprite.material.get_shader_parameter("frame_mix")==0.0,style+" runtime dissolve "+label)
func reset(m) -> void:
	m.cancel_play()
	m.autonomy=false
	m.resting=true
	m.held=false
	m.carried=false
	m.pointer_grab=false
	m.hold_release={}
	m.joy_left=0
	m.landing_left=0
	m.phase="idle"
	m.pilot_start_left=0
	m.pilot_settle_left=0
	m.elapsed=0
	m.visit_id=""
func run() -> void:
	var species=8 if OS.get_cmdline_user_args().has("--cat") else 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--species="): species=int(arg.trim_prefix("--species="))
	var folder="res://builds/wardrobe-v3-native/"+Wardrobe.SPECIES[species]+"/"
	DirAccess.make_dir_recursive_absolute(folder)
	root.transparent_bg=true
	root.mouse_passthrough=true
	root.unfocusable=true
	Engine.max_fps=60
	var state=MemoryState.new()
	state.growth[str(species)]=36
	state.guide_seen=true
	var pet=Pet.new()
	pet.species=species
	pet.state=state
	pet.motion.rabbit_pilot=true
	pet.motion.smooth_walk_enabled=species>0
	root.add_child(pet)
	pet.set_process(false)
	var m=pet.motion
	for style in Wardrobe.STYLES:
		Wardrobe.prewarm(style,species)
		m.set_meta("wardrobe_v3_style",style)
		var sheet=Image.create(1280,1120,false,Image.FORMAT_RGBA8)
		var shot=0
		for direction in [-1,1]:
			reset(m)
			m.phase="wander"
			m.facing=direction
			for i in range(60):
				m.walk_phase=i/60.0
				verify(pet.view,style,"walk/%d/%d"%[direction,i])
				if i%15==0:
					await process_frame
					await RenderingServer.frame_post_draw
					capture(pet,sheet,shot)
					shot+=1
		reset(m)
		m.facing=1
		for action in (["idle","eat","drink"] if species==0 else ["idle"]):
			m.phase=action
			m.food_id=preload("res://scripts/animal_catalog.gd").DEFAULT_MEALS[0]
			m.visit_id="water" if action=="drink" else "hand_feed"
			for i in range(60):
				m.elapsed=i/60.0*4.8
				m.pilot_idle_index=i
				verify(pet.view,style,action+str(i))
			await process_frame
			await RenderingServer.frame_post_draw
			capture(pet,sheet,shot)
			shot+=1
		reset(m)
		m.pointer_grab=true
		m.held=true
		m.carried=true
		m.carry_started_at=0.0
		for i in range(240):
			m.carry_elapsed=i/60.0
			verify(pet.view,style,"hold/"+str(i))
			if i in [10,80,160,200]:
				await process_frame
				await RenderingServer.frame_post_draw
				capture(pet,sheet,shot)
				shot+=1
		# Every release quarter, including the shared exact bridge endpoints.
		for quarter in range(4):
			for i in range(17):
				var sample=Hold.bridge(m,"release%d"%quarter,i/16.0)
				var pose=Wardrobe.resolve(m,sample)
				check(Wardrobe.frames(style,pose.bank,species).size()==17,"release bank "+style)
		reset(m)
		m.phase="dizzy"
		for i in range(240):
			m.elapsed=m.DIZZY_LANDING+i/60.0
			verify(pet.view,style,"dizzy/"+str(i))
			if i in [10,60,100,230]:
				await process_frame
				await RenderingServer.frame_post_draw
				capture(pet,sheet,shot)
				shot+=1
		reset(m)
		for emotion in Wardrobe.EMOTIONS:
			m.react(emotion,2.4)
			m.reaction_time=1.0
			verify(pet.view,style,emotion)
			await process_frame
			await RenderingServer.frame_post_draw
			capture(pet,sheet,shot)
			shot+=1
		# Replay real pointer entry/release and motion.advance, not just static samples.
		var timeline=Image.create(1280,1120,false,Image.FORMAT_RGBA8)
		var timeline_shot=0
		reset(m)
		m.move_to(Vector2(m.bounds.get_center().x,m.bounds.position.y))
		m.phase="wander"
		m.target=m.feet+Vector2(80,0)
		var origin=m.feet
		for tick in range(180):
			pet.advance_frame(1.0/60)
			check(pet.view.generated_sample.get("wardrobe_v3",false),style+" live walk missing "+str(tick))
		check(m.feet.x>origin.x+15,style+" no desktop translation")
		pet.begin_pointer(m.feet-Vector2(0,60))
		for tick in range(240):
			pet.move_pointer(pet.press_screen+Vector2(0,-60),1.0/60)
			pet.advance_frame(1.0/60)
			check(pet.view.generated_sample.get("wardrobe_v3",false),style+" live hold missing "+str(tick))
			if tick%30==0:
				await process_frame
				await RenderingServer.frame_post_draw
				capture(pet,timeline,timeline_shot)
				timeline_shot+=1
		pet.release_pointer()
		for tick in range(420):
			pet.advance_frame(1.0/60)
			check(pet.view.generated_sample.get("wardrobe_v3",false),style+" live release missing "+str(tick)+"/"+m.phase)
			if tick%30==0:
				await process_frame
				await RenderingServer.frame_post_draw
				capture(pet,timeline,timeline_shot)
				timeline_shot+=1
		timeline.save_png(folder+style+"-pointer.png")
		sheet.save_png(folder+style+".png")
		rows.append({"style":style,"native_captures":shot})
	var report={"checks":checks,"failures":failures,"styles":rows,"scope":Wardrobe.SPECIES[species]+" adult; original transforms versus dressed renderer"}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("WARDROBE_NATIVE ",JSON.stringify(report))
	pet.free()
	quit(0 if failures.is_empty() else 1)
func capture(pet,sheet: Image,index: int) -> void:
	var origin=Vector2i(pet.view.position)
	var frame=pet.get_texture().get_image().get_region(Rect2i(origin,Vector2i(256,224)))
	sheet.blit_rect(frame,Rect2i(0,0,256,224),Vector2i(index%5*256,index/5*224))
