extends Button
var delivered=false:
	set(next):
		if delivered==next: return
		delivered=next
		refresh_visual()
var effects=true:
	set(next):
		if effects==next: return
		effects=next
		refresh_visual()
var age=10.0
var opened=false:
	set(next):
		if opened==next: return
		opened=next
		queue_redraw()
var compact=false:
	set(next):
		if compact==next: return
		compact=next
		queue_redraw()
var count=0:
	set(next):
		if count==next: return
		count=next
		queue_redraw()
var text_scale=1.0:
	set(next):
		if text_scale==next: return
		text_scale=next
		queue_redraw()
var idle_box=StyleBoxFlat.new()
var arrived_box=StyleBoxFlat.new()
func _init() -> void:
	idle_box.bg_color=Color("fff7ec")
	idle_box.border_color=Color("6b4a35")
	arrived_box.bg_color=Color("f7c6c7")
	arrived_box.border_color=Color("6b4a35")
	for outline in [idle_box,arrived_box]:
		outline.set_border_width_all(2)
		outline.set_corner_radius_all(3)
func _ready() -> void:
	refresh_visual()
func refresh_visual() -> void:
	set_process(delivered and effects)
	queue_redraw()
func arrive() -> void:
	age=0
	delivered=true
	queue_redraw()
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	age+=delta
	queue_redraw()
func _draw() -> void:
	var bounce=absf(sin(age*3))*2 if delivered and effects else 0.0
	var center=size/2+Vector2(0,1-bounce)
	if compact: center=Vector2(19,size.y/2+5-bounce)
	if delivered and effects: draw_circle(center,15,Color(1,.85,.47,.25+.10*sin(age*3)),true,-1,true)
	var body=Rect2(center+Vector2(-10,-5),Vector2(20,14))
	var outline=arrived_box if delivered else idle_box
	draw_style_box(outline,body)
	draw_rect(Rect2(center+Vector2(-2,-7),Vector2(4,16)),Color("fff7ec"))
	var lid_y=-8.0-(5.0 if opened else 0.0)
	draw_style_box(outline,Rect2(center+Vector2(-12,lid_y),Vector2(24,5)))
	draw_arc(center+Vector2(-4,lid_y),4,0,TAU,20,Color("6b4a35"),1.5,true)
	draw_arc(center+Vector2(4,lid_y),4,0,TAU,20,Color("6b4a35"),1.5,true)
	if delivered and effects:
		for i in range(3):
			var p=center+Vector2.from_angle(age*.5+i*TAU/3)*16
			var glow=.55+.35*sin(age*3+i)
			draw_line(p-Vector2(2,0),p+Vector2(2,0),Color(.80,.66,.37,glow),1,true)
			draw_line(p-Vector2(0,2),p+Vector2(0,2),Color(.80,.66,.37,glow),1,true)
	if compact and delivered:
		var font=get_theme_font("font")
		var caption=str(count)
		var pixels=maxi(12,roundi(12*text_scale))
		while font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x>18 and pixels>12: pixels-=1
		var width=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x
		var radius=8.0
		var badge=Vector2(29,5)
		var baseline=4
		if text_scale>1:
			radius=clampf(ceil(maxf(width,font.get_height(pixels))/2+2),8,11)
			badge=Vector2(minf(29,size.x+1-radius),maxf(5,radius-3))
			baseline=roundi((font.get_ascent(pixels)-font.get_descent(pixels))/2)
		draw_circle(badge,radius,Color("6b4a35"),true,-1,true)
		draw_string(font,badge+Vector2(-width/2,baseline),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,Color.WHITE)
