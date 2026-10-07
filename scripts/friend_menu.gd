extends PopupPanel
signal id_pressed(id: int)
const Catalog=preload("res://scripts/animal_catalog.gd")
const Food=preload("res://scripts/food_catalog.gd")
const Icons=preload("res://scripts/ui_icons.gd")
var entries: Array=[]
var section=0
var source: PopupMenu
var history: Array=[]
var body: VBoxContainer
var heading: Label
var detail: Label
var portrait: TextureRect
var tabs: Array=[]
var friend_button: Button
const SECTIONS=[[32,25],[15],[32,33,27,28],[26,18,14,9,10,900]]
func add_item(text: String, id: int) -> void:
	entries.append({"text":text,"id":id,"disabled":false,"checked":false,"check":false,"submenu":""})
func add_check_item(text: String,id: int) -> void:
	add_item(text,id)
	entries[-1].check=true
func add_submenu_item(text: String,path: String,id: int) -> void:
	add_item(text,id)
	entries[-1].submenu=path
func add_separator() -> void: pass
func get_item_index(id: int) -> int:
	for i in range(entries.size()):
		if entries[i].id==id: return i
	return -1
func set_item_text(index: int,text: String) -> void:
	if index>=0: entries[index].text=text
func set_item_checked(index: int,value: bool) -> void:
	if index>=0: entries[index].checked=value
func set_item_disabled(index: int,value: bool) -> void:
	if index>=0: entries[index].disabled=value

static func box(color: String, radius: int=14) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(color)
	style.set_corner_radius_all(radius)
	style.content_margin_left=14
	style.content_margin_right=14
	style.content_margin_top=10
	style.content_margin_bottom=10
	return style

func _ready() -> void:
	transparent=true
	transparent_bg=true
	size=Vector2i(440,646)
	var skin=preload("res://scripts/cozy_ui.gd").theme()
	theme=skin
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	add_child(column)
	var top=HBoxContainer.new()
	column.add_child(top)
	portrait=TextureRect.new()
	portrait.custom_minimum_size=Vector2(74,82)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(portrait)
	var title_column=VBoxContainer.new()
	title_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(title_column)
	var eyebrow=Label.new()
	eyebrow.text="복슬복슬펫 · 함께하는 하루"
	eyebrow.add_theme_color_override("font_color",Color("85906c"))
	eyebrow.add_theme_font_size_override("font_size",12)
	title_column.add_child(eyebrow)
	heading=Label.new()
	preload("res://scripts/cozy_ui.gd").label(heading,"title")
	title_column.add_child(heading)
	detail=Label.new()
	detail.add_theme_font_size_override("font_size",12)
	title_column.add_child(detail)
	var close=make_button("닫기",func(): hide())
	close.custom_minimum_size=Vector2(50,36)
	close.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	top.add_child(close)
	var placement_button=make_button("가구·아이템 배치",func(): hide(); id_pressed.emit.call_deferred(32))
	placement_button.name="OpenFurniture"
	Icons.decorate(placement_button,"home",40)
	placement_button.custom_minimum_size.y=48
	column.add_child(placement_button)
	var tab_row=HBoxContainer.new()
	column.add_child(tab_row)
	for i in range(4):
		var button=make_button(["함께하기","식탁 준비","집 꾸미기","생활 기록"][i],func():
			section=i
			source=null
			history.clear()
			rebuild())
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		Icons.decorate(button,["together","table","home","journal"][i],28)
		button.add_theme_font_size_override("font_size",preload("res://scripts/cozy_ui.gd").BODY_SIZE)
		tab_row.add_child(button)
		tabs.append(button)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(0,350)
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body=VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",8)
	scroll.add_child(body)
	var footer=HBoxContainer.new()
	column.add_child(footer)
	friend_button=make_button("친구 바꾸기",func(): open_source(get_node("Friends")))
	friend_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer.add_child(friend_button)
	footer.add_child(make_button("오늘은 안녕",func(): hide(); id_pressed.emit(3)))
	about_to_popup.connect(prepare)

func set_friend_count(count: int) -> void:
	if friend_button!=null: friend_button.visible=count>1

func make_button(text: String, action: Callable) -> Button:
	var button=Button.new()
	button.text=text
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	return button

func prepare() -> void:
	var pet=get_parent()
	heading.text=Catalog.NAMES[pet.species]
	detail.text="%s  ·  교감 %d"%[pet.state.GROWTH_NAMES[pet.state.growth_stage(pet.species)],int(pet.state.play_affection.get(str(pet.species),0))]
	portrait.texture=pet.view.sprite.texture
	source=null
	history.clear()
	rebuild()
	var screen=DisplayServer.screen_get_usable_rect(DisplayServer.get_screen_from_rect(Rect2i(position,size)))
	position=Vector2i(Vector2(position).clamp(Vector2(screen.position),Vector2((screen.end-size).max(screen.position))))

func open_source(next: PopupMenu) -> void:
	history.append(source)
	source=next
	rebuild()

func rebuild() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for i in range(tabs.size()):
		tabs[i].add_theme_stylebox_override("normal",box("dce5d2" if i==section and source==null else "f2f0e9"))
	if source!=null:
		body.add_child(make_button("‹  돌아가기",func(): source=history.pop_back(); rebuild()))
		var pet=get_parent()
		if source.name=="Foods":
			var help=Label.new()
			help.text=pet.state.food_progress(pet.species)
			help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			body.add_child(help)
			var basic=int(Catalog.DEFAULT_MEALS[pet.species])
			var quick=make_button("기본 먹이 · "+Food.title_for(pet.species,basic),func(): hide(); pet.activity_requested.emit(100+basic))
			quick.disabled=not pet.state.food_available(pet.species,basic)
			style_action(quick)
			body.add_child(quick)
		for i in range(source.item_count):
			if source.is_item_separator(i): continue
			var item_index=i
			var model=source
			var button=make_button(("✓  " if model.is_item_checked(i) else "")+model.get_item_text(i),func():
				var path=model.get_item_submenu(item_index)
				if not path.is_empty(): open_source(model.get_node(path))
				else:
					hide()
					model.id_pressed.emit(model.get_item_id(item_index)))
			button.disabled=model.is_item_disabled(i)
			var food_id=model.get_item_id(i)-100
			if food_id>=0 and food_id<32:
				button.disabled=not pet.state.food_available(pet.species,food_id)
				button.text=("잠김 · " if button.disabled else "")+model.get_item_text(i)
				if int(pet.state.meals.get(str(pet.species),Catalog.DEFAULT_MEALS[pet.species]))==food_id: button.text+=" · 선택됨"
				button.text+="\n"+pet.state.food_hint(pet.species,food_id)
				button.icon=Food.icon_for(pet.species,food_id)
				button.expand_icon=true
				button.add_theme_constant_override("icon_max_width",44)
			style_action(button)
			body.add_child(button)
		return
	var caption=Label.new()
	caption.text=["동물을 클릭해 쓰다듬고, 물건에 끌어 놓아 함께해요.\n공·생쥐를 클릭하면 놀고, 소파에 놓으면 쉬어요.","메뉴를 골라 식탁을 준비해요.\n식탁을 클릭하거나 동물을 데려다 놓으면 이용해요.\n식탁의 우클릭 메뉴에서 음식·물을 고를 수 있어요.","가구·놀이감·꾸미기 아이템을 배치해요.","물건과 함께한 생활로 새로운 아이템을 열어요."][section]
	caption.text+="\n"+get_parent().state.goal_text(get_parent().species)
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_color_override("font_color",Color("8b806e"))
	body.add_child(caption)
	var progress=get_parent().state.unlock_rows(get_parent().species)
	if section==0:
		for row in progress:
			if row.threshold==0: add_unlock_card(row)
	if section==3:
		for row in progress:
			if not row.open: add_unlock_card(row)
		for row in progress:
			if row.open: add_unlock_card(row)
	else:
		for row in progress:
			if not row.open:
				add_unlock_card(row)
				break
	for id in SECTIONS[section]:
		var index=get_item_index(id)
		if index<0: continue
		var item=entries[index]
		var text=("✓  " if item.checked else "")+item.text
		if item.disabled: text+="\n"+get_parent().state.action_hint(get_parent().species,id)
		if not item.submenu.is_empty(): text+="  ›"
		var button=make_button(text,func():
			if not item.submenu.is_empty(): open_source(get_node(item.submenu))
			else: hide(); id_pressed.emit.call_deferred(item.id))
		button.disabled=item.disabled
		if item.disabled: button.tooltip_text=get_parent().state.action_hint(get_parent().species,id)
		style_action(button)
		Icons.decorate(button,"home" if id==32 else ("table" if id==15 else "journal"),28)
		body.add_child(button)

func style_action(button: Button) -> void:
	button.custom_minimum_size.y=44
	preload("res://scripts/cozy_ui.gd").button(button)
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func add_unlock_card(row: Dictionary) -> void:
	var card=PanelContainer.new()
	card.add_theme_stylebox_override("panel",box("f1f4ec" if row.open else "ffffff",12))
	body.add_child(card)
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",7)
	card.add_child(column)
	var title=Label.new()
	var title_row=HBoxContainer.new()
	title_row.add_theme_constant_override("separation",12)
	column.add_child(title_row)
	var thumb=TextureRect.new()
	thumb.texture=preload("res://scripts/furniture_catalog.gd").texture(str(row.id).trim_prefix("home_"))
	thumb.custom_minimum_size=Vector2(48,48)
	thumb.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.modulate=Color.WHITE if row.open else Color(.75,.75,.75,.7)
	title_row.add_child(thumb)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.text=("배치 가능  ·  " if row.open else "해금 준비  ·  ")+row.get("category","가구")+" · "+row.title
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	title_row.add_child(title)
	if not row.open:
		var hint=Label.new()
		hint.text=row.hint
		hint.add_theme_font_size_override("font_size",12)
		hint.add_theme_color_override("font_color",Color("817d73"))
		hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		column.add_child(hint)
		var bar=ProgressBar.new()
		bar.custom_minimum_size.y=7
		bar.show_percentage=false
		bar.value=row.progress*100
		column.add_child(bar)
