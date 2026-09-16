extends Node2D

const Art=preload("res://scripts/animal_catalog.gd")
const BaseArt=preload("res://scripts/base_art.gd")
const Baby=preload("res://scripts/baby_art.gd")
const BabyMeal=preload("res://scripts/baby_meal.gd")
const Metrics=preload("res://scripts/texture_metrics.gd")
const Special=preload("res://scripts/shared_special.gd")
var adult_special: Array=[]
var adult_special_bounds=Rect2i()
const Interactions=preload("res://scripts/prop_interactions.gd")
var interaction_cache: Dictionary={}
var baby_frames: Array=[]
var baby_extra: Array=[]
const Consumption=preload("res://scripts/consumption_art.gd")
const Food=preload("res://scripts/food_catalog.gd")
const Decor=preload("res://scripts/decor_art.gd")
const Profiles=preload("res://scripts/companion_profiles.gd")
const Habits=preload("res://scripts/habit_art.gd")
const Carry=preload("res://scripts/carry_art.gd")
const Sleep=preload("res://scripts/sleep_art.gd")
const Reactions=preload("res://scripts/reaction_art.gd")
var reaction_frames: Array=[]
var sleep_frames: Array=[]
var sleep_bounds=Rect2i()
var carry_frames: Array=[]
var carry_bounds=Rect2i()
var habit_frames: Array=[]
const FEET=Vector2(102,160)
var motion
var ball_only=false
var sprite: Sprite2D
var resource

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	if ball_only: return
	resource=BaseArt.resource(motion.species)
	baby_frames=Baby.frames(motion.species)
	baby_extra=Baby.extra_frames(motion.species)
	adult_special=Special.frames(motion.species)
	if adult_special.size()==4: adult_special_bounds=adult_special[1].get_image().get_used_rect()
	reaction_frames=Reactions.frames(motion.species)
	habit_frames=Habits.frames(motion.species)
	sleep_frames=Sleep.frames(motion.species)
	if sleep_frames.size()==4: sleep_bounds=sleep_frames[0].get_image().get_used_rect()
	carry_frames=Carry.frames(motion.species)
	if carry_frames.size()==4: carry_bounds=carry_frames[3].get_image().get_used_rect()
	sprite=Sprite2D.new()
	sprite.centered=false
	var shader_material=ShaderMaterial.new()
	shader_material.shader=preload("res://scripts/animal_blend.gdshader")
	sprite.material=shader_material
	add_child(sprite)

func refresh() -> void:
	if not ball_only: sprite.material.set_shader_parameter("baby_meal",false)
	var baby_stage=false
	if not ball_only: baby_stage=motion.growth_stage==0 if motion.growth_stage>=0 else motion.growth_scale<.7
	if not ball_only and motion.phase=="prop_use" and show_prop_interaction(baby_stage):
		apply_growth(); queue_redraw()
		return
	if not ball_only and baby_stage and baby_frames.size()==8:
		show_baby()
		apply_growth(); queue_redraw()
		return
	if not ball_only and adult_special.size()==4 and Special.pose(motion)>=0:
		show_adult_special(Special.pose(motion))
		apply_growth(); queue_redraw()
		return
	if not ball_only and motion.phase=="react" and reaction_frames.size()==64:
		show_reaction()
		apply_growth(); queue_redraw()
		return
	if not ball_only and motion.phase=="doze" and sleep_frames.size()==4:
		show_sleep_frame()
		apply_growth(); queue_redraw()
		return
	if not ball_only and (motion.carried or motion.landing_left>0) and carry_frames.size()==4:
		show_carry_frame()
		apply_growth(); queue_redraw()
		return
	if not ball_only and motion.phase=="signature" and habit_frames.size()==8:
		show_habit_frame()
		apply_growth(); queue_redraw()
		return
	if not ball_only:
		var walking=motion.phase in ["wander","chase","return","visit"] and not motion.held
		if motion.phase=="signature" and motion.species==2 and motion.elapsed<1.5: walking=true
		var bank=2 if motion.phase=="eat" else (1 if motion.phase=="drink" else 0)
		if motion.species>=8 and motion.phase=="pet": bank=3
		var frames: Array=resource.frames[bank]
		var animated=walking or bank>0
		var cycle=Art.CYCLE_SECONDS[motion.species] if walking else 2.4
		var phase=fposmod(motion.elapsed/cycle*frames.size(),frames.size()) if animated else 0.0
		var index=floori(phase)
		var next=(index+1)%frames.size() if animated else index
		var blend=smoothstep(.6,1,phase-index)
		var new_meal=motion.species>=8 and bank in [1,2]
		if new_meal:
			var sample=Consumption.sample(motion.species,bank,motion.elapsed)
			index=int(sample.x)
			next=int(sample.y)
			blend=sample.z
		sprite.texture=frames[index]
		var dimensions=sprite.texture.get_size()*(126*Art.HEIGHTS[motion.species]/sprite.texture.get_height())
		if not animated: dimensions*=Vector2(1+sin(motion.elapsed*TAU/4.8)*.004,1-sin(motion.elapsed*TAU/4.8)*.004)
		var at=FEET-Vector2(dimensions.x*.5,dimensions.y)
		if motion.facing<0:
			at.x+=dimensions.x
			dimensions.x=-dimensions.x
		sprite.position=at
		sprite.scale=dimensions/sprite.texture.get_size()
		if motion.phase=="look":
			sprite.position.x+=sin(motion.elapsed*1.8)*2
		elif motion.phase=="sniff": sprite.position.y+=absf(sin(motion.elapsed*3))*2
		elif motion.phase=="stretch":
			var stretch=sin(clampf(motion.elapsed/3,0,1)*PI)
			sprite.scale*=Vector2(1-stretch*.025,1+stretch*.04)
			sprite.position.y-=absf(dimensions.y)*stretch*.04
		elif motion.phase=="doze":
			sprite.scale.y*=.98+sin(motion.elapsed*1.1)*.01
		# Reuse the restaurant's gentle petting sway, squash and lift.
		sprite.rotation=0
		if motion.joy_left>0 or motion.phase in ["groom","cuddle"]:
			var age=(1.8-motion.joy_left)/1.8*2.0 if motion.joy_left>0 else fposmod(motion.elapsed,2)
			var amount=sin(age/2.0*PI)
			sprite.rotation=sin(age*5)*.035*amount*(1 if motion.species%2==0 else -1)
			sprite.position.y-=sin(age*PI)*1.3*amount
			sprite.scale*=Vector2(1+sin(age*6)*.012*amount,1-sin(age*6)*.012*amount)
		sprite.material.set_shader_parameter("next_frame",frames[next])
		sprite.material.set_shader_parameter("frame_mix",blend)
		sprite.material.set_shader_parameter("modern_meal",new_meal)
		var drinking_water=new_meal and bank==1 and motion.visit_id=="water"
		var has_food=bank in [1,2] and motion.food_id>=0 and motion.visit_id in ["bowl","meal","snack","hand_feed"]
		has_food=has_food or drinking_water
		sprite.material.set_shader_parameter("has_meal",has_food)
		if has_food:
			var texture=Decor.icon("water") if drinking_water else Food.icon(motion.food_id)
			var rect=Food.hand_rect(motion.species,bank,index).lerp(Food.hand_rect(motion.species,bank,next),blend)
			var width=rect.z*1.08
			var height=width*absf(dimensions.x)/dimensions.y/(float(texture.get_width())/texture.get_height())
			# The meal shader can only draw inside the animal sprite's UV rectangle.
			# Fit both axes before positioning, including tall drinks and cakes.
			var fit=minf(1.0,minf(.94/width,.92/height))
			if new_meal: fit=minf(fit,.17/height)
			width*=fit
			height*=fit
			var meal_x=clampf(rect.x+(rect.z-width)*.5,.02,.98-width)
			var meal_y=clampf(rect.y+rect.w-height,.02,.98-height)
			sprite.material.set_shader_parameter("menu_texture",texture)
			sprite.material.set_shader_parameter("old_rect",rect)
			sprite.material.set_shader_parameter("prop_rect",Vector4(meal_x,meal_y,width,height))
			sprite.material.set_shader_parameter("food_bite",bank==2)
			sprite.material.set_shader_parameter("bite_color",Color("e9bd79"))
	apply_growth(); queue_redraw()

func show_adult_special(index: int) -> void:
	var texture: Texture2D=adult_special[index]
	var factor=126*Art.HEIGHTS[motion.species]/maxf(1,adult_special_bounds.size.y)
	sprite.texture=texture
	sprite.rotation=0
	sprite.scale=Vector2(factor*motion.facing,factor)
	sprite.position=FEET-Vector2(texture.get_width()*.5,adult_special_bounds.end.y)*sprite.scale
	sprite.material.set_shader_parameter("has_meal",false)
	sprite.material.set_shader_parameter("frame_mix",0.0)
	sprite.material.set_shader_parameter("next_frame",texture)

func accepts_prop_grab(point: Vector2) -> bool:
	if motion.species!=9 or motion.visit_id!="plant": return true
	var area=Metrics.used_rect(sprite.texture)
	var start=sprite.position.x+(area.position.x+area.size.x*.66)*sprite.scale.x
	return point.x>=start-6

func show_prop_interaction(baby: bool) -> bool:
	var key=str(baby)+motion.visit_id
	if not interaction_cache.has(key):
		var sequence=Interactions.frames(motion.species,baby,motion.visit_id)
		if sequence.size()!=4: return false
		interaction_cache[key]={"frames":sequence,"bounds":Interactions.sequence_bounds(sequence)}
	var entry=interaction_cache[key]
	var texture: Texture2D=entry.frames[Interactions.pose(motion)]
	var used: Rect2i=entry.bounds
	var factor=minf(126*Art.HEIGHTS[motion.species]*1.35/maxf(1,used.size.y),184.0/maxf(1,used.size.x))
	sprite.texture=texture
	sprite.rotation=0
	sprite.scale=Vector2.ONE*factor
	sprite.position=FEET-Vector2(used.position.x+used.size.x*.5,used.end.y)*factor
	sprite.material.set_shader_parameter("has_meal",false)
	sprite.material.set_shader_parameter("frame_mix",0.0)
	sprite.material.set_shader_parameter("next_frame",texture)
	return true

func show_reaction() -> void:
	var row=int(Reactions.ROWS.get(motion.reaction,0))
	# This generated sheet placed the nest and gift rows in the opposite order.
	if motion.species==3 and row in [5,6]: row=11-row
	var plan: Array=[0,1,2,3,4,5,6,7]
	if motion.reaction=="inspect":
		row=2
		plan=[0,2,3,3,4,4,2,0]
	if motion.reaction=="pet":
		if motion.affection<6: plan=[0,1,2,3,2,1,7]
		elif motion.affection>=18: plan=[0,1,2,3,4,4,5,4,5,6,7]
		elif motion.reaction_variant==1: plan=[0,1,2,3,4,3,5,6,7]
	var frame_phase=clampf(motion.reaction_time/motion.reaction_duration*plan.size(),0,plan.size()-.001)
	var slot=floori(frame_phase)
	var index=int(plan[slot])
	var next=int(plan[mini(slot+1,plan.size()-1)])
	var blend=smoothstep(.75,1,frame_phase-slot)
	if motion.reaction=="anticipate" and motion.reaction_time>.5:
		var offset=motion.cursor_position-motion.feet
		index=5 if offset.length()<110 else (3 if offset.x*motion.facing<0 else 4)
		next=index
		blend=0
	var neutral: Rect2i=Reactions.bounds[motion.species]
	var texture: Texture2D=reaction_frames[row*8+index]
	var factor=minf(126*Art.HEIGHTS[motion.species]/maxf(1,neutral.size.y),174.0/maxf(1,neutral.size.x))
	sprite.texture=texture
	sprite.rotation=0
	sprite.scale=Vector2(factor*motion.facing,factor)
	sprite.position=FEET-Vector2(texture.get_width()*.5,neutral.end.y)*sprite.scale
	sprite.material.set_shader_parameter("has_meal",false)
	sprite.material.set_shader_parameter("next_frame",reaction_frames[row*8+next])
	sprite.material.set_shader_parameter("frame_mix",blend)

func show_sleep_frame() -> void:
	var index=1
	var next=2
	var blend=(1-cos(motion.elapsed*TAU/3.6))*.5
	if motion.elapsed<.7:
		index=0
		next=1
		blend=smoothstep(.2,.7,motion.elapsed)
	elif not motion.stay_after_visit and motion.action_left<.8:
		index=2
		next=3
		blend=1-smoothstep(.15,.8,motion.action_left)
	var factor=minf(126*Art.HEIGHTS[motion.species]*(.65 if motion.species==0 else .85)/maxf(1,sleep_bounds.size.y),170.0/maxf(1,sleep_bounds.size.x))
	var texture: Texture2D=sleep_frames[index]
	var anchor=Vector2(texture.get_width()*.5,sleep_bounds.end.y)
	sprite.texture=texture
	sprite.rotation=0
	sprite.scale=Vector2(factor*motion.facing,factor)
	sprite.position=FEET-anchor*sprite.scale
	sprite.material.set_shader_parameter("has_meal",false)
	sprite.material.set_shader_parameter("next_frame",sleep_frames[next])
	sprite.material.set_shader_parameter("frame_mix",blend)

func show_carry_frame() -> void:
	var index=3
	if motion.carried:
		index=0 if motion.carry_elapsed<.18 else 1+int((motion.carry_elapsed-.18)/.3)%2
	var texture: Texture2D=carry_frames[index]
	var factor=126*Art.HEIGHTS[motion.species]/maxf(1,carry_bounds.size.y)
	var direction=motion.facing
	# First sheet's alternating pose was drawn facing the other direction.
	if motion.species<4 and index==2: direction=-direction
	var anchor=Vector2(texture.get_width()*.5,carry_bounds.end.y)
	sprite.texture=texture
	sprite.rotation=0
	sprite.scale=Vector2(factor*direction,factor)
	sprite.position=FEET-anchor*sprite.scale
	sprite.material.set_shader_parameter("has_meal",false)
	sprite.material.set_shader_parameter("next_frame",texture)
	sprite.material.set_shader_parameter("frame_mix",0.0)

func show_habit_frame() -> void:
	var phase=clampf(motion.elapsed/Profiles.HABIT_SECONDS[motion.species]*8,0,7.999)
	var index=mini(7,floori(phase))
	var next=mini(7,index+1)
	var texture: Texture2D=habit_frames[index]
	var neutral: Rect2i=Habits.neutral_bounds[motion.species]
	var scale_factor=126*Art.HEIGHTS[motion.species]/maxf(1,neutral.size.y)
	var anchor=Vector2(neutral.position.x+neutral.size.x*.5,neutral.end.y)
	sprite.texture=texture
	sprite.rotation=0
	sprite.scale=Vector2(scale_factor*motion.facing,scale_factor)
	sprite.position=FEET-anchor*sprite.scale
	sprite.material.set_shader_parameter("has_meal",false)
	sprite.material.set_shader_parameter("next_frame",habit_frames[next])
	sprite.material.set_shader_parameter("frame_mix",smoothstep(.78,1,phase-index))

func _draw() -> void:
	if ball_only:
		var ball_art=Decor.icon("ball")
		if ball_art:
			var ball_size=ball_art.get_size()
			ball_size*=28.0/maxf(ball_size.x,ball_size.y)
			draw_texture_rect(ball_art,Rect2((Vector2(32,32)-ball_size)*.5,ball_size),false)
			return
		draw_circle(Vector2(16,16),10,Color("be715f"))
		draw_arc(Vector2(16,16),6,-PI*.8,PI*.1,20,Color("fce6b9"),3,true)
		return
	if motion.phase=="prop_use" and motion.species==9 and motion.visit_id=="plant":
		draw_string(ThemeDB.fallback_font,Vector2(18,18),"오른쪽 매듭을 잡아당겨요",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("fff3d5"))
		draw_line(Vector2(72,174),Vector2(132,174),Color("705d49"),4,true)
		draw_line(Vector2(72,174),Vector2(72+60*motion.prop_strength,174),Color("efc778"),4,true)
	if motion.phase=="doze":
		var top=FEET.y-126*Art.HEIGHTS[motion.species]*motion.growth_scale
		for i in range(2):
			var rise=fposmod(motion.elapsed*7+i*12,24)
			draw_string(ThemeDB.fallback_font,Vector2(121+i*8,maxf(12,top-rise)),"z",HORIZONTAL_ALIGNMENT_LEFT,-1,12+i*2,Color(.72,.78,.9,1-rise/30))
	if motion.joy_left>0:
		for i in range(3):
			var center=FEET+Vector2(-23+i*23,-126*Art.HEIGHTS[motion.species]*motion.growth_scale-8-(1.8-motion.joy_left)*9)
			var points=PackedVector2Array()
			for n in range(33):
				var t=n*TAU/32
				points.append(center+Vector2(16*pow(sin(t),3),-(13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t)))*.32)
			draw_colored_polygon(points,Color(.85,.38,.43,minf(1,motion.joy_left)))

func show_baby() -> void:
	var index=0
	var moving=motion.phase in ["wander","chase","return","visit"] and not motion.held
	if motion.carried or motion.landing_left>0: index=6
	elif motion.phase=="doze": index=7
	elif motion.phase=="eat": index=3
	elif motion.phase=="drink": index=4
	elif moving: index=1+int(motion.elapsed*4)%2
	elif motion.phase in ["pet","cuddle","groom","signature"] or motion.joy_left>0: index=5 if int(motion.elapsed*2)%3!=0 else 0
	elif motion.phase=="react":
		index=5 if motion.reaction in ["pet","yum","greet","gift","full","askplay"] else 0
	var extra=-1
	if not motion.carried and motion.landing_left<=0 and not moving and baby_extra.size()==8:
		var t=motion.reaction_time if motion.phase=="react" else motion.elapsed
		if motion.phase=="eat": extra=int(t*4)%2
		elif motion.phase=="drink": extra=2+int(t*3)%2
		elif Special.pose(motion,true)>=0: extra=4+Special.pose(motion,true)
	var texture: Texture2D=baby_extra[extra] if extra>=0 else baby_frames[index]
	var neutral: Rect2i=Metrics.used_rect(baby_extra[5]) if extra>=0 else Baby.bounds[motion.species]
	var factor=126*Art.HEIGHTS[motion.species]/maxf(1,neutral.size.y)
	var direction=motion.facing
	# This atlas drew the opposite walking step mirrored for its last four species.
	if extra<0 and motion.species>=12 and index==2: direction=-direction
	sprite.texture=texture
	sprite.rotation=0
	sprite.scale=Vector2(factor*direction,factor)
	sprite.position=FEET-Vector2(texture.get_width()*.5,neutral.end.y)*sprite.scale
	if index==7:
		sprite.scale.y*=1+sin(motion.elapsed*TAU/3.8)*.012
		sprite.position.y=FEET.y-neutral.end.y*sprite.scale.y
	sprite.material.set_shader_parameter("next_frame",texture)
	sprite.material.set_shader_parameter("frame_mix",0.0)
	var water=motion.phase=="drink" and motion.visit_id=="water"
	var serving=motion.phase in ["eat","drink"] and motion.food_id>=0 and motion.visit_id in ["bowl","meal","snack","hand_feed"]
	sprite.material.set_shader_parameter("has_meal",water or serving)
	if water or serving:
		var meal=Decor.icon("water") if water else Food.icon(motion.food_id)
		var placement=BabyMeal.placement(motion.species,maxi(extra,0),texture,meal)
		var rect: Vector4=placement.rect
		sprite.material.set_shader_parameter("baby_meal",true)
		sprite.material.set_shader_parameter("baby_grip",placement.grip)
		sprite.material.set_shader_parameter("modern_meal",true)
		sprite.material.set_shader_parameter("menu_texture",meal)
		sprite.material.set_shader_parameter("old_rect",rect)
		sprite.material.set_shader_parameter("prop_rect",rect)
		sprite.material.set_shader_parameter("food_bite",motion.phase=="eat")

func apply_growth() -> void:
	if ball_only or sprite==null: return
	# Keep the feet fixed so all original actions and mouse outlines agree.
	sprite.position=FEET+(sprite.position-FEET)*motion.growth_scale
	sprite.scale*=motion.growth_scale
