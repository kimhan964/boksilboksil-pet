extends Node2D

# Small local effects follow the full character; they never capture desktop input.
var view
var particles: Array=[]
var hover_left=0.0
var sparkle_clock=0.0
var last_action=""
var last_reaction=""
var reaction_elapsed=0.0
const MAX_PARTICLES=28

func burst(kind: String, at: Vector2, count: int=5) -> void:
	for i in range(count):
		var angle=-PI*.9+float(i)/maxi(1,count-1)*PI*.8
		particles.append({"kind":kind,"at":at,"velocity":Vector2(cos(angle),sin(angle))*(24+i*5),"age":0.0,"life":.85+float(i%3)*.12,"spin":float(i)})
	while particles.size()>MAX_PARTICLES: particles.pop_front()

func _process(delta: float) -> void:
	if view and view.sprite and view.sprite.texture:
		var action=str(view.motion.phase)
		var reaction=str(view.motion.reaction) if action=="react" else ""
		if action!=last_action or reaction!=last_reaction:
			reaction_elapsed=0.0
			var center: Vector2=orbit_layout().center
			if action in ["prop_use","playful","signature"]: burst("sparkle",center+Vector2(0,18),5)
			if reaction in ["happy","yum","gift","pet"]: burst("heart",center+Vector2(0,12),5)
			if reaction=="surprised": burst("sparkle",center,4)
			last_action=action
			last_reaction=reaction
		reaction_elapsed+=delta
	for particle in particles:
		particle.age+=delta
		particle.at+=particle.velocity*delta
		particle.velocity.y-=12*delta
	particles=particles.filter(func(p): return p.age<p.life)
	hover_left=maxf(0,hover_left-delta)
	sparkle_clock+=delta
	if view and (not particles.is_empty() or hover_left>0 or view.motion.phase in ["drop","dizzy"] or view.motion.carried): queue_redraw()
	else: queue_redraw() # Clear the final effect frame too.

func orbit_layout() -> Dictionary:
	var rect: Rect2=view.visible_pet_bounds()
	var radius=clampf(rect.size.x*.36,28,43)
	return {"center":Vector2(clampf(rect.get_center().x,54,202),clampf(rect.position.y-8,24,155)),"radius":Vector2(radius,10)}

func star(at: Vector2, radius: float, color: Color, angle: float=0.0) -> void:
	var points=PackedVector2Array()
	for i in range(10):
		var a=angle-PI*.5+i*PI/5
		points.append(at+Vector2(cos(a),sin(a))*radius*(1.0 if i%2==0 else .46))
	draw_colored_polygon(points,color)
	points.append(points[0])
	draw_polyline(points,Color(.52,.36,.24,color.a*.7),1.1,true)

func heart(at: Vector2, radius: float, color: Color) -> void:
	var points=PackedVector2Array()
	for i in range(33):
		var a=i*TAU/32
		points.append(at+Vector2(16*pow(sin(a),3),-(13*cos(a)-5*cos(2*a)-2*cos(3*a)-cos(4*a)))*radius/16)
	draw_colored_polygon(points,color)

func _draw() -> void:
	if not view or not view.sprite: return
	var motion=view.motion
	var layout=orbit_layout()
	var center: Vector2=layout.center
	if motion.phase=="dizzy":
		var fade=clampf((motion.DIZZY_DURATION-motion.elapsed)/.8,0,1)
		var age=motion.elapsed
		var orbit: Vector2=layout.radius
		var trail=PackedVector2Array()
		for j in range(49):
			var a=j*TAU/48
			trail.append(center+Vector2(cos(a),sin(a))*orbit)
		draw_polyline(trail,Color(.99,.82,.41,.30*fade),1.2,true)
		for i in range(3):
			var angle=age*TAU*1.25+i*TAU/3
			for j in range(1,5):
				var previous=angle-j*.14
				draw_circle(center+Vector2(cos(previous),sin(previous))*orbit,1.6,Color(1,.89,.55,(.27-j*.04)*fade))
			var color=[Color("ffe08a"),Color("ffb6c9"),Color("a9e1ec")][i]
			color.a=fade
			star(center+Vector2(cos(angle),sin(angle))*orbit,6+sin(angle)*1.2,color,angle*.7)
		if age<.65:
			for i in range(6):
				var p=Vector2(128+(i-2.5)*(8+age*28),192-age*12-absf(sin(i))*5)
				draw_circle(p,3+age*4,Color(.95,.88,.75,(1-age/.65)*.55))
	elif motion.phase=="drop":
		for i in range(3):
			var x=clampf(center.x+(i-1)*30,12,244)
			var y=clampf(center.y+fposmod(motion.elapsed*120+i*19,50),12,180)
			draw_line(Vector2(x,y),Vector2(x,y+10),Color(1,.88,.62,.55),1.5,true)
	elif motion.carried:
		for i in range(2):
			star(Vector2(center.x+(i*2-1)*32,center.y+sin(sparkle_clock*5+i)*4),4,Color(1,.85,.58,.7),sparkle_clock)
	if hover_left>0 and motion.phase not in ["dizzy","drop"]:
		star(center+Vector2(35,-4),4+sin(sparkle_clock*6),Color(1,.86,.59,minf(1,hover_left)),sparkle_clock*.4)
	if motion.phase=="react" and motion.reaction=="surprised":
		var at=center+Vector2(27,4-sin(reaction_elapsed*6)*2)
		draw_line(at-Vector2(0,6),at+Vector2(0,1),Color("efb75a"),3,true)
		draw_circle(at+Vector2(0,6),1.8,Color("efb75a"))
	elif motion.phase=="react" and motion.reaction=="angry":
		for i in range(3):
			var rise=fposmod(reaction_elapsed*18+i*8,26)
			var at=center+Vector2(28+sin(rise*.2)*3,-rise+14)
			draw_circle(at,2+rise*.10,Color(.97,.84,.81,(1-rise/26)*.8))
	elif motion.phase=="react" and motion.reaction=="sleepy":
		for i in range(3):
			var rise=fposmod(reaction_elapsed*10+i*10,30)
			draw_arc(center+Vector2(24+rise*.25,-rise+12),2+rise*.1,0,TAU,16,Color(.65,.77,.88,(1-rise/30)*.7),1,true)
	for particle in particles:
		var at: Vector2=particle.at
		if at.x<8 or at.x>248 or at.y<8 or at.y>215: continue
		var alpha=sin(clampf(particle.age/particle.life,0,1)*PI)
		if particle.kind=="heart": heart(at,4.5,Color(1,.55,.68,alpha))
		else: star(at,3.5,Color(1,.85,.54,alpha),particle.spin+particle.age*2)
