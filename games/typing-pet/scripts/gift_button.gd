extends Button
var delivered=false
var effects=true
var age=10.0
var opened=false
func arrive() -> void:
	age=0
	delivered=true
func _process(delta: float) -> void:
	age+=delta
	queue_redraw()
func _draw() -> void:
	var bounce=absf(sin(age*6))*3*maxf(0,1-age/5) if delivered and effects else 0.0
	var center=size/2+Vector2(0,1-bounce)
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
