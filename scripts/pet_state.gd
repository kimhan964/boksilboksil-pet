extends RefCounted
const Catalog=preload("res://scripts/animal_catalog.gd")
signal affection_changed(species: int, gifts: Array)
signal growth_changed(species: int, stage: int)
const GROWTH_NAMES=["새끼","중간","성체"]
const GROWTH_SCALES=[.62,.82,1.0]
const GROWTH_LIMITS=[0,12,36]
const CARE_ACTIONS=["pet","ball","hand_feed","snack","cuddle","doze","relax","personality","bowl","water","plant","lamp"]
var growth: Dictionary={}

func growth_stage(species: int) -> int:
	var points=int(growth.get(str(species),0))
	return 2 if points>=36 else (1 if points>=12 else 0)

func growth_scale(species: int) -> float:
	var points=float(growth.get(str(species),0))
	if points<12: return lerpf(.62,.78,points/12.0)
	if points<36: return lerpf(.82,1.0,(points-12)/24.0)
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
const UNLOCKS={"bowl":1,"water":2,"basket":3,"cushion":5,"plant":7,"lamp":9,"shelter":12}
const REWARDS={"pet":1,"ball":2,"hand_feed":2,"snack":2,"cuddle":2,"doze":1,"relax":1,"personality":1,"decorate":1,"bowl":1,"water":1,"basket":1,"plant":1,"lamp":1,"shelter":1}
var reward_times: Dictionary={}

func reward_activity(species: int, action: String) -> void:
	if species<0 or species>=Catalog.IDS.size() or not REWARDS.has(action): return
	var key=str(species)+":"+action
	var now=Time.get_ticks_msec()/1000.0
	var interval=45.0 if action in ["bowl","water"] else 8.0
	if reward_times.has(key) and now-float(reward_times[key])<interval: return
	reward_times[key]=now
	if action in CARE_ACTIONS: add_growth(species,int(REWARDS[action]))
	add_affection(species,int(REWARDS[action]))
const GIFT_NAMES={"bowl":"음식 그릇과 식당 음식","water":"물그릇","basket":"장난감 바구니와 공 놀이","cushion":"전용 침대","plant":"동물 전용 놀이 소품","lamp":"동물 전용 휴식 소품","shelter":"전용 집"}

func unlocked(species: int, id: String) -> bool:
	return UNLOCKS.has(id) and (test_unlocks() or int(play_affection.get(str(species),0))>=int(UNLOCKS[id]))

func test_unlocks() -> bool:
	return bool(ProjectSettings.get_setting("testing/unlock_all",false))

func can_action(species: int, id: int) -> bool:
	if id>=100 and id<132: return unlocked(species,"bowl")
	if id==1: return unlocked(species,"basket")
	if id in [4,15]: return unlocked(species,"bowl")
	if id in [5,6,7,8]: return unlocked(species,"bowl")
	if id in [11,13]: return unlocked(species,"cushion")
	if id==12: return unlocked(species,"shelter")
	return true

func progress_text(species: int) -> String:
	var score=int(play_affection.get(str(species),0))
	var lines=PackedStringArray(["친밀도 %d · 쓰다듬기와 함께하는 놀이로 친해져요."%score])
	if test_unlocks(): lines.append("테스트 모드 · 모든 음식·놀이·소품이 해금되어 있어요.")
	lines.append("공 가져오기·먹여주기·간식 찾기·토닥이기 +2\n쓰다듬기·잠자리·쉼터·성격 놀이·꾸미기·식사/물 마시기 +1")
	for id in UNLOCKS:
		lines.append(("받았어요 · " if unlocked(species,id) else "친밀도 %d · "%UNLOCKS[id])+GIFT_NAMES[id])
	return "\n".join(lines)

func next_gift(species: int) -> String:
	if test_unlocks(): return "테스트 모드 · 모든 선물 해금"
	var score=int(play_affection.get(str(species),0))
	for id in UNLOCKS:
		if not unlocked(species,id): return "다음 선물: %s · %d 더 친해지면"%[GIFT_NAMES[id],UNLOCKS[id]-score]
	return "모든 선물을 받았어요"
const PROPS=["cushion","bowl","water","basket","plant","lamp","shelter"]
var save_path="user://friends.json"
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

func load_game() -> void:
	if not FileAccess.file_exists(save_path): return
	var data=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary: return
	selected=clean_number(data.get("selected"),0,Catalog.IDS.size()-1)
	palette=clean_number(data.get("palette"),0,2)
	for i in range(Catalog.IDS.size()):
		var key=str(i)
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
	file.store_string(JSON.stringify({"version":3,"growth":growth,"selected":selected,"palette":palette,"affection":play_affection,"layout":layout,"hidden":hidden,"discoveries":discoveries,"personal_layout":personal_layout,"meals":meals,"favorite_foods":favorite_foods}))
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
