extends SceneTree
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Dining=preload("res://scripts/dining_species_art.gd")
const Smooth=preload("res://scripts/smooth_species_art.gd")

func _initialize() -> void:
	Smooth.select_version(12)
	var m=Motion.new()
	m.species=7
	m.growth_stage=2
	m.growth_scale=1.0
	assert(not Dining.enabled(m))
	m.smooth_walk_enabled=true
	assert(Dining.enabled(m))
	m.growth_stage=0
	assert(not Dining.enabled(m))
	m.growth_stage=2
	m.outfit_style=1
	assert(not Dining.enabled(m))
	m.outfit_style=0
	var cels=Dining.frames(m)
	assert(cels.size()==120)
	var idle=Smooth.frames(7,"adult","idle")[0].get_image().get_data()
	assert(cels[0].get_image().get_data()==idle)
	assert(cels[119].get_image().get_data()==idle)
	var left=Dining.contact_offset(m,1)
	var right=Dining.contact_offset(m,-1)
	assert(is_equal_approx(left.x,-right.x) and is_equal_approx(left.y,right.y))
	for fps in [30,60,144]:
		m.autonomy=false
		m.resting=true
		m.feet=Vector2(500,500)
		m.visit(m.feet,"drink","water")
		m.advance(1.0/fps)
		assert(m.phase=="drink" and is_equal_approx(m.action_left,6.4))
		var count=0
		while m.phase=="drink":
			var sample=Dining.sample(m,"drink")
			assert(sample.fixed_cels and sample.index>=0 and sample.index<120)
			m.advance(1.0/fps)
			count+=1
			assert(count<fps*7)
		assert(m.phase=="idle" and m.feet==Vector2(500,500))
		assert(absf(float(count)/fps-6.4)<=1.0/fps+.001)
	print("DINING_CHECK_PASS: preview/age/outfit gates, 120 frames, exact idle boundaries, mirrored contact, 30/60/144fps full recovery")
	quit()
