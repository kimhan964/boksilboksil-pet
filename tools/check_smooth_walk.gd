extends SceneTree
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Art=preload("res://scripts/smooth_species_art.gd")
var checked=0
func _initialize() -> void:
	var otter_pair=OS.get_cmdline_user_args().has("--walk-v11")
	var all_trial=OS.get_cmdline_user_args().has("--walk-v12")
	if otter_pair: Art.select_version(11)
	if all_trial: Art.select_version(12)
	var expected=0
	for species in range(1,16):
		if otter_pair and species!=1: continue
		for stage in [0,2]:
			if all_trial and not Art.data(species).get("stages",{}).has("baby" if stage==0 else "adult"): continue
			expected+=3
			for fps in [30,60,144]:
				var m=Motion.new()
				m.smooth_walk_enabled=true
				m.species=species
				m.growth_stage=stage
				m.growth_scale=.93 if stage==0 else 1.0
				assert(Art.enabled(m))
				m.feet=Vector2(500,500)
				m.target=Vector2(535,513)
				m.phase="wander"
				var start=m.feet
				var previous=m.feet
				var steps=0
				while not m.travel_complete():
					m.advance_travel(1.0/fps)
					assert(m.feet.distance_to(previous)<2.0)
					assert(m.feet.distance_to(m.target)<=previous.distance_to(m.target)+.001 or m.feet.distance_to(m.target)<=m.smooth_walk_cycle.stride_length(m,Art.spec(m))*.5+.001)
					assert(m.walk_phase>=0 and m.walk_phase<1)
					previous=m.feet
					steps+=1
					assert(steps<fps*20)
				assert(m.walk_phase==0 and not m.smooth_walk_cycle.active)
				m.target=start
				m.advance_travel(1.0/fps)
				assert(m.facing==-1)
				m.move_to(Vector2(600,500))
				assert(not m.smooth_walk_cycle.active)
				m.target=Vector2(620,500)
				m.advance_travel(1.0/fps)
				assert(m.feet.x>=600)
				checked+=1
	assert(checked==expected and checked>0)
	print("SMOOTH_WALK_CHECKS_OK ",checked)
	quit()
