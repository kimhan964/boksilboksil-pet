extends Control
var background=StyleBoxFlat.new()
var outline=StyleBoxFlat.new()
var fill=StyleBoxFlat.new()
var shimmer_clock=0.0
var shimmer_amount=0.0
func advance_shimmer(dt: float,tier: int,activity: float) -> void:
	shimmer_clock=fmod(shimmer_clock+dt,1.5)
	shimmer_amount=.12*sin(TAU*shimmer_clock/1.5)*activity if tier==4 else 0.0
	var base=Color("6b4a35")
	outline.border_color=Color(base.r*(1+shimmer_amount),base.g*(1+shimmer_amount),base.b*(1+shimmer_amount),1)
	queue_redraw()
var value=0.0:
	set(next):
		var clamped=clampf(next,0,1)
		if value==clamped: return
		value=clamped
		fill.bg_color=fill_color()
		queue_redraw()
func _init() -> void:
	background.bg_color=Color("efe1cc")
	outline.bg_color=Color.TRANSPARENT
	outline.border_color=Color("6b4a35")
	outline.set_border_width_all(2)
	outline.set_corner_radius_all(6)
	background.set_corner_radius_all(4)
	fill.bg_color=fill_color()
	fill.set_corner_radius_all(4)
func fill_color() -> Color:
	if value<.3: return Color("f2a3a0")
	if value<.65: return Color("f6d98b")
	return Color("a8d5a2")
func _draw():
	draw_style_box(background,Rect2(Vector2.ZERO,size))
	if value>0:
		draw_style_box(fill,Rect2(Vector2.ZERO,Vector2(size.x*value,size.y)))

	draw_style_box(outline,Rect2(Vector2.ZERO,size).grow(2))
