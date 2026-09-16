extends RefCounted
const Keyed=preload("res://scripts/keyed_art.gd")
static var sheets: Dictionary={}
static func frames(species: int) -> Array:
	var group=species/4
	if not sheets.has(group):
		var path="res://assets/specials/adult-%d.png"%group
		if not FileAccess.file_exists(path): return []
		sheets[group]=Keyed.AnimationRegions.frames(path,Keyed.pixels(path))
	return sheets[group].slice((species%4)*4,(species%4)*4+4)

# The same choreography runs at every age; only the drawings change.
static func pose(motion, baby: bool=false) -> int:
	if motion.carried or motion.landing_left>0 or motion.phase in ["wander","chase","return","visit"]: return -1
	var t=motion.reaction_time if motion.phase=="react" else motion.elapsed
	if motion.phase in ["sniff","look","inspect"] or (motion.phase=="react" and motion.reaction in ["inspect","anticipate"]): return int(t*2)%2
	if motion.phase in ["playful","askplay","pet"] or (baby and motion.phase=="signature") or (motion.phase=="react" and motion.reaction in ["askplay","pet","greet"]):
		var plan=[2,2,3,3,1,0] if motion.species%2==0 else [0,1,2,3,3,1]
		return plan[int(t*4)%plan.size()]
	return -1
