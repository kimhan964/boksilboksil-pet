extends RefCounted
# Aggregate counts only. No key identities or entered text are retained.
const COMBO_TIMEOUT_MS=5000
const RETENTION_DAYS=370
const THRESHOLDS=[30,90,180,300]
var remaining=0.0
var days={}
var revision=0
var buckets={}
var combo=0
var tier=0
var last_ms=-1
var last_key=-1
var was_enabled=false
var previous_stamp=0
var calendar_second=-1
var bucket_second=-1
var calendar_day=""
var calendar_hour=0
var calendar_minute=0
var calendar_stamp=0
var previous_day=""
var previous_hour=-1
var retention_day=""
func step(now: int,keys: int,enabled: bool,calendar: Dictionary={}) -> void:
	var second=int(now/1000)
	var wall_second=int(Time.get_unix_time_from_system()) if calendar.is_empty() else second
	if calendar_second!=wall_second or not calendar.is_empty():
		var stamp=calendar if not calendar.is_empty() else Time.get_datetime_dict_from_system()
		calendar_day="%04d-%02d-%02d"%[stamp.year,stamp.month,stamp.day]
		calendar_hour=int(stamp.hour)
		calendar_minute=int(stamp.minute)
		calendar_stamp=Time.get_unix_time_from_datetime_dict(stamp)
		calendar_second=wall_second
		if retention_day!=calendar_day: prune(calendar_day)
	if not enabled:
		if was_enabled or combo>0: clear_combo()
		last_key=-1
		remaining=0
	else:
		# Clear stale rates after suspension/disconnection; never extrapolate startup input.
		if last_ms>=0 and now-last_ms>2500:
			clear_combo()
			last_key=-1
		if last_key>=0 and now-last_key>=COMBO_TIMEOUT_MS and combo>0: clear_combo()
		remaining=clampf(1.0-float(now-last_key)/COMBO_TIMEOUT_MS,0,1) if last_key>=0 else 0.0
		if keys>0: remaining=1.0
		if bucket_second!=second:
			if not buckets.is_empty():
				for s in buckets.keys():
					if s<=second-60:
						combo-=int(buckets[s])
						buckets.erase(s)
			bucket_second=second
		if keys>0:
			buckets[second]=int(buckets.get(second,0))+keys
			combo+=keys
		var next_tier=tier
		if keys>0 or next_tier>0:
			next_tier=0
			for threshold in THRESHOLDS:
				if combo>=threshold: next_tier+=1
		var events=maxi(0,next_tier-tier) if keys>0 else 0
		var dt=clampi(now-last_ms,0,2000) if last_ms>=0 and was_enabled else 0
		var active=dt if last_key>=0 and now-last_key<=10000 else 0
		if keys>0: last_key=now
		# Do not carry a partial sampling interval across a day/hour boundary.
		if active>0 and (previous_day!=calendar_day or previous_hour!=calendar_hour): active=0
		if keys>0 or active>0:
			if not days.has(calendar_day): days[calendar_day]={"hours":{}}
			var day=days[calendar_day]
			if keys>0 and (not day.has("first") or day.first in ["","—"]): day.first="%02d:%02d"%[calendar_hour,calendar_minute]
			var h=str(calendar_hour)
			if not day.hours.has(h): day.hours[h]={"keys":0,"combos":0,"active_ms":0,"peak":0,"minutes":[]}
			var row=day.hours[h]
			row.keys+=maxi(0,keys)
			row.combos+=events
			row.active_ms+=active
			row.peak=maxi(int(row.peak),combo)
			if keys>0 and not row.minutes.has(calendar_minute): row.minutes.append(calendar_minute)
			revision+=1
		tier=next_tier
	last_ms=now
	previous_stamp=calendar_stamp
	previous_day=calendar_day
	previous_hour=calendar_hour
	was_enabled=enabled
func clear_combo() -> void:
	buckets.clear()
	combo=0
	tier=0
func summary(day: String) -> Dictionary:
	var result={"keys":0,"combos":0,"active_ms":0,"peak":0,"focus":0,"minutes":0}
	for row in days.get(day,{}).get("hours",{}).values():
		for key in ["keys","combos","active_ms"]: result[key]+=int(row.get(key,0))
		result.peak=maxi(result.peak,int(row.get("peak",0)))
		result.minutes+=row.get("minutes",[]).size()
	if result.minutes>0: result.focus=clampi(roundi(result.active_ms/(result.minutes*60000.0)*100),0,100)
	return result
func date_stamp(day: Variant) -> int:
	if not day is String or day.length()!=10 or day[4]!="-" or day[7]!="-": return -1
	var parts=day.split("-")
	if parts.size()!=3 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int(): return -1
	var year=int(parts[0])
	var month=int(parts[1])
	var date=int(parts[2])
	if year<1970 or year>9999 or month<1 or month>12: return -1
	var lengths=[31,28,31,30,31,30,31,31,30,31,30,31]
	if year%4==0 and (year%100!=0 or year%400==0): lengths[1]=29
	if date<1 or date>lengths[month-1] or day!="%04d-%02d-%02d"%[year,month,date]: return -1
	return Time.get_unix_time_from_datetime_dict({"year":year,"month":month,"day":date,"hour":0,"minute":0,"second":0})
func prune(today: String) -> void:
	var today_stamp=date_stamp(today)
	if today_stamp<0: return
	retention_day=today
	var cutoff=today_stamp-(RETENTION_DAYS-1)*86400
	var changed=false
	for day in days.keys():
		var stamp=date_stamp(day)
		# Preserve valid future dates when the system clock has moved backwards.
		if stamp<0 or stamp<cutoff:
			days.erase(day)
			changed=true
	if changed: revision+=1
func restore(data: Variant,calendar: Dictionary={}) -> void:
	if not data is Dictionary: return
	var today=calendar if not calendar.is_empty() else Time.get_datetime_dict_from_system()
	var today_key="%04d-%02d-%02d"%[today.year,today.month,today.day]
	var cutoff=date_stamp(today_key)-(RETENTION_DAYS-1)*86400
	var changed=false
	for day in data:
		var stamp=date_stamp(day)
		if stamp<0 or stamp<cutoff or not data[day] is Dictionary: continue
		var clean={"hours":{}}
		if data[day].has("first"): clean.first=str(data[day].first)
		var hours=data[day].get("hours",{})
		if not hours is Dictionary: continue
		for h in hours:
			if not str(h).is_valid_int() or int(h)<0 or int(h)>23 or not hours[h] is Dictionary: continue
			var row={"minutes":[]}
			for k in ["keys","combos","active_ms","peak"]:
				var v=hours[h].get(k,0)
				row[k]=clampi(int(v),0,1000000000) if typeof(v) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(v)) else 0
			var minutes=hours[h].get("minutes",[])
			if minutes is Array:
				for m in minutes:
					if typeof(m) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(m)) and int(m)>=0 and int(m)<60 and not row.minutes.has(int(m)): row.minutes.append(int(m))
			clean.hours[str(int(h))]=row
		if days.get(day)!=clean:
			days[day]=clean
			changed=true
	if changed: revision+=1
	prune(today_key)
