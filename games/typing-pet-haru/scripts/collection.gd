extends RefCounted
# Finite, permanent milestone collection: inputs AND activity time; no duplicate drops.
const ITEMS=[
	{"id":"ribbon","name":"로즈 리본","slot":"pin","actions":60,"seconds":15,"color":"c99eaa"},
	{"id":"clover","name":"클로버 핀","slot":"pin","actions":300,"seconds":120,"color":"95af89"},
	{"id":"sprout","name":"쑥쑥 새싹 핀","slot":"pin","actions":500,"seconds":180,"color":"95af89"},
	{"id":"daisy","name":"데이지 브로치","slot":"pin","actions":1000,"seconds":300,"color":"e9d7a5"},
	{"id":"beret","name":"산책 베레모","slot":"pin","actions":1200,"seconds":420,"color":"a5b888"},
	{"id":"oat","name":"오트 라떼","slot":"skin","actions":1500,"seconds":600,"color":"d1b990"},
	{"id":"jester","name":"장난꾸러기 삐에로","slot":"pin","actions":2000,"seconds":720,"color":"d6a29b"},
	{"id":"friedegg","name":"반숙 프라이 핀","slot":"pin","actions":2500,"seconds":840,"color":"e2b957"},
	{"id":"star","name":"작은 별 핀","slot":"pin","actions":3000,"seconds":900,"color":"d2b578"},
	{"id":"crown","name":"오늘의 작은 왕관","slot":"pin","actions":4000,"seconds":1200,"color":"e4c787"},
	{"id":"mushroom","name":"말랑 버섯 모자","slot":"pin","actions":4500,"seconds":1500,"color":"c88f77"},
	{"id":"rose","name":"로즈 밀크","slot":"skin","actions":5000,"seconds":1800,"color":"ceabb7"},
	{"id":"headphones","name":"나만의 미니 헤드폰","slot":"pin","actions":6000,"seconds":2100,"color":"a5b888"},
	{"id":"wizard","name":"달빛 마법사","slot":"pin","actions":7000,"seconds":2400,"color":"b4a1c8"},
	{"id":"teacup","name":"머리 위 티타임","slot":"pin","actions":8500,"seconds":3000,"color":"dbc8a8"},
	{"id":"sleepcap","name":"꾸벅 줄무늬 수면모자","slot":"pin","actions":9500,"seconds":3300,"color":"cda3a0"},
	{"id":"mist","name":"안개 세이지","slot":"skin","actions":10000,"seconds":3600,"color":"a6bcae"}]
const TINTS={"":Vector3.ZERO,"oat":Vector3(.045,.018,-.035),"rose":Vector3(.045,-.018,.025),"mist":Vector3(-.035,.02,.018)}
var actions=0
var active_ms=0
var claimed: Array[String]=[]
var equipped: Dictionary={}
const ORDERS=[
	{"id":"first_keys","name":"오늘의 첫 주문","target":100,"metric":"actions","reward":1},
	{"id":"coffee_break","name":"따뜻한 한 잔","target":300000,"metric":"time","reward":2},
	{"id":"cozy_work","name":"느긋한 작업 시간","target":900000,"metric":"time","reward":3}]
const LIGHTS=[
	{"id":"rose_keys","name":"딸기 우유 불빛","price":3,"color":"e4a4b1"},
	{"id":"honey_keys","name":"허니 라떼 불빛","price":5,"color":"e0bd75"},
	{"id":"lavender_keys","name":"라벤더 티 불빛","price":8,"color":"b8a6da"}]
var day=""
var daily_actions=0
var daily_ms=0
var daily_claims: Array[String]=[]
var stamps=0
var owned_lights: Array[String]=[]
var light_style=""
func roll_day(today: String="") -> void:
	if today.is_empty(): today=Time.get_date_string_from_system()
	if not day.is_empty() and today<=day: return
	day=today
	daily_actions=0
	daily_ms=0
	daily_claims.clear()
func order_progress(order: Dictionary) -> float:
	return clampf(float(daily_actions if order.metric=="actions" else daily_ms)/order.target,0,1)
func claim_order(id: String) -> bool:
	roll_day()
	for order in ORDERS:
		if order.id==id and id not in daily_claims and order_progress(order)>=1:
			daily_claims.append(id)
			stamps+=order.reward
			return true
	return false
func buy_light(id: String) -> bool:
	for light in LIGHTS:
		if light.id==id and id not in owned_lights and stamps>=light.price:
			stamps-=light.price
			owned_lights.append(id)
			light_style=id
			return true
	return false
func equip_light(id: String) -> bool:
	if not id.is_empty() and id not in owned_lights: return false
	light_style=id
	return true
func light_color() -> Color:
	for light in LIGHTS:
		if light.id==light_style: return Color(light.color)
	return Color("b8d58a")
func ready_orders() -> int:
	var count=0
	for order in ORDERS:
		if order.id not in daily_claims and order_progress(order)>=1: count+=1
	return count

func item(id: String) -> Dictionary:
	for entry in ITEMS:
		if entry.id==id: return entry
	return {}
func eligible(id: String) -> bool:
	var entry=item(id)
	return not entry.is_empty() and actions>=entry.actions and active_ms>=entry.seconds*1000
func credit(count: int, milliseconds: int) -> bool:
	roll_day()
	daily_actions=mini(2147483647,daily_actions+maxi(0,count))
	daily_ms=mini(90000000,daily_ms+maxi(0,milliseconds))
	actions=mini(2147483647,actions+maxi(0,count))
	active_ms=mini(900000000000,active_ms+maxi(0,milliseconds))
	for entry in ITEMS:
		if eligible(entry.id) and entry.id not in claimed: return true
	return false
func claim(id: String) -> bool:
	if not eligible(id) or id in claimed: return false
	claimed.append(id)
	return true
func selected(species: int, slot: String) -> String:
	return str(equipped.get(str(species),{}).get(slot,""))
func equip(species: int,slot: String,id: String) -> bool:
	if species<0 or species>=16 or slot not in ["pin","skin"]: return false
	if not id.is_empty() and (id not in claimed or item(id).get("slot")!=slot): return false
	var slots: Dictionary=equipped.get(str(species),{})
	slots[slot]=id
	equipped[str(species)]=slots
	return true
func progress(entry: Dictionary) -> float:
	return clampf(minf(float(actions)/entry.actions,float(active_ms)/(entry.seconds*1000)),0,1)
func summary() -> String:
	for entry in ITEMS:
		if entry.id not in claimed:
			if eligible(entry.id): return "선물 도착 · "+entry.name
			return "다음 선물 · %s %d%%"%[entry.name,roundi(progress(entry)*100)]
	return "작은 선물 %d종을 모두 모았어요"%ITEMS.size()
func serialize() -> Dictionary:
	return {"actions":actions,"active_ms":active_ms,"claimed":claimed,"equipped":equipped,"day":day,"daily_actions":daily_actions,"daily_ms":daily_ms,"daily_claims":daily_claims,"stamps":stamps,"owned_lights":owned_lights,"light_style":light_style}
func restore(value) -> void:
	if not value is Dictionary: return
	actions=number(value.get("actions"),2147483647)
	active_ms=number(value.get("active_ms"),900000000000)
	claimed.clear()
	equipped.clear()
	day=str(value.get("day",""))
	daily_actions=number(value.get("daily_actions"),2147483647)
	daily_ms=number(value.get("daily_ms"),90000000)
	stamps=number(value.get("stamps"),2147483647)
	daily_claims.clear()
	owned_lights.clear()
	for order in ORDERS:
		if value.get("daily_claims") is Array and order.id in value.daily_claims and order_progress(order)>=1: daily_claims.append(order.id)
	for light in LIGHTS:
		if value.get("owned_lights") is Array and light.id in value.owned_lights: owned_lights.append(light.id)
	light_style=""
	equip_light(str(value.get("light_style","")))
	roll_day()
	if value.get("claimed") is Array:
		for id in value.claimed:
			if id is String and eligible(id) and id not in claimed: claimed.append(id)
	if value.get("equipped") is Dictionary:
		for i in range(16):
			var slots=value.equipped.get(str(i),{})
			if slots is Dictionary:
				for slot in ["pin","skin"]:
					if slots.get(slot) is String: equip(i,slot,slots[slot])
static func number(value,limit: int) -> int:
	return clampi(int(value),0,limit) if typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) else 0
