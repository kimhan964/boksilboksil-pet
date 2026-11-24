extends RefCounted
# Dialog spacing contract (logical pixels; fonts scale, gaps stay fixed).
const GRID=8
const OUTER=20
const MAJOR_GAP=16
const TAB_HEIGHT=40
const TAB_PAD=16
const TAB_GAP=8
const TAB_ICON=20
const TAB_ICON_GAP=6
const CARD_X=20
const CARD_Y=16
const CARD_GAP=16
const CARD_RADIUS=16
const BORDER=2
const INNER_GAP=12
const FIELD_HEIGHT=44
const BUTTON_HEIGHT=40
const FOOTER_HEIGHT=44
const CONTROL_RADIUS=14
const BUTTON_GAP=12
const SCROLL_WIDTH=8
const SCROLL_GAP=8
const SCROLL_Y=8
const HELP_PAD=8
const MIN_FONT=12
const PROFILE_PAD=16
const PROFILE_THUMB=96
const PROFILE_GAP=16
const SETTINGS_WIDTH=640
const SETTINGS_HEIGHT=860
const PAPER="fff7ec"
const INK="5b4636"
const SAGE="f7c6c7"
static var body_font: FontFile
static var title_font: FontFile
static var icon_cache: Dictionary={}
static func heading_font() -> FontFile:
	if title_font==null:
		title_font=FontFile.new()
		title_font.data=FileAccess.get_file_as_bytes("res://assets/fonts/Jua-Regular.ttf")
	return title_font
static func icon(kind: String,pixels: int=24) -> Texture2D:
	var key=kind+str(pixels)
	if icon_cache.has(key): return icon_cache[key]
	var path_=''
	match kind:
		"settings": path_='<path d="M9 2H15L16 6L20 7L22 12L19 15L18 20L13 22L9 19L4 18L2 13L5 9L6 4Z" fill="#a7b694"/><circle cx="12" cy="12" r="4" fill="#fff7ec"/>'
		"coffee": path_='<path d="M4 9H17V16Q17 21 10 21Q4 21 4 16Z" fill="#c4ae8e"/><path d="M17 10H20Q24 15 17 17M3 23H20M7 6Q4 3 7 1M13 6Q10 3 13 1" fill="none" stroke="#92715d" stroke-width="2" stroke-linecap="round"/>'
		"move": path_='<path d="M12 2V22M2 12H22M8 6L12 2L16 6M8 18L12 22L16 18M6 8L2 12L6 16M18 8L22 12L18 16" fill="none" stroke="#a58278" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'
		"gift": path_='<rect x="3" y="9" width="18" height="13" rx="3" fill="#d9aaa5"/><path d="M2 9H22M12 8V22M12 8C0 8 5-2 12 8C19-2 24 8 12 8" fill="none" stroke="#93735d" stroke-width="2"/>'
		"text": path_='<path d="M3 5H21M12 5V21M8 21H16" fill="none" stroke="#a58278" stroke-width="3" stroke-linecap="round"/>'
		"help": path_='<circle cx="12" cy="12" r="10" fill="#e8d6c3"/><path d="M9 8C9 3 18 5 15 10L12 13V15" fill="none" stroke="#806756" stroke-width="2" stroke-linecap="round"/><circle cx="12" cy="19" r="1.2" fill="#806756"/>'
		"paw": path_='<ellipse cx="12" cy="16" rx="6" ry="5"/><ellipse cx="5" cy="9" rx="2.5" ry="3"/><ellipse cx="10" cy="5" rx="2.5" ry="3"/><ellipse cx="16" cy="5" rx="2.5" ry="3"/><ellipse cx="21" cy="10" rx="2.5" ry="3"/>'
		"heart": path_='<path d="M12 21C8 17 2 13 2 7C2 1 10 1 12 6C14 1 22 1 22 7C22 13 16 17 12 21Z"/>'
		_: path_='<path d="M5 9L12 16L19 9" fill="none" stroke="#796657" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>'
	var image=Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 24 24"><g fill="#b68f89">'%[pixels,pixels]+path_+'</g></svg>')
	icon_cache[key]=ImageTexture.create_from_image(image)
	return icon_cache[key]
static func box(color: String,radius: int=16) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(color)
	style.set_corner_radius_all(clampi(radius,14,18) if radius>=8 else radius)
	style.border_color=Color("6b4a35")
	style.set_border_width_all(2)
	style.content_margin_left=14
	style.content_margin_right=14
	style.content_margin_top=9
	style.content_margin_bottom=9
	return style
static func theme() -> Theme:
	var skin=Theme.new()
	if body_font==null:
		body_font=FontFile.new()
		body_font.data=FileAccess.get_file_as_bytes("res://assets/fonts/GowunDodum-Regular.ttf")
	skin.default_font=body_font
	skin.default_font_size=15
	for type in ["Button","OptionButton"]:
		for state in ["normal","hover","pressed","disabled","focus"]:
			var color={"normal":SAGE,"hover":"fbe0dc","pressed":"f3c2be","disabled":"efe8de","focus":"fbe0dc"}[state]
			var style=box(color)
			if state=="focus":
				style.bg_color=Color.TRANSPARENT
				style.border_color=Color("6b4a35")
				style.set_border_width_all(2)
			skin.set_stylebox(state,type,style)
		skin.set_font("font",type,heading_font())
		skin.set_font_size("font_size",type,16)
		for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: skin.set_color(key,type,Color(INK))
		skin.set_color("font_disabled_color",type,Color("9a8b7c"))
	skin.set_color("font_color","Label",Color(INK))
	skin.set_font("font","TabContainer",heading_font())
	skin.set_font_size("font_size","TabContainer",17)
	skin.set_icon("arrow","OptionButton",icon("arrow"))
	for state in ["scroll","scroll_focus","grabber","grabber_highlight","grabber_pressed"]:
		var scroll=box("efe1cc" if state.begins_with("scroll") else "f7c6c7",5)
		scroll.content_margin_left=4
		scroll.content_margin_right=4
		scroll.content_margin_top=0
		scroll.content_margin_bottom=0
		skin.set_stylebox(state,"VScrollBar",scroll)
	skin.set_stylebox("panel","TooltipPanel",box("fffdf8",8))
	skin.set_color("font_color","TooltipLabel",Color(INK))
	skin.set_stylebox("panel","PopupPanel",box("fffdf8",18))
	skin.set_stylebox("panel","PopupMenu",box("fffdf8"))
	skin.set_color("font_color","PopupMenu",Color(INK))
	skin.set_color("font_hover_color","PopupMenu",Color(INK))
	skin.set_stylebox("hover","PopupMenu",box(SAGE))
	for state in ["background","fill"]:
		var bar=box("efe8de" if state=="background" else "f7c6c7",4)
		bar.content_margin_top=0
		bar.content_margin_bottom=0
		bar.content_margin_left=0
		bar.content_margin_right=0
		skin.set_stylebox(state,"ProgressBar",bar)
	for state in ["slider","grabber_area","grabber_area_highlight"]:
		var track=box("efe1cc" if state=="slider" else "f7c6c7",5)
		track.content_margin_top=3
		track.content_margin_bottom=3
		skin.set_stylebox(state,"HSlider",track)
	var knob=Image.new()
	knob.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><circle cx="10" cy="10" r="8" fill="#fff7ec" stroke="#6b4a35" stroke-width="2"/><circle cx="10" cy="10" r="3" fill="#f7c6c7"/></svg>')
	for state in ["grabber","grabber_highlight","grabber_disabled"]:
		skin.set_icon(state,"HSlider",ImageTexture.create_from_image(knob))
	return skin

static func card_style(color: String="fffdf8",profile: bool=false) -> StyleBoxFlat:
	var style=box(color,CARD_RADIUS)
	style.set_border_width_all(BORDER)
	style.content_margin_left=PROFILE_PAD if profile else CARD_X
	style.content_margin_right=PROFILE_PAD if profile else CARD_X
	style.content_margin_top=PROFILE_PAD if profile else CARD_Y
	style.content_margin_bottom=PROFILE_PAD if profile else CARD_Y
	return style
static func dialog_theme() -> Theme:
	var skin=theme()
	for type in ["Button","OptionButton","LineEdit"]:
		for state in ["normal","hover","pressed","disabled","focus"]:
			var color={"normal":SAGE,"hover":"fbe0dc","pressed":"f3c2be","disabled":"efe8de","focus":"fbe0dc"}[state]
			var style=box(color,CONTROL_RADIUS)
			style.content_margin_left=TAB_PAD
			style.content_margin_right=TAB_PAD
			style.content_margin_top=GRID
			style.content_margin_bottom=GRID
			if state=="focus": style.bg_color=Color.TRANSPARENT
			skin.set_stylebox(state,type,style)
	for state in ["scroll","scroll_focus","grabber","grabber_highlight","grabber_pressed"]:
		var style=box("efe1cc" if state.begins_with("scroll") else "f7c6c7",4)
		style.content_margin_left=SCROLL_WIDTH/2
		style.content_margin_right=SCROLL_WIDTH/2
		style.content_margin_top=0
		style.content_margin_bottom=0
		skin.set_stylebox(state,"VScrollBar",style)
	return skin
static func pad_scroll(scroll: ScrollContainer) -> void:
	if scroll.has_meta("ui_padded"): return
	scroll.set_meta("ui_padded",true)
	scroll.add_theme_constant_override("horizontal_separation",SCROLL_GAP)
	var child: Control=null
	for node in scroll.get_children():
		if node is Control and not node is ScrollBar: child=node; break
	if child==null: return
	scroll.remove_child(child)
	var margin=MarginContainer.new()
	margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_top",SCROLL_Y)
	margin.add_theme_constant_override("margin_bottom",SCROLL_Y)
	margin.add_theme_constant_override("margin_right",SCROLL_GAP)
	scroll.add_child(margin)
	margin.add_child(child)
static func apply_dialog_spacing(node: Node) -> void:
	if node is Label and node.get_parent() is VBoxContainer:
		node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		if int(node.get_meta("base_font_size",node.get_theme_font_size("font_size")))<=13 and not node.has_meta("ui_help_padded"):
			node.set_meta("ui_help_padded",true)
			var parent=node.get_parent()
			var index=node.get_index()
			parent.remove_child(node)
			var margin=MarginContainer.new()
			margin.add_theme_constant_override("margin_top",HELP_PAD)
			margin.add_theme_constant_override("margin_bottom",HELP_PAD)
			parent.add_child(margin)
			parent.move_child(margin,index)
			margin.add_child(node)
	if node is BoxContainer and not node.has_theme_constant_override("separation"):
		node.add_theme_constant_override("separation",BUTTON_GAP if node is HBoxContainer else INNER_GAP)
	if node is Button:
		node.custom_minimum_size.y=maxf(node.custom_minimum_size.y,FIELD_HEIGHT if node is OptionButton else BUTTON_HEIGHT)
		node.clip_text=true
	if node is Label and node.get_parent() is VBoxContainer:
		node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if node is ScrollContainer: pad_scroll(node)
	for child in node.get_children(): apply_dialog_spacing(child)
