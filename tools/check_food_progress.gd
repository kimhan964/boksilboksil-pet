extends SceneTree
const State=preload("res://scripts/pet_state.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Food=preload("res://scripts/food_catalog.gd")
var failures=0
func check(ok: bool) -> void:
	if not ok:
		failures+=1
		print_stack()
func _initialize() -> void:
	var s=State.new()
	for species in range(16):
		s.play_affection[str(species)]=3
		s.activity_counts[str(species)]={}
		var count=0
		for food in range(32):
			if s.food_available(species,food): count+=1
		check(count==1 and s.food_available(species,s.Catalog.DEFAULT_MEALS[species]))
		for food in range(32):
			var need=s.food_requirement(species,food)
			s.play_affection[str(species)]=need.x
			s.activity_counts[str(species)]={"hand_feed":need.y}
			check(s.can_action(species,100+food))
			s.play_affection[str(species)]=need.x-1
			check(not s.can_action(species,100+food))
			if need.y>0:
				s.play_affection[str(species)]=need.x
				s.activity_counts[str(species)]={"hand_feed":need.y-1}
				check(not s.can_action(species,100+food))
		var m=Motion.new()
		m.species=species
		m.feet=Vector2(300,300)
		m.initiative_cooldown=0
		m.satiety=20
		m.destinations=[{"point":Vector2(400,300),"action":"eat","id":"bowl"}]
		check(m.try_initiative() and m.visit_id=="bowl" and not m.visit_reward)
		check(not m.try_initiative())
	var pixels=Food.Keyed.pixels("res://assets/food/character-menu-v2.png")
	for y in [224,225,434,435,644,645,854,855,1064,1065,1274,1275,1489,1490]:
		for x in range(pixels.get_width()): check(pixels.get_pixel(x,y).a<.05)
	print("FOOD_UNLOCK_SPECIES=16 FOOD_ROWS=checked FAILURES=",failures)
	quit(1 if failures else 0)
