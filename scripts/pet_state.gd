extends RefCounted
const Catalog=preload("res://scripts/animal_catalog.gd")
signal affection_changed(species: int, gifts: Array)
signal growth_changed(species: int, stage: int)
signal food_unlocked(species: int, foods: Array)

func feeding_count(species: int) -> int:
	return int(activity_counts.get(str(species),{}).get("hand_feed",0))

func food_requirement(species: int, food: int) -> Vector2i:
	var basic=int(Catalog.DEFAULT_MEALS[species])
	if food==basic: return Vector2i(3,0)
	var home=food/4==basic/4
	var slot=food%4
	if home: return [Vector2i(3,0),Vector2i(8,1),Vector2i(16,3),Vector2i(24,5)][(food-basic+4)%4]
	return [Vector2i(12,2),Vector2i(22,4),Vector2i(32,6),Vector2i(40,8)][slot]

func food_available(species: int, food: int) -> bool:
	if species<0 or species>=Catalog.IDS.size() or food<0 or food>=32: return false
	if test_unlocks(): return true
	var need=food_requirement(species,food)
	return int(play_affection.get(str(species),0))>=need.x and feeding_count(species)>=need.y

func food_hint(species: int, food: int) -> String:
	if food_available(species,food): return "집어서 입 근처에 놓아 먹여주세요"
	var need=food_requirement(species,food)
	return "교감 %d · 직접 먹여주기 %d회 (%d/%d)"%[need.x,need.y,mini(feeding_count(species),need.y),need.y]

func food_progress(species: int) -> String:
	var count=0
	for food in range(32):
		if food_available(species,food): count+=1
	return "열린 먹이 %d/32 · 직접 먹여주기 %d회\n먹이를 선택 → 그릇에서 집기 → 입 근처에 놓기"%[count,feeding_count(species)]
const GROWTH_NAMES=["새끼","중간","성체"]
const GROWTH_SCALES=[.93,.98,1.0]
const GROWTH_LIMITS=[0,12,36]
const CARE_ACTIONS=["pet","ball","hand_feed","snack","cuddle","doze","relax","playful","personality","bowl","water","plant","lamp","acorn"]
var growth: Dictionary={}
var guide_seen=false
var activity_counts: Dictionary={}
const GOALS=[["pet",3,"쓰다듬기로 첫 인사 3번"],["hand_feed",1,"음식을 집어 직접 먹여주기"],["follow",1,"마우스 따라오기 함께하기"],["ball",1,"공을 직접 던지고 돌려받기"],["rub",1,"소품에 부비는 모습 보기"],["cuddle",1,"잠자리에서 토닥여주기"],["personality",1,"성격 행동 함께하기"]]

func goal_text(species: int) -> String:
	var counts: Dictionary=activity_counts.get(str(species),{})
	for goal in GOALS:
		var count=int(counts.get(goal[0],0))
		if count<int(goal[1]): return "목표: %s (%d/%d)"%[goal[2],count,goal[1]]
	return "첫 교감 목표 완료! · "+next_gift(species)

func growth_stage(species: int) -> int:
	var points=int(growth.get(str(species),0))
	return 2 if points>=36 else (1 if points>=12 else 0)

func growth_scale(species: int) -> float:
	var points=float(growth.get(str(species),0))
	# Newborn pets start about 1.5x larger (.62 -> .93). Keep the
	# boundary continuous so growing into the next stage never shrinks them.
	if points<12: return lerpf(.93,.98,points/12.0)
	if points<36: return lerpf(.98,1.0,(points-12)/24.0)
	return 1.0

func growth_text(species: int) -> String:
	var stage=growth_stage(species)
	var points=int(growth.get(str(species),0))
	var text="성장 단계: %s · 성장 경험치 %d\n새끼 → 중간 → 성체\n"%[GROWTH_NAMES[stage],points]
	text+=("다음 단계까지 %d 더 돌봐주세요."%(GROWTH_LIMITS[stage+1]-points)) if stage<2 else "함께 돌보며 어른으로 자랐어요!"
	return text+"\n먹여주기·공놀이·간식 찾기·토닥이기 +2\n쓰다듬기·잠자리·휴식·성격 놀이·식사·물 마시기 +1\n소품 해금과 성장은 별개예요. 자리를 비워도 퇴행하지 않아요."

func add_growth(species: int, amount: int) -> void:
	if species<0 or species>=Catalog.IDS.size() or amount<=0: return
	var before=growth_stage(species)
	growth[str(species)]=clampi(int(growth.get(str(species),0))+amount,0,9999)
	if growth_stage(species)!=before: growth_changed.emit(species,growth_stage(species))
const UNLOCKS={"acorn":0,"bowl":3,"water":6,"playful":8,"follow":10,"basket":12,"snack":16,"rub":18,"cushion":20,"cuddle":24,"plant":30,"personality":36,"lamp":42,"shelter":50}
const ACTION_UNLOCKS={1:"basket",4:"snack",5:"bowl",6:"bowl",7:"bowl",8:"bowl",11:"cushion",12:"shelter",13:"cuddle",15:"bowl",16:"personality",20:"plant",21:"lamp",22:"playful",23:"follow",24:"rub",29:"acorn"}
const REWARD_UNLOCKS={"follow":"follow","rub":"rub","ball":"basket","hand_feed":"bowl","snack":"snack","cuddle":"cuddle","doze":"cushion","relax":"shelter","playful":"playful","personality":"personality","decorate":"bowl","bowl":"bowl","water":"water","basket":"basket","plant":"plant","lamp":"lamp","shelter":"shelter","acorn":"acorn"}
const REWARDS={"follow":1,"rub":1,"pet":1,"ball":2,"hand_feed":2,"snack":2,"cuddle":2,"doze":1,"relax":1,"playful":1,"personality":1,"decorate":1,"bowl":1,"water":1,"basket":1,"plant":1,"lamp":1,"shelter":1,"acorn":1}
var reward_times: Dictionary={}

func reward_activity(species: int, action: String) -> void:
	if species<0 or species>=Catalog.IDS.size() or not REWARDS.has(action): return
	if REWARD_UNLOCKS.has(action) and not unlocked(species,REWARD_UNLOCKS[action]): return
	var key=str(species)+":"+action
	var now=Time.get_ticks_msec()/1000.0
	var interval=45.0 if action in ["bowl","water"] else 8.0
	if reward_times.has(key) and now-float(reward_times[key])<interval: return
	var before_foods: Array=[]
	for food in range(32):
		if food_available(species,food): before_foods.append(food)
	reward_times[key]=now
	var counts: Dictionary=activity_counts.get(str(species),{})
	counts[action]=int(counts.get(action,0))+1
	activity_counts[str(species)]=counts
	if action in CARE_ACTIONS: add_growth(species,int(REWARDS[action]))
	add_affection(species,int(REWARDS[action]))
	var new_foods: Array=[]
	for food in range(32):
		if food not in before_foods and food_available(species,food): new_foods.append(food)
	if not new_foods.is_empty(): food_unlocked.emit(species,new_foods)
const GIFT_NAMES={"follow":"마우스 따라오기","rub":"소품에 부비기","bowl":"음식 그릇·먹여주기·꾸미기","water":"작은 연못","playful":"킁킁·폴짝 놀이","acorn":"모두의 도토리 오뚝이","basket":"장난감 바구니·공 던지기","snack":"간식 찾기","cushion":"전용 침대·잠자리","cuddle":"잠자리 토닥이기","plant":"동물 전용 놀이 소품","personality":"MBTI 성격 행동","lamp":"동물 전용 휴식 소품","shelter":"전용 집·쉼터"}

func unlocked(species: int, id: String) -> bool:
	return UNLOCKS.has(id) and (test_unlocks() or int(play_affection.get(str(species),0))>=int(UNLOCKS[id]))

func test_unlocks() -> bool:
	return OS.has_feature("editor") and bool(ProjectSettings.get_setting("testing/unlock_all",false))

func can_action(species: int, id: int) -> bool:
	if id>=100 and id<132: return food_available(species,id-100)
	if ACTION_UNLOCKS.has(id): return unlocked(species,ACTION_UNLOCKS[id])
	return true

func action_hint(species: int, id: int) -> String:
	if id>=100 and id<132: return food_hint(species,id-100)
	var key="bowl" if id>=100 and id<132 else str(ACTION_UNLOCKS.get(id,""))
	if key.is_empty() or unlocked(species,key): return ""
	return "교감 %d에 해금 · %d 더 필요"%[UNLOCKS[key],maxi(0,int(UNLOCKS[key])-int(play_affection.get(str(species),0)))]

func progress_text(species: int) -> String:
	var score=int(play_affection.get(str(species),0))
	var lines=PackedStringArray(["친밀도 %d · 쓰다듬기와 함께하는 놀이로 친해져요."%score])
	if test_unlocks(): lines.append("테스트 모드 · 모든 음식·놀이·소품이 해금되어 있어요.")
	lines.append("처음에는 쓰다듬기와 자리 옮기기로 알아가요.\n공 가져오기·먹여주기·간식 찾기·토닥이기 완료 +2\n쓰다듬기·잠자리·쉼터·성격 놀이·꾸미기·식사/물 마시기 +1\n같은 행동은 8초, 식사·물은 45초마다 교감을 얻어요.\n친구마다 따로 진행되며, 해금은 계속 유지돼요.")
	lines.append(food_progress(species))
	for id in UNLOCKS:
		lines.append(("받았어요 · " if unlocked(species,id) else "친밀도 %d · "%UNLOCKS[id])+GIFT_NAMES[id])
	return "\n".join(lines)

func next_gift(species: int) -> String:
	if test_unlocks(): return "테스트 모드 · 모든 선물 해금"
	var score=int(play_affection.get(str(species),0))
	for id in UNLOCKS:
		if not unlocked(species,id): return "다음 선물: %s · %d 더 친해지면"%[GIFT_NAMES[id],UNLOCKS[id]-score]
	return "모든 선물을 받았어요"
const PROPS=["cushion","bowl","water","basket","plant","lamp","shelter","acorn"]
var save_path="user://friends-release.json"
var selected=0
var palette=0
var play_affection: Dictionary={}
var layout: Dictionary={}
var hidden: Array=[]
var discoveries: Dictionary={}
var save_failed=false
var personal_layout: Dictionary={}
var meals: Dictionary={}
var favorite_foods: Dictionary={}
var outfits: Dictionary={}
var outfit_colors: Dictionary={}

func load_game() -> void:
	if not FileAccess.file_exists(save_path): return
	var data=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary: return
	guide_seen=data.get("guide_seen",false)==true
	if data.get("activity_counts") is Dictionary:
		for i in range(Catalog.IDS.size()):
			var counts=data.activity_counts.get(str(i),{})
			if not counts is Dictionary: continue
			var clean: Dictionary={}
			for action in REWARDS: clean[action]=clean_number(counts.get(action),0,9999)
			activity_counts[str(i)]=clean
	selected=clean_number(data.get("selected"),0,Catalog.IDS.size()-1)
	palette=clean_number(data.get("palette"),0,2)
	for i in range(Catalog.IDS.size()):
		var key=str(i)
		if data.get("outfits") is Dictionary: outfits[key]=clean_number(data.outfits.get(key),0,3)
		if data.get("outfit_colors") is Dictionary: outfit_colors[key]=clean_number(data.outfit_colors.get(key),0,5)
		if data.get("growth") is Dictionary: growth[key]=clean_number(data.growth.get(key),0,9999)
		if data.get("meals") is Dictionary: meals[key]=clean_number(data.meals.get(key,Catalog.DEFAULT_MEALS[i]),0,31)
		if data.get("favorite_foods") is Dictionary and data.favorite_foods.get(key)==true: favorite_foods[key]=true
		if data.get("personal_layout") is Dictionary and data.personal_layout.get(key) is Dictionary:
			var places: Dictionary={}
			for id in ["cushion","shelter"]:
				var point=data.personal_layout[key].get(id)
				if point is Array and point.size()==2 and numeric(point[0]) and numeric(point[1]): places[id]=[float(point[0]),float(point[1])]
			personal_layout[key]=places
	if data.get("affection") is Dictionary:
		for i in range(Catalog.IDS.size()): play_affection[str(i)]=clean_number(data.affection.get(str(i)),0,9999)
	if data.get("layout") is Dictionary:
		for id in PROPS:
			var point=data.layout.get(id)
			if point is Array and point.size()==2 and numeric(point[0]) and numeric(point[1]): layout[id]=[float(point[0]),float(point[1])]
	if data.get("hidden") is Array:
		for id in data.hidden:
			if id in PROPS and id not in hidden: hidden.append(id)
	if data.get("discoveries") is Dictionary:
		for i in range(Catalog.IDS.size()):
			var id=data.discoveries.get(str(i))
			if id in PROPS: discoveries[str(i)]=id

func numeric(value) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))
func clean_number(value, low: int, high: int) -> int:
	return clampi(int(value),low,high) if numeric(value) else low

func save_game() -> void:
	var file=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file==null:
		save_failed=true
		return
	file.store_string(JSON.stringify({"version":5,"guide_seen":guide_seen,"activity_counts":activity_counts,"growth":growth,"selected":selected,"palette":palette,"affection":play_affection,"layout":layout,"hidden":hidden,"discoveries":discoveries,"personal_layout":personal_layout,"meals":meals,"favorite_foods":favorite_foods,"outfits":outfits,"outfit_colors":outfit_colors}))
	file.close()
	save_failed=DirAccess.rename_absolute(save_path+".tmp",save_path)!=OK

func add_affection(species: int, amount: int=1) -> void:
	if species<0 or species>=Catalog.IDS.size(): return
	var before=int(play_affection.get(str(species),0))
	play_affection[str(species)]=clampi(before+amount,0,9999)
	var gifts: Array=[]
	for id in UNLOCKS:
		if not test_unlocks() and before<int(UNLOCKS[id]) and unlocked(species,id): gifts.append(id)
	save_game()
	affection_changed.emit(species,gifts)
