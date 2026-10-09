extends SceneTree
const State=preload("res://scripts/pet_state.gd")
const Rules=preload("res://scripts/home_unlocks.gd")
class MemoryState extends State:
	func save_game() -> void: pass
func _initialize() -> void:
	ProjectSettings.set_setting("testing/unlock_all",false)
	var state=MemoryState.new()
	for id in ["sofa","table","play_rug"]: assert(state.furniture_available(id))
	for id in Rules.RULES: assert(not state.furniture_available(id))
	# Every individual gate is closed immediately before its boundary.
	for id in Rules.RULES:
		var rule=Rules.RULES[id]
		var action=Rules.GROUPS[rule[0]].actions[0]
		state.activity_counts={"0":{action:rule[1]-1}}
		assert(not state.furniture_available(id),id+" opened early")
		state.activity_counts["0"][action]+=1
		assert(state.furniture_available(id),id+" failed at exact threshold")
	# Two species share progress and real completion emits the new gift once.
	state.activity_counts={"0":{"acorn":1},"1":{"home_play":1}}
	var events=[]
	state.affection_changed.connect(func(_species,gifts): events.append(gifts))
	state.reward_activity(1,"home_play")
	assert(state.furniture_available("toy_ball") and events[-1].has("home_toy_ball"))
	assert(state.home_owned.get("toy_ball",false))
	state.reward_activity(1,"home_play")
	assert(Rules.count(state,"play")==3,"Cooldown was bypassed")
	state.activity_counts.clear()
	assert(state.furniture_available("toy_ball"),"Earned item relocked")
	# Old saves keep items already earned by affinity; new saves use action gates.
	var path="user://home-unlock-test-%d.json"%Time.get_ticks_usec()
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":8,"affection":{"0":20}}))
	file.close()
	var loaded=State.new()
	loaded.save_path=path
	loaded.load_game()
	assert(loaded.furniture_available("reading_chair") and not loaded.furniture_available("daybed"))
	loaded.save_game()
	var again=State.new()
	again.save_path=path
	again.load_game()
	assert(again.furniture_available("reading_chair"))
	DirAccess.remove_absolute(path)
	print("HOME_UNLOCK_RULES: PASS; 18 gates, shared completion, cooldown, permanent ownership, legacy migration, restart")
	quit()
