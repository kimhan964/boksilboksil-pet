extends SceneTree
const State=preload("res://scripts/pet_state.gd")
var failures=0
func check(condition: bool, message: String) -> void:
	if not condition:
		failures+=1
		push_error(message)
func _initialize() -> void:
	var state=State.new()
	state.save_path="user://growth-check-only.json"
	for species in range(16):
		check(state.growth_stage(species)==0,"New animal must be a baby")
		state.add_growth(species,11)
		check(state.growth_stage(species)==0,"Baby boundary")
		check(state.growth_scale(species)>.62 and state.growth_scale(species)<.82,"Gradual baby growth")
		state.add_growth(species,1)
		check(state.growth_stage(species)==1,"Middle boundary")
		state.add_growth(species,23)
		check(state.growth_stage(species)==1,"Middle upper boundary")
		check(state.growth_scale(species)>.82 and state.growth_scale(species)<1,"Gradual middle growth")
		state.add_growth(species,1)
		check(state.growth_stage(species)==2,"Adult boundary")
	state.save_game()
	var restored=State.new()
	restored.save_path=state.save_path
	restored.load_game()
	check(restored.growth==state.growth,"Growth save round trip")
	state.growth.clear()
	state.reward_activity(9,"decorate")
	check(state.growth_stage(9)==0 and state.growth.is_empty(),"Decorating must not grow animals")
	state.reward_activity(9,"hand_feed")
	state.reward_activity(9,"hand_feed")
	check(state.growth.get("9")==2,"Feeding reward and cooldown")
	check(not state.growth.has("8"),"Animal independence")
	var legacy=FileAccess.open(state.save_path,FileAccess.WRITE)
	legacy.store_string('{"version":2,"affection":{"9":87},"meals":{"9":24}}')
	legacy.close()
	var migrated=State.new()
	migrated.save_path=state.save_path
	migrated.load_game()
	check(migrated.play_affection.get("9")==87 and migrated.growth_stage(9)==0,"Legacy affection preserved; growth begins at baby")
	DirAccess.remove_absolute(state.save_path)
	print("GROWTH_CHECK 16 species; thresholds, save, cooldown, isolation, migration. FAILURES=",failures)
	quit(1 if failures else 0)
