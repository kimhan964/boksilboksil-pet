extends RefCounted
# Finite, permanent milestone collection: inputs AND activity time; no duplicate drops.
const ITEMS=[
	{"id":"ribbon","name":"로즈 리본","slot":"pin","actions":60,"seconds":15,"color":"c99eaa"},
	{"id":"clover","name":"클로버 핀","slot":"pin","actions":300,"seconds":120,"color":"95af89"},
	{"id":"daisy","name":"데이지 브로치","slot":"pin","actions":1000,"seconds":300,"color":"e9d7a5"},
	{"id":"oat","name":"오트 라떼","slot":"skin","actions":1500,"seconds":600,"color":"d1b990"},
	{"id":"star","name":"작은 별 핀","slot":"pin","actions":3000,"seconds":900,"color":"d2b578"},
	{"id":"rose","name":"로즈 밀크","slot":"skin","actions":5000,"seconds":1800,"color":"ceabb7"},
	{"id":"mist","name":"안개 세이지","slot":"skin","actions":10000,"seconds":3600,"color":"a6bcae"}]
const TINTS={"":Vector3.ZERO,"oat":Vector3(.045,.018,-.035),"rose":Vector3(.045,-.018,.025),"mist":Vector3(-.035,.02,.018)}
var actions=0
var active_ms=0
var claimed: Array[String]=[]
var equipped: Dictionary={}

func item(id: String) -> Dictionary:
	for entry in ITEMS:
		if entry.id==id: return entry
	return {}
func eligible(id: String) -> bool:
	var entry=item(id)
	return not entry.is_empty() and actions>=entry.actions and active_ms>=entry.seconds*1000
func credit(count: int, milliseconds: int) -> bool:
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
	return "작은 선물 7종을 모두 모았어요"
func serialize() -> Dictionary:
	return {"actions":actions,"active_ms":active_ms,"claimed":claimed,"equipped":equipped}
func restore(value) -> void:
	if not value is Dictionary: return
	actions=number(value.get("actions"),2147483647)
	active_ms=number(value.get("active_ms"),900000000000)
	claimed.clear()
	equipped.clear()
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
