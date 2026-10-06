extends Node2D
var age=0.0
func _process(delta: float) -> void:
	if not visible: return
	age+=delta
	queue_redraw()
func _draw() -> void:
	if age>2: return
	for i in range(8):
		var angle=i*TAU/8-.2
		var distance=20+65*(1-exp(-age*2))
		var p=Vector2.from_angle(angle)*distance
		var color=Color("ceadb3") if i%2==0 else Color("a7ba90")
		color.a=maxf(0,1-age/2)
		draw_line(p-Vector2(3,0),p+Vector2(3,0),color,2,true)
		draw_line(p-Vector2(0,3),p+Vector2(0,3),color,2,true)
