extends SceneTree
const Main=preload("res://scripts/main.gd")
const State=preload("res://scripts/pet_state.gd")
class MemoryState extends State:
	func load_game() -> void:
		selected=0;guide_seen=true;home_initialized=true;starter_layout_version=1
		play_affection={"0":200}
	func save_game() -> void: pass
var failures=[]
func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message);push_error(message)
func _initialize(): run.call_deferred()
func run():
	ProjectSettings.set_setting("commerce/enabled",false)
	for file in DirAccess.get_files_at("C:/Users/rlagk/Documents/복슬복슬펫/0.33.0-small-preview/animal-packs"):
		if file.ends_with(".pck"): ProjectSettings.load_resource_pack("C:/Users/rlagk/Documents/복슬복슬펫/0.33.0-small-preview/animal-packs/"+file,false)
	var app=Main.new();app.state=MemoryState.new();root.add_child(app);await process_frame
	app.set_process(false);app.pet.set_process(false)
	var room=app.furniture_room;room.set_process(false);app.delivery_queue.clear()
	for id in room.pieces.keys(): room.remove_piece(id)
	for prop in app.props.values(): prop.hide()
	room.place("toy_mouse",Vector2(650,300),false)
	room.place("sofa",Vector2(740,300),false)
	var piece=room.pieces.toy_mouse;piece.set_process(false)
	var m=app.pet.motion
	var original=piece.position
	for species in range(16):
		for age in [0,2]:
			m.cancel_play();room.toy_play.cancel();m.species=species;m.growth_stage=age;m.autonomy=false
			m.rabbit_pilot=species==0;m.smooth_walk_enabled=species!=0
			m.move_to(Vector2(600,m.bounds.get_center().y));piece.position=original
			# Native click/drag release signal, without advancing the pet: toy must move itself.
			piece.toy_launched.emit(Vector2(170,0))
			check(room.toy_play.mouse_motion.running,"mouse start")
			for tick in range(30): room.toy_play.advance(room,1.0/60)
			check(piece.position.x>original.x+10,"independent travel "+str(species))
			var first_y=piece.position.y
			var rounds=0;var prior_goal=m.target;var last_round=room.toy_play.mouse_motion.rounds
			var saw_inspect=false;var start_feet=m.feet;var max_travel=0.0
			for tick in range(1400):
				var previous=m.feet;var previous_x=piece.position.x
				m.advance(1.0/60);room.toy_play.advance(room,1.0/60)
				max_travel=maxf(max_travel,m.feet.distance_to(start_feet))
				var controller=room.toy_play.mouse_motion
				check(piece.position.y==first_y,"floor changed")
				check(absf(piece.position.x-previous_x)<=4,"toy jump")
				check(m.feet.distance_to(previous)<8,"pet teleported")
				if controller.running and controller.rounds==last_round:
					check(m.target.is_equal_approx(prior_goal),"pursuit target jitter")
				prior_goal=m.target;last_round=controller.rounds;rounds=maxi(rounds,controller.rounds)
				saw_inspect=saw_inspect or controller.stage=="inspect"
				if not controller.running: break
			check(not room.toy_play.busy(),"22 second play did not finish")
			check(rounds>=2 and saw_inspect and max_travel>15,"no chase/catch %d age %d rounds %d inspect %s travel %f"%[species,age,rounds,saw_inspect,max_travel])
	# Screen edge turns inward and stays visible; catch must also work via normal furniture use.
	m.species=0;m.growth_stage=2;m.cancel_play();room.toy_play.cancel()
	piece.position=piece.clamp_position(Vector2(100000,first_floor(piece)))
	room.toy_play.launch_user(room,"toy_mouse",Vector2(170,0))
	check(room.toy_play.mouse_motion.direction==-1,"edge did not turn")
	for tick in range(120): room.toy_play.advance(room,1.0/60)
	check(piece.position==piece.clamp_position(Vector2(piece.position)),"offscreen mouse")
	m.held=true;room.toy_play.advance(room,.1);check(not room.toy_play.busy(),"grab cancellation")
	m.held=false;m.cancel_play();room.toy_play.cancel();piece.position=original
	check(room.use_piece("toy_mouse"),"right-click/use route")
	for tick in range(1600):
		m.advance(1.0/60);room.toy_play.advance(room,1.0/60)
		if room.toy_play.mouse_motion.running: break
	check(room.toy_play.mouse_motion.running,"arrival did not start motor")
	piece.dragging=true;room.toy_play.advance(room,.1);piece.dragging=false
	check(not room.toy_play.busy(),"drag cancellation")
	room.toy_play.launch_user(room,"toy_mouse",Vector2(170,0))
	var paused=piece.position;app.pet.menu.show()
	room.toy_play.advance(room,1);check(piece.position==paused,"menu pause");app.pet.menu.hide()
	room.remove_piece("toy_mouse");room.toy_play.advance(room,.1);check(not room.toy_play.busy(),"remove cancellation")
	# Yarn keeps its existing inertial throw behavior.
	m.cancel_play();room.place("toy_ball",Vector2(650,300),false)
	var ball=room.pieces.toy_ball;ball.set_process(false);var before=ball.position
	room.toy_play.launch_user(room,"toy_ball",Vector2(210,0))
	for tick in range(30): room.toy_play.advance(room,1.0/60)
	check(ball.position.x>before.x+40,"ball throw regression")
	room.toy_play.cancel();app.queue_free();await process_frame
	print("V1_MOUSE_TOY: ","PASS 32 species/age chases + edges, click/use, interruptions, yarn" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
func first_floor(piece) -> float: return float(piece.position.y)
