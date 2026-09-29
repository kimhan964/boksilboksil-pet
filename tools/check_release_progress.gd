extends SceneTree
const State=preload("res://scripts/pet_state.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
var failures=0
var checks=0
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _initialize() -> void:
	var s=State.new()
	s.save_path="user://progression-check-%d.json"%Time.get_ticks_usec()
	check(not s.test_unlocks(),"release defaults")
	check(State.new().save_path=="user://friends-release.json","isolated release save")
	for species in range(16):
		check(s.can_action(species,0),"pet available")
		check(s.growth_stage(species)==0,"starts baby")
		for id in s.ACTION_UNLOCKS: check(not s.can_action(species,id),"action initially locked")
		for key in s.UNLOCKS:
			s.play_affection[str(species)]=s.UNLOCKS[key]-1
			check(not s.unlocked(species,key),"threshold below")
			s.play_affection[str(species)]=s.UNLOCKS[key]
			check(s.unlocked(species,key),"threshold reached")
			for id in s.ACTION_UNLOCKS:
				if s.ACTION_UNLOCKS[id]==key: check(s.can_action(species,id),"action opens")
		s.play_affection[str(species)]=0
	s.reward_activity(0,"ball")
	check(int(s.play_affection.get("0",0))==0,"locked reward rejected")
	s.reward_activity(0,"pet")
	s.reward_activity(0,"pet")
	check(s.play_affection["0"]==1,"repeat cooldown")
	check(int(s.play_affection.get("1",0))==0,"species isolated")
	s.play_affection["0"]=12
	s.reward_activity(0,"ball")
	check(s.play_affection["0"]==14,"unlocked play rewards")
	var loaded=State.new()
	loaded.save_path=s.save_path
	loaded.load_game()
	check(loaded.play_affection["0"]==14,"reload progress")
	check(loaded.can_action(0,1) and not loaded.can_action(0,16),"reload locks")
	var m=Motion.new()
	m.autonomy=true
	m.can_playful=false
	m.can_personality=false
	m.can_ask_play=false
	for i in range(200):
		m.habit_cooldown=0
		m.personality_cooldown=0
		m.choose_autonomous_action()
		check(m.phase not in ["signature","playful"] and not m.personality_active,"autonomy obeys locks")
	DirAccess.remove_absolute(s.save_path)
	print("RELEASE_PROGRESS_CHECKS=",checks," FAILURES=",failures)
	quit(1 if failures else 0)
