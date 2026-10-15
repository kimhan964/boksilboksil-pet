extends RefCounted
const Catalog=preload("res://scripts/animal_catalog.gd")
const Generated=preload("res://scripts/generated_species_art.gd")
const Home=preload("res://scripts/home_animation.gd")
const Slap=preload("res://scripts/slapstick.gd")
# id, category, title, real-world trigger, required furniture
const ROWS=[
	["idle","일상","편안한 대기","아무것도 하지 않고 잠시 쉬고 있을 때예요.",""],
	["walk","일상","산책 · 깡총걸음","스스로 산책하거나, 가구를 클릭해 찾아갈 때예요.",""],
	["look","일상","주변 둘러보기","주변 물건에 관심을 갖고 살펴볼 때예요.",""],
	["stretch","일상","기지개","편안히 쉬는 동안 가끔 몸을 쭉 펴요.",""],
	["pet","교감","기분 좋은 반응","동물을 짧게 클릭해 쓰다듬어 주세요.",""],
	["carry","교감","살짝 들기","동물을 잡고 위로 들어 올려 보세요.",""],
	["struggle","교감","내려 주세요","동물을 잡은 채 2초가 지나면 버둥거려요.",""],
	["eat","식사·휴식","냠냠 식사","식탁에 음식을 차린 뒤 클릭하거나 동물을 데려다 놓으세요.","table"],
	["drink","식사·휴식","물 한 모금","식탁 우클릭에서 물을 준비하고 동물이 마시게 해 주세요.","table"],
	["sleep","식사·휴식","꾸벅꾸벅","피곤할 때 스스로 잠들어요. 침대에서도 쉴 수 있어요.",""],
	["sofa","가구·놀이","소파에서 쉬기","소파를 클릭하거나 동물을 끌어 놓으면 쉬어요.","sofa"],
	["read","가구·놀이","책 읽는 시간","책장을 클릭하거나 동물을 데려다 놓으세요.","shelf"],
	["music","가구·놀이","음악에 귀 기울이기","음악 가구를 클릭하면 리듬을 즐겨요.","record_player"],
	["play","가구·놀이","러그에서 놀기","놀이 러그를 클릭하거나 동물을 데려다 놓으세요.","play_rug"],
	["stumble","깜짝 행동","앗, 꽈당!","자유롭게 걷다가 가끔 넘어져요. 식사·가구 이용 중에는 방해하지 않아요.",""],
	["sneeze","깜짝 행동","에취!","쉬는 동안 가끔 재채기해요. 연속해서 반복하지 않아요.",""]
]
static func motion_for(species: int,baby: bool):
	var m=preload("res://scripts/desktop_pet_motion.gd").new()
	m.species=species;m.growth_stage=0 if baby else 2;m.growth_scale=.65 if baby else 1.0
	m.rabbit_pilot=species==0;m.smooth_walk_enabled=true;m.autonomy=false
	m.food_id=Catalog.DEFAULT_MEALS[species];m.bounds=Rect2(0,0,1600,900);m.feet=Vector2(400,700);m.target=m.feet
	return m
static func ready(m,row: Array) -> bool:
	if row[0] in ["stumble","sneeze"]: return Slap.available(m)
	if row[0] in ["sofa","read","music","play"]: return Home.available(m)
	return preload("res://scripts/asset_images.gd").exists(Generated.asset_root(m.species)+"/manifest.json")
static func seconds(m,id: String) -> float:
	if id in ["stumble","sneeze"]: return Slap.DURATIONS[id]+.4
	if id in ["sofa","read","music","play"]: return Home.DURATIONS[{"sofa":"rest","read":"read","music":"music","play":"play"}[id]]
	if id=="walk":
		if m.species==0: return float(preload("res://scripts/rabbit_pilot_art.gd").data().stages[Generated.stage_name(m)].cycle_seconds)
		return float(preload("res://scripts/smooth_species_art.gd").spec(m).cycle_seconds)
	if id=="struggle": return 2.4
	if id=="carry": return 2.0
	return 5.5 if id in ["eat","drink"] else 4.8
static func sample(m,id: String,time: float) -> Dictionary:
	m.phase="idle";m.visit_id="";m.held=false;m.carried=false;m.pointer_grab=false;m.joy_left=0;m.landing_left=0;m.reaction="";m.hold_release.clear()
	m.elapsed=time;m.reaction_time=time;m.action_left=maxf(.01,seconds(m,id)-time);m.walk_phase=fposmod(time/seconds(m,id),1.0)
	match id:
		"walk": m.phase="wander"
		"look","stretch","eat","drink": m.phase=id
		"sleep": m.phase="doze";m.stay_after_visit=true
		"pet": m.phase="pet";m.joy_left=1.8
		"carry","struggle":
			m.carried=true;m.held=true;m.pointer_grab=true;m.carry_started_at=0.0
			m.carry_elapsed=.6 if id=="carry" else m.STRUGGLE_HOLD_SECONDS+m.STRUGGLE_ENTRY_SECONDS+time
		"sofa","read","music","play":
			m.phase="home_use";m.visit_id={"sofa":"home_sofa","read":"home_shelf","music":"home_record_player","play":"home_play_rug"}[id]
		"stumble","sneeze":
			m.phase="silly";m.silly_kind=id
			return Slap.sample(m)
	if id in ["eat","drink"]: m.visit_id="home_food" if id=="eat" else "home_water"
	return Generated.sample(m)
static func requirement(state,row: Array) -> Dictionary:
	if row[4].is_empty(): return {"open":true,"text":"처음부터 함께해요","ratio":1.0}
	var available: bool=state.furniture_available(row[4])
	var needed=int(state.UNLOCKS.get("home_"+row[4],0));var points=int(state.home_points())
	return {"open":available,"text":("배치 가능" if available else "교감 %d / %d"%[points,needed])+" · "+state.gift_name("home_"+row[4]),"ratio":1.0 if available else clampf(float(points)/maxi(1,needed),0,1)}
