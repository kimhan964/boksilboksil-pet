extends SceneTree
const Art=preload("res://scripts/rabbit_art.gd")
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Outline=preload("res://scripts/animation_outline.gd")
var failures: Array=[]
var count=0
func _initialize() -> void: call_deferred("run")
func require(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	require(Art.data().method=="generated-complete-character-cels","Wrong production method")
	for stage in ["baby","adult"]:
		for action in Art.data().stages[stage].sequences:
			var frames=Art.frames(stage,action)
			require(frames.size()==8,stage+"/"+action+" frame count")
			for i in range(frames.size()):
				var sample=Art.sample_frame(stage,action,i)
				var image: Image=sample.texture.get_image()
				var used=image.get_used_rect()
				require(used.has_area(),stage+"/"+action+" empty")
				require(used.position.x>0 and used.position.y>0 and used.end.x<256 and used.end.y<256,stage+"/"+action+" clipped")
				require(sample.mouth.x>0 and sample.mouth.x<256 and sample.mouth.y>0 and sample.mouth.y<256,stage+"/"+action+" mouth")
				count+=1
	var motion=Motion.new()
	motion.species=0
	var view=View.new()
	view.motion=motion
	root.add_child(view)
	var routes=["idle","wander","eat","drink","doze","pet","cuddle","signature","playful","look","sniff","groom","stretch","rub","askplay","relax","prop_use","react"]
	var runtime_samples=0
	for stage in range(3):
		motion.growth_stage=stage
		motion.growth_scale=[.62,.82,1.0][stage]
		var expected=.55*motion.growth_scale
		for facing in [-1.0,1.0]:
			motion.facing=facing
			for action in routes:
				motion.phase=action
				motion.reaction="pet"
				motion.action_left=4
				motion.food_id=0
				motion.visit_id="plant" if action=="prop_use" else "hand_feed"
				for tick in range(24):
					motion.elapsed=tick*.2
					motion.reaction_time=tick*.08
					motion.walk_phase=tick/24.0
					view.refresh()
					var before=view.sprite.scale
					require(is_equal_approx(absf(before.x),expected) and is_equal_approx(before.y,expected),"Scale changed: "+action)
					require(view.rabbit_sample.stage==("baby" if stage==0 else "adult"),"Stage route changed")
					require(view.sprite.material.get_shader_parameter("frame_mix")==0.0,"Cross fade enabled")
					Outline.fit(view.sprite,View.FEET,Vector2(204,190))
					require(view.sprite.scale.is_equal_approx(before),"Unexpected outline fit: "+action)
					runtime_samples+=1
		# Pickup and landing must select the authored whole-character frames.
		motion.carried=true
		motion.carry_elapsed=.5
		view.refresh()
		require(view.rabbit_sample.action=="carry" and view.rabbit_sample.index in [2,3,4,5],"Carry route")
		motion.carried=false
		motion.landing_left=.2
		view.refresh()
		require(view.rabbit_sample.action=="land" and view.rabbit_sample.index==6,"Landing route")
		motion.landing_left=0
	# A real sleep -> idle transition uses the generated wake-up cells.
	motion.growth_stage=2
	motion.phase="doze"
	motion.elapsed=2
	view.refresh(.016)
	motion.phase="idle"
	view.refresh(.016)
	require(view.rabbit_sample.action=="sleep" and view.rabbit_sample.index==6,"Wake transition")
	for i in range(32): view.refresh(.016)
	require(view.rabbit_sample.action=="idle","Wake transition stuck")
	view.free()
	for failure in failures.slice(0,20): print("RABBIT_FAILURE ",failure)
	print("RABBIT_CELS=",count," RUNTIME_SAMPLES=",runtime_samples," FAILURES=",failures.size())
	quit(1 if not failures.is_empty() else 0)
