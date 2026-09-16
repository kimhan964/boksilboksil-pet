extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Special=preload("res://scripts/shared_special.gd")
const Outline=preload("res://scripts/animation_outline.gd")
var failures=0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var samples=0
	for species in range(16):
		var motion=Motion.new()
		motion.species=species
		motion.autonomy=false
		var view=View.new()
		view.motion=motion
		root.add_child(view)
		if view.adult_special.size()!=4: failures+=1
		for stage in range(3):
			motion.growth_stage=stage
			motion.growth_scale=[.62,.82,1.0][stage]
			for phase in ["playful","sniff","look"]:
				motion.phase=phase
				for frame in range(12):
					motion.elapsed=frame*.25
					view.refresh()
					var index=Special.pose(motion,stage==0)
					var expected=view.baby_extra[index+4] if stage==0 else view.adult_special[index]
					if view.sprite.texture!=expected: failures+=1
					Outline.fit(view.sprite,View.FEET,Vector2(204,190))
					for p in Outline.blended_points(view.sprite):
						if p.x<4.9 or p.y<4.9 or p.x>199.1 or p.y>185.1: failures+=1
					samples+=1
		motion.start_habit()
		if motion.phase!="playful": failures+=1
		motion.start_habit()
		if motion.phase!="signature": failures+=1
		motion.start_playful()
		motion.advance(3.1)
		if motion.phase!="idle": failures+=1
		view.free()
	print("SHARED_SPECIAL_SAMPLES=",samples," FAILURES=",failures)
	quit(0 if failures==0 else 1)
