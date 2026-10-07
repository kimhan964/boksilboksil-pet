extends RefCounted
const PAPER="faf8f3"
const INK="59564f"
const SAGE="e5eadd"
static var body_font: FontFile
static var title_font: FontFile
static func heading_font() -> FontFile:
	if title_font==null:
		title_font=FontFile.new()
		title_font.data=FileAccess.get_file_as_bytes("res://assets/fonts/Jua-Regular.ttf")
	return title_font
static func icon(kind: String,pixels: int=24) -> Texture2D:
	var path_=''
	match kind:
		"settings": path_='<path d="M9 2H15L16 6L20 7L22 12L19 15L18 20L13 22L9 19L4 18L2 13L5 9L6 4Z" fill="#a7b694"/><circle cx="12" cy="12" r="4" fill="#fff9ef"/>'
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
	return ImageTexture.create_from_image(image)
static func box(color: String,radius: int=10) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(color)
	style.set_corner_radius_all(radius)
	style.border_color=Color("e6ded1")
	style.set_border_width_all(1)
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
			var color={"normal":SAGE,"hover":"dce5d2","pressed":"cfddc4","disabled":"eeece6","focus":"dce5d2"}[state]
			var style=box(color)
			if state=="focus":
				style.bg_color=Color.TRANSPARENT
				style.border_color=Color("98a68f")
				style.set_border_width_all(2)
			skin.set_stylebox(state,type,style)
		skin.set_font("font",type,heading_font())
		skin.set_font_size("font_size",type,16)
		for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: skin.set_color(key,type,Color(INK))
		skin.set_color("font_disabled_color",type,Color("817d73"))
	skin.set_color("font_color","Label",Color(INK))
	skin.set_font("font","TabContainer",heading_font())
	skin.set_font_size("font_size","TabContainer",17)
	skin.set_icon("arrow","OptionButton",icon("arrow"))
	for state in ["scroll","scroll_focus","grabber","grabber_highlight","grabber_pressed"]:
		var scroll=box("eee9df" if state.begins_with("scroll") else "c7b8aa",5)
		scroll.content_margin_left=4
		scroll.content_margin_right=4
		scroll.content_margin_top=0
		scroll.content_margin_bottom=0
		skin.set_stylebox(state,"VScrollBar",scroll)
	skin.set_stylebox("panel","TooltipPanel",box("fff4e5",8))
	skin.set_color("font_color","TooltipLabel",Color(INK))
	skin.set_stylebox("panel","PopupPanel",box(PAPER,18))
	skin.set_stylebox("panel","PopupMenu",box(PAPER))
	skin.set_color("font_color","PopupMenu",Color(INK))
	skin.set_color("font_hover_color","PopupMenu",Color(INK))
	skin.set_stylebox("hover","PopupMenu",box(SAGE))
	for state in ["background","fill"]:
		var bar=box("eeece6" if state=="background" else "a3b394",4)
		bar.content_margin_top=0
		bar.content_margin_bottom=0
		bar.content_margin_left=0
		bar.content_margin_right=0
		skin.set_stylebox(state,"ProgressBar",bar)
	for state in ["slider","grabber_area","grabber_area_highlight"]:
		var track=box("e5e0d7" if state=="slider" else "d5b0b4",5)
		track.content_margin_top=3
		track.content_margin_bottom=3
		skin.set_stylebox(state,"HSlider",track)
	var knob=Image.new()
	knob.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><circle cx="10" cy="10" r="8" fill="#fff8ef" stroke="#ba969c" stroke-width="2"/><circle cx="10" cy="10" r="3" fill="#d9b5bd"/></svg>')
	for state in ["grabber","grabber_highlight","grabber_disabled"]:
		skin.set_icon(state,"HSlider",ImageTexture.create_from_image(knob))
	return skin
