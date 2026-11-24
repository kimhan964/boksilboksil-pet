extends Control
var values=[]
var captions=[]
var color=Color("f7c6c7")
var unit=""
var fixed_max=0.0
var text_scale=1.0:
	set(value):
		text_scale=clampf(value,.9,1.3)
		custom_minimum_size=Vector2(0,150+ceil(42*maxf(0,text_scale-1)))
		queue_redraw()
func _ready():
	custom_minimum_size=Vector2(0,150+ceil(42*maxf(0,text_scale-1)))
	mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
func _gui_input(event):
	if event is InputEventMouseMotion and not values.is_empty():
		var i=clampi(int((event.position.x-12)/maxf(1,(size.x-24)/values.size())),0,values.size()-1)
		tooltip_text=str(captions[i])+" · "+str(values[i])+unit
func _draw():
	if values.is_empty(): return
	var font=preload("res://scripts/cozy_ui.gd").body_font
	if font==null: font=ThemeDB.fallback_font
	var top=maxf(1,fixed_max)
	for v in values: top=maxf(top,float(v))
	var step=(size.x-24)/values.size()
	var font_size=maxi(12,roundi(12*text_scale))
	var caption_height=maxf(28,font.get_height(font_size)+10)
	var baseline=size.y-caption_height
	var plot_height=maxf(1,baseline-font.get_height(font_size)-13)
	draw_line(Vector2(12,baseline),Vector2(size.x-12,baseline),Color("6b4a35"),1)
	for i in range(values.size()):
		var h=float(values[i])/top*plot_height
		var x=12+i*step
		draw_rect(Rect2(x+2,baseline-maxf(h,2),maxf(2,step-4),maxf(h,2)),color if h>0 else Color("efe8de"))
		if values.size()<=7 or i%6==0 or i==23:
			var caption=str(captions[i])
			var label_x=maxf(12,minf(x,size.x-12-font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x))
			draw_string(font,Vector2(label_x,baseline+font.get_ascent(font_size)+6),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("5b4636"))
	draw_string(font,Vector2(12,font.get_ascent(font_size)+2),"최대 %d%s"%[int(top),unit],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("5b4636"))
