extends Control
# Static, single-color counter; tier data remains in typing_report.
var count=0
var text_scale=1.0
var pop_time=0.0
func advance(dt: float,value: int,_level: int,pressed: bool,scale_: float,enabled: bool):
	var changed=count!=value or text_scale!=scale_
	count=value
	text_scale=scale_
	var was_popping=pop_time>0
	pop_time=maxf(0,pop_time-dt)
	if pressed and enabled: pop_time=.12
	if not enabled: pop_time=0
	if changed or was_popping or pop_time>0: queue_redraw()
func _draw():
	var font=preload("res://scripts/cozy_ui.gd").heading_font()
	var pixels=roundi(clampf(44*text_scale,44,52))
	var number=str(count)
	while tight_width(font,number,pixels)>size.x-16 and pixels>16: pixels-=1
	var w=tight_width(font,number,pixels)
	var pos=Vector2((size.x-w)/2,60)
	var pop=1+.04*(pop_time/.12)
	var pivot=Vector2(size.x/2,42)
	draw_set_transform(pivot*(1-pop),0,Vector2.ONE*pop)
	tight_text(font,pos,number,pixels,Color("5b4636"))
	draw_set_transform(Vector2.ZERO)
	var caption="COMBO"
	var caption_size=maxi(12,roundi(12*text_scale))
	var cw=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,caption_size).x
	draw_string_outline(font,Vector2((size.x-cw)/2,18),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,caption_size,3,Color("fff7ec"))
	draw_string(font,Vector2((size.x-cw)/2,18),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,caption_size,Color("5b4636"))

static func tight_width(font: Font,text: String,pixels: int) -> float:
	var width=0.0
	for letter in text: width+=font.get_string_size(letter,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x-1.2
	return width+1.2
func tight_text(font: Font,pos: Vector2,text: String,pixels: int,color: Color,outline: int=0):
	for letter in text:
		if outline>0: draw_string_outline(font,pos,letter,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,outline,color)
		else: draw_string(font,pos,letter,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)
		pos.x+=font.get_string_size(letter,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x-1.2
