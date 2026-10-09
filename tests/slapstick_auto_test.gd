extends SceneTree
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Slap=preload("res://scripts/slapstick.gd")
var failures=[]
func _initialize() -> void:
	for species in range(16):
		for stage in [0,2]:
			var m=Motion.new()
			m.species=species
			m.growth_stage=stage
			m.growth_scale=.93 if stage==0 else 1.0
			m.rabbit_pilot=species==0
			m.smooth_walk_enabled=species>0
			m.bounds=Rect2(0,0,1600,900)
			m.feet=Vector2(400,700)
			m.target=Vector2(550,700)
			m.phase="wander"
			m.slapstick.cooldown=0
			m.rng.seed=41
			var triggered=false
			for i in range(1200):
				m.advance(1.0/60)
				if m.silly_kind=="stumble":
					triggered=true
					break
			if not triggered: failures.append("automatic stumble %d/%d"%[species,stage])
			Slap.release_other_species(species)
			var frames=Slap.frames(m,"stumble")
			if frames.size()!=60: failures.append("missing 60-frame bank %d/%d"%[species,stage])
	print("SLAPSTICK_AUTO: ","PASS 16 species x 2 ages" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
