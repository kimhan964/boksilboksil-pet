extends RefCounted
# Counts are shared across owned pets. Every route begins with a basic activity.
const GROUPS={
	"bond":{"label":"쓰다듬기·토닥이기","actions":["pet","cuddle","rub"]},
	"play":{"label":"함께 놀기","actions":["acorn","ball","basket","plant","home_play","playful","snack"]},
	"care":{"label":"식사·물 마시기","actions":["bowl","water","hand_feed","home_tea"]},
	"rest":{"label":"가구에서 휴식","actions":["home_rest","doze","relax"]},
	"read":{"label":"가구에서 독서","actions":["home_read"]},
	"music":{"label":"음악 감상","actions":["home_music"]}
}
const RULES={
	"toy_ball":["play",3],"shelf":["bond",5],"wall_clock":["care",4],
	"toy_mouse":["play",8],"lamp":["rest",5],"wall_shelf":["read",4],
	"alarm_clock":["rest",8],"reading_chair":["read",8],"plant_stand":["care",8],
	"daybed":["rest",12],"dresser":["bond",15],"vanity":["bond",20],
	"record_player":["play",15],"fireplace":["rest",20],"window_seat":["care",15],
	"aquarium":["care",24],"tv":["rest",30],"turntable":["music",12]
}
static func count(state,group: String) -> int:
	var total=0
	for counts in state.activity_counts.values():
		for action in GROUPS[group].actions: total+=int(counts.get(action,0))
	return total
static func achieved(state,id: String) -> bool:
	if not RULES.has(id): return false
	return count(state,RULES[id][0])>=RULES[id][1]
static func hint(state,id: String) -> String:
	if not RULES.has(id): return "기본 제공 · 처음부터 이용해요"
	var rule=RULES[id]
	return "%s %d / %d회"%[GROUPS[rule[0]].label,mini(count(state,rule[0]),rule[1]),rule[1]]
static func progress(state,id: String) -> float:
	if not RULES.has(id): return 1.0
	return clampf(float(count(state,RULES[id][0]))/RULES[id][1],0,1)
