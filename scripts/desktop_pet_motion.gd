extends RefCounted

const Personality=preload("res://scripts/personality_behaviors.gd")
var personality_steps: Array=[]
var personality_origin=Vector2.ZERO
var personality_speed=1.0
var personality_active=false
var personality_cooldown=18.0

signal bonded
signal activity_bonded(action: String)
var personality_reward=false
signal visited(id: String)
signal activity_finished(id: String)
var reaction=""
var reaction_time=0.0
var reaction_duration=2.0
var reaction_followup="idle"
var reaction_variant=0
var pending_reaction=""
var affection=0
var can_ask_play=false
var ask_left=45.0
var cursor_position=Vector2.ZERO
const Profiles=preload("res://scripts/companion_profiles.gd")
var habit_cooldown=0.0
var habit_round=0
var habit_start=Vector2.ZERO
var habit_target=Vector2.ZERO
var destinations: Array=[]
var visit_id=""
var visit_action="idle"
var visit_reward=false
var action_left=0.0
var prop_dragging=false
var prop_press=Vector2.ZERO
var prop_last=Vector2.ZERO
var prop_strength=0.0
var prop_progress=0.0
var prop_effort=0.0
var food_id=-1
var favorite_food=false
var autonomy=true
var energy=65.0
var satiety=70.0
var hydration=75.0
var recent_actions: Array=[]
var last_destination=""
var stay_after_visit=false
var favorite_place="cushion"
const SPEEDS=[66.0,52.0,82.0,46.0,54.0,72.0,44.0,50.0,60.0,56.0,62.0,42.0,56.0,48.0,44.0,46.0]
var species=0
var growth_scale=1.0
var growth_stage=-1
var bounds=Rect2(100,160,1080,520)
var feet=Vector2.ZERO
var target=Vector2.ZERO
var phase="idle"
var facing=1.0
var elapsed=0.0
var rest_left=1.0
var joy_left=0.0
var cooldown=0.0
var resting=false
var held=false
var carried=false
var carry_elapsed=0.0
var landing_left=0.0
var ball_visible=false
var ball_velocity=Vector2.ZERO
var ball_height=0.0
var ball_lift=0.0
var ball_position=Vector2.ZERO
var ball_start=Vector2.ZERO
var ball_target=Vector2.ZERO
var throw_origin=Vector2.ZERO
var flight=0.0
var rng=RandomNumberGenerator.new()

func configure(screen: Rect2, initial: Vector2) -> void:
	# Coordinates are desktop pixels, including negative monitor origins.
	bounds=Rect2(screen.position+Vector2(102,160),(screen.size-Vector2(204,190)).max(Vector2.ONE))
	feet=initial.clamp(bounds.position,bounds.end)
	target=feet
	rng.randomize()
	rest_left=rng.randf_range(.6,1.2)
	habit_cooldown=rng.randf_range(2,4)

func pet() -> void:
	if cooldown>0: return
	ask_left=55
	cancel_play()
	react("pet",2.6 if affection>=18 else 1.8)
	joy_left=1.8
	cooldown=2.2
	bonded.emit()

func cancel_play() -> void:
	prop_dragging=false
	prop_strength=0.0
	prop_progress=0.0
	prop_effort=0.0
	personality_reward=false
	personality_steps.clear()
	personality_active=false
	reaction=""
	reaction_followup="idle"
	carried=false
	landing_left=0
	ball_visible=false
	visit_id=""
	visit_reward=false
	stay_after_visit=false
	phase="idle"
	target=feet
	rest_left=rng.randf_range(1,2)

func move_to(point: Vector2) -> void:
	cancel_play()
	feet=point.clamp(bounds.position,bounds.end)
	target=feet

func prepare_ball() -> void:
	cancel_play()
	resting=false
	held=false
	phase="ball_ready"
	ball_visible=true
	ball_height=0
	ball_position=(feet+Vector2(70*facing,0)).clamp(bounds.position,bounds.end)

func release_ball(point: Vector2, velocity: Vector2) -> void:
	held=false
	ball_position=point.clamp(bounds.position,bounds.end)
	ball_velocity=velocity.limit_length(1400)
	ball_height=0
	ball_lift=minf(180,ball_velocity.length()*.18)
	throw_origin=feet
	flight=0
	ask_left=70
	phase="ball_flight" if ball_velocity.length()>=70 else "ball_ready"

func advance_ball(delta: float) -> void:
	# Substeps keep bounces stable if the desktop briefly drops frames.
	var remaining=minf(delta,.25)
	while remaining>0:
		var step=minf(remaining,1.0/120.0)
		remaining-=step
		ball_position+=ball_velocity*step
		ball_velocity*=exp(-3.0*step)
		for axis in [0,1]:
			if ball_position[axis]<bounds.position[axis] or ball_position[axis]>bounds.end[axis]:
				ball_position[axis]=clampf(ball_position[axis],bounds.position[axis],bounds.end[axis])
				ball_velocity[axis]*=-.55
		ball_lift-=620*step
		ball_height+=ball_lift*step
		if ball_height<0:
			ball_height=0
			ball_lift=-ball_lift*.32 if absf(ball_lift)>35 else 0.0
	flight+=delta
	if ball_velocity.length()<18 and ball_height<1 or flight>3:
		ball_height=0
		ball_target=ball_position
		target=ball_target
		phase="chase"

func visit(point: Vector2, action: String, id: String="", reward: bool=false) -> void:
	cancel_play()
	resting=false
	held=false
	target=point.clamp(bounds.position,bounds.end)
	visit_action=action
	visit_id=id
	visit_reward=reward
	phase="visit"

func begin_prop_drag(cursor: Vector2) -> void:
	if phase!="prop_use": return
	prop_dragging=true
	prop_press=cursor
	prop_last=cursor
	action_left=8.0

func drag_prop(cursor: Vector2) -> void:
	if not prop_dragging or phase!="prop_use": return
	var distance=cursor.distance_to(prop_last)
	prop_effort+=minf(distance,30.0)
	prop_progress+=minf(distance,30.0)/18.0
	prop_last=cursor
	prop_strength=clampf((cursor.x-prop_press.x)/maxf(30,70*growth_scale),0,1)

func release_prop_drag() -> void:
	prop_dragging=false
	prop_strength=0
	if phase=="prop_use" and prop_effort>=30:
		visit_reward=true
		action_left=minf(action_left,1.2)

func finish_prop_use() -> void:
	var completed=visit_id
	var reward=visit_reward and (species!=9 or completed!="plant" or prop_effort>=30)
	prop_dragging=false
	prop_strength=0
	visit_reward=false
	visit_id=""
	phase="idle"
	rest_left=2.5
	if reward:
		activity_bonded.emit(completed)
		joy_left=1.8
	activity_finished.emit(completed)

func remember(action: String) -> void:
	recent_actions.append(action)
	if recent_actions.size()>2: recent_actions.pop_front()

func choose_autonomous_action() -> void:
	if personality_cooldown<=0 and energy>30:
		start_personality()
		return
	if can_ask_play and ask_left<=0 and energy>35:
		ask_left=rng.randf_range(55,90)
		var near=feet+(cursor_position-feet).limit_length(100)
		visit(near,"askplay","askplay")
		return
	# Give each friend a visible animation regularly, even without unlocked props.
	if habit_cooldown<=0 and energy>25:
		remember("signature")
		start_habit()
		return
	var options: Array=[]
	if habit_cooldown<=0:
		options.append({"action":"signature","weight":38.0 if energy>35 else 12.0})
	for action in ["wander","look","groom","stretch","doze"]:
		var weight={"wander":42.0,"look":10.0,"groom":12.0,"stretch":8.0,"doze":.4}[action]
		if action=="doze" and energy<40: weight+=(40-energy)*1.2
		if action in recent_actions: weight*=.15
		options.append({"action":action,"weight":weight})
	for destination in destinations:
		var action=destination.action
		var weight=8.0
		if action=="eat": weight+=(100-satiety)*.55
		elif action=="drink": weight+=(100-hydration)*.45
		elif action in ["relax","doze"]:
			weight=2.0 if energy>=40 else 8.0+(40-energy)*1.2
		if destination.id==favorite_place: weight*=1.6
		if destination.id==last_destination: weight*=.12
		if action in recent_actions: weight*=.3
		options.append({"action":action,"weight":weight,"destination":destination})
	var total=0.0
	for option in options: total+=option.weight
	var roll=rng.randf()*total
	var chosen=options.back()
	for option in options:
		roll-=option.weight
		if roll<=0:
			chosen=option
			break
	remember(chosen.action)
	if chosen.action=="signature":
		start_habit()
	elif chosen.has("destination"):
		var destination=chosen.destination
		last_destination=destination.id
		visit(destination.point,destination.action,destination.id)
	elif chosen.action=="wander":
		# Short strolls are more common than crossing the whole desktop.
		var angle=rng.randf_range(-PI,PI)
		var step=Vector2(cos(angle),sin(angle)*.55)*rng.randf_range(65,155)
		target=(feet+step).clamp(bounds.position,bounds.end)
		if feet.distance_to(target)<30: target=(feet-step).clamp(bounds.position,bounds.end)
		phase="wander"
	else:
		phase=chosen.action
		elapsed=0
		action_left=rng.randf_range(6,10) if phase=="doze" else rng.randf_range(1.4,2.8)
		if phase=="doze": react("nest",2.4,"doze")

func react(kind: String, duration: float=2.0, followup: String="idle") -> void:
	ball_visible=false
	reaction=kind
	reaction_time=0
	reaction_duration=duration
	reaction_followup=followup
	reaction_variant=rng.randi_range(0,1)
	phase="react"
	elapsed=0
	target=feet

func start_personality(reward: bool=false) -> void:
	cancel_play()
	personality_reward=reward
	resting=false
	held=false
	personality_origin=feet
	personality_steps=Personality.sequence(species,feet,cursor_position,facing)
	personality_active=true
	personality_cooldown=rng.randf_range(38,60)
	next_personality_step()

func next_personality_step() -> void:
	if personality_steps.is_empty():
		if personality_reward: activity_bonded.emit("personality")
		personality_reward=false
		personality_active=false
		reaction=""
		phase="idle"
		target=feet
		rest_left=rng.randf_range(1,2)
		return
	var step: Dictionary=personality_steps.pop_front()
	if step.has("offset"):
		reaction=""
		phase="wander"
		elapsed=0
		target=(personality_origin+step.offset).clamp(bounds.position,bounds.end)
		personality_speed=step.speed
	else:
		react(step.pose,step.duration)

func advance_personality(delta: float) -> void:
	if phase=="wander":
		if absf(target.x-feet.x)>.5: facing=1.0 if target.x>feet.x else -1.0
		feet=feet.move_toward(target,SPEEDS[species]*lerpf(.72,1.0,inverse_lerp(.62,1.0,growth_scale))*personality_speed*delta)
		if feet.distance_to(target)<.5: next_personality_step()
	elif reaction_time>=reaction_duration:
		next_personality_step()

func start_habit() -> void:
	habit_round+=1
	if habit_round%2==1:
		start_playful()
		habit_cooldown=rng.randf_range(10,18)
		return
	cancel_play()
	phase="signature"
	elapsed=0
	habit_start=feet
	var distance={0:42.0,5:50.0}.get(species,0.0)
	var direction=facing
	if not bounds.has_point(feet+Vector2(direction*distance,0)): direction=-direction
	facing=direction
	habit_target=(feet+Vector2(direction*distance,0)).clamp(bounds.position,bounds.end)
	habit_cooldown=rng.randf_range(10,18)

func start_playful(reward: bool=false) -> void:
	cancel_play()
	resting=false
	held=false
	phase="playful"
	elapsed=0
	action_left=3.0
	visit_id="personality"
	visit_action="playful"
	visit_reward=reward

func advance_habit() -> void:
	var progress=clampf(elapsed/Profiles.HABIT_SECONDS[species],0,1)
	var travel=0.0
	match species:
		0:
			travel=.5*smoothstep(.12,.34,progress)+.5*smoothstep(.46,.68,progress)
		2:
			travel=smoothstep(.08,.36,progress)
		5:
			travel=smoothstep(.42,.68,progress)
	feet=habit_start.lerp(habit_target,travel)
	if progress>=1:
		phase="idle"
		target=feet
		rest_left=rng.randf_range(.8,2)

func advance(delta: float) -> void:
	elapsed+=delta
	if not reaction.is_empty(): reaction_time+=delta
	if carried: carry_elapsed+=delta
	landing_left=maxf(0,landing_left-delta)
	cooldown=maxf(0,cooldown-delta)
	joy_left=maxf(0,joy_left-delta)
	satiety=maxf(0,satiety-delta*.08)
	hydration=maxf(0,hydration-delta*.1)
	energy=maxf(0,energy-delta*(.2 if phase in ["wander","chase","return","visit"] else .025))
	if held: return
	if phase=="prop_use":
		action_left-=delta
		if not prop_dragging: prop_progress+=delta*preload("res://scripts/prop_interactions.gd").SPEEDS[species]
		if prop_dragging: action_left=maxf(action_left,1.0)
		if visit_id=="lamp": energy=minf(100,energy+delta*2)
		if action_left<=0: finish_prop_use()
		return
	if phase=="ball_ready": return
	if phase=="interaction_done":
		var finished=visit_id
		var reward=visit_reward
		visit_id=""
		visit_reward=false
		phase="idle"
		rest_left=2
		if reward: activity_bonded.emit(finished)
		activity_finished.emit(finished)
		return
	if phase=="ball_flight":
		advance_ball(delta)
		return
	if not resting: personality_cooldown=maxf(0,personality_cooldown-delta)
	if personality_active:
		advance_personality(delta)
		return
	if not resting: ask_left=maxf(0,ask_left-delta)
	if phase=="react":
		if reaction_time>=reaction_duration:
			reaction=""
			phase=reaction_followup
			elapsed=0
			rest_left=rng.randf_range(1,2)
			if phase=="doze": action_left=rng.randf_range(7,12)
		return
	if phase=="idle" and not pending_reaction.is_empty():
		var next_reaction=pending_reaction
		pending_reaction=""
		react(next_reaction,2.4)
		return
	habit_cooldown=maxf(0,habit_cooldown-delta)
	if phase=="signature":
		advance_habit()
	elif phase in ["wander","chase","return","visit"]:
		var direction=target-feet
		if absf(direction.x)>.5: facing=1.0 if direction.x>0 else -1.0
		feet=feet.move_toward(target,SPEEDS[species]*lerpf(.72,1.0,inverse_lerp(.62,1.0,growth_scale))*delta*(1.5 if phase in ["chase","return"] else 1.0))
		if phase=="return": ball_position=feet+Vector2(facing*22,-28)
		if feet.distance_to(target)<.5:
			if phase=="visit":
				phase=visit_action
				action_left=rng.randf_range(7,12) if phase=="doze" else (rng.randf_range(3,5) if phase=="relax" else 4.0)
				elapsed=0
				if phase=="prop_use":
					action_left=14.0 if species==9 and visit_id=="plant" else 8.0
					facing=1.0
				visited.emit(visit_id)
				if phase=="doze": react("nest",2.4,"doze")
				elif phase in ["askplay","inspect","pet"]:
					react(phase,2.2,"interaction_done" if visit_reward else "idle")
			elif phase=="chase":
				phase="return"
				target=throw_origin
			elif phase=="return":
				react("askplay",1.8,"ball_ready")
				ball_visible=true
				ball_height=0
				ball_position=(feet+Vector2(70*facing,0)).clamp(bounds.position,bounds.end)
				joy_left=1.8
				activity_bonded.emit("ball")
			else:
				phase="idle"
				rest_left=rng.randf_range(.7,1.8)
	elif phase in ["eat","drink","relax","sniff","look","groom","stretch","doze","cuddle","playful"]:
		action_left-=delta
		# A deliberate bed command keeps the actual sleeping pose until interrupted.
		if phase=="doze" and stay_after_visit: action_left=maxf(1.2,action_left)
		if phase=="doze" and visit_reward and elapsed>=3:
			visit_reward=false
			activity_bonded.emit("doze")
		if phase=="eat": satiety=minf(100,satiety+delta*7)
		elif phase=="drink": hydration=minf(100,hydration+delta*9)
		elif phase in ["relax","doze","cuddle"]: energy=minf(100,energy+delta*(2 if phase=="doze" else 1))
		if action_left<=0:
			var completed_id=visit_id
			if visit_reward:
				activity_bonded.emit(visit_action if visit_action in ["doze","relax","cuddle"] else visit_id)
				joy_left=1.8
			visit_reward=false
			phase="idle"
			rest_left=rng.randf_range(1,2.5)
			if stay_after_visit: resting=true
			stay_after_visit=false
			visit_id=""
			activity_finished.emit(completed_id)
	elif phase=="pet":
		if joy_left<=0:
			phase="idle"
			rest_left=rng.randf_range(1,2)
	elif not resting and autonomy:
		rest_left-=delta
		if rest_left<=0:
			choose_autonomous_action()
