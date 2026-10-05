extends RefCounted
const PAPER="faf8f3"
const INK="59564f"
const SAGE="e5eadd"
static func box(color: String,radius: int=10) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(color)
	style.set_corner_radius_all(radius)
	style.content_margin_left=14
	style.content_margin_right=14
	style.content_margin_top=9
	style.content_margin_bottom=9
	return style
static func theme() -> Theme:
	var skin=Theme.new()
	var font=SystemFont.new()
	font.font_names=PackedStringArray(["Malgun Gothic","sans-serif"])
	skin.default_font=font
	skin.default_font_size=14
	for type in ["Button","OptionButton"]:
		for state in ["normal","hover","pressed","disabled","focus"]:
			var color={"normal":SAGE,"hover":"dce5d2","pressed":"cfddc4","disabled":"eeece6","focus":"dce5d2"}[state]
			var style=box(color)
			if state=="focus":
				style.bg_color=Color.TRANSPARENT
				style.border_color=Color("98a68f")
				style.set_border_width_all(2)
			skin.set_stylebox(state,type,style)
		for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: skin.set_color(key,type,Color(INK))
		skin.set_color("font_disabled_color",type,Color("817d73"))
	skin.set_color("font_color","Label",Color(INK))
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
	return skin
