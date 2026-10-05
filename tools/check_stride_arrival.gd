extends SceneTree
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Art=preload("res://scripts/smooth_species_art.gd")
var checked=0
var largest_error=0.0

func make_motion(species: int,stage: String):
	var m=Motion.new()
	m.smooth_walk_enabled=true
	m.species=species
	m.growth_stage=0 if stage=="baby" else 2
	m.growth_scale=.93 if stage=="baby" else 1.0
	m.autonomy=false
	m.resting=true
	m.feet=Vector2(500,500)
	m.phase="wander"
	return m

func _initialize() -> void:
	Art.select_version(12)
	for species in range(1,16):
		for stage in Art.data(species).get("stages",{}):
			for fps in [30,60,144]:
				for direction in [-1.0,1.0]:
					for fraction in [.01,.25,.49,.51,.75,1.0,1.25,1.51,2.75]:
						var m=make_motion(species,stage)
						var stride=m.smooth_walk_cycle.stride_length(m,Art.spec(m))
						var start=m.feet
						m.target=start+Vector2(direction*stride*fraction,0)
						var steps=0
						while m.phase=="wander":
							var previous=m.feet
							m.advance(1.0/fps)
							assert(m.feet.distance_to(previous)<=stride/(1.6*fps)+.001)
							if m.smooth_walk_cycle.active:
								assert(absf(m.smooth_walk_cycle.origin.distance_to(m.smooth_walk_cycle.destination)-stride)<.001)
							steps+=1
							assert(steps<fps*8)
						assert(m.phase=="idle" and not m.smooth_walk_cycle.active and m.walk_phase==0)
						assert(m.feet.distance_to(m.target)<=stride*.5+.001)
						assert(absf(m.feet.distance_to(start)-roundf(fraction)*stride)<.002)
						largest_error=maxf(largest_error,m.feet.distance_to(m.target))
						checked+=1
				# A screen edge must not cause a compressed step or leave bounds.
				var edge=make_motion(species,stage)
				var stride=edge.smooth_walk_cycle.stride_length(edge,Art.spec(edge))
				edge.feet=Vector2(edge.bounds.end.x-stride*.7,500)
				edge.target=Vector2(edge.bounds.end.x,500)
				var edge_start=edge.feet
				edge.advance(1.0/fps)
				assert(edge.phase=="idle" and edge.feet==edge_start)
				# Changing a goal midway finishes the current contact first.
				var turn=make_motion(species,stage)
				turn.target=turn.feet+Vector2(stride*2,0)
				turn.advance(.4)
				var old_destination=turn.smooth_walk_cycle.destination
				turn.target=Vector2(500-stride,500)
				while turn.smooth_walk_cycle.active:
					turn.advance(1.0/fps)
					assert(turn.facing==1)
				assert(turn.feet.is_equal_approx(old_destination))
				turn.advance(1.0/fps)
				assert(turn.facing==-1)
				# A visit inside the arrival radius must start its requested action.
				var visit=make_motion(species,stage)
				var visit_start=visit.feet
				visit.visit(visit.feet+Vector2(stride*.25,0),"drink","water")
				visit.advance(1.0/fps)
				assert(visit.phase=="drink" and visit.feet==visit_start)
				checked+=3
	print("STRIDE_ARRIVAL_CHECKS_OK ",checked," max_nearest_contact_error_px=",largest_error)
	quit()
