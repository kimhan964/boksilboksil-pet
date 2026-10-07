extends Button
var delivered=false
var effects=true
var age=10.0
var opened=false
var compact=false
var count=0
var previous_visual_state=[]
func arrive() -> void:
	age=0
	delivered=true
func _process(delta: float) -> void:
	age+=delta
	var state=[delivered,effects,opened,compact,count]
	if (delivered and effects and is_visible_in_tree()) or state!=previous_visual_state:
		previous_visual_state=state
		queue_redraw()
func _draw() -> void:
	var bounce=absf(sin(age*3))*2 if delivered and effects else 0.0
	var center=size/2+Vector2(0,1-bounce)
	if compact: center=Vector2(19,size.y/2+5-bounce)
	if delivered and effects: draw_circle(center,15,Color(1,.85,.47,.25+.10*sin(age*3)),true,-1,true)
	var body=Rect2(center+Vector2(-10,-5),Vector2(20,14))
	var outline=StyleBoxFlat.new()
	outline.bg_color=Color("ebc7c4") if delivered else Color("dce4d2")
	outline.border_color=Color("a5807d") if delivered else Color("9ca88b")
	outline.set_border_width_all(1)
	outline.set_corner_radius_all(3)
	draw_style_box(outline,body)
	draw_rect(Rect2(center+Vector2(-2,-7),Vector2(4,16)),Color("fff5df"))
	var lid_y=-8.0-(5.0 if opened else 0.0)
	draw_style_box(outline,Rect2(center+Vector2(-12,lid_y),Vector2(24,5)))
	draw_arc(center+Vector2(-4,lid_y),4,0,TAU,20,Color("b78c89"),1.5,true)
	draw_arc(center+Vector2(4,lid_y),4,0,TAU,20,Color("b78c89"),1.5,true)
	if delivered and effects:
		for i in range(3):
			var p=center+Vector2.from_angle(age*.5+i*TAU/3)*16
			var glow=.55+.35*sin(age*3+i)
			draw_line(p-Vector2(2,0),p+Vector2(2,0),Color(.80,.66,.37,glow),1,true)
			draw_line(p-Vector2(0,2),p+Vector2(0,2),Color(.80,.66,.37,glow),1,true)
	if compact and delivered:
		var badge=Vector2(29,5)
		draw_circle(badge,8,Color("b75d62"),true,-1,true)
		var font=get_theme_font("font")
		var caption=str(count)
		var width=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		draw_string(font,badge+Vector2(-width/2,4),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
