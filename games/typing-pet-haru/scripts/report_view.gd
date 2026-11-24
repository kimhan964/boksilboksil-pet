extends ScrollContainer
const Cozy=preload("res://scripts/cozy_ui.gd")
var app
var body: VBoxContainer
var elapsed=0.0
func _ready():
	name="리포트"
	horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body=VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",Cozy.CARD_GAP)
	add_child(body)
	rebuild()
func _process(dt):
	if not is_visible_in_tree(): return
	elapsed+=dt
	if elapsed>=5:
		elapsed=0
		rebuild()
func text(parent: Node,s: String,font_size=14):
	var l=Label.new()
	l.text=s
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.set_meta("base_font_size",font_size)
	l.add_theme_font_size_override("font_size",maxi(Cozy.MIN_FONT,roundi(font_size*app.text_scale)))
	parent.add_child(l)
func card(title_: String) -> VBoxContainer:
	var panel=PanelContainer.new()
	panel.add_theme_stylebox_override("panel",Cozy.card_style())
	body.add_child(panel)
	var box=VBoxContainer.new()
	box.add_theme_constant_override("separation",Cozy.INNER_GAP)
	panel.add_child(box)
	text(box,title_,20)
	return box
func chart(parent,values,captions,color,unit,maximum=0):
	var c=preload("res://scripts/report_chart.gd").new()
	c.values=values
	c.captions=captions
	c.color=Color(color)
	c.unit=unit
	c.fixed_max=maximum
	c.text_scale=app.text_scale
	parent.add_child(c)
func rebuild():
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var now=Time.get_datetime_dict_from_system()
	var date="%04d-%02d-%02d"%[now.year,now.month,now.day]
	var summary=app.report.summary(date)
	var today=card("오늘 · "+date)
	text(today,"입력 활동 %d분 · %d타"%[summary.active_ms/60000,summary.keys],24)
	text(today,"최고 COMBO %d · 단계 달성 %d회 · 집중 지속 지수 %d점"%[summary.peak,summary.combos,summary.focus])
	text(today,"오늘 첫 타자 "+str(app.report.days.get(date,{}).get("first","아직 기록 없음")))
	text(today,"최근 60초 30·90·180·300타 단계에 올라갈 때 1회 집계합니다. COMBO는 최근 60초 타자 수이며, 5초 동안 타자가 없으면 초기화됩니다.",12)
	var hours=app.report.days.get(date,{}).get("hours",{})
	var labels=[]
	var keys=[]
	var combos=[]
	var focus=[]
	for h in range(24):
		var row=hours.get(str(h),{})
		labels.append(str(h)+"시")
		keys.append(int(row.get("keys",0)))
		combos.append(int(row.get("combos",0)))
		var minutes=row.get("minutes",[]).size()
		focus.append(clampi(roundi(float(row.get("active_ms",0))/maxi(1,minutes*60000)*100),0,100))
	chart(card("시간당 타자 수"),keys,labels,"a4b69a","타")
	chart(card("시간당 COMBO 달성"),combos,labels,"d99cab","회")
	chart(card("시간당 집중 지속 지수"),focus,labels,"c6b27f","점",100)
	var explanation=card("집중 지수는 이렇게 계산해요")
	text(explanation,"키 입력 후 10초 이내 이어진 활동 시간 ÷ 입력이 있었던 분의 총 시간 × 100. 실제 집중력이나 업무 성과를 측정한 값이 아닙니다. 읽기·생각하기·마우스 작업은 반영되지 않아요.",12)
	var midnight=Time.get_unix_time_from_datetime_string(date+"T00:00:00")
	var monday=midnight-((int(now.weekday)+6)%7)*86400
	for offset in [0,7]:
		var week=card("이번 주" if offset==0 else "지난주 리포트")
		var minutes=[]
		var week_keys=[]
		var week_combos=[]
		var week_focus=[]
		var total=0
		for d in range(7):
			var key=Time.get_date_string_from_unix_time(monday+(d-offset)*86400)
			var s=app.report.summary(key)
			minutes.append(int(s.active_ms/60000))
			week_keys.append(s.keys)
			week_combos.append(s.combos)
			week_focus.append(s.focus)
			total+=s.keys
		text(week,"총 %d타 · COMBO %d회"%[total,week_combos.reduce(func(a,b): return a+b,0)])
		text(week,"입력 활동 시간")
		chart(week,minutes,["월","화","수","목","금","토","일"],"d99cab","분")
		text(week,"타자 수")
		chart(week,week_keys,["월","화","수","목","금","토","일"],"a4b69a","타")
		text(week,"COMBO 단계 달성")
		chart(week,week_combos,["월","화","수","목","금","토","일"],"c6b27f","회")
		text(week,"집중 지속 지수")
		chart(week,week_focus,["월","화","수","목","금","토","일"],"b1a9c0","점",100)
		if total==0: text(week,"이 기간에는 아직 타자 기록이 없어요.",12)
	text(body,"기록은 이 PC에 최대 370일 보관됩니다. 업데이트 전 날짜별 기록은 소급 생성하지 않습니다. 입력한 글자나 내용은 저장하지 않아요.",12)
	Cozy.apply_dialog_spacing(body)
