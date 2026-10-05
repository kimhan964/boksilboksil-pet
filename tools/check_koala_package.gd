extends SceneTree
const Smooth=preload("res://scripts/smooth_species_art.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
func _initialize() -> void:
	assert(Smooth.version==12 and Smooth.asset_version(14)==13)
	for stage in [0,2]:
		var m=Motion.new()
		m.species=14
		m.growth_stage=stage
		m.smooth_walk_enabled=true
		m.walk_phase=.999
		assert(Smooth.enabled(m))
		assert(Smooth.frames(14,Smooth.stage(m)).size()==60)
		assert(Smooth.frames(14,Smooth.stage(m),"idle").size()==1)
		assert(Smooth.sample(m,"walk").index==59)
		assert(is_equal_approx(Smooth.spec(m).cycle_seconds,2.45))
		m.outfit_style=1
		assert(not Smooth.enabled(m))
	print("INSTALLED_KOALA_60_CELS_OK baby adult; cycle=2.45; outfit fallback retained")
	quit()
