extends Node
const Catalog=preload("res://scripts/furniture_catalog.gd")
const Piece=preload("res://scripts/furniture_window.gd")
var app
var pieces: Dictionary={}
var panel: Window
var buttons: Dictionary={}
var placement_buttons: Dictionary={}
var home_delay=8.0
var last_home=""
var drop_target=""
var space_picker: OptionButton
const HOME_IDS={"home_food":"table","home_water":"table","home_tea":"table","home_sofa":"sofa","home_shelf":"shelf","home_lamp":"lamp","home_reading_chair":"reading_chair","home_daybed":"daybed","home_vanity":"vanity","home_record_player":"record_player","home_play_rug":"play_rug","home_window_seat":"window_seat","home_tv":"tv","home_turntable":"turntable"}
const Home=preload("res://scripts/home_animation.gd")
func _ready() -> void:
	for id in app.state.furniture:
		var at=app.state.furniture[id]
		place(id,Vector2(at[0],at[1]),false)
		if pieces.has(id): pieces[id].set_mirrored(at.size()>2 and at[2]==true)
func place(id: String,at=Vector2.INF,persist: bool=true) -> void:
	if not Catalog.ITEMS.has(id) or Catalog.texture(id)==null: return
	if pieces.has(id): return
	var piece=Piece.new()
	piece.item_id=id
	add_child(piece)
	if not at.is_finite():
		var rect=app.usable_screen()
		var slot=Catalog.ITEMS.keys().find(id)
		at=Vector2(rect.position)+Vector2(rect.size.x*.5-300+(slot%5)*155,rect.size.y*.78-(slot/5)*155)-Vector2(piece.size.x*.5,piece.size.y)
		if app.state.activity_space=="floor":
			# Prefer an unused horizontal slot for a newly added decoration.
			for x in range(rect.position.x+160,rect.end.x-piece.size.x-160,24):
				var occupied=false
				for other in pieces.values():
					if x<other.position.x+other.size.x+12 and x+piece.size.x+12>other.position.x: occupied=true
				if not occupied:
					at.x=x
					break
	piece.position=piece.clamp_position(at)
	floor_piece(piece)
	piece.moved.connect(func():
		save()
		if is_instance_valid(app.pet) and HOME_IDS.get(app.pet.motion.visit_id,"")==id: use_piece(id))
	piece.layer_changed.connect(app.request_layer_order)
	piece.removed.connect(func(): remove_piece(id))
	piece.activated.connect(func(action): use_piece(id,action))
	pieces[id]=piece
	app.request_layer_order()
	if persist: save()
	refresh_world()
	refresh_buttons()
	call_deferred("keep_panel_front")
func keep_panel_front() -> void:
	if is_instance_valid(panel) and panel.visible and DisplayServer.get_name()!="headless":
		DisplayServer.window_move_to_foreground(panel.get_window_id())
func remove_piece(id: String) -> void:
	if not pieces.has(id): return
	if is_instance_valid(app.pet) and HOME_IDS.get(app.pet.motion.visit_id,"")==id: app.pet.motion.cancel_play()
	pieces[id].hide()
	pieces[id].queue_free()
	pieces.erase(id)
	save()
	refresh_world()
	refresh_buttons()
func save() -> void:
	var previous=app.state.furniture.duplicate(true)
	app.state.furniture.clear()
	for id in pieces:
		floor_piece(pieces[id])
		var at: Vector2i=pieces[id].position
		var saved_y=previous[id][1] if app.state.activity_space=="floor" and previous.has(id) else at.y
		app.state.furniture[id]=[at.x,saved_y]
		if pieces[id].mirrored: app.state.furniture[id].append(true)
	app.state.save_game()
	app.request_layer_order()
	refresh_world()
	refresh_buttons()
func floor_piece(piece) -> void:
	piece.floor_locked=app.state.activity_space=="floor"
	if app.state.activity_space!="floor": return
	var floor_y=preload("res://scripts/living_space.gd").ground(Rect2(app.usable_screen()))
	var at=Vector2(piece.position)
	at.y+=floor_y-piece.art_point(Vector2(.5,.94)).y
	piece.position=piece.clamp_position(at)
	piece.floor_top=piece.position.y
func apply_space() -> void:
	for id in pieces:
		if app.state.activity_space=="desktop" and app.state.furniture.has(id):
			var at=app.state.furniture[id]
			pieces[id].position=pieces[id].clamp_position(Vector2(at[0],at[1]))
		floor_piece(pieces[id])
	refresh_buttons()
func refresh_world() -> void:
	if not is_instance_valid(app.pet): return
	app.apply_prop_visibility()
	app.refresh_destinations()
func replaces(id: String) -> bool:
	return (pieces.has("table") and id in ["bowl","water"]) or (pieces.has("sofa") and id in ["cushion","shelter"]) or (pieces.has("lamp") and id=="lamp")
func destinations() -> Array:
	var result=[]
	if not is_instance_valid(app.pet): return result
	for id in HOME_IDS:
		var piece_id: String=HOME_IDS[id]
		if not pieces.has(piece_id) or not pieces[piece_id].visible or pieces[piece_id].dragging: continue
		if id=="home_food" and not app.state.unlocked(app.state.selected,"bowl"): continue
		if id=="home_water" and not app.state.unlocked(app.state.selected,"water"): continue
		var action="home_use" if Home.KINDS.has(id) and Home.available(app.pet.motion) else {"home_food":"eat","home_water":"drink","home_tea":"drink","home_sofa":"relax","home_shelf":"sniff","home_lamp":"doze","home_reading_chair":"relax","home_daybed":"doze","home_vanity":"groom","home_record_player":"look","home_play_rug":"playful","home_window_seat":"relax","home_tv":"relax","home_turntable":"look"}[id]
		result.append({"point":destination_point(id),"action":action,"id":id})
	return result
func destination_point(id: String) -> Vector2:
	var p=pieces[HOME_IDS[id]]
	var m=app.pet.motion
	var side=-1.0 if p.mirrored else 1.0
	var point=p.art_point(Vector2(.5,.94))
	if id in ["home_food","home_water","home_tea"]:
		var contact=p.art_point(Vector2(.35,.35) if id=="home_water" else Vector2(.68,.35))
		if id=="home_water":
			# Stand beside the low table and lift a water cup. Ground-level pond
			# cels would make the body float to reach an elevated tabletop bowl.
			point=contact-Vector2(24*side,-36)*m.growth_scale
		else:
			point=contact-Vector2(34*side,-36)*m.growth_scale
	elif id=="home_shelf": point+=Vector2(-p.size.x*.55*side,0)
	elif id=="home_lamp": point+=Vector2(-p.size.x*.65*side,0)
	elif id in ["home_vanity","home_record_player","home_tv","home_turntable"]: point+=Vector2(-p.size.x*.6*side,0)
	if id in ["home_tv","home_turntable"] and (point.x<m.bounds.position.x or point.x>m.bounds.end.x):
		point.x=p.art_point(Vector2(.5,.94)).x+p.size.x*.6*side
	return point.clamp(m.bounds.position,m.bounds.end)
func drop_candidate(feet: Vector2,cursor: Vector2=Vector2.INF) -> String:
	if not is_instance_valid(app.pet) or app.decorating or not app.hunt.is_empty(): return ""
	if app.commerce_access!=null and not app.commerce_access.permits(app.state.selected): return ""
	var chosen=""
	var best=INF
	for id in pieces:
		var piece=pieces[id]
		if not piece.visible or piece.dragging or piece.menu.visible: continue
		var area=Rect2(Vector2(piece.position)+piece.sprite.position,piece.sprite.texture.get_size()*piece.sprite.scale)
		var distance=feet.distance_to(feet.clamp(area.position,area.end))
		var score=distance+feet.distance_to(area.get_center())*.12
		# Also accept the grabbed point over the furniture, especially when the
		# animal was picked up by its ears/head. Prefer actual foot contact.
		if cursor.is_finite():
			var cursor_distance=cursor.distance_to(cursor.clamp(area.position,area.end))
			if cursor_distance<=12:
				score=minf(score,cursor_distance+cursor.distance_to(area.get_center())*.12+8)
				distance=minf(distance,cursor_distance)
		if distance<=28 and score<best:
			chosen=id
			best=score
	return chosen
func preview_drop(feet: Vector2=Vector2.INF,cursor: Vector2=Vector2.INF) -> String:
	drop_target=drop_candidate(feet,cursor) if feet.is_finite() else ""
	for id in pieces: pieces[id].set_drop_hover(id==drop_target)
	return drop_target
func accept_drop(feet: Vector2,cursor: Vector2=Vector2.INF) -> bool:
	# Re-evaluate at release: the furniture may have moved or been removed.
	var id=drop_candidate(feet,cursor)
	preview_drop()
	if id.is_empty(): return false
	return use_piece(id)
func use_piece(id: String,action: String="default") -> bool:
	if not is_instance_valid(app.pet) or not pieces.has(id) or app.decorating: return false
	if app.commerce_access!=null and not app.commerce_access.permits(app.state.selected): return false
	var key="home_"+id
	if id=="table": key="home_water" if action=="drink" else ("home_food" if action=="eat" else "home_tea")
	for destination in destinations():
		if destination.id!=key: continue
		app.cancel_feeding()
		app.cancel_hunt()
		app.pet.motion.visit(destination.point,destination.action,key,true)
		app.request_layer_order()
		home_delay=18.0
		last_home=key
		return true
	app.pet.motion.say("조금 더 친해지면 함께할 수 있어")
	return false
func on_visit(id: String) -> void:
	if not HOME_IDS.has(id) or not pieces.has(HOME_IDS[id]): return
	app.request_layer_order()
	var m=app.pet.motion
	m.facing=-1 if pieces[HOME_IDS[id]].mirrored else 1
	if id in ["home_tv","home_turntable"]:
		m.facing=1 if pieces[HOME_IDS[id]].art_point(Vector2(.5,.94)).x>=m.feet.x else -1
	m.say({"home_food":"잘 먹을게","home_water":"시원해","home_tea":"차 한 잔","home_sofa":"포근해","home_shelf":"한 장 더","home_lamp":"잠깐 쉬자","home_reading_chair":"책 읽는 시간","home_daybed":"조금만 잘게","home_vanity":"단정하게","home_record_player":"좋은 노래","home_play_rug":"같이 놀자","home_window_seat":"느긋한 오후","home_tv":"같이 볼까","home_turntable":"이 곡 좋아"}[id])
	last_home=id
	home_delay=18
func _process(delta: float) -> void:
	if not is_instance_valid(app.pet): return
	var m=app.pet.motion
	for id in pieces:
		pieces[id].set_active(HOME_IDS.get(m.visit_id,"")==id and m.phase!="visit")
		if pieces[id].dragging and HOME_IDS.get(m.visit_id,"")==id: m.cancel_play()
	if pieces.has("table"):
		var amount=1.0
		if m.visit_id=="home_food" and m.phase=="eat": amount=1.0-smoothstep(.7,3.5,m.elapsed)
		pieces.table.set_food(preload("res://scripts/food_catalog.gd").icon_for(m.species,m.food_id),amount)
	# Furniture is part of normal autonomous life, with a quiet pause between visits.
	if m.held or m.resting or not m.autonomy or app.decorating or app.objects_are_dragging() or app.pet.menu.visible: return
	home_delay=maxf(0,home_delay-delta)
	if home_delay>0 or m.phase!="idle" or not app.falling_gifts.is_empty(): return
	var choices=destinations().filter(func(d): return d.id!=last_home)
	if choices.is_empty(): return
	var choice=choices[m.rng.randi_range(0,choices.size()-1)]
	for d in choices:
		if (m.hydration<55 and d.id=="home_water") or (m.satiety<55 and d.id=="home_food") or (m.energy<35 and d.id=="home_sofa"): choice=d
	m.visit(choice.point,choice.action,choice.id,true)
	home_delay=18
	last_home=choice.id
func refresh_buttons() -> void:
	if is_instance_valid(space_picker): space_picker.select(0 if app.state.activity_space=="floor" else 1)
	for id in buttons: buttons[id].text="치우기" if pieces.has(id) else "배치하기"
	for id in placement_buttons:
		for control in placement_buttons[id]: control.disabled=not pieces.has(id)
		placement_buttons[id][2].text="반전 ✓" if pieces.has(id) and pieces[id].mirrored else "좌우 반전"
func open() -> void:
	if not is_instance_valid(panel): build_panel()
	refresh_buttons()
	var rect=app.usable_screen()
	panel.position=rect.position+(rect.size-panel.size)/2
	panel.show()
	if DisplayServer.get_name()!="headless": DisplayServer.window_move_to_foreground(panel.get_window_id())
func build_panel() -> void:
	panel=Window.new()
	panel.visible=false
	panel.force_native=true
	panel.title="나의 작은 공간 · 가구 배치"
	panel.size=Vector2i(470,620)
	panel.unresizable=true
	panel.always_on_top=true
	panel.theme=app.app_theme
	panel.close_requested.connect(func(): panel.hide())
	add_child(panel)
	var background=ColorRect.new()
	background.color=Color("faf8f3")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(background)
	var column=VBoxContainer.new()
	column.position=Vector2(22,18)
	column.size=Vector2(426,580)
	column.add_theme_constant_override("separation",10)
	panel.add_child(column)
	var heading=Label.new()
	heading.text="나의 작은 공간"
	heading.add_theme_font_size_override("font_size",22)
	heading.add_theme_color_override("font_color",Color("59564f"))
	column.add_child(heading)
	var hint=Label.new()
	hint.text="동물을 끌어 가구에 놓으면 이용해요. 클릭해도 찾아가요.\n가구 끌기 / ← →: 이동 · 좌우 반전: 방향 바꾸기"
	hint.add_theme_font_size_override("font_size",13)
	hint.add_theme_color_override("font_color",Color("777167"))
	column.add_child(hint)
	space_picker=OptionButton.new()
	space_picker.add_item("활동 공간: 아래쪽 바닥 (기본)")
	space_picker.add_item("활동 공간: 화면 전체")
	style_button(space_picker)
	space_picker.selected=0 if app.state.activity_space=="floor" else 1
	space_picker.item_selected.connect(func(index): app.set_activity_space("floor" if index==0 else "desktop"))
	column.add_child(space_picker)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(426,380)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var rows=VBoxContainer.new()
	rows.add_theme_constant_override("separation",10)
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for id in Catalog.ITEMS:
		var item=VBoxContainer.new()
		rows.add_child(item)
		var row=HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		item.add_child(row)
		var preview=TextureRect.new()
		preview.texture=Catalog.texture(id)
		preview.custom_minimum_size=Vector2(64,68)
		preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(preview)
		var label=Label.new()
		label.text=Catalog.ITEMS[id].name
		label.custom_minimum_size=Vector2(195,0)
		label.add_theme_color_override("font_color",Color("59564f"))
		row.add_child(label)
		var button=Button.new()
		button.custom_minimum_size=Vector2(86,36)
		button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		style_button(button)
		button.pressed.connect(func():
			if pieces.has(id): remove_piece(id)
			else: place(id))
		row.add_child(button)
		buttons[id]=button
		var placement=HBoxContainer.new()
		placement.alignment=BoxContainer.ALIGNMENT_END
		placement.add_theme_constant_override("separation",8)
		item.add_child(placement)
		placement_buttons[id]=[]
		for action in [-1,1,0]:
			var control=Button.new()
			control.text="←" if action==-1 else ("→" if action==1 else "좌우 반전")
			control.tooltip_text="24px 왼쪽" if action==-1 else ("24px 오른쪽" if action==1 else "가구와 상호작용 방향 반전")
			control.custom_minimum_size=Vector2(88 if action==0 else 44,30)
			style_button(control)
			control.pressed.connect(func():
				if not pieces.has(id): return
				if action==0: pieces[id].set_mirrored(not pieces[id].mirrored,true)
				else: pieces[id].nudge(action*24))
			placement.add_child(control)
			placement_buttons[id].append(control)
	var done=Button.new()
	done.text="배치 마치기"
	style_button(done)
	done.pressed.connect(func(): save(); panel.hide())
	column.add_child(done)
func style_button(button: Button) -> void:
	for key in ["normal","hover","pressed"]:
		var style=StyleBoxFlat.new()
		style.bg_color=Color("e5eadd") if key=="normal" else Color("d3dfc8")
		style.set_corner_radius_all(8)
		style.content_margin_top=8
		style.content_margin_bottom=8
		button.add_theme_stylebox_override(key,style)
	button.add_theme_color_override("font_color",Color("4d6045"))
	button.add_theme_color_override("font_hover_color",Color("344830"))
