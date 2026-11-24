extends Window
const Catalog=preload("res://scripts/catalog.gd")
const Pin=preload("res://scripts/pin.gd")
const Cozy=preload("res://scripts/cozy_ui.gd")
const GiftButton=preload("res://scripts/gift_button.gd")
const ReportChart=preload("res://scripts/report_chart.gd")
var app
var content: Control
var progress_text: Label
var progress_bar: ProgressBar
var tabs: TabContainer
var tab_buttons: Array[Button]=[]
var tab_strip: HBoxContainer
var tab=0
var preview_pin
var present: Control
var resize_tween: Tween
var cafe_rows=[]
var cafe_balance: Label
var collection_count: Label
var cafe_notice: Label
var cafe_notice_text="오늘의 주문은 날짜가 바뀌면 새로 준비돼요"
func _init() -> void:
	visible=false
	force_native=true
	always_on_top=true
	unresizable=true
	size=Vector2i(Cozy.SETTINGS_WIDTH,Cozy.SETTINGS_HEIGHT)
	title="단짝 타자친구 · 설정과 작은 선물"
func _ready() -> void:
	theme=Cozy.dialog_theme()
	var available=available_screen()
	if available.size.y>0: size.y=mini(Cozy.SETTINGS_HEIGHT,maxi(1,available.size.y-Cozy.OUTER*2))
	close_requested.connect(hide)
func label(text_: String,font_size: int=14) -> Label:
	var result=Label.new()
	result.text=text_
	result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size",maxi(Cozy.MIN_FONT,font_size))
	return result
func button(text_: String,action: Callable) -> Button:
	var result=Button.new()
	result.text=text_
	result.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	result.pressed.connect(action)
	return result
func section(parent: VBoxContainer,title_: String) -> VBoxContainer:
	var card=PanelContainer.new()
	card.add_theme_stylebox_override("panel",Cozy.card_style())
	parent.add_child(card)
	var body=VBoxContainer.new()
	body.add_theme_constant_override("separation",Cozy.INNER_GAP)
	card.add_child(body)
	var title_label=label(title_,19)
	title_label.add_theme_font_override("font",Cozy.heading_font())
	title_label.add_theme_color_override("font_color",Color("5b4636"))
	var heading=HBoxContainer.new()
	heading.alignment=BoxContainer.ALIGNMENT_CENTER
	heading.add_theme_constant_override("separation",Cozy.GRID)
	body.add_child(heading)
	var symbol=TextureRect.new()
	symbol.texture=Cozy.icon({"오늘 함께할 친구":"paw","내 책상에 쏙":"move","글씨도 편안하게":"text","작은 반응들":"heart","오늘의 스탬프 카드":"coffee","작은 교환소 · 입력 불빛":"gift","오늘의 첫 주문":"coffee","따뜻한 한 잔":"coffee","느긋한 작업 시간":"coffee"}.get(title_,"paw"))
	symbol.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	symbol.custom_minimum_size=Vector2(24,24)
	heading.add_child(symbol)
	heading.add_child(title_label)
	return body
func rebuild() -> void:
	cafe_rows.clear()
	if resize_tween and resize_tween.is_valid(): resize_tween.kill()
	if is_instance_valid(tabs): tab=tabs.current_tab
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content=PanelContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background=Cozy.box("fff7ec",0)
	background.content_margin_left=Cozy.OUTER
	background.content_margin_right=Cozy.OUTER
	background.content_margin_top=Cozy.OUTER
	background.content_margin_bottom=Cozy.OUTER
	content.add_theme_stylebox_override("panel",background)
	add_child(content)
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",Cozy.MAJOR_GAP)
	content.add_child(column)
	var heading=HBoxContainer.new()
	heading.alignment=BoxContainer.ALIGNMENT_CENTER
	heading.add_theme_constant_override("separation",Cozy.GRID)
	var title_group=VBoxContainer.new()
	title_group.add_theme_constant_override("separation",Cozy.GRID)
	column.add_child(title_group)
	title_group.add_child(heading)
	var paw=TextureRect.new()
	paw.texture=Cozy.icon("paw")
	paw.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	paw.custom_minimum_size=Vector2(26,26)
	heading.add_child(paw)
	var brand=label("단짝 타자친구",28)
	brand.add_theme_font_override("font",Cozy.heading_font())
	brand.add_theme_color_override("font_color",Color("5b4636"))
	heading.add_child(brand)
	title_group.add_child(label("작은 책상 카페 · 일하는 순간도 포근하게",12))
	var preview=PanelContainer.new()
	preview.name="ProfileCard"
	preview.add_theme_stylebox_override("panel",Cozy.card_style("efe1cc",true))
	column.add_child(preview)
	var profile_row=HBoxContainer.new()
	profile_row.add_theme_constant_override("separation",Cozy.PROFILE_GAP)
	preview.add_child(profile_row)
	var thumbnail=Control.new()
	thumbnail.custom_minimum_size=Vector2.ONE*Cozy.PROFILE_THUMB
	profile_row.add_child(thumbnail)
	var hero=Sprite2D.new()
	hero.centered=false
	hero.texture=app.widget.frames[0]
	hero.scale=Vector2.ONE*(float(Cozy.PROFILE_THUMB)/hero.texture.get_width())
	hero.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var mat=ShaderMaterial.new()
	mat.shader=preload("res://scripts/tone.gdshader")
	mat.set_shader_parameter("balance",Catalog.TONES[app.species])
	mat.set_shader_parameter("shift",app.collection.TINTS.get(app.collection.selected(app.species,"skin"),Vector3.ZERO))
	hero.material=mat
	thumbnail.add_child(hero)
	preview_pin=Pin.new()
	preview_pin.kind=app.collection.selected(app.species,"pin")
	preview_pin.worn=true
	preview_pin.position=Catalog.accessory_anchor(app.species,preview_pin.kind)*Cozy.PROFILE_THUMB
	preview_pin.scale=Vector2.ONE*(Cozy.PROFILE_THUMB/200.0)
	thumbnail.add_child(preview_pin)
	var profile_text=VBoxContainer.new()
	profile_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	profile_text.alignment=BoxContainer.ALIGNMENT_CENTER
	profile_text.add_theme_constant_override("separation",Cozy.INNER_GAP)
	profile_row.add_child(profile_text)
	var friend_name=label(Catalog.NAMES[app.species],21)
	friend_name.add_theme_font_override("font",Cozy.heading_font())
	profile_text.add_child(friend_name)
	profile_text.add_child(label("소장 %d / %d  ·  스탬프 %d"%[app.collection.claimed.size(),app.collection.ITEMS.size(),app.collection.stamps],12))
	tab_buttons.clear()
	tab_strip=HBoxContainer.new()
	tab_strip.name="TabStrip"
	tab_strip.alignment=BoxContainer.ALIGNMENT_CENTER
	tab_strip.add_theme_constant_override("separation",Cozy.TAB_GAP)
	column.add_child(tab_strip)
	tabs=TabContainer.new()
	tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	tabs.tabs_visible=false
	tabs.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	column.add_child(tabs)
	var options_scroll=ScrollContainer.new()
	options_scroll.name="친구 설정"
	options_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(options_scroll)
	var options=VBoxContainer.new()
	options.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation",Cozy.CARD_GAP)
	options_scroll.add_child(options)
	var friend_options=section(options,"오늘 함께할 친구")
	var species=OptionButton.new()
	species.alignment=HORIZONTAL_ALIGNMENT_CENTER
	for i in range(Catalog.NAMES.size()):
		species.add_item(Catalog.NAMES[i]+(" · 잠김" if not app.can_use(i) else ""))
		species.set_item_disabled(i,not app.can_use(i))
	species.select(app.species)
	species.item_selected.connect(app.choose_friend)
	friend_options.add_child(species)
	if app.commerce_enabled:
		friend_options.add_child(button("구매한 친구 · 계정 연결",func(): app.commerce.show_account()))
	var position_options=section(options,"내 책상에 쏙")
	var row=HBoxContainer.new()
	position_options.add_child(row)
	var corner=OptionButton.new()
	corner.alignment=HORIZONTAL_ALIGNMENT_CENTER
	corner.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for title_ in ["왼쪽 위","오른쪽 위","왼쪽 아래","오른쪽 아래"]: corner.add_item(title_)
	corner.select(app.corner)
	corner.item_selected.connect(func(value): app.corner=value; app.custom_position=false; app.widget.place(); app.save_game())
	row.add_child(corner)
	var presets=HBoxContainer.new()
	presets.add_theme_constant_override("separation",Cozy.BUTTON_GAP)
	position_options.add_child(presets)
	var size_buttons: Array[Button]=[]
	var factors=[.85,1.0,1.2]
	for i in range(3):
		var preset=button(["작게 · 85%","보통 · 100%","크게 · 120%"][i],func(): pass)
		preset.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		preset.toggle_mode=true
		preset.button_pressed=is_equal_approx(app.widget.root.scale.x,factors[i])
		presets.add_child(preset)
		size_buttons.append(preset)
	position_options.add_child(label("동물·APM 영역을 드래그하면 자유롭게 이동해요",12))
	var size_label=label("펫 크기 %d%%"%roundi(app.widget.root.scale.x*100),12)
	var slider_group=VBoxContainer.new()
	slider_group.add_theme_constant_override("separation",Cozy.GRID)
	position_options.add_child(slider_group)
	slider_group.add_child(size_label)
	var slider=HSlider.new()
	slider.min_value=70
	slider.max_value=150
	slider.step=1
	slider.value=app.widget.root.scale.x*100
	slider.custom_minimum_size=Vector2(0,24)
	slider.value_changed.connect(func(value):
		app.set_size(value/100.0)
		size_label.text="펫 크기 %d%%"%int(value)
		for i in range(3): size_buttons[i].set_pressed_no_signal(is_equal_approx(value/100.0,factors[i])))
	slider.drag_ended.connect(func(_changed): app.save_game())
	slider.drag_started.connect(func():
		if resize_tween and resize_tween.is_valid(): resize_tween.kill())
	for i in range(3):
		size_buttons[i].pressed.connect(func():
			if resize_tween and resize_tween.is_valid(): resize_tween.kill()
			app.zoom=i
			size_buttons[i].set_pressed_no_signal(true)
			resize_tween=create_tween()
			resize_tween.tween_property(slider,"value",factors[i]*100,.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			resize_tween.tween_callback(app.save_game))
	slider_group.add_child(slider)
	var text_options=section(options,"글씨도 편안하게")
	var text_row=HBoxContainer.new()
	text_options.add_child(text_row)
	var text_choice=OptionButton.new()
	text_choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text_choice.alignment=HORIZONTAL_ALIGNMENT_CENTER
	for percent in [90,100,110,120,130]: text_choice.add_item("글씨 크기 %d%%"%percent)
	text_choice.select(clampi(roundi((app.text_scale-.9)/.1),0,4))
	text_choice.item_selected.connect(func(index): app.set_text_size(.9+index*.1))
	text_row.add_child(text_choice)
	var reaction_options=section(options,"작은 반응들")
	var toggles=HBoxContainer.new()
	reaction_options.add_child(toggles)
	for property_ in ["show_lights","gift_effects","combo_effects"]:
		var toggle=button({"show_lights":"입력 불빛","gift_effects":"선물 반짝임","combo_effects":"콤보 효과"}[property_],func(): pass)
		toggle.toggle_mode=true
		toggle.button_pressed=app.get(property_)
		toggle.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var caption={"show_lights":"입력 불빛","gift_effects":"선물 반짝임","combo_effects":"콤보 효과"}[property_]
		toggle.text=caption+("\n켜짐" if toggle.button_pressed else "\n꺼짐")
		toggle.toggled.connect(func(value):
			app.set(property_,value)
			toggle.text=caption+("\n켜짐" if value else "\n꺼짐")
			app.save_game())
		toggles.add_child(toggle)
	reaction_options.add_child(button("입력 반응 다시 시작" if app.paused else "입력 반응 잠시 쉬기",app.toggle_pause))
	if not app.bridge.connected and not app.paused:
		reaction_options.add_child(button("입력 도우미 다시 연결",func(): app.bridge.start(); rebuild.call_deferred()))
	options.add_child(label("APM은 입력 속도에 따라 부드럽게 변해요.\n활동 시간은 30초간 입력이 없으면 멈춰요.",12))
	options.add_child(label("키보드·마우스의 입력 횟수만 사용해요.\n입력한 글자나 사용하는 프로그램은 저장하지 않아요.",11))
	var gifts=VBoxContainer.new()
	gifts.name="선물 · 꾸미기"
	gifts.add_theme_constant_override("separation",Cozy.INNER_GAP)
	tabs.add_child(gifts)
	progress_text=label("",12)
	gifts.add_child(progress_text)
	progress_bar=ProgressBar.new()
	progress_bar.custom_minimum_size=Vector2(0,8)
	progress_bar.show_percentage=false
	gifts.add_child(progress_bar)
	collection_count=label("소장 %d / %d · 모두 모아 나만의 친구로"%[app.collection.claimed.size(),app.collection.ITEMS.size()],12)
	gifts.add_child(collection_count)
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	gifts.add_child(scroll)
	var grid=GridContainer.new()
	grid.columns=2
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",Cozy.CARD_GAP)
	grid.add_theme_constant_override("v_separation",Cozy.CARD_GAP)
	scroll.add_child(grid)
	var entries=app.collection.ITEMS.duplicate()
	entries.sort_custom(func(a,b):
		var rank_a=0 if app.collection.eligible(a.id) and a.id not in app.collection.claimed else (1 if a.id in app.collection.claimed else 2)
		var rank_b=0 if app.collection.eligible(b.id) and b.id not in app.collection.claimed else (1 if b.id in app.collection.claimed else 2)
		return rank_a<rank_b if rank_a!=rank_b else a.actions<b.actions)
	for entry in entries: add_item_card(grid,entry)
	var reset=HBoxContainer.new()
	gifts.add_child(reset)
	for slot in ["pin","skin"]:
		var clear=button("액세서리 벗기기" if slot=="pin" else "기본 색상",func():
			app.collection.equip(app.species,slot,"")
			app.widget.apply_cosmetics()
			app.save_game()
			rebuild.call_deferred())
		clear.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		reset.add_child(clear)
	build_cafe_tab()
	var reports=preload("res://scripts/report_view.gd").new()
	reports.app=app
	tabs.add_child(reports)
	tabs.current_tab=clampi(tab,0,3)
	for i in range(4):
		var tab_button=button(tabs.get_tab_title(i),func(): pass)
		tab_button.name="TabButton%d"%i
		tab_button.add_theme_constant_override("h_separation",Cozy.TAB_ICON_GAP)
		if i<3: tab_button.icon=Cozy.icon(["paw","gift","coffee"][i],Cozy.TAB_ICON)
		tab_button.custom_minimum_size.y=Cozy.TAB_HEIGHT
		tab_button.toggle_mode=true
		tab_button.button_pressed=i==tabs.current_tab
		tab_button.pressed.connect(func(): tabs.current_tab=i)
		tab_strip.add_child(tab_button)
		tab_buttons.append(tab_button)
	tabs.tab_changed.connect(update_tab_states)
	update_tab_states(tabs.current_tab)
	var footer=HBoxContainer.new()
	footer.name="FooterButtons"
	footer.add_theme_constant_override("separation",Cozy.BUTTON_GAP)
	column.add_child(footer)
	var close=button("닫기",hide)
	close.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var quit_button=button("게임 종료",app.shutdown)
	quit_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer.add_child(quit_button)
	var help_button=button("도움말",app.open_tutorial)
	help_button.icon=Cozy.icon("help")
	help_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer.add_child(help_button)
	footer.add_child(close)
	for control in footer.get_children(): control.custom_minimum_size.y=Cozy.FOOTER_HEIGHT
	Cozy.apply_dialog_spacing(content)
	for tab_button in tab_buttons: tab_button.clip_text=false
	refresh_progress()
	apply_text_size()
func update_tab_states(index: int) -> void:
	var bold=FontVariation.new()
	bold.base_font=Cozy.heading_font()
	bold.variation_embolden=.7
	for i in range(tab_buttons.size()):
		var button_=tab_buttons[i]
		var selected=i==index
		button_.set_pressed_no_signal(selected)
		button_.add_theme_font_override("font",bold if selected else Cozy.heading_font())
		for state in ["normal","hover","pressed","hover_pressed","focus"]:
			var style=Cozy.box("f3c2be" if selected else ("fbe0dc" if state=="hover" else "fffdf8"),Cozy.CONTROL_RADIUS)
			style.content_margin_left=Cozy.TAB_PAD
			style.content_margin_right=Cozy.TAB_PAD
			style.content_margin_top=Cozy.GRID
			style.content_margin_bottom=Cozy.GRID
			style.set_border_width_all(Cozy.BORDER)
			style.border_color=Color("6b4a35")
			if state=="focus": style.bg_color=Color.TRANSPARENT
			button_.add_theme_stylebox_override(state,style)
func add_item_card(grid: GridContainer,entry: Dictionary) -> void:
	var card=PanelContainer.new()
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",Cozy.card_style())
	grid.add_child(card)
	var body=VBoxContainer.new()
	body.add_theme_constant_override("separation",Cozy.INNER_GAP)
	card.add_child(body)
	var icon=Control.new()
	icon.custom_minimum_size=Vector2(180,46)
	body.add_child(icon)
	if entry.slot=="pin":
		var badge=Pin.new()
		badge.kind=entry.id
		badge.position=Vector2(90,23)
		icon.resized.connect(func(): badge.position.x=icon.size.x/2)
		icon.add_child(badge)
	else:
		var swatch=Panel.new()
		swatch.position=Vector2(65,13)
		icon.resized.connect(func(): swatch.position.x=(icon.size.x-50)/2)
		swatch.size=Vector2(50,20)
		swatch.add_theme_stylebox_override("panel",preload("res://scripts/widget.gd").box(entry.color,8))
		icon.add_child(swatch)
	var item_name=label(entry.name,17)
	item_name.add_theme_font_override("font",Cozy.heading_font())
	body.add_child(item_name)
	var owned=entry.id in app.collection.claimed
	var ready=app.collection.eligible(entry.id)
	var selected=app.collection.selected(app.species,entry.slot)==entry.id
	var card_style=Cozy.card_style("f7c6c7" if selected else ("fbe0dc" if ready and not owned else "fffdf8"))
	card_style.border_color=Color("6b4a35" if selected else "6b4a35")
	card.add_theme_stylebox_override("panel",card_style)
	var hint="이 친구에게 장착 중" if selected else ("영구 소장 · 장착할 수 있어요" if owned else "%d/%d회 · %d/%d분"%[mini(app.collection.actions,entry.actions),entry.actions,mini(int(app.collection.active_ms/60000),int(ceil(entry.seconds/60.0))),int(ceil(entry.seconds/60.0))])
	if not owned and entry.seconds<60: hint="%d/%d회 · %d/%d초"%[mini(app.collection.actions,entry.actions),entry.actions,mini(int(app.collection.active_ms/1000),entry.seconds),entry.seconds]
	body.add_child(label(hint,12))
	var action=button("장착 중" if selected else ("장착하기" if owned else ("선물 받기" if ready else "아직 잠겨 있어요")),func():
		if not owned and not app.collection.claim(entry.id): return
		app.collection.equip(app.species,entry.slot,entry.id)
		app.widget.apply_cosmetics()
		app.save_game()
		rebuild.call_deferred()
		if not owned: show_present.call_deferred(entry))
	action.disabled=selected or (not owned and not ready)
	action.add_theme_font_size_override("font_size",14)
	body.add_child(action)
func refresh_progress() -> void:
	refresh_cafe()
	if not is_instance_valid(progress_text): return
	progress_text.text=app.collection.summary()
	progress_bar.value=100
	for entry in app.collection.ITEMS:
		if entry.id not in app.collection.claimed:
			progress_bar.value=app.collection.progress(entry)*100
			break
	# Rebuild on availability boundaries only, keeping scroll position stable while typing.
	var available=0
	for entry in app.collection.ITEMS:
		if app.collection.eligible(entry.id): available+=1
	if has_meta("available") and get_meta("available")!=available: rebuild.call_deferred()
	set_meta("available",available)
func show_present(entry: Dictionary) -> void:
	if is_instance_valid(present): present.queue_free()
	present=Control.new()
	present.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(present)
	var dim=ColorRect.new()
	dim.color=Color(.35,.30,.25,.25)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	present.add_child(dim)
	var center=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	present.add_child(center)
	var card=PanelContainer.new()
	card.custom_minimum_size.x=minf(440,size.x-Cozy.OUTER*2)
	card.add_theme_stylebox_override("panel",Cozy.card_style())
	center.add_child(card)
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",Cozy.INNER_GAP)
	card.add_child(column)
	column.add_child(label("작은 선물이 도착했어요",21))
	var subtitle=label("상자를 눌러 열어보세요",13)
	column.add_child(subtitle)
	var stage=Control.new()
	stage.custom_minimum_size.y=112
	column.add_child(stage)
	var gift=preload("res://scripts/gift_button.gd").new()
	gift.position=Vector2(168,32)
	gift.size=Vector2(40,30)
	gift.scale=Vector2.ONE*1.6
	gift.delivered=true
	gift.effects=app.gift_effects
	gift.text_scale=app.text_scale
	gift.age=0
	for style_ in ["normal","hover","pressed","focus"]: gift.add_theme_stylebox_override(style_,StyleBoxEmpty.new())
	stage.add_child(gift)
	stage.resized.connect(func(): gift.position.x=(stage.size.x-64)/2)
	var item_icon=Node2D.new()
	item_icon.position=Vector2(200,56)
	item_icon.visible=false
	stage.add_child(item_icon)
	stage.resized.connect(func(): item_icon.position.x=stage.size.x/2)
	if entry.slot=="pin":
		var badge=Pin.new()
		badge.kind=entry.id
		badge.scale=Vector2.ONE*2.8
		item_icon.add_child(badge)
	else:
		var swatch=Panel.new()
		swatch.position=Vector2(-35,-24)
		swatch.size=Vector2(70,48)
		swatch.add_theme_stylebox_override("panel",preload("res://scripts/widget.gd").box(entry.color,18))
		item_icon.add_child(swatch)
	var particles=preload("res://scripts/gift_sparkles.gd").new()
	particles.position=Vector2(200,56)
	particles.visible=false
	stage.add_child(particles)
	stage.resized.connect(func(): particles.position.x=stage.size.x/2)
	gift.pressed.connect(func():
		gift.hide()
		item_icon.show()
		subtitle.text=entry.name+" · 바로 장착했어요!"
		if app.gift_effects:
			particles.restart()
			item_icon.scale=Vector2.ONE*.6
			create_tween().tween_property(item_icon,"scale",Vector2.ONE,.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	column.add_child(label("함께 보낸 시간이 선물이 되었어요",12))
	var close=button("고마워, 잘 쓸게!",func(): present.queue_free())
	close.custom_minimum_size.y=Cozy.FOOTER_HEIGHT
	column.add_child(close)
	Cozy.apply_dialog_spacing(present)
	apply_text_size()

func scale_text(node: Node) -> void:
	if node is GiftButton or node is ReportChart: node.set("text_scale",app.text_scale)
	if node is Control:
		for property_ in ["font_size"]:
			if node is Label or node is Button or node is TabContainer:
				if not node.has_meta("base_font_size"): node.set_meta("base_font_size",node.get_theme_font_size(property_))
				node.add_theme_font_size_override(property_,maxi(Cozy.MIN_FONT,roundi(float(node.get_meta("base_font_size"))*app.text_scale)))
				if node is OptionButton: node.get_popup().add_theme_font_size_override("font_size",roundi(15*app.text_scale))
	for child in node.get_children(): scale_text(child)
func apply_text_size() -> void:
	if is_instance_valid(content): scale_text(content)
	if is_instance_valid(present): scale_text(present)
	var available=available_screen()
	size.x=roundi(Cozy.SETTINGS_WIDTH+maxf(0,app.text_scale-1)*320)
	if available.size.x>0 and available.size.y>0:
		size.x=mini(size.x,maxi(1,available.size.x-Cozy.OUTER*2))
		size.y=mini(Cozy.SETTINGS_HEIGHT,maxi(1,available.size.y-Cozy.OUTER*2))
		position=position.clamp(available.position,(available.end-size).max(available.position))
func available_screen() -> Rect2i:
	if not visible and is_instance_valid(app.widget) and app.widget.screen_rect.size.x>0: return app.widget.screen_rect
	var widget_script=preload("res://scripts/widget.gd")
	return widget_script.screen_for_bounds(Rect2i(position,size),widget_script.usable_screens(),current_screen)

func build_cafe_tab() -> void:
	var scroll=ScrollContainer.new()
	scroll.name="카페 노트"
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var page=VBoxContainer.new()
	page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation",Cozy.CARD_GAP)
	scroll.add_child(page)
	var wallet=section(page,"오늘의 스탬프 카드")
	cafe_balance=label("",20)
	cafe_balance.add_theme_font_override("font",Cozy.heading_font())
	wallet.add_child(cafe_balance)
	wallet.add_child(label("오늘의 주문을 완료하고 스탬프를 받아요",12))
	wallet.add_child(label("매일 새 주문 · 모은 스탬프와 교환한 테마는 계속 소장",12))
	cafe_notice=label(cafe_notice_text,12)
	cafe_notice.add_theme_color_override("font_color",Color("5b4636"))
	wallet.add_child(cafe_notice)
	for order in app.collection.ORDERS:
		var card=section(page,order.name)
		var progress_label=label("",13)
		card.add_child(progress_label)
		var bar=ProgressBar.new()
		bar.custom_minimum_size=Vector2(0,8)
		bar.show_percentage=false
		card.add_child(bar)
		var claim_button=button("",func():
			if app.collection.claim_order(order.id):
				cafe_notice_text="스탬프 +%d개! 오늘도 함께해 줘서 고마워요"%order.reward
				cafe_notice.text=cafe_notice_text
				app.save_game()
				refresh_cafe()
				app.widget.refresh_text())
		claim_button.icon=Cozy.icon("coffee")
		card.add_child(claim_button)
		cafe_rows.append({"order":order,"label":progress_label,"bar":bar,"button":claim_button})
	var shop=section(page,"작은 교환소 · 입력 불빛")
	shop.add_child(label("입력할 때 켜지는 네모 불빛의 색상을 꾸며요",12))
	for light in app.collection.LIGHTS:
		var row=VBoxContainer.new()
		row.add_theme_constant_override("separation",Cozy.INNER_GAP)
		shop.add_child(row)
		var sample=HBoxContainer.new()
		sample.alignment=BoxContainer.ALIGNMENT_CENTER
		row.add_child(sample)
		for i in range(8):
			var tile=Panel.new()
			tile.custom_minimum_size=Vector2(20,20)
			tile.add_theme_stylebox_override("panel",Cozy.box(light.color,5))
			sample.add_child(tile)
		row.add_child(label(light.name,16))
		var owned=light.id in app.collection.owned_lights
		var selected=app.collection.light_style==light.id
		var buy=button("사용 중" if selected else ("사용하기" if owned else "스탬프 %d개로 교환"%light.price),func():
			var success=app.collection.equip_light(light.id) if owned else app.collection.buy_light(light.id)
			if success:
				cafe_notice_text=light.name+" 적용 완료! 타자를 쳐보세요"
				app.save_game()
				rebuild.call_deferred())
		buy.disabled=selected or (not owned and app.collection.stamps<light.price)
		buy.set_meta("light_price",light.price)
		buy.set_meta("owned",owned)
		row.add_child(buy)
	shop.add_child(button("기본 세이지 불빛",func(): app.collection.equip_light(""); app.save_game(); rebuild.call_deferred()))
	refresh_cafe()
func refresh_cafe() -> void:
	if not is_instance_valid(cafe_balance): return
	cafe_balance.text="스탬프 %d개  ·  오늘 %d / 3 완료"%[app.collection.stamps,app.collection.daily_claims.size()]
	for row in cafe_rows:
		var order=row.order
		var done=order.id in app.collection.daily_claims
		var ratio=app.collection.order_progress(order)
		row.bar.value=ratio*100
		row.label.text=("입력 %d / %d회"%[mini(app.collection.daily_actions,order.target),order.target]) if order.metric=="actions" else ("활동 %d / %d분"%[mini(int(app.collection.daily_ms/60000),int(order.target/60000)),int(order.target/60000)])
		row.button.text="완료 · 스탬프 받았어요" if done else "스탬프 %d개 받기"%order.reward
		row.button.disabled=done or ratio<1
	for child in find_children("*","Button",true,false):
		if child.has_meta("light_price") and not child.get_meta("owned"):
			child.disabled=app.collection.stamps<int(child.get_meta("light_price"))

