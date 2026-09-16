extends SceneTree
class MemoryState extends "res://scripts/pet_state.gd":
	func save_game() -> void: pass

func _initialize() -> void:
	var state=MemoryState.new()
	ProjectSettings.set_setting("testing/unlock_all",false)
	assert(not state.unlocked(0,"bowl"))
	state.add_affection(0)
	assert(state.unlocked(0,"bowl"))
	state.reward_activity(0,"ball")
	assert(state.play_affection["0"]==3 and state.unlocked(0,"basket"))
	state.reward_activity(0,"ball")
	assert(state.play_affection["0"]==3)
	state.reward_activity(1,"ball")
	assert(state.play_affection["1"]==2)
	for action in ["hand_feed","snack","cuddle","doze","relax","personality","decorate","bowl","water"]:
		var before=int(state.play_affection["0"])
		state.reward_activity(0,action)
		assert(state.play_affection["0"]==before+state.REWARDS[action])
	assert(state.unlocked(0,"shelter"))
	ProjectSettings.set_setting("testing/unlock_all",true)
	assert(state.unlocked(15,"shelter"))
	print("ACTIVITY_REWARD_CHECK_PASSED (no save file written)")
	quit()
