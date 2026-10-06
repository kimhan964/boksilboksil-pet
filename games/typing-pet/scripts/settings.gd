extends Window
const Catalog=preload("res://scripts/catalog.gd")
const Pin=preload("res://scripts/pin.gd")
var app
var content: Control
var progress_text: Label
var progress_bar: ProgressBar
var tabs: TabContainer
var tab=0
var preview_pin
var present: Control
func _init() -> void:
	visible=false
	force_native=true
	always_on_top=true
	unresizable=true
	size=Vector2i(540,640)
	title="복슬복슬 타자친구 · 설정과 작은 선물"
func _ready() -> void:
	theme=app.skin
	close_requested.connect(hide)
func label(text_: String,font_size: int=14) -> Label:
	var result=Label.new()
	result.text=text_
	result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size",font_size)
	return result
func button(text_: String,action: Callable) -> Button:
	var result=Button.new()
	result.text=text_
	result.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	result.pressed.connect(action)
	return result
func rebuild() -> void:
	if is_instance_valid(tabs): tab=tabs.current_tab
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content=PanelContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_stylebox_override("panel",preload("res://scripts/cozy_ui.gd").box("faf8f3",0))
	add_child(content)
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	content.add_child(column)
	var brand=label("복슬복슬 타자친구",23)
	brand.add_theme_color_override("font_color",Color("94766b"))
	column.add_child(brand)
	column.add_child(label("일하는 순간에도, 작은 친구와 함께",12))
	var preview=Control.new()
	preview.custom_minimum_size=Vector2(0,108)
	column.add_child(preview)
	var hero=Sprite2D.new()
	hero.centered=false
	hero.texture=app.widget.frames[0]
	hero.scale=Vector2.ONE*(104.0/hero.texture.get_width())
	hero.position=Vector2(204,0)
	var mat=ShaderMaterial.new()
	mat.shader=preload("res://scripts/tone.gdshader")
	mat.set_shader_parameter("shift",app.collection.TINTS.get(app.collection.selected(app.species,"skin"),Vector3.ZERO))
	hero.material=mat
	preview.add_child(hero)
	preview_pin=Pin.new()
	preview_pin.kind=app.collection.selected(app.species,"pin")
	preview_pin.worn=true
	preview_pin.position=hero.position+Catalog.accessory_anchor(app.species,preview_pin.kind)*104
	preview_pin.scale=Vector2.ONE*.52
	preview.add_child(preview_pin)
	tabs=TabContainer.new()
	tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	tabs.tab_alignment=TabBar.ALIGNMENT_CENTER
	for style_ in ["panel","tab_selected","tab_unselected","tab_hovered","tab_focus"]:
		tabs.add_theme_stylebox_override(style_,preload("res://scripts/cozy_ui.gd").box("e5eadd" if style_=="tab_selected" else "faf8f3",10))
	for color_ in ["font_selected_color","font_unselected_color","font_hovered_color","font_focus_color"]:
		tabs.add_theme_color_override(color_,Color("59564f"))
	column.add_child(tabs)
	var options_scroll=ScrollContainer.new()
	options_scroll.name="설정"
	options_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(options_scroll)
	var options=VBoxContainer.new()
	options.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation",10)
	options_scroll.add_child(options)
	options.add_child(label("오늘 함께할 친구"))
	var species=OptionButton.new()
	species.alignment=HORIZONTAL_ALIGNMENT_CENTER
	for title_ in Catalog.NAMES: species.add_item(title_)
	species.select(app.species)
	species.item_selected.connect(app.choose_friend)
	options.add_child(species)
	options.add_child(label("화면 위치 · 펫 크기"))
	var row=HBoxContainer.new()
	options.add_child(row)
	var corner=OptionButton.new()
	corner.alignment=HORIZONTAL_ALIGNMENT_CENTER
	corner.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for title_ in ["왼쪽 위","오른쪽 위","왼쪽 아래","오른쪽 아래"]: corner.add_item(title_)
	corner.select(app.corner)
	corner.item_selected.connect(func(value): app.corner=value; app.custom_position=false; app.widget.place(); app.save_game())
	row.add_child(corner)
	var zoom=OptionButton.new()
	zoom.alignment=HORIZONTAL_ALIGNMENT_CENTER
	zoom.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for title_ in ["작게","보통","크게"]: zoom.add_item(title_)
	zoom.select(app.zoom)
	zoom.item_selected.connect(func(value): app.zoom=value; app.scale_factor=0; app.widget.place(); app.save_game(); rebuild.call_deferred())
	row.add_child(zoom)
	options.add_child(button("동물을 잡아서 원하는 곳으로 옮기기",func(): app.widget.move_enabled=true; hide()))
	var size_label=label("크기 %d%%"%roundi(app.widget.root.scale.x*100),12)
	options.add_child(size_label)
	var slider=HSlider.new()
	slider.min_value=70
	slider.max_value=150
	slider.step=5
	slider.value=app.widget.root.scale.x*100
	slider.custom_minimum_size=Vector2(0,24)
	slider.value_changed.connect(func(value): app.set_size(value/100.0); size_label.text="크기 %d%%"%int(value))
	options.add_child(slider)
	var toggles=HBoxContainer.new()
	options.add_child(toggles)
	for property_ in ["show_lights","gift_effects"]:
		var toggle=button("입력 불빛" if property_=="show_lights" else "선물 반짝임",func(): pass)
		toggle.toggle_mode=true
		toggle.button_pressed=app.get(property_)
		toggle.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		toggle.toggled.connect(func(value): app.set(property_,value); app.save_game())
		toggles.add_child(toggle)
	options.add_child(button("입력 반응 다시 시작" if app.paused else "입력 반응 잠시 쉬기",app.toggle_pause))
	if not app.bridge.connected and not app.paused:
		options.add_child(button("입력 도우미 다시 연결",func(): app.bridge.start(); rebuild.call_deferred()))
	options.add_child(label("APM은 입력 속도에 따라 부드럽게 변해요.\n활동 시간은 30초간 입력이 없으면 멈춰요.",12))
	options.add_child(label("키보드·마우스의 입력 횟수만 사용해요.\n입력한 글자나 사용하는 프로그램은 저장하지 않아요.",11))
	var gifts=VBoxContainer.new()
	gifts.name="선물 · 꾸미기"
	gifts.add_theme_constant_override("separation",8)
	tabs.add_child(gifts)
	progress_text=label("",12)
	gifts.add_child(progress_text)
	progress_bar=ProgressBar.new()
	progress_bar.custom_minimum_size=Vector2(0,8)
	progress_bar.show_percentage=false
	gifts.add_child(progress_bar)
	gifts.add_child(label("입력과 활동을 쌓아 영구 소장 · 16마리 모두 사용 가능",11))
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	gifts.add_child(scroll)
	var grid=GridContainer.new()
	grid.columns=2
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	scroll.add_child(grid)
	for entry in app.collection.ITEMS: add_item_card(grid,entry)
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
	tabs.current_tab=clampi(tab,0,1)
	var footer=HBoxContainer.new()
	column.add_child(footer)
	var close=button("닫기",hide)
	close.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer.add_child(close)
	footer.add_child(button("오늘은 안녕",app.shutdown))
	refresh_progress()
func add_item_card(grid: GridContainer,entry: Dictionary) -> void:
	var card=PanelContainer.new()
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",preload("res://scripts/cozy_ui.gd").box("f0eee6",10))
	grid.add_child(card)
	var body=VBoxContainer.new()
	body.add_theme_constant_override("separation",4)
	card.add_child(body)
	var icon=Control.new()
	icon.custom_minimum_size=Vector2(180,52)
	body.add_child(icon)
	if entry.slot=="pin":
		var badge=Pin.new()
		badge.kind=entry.id
		badge.position=Vector2(90,26)
		icon.add_child(badge)
	else:
		var swatch=Panel.new()
		swatch.position=Vector2(65,16)
		swatch.size=Vector2(50,20)
		swatch.add_theme_stylebox_override("panel",preload("res://scripts/widget.gd").box(entry.color,8))
		icon.add_child(swatch)
	body.add_child(label(entry.name,13))
	var owned=entry.id in app.collection.claimed
	var ready=app.collection.eligible(entry.id)
	var selected=app.collection.selected(app.species,entry.slot)==entry.id
	var hint="이 친구에게 장착 중" if selected else ("영구 소장 · 장착할 수 있어요" if owned else "%d/%d회 · %d/%d분"%[mini(app.collection.actions,entry.actions),entry.actions,mini(int(app.collection.active_ms/60000),int(ceil(entry.seconds/60.0))),int(ceil(entry.seconds/60.0))])
	if not owned and entry.seconds<60: hint="%d/%d회 · %d/%d초"%[mini(app.collection.actions,entry.actions),entry.actions,mini(int(app.collection.active_ms/1000),entry.seconds),entry.seconds]
	body.add_child(label(hint,10))
	var action=button("장착 중" if selected else ("장착하기" if owned else ("선물 받기" if ready else "아직 잠겨 있어요")),func():
		if not owned and not app.collection.claim(entry.id): return
		app.collection.equip(app.species,entry.slot,entry.id)
		app.widget.apply_cosmetics()
		app.save_game()
		rebuild.call_deferred()
		if not owned: show_present.call_deferred(entry))
	action.disabled=selected or (not owned and not ready)
	action.add_theme_font_size_override("font_size",11)
	body.add_child(action)
func refresh_progress() -> void:
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
	var card=Panel.new()
	card.position=Vector2(90,165)
	card.size=Vector2(360,310)
	card.add_theme_stylebox_override("panel",preload("res://scripts/cozy_ui.gd").box("fff8ee",24))
	present.add_child(card)
	var title_=label("작은 선물이 도착했어요",21)
	title_.position=Vector2(12,24)
	title_.size=Vector2(336,32)
	card.add_child(title_)
	var subtitle=label("상자를 눌러 열어보세요",13)
	subtitle.position=Vector2(12,65)
	subtitle.size=Vector2(336,25)
	card.add_child(subtitle)
	var gift=preload("res://scripts/gift_button.gd").new()
	gift.position=Vector2(150,119)
	gift.size=Vector2(40,30)
	gift.scale=Vector2.ONE*1.6
	gift.delivered=true
	gift.effects=app.gift_effects
	gift.age=0
	for style_ in ["normal","hover","pressed","focus"]: gift.add_theme_stylebox_override(style_,StyleBoxEmpty.new())
	card.add_child(gift)
	var item_icon=Node2D.new()
	item_icon.position=Vector2(180,151)
	item_icon.visible=false
	card.add_child(item_icon)
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
	particles.position=Vector2(180,151)
	particles.visible=false
	card.add_child(particles)
	gift.pressed.connect(func():
		gift.hide()
		item_icon.show()
		subtitle.text=entry.name+" · 바로 장착했어요!"
		if app.gift_effects:
			particles.show()
			particles.age=0
			item_icon.scale=Vector2.ONE*.6
			create_tween().tween_property(item_icon,"scale",Vector2.ONE,.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	var name_=label("함께 보낸 시간이 선물이 되었어요",12)
	name_.position=Vector2(12,212)
	name_.size=Vector2(336,25)
	card.add_child(name_)
	var close=button("고마워, 잘 쓸게!",func(): present.queue_free())
	close.position=Vector2(32,251)
	close.size=Vector2(296,38)
	card.add_child(close)
