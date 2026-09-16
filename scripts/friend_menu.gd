extends PopupPanel
signal id_pressed(id: int)
const Catalog=preload("res://scripts/animal_catalog.gd")
var entries: Array=[]
var section=0
var source: PopupMenu
var history: Array=[]
var body: VBoxContainer
var heading: Label
var detail: Label
var portrait: TextureRect
var tabs: Array=[]
const SECTIONS=[[0,1,22,4,16,20],[2,15,11,12,13,21],[5,6,7,8],[18,14,9,19,10,900]]

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
	size=Vector2i(408,564)
	var skin=Theme.new()
	var font=SystemFont.new()
	font.font_names=PackedStringArray(["Malgun Gothic"])
	skin.default_font=font
	skin.default_font_size=14
	skin.set_stylebox("panel","PopupPanel",box("f8f1e5",22))
	for state_name in ["normal","hover","pressed","disabled","focus"]:
		var color={"normal":"fffaf2","hover":"e7eddc","pressed":"d3dfc2","disabled":"ece7de","focus":"e7eddc"}[state_name]
		var style=box(color)
		if state_name=="focus":
			style.bg_color=Color.TRANSPARENT
			style.border_color=Color("71865b")
			style.set_border_width_all(2)
		skin.set_stylebox(state_name,"Button",style)
	for state_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: skin.set_color(state_name,"Button",Color("594a3c"))
	skin.set_color("font_disabled_color","Button",Color("a79e91"))
	skin.set_color("font_color","Label",Color("594a3c"))
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
	eyebrow.text="바탕화면 친구"
	eyebrow.add_theme_color_override("font_color",Color("85906c"))
	eyebrow.add_theme_font_size_override("font_size",12)
	title_column.add_child(eyebrow)
	heading=Label.new()
	heading.add_theme_font_size_override("font_size",23)
	title_column.add_child(heading)
	detail=Label.new()
	detail.add_theme_font_size_override("font_size",12)
	title_column.add_child(detail)
	var close=make_button("닫기",func(): hide())
	close.custom_minimum_size=Vector2(50,36)
	close.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	top.add_child(close)
	var tab_row=HBoxContainer.new()
	column.add_child(tab_row)
	for i in range(4):
		var button=make_button(["함께 놀기","돌보기","꾸미기","기록"][i],func():
			section=i
			source=null
			history.clear()
			rebuild())
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",13)
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
	var friends=make_button("친구 바꾸기",func(): open_source(get_node("Friends")))
	friends.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer.add_child(friends)
	footer.add_child(make_button("오늘은 안녕",func(): hide(); id_pressed.emit(3)))
	about_to_popup.connect(prepare)

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
		tabs[i].add_theme_stylebox_override("normal",box("dce6cc" if i==section and source==null else "eee7da"))
	if source!=null:
		body.add_child(make_button("‹  돌아가기",func(): source=history.pop_back(); rebuild()))
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
			style_action(button)
			body.add_child(button)
		return
	var caption=Label.new()
	caption.text=["오늘은 어떤 놀이를 해볼까?","먹고 쉬며, 조금 더 가까이","우리 친구의 자리를 꾸며요","함께 쌓아가는 작은 기록"][section]
	caption.add_theme_color_override("font_color",Color("8b806e"))
	body.add_child(caption)
	for id in SECTIONS[section]:
		var index=get_item_index(id)
		if index<0: continue
		var item=entries[index]
		var text=("✓  " if item.checked else "")+item.text
		if not item.submenu.is_empty(): text+="  ›"
		var button=make_button(text,func():
			if not item.submenu.is_empty(): open_source(get_node(item.submenu))
			else: hide(); id_pressed.emit(item.id))
		button.disabled=item.disabled
		if item.disabled: button.tooltip_text="친밀도를 쌓으면 열려요"
		style_action(button)
		body.add_child(button)

func style_action(button: Button) -> void:
	button.custom_minimum_size.y=44
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
