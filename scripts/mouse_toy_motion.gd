extends RefCounted
## Clock-driven toy travel; the animal follows one stable target per leg.
const PLAY_SECONDS=22.0
const KEY="home_toy_mouse"
var running=false
var stage=""
var species=-1
var direction=1
var elapsed=0.0
var clock=0.0
var leg_seconds=2.0
var rounds=0
var caught=false
var start_position=Vector2.ZERO
var goal=Vector2.ZERO

func cancel() -> void:
	running=false;stage="";caught=false

func start(room,velocity: float=0.0) -> void:
	if not is_instance_valid(room.app.pet) or not room.pieces.has("toy_mouse"): return
	var m=room.app.pet.motion
	var piece=room.pieces.toy_mouse
	if room.app.decorating or m.held or m.carried or piece.dragging or piece.arriving or not piece.visible: return
	if room.app.commerce_access!=null and not room.app.commerce_access.permits(m.species): return
	room.app.cancel_feeding();room.app.cancel_hunt()
	running=true;species=m.species;elapsed=0.0;rounds=0
	direction=int(signf(velocity)) if absf(velocity)>5 else (1 if not piece.mirrored else -1)
	m.say("쥐가 움직인다! 따라가 볼까?")
	begin_leg(room)

func begin_leg(room) -> void:
	var piece=room.pieces.toy_mouse
	var m=room.app.pet.motion
	start_position=Vector2(piece.position)
	var center=piece.art_point(Vector2(.5,1.0)).x-piece.position.x
	# Shared furniture is backdrop, not a solid obstacle across the entire floor.
	# Keep both the toy and its trailing pet destination within the activity area.
	var lo=maxf(piece.clamp_position(Vector2(-100000,start_position.y)).x,m.bounds.position.x+50-center)
	var hi=minf(piece.clamp_position(Vector2(100000,start_position.y)).x,m.bounds.end.x-50-center)
	if hi-lo<24:
		finish(room);return
	var distance=90.0+float(rounds%3)*12.0
	var x=clampf(start_position.x+direction*distance,lo,hi)
	if absf(x-start_position.x)<36:
		direction=-direction
		x=clampf(start_position.x+direction*distance,lo,hi)
	goal=Vector2(x,start_position.y)
	if absf(x-start_position.x)<8:
		finish(room);return
	direction=1 if goal.x>start_position.x else -1
	piece.set_mirrored(direction<0)
	leg_seconds=maxf(.6,absf(goal.x-start_position.x)/72.0)
	stage="run";clock=0.0;caught=false;rounds+=1
	var point=piece.ground_point()+goal-start_position+Vector2(-direction*42,0)
	m.visit(point.clamp(m.bounds.position,m.bounds.end),"sniff",KEY,true)
	room.app.request_layer_order()

func on_arrival(room) -> void:
	if not running: return
	caught=true
	var m=room.app.pet.motion
	m.phase="sniff";m.elapsed=0.0;m.action_left=2.0;m.facing=direction
	if stage=="wait": begin_inspect(room)

func begin_inspect(room) -> void:
	stage="inspect";clock=0.0
	room.app.pet.motion.say("잡았다, 킁킁!")

func advance(room,delta: float) -> void:
	if not running: return
	if not is_instance_valid(room.app.pet) or not room.pieces.has("toy_mouse"):
		cancel();return
	var m=room.app.pet.motion
	var piece=room.pieces.toy_mouse
	if m.species!=species or m.visit_id!=KEY or m.held or m.carried or piece.dragging or piece.arriving or not piece.visible or room.app.decorating:
		room.save();cancel();return
	if room.app.pet.menu.visible or piece.menu.visible: return
	var dt=maxf(0.0,delta)
	elapsed+=dt;clock+=dt
	if elapsed>=PLAY_SECONDS:
		finish(room);return
	if caught: m.action_left=maxf(m.action_left,2.0)
	if stage=="run":
		var t=clampf(clock/leg_seconds,0.0,1.0)
		# One fixed path and clock avoid rounding feedback and pet-dependent stalls.
		piece.position=Vector2i(start_position.lerp(goal,smoothstep(0.0,1.0,t)).round())
		if t>=1.0:
			piece.position=Vector2i(goal.round());stage="wait";clock=0.0
			if caught: begin_inspect(room)
	elif stage=="wait":
		if caught: begin_inspect(room)
		elif clock>=12.0:
			direction=-direction;begin_leg(room)
	elif stage=="inspect" and clock>=1.0:
		direction=-direction;begin_leg(room)

func finish(room) -> void:
	room.save()
	var m=room.app.pet.motion
	m.react("happy",1.4,"interaction_done")
	m.say("쥐랑 신나게 놀았어")
	cancel()
