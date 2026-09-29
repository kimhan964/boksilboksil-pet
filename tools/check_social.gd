extends SceneTree
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const State=preload("res://scripts/pet_state.gd")
var failures=0
func check(ok: bool) -> void:
	if not ok: failures+=1
func _initialize() -> void:
	for species in range(16):
		var m=Motion.new()
		m.species=species
		m.bounds=Rect2(0,0,1000,700)
		m.feet=Vector2(200,300)
		m.cursor_position=Vector2(380,300)
		check(not m.start_social("follow"))
		m.can_follow=true
		var earned=[]
		m.activity_bonded.connect(func(action): earned.append(action))
		check(m.start_social("follow",true))
		for tick in range(450): m.advance(1.0/60)
		check(m.feet.x>200 and m.feet.distance_to(m.cursor_position)>=60)
		check(m.social_kind.is_empty() and earned==["follow"])
		m.can_rub=true
		check(not m.start_social("rub"))
		m.destinations=[{"point":m.feet+Vector2(50,0),"action":"relax","id":"cushion"}]
		check(m.start_social("rub",true))
		for tick in range(600): m.advance(1.0/60)
		check(m.social_kind.is_empty() and "rub" in earned)
		m.start_social("follow",true)
		m.cancel_play()
		check(m.social_kind.is_empty())
		m.voice_cooldown=0
		m.speak()
		check(m.voice_left>0 and not m.VOICES[species].is_empty())
	var s=State.new()
	s.save_path="user://social-check-%d.json"%Time.get_ticks_usec()
	s.reward_activity(0,"pet")
	check("1/3" in s.goal_text(0))
	s.guide_seen=true
	s.save_game()
	var restored=State.new()
	restored.save_path=s.save_path
	restored.load_game()
	check(restored.guide_seen and "1/3" in restored.goal_text(0))
	DirAccess.remove_absolute(s.save_path)
	print("SOCIAL_SPECIES=16 GOAL_SAVE=checked FAILURES=",failures)
	quit(1 if failures else 0)
